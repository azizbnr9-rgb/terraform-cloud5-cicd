variable "name_prefix" {
  description = "Préfixe de nommage des ressources (<projet>-<environnement>)."
  type        = string
}

variable "project_name" {
  description = "Nom du projet, affiché sur la page de démonstration."
  type        = string
}

variable "environment" {
  description = "Environnement (dev, test, prod), affiché sur la page de démonstration."
  type        = string
}

variable "instance_type" {
  description = "Type d'instance EC2."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]*\\.[a-z0-9]+$", var.instance_type))
    error_message = "instance_type doit ressembler à t3.micro."
  }
}

variable "ami_ssm_parameter" {
  description = "Paramètre SSM public donnant l'AMI la plus récente (Amazon Linux 2023 par défaut)."
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

variable "app_subnet_ids" {
  description = "Sous-réseaux privés applicatifs où l'Auto Scaling Group lance les instances."
  type        = list(string)

  validation {
    condition     = length(var.app_subnet_ids) >= 2
    error_message = "Au moins deux sous-réseaux (deux zones) sont requis."
  }
}

variable "app_sg_id" {
  description = "Security Group des instances applicatives."
  type        = string
}

variable "instance_profile_name" {
  description = "Instance profile IAM attaché aux instances."
  type        = string
}

variable "target_group_arns" {
  description = "Target groups de l'ALB dans lesquels les instances sont enregistrées."
  type        = list(string)
}

variable "min_size" {
  description = "Nombre minimal d'instances."
  type        = number
  default     = 2

  validation {
    condition     = var.min_size >= 1
    error_message = "min_size doit être supérieur ou égal à 1."
  }
}

variable "max_size" {
  description = "Nombre maximal d'instances."
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Capacité souhaitée (null = min_size)."
  type        = number
  default     = null
}

variable "root_volume_size" {
  description = "Taille du volume racine chiffré, en Go."
  type        = number
  default     = 8

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 100
    error_message = "root_volume_size doit être compris entre 8 et 100 Go."
  }
}

variable "cpu_target_value" {
  description = "Utilisation CPU moyenne visée par la politique de scaling (en %)."
  type        = number
  default     = 50

  validation {
    condition     = var.cpu_target_value > 10 && var.cpu_target_value < 95
    error_message = "cpu_target_value doit être compris entre 10 et 95."
  }
}

variable "health_check_grace_period" {
  description = "Délai (secondes) avant la prise en compte du health check ELB après lancement."
  type        = number
  default     = 120
}

variable "tags" {
  description = "Tags propagés aux instances et volumes (les default_tags du provider ne s'y appliquent pas)."
  type        = map(string)
  default     = {}
}
