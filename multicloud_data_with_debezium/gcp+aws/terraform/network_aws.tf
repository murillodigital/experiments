resource "aws_vpn_gateway" "aws-vpn-gw" {
  vpc_id = var.aws_vpc_id
}

resource "aws_customer_gateway" "aws-cgw" {
  bgp_asn    = 65000
  ip_address = google_compute_address.gcp-vpn-ip.address
  type       = "ipsec.1"
  tags = {
    "Name" = "aws-customer-gw"
  }
}

resource "aws_vpn_connection" "aws-vpn-connection1" {
  vpn_gateway_id      = aws_vpn_gateway.aws-vpn-gw.id
  customer_gateway_id = aws_customer_gateway.aws-cgw.id
  type                = "ipsec.1"
  static_routes_only  = false
  tags = {
    "Name" = "aws-vpn-connection1"
  }
}

resource "aws_route" "aws-vpn-private-route" {
  gateway_id = aws_vpn_gateway.aws-vpn-gw.id
  destination_cidr_block = var.gcp_network_cidr
  route_table_id = var.aws_private_route_table
}

resource "aws_vpn_gateway_route_propagation" "aws-vpn-private-route-propagation" {
  vpn_gateway_id = aws_vpn_gateway.aws-vpn-gw.id
  route_table_id = var.aws_private_route_table
}

resource "aws_route" "aws-vpn-public-route" {
  gateway_id = aws_vpn_gateway.aws-vpn-gw.id
  destination_cidr_block = var.gcp_network_cidr
  route_table_id = var.aws_public_route_table
}

resource "aws_vpn_gateway_route_propagation" "aws-vpn-public-route-propagation" {
  vpn_gateway_id = aws_vpn_gateway.aws-vpn-gw.id
  route_table_id = var.aws_public_route_table
}

resource "aws_security_group_rule" "debezium_internal_sg_vpn_9092-9094" {
  security_group_id = var.aws_internal_sg
  type = "ingress"
  from_port = 9092
  to_port = 9094
  protocol = "tcp"
  cidr_blocks = [var.gcp_network_cidr]
}