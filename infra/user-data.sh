#!/bin/bash
set -euxo pipefail

# Send output to CloudWatch
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console)
exec 2>&1

CLOUDWATCH_LOG_GROUP="${cloudwatch_log_group}"

# Install CloudWatch agent
wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb

# Update system
apt-get update
apt-get upgrade -y

# Install Docker
apt-get install -y docker.io

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Create CloudWatch agent config
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<'CWCONFIG'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "${cloudwatch_log_group}",
            "log_stream_name": "{instance_id}/user-data"
          },
          {
            "file_path": "/var/log/docker.log",
            "log_group_name": "${cloudwatch_log_group}",
            "log_stream_name": "{instance_id}/docker"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "FastAPI",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {
            "name": "cpu_usage_idle",
            "rename": "CPU_IDLE",
            "unit": "Percent"
          },
          "cpu_usage_iowait"
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          {
            "name": "used_percent",
            "rename": "DISK_USED",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "/"
        ]
      },
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MEM_USED",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
CWCONFIG

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

echo "User data script completed successfully"
