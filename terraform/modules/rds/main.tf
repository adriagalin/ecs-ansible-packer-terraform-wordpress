resource "aws_security_group" "rds" {
  name = "${var.db_name} - rds sg"
  vpc_id = "${var.vpc_id}"
  ingress {
      from_port = "${var.ingress_from_port}"
      to_port = "${var.ingress_to_port}"
      protocol = "${var.ingress_to_protocol}"
      cidr_blocks = ["${var.ingress_cidr_blocks}"]
  }
  egress {
      from_port = 1024
      to_port = 65535
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "Allow RDS"
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "${var.db_name} rds subnet group"
  subnet_ids = ["${var.subnet_ids}"]
  tags {
    Name = "${var.db_name}"
  }
}

resource "aws_db_instance" "rds" {
  identifier = "${var.identifier}"
  allocated_storage = "${var.allocated_storage}"
  engine = "${var.engine}"
  engine_version = "${var.engine_version}"
  instance_class = "${var.instance_class}"
  name = "${var.db_name}"
  username = "${var.db_username}"
  password = "${var.db_password}"
  vpc_security_group_ids = ["${aws_security_group.rds.id}"]
  db_subnet_group_name = "${aws_db_subnet_group.rds.id}"
  parameter_group_name = "${var.parameter_group_name}"
  skip_final_snapshot = true
  tags {
    Name = "${var.db_name}"
  }
  depends_on = ["aws_security_group.rds"]
}
