-// TODO: Add tfvars file with all variables
module "network" {
  source = "../../modules/network"
  cidr_block = "12.0.0.0/16"
  cluster_name = "${var.cluster_name}"
  cluster_id = "${var.cluster_id}"

  public_subnet_name = "public"
  public_subnets_az_count = 3
  public_subnets = ["12.0.0.0/24", "12.0.1.0/24", "12.0.2.0/24"]
  public_subnets_azs = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  private_subnet_name = "private"
  private_subnets_az_count = 3
  private_subnets = ["12.0.5.0/24", "12.0.6.0/24", "12.0.7.0/24"]
  private_subnets_azs = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

}

/* START SG ------------------------------- */
// TODO: Add more specific security group and more customizable module: ecs (only ingress), elb (only egress), ec2 (ingress, egress), rds, etc
module "security_group_elb" {
  source = "../../modules/security-groups/sg"
  name = "${var.cluster_name}-elb-sg"
  vpc_id = "${module.network.vpc_id}"
}

module "security_group_elb_group_rule_allow_80" {
  source = "../../modules/security-groups/rule"
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${module.security_group_elb.aws_security_group_id}"
}

module "security_group_elb_group_rule_egress" {
  source = "../../modules/security-groups/rule"
  type = "egress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${module.security_group_elb.aws_security_group_id}"
}

module "security_group_efs" {
  source = "../../modules/security-groups/sg"
  name = "${var.cluster_name}-efs-sg"
  vpc_id = "${module.network.vpc_id}"
}

module "security_group_efs_group_rule_allow_2049" {
  source = "../../modules/security-groups/rule"
  type = "ingress"
  from_port = 2049
  to_port = 2049
  protocol = "tcp"
  cidr_blocks = ["${module.network.private_subnet_cidr_blocks}"]
  security_group_id = "${module.security_group_efs.aws_security_group_id}"
}

module "security_group_ecs_instances" {
  source = "../../modules/security-groups/sg"
  name = "${var.cluster_name}-ecs-sg"
  vpc_id = "${module.network.vpc_id}"
}

module "security_group_ecs_group_rule_allow_80" {
  source = "../../modules/security-groups/rule"
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${module.security_group_ecs_instances.aws_security_group_id}"
}

module "security_group_ecs_group_egress_rule_allow_all" {
  source = "../../modules/security-groups/rule"
  type = "egress"
  from_port = 0
  to_port = 65535
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${module.security_group_ecs_instances.aws_security_group_id}"
}
/* END SG --------------------------------- */

/* START RDS ------------------------------- */
module "wordpress_rds" {
  source = "../../modules/rds"
  subnet_ids = ["${module.network.private_subnet_ids}"]
  identifier = "wordpress-rds"
  allocated_storage = 5
  engine = "mysql"
  engine_version = "5.7.17"
  instance_class = "db.t2.micro"
  db_name = "wordpress"
  db_username = "wordpress"
  db_password = "s3cr3ts3cr3t"
  parameter_group_name = "default.mysql5.7"
  vpc_id = "${module.network.vpc_id}"
  ingress_from_port = 3306
  ingress_to_port = 3306
  ingress_to_protocol = "tcp"
  ingress_cidr_blocks = ["${module.network.private_subnet_cidr_blocks}"]
}
/* END RDS --------------------------------- */

/* START ECS ------------------------------- */
module "ecs_registry" {
  source = "../../modules/ecr-repository"
  name = "wordpress"
}

module "ecs_cluster" {
  source = "../../modules/ecs-cluster"
  ecs_cluster_name = "${var.cluster_name}"

  efs_creation_token = "${var.cluster_name}"
  efs_tag_name = "${var.cluster_name}-efs"
  efs_subnets_ids = ["${module.network.private_subnet_ids}"]
  efs_subnets_count = 3
  efs_security_groups = ["${module.security_group_efs.aws_security_group_id}"]

  ecs_efs_name = "${var.cluster_name}-efs"
  ecs_service_data_dir = "/var/www/html/wordpress/" # /var/www/html/efs-mount-point/
  ecs_launch_configuration_prefix_name = "${var.cluster_name}"
  ecs_launch_configuration_ami_id = "ami-809f84e6"
  ecs_launch_configuration_security_groups_ids = ["${module.security_group_ecs_instances.aws_security_group_id}","${module.security_group_efs.aws_security_group_id}"]

  ecs_aws_autoscaling_group_availability_zones = [
    "eu-west-1a",
    "eu-west-1b",
    "eu-west-1c",
  ]
  ecs_aws_autoscaling_group_name = "ecs-demo-instances"
  ecs_aws_autoscaling_group_subnet_ids = ["${module.network.private_subnet_ids}"]
  ecs_aws_autoscaling_group_min_size = 2
  ecs_aws_autoscaling_group_max_size = 5
  ecs_aws_autoscaling_group_desired_capacity  = 2
}
/* END ECS --------------------------------- */

/* START ELB ------------------------------- */
module "elb" {
  source = "../../modules/balancers/elb"
  name = "${var.cluster_name}-elb"
  subnet_ids = ["${module.network.public_subnet_ids}"]
  security_group_ids = ["${module.security_group_elb.aws_security_group_id}"]
}
/* START ELB ------------------------------- */
