provider "aws" {}

resource "aws_default_vpc" "default_vpc" { }

resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-east-1a"
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = "us-east-1b"
}

resource "aws_default_security_group" "default_sg" {
  vpc_id = aws_default_vpc.default_vpc.id
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
      aws_default_security_group.default_sg.id]
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.kms.arn
  }
}

output "zookeeper_connect_string" {
  value = aws_msk_cluster.inventory_stream.zookeeper_connect_string
}

output "bootstrap_brokers" {
  description = "Plaintext connection host:port pairs"
  value       = aws_msk_cluster.inventory_stream.bootstrap_brokers
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
  username = "murillodigital"
  password = "notmypwd"
  parameter_group_name = aws_db_parameter_group.debezium_parameters.name
  skip_final_snapshot = true
  availability_zone = "us-east-1a"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "debezium_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  vpc_security_group_ids = [aws_default_security_group.default_sg.id]
}