variable "name" {}
variable "desired_count" { default = 1 }
variable "minimum_healthy_percent" { default = 50 }
variable "cluster_id" {}
variable "iam_role_arn" {}
variable "elb_name" {}
variable "container_name" {}
variable "container_port" { default = 80 }

variable "task_definition_family_name" {}
variable "task_definition_volume_name" { default = "efs-data" }
variable "task_definition_volume_path" { default = "/mnt/efs/data" }

variable "service_name" {}
variable "service_essential" { default = true }
variable "service_memory" { default = 1024 }
variable "service_cpu" { default = 1024 }
variable "service_repository_url" {}
variable "service_image_tag" { }
variable "service_command" { }
variable "service_container_path" { default = "/var/www/html/" }
variable "service_source_volume" {}
variable "service_host_port" { default = 80 }
variable "service_container_port" { default = 80 }
variable "service_protocol" { default = "tcp" }
variable "wordpress_db_host" {}
variable "wordpress_db_name" {}
variable "wordpress_db_user" {}
variable "wordpress_db_password" {}
