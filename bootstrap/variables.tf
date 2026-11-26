variable "aws_region" {
  description = "Région du bucket d'état."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Préfixe de nommage."
  type        = string
  default     = "cloud5"
}

variable "owner" {
  description = "Responsable (tag Owner)."
  type        = string
}

variable "state_noncurrent_retention_days" {
  description = "Conservation des anciennes versions de l'état (jours)."
  type        = number
  default     = 90
}

variable "enable_github_oidc" {
  description = "Crée le fournisseur OIDC GitHub et les rôles du pipeline (impossible sur AWS Academy, où la création IAM est bloquée)."
  type        = bool
  default     = false
}

variable "github_repository" {
  description = "Dépôt GitHub autorisé à assumer les rôles du pipeline, au format owner/repo."
  type        = string
  default     = "azizbnr9-rgb/terraform-cloud5-cicd"

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository doit être au format owner/repo."
  }
}
