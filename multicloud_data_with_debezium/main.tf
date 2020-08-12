provider "google" {
  region = "us-east1"
}

provider "aws" {
  region = "us-east-1"
}

module "aws" {
  source = "aws/terraform"
  bastion_key_name = var.bastion_key_name
}

module "gcp_aws" {
  source = "gcp+aws/terraform"
  aws_internal_sg = module.aws.aws_internal_sg
  aws_lb = module.aws.aws_lb
  aws_private_route_table = module.aws.aws_private_route_table
  aws_private_subnet1 = module.aws.aws_private_subnet1
  aws_private_subnet2 = module.aws.aws_private_subnet2
  aws_public_route_table = module.aws.aws_public_route_table
  aws_vpc_id = module.aws.aws_vpc_id
  bootstrap_servers = module.aws.aws_brokers_cleartext
  kafka_topic = "inventory.inventory.products"
}