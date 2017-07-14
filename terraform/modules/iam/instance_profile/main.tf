variable "name" {}
variable "role" {}

resource "aws_iam_instance_profile" "main" {
  name = "${var.name}"
  role = "${var.role}"
}

output "id" {
  value = "${aws_iam_instance_profile.main.id}"
}
output "name" {
  value = "${aws_iam_instance_profile.main.name}"
}
