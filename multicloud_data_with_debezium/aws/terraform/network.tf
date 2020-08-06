data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "debezium-vpc" {
  cidr_block = "10.100.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "debezium-vpc"
  }
}

resource "aws_subnet" "debezium-subnet-az1-public" {
  vpc_id = aws_vpc.debezium-vpc.id
  cidr_block = "10.100.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "debezium-subnet-az1-public"
  }
}

resource "aws_subnet" "debezium-subnet-az2-private" {
  vpc_id = aws_vpc.debezium-vpc.id
  cidr_block = "10.100.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "debezium-subnet-az2-private"
  }
}

resource "aws_subnet" "debezium-subnet-az3-private" {
  vpc_id = aws_vpc.debezium-vpc.id
  cidr_block = "10.100.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[2]

  tags = {
    Name = "debezium-subnet-az3-private"
  }
}

resource "aws_subnet" "debezium-subnet-az4-public" {
  vpc_id = aws_vpc.debezium-vpc.id
  cidr_block = "10.100.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[3]

  tags = {
    Name = "debezium-subnet-az4-public"
  }
}

resource "aws_route_table" "debezium-route-table-public" {
  vpc_id = aws_vpc.debezium-vpc.id
  tags = {
    Name = "debezium-route-table-public"
  }
}

resource "aws_route_table" "debezium-route-table-private" {
  vpc_id = aws_vpc.debezium-vpc.id
  tags = {
    Name = "debezium-route-table-private"
  }
}

resource "aws_route_table_association" "debezium-route-table-public-association-az1" {
  subnet_id = aws_subnet.debezium-subnet-az1-public.id
  route_table_id = aws_route_table.debezium-route-table-public.id
}

resource "aws_route_table_association" "debezium-route-table-public-association-az4" {
  subnet_id = aws_subnet.debezium-subnet-az4-public.id
  route_table_id = aws_route_table.debezium-route-table-public.id
}

resource "aws_route_table_association" "debezium-route-table-private-association-az2" {
  subnet_id = aws_subnet.debezium-subnet-az2-private.id
  route_table_id = aws_route_table.debezium-route-table-private.id
}

resource "aws_route_table_association" "debezium-route-table-private-association-az3" {
  subnet_id = aws_subnet.debezium-subnet-az3-private.id
  route_table_id = aws_route_table.debezium-route-table-private.id
}

resource "aws_internet_gateway" "debezium-ig" {
  vpc_id = aws_vpc.debezium-vpc.id
}

resource "aws_eip" "debezium-ng-eip" {
  vpc = true
}

resource "aws_nat_gateway" "debezium-ng" {
  depends_on = [aws_internet_gateway.debezium-ig, aws_eip.debezium-ng-eip]
  allocation_id = aws_eip.debezium-ng-eip.id
  subnet_id = aws_subnet.debezium-subnet-az1-public.id
}

resource "aws_route" "debezium-public-ig-route" {
  route_table_id = aws_route_table.debezium-route-table-public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.debezium-ig.id
}

resource "aws_route" "debezium-private-ng-route" {
  route_table_id = aws_route_table.debezium-route-table-private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.debezium-ng.id
}


resource "aws_security_group" "debezium_external_sg" {
  name = "murillodigital-debezium-external-sg"
  vpc_id = aws_vpc.debezium-vpc.id
}

resource "aws_security_group_rule" "debezium_external_sg_80" {
  security_group_id = aws_security_group.debezium_external_sg.id
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "debezium_external_sg_22" {
  security_group_id = aws_security_group.debezium_external_sg.id
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "debezium_external_sg_egress" {
  security_group_id = aws_security_group.debezium_external_sg.id
  type = "egress"
  from_port = 0
  protocol = "-1"
  to_port = 0
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "debezium_internal_sg" {
  name = "murillodigital-debezium-internal-sg"
  vpc_id = aws_vpc.debezium-vpc.id
}

resource "aws_security_group_rule" "debezium_internal_sg_5432" {
  security_group_id = aws_security_group.debezium_internal_sg.id
  type = "ingress"
  from_port = 5432
  to_port = 5432
  protocol = "tcp"
  self = true
}

resource "aws_security_group_rule" "debezium_internal_sg_9092-9094" {
  security_group_id = aws_security_group.debezium_internal_sg.id
  type = "ingress"
  from_port = 9092
  to_port = 9094
  protocol = "tcp"
  self = true
}

resource "aws_security_group_rule" "debezium_internal_sg_8083" {
  security_group_id = aws_security_group.debezium_internal_sg.id
  type = "ingress"
  from_port = 8083
  to_port = 8083
  protocol = "tcp"
  security_groups = [aws_security_group.debezium_external_sg.id]
}

resource "aws_security_group_rule" "debezium_internal_sg_egress" {
  security_group_id = aws_security_group.debezium_internal_sg.id
  type = "egress"
  from_port = 0
  protocol = "-1"
  to_port = 0
  cidr_blocks = ["0.0.0.0/0"]
}