output "bastion_public_ip" { value = aws_instance.bastion.public_ip }
output "asg_name" { value = aws_autoscaling_group.app.name }
output "scale_out_policy_arn" { value = aws_autoscaling_policy.scale_out.arn }