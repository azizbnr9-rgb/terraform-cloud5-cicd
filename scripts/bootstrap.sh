#!/usr/bin/env bash
# Crée (ou met à jour) le bucket du backend distant, puis y migre l'état du bootstrap.
# Prérequis : identifiants AWS dans l'environnement (jamais dans le dépôt).
set -euo pipefail
cd "$(dirname "$0")/../bootstrap"
REGION="${AWS_REGION:-us-east-1}"
PROJECT="${PROJECT_NAME:-cloud5}"
OWNER="${OWNER:?Définir OWNER}"
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
BUCKET="${PROJECT}-tfstate-${ACCOUNT}"
write_backend() {
  cat > backend.tf <<HCL
terraform {
  backend "s3" {
    bucket       = "${BUCKET}"
    key          = "bootstrap/terraform.tfstate"
    region       = "${REGION}"
    encrypt      = true
    use_lockfile = true
  }
}
HCL
}
if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "Bucket $BUCKET existant : mise à jour avec l'état distant"
  write_backend
  terraform init -input=false
  terraform apply -input=false -auto-approve -var "owner=${OWNER}" -var "aws_region=${REGION}"
else
  echo "Création du bucket $BUCKET (état local temporaire)"
  rm -f backend.tf
  terraform init -input=false
  terraform apply -input=false -auto-approve -var "owner=${OWNER}" -var "aws_region=${REGION}"
  write_backend
  terraform init -input=false -migrate-state -force-copy
  rm -f terraform.tfstate terraform.tfstate.backup
fi
terraform output
