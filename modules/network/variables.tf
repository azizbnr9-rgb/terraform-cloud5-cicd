variable "name_prefix" {
  description = "Préfixe de nommage des ressources (<projet>-<environnement>)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,28}$", var.name_prefix))
    error_message = "name_prefix doit contenir 3 à 28 caractères parmi a-z, 0-9 et '-'."
  }
}

variable "vpc_cidr" {
  description = "Bloc CIDR principal du VPC (ex : 10.20.0.0/16)."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && tonumber(split("/", var.vpc_cidr)[1]) <= 24
    error_message = "vpc_cidr doit être un bloc CIDR IPv4 valide de taille /24 ou plus large."
  }
}

variable "azs" {
  description = "Zones de disponibilité utilisées (au moins deux pour la haute disponibilité)."
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 2
    error_message = "Au moins deux zones de disponibilité sont requises."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR des sous-réseaux publics (ALB, NAT), un par zone, dans l'ordre de var.azs."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.azs) && alltrue([for c in var.public_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "Il faut un CIDR public valide par zone de disponibilité."
  }
}

variable "app_subnet_cidrs" {
  description = "CIDR des sous-réseaux privés applicatifs, un par zone, dans l'ordre de var.azs."
  type        = list(string)

  validation {
    condition     = length(var.app_subnet_cidrs) == length(var.azs) && alltrue([for c in var.app_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "Il faut un CIDR applicatif valide par zone de disponibilité."
  }
}

variable "db_subnet_cidrs" {
  description = "CIDR des sous-réseaux privés dédiés à la base de données, un par zone."
  type        = list(string)

  validation {
    condition     = length(var.db_subnet_cidrs) == length(var.azs) && alltrue([for c in var.db_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "Il faut un CIDR base de données valide par zone de disponibilité."
  }
}

variable "enable_nat_gateway" {
  description = "Crée des NAT Gateways pour la sortie Internet contrôlée des sous-réseaux applicatifs."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "true : une seule NAT Gateway (économique, dev/test). false : une NAT par zone (haute disponibilité, prod)."
  type        = bool
  default     = true
}

variable "enable_s3_endpoint" {
  description = "Crée un VPC endpoint S3 de type Gateway (gratuit) pour éviter le passage par la NAT vers S3."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags supplémentaires appliqués aux ressources du module."
  type        = map(string)
  default     = {}
}
