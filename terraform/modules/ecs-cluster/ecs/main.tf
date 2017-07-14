variable "name" { default = "default" }

resource "aws_ecs_cluster" "main" {
  name = "${var.name}"
}

output "aws_ecs_cluster_main_id" {
  value = "${aws_ecs_cluster.main.id}"
}
