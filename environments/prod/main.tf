data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  azs         = slice(sort(data.aws_availability_zones.available.names), 0, var.az_count)

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}

module "network" {
  source = "../../modules/network"

  name_prefix         = local.name_prefix
  vpc_cidr            = var.vpc_cidr
  azs                 = local.azs
  public_subnet_cidrs = var.public_subnet_cidrs
  app_subnet_cidrs    = var.app_subnet_cidrs
  db_subnet_cidrs     = var.db_subnet_cidrs
  single_nat_gateway  = var.single_nat_gateway
}

module "storage" {
  source = "../../modules/storage"

  name_prefix             = local.name_prefix
  bucket_suffix           = data.aws_caller_identity.current.account_id
  force_destroy           = var.force_destroy_buckets
  enable_alb_log_delivery = var.enable_alb_access_logs
}

module "security" {
  source = "../../modules/security"

  name_prefix                    = local.name_prefix
  vpc_id                         = module.network.vpc_id
  alb_ingress_cidrs              = var.alb_ingress_cidrs
  create_instance_role           = var.create_instance_role
  existing_instance_profile_name = var.existing_instance_profile_name
  app_bucket_arn                 = module.storage.bucket_arn
}

module "load_balancer" {
  source = "../../modules/load-balancer"

  name_prefix        = local.name_prefix
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  alb_sg_id          = module.security.alb_sg_id
  certificate_arn    = var.certificate_arn
  access_logs_bucket = var.enable_alb_access_logs ? module.storage.bucket_name : null

  enable_deletion_protection = var.environment == "prod"

  # Explicite : la politique du bucket (écriture des journaux ALB) doit exister avant l'ALB.
  depends_on = [module.storage]
}

module "compute" {
  source = "../../modules/compute"

  name_prefix           = local.name_prefix
  project_name          = var.project_name
  environment           = var.environment
  instance_type         = var.instance_type
  app_subnet_ids        = module.network.app_subnet_ids
  app_sg_id             = module.security.app_sg_id
  instance_profile_name = module.security.instance_profile_name
  target_group_arns     = [module.load_balancer.target_group_arn]
  min_size              = var.min_size
  max_size              = var.max_size
  desired_capacity      = var.desired_capacity
  tags                  = local.common_tags
}

module "database" {
  source = "../../modules/database"

  name_prefix             = local.name_prefix
  db_subnet_ids           = module.network.db_subnet_ids
  db_sg_id                = module.security.db_sg_id
  instance_class          = var.db_instance_class
  multi_az                = var.db_multi_az
  backup_retention_period = var.db_backup_retention_period
  deletion_protection     = var.db_deletion_protection
  skip_final_snapshot     = var.environment != "prod"
}
