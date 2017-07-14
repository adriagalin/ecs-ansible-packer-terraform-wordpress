output "aws_vpc_id" {
  value = "${aws_vpc.main.id}"
}
output "aws_vpc_cidr_block" {
  value = "${aws_vpc.main.cidr_block}"
}
output "aws_internet_gateway_id" {
  value = "${aws_internet_gateway.main.id}"
}


