# IAM Role for SSM Access on instances
resource "aws_iam_role" "ssm_role" {
  name = "utc-ssm-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "utc-ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}

# Bastion Host Instance
resource "aws_instance" "bastion" {
  ami                  = var.ami_id
  instance_type        = "t3.micro"
  subnet_id            = var.public_subnet_1a_id
  vpc_security_group_ids = [var.bastion_sg_id]
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  tags = { Name = "Bastion Host (SSH)" }
}

# App Launch Template
resource "aws_launch_template" "app" {
  name_prefix   = "utc-app-"
  image_id      = var.ami_id
  instance_type = "t3.micro"

  iam_instance_profile {
    arn = aws_iam_instance_profile.ssm_profile.arn
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.app_sg_id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              echo "=== Starting Setup on Ubuntu ==="
              export DEBIAN_FRONTEND=noninteractive
              apt-get update -y
              apt-get install -y apache2 amazon-efs-utils
              systemctl start apache2
              systemctl enable apache2
              echo "<h1>Welcome to UTC Application</h1>" > /var/www/html/index.html
              echo "=== Setup Complete ==="
              EOF
  )
              
  

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "App Server" }
  }
}

# Auto Scaling Group across all 3 Private App Subnets
resource "aws_autoscaling_group" "app" {
  name                = "utc-asg"
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
  name                   = "high-cpu-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
}