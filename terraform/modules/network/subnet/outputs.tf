output "subnet_ids" {
  value = ["${aws_subnet.subnet.*.id}"]
}

output "subnet_cidr_blocks" {
  value = ["${aws_subnet.subnet.*.cidr_block}"]
}

output "nat_gateway_ids" {
  value = ["${split(",", var.is_public ? join(",", aws_nat_gateway.nat_gateway.*.id) : "")}"]
}
