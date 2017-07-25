output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "public_subnet_ids" {
  value = "${module.public_subnets.subnet_ids}"
}

output "public_subnet_cidr_blocks" {
  value = "${module.public_subnets.subnet_cidr_blocks}"
}

output "nat_gateway_ids" {
  value = "${module.public_subnets.nat_gateway_ids}"
}

output "private_subnet_ids" {
  value = "${module.private_subnets.subnet_ids}"
}

output "private_subnet_cidr_blocks" {
  value = "${module.private_subnets.subnet_cidr_blocks}"
}
