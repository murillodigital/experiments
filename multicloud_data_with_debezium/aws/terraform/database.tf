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

resource "null_resource" "create_inventory_db" {
  depends_on = [aws_db_instance.inventory_psql]
  provisioner "local-exec" {
    command = "psql -h ${aws_db_instance.inventory_psql.address} -p 5432 -U \"${var.db_username}\" -d ${var.db_name} -f - \"${templatefile("./templates/initialize.sql.tpl", { table_name = var.db_name })}\""
    environment = {
      PGPASSWORD = var.db_password
    }
  }
}