# IAM Role for SSM Access & CloudWatch Logging
resource "aws_iam_role" "ssm_role" {
  name = "${var.environment}-ssm-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Attach SSM Policy
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 1. Attach CloudWatch Agent Policy
resource "aws_iam_role_policy_attachment" "cloudwatch_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.environment}-ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}

# 2. CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/${var.environment}/ec2/apache2"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "user_data_logs" {
  name              = "/${var.environment}/ec2/user-data"
  retention_in_days = 30
}

# Bastion Host Instance
resource "aws_instance" "bastion" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  subnet_id            = var.public_subnet_1a_id
  vpc_security_group_ids = [var.bastion_sg_id]
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  tags = { 
    Name        = "${var.environment}-bastion-host" 
    Environment = var.environment
  }
}

# App Launch Template
resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-app-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.ssm_profile.arn
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.app_sg_id]
  }

   user_data = base64encode(<<-EOF
              #!/bin/bash
              set -x
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              echo "=== Starting Setup on Ubuntu ==="

              export DEBIAN_FRONTEND=noninteractive
              apt-get update -y
              apt-get install -y apache2 curl wget

              systemctl start apache2
              systemctl enable apache2
              echo "<h1>Welcome to UTC Application (${var.environment})</h1>" > /var/www/html/index.html

              echo "=== Installing CloudWatch Agent ==="
              wget -q https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -O /tmp/amazon-cloudwatch-agent.deb
              dpkg -i -E /tmp/amazon-cloudwatch-agent.deb
              rm -f /tmp/amazon-cloudwatch-agent.deb

              cat <<CWCONFIG > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
              {
                "logs": {
                  "logs_collected": {
                    "files": {
                      "collect_list": [
                        {
                          "file_path": "/var/log/user-data.log",
                          "log_group_name": "/${var.environment}/ec2/user-data",
                          "log_stream_name": "{instance_id}"
                        },
                        {
                          "file_path": "/var/log/apache2/access.log",
                          "log_group_name": "/${var.environment}/ec2/apache2",
                          "log_stream_name": "{instance_id}-access"
                        },
                        {
                          "file_path": "/var/log/apache2/error.log",
                          "log_group_name": "/${var.environment}/ec2/apache2",
                          "log_stream_name": "{instance_id}-error"
                        }
                      ]
                    }
                  }
                }
              }
              CWCONFIG

              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
                -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

              echo "=== Setup Complete ==="
              EOF
  )
}

# Auto Scaling Group across all 3 Private App Subnets
resource "aws_autoscaling_group" "app" {
  name                = "${var.environment}-asg"
  vpc_zone_identifier = var.private_app_subnets
  target_group_arns   = [var.target_group_arn]
  min_size            = 2
  max_size            = 6
  desired_capacity    = 3

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300
}

# Scale Out Policy
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.environment}-high-cpu-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
}