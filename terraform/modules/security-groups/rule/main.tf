variable "type" { default = "ingress" }
variable "from_port" { default = 0 }
variable "to_port" { default = 0 }
variable "protocol" { default = "tcp" }
variable "cidr_blocks" { type = "list" }
variable "security_group_id" {}
variable "source_security_group_id" { default = "" }
variable "use_cidr_blocks" { default = true }
variable "use_source_security_group" { default = false }


resource "aws_security_group_rule" "main" {
  type              = "${var.type}"
  from_port         = "${var.from_port}"
  to_port           = "${var.to_port}"
  protocol          = "${var.protocol}"
  cidr_blocks       = ["${var.cidr_blocks}"]
  security_group_id = "${var.security_group_id}"
}
