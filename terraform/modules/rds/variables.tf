variable "subnet_ids" { type = "list" }
variable "identifier" {}
variable "allocated_storage" { default = 5 }
variable "engine" { default = "mysql" }
variable "engine_version" { default = "5.7.17" }
variable "instance_class" { default = "db.t2.micro" }
variable "db_name" {}
variable "db_username" {}
variable "db_password" {}
variable "parameter_group_name" { default = "default.mysql5.7" }
variable "vpc_id" {}
variable "ingress_from_port" {}
variable "ingress_to_port" {}
variable "ingress_to_protocol" {}
variable "ingress_cidr_blocks" { type = "list" }
