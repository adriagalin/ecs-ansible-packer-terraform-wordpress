variable "vpc_id" {
  type = "string"
}

variable "vpc_cidr_block" {
  type = "string"
}

variable "map_public_ip_on_launch" {
  default = true
}

variable "nat_gateway_ids" {
  type = "list"
  default = []
}

variable "is_public" {
  default = false
}

variable "internet_gateway_id" {
  type = "string"
  default = ""
}

variable "subnet_name" {
  type = "string"
}

variable "subnets_az_count" {
  type = "string"
}

variable "subnets" {
  type = "list"
}

variable "subnets_azs" {
  type = "list"
}

variable "cluster_name" {
  type = "string"
}

variable "cluster_id" {
  type = "string"
}

variable "extra_tags" {
  type = "map"
  default = {}
}
