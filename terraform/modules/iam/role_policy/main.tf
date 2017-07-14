variable "name" {}
variable "role_id" {}
variable "policy" {}

resource "aws_iam_role_policy" "main" {
  name = "${var.name}"
  role = "${var.role_id}"
  policy = "${var.policy}"
}

output "id" {
  value = "${aws_iam_role_policy.main.id}"
}
output "name" {
  value = "${aws_iam_role_policy.main.name}"
}
