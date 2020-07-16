output "zookeeper_connect_string" {
  value = aws_msk_cluster.inventory_stream.zookeeper_connect_string
}

output "bootstrap_brokers_tls" {
  description = "Plaintext connection host:port pairs - TLS connection"
  value       = aws_msk_cluster.inventory_stream.bootstrap_brokers_tls
}

output "bootstrap_brokers" {
  description = "Plaintext connection host:port pairs"
  value       = aws_msk_cluster.inventory_stream.bootstrap_brokers
}

output "db_instance_address" {
  value = aws_db_instance.inventory_psql.address
}