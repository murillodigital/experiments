data "google_project" "project" {}

resource "google_compute_instance" "murillodigital-beam" {
  name = "murillodigital-beam"
  machine_type = "n1-standard-1"
  zone = "${var.gcp_region}-b"
  service_account {
    scopes = ["bigquery"]
  }

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
#!/bin/bash
apt update
apt install -y git python3-pip python3-venv
git clone https://github.com/murillodigital/experiments /root/experiments
python3 -m venv /root/experiments/multicloud_data_with_debezium/gcp+aws/beam
pushd /root/experiments/multicloud_data_with_debezium/gcp+aws/beam
. bin/activate
pip install wheel
pip install -r requirements.txt
popd
echo "BOOTSTRAP_SERVERS=${var.bootstrap_servers}" >> /root/murillodigital.env
echo "KAFKA_TOPIC=${var.kafka_topic}" >> /root/murillodigital.env
echo "GCP_PROJECT=${data.google_project.project.name}" >> /root/murillodigital.env
echo "DATASET=${var.dataset_name}" >> /root/murillodigital.env
echo "TABLE=${var.table_name}" >> /root/murillodigital.env
cp /root/experiments/multicloud_data_with_debezium/gcp+aws/beam/murillodigital.service /etc/systemd/system/murillodigital.service
chmod 644 /etc/systemd/system/murillodigital.service
systemctl start murillodigital
EOF

  tags = [
    "murillodigital-debezium"
  ]
}