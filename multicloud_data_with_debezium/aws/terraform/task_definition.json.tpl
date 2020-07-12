[
  {
    "name": "debezium",
    "image": "debezium/connect:1.2",
    "cpu": 10,
    "memory": 256,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 8083,
        "hostPort": 8083
      }
    ],
    "environment": [
      {
        "name": "GROUP_ID",
        "value": "1"
      },
      {
        "name": "CONFIG_STORAGE_TOPIC",
        "value": "inventory_configs"
      },
      {
        "name": "OFFSET_STORAGE_TOPIC",
        "value": "inventory_offsets"
      },
      {
        "name": "STATUS_STORAGE_TOPIC",
        "value": "inventory_status"
      },
      {
        "name": "BOOTSTRAP_SERVERS",
        "value": "${bootstrap_servers}"
      }
    ]
  }
]