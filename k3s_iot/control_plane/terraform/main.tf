provider "google" {
  region      = "us-east1"
}

data "google_project" "project" { }

data "google_compute_zones" "available" {
  region = "us-east1"
}

module "gcp-network" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 2.0"
  project_id   = data.google_project.project.project_id
  network_name = "murillodigital-gitops"

  subnets = [
    {
      subnet_name   = "murillodigital-gitops-subnet1"
      subnet_ip     = "10.0.0.0/17"
      subnet_region = "us-east1"
    },
  ]

  secondary_ranges = {
    "murillodigital-gitops-subnet1" = [
      {
        range_name    = "murillodigital-gitops-pods"
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = "murillodigital-gitops-services"
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}

module "gke" {
  source = "terraform-google-modules/kubernetes-engine/google"
  project_id = data.google_project.project.project_id
  name = "murillodigital-gitops"
  region = "us-east1"
  zones = [
    data.google_compute_zones.available.names[0],
    data.google_compute_zones.available.names[1],
    data.google_compute_zones.available.names[2]]
  network = module.gcp-network.network_name
  subnetwork = module.gcp-network.subnets_names[0]
  ip_range_pods = "murillodigital-gitops-pods"
  ip_range_services = "murillodigital-gitops-services"
  http_load_balancing = false
  horizontal_pod_autoscaling = true
  network_policy = true
  create_service_account = true

  node_pools = [
    {
      name = "default-node-pool"
      machine_type = "e2-standard-2"
      min_count = 1
      max_count = 3
      local_ssd_count = 0
      disk_size_gb = 100
      disk_type = "pd-standard"
      image_type = "COS"
      auto_repair = true
      auto_upgrade = true
      preemptible = false
      initial_node_count = 1
    },
  ]

  node_pools_oauth_scopes = {
    all = []

    default-node-pool = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  node_pools_labels = {
    all = {}

    default-node-pool = {
      default-node-pool = true
    }
  }

  node_pools_tags = {
    all = []

    default-node-pool = [
      "default-node-pool",
    ]
  }
}
