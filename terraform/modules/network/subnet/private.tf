resource "aws_route_table" "private" {
  count = "${var.is_public ? 0 : var.subnets_az_count}"
  vpc_id = "${var.vpc_id}"

  tags = "${merge(map(
    "Name", "${var.cluster_name}-${var.subnet_name}-${var.subnets_azs[count.index]}",
    "Cluster", "${var.cluster_id}"
  ), var.extra_tags)}"
}

resource "aws_route" "to_nat_gateway" {
  count = "${var.is_public ? 0 : var.subnets_az_count}"
  route_table_id         = "${aws_route_table.private.*.id[count.index]}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(var.nat_gateway_ids, count.index)}"
  depends_on             = ["aws_route_table.private"]
}

resource "aws_route_table_association" "private_routing" {
  count = "${var.is_public ? 0 : var.subnets_az_count}"
  route_table_id = "${aws_route_table.private.*.id[count.index]}"
  subnet_id      = "${aws_subnet.subnet.*.id[count.index]}"
}
