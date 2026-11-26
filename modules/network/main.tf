data "aws_region" "current" {}

locals {
  # Une entrée par zone : clé = nom de l'AZ, valeur = CIDR et suffixe court (a, b, ...).
  public_subnets = { for idx, az in var.azs : az => { cidr = var.public_subnet_cidrs[idx], suffix = substr(az, -1, 1) } }
  app_subnets    = { for idx, az in var.azs : az => { cidr = var.app_subnet_cidrs[idx], suffix = substr(az, -1, 1) } }
  db_subnets     = { for idx, az in var.azs : az => { cidr = var.db_subnet_cidrs[idx], suffix = substr(az, -1, 1) } }

  # Zones qui portent une NAT Gateway : la première seulement, ou toutes.
  nat_azs = var.enable_nat_gateway ? (var.single_nat_gateway ? [var.azs[0]] : var.azs) : []
}

################################################################################
# VPC et Internet Gateway
################################################################################

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = "${var.name_prefix}-vpc" })
}

# Le groupe de sécurité par défaut est vidé de toutes ses règles (bonne pratique CIS).
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name_prefix}-default-sg-locked" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name_prefix}-igw" })
}

################################################################################
# Sous-réseaux
################################################################################

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-${each.value.suffix}"
    Tier = "public"
  })
}

resource "aws_subnet" "app" {
  for_each = local.app_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.key

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-app-${each.value.suffix}"
    Tier = "private-app"
  })
}

resource "aws_subnet" "db" {
  for_each = local.db_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.key

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-${each.value.suffix}"
    Tier = "private-db"
  })
}

################################################################################
# Sortie contrôlée : NAT Gateway(s)
################################################################################

resource "aws_eip" "nat" {
  for_each = toset(local.nat_azs)

  domain = "vpc"

  tags = merge(var.tags, { Name = "${var.name_prefix}-nat-eip-${substr(each.key, -1, 1)}" })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  for_each = toset(local.nat_azs)

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(var.tags, { Name = "${var.name_prefix}-nat-${substr(each.key, -1, 1)}" })

  depends_on = [aws_internet_gateway.this]
}

################################################################################
# Tables de routage
################################################################################

# Public : route par défaut vers l'Internet Gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name_prefix}-rt-public" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Applicatif : une table par zone, sortie Internet via la NAT de la zone
# (ou la NAT unique), jamais d'accès entrant direct.
resource "aws_route_table" "app" {
  for_each = local.app_subnets

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name_prefix}-rt-app-${each.value.suffix}" })
}

resource "aws_route" "app_nat" {
  for_each = var.enable_nat_gateway ? local.app_subnets : {}

  route_table_id         = aws_route_table.app[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway ? aws_nat_gateway.this[var.azs[0]].id : aws_nat_gateway.this[each.key].id
}

resource "aws_route_table_association" "app" {
  for_each = aws_subnet.app

  subnet_id      = each.value.id
  route_table_id = aws_route_table.app[each.key].id
}

# Base de données : table isolée, aucune route vers Internet.
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name_prefix}-rt-db-isolated" })
}

resource "aws_route_table_association" "db" {
  for_each = aws_subnet.db

  subnet_id      = each.value.id
  route_table_id = aws_route_table.db.id
}

################################################################################
# VPC endpoint S3 (Gateway, sans coût horaire)
################################################################################

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [for rt in aws_route_table.app : rt.id]

  tags = merge(var.tags, { Name = "${var.name_prefix}-vpce-s3" })
}
