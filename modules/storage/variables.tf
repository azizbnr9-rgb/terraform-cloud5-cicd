variable "name_prefix" {
  description = "Préfixe de nommage des ressources (<projet>-<environnement>)."
  type        = string
}

variable "bucket_suffix" {
  description = "Suffixe garantissant l'unicité mondiale du nom de bucket (ex : identifiant du compte AWS)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{1,20}$", var.bucket_suffix))
    error_message = "bucket_suffix : 1 à 20 caractères parmi a-z, 0-9 et '-'."
  }
}

variable "force_destroy" {
  description = "Autorise terraform destroy à vider le bucket (true en dev/test, false en prod)."
  type        = bool
  default     = false
}

variable "enable_alb_log_delivery" {
  description = "Ajoute la politique autorisant l'ALB à écrire ses journaux d'accès sous le préfixe alb/."
  type        = bool
  default     = true
}

variable "ia_transition_days" {
  description = "Nombre de jours avant passage des objets en classe STANDARD_IA (minimum 30)."
  type        = number
  default     = 30

  validation {
    condition     = var.ia_transition_days >= 30
    error_message = "S3 impose au moins 30 jours avant une transition vers STANDARD_IA."
  }
}

variable "log_expiration_days" {
  description = "Durée de conservation des journaux (préfixes logs/ et alb/), en jours."
  type        = number
  default     = 90

  validation {
    condition     = var.log_expiration_days >= 1
    error_message = "log_expiration_days doit être supérieur ou égal à 1."
  }
}

variable "noncurrent_version_expiration_days" {
  description = "Durée de conservation des anciennes versions d'objets, en jours."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags supplémentaires appliqués aux ressources du module."
  type        = map(string)
  default     = {}
}
