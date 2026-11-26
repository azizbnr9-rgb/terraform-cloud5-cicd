output "environment" {
  description = "Environnement déployé."
  value       = var.environment
}

output "alb_url" {
  description = "URL publique de l'application."
  value       = module.load_balancer.alb_url
}

output "vpc_id" {
  description = "VPC de l'environnement."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Sous-réseaux publics."
  value       = module.network.public_subnet_ids
}

output "app_subnet_ids" {
  description = "Sous-réseaux privés applicatifs."
  value       = module.network.app_subnet_ids
}

output "db_subnet_ids" {
  description = "Sous-réseaux privés base de données."
  value       = module.network.db_subnet_ids
}

output "asg_name" {
  description = "Auto Scaling Group des serveurs web."
  value       = module.compute.asg_name
}

output "db_address" {
  description = "Adresse privée de la base RDS."
  value       = module.database.db_address
}

output "db_master_secret_arn" {
  description = "Secret Secrets Manager des identifiants RDS."
  value       = module.database.db_master_secret_arn
}

output "app_bucket_name" {
  description = "Bucket S3 applicatif."
  value       = module.storage.bucket_name
}
