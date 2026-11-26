data "aws_caller_identity" "current" {}

# Compte AWS du service Elastic Load Balancing de la région (journaux d'accès ALB).
data "aws_elb_service_account" "this" {}

locals {
  bucket_name = "${var.name_prefix}-app-${var.bucket_suffix}"
  bucket_id   = var.create_bucket_with_cli ? terraform_data.bucket_cli[0].output.bucket : aws_s3_bucket.this[0].id
  bucket_arn  = "arn:aws:s3:::${local.bucket_id}"
}

# Cas standard : bucket géré par la ressource aws_s3_bucket.
resource "aws_s3_bucket" "this" {
  count = var.create_bucket_with_cli ? 0 : 1

  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = merge(var.tags, { Name = local.bucket_name })
}

# AWS Academy : une SCP interdit s3:GetBucketObjectLockConfiguration, lu par aws_s3_bucket.
# Le bucket est alors créé et supprimé par l'AWS CLI ; ses propriétés restent gérées ci-dessous.
resource "terraform_data" "bucket_cli" {
  count = var.create_bucket_with_cli ? 1 : 0

  # Un nouveau nom de bucket entraîne la recréation (et l'exécution des provisioners).
  triggers_replace = local.bucket_name

  input = {
    bucket        = local.bucket_name
    force_destroy = var.force_destroy
    script        = "${path.module}/scripts/s3-bucket.sh"
    tags          = jsonencode(merge(var.tags, { Name = local.bucket_name }))
  }

  provisioner "local-exec" {
    command     = "bash ${self.input.script} create ${self.input.bucket}"
    environment = { TAGS_JSON = self.input.tags }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "bash ${self.input.script} delete ${self.input.bucket} ${self.input.force_destroy}"
  }
}

# Aucun accès public, quelle que soit la politique ou l'ACL.
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = local.bucket_id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = local.bucket_id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = local.bucket_id

  versioning_configuration {
    status = "Enabled"
  }
}

# SSE-S3 (AES-256) : seul chiffrement compatible avec les journaux d'accès ALB.
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = local.bucket_id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = local.bucket_id

  rule {
    id     = "transition-standard-ia"
    status = "Enabled"

    filter {}

    transition {
      days          = var.ia_transition_days
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  rule {
    id     = "expire-app-logs"
    status = "Enabled"

    filter {
      prefix = "logs/"
    }

    expiration {
      days = var.log_expiration_days
    }
  }

  rule {
    id     = "expire-alb-logs"
    status = "Enabled"

    filter {
      prefix = "alb/"
    }

    expiration {
      days = var.log_expiration_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

data "aws_iam_policy_document" "bucket" {
  # Refuse toute requête non chiffrée en transit.
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [local.bucket_arn, "${local.bucket_arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  dynamic "statement" {
    for_each = var.enable_alb_log_delivery ? [1] : []

    content {
      sid       = "AllowAlbAccessLogs"
      effect    = "Allow"
      actions   = ["s3:PutObject"]
      resources = ["${local.bucket_arn}/alb/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

      principals {
        type        = "AWS"
        identifiers = [data.aws_elb_service_account.this.arn]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = local.bucket_id
  policy = data.aws_iam_policy_document.bucket.json

  # Le blocage d'accès public doit exister avant la politique.
  depends_on = [aws_s3_bucket_public_access_block.this]
}
