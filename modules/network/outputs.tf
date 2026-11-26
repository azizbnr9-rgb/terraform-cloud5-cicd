output "vpc_id" {
  description = "Identifiant du VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "Bloc CIDR du VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Sous-réseaux publics, dans l'ordre des zones."
  value       = [for az in var.azs : aws_subnet.public[az].id]
}

output "app_subnet_ids" {
  description = "Sous-réseaux privés applicatifs, dans l'ordre des zones."
  value       = [for az in var.azs : aws_subnet.app[az].id]
}

output "db_subnet_ids" {
  description = "Sous-réseaux privés de base de données, dans l'ordre des zones."
  value       = [for az in var.azs : aws_subnet.db[az].id]
}

output "nat_public_ips" {
  description = "Adresses IP publiques de sortie (NAT)."
  value       = [for eip in aws_eip.nat : eip.public_ip]
}
