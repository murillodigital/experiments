resource "aws_db_parameter_group" "debezium_db_parameter_group" {
  name = "murillodigitaldebeziumdbparams"
  family = "postgres12"

  parameter {
    name = "rds.logical_replication"
    value = "1"
    apply_method = "pending-reboot"
  }
}

resource "aws_db_subnet_group" "debezium_db_subnet_group" {
  name = "murillodigital-debezium-db-subnetgroup"
  subnet_ids = [
    aws_subnet.debezium-subnet-az2-private.id,
    aws_subnet.debezium-subnet-az3-private.id
  ]
}

resource "aws_db_instance" "debezium_db" {
  tags = {
    name = "murillodigital-debezium-database"
  }
  allocated_storage = 10
  instance_class = "db.t2.micro"
  engine = "postgres"
  engine_version = "12.3"
  username = var.db_username
  password = var.db_password
  parameter_group_name = aws_db_parameter_group.debezium_db_parameter_group.name
  skip_final_snapshot = true
  availability_zone = aws_subnet.debezium-subnet-az2-private.availability_zone
  name = var.db_name
  publicly_accessible = false
  db_subnet_group_name = aws_db_subnet_group.debezium_db_subnet_group.name
  vpc_security_group_ids = [
    aws_security_group.debezium_internal_sg.id
  ]
}