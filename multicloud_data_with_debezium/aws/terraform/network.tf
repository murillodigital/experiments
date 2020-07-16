
resource "aws_default_vpc" "default_vpc" { }

resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-east-1a"
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = "us-east-1b"
}

resource "aws_default_subnet" "default_az3" {
  availability_zone = "us-east-1c"
}

resource "aws_security_group" "debezium_external_sg" {
  name = "murillodigital-debezium-external-sg"
  vpc_id = aws_default_vpc.default_vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
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

resource "aws_security_group" "debezium_internal_sg" {
  name = "murillodigital-debezium-internal-sg"
  vpc_id = aws_default_vpc.default_vpc.id

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    self = true
  }

  ingress {
    from_port = 9092
    to_port = 9094
    protocol = "tcp"
    self = true
  }

  ingress {
    from_port = 8083
    to_port = 8083
    protocol = "tcp"
    security_groups = [aws_security_group.debezium_external_sg.id]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}