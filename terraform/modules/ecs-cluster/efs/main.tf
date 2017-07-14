variable "creation_token" {}
variable "performance_mode" { default = "generalPurpose" }
variable "tag_name" { default = "data" }
variable "subnets_count" {}
variable "subnets_ids" { type = "list" } // Normally private subnets
variable "security_groups" { type = "list" }


resource "aws_efs_file_system" "main" {
  creation_token = "${var.creation_token}"
  performance_mode = "${var.performance_mode}"

  tags {
    Name = "${var.tag_name}"
  }
}

resource "aws_efs_mount_target" "main" {
  count = "${var.subnets_count}"
  file_system_id = "${aws_efs_file_system.main.id}"
  subnet_id = "${element(var.subnets_ids, count.index)}"
  security_groups = ["${var.security_groups}"]
}
