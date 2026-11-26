output "state_bucket" {
  description = "Bucket S3 du backend distant (à passer en -backend-config=bucket=...)."
  value       = local.state_bucket_id
}

output "plan_role_arn" {
  description = "Rôle OIDC du job plan (variable GitHub AWS_PLAN_ROLE_ARN)."
  value       = try(aws_iam_role.plan[0].arn, null)
}

output "apply_role_arn" {
  description = "Rôle OIDC des jobs apply/destroy (variable GitHub AWS_APPLY_ROLE_ARN)."
  value       = try(aws_iam_role.apply[0].arn, null)
}
