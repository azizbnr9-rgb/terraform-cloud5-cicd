################################################################################
# Général
################################################################################

variable "aws_region" {
  description = "Région de déploiement."
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region doit être un code de région AWS valide (ex : us-east-1)."
  }
}

variable "project_name" {
  description = "Préfixe de nommage <projet>."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,14}$", var.project_name))
    error_message = "project_name : 3 à 15 caractères, minuscules, chiffres et '-'."
  }
}

variable "environment" {
  description = "Nom de l'environnement."
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment doit valoir dev, test ou prod."
  }
}

variable "owner" {
  description = "Responsable de l'infrastructure (tag Owner)."
  type        = string

  validation {
    condition     = length(trimspace(var.owner)) > 0
    error_message = "owner ne peut pas être vide."
  }
}

################################################################################
# Réseau
################################################################################

variable "vpc_cidr" {
  description = "Bloc réseau principal du VPC."
  type        = string
}

variable "az_count" {
  description = "Nombre de zones de disponibilité utilisées."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count doit valoir 2 ou 3."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR des sous-réseaux publics (un par zone)."
  type        = list(string)
}

variable "app_subnet_cidrs" {
  description = "CIDR des sous-réseaux privés applicatifs (un par zone)."
  type        = list(string)
}

variable "db_subnet_cidrs" {
  description = "CIDR des sous-réseaux privés base de données (un par zone)."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Une seule NAT Gateway (true, économique) ou une par zone (false, haute disponibilité)."
  type        = bool
  default     = true
}

################################################################################
# Sécurité
################################################################################

variable "alb_ingress_cidrs" {
  description = "Plages autorisées à joindre l'ALB en HTTP/HTTPS."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "create_instance_role" {
  description = "Créer le rôle IAM des instances (false sur AWS Academy, où la création de rôles est interdite)."
  type        = bool
  default     = true
}

variable "existing_instance_profile_name" {
  description = "Instance profile existant utilisé si create_instance_role = false (ex : LabInstanceProfile)."
  type        = string
  default     = null
}

variable "certificate_arn" {
  description = "Certificat ACM optionnel pour activer HTTPS sur l'ALB."
  type        = string
  default     = null
}

################################################################################
# Calcul
################################################################################

variable "instance_type" {
  description = "Type d'instance EC2."
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Nombre minimal d'instances."
  type        = number
  default     = 2

  validation {
    condition     = var.min_size >= 2
    error_message = "min_size doit être au moins 2 pour résister à la panne d'une instance."
  }
}

variable "max_size" {
  description = "Nombre maximal d'instances."
  type        = number
  default     = 4

  validation {
    condition     = var.max_size >= var.min_size
    error_message = "max_size doit être supérieur ou égal à min_size."
  }
}

variable "desired_capacity" {
  description = "Capacité souhaitée (null = min_size)."
  type        = number
  default     = null
}

################################################################################
# Base de données
################################################################################

variable "db_instance_class" {
  description = "Classe RDS."
  type        = string
  default     = "db.t3.micro"
}

variable "db_multi_az" {
  description = "RDS Multi-AZ."
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "Rétention des sauvegardes RDS (jours)."
  type        = number
  default     = 1
}

variable "db_deletion_protection" {
  description = "Protection contre la suppression de la base."
  type        = bool
  default     = false
}

################################################################################
# Stockage
################################################################################

variable "force_destroy_buckets" {
  description = "Autoriser destroy à vider le bucket applicatif."
  type        = bool
  default     = false
}

variable "enable_alb_access_logs" {
  description = "Envoyer les journaux d'accès de l'ALB dans le bucket applicatif."
  type        = bool
  default     = true
}
