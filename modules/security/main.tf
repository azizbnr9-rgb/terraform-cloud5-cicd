################################################################################
# Security Groups : chaîne Internet -> ALB -> App -> DB
################################################################################

resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "ALB - HTTP and HTTPS from Internet"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name_prefix}-alb-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-app-sg"
  description = "App instances - web traffic from ALB SG only"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name_prefix}-app-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "db" {
  name        = "${var.name_prefix}-db-sg"
  description = "RDS - connections from app SG only"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name_prefix}-db-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

# --- ALB ----------------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = toset(var.alb_ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTP from ${each.value}"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each = toset(var.alb_ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from ${each.value}"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "To app instances only"
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

# --- Applicatif ---------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Web traffic from ALB SG only"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

# Sortie HTTPS/HTTP : paquets (dnf), agent SSM et API AWS, via la NAT.
resource "aws_vpc_security_group_egress_rule" "app_https" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS egress (packages, SSM, AWS APIs) via NAT"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "app_http" {
  security_group_id = aws_security_group.app.id
  description       = "HTTP egress (package mirrors) via NAT"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "app_to_db" {
  security_group_id            = aws_security_group.app.id
  description                  = "To database"
  referenced_security_group_id = aws_security_group.db.id
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
}

# --- Base de données ----------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "Connections from app SG only"
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
}
# Aucune règle de sortie sur le SG DB : RDS n'initie aucune connexion.

################################################################################
# IAM : rôle d'instance au moindre privilège
################################################################################

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    sid     = "Ec2AssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  count = var.create_instance_role ? 1 : 0

  name               = "${var.name_prefix}-instance-role"
  description        = "Web instances role for ${var.name_prefix}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json

  tags = var.tags
}

# Administration sans SSH ni port 22 : AWS Systems Manager Session Manager.
resource "aws_iam_role_policy_attachment" "ssm_core" {
  count = var.create_instance_role ? 1 : 0

  role       = aws_iam_role.instance[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "app_bucket" {
  statement {
    sid       = "ListAppBucket"
    actions   = ["s3:ListBucket"]
    resources = [var.app_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["assets/*", "logs/*"]
    }
  }

  statement {
    sid       = "ReadAssets"
    actions   = ["s3:GetObject"]
    resources = ["${var.app_bucket_arn}/assets/*"]
  }

  statement {
    sid       = "WriteLogs"
    actions   = ["s3:PutObject"]
    resources = ["${var.app_bucket_arn}/logs/*"]
  }
}

resource "aws_iam_role_policy" "app_bucket" {
  count = var.create_instance_role ? 1 : 0

  name   = "${var.name_prefix}-app-bucket-access"
  role   = aws_iam_role.instance[0].id
  policy = data.aws_iam_policy_document.app_bucket.json
}

resource "aws_iam_instance_profile" "instance" {
  count = var.create_instance_role ? 1 : 0

  name = "${var.name_prefix}-instance-profile"
  role = aws_iam_role.instance[0].name

  tags = var.tags
}
