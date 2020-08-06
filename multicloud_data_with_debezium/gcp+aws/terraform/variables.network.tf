variable "aws_vpc_id" {
  type = string
  description = "AWS VPC ID"
}

variable "aws_private_subnet1" {
  type = string
  description = "AWS ID for Private Subnet in AZ 1"
}

variable "aws_private_subnet2" {
  type = string
  description = "AWS ID for Private Subnet in AZ 2"
}

variable "aws_private_route_table" {
  type = string
  description = "AWS ID for the Private Route Table"
}

variable "gcp_region" {
  description = "Default to Oregon region."
  default     = "us-east1"
}

variable "gcp_network_cidr" {
  default = "10.240.0.0/16"
}

variable "gcp_subnet1_cidr" {
  default = "10.240.0.0/24"
}

variable "GCP_TUN1_VPN_GW_ASN" {
  description = "Tunnel 1 - Virtual Private Gateway ASN, from the AWS VPN Customer Gateway Configuration"
  default     = "64512"
}

variable "GCP_TUN1_CUSTOMER_GW_INSIDE_NETWORK_CIDR" {
  description = "Tunnel 1 - Customer Gateway from Inside IP Address CIDR block, from AWS VPN Customer Gateway Configuration"
  default     = "30"
}

variable "GCP_TUN2_VPN_GW_ASN" {
  description = "Tunnel 2 - Virtual Private Gateway ASN, from the AWS VPN Customer Gateway Configuration"
  default     = "64512"
}

variable "GCP_TUN2_CUSTOMER_GW_INSIDE_NETWORK_CIDR" {
  description = "Tunnel 2 - Customer Gateway from Inside IP Address CIDR block, from AWS VPN Customer Gateway Configuration"
  default     = "30"
}