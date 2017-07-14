/* START NETWORK ------------------------------- */
module "vpc" {
  source = "../../modules/network/vpc"
  vpc_cidr = "12.0.0.0/16"
  tag_name = "${var.name}-vpc"
}

// TODO: Create subnets with loop
module "public_subnet_az1" {
  source = "../../modules/network/subnet"
  vpc_id = "${module.vpc.aws_vpc_id}"
  subnet_cidr = "12.0.0.0/24"
  subnet_zone = "eu-west-1a"
  tag_name = "${var.name}-public-subnet-az1"
  route_table_cidr_block = "0.0.0.0/0"
  route_table_gateway_id = "${module.vpc.aws_internet_gateway_id}"
}
module "public_subnet_az2" {
  source = "../../modules/network/subnet"
  vpc_id = "${module.vpc.aws_vpc_id}"
  subnet_cidr = "12.0.1.0/24"
  subnet_zone = "eu-west-1b"
  tag_name = "${var.name}-public-subnet-az2"
  route_table_cidr_block = "0.0.0.0/0"
  route_table_gateway_id = "${module.vpc.aws_internet_gateway_id}"
}
module "public_subnet_az3" {
  source = "../../modules/network/subnet"
  vpc_id = "${module.vpc.aws_vpc_id}"
  subnet_cidr = "12.0.2.0/24"
  subnet_zone = "eu-west-1c"
  tag_name = "${var.name}-public-subnet-az3"
  route_table_cidr_block = "0.0.0.0/0"
  route_table_gateway_id = "${module.vpc.aws_internet_gateway_id}"
}
module "private_subnet_az1" {
  create_nat_gateway = true
  source = "../../modules/network/subnet"
  vpc_id = "${module.vpc.aws_vpc_id}"
  subnet_cidr = "12.0.7.0/24"
  subnet_zone = "eu-west-1a"
  tag_name = "${var.name}-private-subnet-az1"
  route_table_cidr_block = "0.0.0.0/0"
  nat_gateway_subnet_id = "${module.public_subnet_az1.aws_subnet_id}"
}
module "private_subnet_az2" {
  create_nat_gateway = true
  source = "../../modules/network/subnet"
  vpc_id = "${module.vpc.aws_vpc_id}"
  subnet_cidr = "12.0.8.0/24"
  subnet_zone = "eu-west-1b"
  tag_name = "${var.name}-private-subnet-az2"
  route_table_cidr_block = "0.0.0.0/0"
  nat_gateway_subnet_id = "${module.public_subnet_az2.aws_subnet_id}"
}
module "private_subnet_az3" {
  create_nat_gateway = true
  source = "../../modules/network/subnet"
  vpc_id = "${module.vpc.aws_vpc_id}"
  subnet_cidr = "12.0.9.0/24"
  subnet_zone = "eu-west-1c"
  tag_name = "${var.name}-private-subnet-az3"
  route_table_cidr_block = "0.0.0.0/0"
  nat_gateway_subnet_id = "${module.public_subnet_az3.aws_subnet_id}"
}
/* END NETWORK ---------------------------------- */

/* START SG ------------------------------- */
// TODO: Add more specific security group and more customizable module: ecs (only ingress), elb (only egress), ec2 (ingress, egress), rds, etc
module "security_group_elb" {
  source = "../../modules/security-groups/sg"
  name = "${var.name}-elb-sg"
  vpc_id = "${module.vpc.aws_vpc_id}"
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
  cidr_blocks = [
    "${module.private_subnet_az1.aws_subnet_cidr_block}",
    "${module.private_subnet_az2.aws_subnet_cidr_block}",
    "${module.private_subnet_az3.aws_subnet_cidr_block}"
  ]
  security_group_id = "${module.security_group_elb.aws_security_group_id}"
}

module "security_group_efs" {
  source = "../../modules/security-groups/sg"
  name = "${var.name}-efs-sg"
  vpc_id = "${module.vpc.aws_vpc_id}"
}

module "security_group_efs_group_rule_allow_2049" {
  source = "../../modules/security-groups/rule"
  type = "ingress"
  from_port = 2049
  to_port = 2049
  protocol = "tcp"
  cidr_blocks = [
    "${module.private_subnet_az1.aws_subnet_cidr_block}",
    "${module.private_subnet_az2.aws_subnet_cidr_block}",
    "${module.private_subnet_az3.aws_subnet_cidr_block}"
  ]
  security_group_id = "${module.security_group_efs.aws_security_group_id}"
}

module "security_group_ecs_instances" {
  source = "../../modules/security-groups/sg"
  name = "${var.name}-ecs-sg"
  vpc_id = "${module.vpc.aws_vpc_id}"
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
module "security_group_ecs_group_rule_allow_22" {
  source = "../../modules/security-groups/rule"
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  # cidr_blocks = ["0.0.0.0/0"]
  cidr_blocks = [
    "${module.public_subnet_az1.aws_subnet_cidr_block}",
    "${module.public_subnet_az2.aws_subnet_cidr_block}",
    "${module.public_subnet_az3.aws_subnet_cidr_block}",
    "${module.private_subnet_az1.aws_subnet_cidr_block}",
    "${module.private_subnet_az2.aws_subnet_cidr_block}",
    "${module.private_subnet_az3.aws_subnet_cidr_block}"
  ]
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
  subnet_ids = ["${module.private_subnet_az1.aws_subnet_id}","${module.private_subnet_az2.aws_subnet_id}","${module.private_subnet_az3.aws_subnet_id}"]
  identifier = "wordpress-rds"
  allocated_storage = 5
  engine = "mysql"
  engine_version = "5.7.17"
  instance_class = "db.t2.micro"
  db_name = "wordpress"
  db_username = "wordpress"
  db_password = "s3cr3ts3cr3t"
  parameter_group_name = "default.mysql5.7"
  vpc_id = "${module.vpc.aws_vpc_id}"
  ingress_from_port = 3306
  ingress_to_port = 3306
  ingress_to_protocol = "tcp"
  ingress_cidr_blocks = ["${module.private_subnet_az1.aws_subnet_cidr_block}","${module.private_subnet_az2.aws_subnet_cidr_block}","${module.private_subnet_az3.aws_subnet_cidr_block}"]
}
/* END RDS --------------------------------- */

/* START ECS ------------------------------- */
module "ecs_registry" {
  source = "../../modules/ecr-repository"
  name = "wordpress"
}

module "ecs_cluster" {
  source = "../../modules/ecs-cluster"
  ecs_cluster_name = "${var.name}"

  efs_creation_token = "${var.name}"
  efs_tag_name = "${var.name}-efs"
  efs_subnets_ids = [
    "${module.private_subnet_az1.aws_subnet_id}",
    "${module.private_subnet_az2.aws_subnet_id}",
    "${module.private_subnet_az3.aws_subnet_id}"
  ]
  efs_subnets_count = 3
  efs_security_groups = ["${module.security_group_efs.aws_security_group_id}"]

  ecs_efs_name = "${var.name}-efs"
  ecs_service_data_dir = "/var/www/html/wordpress/" # /var/www/html/efs-mount-point/
  ecs_launch_configuration_prefix_name = "${var.name}"
  ecs_launch_configuration_ami_id = "ami-809f84e6"
  ecs_launch_configuration_security_groups_ids = ["${module.security_group_ecs_instances.aws_security_group_id}","${module.security_group_efs.aws_security_group_id}"]

  ecs_aws_autoscaling_group_availability_zones = [
    "eu-west-1a",
    "eu-west-1b",
    "eu-west-1c",
  ]
  ecs_aws_autoscaling_group_name = "ecs-demo-instances"
  ecs_aws_autoscaling_group_subnet_ids = [
    "${module.private_subnet_az1.aws_subnet_id}",
    "${module.private_subnet_az2.aws_subnet_id}",
    "${module.private_subnet_az3.aws_subnet_id}"
  ]
  ecs_aws_autoscaling_group_min_size = 1
  ecs_aws_autoscaling_group_max_size = 5
  ecs_aws_autoscaling_group_desired_capacity  = 2
}
/* END ECS --------------------------------- */

/* START ELB ------------------------------- */
module "elb" {
  source = "../../modules/balancers/elb"
  name = "${var.name}-elb"
  subnet_ids = [
    "${module.public_subnet_az1.aws_subnet_id}",
    "${module.public_subnet_az2.aws_subnet_id}",
    "${module.public_subnet_az3.aws_subnet_id}"
  ]
  security_group_ids = ["${module.security_group_elb.aws_security_group_id}"]
}
/* START ELB ------------------------------- */
