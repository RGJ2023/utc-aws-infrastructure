#utput "bastion_public_ip" { value = aws_instance.bastion.public_ip }
output "asg_name" { value = aws_autoscaling_group.app.name }
output "scale_out_policy_arn" { value = aws_autoscaling_policy.scale_out.arn }
output "scale_in_policy_arn" {
  value       = aws_autoscaling_policy.scale_in.arn
  description = "ARN of scale in policy for low CPU metric alarm"
}