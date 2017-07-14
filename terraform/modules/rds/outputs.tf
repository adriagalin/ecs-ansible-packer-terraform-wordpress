output "subnet_group" {
  value = "${aws_db_subnet_group.rds.name}"
}
output "db_instance_id" {
  value = "${aws_db_instance.rds.id}"
}
output "db_instance_address" {
  value = "${aws_db_instance.rds.address}"
}
output "db_security_group" {
  value = "${aws_security_group.rds.id}"
}
