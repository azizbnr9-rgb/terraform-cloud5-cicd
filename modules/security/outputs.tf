output "alb_sg_id" {
  description = "Security Group du Load Balancer."
  value       = aws_security_group.alb.id
}

output "app_sg_id" {
  description = "Security Group des instances applicatives."
  value       = aws_security_group.app.id
}

output "db_sg_id" {
  description = "Security Group de la base de données."
  value       = aws_security_group.db.id
}

output "instance_profile_name" {
  description = "Instance profile IAM à attacher aux instances (créé par le module ou existant)."
  value       = var.create_instance_role ? aws_iam_instance_profile.instance[0].name : var.existing_instance_profile_name
}
