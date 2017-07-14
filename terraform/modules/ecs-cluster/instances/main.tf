variable "ecs_cluster_name" {}
variable "service_data_dir" {}
variable "efs_name" {}

variable "launch_configuration_prefix_name" {}
variable "launch_configuration_ami_id" {}
variable "launch_configuration_instance_type" { default = "t2.micro" }
variable "launch_configuration_instance_profile" {}
variable "launch_configuration_security_groups_ids" { type = "list" }

variable "aws_autoscaling_group_availability_zones" { default = [] }
variable "aws_autoscaling_group_name" {}
variable "aws_autoscaling_group_subnet_ids" { default = [] }
variable "aws_autoscaling_group_min_size" { default = 1 }
variable "aws_autoscaling_group_max_size" { default = 5 }
variable "aws_autoscaling_group_health_check_grace_period" { default = 300 }
variable "aws_autoscaling_group_health_check_type" { default = "ELB" } //EC2
variable "aws_autoscaling_group_desired_capacity" { default = 1 }

// TODO: Add data search resource for AMI: https://www.terraform.io/docs/providers/aws/d/ami.html

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.sh")}"
  vars {
    ecs_cluster_name = "${var.ecs_cluster_name}"
    efs_name = "${var.efs_name}"
    service_data_dir = "${var.service_data_dir}"
  }
}

resource "aws_launch_configuration" "ecs_instance" {
  name_prefix = "${var.launch_configuration_prefix_name}-"
  image_id = "${var.launch_configuration_ami_id}"
  instance_type = "${var.launch_configuration_instance_type}"

  iam_instance_profile = "${var.launch_configuration_instance_profile}"

  security_groups = ["${var.launch_configuration_security_groups_ids}"]

  user_data = "${data.template_file.user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

// TODO: aws_placement_group
resource "aws_autoscaling_group" "ecs_cluster" {
  name = "${var.aws_autoscaling_group_name}"
  max_size = "${var.aws_autoscaling_group_max_size}"
  min_size = "${var.aws_autoscaling_group_min_size}"
  health_check_grace_period = "${var.aws_autoscaling_group_health_check_grace_period}"
  health_check_type         = "${var.aws_autoscaling_group_health_check_type}"
  desired_capacity          = "${var.aws_autoscaling_group_desired_capacity}"

  launch_configuration = "${aws_launch_configuration.ecs_instance.name}"

  vpc_zone_identifier = ["${var.aws_autoscaling_group_subnet_ids}"]

  tag {
    key = "Name"
    value = "${var.aws_autoscaling_group_name}"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
    # ignore_changes = ["image_id"] # TODO: review
  }
  // TODO: Add more configuration options.
}
// TODO: Add AWS autoscaling policies: UP, DOWN, etc.
// TODO: Add AWS cloudwatch metrics alarms.
