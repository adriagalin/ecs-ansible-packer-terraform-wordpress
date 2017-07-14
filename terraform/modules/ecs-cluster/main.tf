variable "ecs_cluster_name" {}
variable "ecs_efs_name" {}
variable "ecs_service_data_dir" {}
variable "efs_creation_token" {}
variable "efs_tag_name" {}
variable "efs_subnets_count" {}
variable "efs_subnets_ids" { type = "list" }
variable "efs_security_groups" { type = "list" }

variable "ecs_launch_configuration_prefix_name" {}
variable "ecs_launch_configuration_ami_id" {}
variable "ecs_launch_configuration_security_groups_ids" { type = "list" }

variable "ecs_aws_autoscaling_group_availability_zones" { type = "list" }
variable "ecs_aws_autoscaling_group_name" {}
variable "ecs_aws_autoscaling_group_subnet_ids" { type = "list" }
variable "ecs_aws_autoscaling_group_min_size" {}
variable "ecs_aws_autoscaling_group_max_size" {}
variable "ecs_aws_autoscaling_group_desired_capacity" {}

// TODO: add conditionals to improve reusability

module "ecs" {
  source = "./ecs"
  name = "${var.ecs_cluster_name}"
}

module "efs" {
  source = "./efs"
  creation_token = "${var.efs_creation_token}"
  tag_name = "${var.efs_tag_name}"
  subnets_count = "${var.efs_subnets_count}"
  subnets_ids = ["${var.efs_subnets_ids}"]
  security_groups = ["${var.efs_security_groups}"]
}

module "ecs_instances" {
  source = "./instances"

  ecs_cluster_name = "${var.ecs_cluster_name}"
  efs_name = "${var.ecs_efs_name}"
  service_data_dir = "${var.ecs_service_data_dir}"

  launch_configuration_prefix_name = "${var.ecs_launch_configuration_prefix_name}"
  launch_configuration_ami_id = "${var.ecs_launch_configuration_ami_id}"
  launch_configuration_instance_profile = "${module.iam_ecs_instances_profile.id}"
  launch_configuration_security_groups_ids = ["${var.ecs_launch_configuration_security_groups_ids}"]

  aws_autoscaling_group_availability_zones = ["${var.ecs_aws_autoscaling_group_availability_zones}"]
  aws_autoscaling_group_name = "${var.ecs_aws_autoscaling_group_name}"
  aws_autoscaling_group_subnet_ids = ["${var.ecs_aws_autoscaling_group_subnet_ids}"]
  aws_autoscaling_group_min_size = "${var.ecs_aws_autoscaling_group_min_size}"
  aws_autoscaling_group_max_size = "${var.ecs_aws_autoscaling_group_max_size}"
  aws_autoscaling_group_health_check_grace_period = 300
  aws_autoscaling_group_health_check_type = "ELB"
  aws_autoscaling_group_desired_capacity = "${var.ecs_aws_autoscaling_group_desired_capacity}"
}

module "iam_ecs_instances_role" {
  source = "../iam/role"
  name = "${var.ecs_cluster_name}-ecs-instances-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

module "iam_ecs_instances_role_policy" {
  source = "../iam/role_policy"
  name = "${var.ecs_cluster_name}-ecs-instances-role-policy"
  role_id = "${module.iam_ecs_instances_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:UpdateContainerInstancesState",
        "ecs:Submit*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "elasticfilesystem:DescribeFileSystems"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

module "iam_ecs_instances_profile" {
  source = "../iam/instance_profile"
  name = "${var.ecs_cluster_name}-ecs-instances-role-policy"
  role = "${module.iam_ecs_instances_role.id}"
}

module "iam_ecs_service_role" {
  source = "../iam/role"
  name = "${var.ecs_cluster_name}-ecs-service-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

module "iam_ecs_services_role_policy" {
  source = "../iam/role_policy"
  name = "${var.ecs_cluster_name}-ecs-services-instances-role-policy"
  role_id = "${module.iam_ecs_service_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:Describe*",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
