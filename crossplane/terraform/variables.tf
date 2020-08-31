variable "region" {
  description = "GCP Region For Project Deployment"
  default = "us-east1"
}

variable "project_id" {
  description = "ID of the GCP Project for experiment deployment"
}

variable "network_name" {
  description = "Name to use for the VPC network"
}

variable "subnetwork_name" {
  description = "Name to use for the Subnet where GKE will be deployed"
}

variable "ip_range_pods_name" {
  description = "Name to use for the ip range to be assigned to pods"
}

variable "ip_range_services_name" {
  description = "Name to use for the ip range to be assigned to services"
}