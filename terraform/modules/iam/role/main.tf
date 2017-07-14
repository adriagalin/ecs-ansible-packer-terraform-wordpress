variable "name" {}
variable "assume_role_policy" {}

resource "aws_iam_role" "main" {
  name = "${var.name}"
  assume_role_policy = "${var.assume_role_policy}"
}

output "id" {
  value = "${aws_iam_role.main.id}"
}
output "arn" {
  value = "${aws_iam_role.main.arn}"
}
output "name" {
  value = "${aws_iam_role.main.name}"
}
