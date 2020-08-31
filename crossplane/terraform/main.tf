provider "google" {
  region = "us-east1"
}

data "google_compute_zones" "available" {
  region = var.region
}

module "gcp-network" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 2.0"
  project_id   = var.project_id
  network_name = var.network_name

  subnets = [
    {
      subnet_name   = var.subnetwork_name
      subnet_ip     = "10.0.0.0/17"
      subnet_region = var.region
    },
  ]

  secondary_ranges = {
    "${var.subnetwork_name}" = [
      {
        range_name    = var.ip_range_pods_name
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = var.ip_range_services_name
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}

module "gke" {
  source = "terraform-google-modules/kubernetes-engine/google"
  project_id = var.project_id
  name = "murillodigital-crossplane"
  region = var.region
  zones = [
    data.google_compute_zones.available.names[0],
    data.google_compute_zones.available.names[1],
    data.google_compute_zones.available.names[2]]
  network = module.gcp-network.network_name
  subnetwork = module.gcp-network.subnets_names[0]
  ip_range_pods = var.ip_range_pods_name
  ip_range_services = var.ip_range_services_name
  http_load_balancing = false
  horizontal_pod_autoscaling = true
  network_policy = true
  create_service_account = true

  node_pools = [
    {
      name = "default-node-pool"
      machine_type = "e2-micro"
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

resource "google_service_account" "murillodigital-crossplane-sa" {
  account_id   = "murillodigital-crossplane"
  display_name = "Service Account Used by the Crossplane GCP provider"
}

resource "google_service_account_key" "murillodigital-crossplane-key" {
  service_account_id = google_service_account.murillodigital-crossplane-sa.name
}

resource "local_file" "murillodigital-crossplane-keyfile" {
  content = base64decode(google_service_account_key.murillodigital-crossplane-key.private_key)
  filename = "${path.module}/sa.json"
}

resource "google_project_iam_member" "murillodigital-crossplane-sqlrole" {
  project = var.project_id
  role = "roles/cloudsql.admin"
  member = "serviceAccount:${google_service_account.murillodigital-crossplane-sa.email}"
}

resource "google_project_iam_member" "murillodigital-crossplane-pubsubrole" {
  project = var.project_id
  role = "roles/pubsub.admin"
  member = "serviceAccount:${google_service_account.murillodigital-crossplane-sa.email}"
}