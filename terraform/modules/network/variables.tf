variable "cidr_block" {
  type = "string"
}

variable "cluster_name" {
  type = "string"
}

variable "cluster_id" {
  type = "string"
}

variable "public_subnet_name" {
  type = "string"
}

variable "public_subnets_az_count" {
  type = "string"
}

variable "public_is_public" {
  default = true
}

variable "public_subnets" {
  type = "list"
}

variable "public_subnets_azs" {
  type = "list"
}

variable "private_subnet_name" {
  type = "string"
}

variable "private_subnets_az_count" {
  type = "string"
}

variable "private_is_public" {
  default = false
}

variable "private_subnets" {
  type = "list"
}

variable "private_subnets_azs" {
  type = "list"
}
