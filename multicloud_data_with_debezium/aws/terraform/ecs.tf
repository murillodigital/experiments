
resource "aws_iam_role" "debezium_fargate_iam_role" {
  name               = "murillodigital-debezium-fargate-iam-role"
  assume_role_policy = data.aws_iam_policy_document.debezium_fargate_iam_policy.json
}

data "aws_iam_policy_document" "debezium_fargate_iam_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "debezium_fargate_iam_policy_attachment" {
  role       = aws_iam_role.debezium_fargate_iam_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_lb" "debezium_lb" {
  name = "murillodigitaldebeziumlb"
  subnets = [
    aws_subnet.debezium-subnet-az1-public.id,
    aws_subnet.debezium-subnet-az2-private.id,
    aws_subnet.debezium-subnet-az3-private.id,
    aws_subnet.debezium-subnet-az4-public.id
  ]
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.debezium_external_sg.id
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
  name = "murillodigital-debezium-tg"
  port = 8083
  protocol = "HTTP"
  vpc_id = aws_vpc.debezium-vpc.id
  target_type = "ip"
}

resource "aws_ecs_cluster" "debezium_ecs" {
  name = "murillodigital-debezium-ecs"
  capacity_providers = ["FARGATE"]
}

resource "aws_cloudwatch_log_group" "debezium_log_group" {
  name = "/ecs/debezium_testing"
}

resource "aws_ecs_task_definition" "debezium_task" {
  family = "murillodigital-debezium-task-definitiojn"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = 512
  memory = 2048
  tags = {}
  execution_role_arn = aws_iam_role.debezium_fargate_iam_role.arn
  container_definitions = templatefile("./templates/task_definition.json.tpl", { bootstrap_servers = aws_msk_cluster.debezium_msk_cluster.bootstrap_brokers })
}

resource "aws_ecs_service" "debezium_service" {
  name = "murillodigital-debezium-service"
  cluster = aws_ecs_cluster.debezium_ecs.id
  task_definition = aws_ecs_task_definition.debezium_task.arn
  desired_count = 1
  launch_type = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.debezium_internal_sg.id]
    subnets = [aws_subnet.debezium-subnet-az2-private.id, aws_subnet.debezium-subnet-az3-private.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.debezium_targets.arn
    container_name = "debezium"
    container_port = 8083
  }
}
