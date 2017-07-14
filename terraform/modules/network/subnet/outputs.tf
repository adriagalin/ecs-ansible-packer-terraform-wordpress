output "aws_subnet_id" {
  value = "${aws_subnet.subnet.id}"
}
output "aws_subnet_cidr_block" {
  value = "${aws_subnet.subnet.cidr_block}"
}

// TODO: part from count loop
# output "subnets_ids" {
#   value = ["${aws_subnet.subnet.*.id}"]
# }
