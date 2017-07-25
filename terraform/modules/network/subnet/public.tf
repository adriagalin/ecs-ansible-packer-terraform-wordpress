resource "aws_route_table" "public" {
  count = "${var.is_public}"
  vpc_id = "${var.vpc_id}"

  tags = "${merge(map(
    "Name", "${var.cluster_name}-${var.subnet_name}",
    "Cluster", "${var.cluster_id}"
  ), var.extra_tags)}"
}

resource "aws_main_route_table_association" "main_routing" {
  count = "${var.is_public}"
  vpc_id = "${var.vpc_id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route" "main_gateway_route" {
  count = "${var.is_public}"
  destination_cidr_block = "0.0.0.0/0"
  route_table_id = "${aws_route_table.public.id}"
  gateway_id = "${var.internet_gateway_id}"
}

resource "aws_route_table_association" "public_routing" {
  count = "${var.is_public ? "${length(var.subnets) > 1 ? length(var.subnets) : var.subnets_az_count}" : 0}"
  route_table_id = "${aws_route_table.public.id}"
  subnet_id = "${aws_subnet.subnet.*.id[count.index]}"
}

resource "aws_eip" "nat_gateway_eip" {
  count = "${var.is_public ? length(var.subnets) : 0}"
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  count = "${var.is_public ? var.subnets_az_count : 0}"
  allocation_id = "${aws_eip.nat_gateway_eip.*.id[count.index]}"
  subnet_id = "${aws_subnet.subnet.*.id[count.index]}"
}
