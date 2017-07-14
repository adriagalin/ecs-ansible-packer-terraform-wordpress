output "ecs_cluster_id" {
  value = "${module.ecs.aws_ecs_cluster_main_id}"
}
output "ecs_service_role_id" {
  value = "${module.iam_ecs_service_role.id}"
}
output "ecs_service_role_arn" {
  value = "${module.iam_ecs_service_role.arn}"
}
