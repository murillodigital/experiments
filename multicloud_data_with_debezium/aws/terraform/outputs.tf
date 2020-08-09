output "aws_zookeeper" {
  value = aws_msk_cluster.debezium_msk_cluster.zookeeper_connect_string
}

output "aws_brokers_tls" {
  description = "Plaintext connection host:port pairs - TLS connection"
  value       = aws_msk_cluster.debezium_msk_cluster.bootstrap_brokers_tls
}

output "aws_brokers_cleartext" {
  description = "Plaintext connection host:port pairs"
  value       = aws_msk_cluster.debezium_msk_cluster.bootstrap_brokers
}

output "aws_db" {
  value = aws_db_instance.debezium_db.address
}

output "aws_lb" {
  value = aws_lb.debezium_lb.dns_name
}

output "aws_bastion" {
  value = aws_instance.debezium_bastion_host.public_ip
}

output "aws_vpc_id" {
  value = aws_vpc.debezium-vpc.id
}

output "subnet_public_az1" {
  value = aws_subnet.debezium-subnet-az1-public.id
}

output "aws_private_subnet1" {
  value = aws_subnet.debezium-subnet-az2-private.id
}

output "aws_private_subnet2" {
  value = aws_subnet.debezium-subnet-az3-private.id
}

output "aws_public_route_table" {
  value = aws_route_table.debezium-route-table-public.id
}

output "aws_private_route_tabel" {
  value = aws_route_table.debezium-route-table-private.id
}

output "aws_internal_sg" {
  value = aws_security_group.debezium_internal_sg.id
}

output "aws_external_sg" {
  value = aws_security_group.debezium_external_sg.id
}