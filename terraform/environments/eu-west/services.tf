# // TODO: Create generic services, add terraform remote state and then gets iam_role_service, cluster ecs, rds etc
module "wordpress_service" {
  source = "../../modules/ecs-cluster/service-wordpress"
  name = "wordpress"
  desired_count = 2
  cluster_id = "${module.ecs_cluster.ecs_cluster_id}"
  iam_role_arn = "${module.ecs_cluster.ecs_service_role_arn}"
  elb_name = "${module.elb.elb_name}"
  container_name = "wordpress"
  container_port = 80

  task_definition_family_name = "wordpress"
  task_definition_volume_name = "efs-data"
  task_definition_volume_path = "/var/www/html/wordpress/"

  service_name = "wordpress"
  service_essential = true
  service_memory = 500
  service_cpu = 512
  service_repository_url = "${module.ecs_registry.url}"
  service_image_tag = "latest"
  service_command = "apachectl -D FOREGROUND"
  service_container_path = "/var/www/html/wordpress/"
  service_source_volume = "efs-data"
  service_host_port = 80
  service_container_port = 80
  service_protocol = "tcp"
  wordpress_db_host = "${module.wordpress_rds.db_instance_address}"
  wordpress_db_name = "wordpress"
  wordpress_db_user = "wordpress"
  wordpress_db_password = "s3cr3ts3cr3t"
}
