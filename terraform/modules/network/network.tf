module "vpc" {
  source = "vpc"
  cidr_block = "${var.cidr_block}"
  cluster_name = "${var.cluster_name}"
  cluster_id = "${var.cluster_id}"
}

module "public_subnets" {
  source = "subnet"
  vpc_id = "${module.vpc.vpc_id}"
  vpc_cidr_block = "${module.vpc.cidr_block}"
  internet_gateway_id = "${module.vpc.internet_gateway_id}"
  subnet_name = "${var.public_subnet_name}"
  subnets_az_count = "${var.public_subnets_az_count}" // TODO: add extra az
  is_public = "${var.public_is_public}"
  subnets = ["${var.public_subnets}"]
  subnets_azs = ["${var.public_subnets_azs}"]
  cluster_name = "${var.cluster_name}"
  cluster_id = "${var.cluster_id}"
}

module "private_subnets" {
  source = "subnet"
  vpc_id = "${module.vpc.vpc_id}"
  vpc_cidr_block = "${module.vpc.cidr_block}"
  subnet_name = "${var.private_subnet_name}"
  subnets_az_count = "${var.private_subnets_az_count}" // TODO: add extra az
  is_public = "${var.private_is_public}"
  subnets = ["${var.private_subnets}"]
  subnets_azs = ["${var.private_subnets_azs}"]
  cluster_name = "${var.cluster_name}"
  cluster_id = "${var.cluster_id}"
  nat_gateway_ids = ["${module.public_subnets.nat_gateway_ids}"]
}
