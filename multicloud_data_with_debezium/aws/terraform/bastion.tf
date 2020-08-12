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

data "template_file" "debezium_sql_initializer" {
  template = file("${path.module}/templates/initialize.sql.tpl")
  vars = {
    table_name = var.db_name
  }
}

data "template_file" "connector_initializer" {
  template = file("${path.module}/templates/psql-connector.json.tpl")
  vars = {
    database_hostname = aws_db_instance.debezium_db.address
    database_user = var.db_username
    database_password = var.db_password
  }
}

resource "aws_instance" "debezium_bastion_host" {
  depends_on = [
    aws_db_instance.debezium_db,
    aws_ecs_service.debezium_service,
    aws_msk_cluster.debezium_msk_cluster
  ]
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  subnet_id = aws_subnet.debezium-subnet-az1-public.id

  key_name = var.bastion_key_name

  vpc_security_group_ids = [
    aws_security_group.debezium_external_sg.id,
    aws_security_group.debezium_internal_sg.id
  ]

  associate_public_ip_address = true

  user_data = <<EOF
#!/bin/bash
echo '${replace(data.template_file.connector_initializer.rendered, "\n", " ")}' > /tmp/connector.json
echo '${replace(data.template_file.debezium_sql_initializer.rendered, "\n", " ")}' > /tmp/initializer.sql
sudo apt update
sudo apt install -y wget
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
sudo apt update
sudo apt -y install postgresql-client-12
sleep 120
PGPASSWORD="${var.db_password}" psql -h ${aws_db_instance.debezium_db.address} -p 5432 -U "${var.db_username}" -d ${var.db_name} -f "/tmp/initializer.sql"
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" ${aws_lb.debezium_lb.dns_name}/connectors/ --data "@/tmp/connector.json"
EOF

  tags = {
    name = "murillodigital-debezium-bastion"
  }
}