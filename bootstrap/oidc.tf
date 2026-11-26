################################################################################
# Identité fédérée GitHub Actions -> AWS (OIDC), sans clé d'accès longue durée.
# Activée avec enable_github_oidc = true sur un compte AWS standard.
# Sur AWS Academy, la création IAM est interdite : le pipeline utilise alors
# les identifiants temporaires du lab stockés dans les secrets GitHub.
################################################################################

locals {
  oidc_count = var.enable_github_oidc ? 1 : 0
  account_id = data.aws_caller_identity.current.account_id
  prefix     = var.project_name
}

resource "aws_iam_openid_connect_provider" "github" {
  count = local.oidc_count

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

# --- Rôle "plan" : lecture seule + verrou d'état ------------------------------
# Assumable uniquement depuis les Pull Requests et la branche main du dépôt.

data "aws_iam_policy_document" "plan_trust" {
  count = local.oidc_count

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [
        "repo:${var.github_repository}:pull_request",
        "repo:${var.github_repository}:ref:refs/heads/main",
      ]
    }
  }
}

resource "aws_iam_role" "plan" {
  count = local.oidc_count

  name                 = "${local.prefix}-github-plan"
  description          = "GitHub Actions - terraform plan (read-only)"
  assume_role_policy   = data.aws_iam_policy_document.plan_trust[0].json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  count = local.oidc_count

  role       = aws_iam_role.plan[0].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "plan_state" {
  statement {
    sid       = "ListState"
    actions   = ["s3:ListBucket"]
    resources = [local.state_bucket_arn]
  }

  statement {
    sid       = "ReadState"
    actions   = ["s3:GetObject"]
    resources = ["${local.state_bucket_arn}/*"]
  }

  # Le plan pose et retire un verrou, mais ne peut jamais réécrire l'état.
  statement {
    sid       = "LockOnly"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${local.state_bucket_arn}/*.tflock"]
  }
}

resource "aws_iam_role_policy" "plan_state" {
  count = local.oidc_count

  name   = "terraform-state-lock"
  role   = aws_iam_role.plan[0].id
  policy = data.aws_iam_policy_document.plan_state.json
}

# --- Rôle "apply" : écriture limitée aux services du projet --------------------
# Assumable uniquement par les jobs liés aux environnements GitHub protégés.

data "aws_iam_policy_document" "apply_trust" {
  count = local.oidc_count

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for env in ["dev", "test", "prod"] : "repo:${var.github_repository}:environment:${env}"]
    }
  }
}

resource "aws_iam_role" "apply" {
  count = local.oidc_count

  name                 = "${local.prefix}-github-apply"
  description          = "GitHub Actions - terraform apply on protected environments"
  assume_role_policy   = data.aws_iam_policy_document.apply_trust[0].json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "apply_readonly" {
  count = local.oidc_count

  role       = aws_iam_role.apply[0].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "apply" {
  statement {
    sid       = "StateReadWrite"
    actions   = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [local.state_bucket_arn, "${local.state_bucket_arn}/*"]
  }

  # Services de l'infrastructure, limités à la région du projet.
  statement {
    sid       = "ProjectServices"
    actions   = ["ec2:*", "elasticloadbalancing:*", "autoscaling:*", "rds:*", "cloudwatch:PutMetricAlarm", "cloudwatch:DeleteAlarms"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid       = "ProjectBuckets"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::${local.prefix}-*-app-${local.account_id}", "arn:aws:s3:::${local.prefix}-*-app-${local.account_id}/*"]
  }

  # IAM limité aux rôles et profils préfixés par le projet.
  statement {
    sid     = "ProjectIamRoles"
    actions = [
      "iam:CreateRole", "iam:DeleteRole", "iam:TagRole", "iam:UntagRole", "iam:UpdateAssumeRolePolicy",
      "iam:AttachRolePolicy", "iam:DetachRolePolicy", "iam:PutRolePolicy", "iam:DeleteRolePolicy",
      "iam:CreateInstanceProfile", "iam:DeleteInstanceProfile", "iam:TagInstanceProfile",
      "iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile",
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:role/${local.prefix}-*",
      "arn:aws:iam::${local.account_id}:instance-profile/${local.prefix}-*",
    ]
  }

  statement {
    sid       = "PassInstanceRoleToEc2Only"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${local.account_id}:role/${local.prefix}-*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }

  statement {
    sid       = "ServiceLinkedRoles"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["autoscaling.amazonaws.com", "elasticloadbalancing.amazonaws.com", "rds.amazonaws.com"]
    }
  }

  # Secret RDS géré par AWS (manage_master_user_password) et clés AWS managées.
  statement {
    sid       = "RdsManagedSecret"
    actions   = ["secretsmanager:CreateSecret", "secretsmanager:DeleteSecret", "secretsmanager:TagResource", "secretsmanager:RotateSecret"]
    resources = ["arn:aws:secretsmanager:${var.aws_region}:${local.account_id}:secret:rds!*"]
  }

  statement {
    sid       = "KmsViaServices"
    actions   = ["kms:DescribeKey", "kms:CreateGrant", "kms:Decrypt", "kms:GenerateDataKey*"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["rds.${var.aws_region}.amazonaws.com", "secretsmanager.${var.aws_region}.amazonaws.com", "ec2.${var.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "apply" {
  count = local.oidc_count

  name   = "terraform-apply-scoped"
  role   = aws_iam_role.apply[0].id
  policy = data.aws_iam_policy_document.apply.json
}
