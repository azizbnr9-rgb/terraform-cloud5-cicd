output "db_identifier" {
  description = "Identifiant de l'instance RDS."
  value       = aws_db_instance.this.identifier
}

output "db_address" {
  description = "Nom DNS privé de la base (résout vers une IP privée du VPC)."
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "Port de la base."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Nom de la base applicative."
  value       = aws_db_instance.this.db_name
}

output "db_master_secret_arn" {
  description = "ARN du secret Secrets Manager contenant les identifiants administrateur (la valeur n'est jamais exposée)."
  value       = try(aws_db_instance.this.master_user_secret[0].secret_arn, null)
}
