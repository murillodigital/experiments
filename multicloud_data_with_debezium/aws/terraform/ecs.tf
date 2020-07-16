
resource "aws_iam_role" "fargate_iam_role" {
  name               = "debezium_fargate_role"
  assume_role_policy = data.aws_iam_policy_document.fargate_policy.json
}

data "aws_iam_policy_document" "fargate_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "fargate_policy_attachment" {
  role       = aws_iam_role.fargate_iam_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_lb" "debezium_lb" {
  name = "debeziumalb"
  subnets = [
    aws_default_subnet.default_az1.id,
    aws_default_subnet.default_az2.id,
    aws_default_subnet.default_az3.id
  ]
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.external_sg.id
  ]
}

resource "aws_lb_listener" "debezium_listener" {
  load_balancer_arn = aws_lb.debezium_lb.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.debezium_targets.arn
  }
}

resource "aws_lb_target_group" "debezium_targets" {
  name = "debezium-alb-tg"
  port = 8083
  protocol = "HTTP"
  vpc_id = aws_default_vpc.default_vpc.id
  target_type = "ip"
}

resource "aws_ecs_cluster" "inventory_ecs" {
  name = "inventory_ecs"
  capacity_providers = ["FARGATE"]
}

resource "aws_cloudwatch_log_group" "debezium_log_group" {
  name = "/ecs/debezium_testing"
}

resource "aws_ecs_task_definition" "debezium_task" {
  family = "debezium_task"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = 512
  memory = 2048
  tags = {}
  execution_role_arn = aws_iam_role.fargate_iam_role.arn
  container_definitions = templatefile("./templates/task_definition.json.tpl", { bootstrap_servers = aws_msk_cluster.inventory_stream.bootstrap_brokers })
}

resource "aws_ecs_service" "debezium_service" {
  name = "debezium_service"
  cluster = aws_ecs_cluster.inventory_ecs.id
  task_definition = aws_ecs_task_definition.debezium_task.arn
  desired_count = 1
  launch_type = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.internal_sg.id]
    subnets = [aws_default_subnet.default_az1.id,aws_default_subnet.default_az2.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.debezium_targets.arn
    container_name = "debezium"
    container_port = 8083
  }
}

//resource "null_resource" "create_debezium_connector" {
//  depends_on = [aws_db_instance.inventory_psql]
//  provisioner "local-exec" {
//    command = "curl -i -X POST -H \"Accept:application/json\" -H \"Content-Type:application/json\" ${aws_ecs_service.debezium_service.}:8083/connectors/ --data '@./templates/psql-connector.json'"
//  }
//}