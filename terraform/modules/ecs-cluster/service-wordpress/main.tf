data "template_file" "wordpress_task" {
  template = "${file("${path.module}/task-definitions/service.json")}"
  vars {
    name = "${var.service_name}"
    essential = "${var.service_essential}"
    memory = "${var.service_memory}"
    cpu = "${var.service_cpu}"
    repository_url = "${var.service_repository_url}"
    image_tag = "${var.service_image_tag}"
    command = "${var.service_command}"
    container_path = "${var.service_container_path}"
    source_volume = "${var.service_source_volume}"
    host_port = "${var.service_host_port}"
    container_port = "${var.service_container_port}"
    protocol = "${var.service_protocol}"
    wordpress_db_host = "${var.wordpress_db_host}"
    wordpress_db_name = "${var.wordpress_db_name}"
    wordpress_db_user = "${var.wordpress_db_user}"
    wordpress_db_password = "${var.wordpress_db_password}"
  }
}

resource "aws_ecs_task_definition" "wordpress" {
  family = "${var.task_definition_family_name}"
  container_definitions = "${data.template_file.wordpress_task.rendered}"
  volume {
    name = "${var.task_definition_volume_name}"
    host_path = "${var.task_definition_volume_path}"
  }
  // TODO: placement_constraints and add other options.
}

resource "aws_ecs_service" "main" {
    name = "${var.name}"
    cluster = "${var.cluster_id}"
    task_definition = "${aws_ecs_task_definition.wordpress.arn}"
    desired_count = "${var.desired_count}"
    deployment_minimum_healthy_percent = "${var.minimum_healthy_percent}"
    iam_role = "${var.iam_role_arn}"

    load_balancer {
        elb_name = "${var.elb_name}"
        container_name = "${var.container_name}"
        container_port = "${var.container_port}"
    }

    // TODO:   iam_role        = "${aws_iam_role.foo.arn}" depends_on      = ["aws_iam_role_policy.foo"]
    // TODO: placement_strategy
    // TODO: placement_constraints
    // TODO: Add logs
    // TODO: Add healthy checks
    // TODO: Add ALB conditional
}
