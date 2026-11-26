output "bucket_name" {
  description = "Nom du bucket applicatif (assets, journaux, sauvegardes)."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN du bucket applicatif."
  value       = aws_s3_bucket.this.arn
}

output "alb_logs_prefix" {
  description = "Préfixe des journaux d'accès ALB dans le bucket."
  value       = "alb"
}
