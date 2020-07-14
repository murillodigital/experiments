provider "aws" {
  region = "us-east-1"
}

variable "db_username" {
  type = string
  default = "murillodigital"
}

variable "db_password" {
  type = string
  default = "notmyrealpwd"
}

variable "db_name" {
  type = string
  default = "inventory"
}

resource "aws_default_vpc" "default_vpc" { }

resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-east-1a"
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = "us-east-1b"
}

resource "aws_security_group" "inventory_sg" {
  name = "murillodigital_debezium"
  description = "Demo SG for Debezium on Multicloud"
  vpc_id = aws_default_vpc.default_vpc.id

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 9094
    to_port = 9094
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_kms_key" "kms" {
  description = "inventory_key"
}

resource "aws_msk_cluster" "inventory_stream" {
  cluster_name           = "inventorystream"
  kafka_version          = "2.4.1"
  number_of_broker_nodes = 2

  broker_node_group_info {
    instance_type   = "kafka.t3.small"
    ebs_volume_size = 10
    client_subnets = [
      aws_default_subnet.default_az1.id,
      aws_default_subnet.default_az2.id
    ]
    security_groups = [
      aws_security_group.inventory_sg.id]
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.kms.arn
    encryption_in_transit {
      client_broker = "TLS"
    }
  }
}

resource "aws_db_parameter_group" "debezium_parameters" {
  name = "debeziumparams"
  family = "postgres12"

  parameter {
    name = "rds.logical_replication"
    value = "1"
    apply_method = "pending-reboot"
  }
}

resource "aws_db_instance" "inventory_psql" {
  allocated_storage = 10
  instance_class = "db.t2.micro"
  engine = "postgres"
  engine_version = "12.3"
  username = var.db_username
  password = var.db_password
  parameter_group_name = aws_db_parameter_group.debezium_parameters.name
  skip_final_snapshot = true
  availability_zone = "us-east-1a"
  name = var.db_name
  publicly_accessible = true
}

//resource "null_resource" "create_inventory_db" {
//  depends_on = [aws_db_instance.inventory_psql]
//  provisioner "local-exec" {
//    command = "psql -h ${aws_db_instance.inventory_psql.address} -p 5432 -U \"${var.db_username}\" -d ${var.db_name} -f \"./initialize.sql\""
//    environment = {
//      PGPASSWORD = var.db_password
//    }
//  }
//}

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
  cpu = 256
  memory = 1024
  tags = {}
  execution_role_arn = aws_iam_role.fargate_iam_role.arn
  container_definitions = templatefile("task_definition.json.tpl", { bootstrap_servers = aws_msk_cluster.inventory_stream.bootstrap_brokers_tls })
}

resource "aws_ecs_service" "debezium_service" {
  name = "debezium_service"
  cluster = aws_ecs_cluster.inventory_ecs.id
  task_definition = aws_ecs_task_definition.debezium_task.arn
  desired_count = 1
  launch_type = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.inventory_sg.id]
    subnets = [aws_default_subnet.default_az1.id,aws_default_subnet.default_az2.id]
    assign_public_ip = true
  }
}

output "zookeeper_connect_string" {
  value = aws_msk_cluster.inventory_stream.zookeeper_connect_string
}

output "bootstrap_brokers" {
  description = "Plaintext connection host:port pairs"
  value       = aws_msk_cluster.inventory_stream.bootstrap_brokers_tls
}

output "db_instance_address" {
  value = aws_db_instance.inventory_psql.address
}

//resource "null_resource" "create_debezium_connector" {
//  depends_on = [aws_db_instance.inventory_psql]
//  provisioner "local-exec" {
//    command = "curl -i -X POST -H \"Accept:application/json\" -H \"Content-Type:application/json\" localhost:8083/connectors/ --data '@psql-connector.json'"
//    environment = {
//      PGPASSWORD = var.db_password
//    }
//  }
//}