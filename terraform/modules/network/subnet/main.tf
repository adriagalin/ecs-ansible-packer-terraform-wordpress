variable "vpc_id" {}
variable "subnet_cidr" {}
variable "subnet_zone" {}
variable "map_public_ip_on_launch" { default = false }
variable "tag_name" {}
variable "route_table_cidr_block" { default = "0.0.0.0/0" }
variable "route_table_gateway_id" { default = "" }
variable "create_nat_gateway" { default = false }
variable "nat_gateway_subnet_id" { default = "" }

# // TODO: Create subnets with count and bucle
# module "public_subnets" {
#   count = 3
#   source = "../../modules/network/subnet"
#   vpc_id = "${module.vpc.aws_vpc_id}"
#   subnet_cidr = ["172.31.0.0/24", "172.31.1.0/24", "172.31.2.0/24"]
#   subnet_zone = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
# }

resource "aws_subnet" "subnet" {
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${var.subnet_cidr}"
  availability_zone = "${var.subnet_zone}"
  map_public_ip_on_launch = "${var.map_public_ip_on_launch}"

  tags {
    Name = "${var.tag_name}"
  }
}

resource "aws_eip" "nat_gateway_ip" {
  count = "${var.create_nat_gateway}"
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  count = "${var.create_nat_gateway}"
  allocation_id = "${aws_eip.nat_gateway_ip.id}"
  subnet_id = "${var.nat_gateway_subnet_id}"
  depends_on = ["aws_subnet.subnet"]
}

/* Routing table for subnet */
resource "aws_route_table" "route_table" {
  count = "${var.create_nat_gateway}"
  vpc_id = "${var.vpc_id}"
  route {
    cidr_block = "${var.route_table_cidr_block}"
    gateway_id = "${aws_nat_gateway.nat_gateway.id}"
  }
  tags {
    Name = "${var.tag_name} - Routing Table"
  }
}
resource "aws_route_table" "route_table_main_gateway" {
  count = "${1 - var.create_nat_gateway}"
  vpc_id = "${var.vpc_id}"
  route {
    cidr_block = "${var.route_table_cidr_block}"
    gateway_id = "${var.route_table_gateway_id}"
  }
  tags {
    Name = "${var.tag_name} - Routing Table"
  }
}

/* Associate the routing table to subnet */
resource "aws_route_table_association" "route_table_association" {
  count = "${var.create_nat_gateway}"
  subnet_id = "${aws_subnet.subnet.id}"
  route_table_id = "${aws_route_table.route_table.id}"
}
resource "aws_route_table_association" "route_table_association_main_gateway" {
  count = "${1 - var.create_nat_gateway}"
  subnet_id = "${aws_subnet.subnet.id}"
  route_table_id = "${aws_route_table.route_table_main_gateway.id}"
}
