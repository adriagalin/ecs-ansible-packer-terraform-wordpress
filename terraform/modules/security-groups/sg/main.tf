variable "name" {}
variable "vpc_id" {}

resource "aws_security_group" "main" {
  name        = "${var.name}"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name   = "${var.name}"
  }
}

output "aws_security_group_id" {
  value = "${aws_security_group.main.id}"
}
