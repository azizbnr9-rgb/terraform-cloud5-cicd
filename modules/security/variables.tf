variable "name_prefix" {
  description = "Préfixe de nommage des ressources (<projet>-<environnement>)."
  type        = string
}

variable "vpc_id" {
  description = "VPC dans lequel les Security Groups sont créés."
  type        = string
}

variable "alb_ingress_cidrs" {
  description = "Plages IPv4 autorisées à joindre le Load Balancer en HTTP/HTTPS."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for c in var.alb_ingress_cidrs : can(cidrhost(c, 0))])
    error_message = "Chaque entrée de alb_ingress_cidrs doit être un CIDR IPv4 valide."
  }
}

variable "app_port" {
  description = "Port d'écoute de l'application sur les instances."
  type        = number
  default     = 80

  validation {
    condition     = var.app_port > 0 && var.app_port < 65536
    error_message = "app_port doit être compris entre 1 et 65535."
  }
}

variable "db_port" {
  description = "Port de la base de données (3306 pour MySQL)."
  type        = number
  default     = 3306
}

variable "create_instance_role" {
  description = "true : crée un rôle IAM d'instance au moindre privilège. false : réutilise un instance profile existant (comptes AWS Academy où la création de rôles est interdite)."
  type        = bool
  default     = true
}

variable "existing_instance_profile_name" {
  description = "Nom de l'instance profile existant à utiliser lorsque create_instance_role = false (ex : LabInstanceProfile)."
  type        = string
  default     = null

  validation {
    condition     = var.existing_instance_profile_name == null || can(regex("^[\\w+=,.@-]{1,128}$", var.existing_instance_profile_name))
    error_message = "existing_instance_profile_name doit être un nom d'instance profile IAM valide."
  }
}

variable "app_bucket_arn" {
  description = "ARN du bucket S3 applicatif auquel les instances peuvent accéder (lecture assets/, écriture logs/)."
  type        = string
}

variable "tags" {
  description = "Tags supplémentaires appliqués aux ressources du module."
  type        = map(string)
  default     = {}
}
