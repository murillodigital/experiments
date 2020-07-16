output "zookeeper_connect_string" {
  value = aws_msk_cluster.debezium_msk_cluster.zookeeper_connect_string
}

output "bootstrap_brokers_tls" {
  description = "Plaintext connection host:port pairs - TLS connection"
  value       = aws_msk_cluster.debezium_msk_cluster.bootstrap_brokers_tls
}

output "bootstrap_brokers" {
  description = "Plaintext connection host:port pairs"
  value       = aws_msk_cluster.debezium_msk_cluster.bootstrap_brokers
}

output "db_instance_address" {
  value = aws_db_instance.debezium_db.address
}

output "debezium_loadbalancer_endpoint" {
  value = aws_lb.debezium_lb.dns_name
}

output "debezium_bastion_ip" {
  value = aws_instance.debezium_bastion_host.public_ip
}