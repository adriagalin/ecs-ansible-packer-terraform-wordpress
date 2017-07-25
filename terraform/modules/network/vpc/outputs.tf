output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "cidr_block" {
  value = "${aws_vpc.vpc.cidr_block}"
}

output "internet_gateway_id" {
  value = "${aws_internet_gateway.igw.id}"
}
