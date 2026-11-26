# Test : proche de la prod mais réduit, déploiement après revue.
# Aucune valeur sensible ici : le mot de passe RDS est généré par AWS (Secrets Manager)
# et les identifiants AWS viennent du pipeline ou de l'environnement local.

aws_region   = "us-east-1"
project_name = "cloud5"
environment  = "test"
owner        = "azizbnr9-rgb"

# Réseau
vpc_cidr            = "10.30.0.0/16"
az_count            = 2
public_subnet_cidrs = ["10.30.1.0/24", "10.30.2.0/24"]
app_subnet_cidrs    = ["10.30.11.0/24", "10.30.12.0/24"]
db_subnet_cidrs     = ["10.30.21.0/24", "10.30.22.0/24"]
single_nat_gateway  = true

# Sécurité (AWS Academy : création de rôles IAM interdite -> instance profile fourni par le lab)
alb_ingress_cidrs              = ["0.0.0.0/0"]
create_instance_role           = false
existing_instance_profile_name = "LabInstanceProfile"

# Calcul
instance_type = "t3.micro"
min_size      = 2
max_size      = 3

# Base de données
db_instance_class          = "db.t3.micro"
db_multi_az                = false
db_backup_retention_period = 1
db_deletion_protection     = false

# Stockage
force_destroy_buckets  = true
enable_alb_access_logs = true
