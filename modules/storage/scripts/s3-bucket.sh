#!/usr/bin/env bash
# Création / suppression d'un bucket S3 par l'AWS CLI.
# Utilisé quand une SCP (AWS Academy Learner Lab) interdit s3:GetBucketObjectLockConfiguration,
# que la ressource aws_s3_bucket lit systématiquement. Toutes les autres propriétés du bucket
# (versioning, chiffrement, accès public, politique, cycle de vie) restent gérées par Terraform.
# Usage : s3-bucket.sh create <bucket>   |   s3-bucket.sh delete <bucket> <force_destroy>
set -euo pipefail
action="$1"
bucket="$2"
force="${3:-false}"
region="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"

case "$action" in
  create)
    if ! aws s3api head-bucket --bucket "$bucket" 2>/dev/null; then
      if [ "$region" = "us-east-1" ]; then
        aws s3api create-bucket --bucket "$bucket" >/dev/null
      else
        aws s3api create-bucket --bucket "$bucket" --create-bucket-configuration "LocationConstraint=$region" >/dev/null
      fi
      aws s3api wait bucket-exists --bucket "$bucket"
    fi
    if [ -n "${TAGS_JSON:-}" ]; then
      tagset=$(python3 -c 'import json, os; print(json.dumps({"TagSet": [{"Key": k, "Value": v} for k, v in json.loads(os.environ["TAGS_JSON"]).items()]}))')
      aws s3api put-bucket-tagging --bucket "$bucket" --tagging "$tagset"
    fi
    echo "Bucket $bucket prêt"
    ;;
  delete)
    aws s3api head-bucket --bucket "$bucket" 2>/dev/null || { echo "Bucket $bucket déjà supprimé"; exit 0; }
    if [ "$force" = "true" ]; then
      python3 - "$bucket" <<'PY'
import json, subprocess, sys
bucket = sys.argv[1]
while True:
    raw = subprocess.check_output(["aws", "s3api", "list-object-versions", "--bucket", bucket, "--max-items", "1000", "--output", "json"])
    data = json.loads(raw or b"{}")
    objects = [{"Key": o["Key"], "VersionId": o["VersionId"]} for o in (data.get("Versions") or []) + (data.get("DeleteMarkers") or [])]
    if not objects:
        break
    subprocess.check_call(["aws", "s3api", "delete-objects", "--bucket", bucket, "--delete", json.dumps({"Objects": objects, "Quiet": True})])
PY
    fi
    aws s3api delete-bucket --bucket "$bucket"
    echo "Bucket $bucket supprimé"
    ;;
  *)
    echo "Action inconnue : $action" >&2
    exit 1
    ;;
esac
