resource "google_storage_bucket" "debezium_dataflow_bucket" {
  name = "debezium_dataflow"
  location = "US"
  storage_class = "STANDARD"
  force_destroy = true
}