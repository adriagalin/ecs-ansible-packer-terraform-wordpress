resource "aws_vpc" "vpc" {
  cidr_block = "${var.cidr_block}"
  enable_dns_hostnames = "${var.enable_dns_hostnames}"
  tags = "${merge(map(
    "Name", "${var.cluster_name}-vpc",
    "Cluster", "${var.cluster_id}"
  ), var.extra_tags)}"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = "${merge(map(
    "Name", "${var.cluster_name}-igw",
    "Cluster", "${var.cluster_id}"
  ), var.extra_tags)}"
}
