resource "aws_sns_topic" "utc_scaling" {
  name = "utc-auto-scaling"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.utc_scaling.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "utc-high-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [var.scale_out_policy, aws_sns_topic.utc_scaling.arn]

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
}