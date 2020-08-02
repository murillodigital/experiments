resource "google_bigquery_dataset" "murillodigital_debezium" {
  dataset_id = var.dataset_name
  friendly_name = var.dataset_name
  description = "Dataset for Multicloud Debezium series at murillodigital.com"
  location = "US"
  default_table_expiration_ms = 3600000
}

resource "google_bigquery_table" "murillodigital_inventory_table" {
  dataset_id = google_bigquery_dataset.murillodigital_debezium.dataset_id
  table_id = "murillodigital_inventory"
  time_partitioning {
    type = "DAY"
  }

  schema = <<EOF
[
  {
    "name": "sku",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Product Stock Keeping Unit"
  },
  {
    "name": "name",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Friendly Product Name"
  },
  {
    "name": "price",
    "type": "FLOAT64",
    "mode": "REQUIRED",
    "description": "Product price"
  },
  {
    "name": "quantity",
    "type": "INT64",
    "mode": "REQUIRED",
    "description": "Quantity of products on hand"
  },
  {
    "name": "timestamp",
    "type": "DATETIME",
    "mode": "REQUIRED",
    "description": "Time of data change event"
  },
  {
    "name": "deleted",
    "type": "BOOL",
    "mode": "NULLABLE",
    "description": "Has this SKU been deleted"
  }
]
EOF
}

