variable "name_prefix" {
  description = "Préfixe de nommage des ressources (<projet>-<environnement>)."
  type        = string
}

variable "db_subnet_ids" {
  description = "Sous-réseaux privés dédiés à la base (au moins deux zones)."
  type        = list(string)

  validation {
    condition     = length(var.db_subnet_ids) >= 2
    error_message = "Un DB subnet group RDS exige au moins deux zones."
  }
}

variable "db_sg_id" {
  description = "Security Group de la base de données."
  type        = string
}

variable "engine_version" {
  description = "Version majeure.mineure de MySQL."
  type        = string
  default     = "8.0"
}

variable "parameter_group_family" {
  description = "Famille du groupe de paramètres RDS, cohérente avec engine_version."
  type        = string
  default     = "mysql8.0"
}

variable "instance_class" {
  description = "Classe d'instance RDS."
  type        = string
  default     = "db.t3.micro"

  validation {
    condition     = startswith(var.instance_class, "db.")
    error_message = "instance_class doit commencer par 'db.' (ex : db.t3.micro)."
  }
}

variable "allocated_storage" {
  description = "Stockage initial (Go)."
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "RDS MySQL exige au moins 20 Go."
  }
}

variable "max_allocated_storage" {
  description = "Plafond de l'extension automatique du stockage (Go, 0 pour désactiver)."
  type        = number
  default     = 50
}

variable "db_name" {
  description = "Nom de la base créée à l'initialisation."
  type        = string
  default     = "appdb"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,63}$", var.db_name))
    error_message = "db_name doit commencer par une lettre et ne contenir que lettres, chiffres et '_'."
  }
}

variable "master_username" {
  description = "Utilisateur administrateur. Le mot de passe n'est jamais fourni : RDS le génère et le stocke dans AWS Secrets Manager."
  type        = string
  default     = "dbadmin"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,15}$", var.master_username)) && !contains(["admin", "root", "rdsadmin"], lower(var.master_username))
    error_message = "master_username : 1 à 16 caractères, commence par une lettre, et n'est pas un nom réservé."
  }
}

variable "multi_az" {
  description = "Instance de secours synchrone dans une autre zone (recommandé en prod)."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Durée de rétention des sauvegardes automatiques (jours)."
  type        = number
  default     = 1

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "backup_retention_period doit être compris entre 0 et 35."
  }
}

variable "deletion_protection" {
  description = "Empêche la suppression de la base (true en prod)."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Ne pas créer d'instantané final lors de la destruction (true en dev/test)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags supplémentaires appliqués aux ressources du module."
  type        = map(string)
  default     = {}
}
