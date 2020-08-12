data "google_project" "project" {}

resource "google_compute_instance" "murillodigital-beam" {
  name = "murillodigital-beam"
  machine_type = "n1-standard-1"
  zone = "${var.gcp_region}-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  scratch_disk {
    interface = "SCSI"
  }

  network_interface {
    network = google_compute_network.gcp-network.name
    subnetwork = google_compute_subnetwork.gcp-subnet1.name
    access_config { }
  }

  metadata_startup_script = <<EOF
apt update
apt install -y git python3-pip python3-venv
git clone https://github.com/murillodigital/experiments /root/experiments
python3 -m venv /root/experimens/multicloud_data_with_debezium/gcp+aws/beam/
echo "BOOTSTRAP_SERVERS=${var.bootstrap_servers}" >> /root/murillodigital.env
echo "KAFKA_TOPIC=${var.kafka_topic}" >> /root/murillodigital.env
echo "GCP_PROJECT=${data.google_project.project.name}" >> /root/murillodigital.env
echo "DATASET=${var.dataset_name}" >> /root/murillodigital.env
echo "TABLE=${var.table_name}" >> /root/murillodigital.env
EOF

  tags = [
    "murillodigital-debezium"
  ]
}