# Wordpress Stack using Ansible, Packer, Docker, Terraform and AWS

## Goal

The goal is to setup a wordpress container on an ECS cluster using tools like terraform, packer and ansible. This wordpress will use RDS as a database.

## Questions

### What you have done?

First up I built the docker image with Packer docker builder using local shell provisioner, ansible-local provisioner and docker post-processor to upload the image to private docker registry aka AWS ECR. This image contains wordpress files with apache2 as a webserver. In addition, it has an entrypoint that copies files to the EFS folder at the first time if necessary, then populate DB config and wpSalt through environment variables. Resulting from the build I get a docker image that can run apache2 with wordpress configuration. Also, I used vagrant to do some ansible tests.

Afterwards, I’ve done a terraform configuration that creates a AWS ECS cluster in EU-WEST region with base infrastructure components and auto scaling groups configuration using ECS optimized AMI that comes with the ecs agent already installed, ELB was going to load balance wordpress docker containers, RDS for database and Elastic File System which gives me a low latency NFS mount.

A Wordpress dockerized service runs in a specific port on every container instance and it has mounted an EFS folder. I have splitted the components with modules that will allow me or others to reuse them for other projects or create more environments (Needs more work to achieve 100% of that). I have created a provisioning task for the Wordpress service to deploy without downtime.

Finally to run the whole stack, I have created a Makefile with some commands that make it easier to manage each part. Using the Makefile the entire platform can be created with a single command.

### How run your project?

**Note:** Tested on Mac OS X system.

1. Create or use existing IAM user with API access. Or sign up to [AWS account](https://aws.amazon.com/) and create user with API access.

2. Clone the repo.
    ```bash
    git clone repo_url
    ```

3. Install packer, terraform, ansible, awscli and docker.
     ```bash
     brew install packer terraform ansible awscli
     ```
    For the moment I writing this, I used the following versions:
    - packer: 1.0.2
    - terraform: 0.9.11
    - ansible: 2.3.1.0
    - awscli: 1.11.117

4. Install Docker following this link: [Docker for Mac](https://docs.docker.com/docker-for-mac/install/)

5. When everything is ready, check the versions with this command:
    ```bash
    make check
    ```

6. Set AWS environment variables or use awscli profile option.
    ```bash
    export AWS_ACCESS_KEY_ID="anaccesskey"
    export AWS_SECRET_ACCESS_KEY="asecretkey"
    export AWS_DEFAULT_REGION="eu-west-1"
    ```
    or
    ```bash
    export AWS_DEFAULT_REGION="eu-west-1"
    export AWS_DEFAULT_PROFILE=default
    ```

    If you needed more info follow this links:
    - [AWSCLI](http://docs.aws.amazon.com/es_es/cli/latest/userguide/cli-chap-getting-started.html)
    - [TERRAFORM AWS PROVIDERS](https://www.terraform.io/docs/providers/aws/index.html)

7. At this point, run this command to create the platform stack and deploy the wordpress service:
    ```bash
    make create-all
    ```

    Wait a few minutes for positive health checks and open a browser with the ELB url provided. Then, you will see the wp-admin install interface.

    If you needed to update the image you can do the following:
    ```bash
    make build VERSION=IMAGE_TAG
    make wordpress VERSION=IMAGE_TAG
    ```
    ***IMAGE_TAG** can be a commit short hash (git rev-parse --short HEAD)

8. Finally, execute this command to tear down the infrastructure:
    ```bash
    make destroy
    ```

### How components interact between each over?

Firstly, I set up an ECR registry for docker images. Then, I built the packer template based on Ubuntu 16.04 docker image with 4 provisioners; a local shell script that install Ansible roles, then a shell script that installs Ansible, also an Ansible playbook that sets up the timezone and installs wordpress, and finally a cleanup shell script that removes ansible and clears off unused ansible tmp files to save a few space in the resulting docker image. The docker post-processor generate a tagged image and then upload to ECR registry.

Next, I have created VPC with 3 public subnets and 3 private subnets in different availability zones. The public subnets have a routing table that points to the Internet Gateway. The private subnets have a routing table to get the outgoing internet connection for ec2 container instances through 3 NAT Gateways with elastic ip, set up it in public subnets. I made ELB security group which allows incoming traffic on port 80 and outbound traffic from private network on port 80. An EFS security group to allow connection of NFS points on container instances. An ECS security group which handles incoming traffic from public and private subnets on port 80 and open port 22 for testing purposes. Also, it allows all outgoing traffic. Then I deployed a single RDS instance with security group that only permit traffic from private subnet on port 3306.

There are two IAM roles: one for EC2 instances and another one for the ECS services. EC2 instances role has permissions to interact with ECS cluster, such as register itself when a server started or read EFS information. ECS services role have permissions to register/unregister services from ELB, etc. Container instances need to be launched with an EC2 instance IAM role that authenticates to the account and provides the required resource permissions.

Next, the ECS cluster has a NFS folder mounted for each instance of the specific subnet, and auto scaling group for the ec2 container instances that are booted on private subnet so they are not externally accessible. This setup allows to scale the system up or down simply by changing the values in terraform configuration or automatically following auto scaling group policies.

An ELB will load balance the http request to EC2 container instances on port 80 across multiple availability zones. When the instances are loaded and joined to the cluster using  the init script, and service configuration runs a valid container (if required), and the ELB health checks are going well, the ELB register the instance on it, and allows external traffic to the service. Note that, I statically allocate port numbers. This means I can only run one container of this service per instance per port.

Finally, I have a wordpress service setting that launch a specific wordpress image, which was generated with packer and ansible. Also, it has a wordpress database hostname where it gets the url from rds module.

To summarize, inbound traffic is routed through an ELB exposed to the internet and forwarded to their ECS service and containers.

Here are the components I used to configure a container cluster infrastructure and the Wordpress service:

- VPC (/16 ip address range)
- Internet gateway (interface between VPC and the internet).
- 3 public subnet and NAT gateways in 3 availability zone .
- 3 private subnet in 3 availability zone for ecs instances with auto scaling group.
- Elastic ips for nat gateways.
- Route tables and route tables association for subnets.
- Security groups for accessing and/or blocking ELB, container instances, EFS, public and private subnets communications.
- IAM policies, roles and instance profiles.
 - ECS: cluster, instances role, services role, container instances in different availability zones in private subnet with auto scaling group configured and security group, running ECS agent.
- ELB to distribute traffic between container instances.
- EFS file system.
- RDS instance.
- ECR repository
- Wordpress service task definition.

### What problems did you have?

I had the following problems:

- Classic Elastic Load Balancing, allows only a single container attached per instance per elb in the same port. With Application Load Balancing, multiple tasks per container instance can be used, but it only allows http, https, websockets connections (Need to improve that).
- Every time that I run terraform, terraform shows that the aws_route_table (for example: module.private_subnet_az3.aws_route_table.route_table) changes. I need more time to research on this issue.
- Occasionally, the instances do not have internet because the gateway is not provisioned on time. With modulable infrastructure "depends_on" option is difficult to configure it to achieve more module decoupling. See this issue: https://github.com/hashicorp/terraform/issues/10462. I need time to improve this for example adding terraform null_resource resource that allows me add depends_on with module or do some code refactor. At the moment, I did some workaround in user_data script, adding sleep command, etc. Check [here.](https://github.com/adriagalin/ecs-ansible-packer-terraform-wordpress/blob/master/terraform/modules/ecs-cluster/instances/user_data.sh#L9)
- When ec2 instance is provisioned, it executes an init script with some tasks that sometimes the EFS folder is not mounted. To solve this, I checked instance metadata to know the EFS state using curl. Check [here.](https://github.com/adriagalin/ecs-ansible-packer-terraform-wordpress/blob/master/terraform/modules/ecs-cluster/instances/user_data.sh#L58)
- Sometimes, it is difficult to find the root of the problem due to the lack of details provided by AWS through Terraform.

### How you would have done things to have the best HA/automated architecture?

I designed the architecture thinking about HA and fault tolerance in many parts. So, scalability and elasticity is built in most of the layers in this architecture. Note that EFS, ELB, S3 and Cloudfront are designed for HA and fault tolerance  by default provided by Amazon.
First, I will add a CI/CD pipeline for the entire platform. Test every part of the platform with "servespec" and generate and deploy new versions of the EC2 instances and wordpress images automatically via pull request. I will add all wp-config file variable as environment variables  (12factor manifesto at point 3).

For the infrastructure, to achieve the best performance in the HA/automated platform, I just need to change some things because AWS provides some services with HA and fault tolerance that I do not need maintain. So, the ELB, with cross-zone enable, can keep its capacity automatically depending upon the traffic and instance healthy, and direct requests across multiple availability zones.
The ECS orchestration layer also kills a container when health checks are failing and a new one is launched to replace it. I will add S3 with CDN for fast delivery for user and public static assets. For wordpress storage I used EFS which provides a distributed file system with fault tolerance and HA for wp core files. Wordpress ec2 container instances are launched across multiple availability zones, and they can be scaled out and down depending upon the traffic with auto scaling group policies and cloudwatch metrics. It’s important to separate different components to decouple infrastructure, so you can scaled independently.

The biggest pain is the RDS so, I need to migrate RDS instance to RDS master-standby architecture deploying standby instance in different availability zone and create specific subnet for this tier to isolate from ec2 containers subnet. Also, I would add read replicas in different availability zones for read scalability. With this architecture I can increase the number of read replicas in different AZs, manually or implementing a tool for that, during peaks to improve performance reads. Further, I will add a database caching with elasticache to reduce latency and increase throughput for reads and leaves the database to handle more important traffic. For wordpress service task add auto scaling group.

Keep in mind that wordpress [is not designed to take advantage of multiple database instances](https://codex.wordpress.org/HyperDB), so I will need to extend it with a plugin. Now, all parts of this architecture are highly available. I think this architecture is not the best, even when applying some improvements and/or iterating some part of it, it will never be perfect.

### Share with us any ideas you have in mind to improve this kind of infrastructure.

- Using Vault to store and share sensitive data like DB and third party API passwords.
- Create a base infrastructure with remote state. Wordpress service has their remote state too. With this structure I can use datasource to get information from base infra only changing wordpress service state. The state will be stored and managed separately from the code in order to work with multiple people on the stack, and for each environment. Remotes stage can will be saved on S3.
- Enable [Amazon EC2 Run Command](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ec2-run-command.html) feature to securely and remotely manage the configuration. With this option, I don’t need SSH and I can audited every command.
- Or use bastion host with ssh or vpn.
- Configure cloudwatch alarms. For example, monitor EFS storage burst credits. Or automatically restarting failed AWS EC2 instances. Or disk space monitoring.
- Add ALB for serving multiple container on the same balancer, otherwise I need 1 ELB for service. I can use internal proxy service but if I can use cloud providers services to delegate these problems I can reduce the platform complexity.
- Enable auto scaling policies (add aws_cloudwatch_metric_alarm and aws_appautoscaling_policy).
- Storing configuration information in a private bucket in Amazon S3 or hashicorp vault to get information when instances are created.

- Add Route 53 for domains.
- Add internal dns with route53 to communicate between services.
- Add SSL termination.
- Add CDN or ElasticCache for page caching.
- Store user media on S3 and distributed via Cloudfront.
- Add SES for sending emails.
- Add another database (elasticache for example) for user sessions.
- Add cron docker service for wordpress tasks or scheduled service.
- Add cloudwatch logs.
- Add subnet convention for ip address range.
- Add serverspec test for checking every packer build and kitchen-terraform for terraform code.
- Apply 12factor manifesto.

- Create a generic packer template that I can pass different params to create different image services (more dynamic).
- Use a custom-made base image with this preconfigured images I just need a little extra configuration per-image and I can drastically cut down image provisioning time.
- Use alpine for small image size.
- Remove unnecessary files from image.
- Create docker image label from commit on packer post-processor.
- Tweaking container resource assignments.
- Refactor modules to gain dynamism.
- Try to set up the instances/images stateless. Now it's almost ready.
- Add description and tags like environment to improve better readability.

## Bonus

>Tomorrow we want to put this project in production. What would be your advices and choices to achieve that.
>Regarding the infrastructure itself and also external services like the >monitoring, ...

If you plan on using this project in a production environment, keep in mind that this platform only serves 1 wordpress site and it hasn’t all the part in HA.

Firstly, configure a custom domain name for your environment and add ssl termination on ELB.
Review the security to protect the EC2 instance metadata endpoints, the IAM role exposes it. Additionally, save all configuration variables and credentials in a secret place like hashicorp vault or S3 with permissions. Use instance profiles and ecs task roles to define a good granularity and credential lifetime. Add AWS policies at the container-level, not at the instance-level for better control who/which can access.

For logging, you would need to push all logs like ECS agent and instance logs to CloudWatch Log. Or if you want better searchs, use external service like Logentries or a customized ELK stack. Also, analyze logs and react when some alert conditions are activated.

For monitoring, you would need to configure a monitor service that collects and tracks metrics, sets alarms on and automatically react to changes in your AWS resources. To make sure you get notified when containers start failing, you need to listen to events from ECS. In addition, you can monitor logs adding alerts for example with two alarms that watch the load in the instances of the environment and are triggered if the load is too high or too low. When an alarm is triggered, auto scaling group scales up or down in response. Cloudwatch or Datadog service are good for that. You need constantly to monitor for unexpected state changes and retry operations. Using a service like uptimerobot, pingdom, etc to know what customers are seeing as end users: do they have bad latency? Do they have errors?

For maintenance, you will need to configure periodic dumps/snapshots of the database and file data that will be saved in a S3 private bucket. Also, planificate a recovery plan.

As discussed above, you would need to add CI/CD pipeline to provide a good path for deploying in production. CI/CD with rolling deployments: setting deployment_minimum_healthy_percent at 50% on wordpress service task, having at least 2 minimum EC2 instances available. You can create Jenkins pipeline or use your current Concourse CI.

When you need to upgrade the current RDS instance to RDS mater-standby is not mandatory to add read replicas at the first time, firstly analyze the metrics, and then you can see when is the best moment to add them, so you will save costs.
