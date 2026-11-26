variable "name_prefix" {
  description = "Préfixe de nommage des ressources (<projet>-<environnement>)."
  type        = string

  validation {
    condition     = length(var.name_prefix) <= 28
    error_message = "name_prefix doit faire au plus 28 caractères (limite de 32 pour les noms d'ALB et de target group)."
  }
}

variable "vpc_id" {
  description = "VPC du target group."
  type        = string
}

variable "public_subnet_ids" {
  description = "Sous-réseaux publics (au moins deux zones) où l'ALB est déployé."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "Un ALB exige au moins deux sous-réseaux dans deux zones différentes."
  }
}

variable "alb_sg_id" {
  description = "Security Group de l'ALB."
  type        = string
}

variable "app_port" {
  description = "Port des instances ciblées."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Chemin HTTP vérifié par le health check du target group."
  type        = string
  default     = "/health"

  validation {
    condition     = startswith(var.health_check_path, "/")
    error_message = "health_check_path doit commencer par '/'."
  }
}

variable "certificate_arn" {
  description = "ARN d'un certificat ACM. S'il est fourni, un listener HTTPS est créé et HTTP redirige vers HTTPS."
  type        = string
  default     = null
}

variable "access_logs_bucket" {
  description = "Bucket S3 recevant les journaux d'accès de l'ALB (null pour désactiver)."
  type        = string
  default     = null
}

variable "enable_deletion_protection" {
  description = "Protection contre la suppression de l'ALB (recommandé en prod)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags supplémentaires appliqués aux ressources du module."
  type        = map(string)
  default     = {}
}
