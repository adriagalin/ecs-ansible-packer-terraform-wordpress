resource "aws_subnet" "subnet" {
  count = "${length(var.subnets) > 1 ? length(var.subnets) : var.subnets_az_count}"

  vpc_id = "${var.vpc_id}"

  cidr_block = "${length(var.subnets) > 1 ?
    "${element(var.subnets, count.index)}" :
    "${cidrsubnet(var.vpc_cidr_block, 6, count.index)}"
  }"

  availability_zone = "${var.subnets_azs[count.index]}"

  map_public_ip_on_launch = "${var.map_public_ip_on_launch}"

  tags = "${merge(map(
    "Name", "${var.cluster_name}-${var.subnet_name}-${var.subnets_azs[count.index]}",
    "Cluster", "${var.cluster_id}"
  ), var.extra_tags)}"
}
