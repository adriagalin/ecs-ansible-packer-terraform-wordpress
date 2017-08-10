variable "cidr_block" {
  type = "string"
}

variable "enable_dns_hostnames" {
  default = true
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
