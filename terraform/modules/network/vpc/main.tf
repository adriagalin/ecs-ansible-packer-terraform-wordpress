variable "vpc_cidr" { default = "172.31.0.0/16" }
variable "enable_dns_hostnames" { default = true }
variable "tag_name" {}

resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = "${var.enable_dns_hostnames}"
  tags {
    Name = "${var.tag_name}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "${var.tag_name} gw"
  }
}
