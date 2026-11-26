# Backend distant S3 : état chiffré, versionné, verrouillé (fichier .tflock natif S3).
# Le nom du bucket dépend du compte AWS : il est fourni à l'initialisation
#   terraform init -backend-config="bucket=cloud5-tfstate-<ACCOUNT_ID>"
terraform {
  backend "s3" {
    key          = "test/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
