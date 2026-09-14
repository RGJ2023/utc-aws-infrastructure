output "alb_sg_id" { value = aws_security_group.alb.id }
#utput "bastion_sg_id" { value = aws_security_group.bastion.id }
output "app_sg_id" { value = aws_security_group.app.id }
output "db_sg_id" { value = aws_security_group.db.id }