variable "name" { default = "default" }

resource "aws_ecr_repository" "main" {
  name = "${var.name}"
}

output "arn" {
  value = "${aws_ecr_repository.main.arn}"
}
output "id" {
  value = "${aws_ecr_repository.main.registry_id}"
}
output "url" {
  value = "${aws_ecr_repository.main.repository_url}"
}
