output "bucket_name" {
  description = "Nom du bucket applicatif (assets, journaux, sauvegardes)."
  value       = local.bucket_id
}

output "bucket_arn" {
  description = "ARN du bucket applicatif."
  value       = local.bucket_arn
}

output "alb_logs_prefix" {
  description = "Préfixe des journaux d'accès ALB dans le bucket."
  value       = "alb"
}
