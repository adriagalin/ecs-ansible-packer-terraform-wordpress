output "ecr_repository" {
  value = "${module.ecs_registry.url}"
}

output "elb_dns" {
  value = "${module.elb.elb_dns_name}"
}
