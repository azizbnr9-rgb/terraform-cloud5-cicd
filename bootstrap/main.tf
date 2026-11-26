data "aws_caller_identity" "current" {}

locals {
  state_bucket     = "${var.project_name}-tfstate-${data.aws_caller_identity.current.account_id}"
  state_bucket_id  = var.create_bucket_with_cli ? terraform_data.state_bucket_cli[0].output.bucket : aws_s3_bucket.state[0].id
  state_bucket_arn = "arn:aws:s3:::${local.state_bucket_id}"
}

# Bucket de l'état Terraform : chiffré, versionné, privé, TLS obligatoire.
# Le verrouillage repose sur les fichiers .tflock natifs de S3 (use_lockfile).
resource "aws_s3_bucket" "state" {
  count = var.create_bucket_with_cli ? 0 : 1

  bucket = local.state_bucket

  tags = { Name = local.state_bucket }

  lifecycle {
    prevent_destroy = true
  }
}

# AWS Academy : bucket créé par l'AWS CLI (voir modules/storage/scripts/s3-bucket.sh).
resource "terraform_data" "state_bucket_cli" {
  count = var.create_bucket_with_cli ? 1 : 0

  input = {
    bucket = local.state_bucket
    script = "${path.module}/../modules/storage/scripts/s3-bucket.sh"
  }

  provisioner "local-exec" {
    command = "bash ${self.input.script} create ${self.input.bucket}"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = local.state_bucket_id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = local.state_bucket_id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = local.state_bucket_id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = local.state_bucket_id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = local.state_bucket_id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.state_noncurrent_retention_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.state]
}

data "aws_iam_policy_document" "state" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [local.state_bucket_arn, "${local.state_bucket_arn}/*"]

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
}

resource "aws_s3_bucket_policy" "state" {
  bucket = local.state_bucket_id
  policy = data.aws_iam_policy_document.state.json

  depends_on = [aws_s3_bucket_public_access_block.state]
}
