# ------------------------------------------------------------------------------
# SNS Notification Topic & Email Subscription
# ------------------------------------------------------------------------------
resource "aws_sns_topic" "scaling_alerts" {
  name = "${var.environment}-auto-scaling-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.scaling_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# ------------------------------------------------------------------------------
# Scale-Out Alarm (High CPU >= 80%)
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.environment}-high-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  
  # Triggers both the ASG Scale-Out Policy AND the SNS Email Notification
  alarm_actions       = [var.scale_out_policy, aws_sns_topic.scaling_alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  tags = {
    Name        = "${var.environment}-high-cpu-alarm"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# Scale-In Alarm (Low CPU <= 20%) 
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.environment}-low-cpu-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 20
  
  # Triggers the ASG Scale-In Policy
  alarm_actions       = [var.scale_in_policy]

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  tags = {
    Name        = "${var.environment}-low-cpu-alarm"
    Environment = var.environment
  }
}