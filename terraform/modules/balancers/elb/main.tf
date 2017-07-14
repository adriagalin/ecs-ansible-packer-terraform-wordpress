variable "name" {}
variable "subnet_ids" { type = "list" }
variable "security_group_ids" { type = "list" }
# variable "instance_ids" {}
# variable "ssl_certificate_id" {}

// TODO: More customizable module
resource "aws_elb" "main" {
  name = "${var.name}"
  subnets = ["${var.subnet_ids}"]
  security_groups = ["${var.security_group_ids}"]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 10
    unhealthy_threshold = 2
    timeout = 5
    target = "HTTP:80/health"
    interval = 30
  }

  //instances = ["${split(",", var.instance_ids)}"]

  cross_zone_load_balancing = true
  idle_timeout = 60
  connection_draining = true
  connection_draining_timeout = 300

  tags {
    Name = "${var.name}"
  }
}
