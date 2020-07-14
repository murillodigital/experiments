[
  {
    "name": "debezium",
    "image": "debezium/connect:1.2",
    "cpu": 256,
    "memory": 512,
    "essential": true,
    "networkMode": "awsvpc",
    "mountPoints": [],
    "volumes": [],
    "portMappings": [
      {
        "containerPort": 8083,
        "hostPort": 8083,
        "port": "tcp"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group" : "/ecs/debezium_testing",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "ecs"
      }
    },
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