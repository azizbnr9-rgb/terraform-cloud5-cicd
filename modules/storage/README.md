# Module `storage`

Bucket S3 applicatif (ressources, journaux, sauvegardes) : accès public bloqué, versioning, chiffrement, TLS obligatoire, cycle de vie et réception des journaux ALB.

## Ressources gérées

- `aws_s3_bucket`
- `aws_s3_bucket_lifecycle_configuration`
- `aws_s3_bucket_ownership_controls`
- `aws_s3_bucket_policy`
- `aws_s3_bucket_public_access_block`
- `aws_s3_bucket_server_side_encryption_configuration`
- `aws_s3_bucket_versioning`
- `terraform_data`

## Exemple d'utilisation

```hcl
module "storage" {
  source = "../../modules/storage"

  name_prefix   = "cloud5-dev"
  bucket_suffix = data.aws_caller_identity.current.account_id
  force_destroy = true
}
```

## Entrées

| Nom | Description | Type | Défaut |
|-----|-------------|------|--------|
| `name_prefix` | Préfixe de nommage des ressources (<projet>-<environnement>). | `string` | **obligatoire** |
| `bucket_suffix` | Suffixe garantissant l'unicité mondiale du nom de bucket (ex : identifiant du compte AWS). | `string` | **obligatoire** |
| `force_destroy` | Autorise terraform destroy à vider le bucket (true en dev/test, false en prod). | `bool` | `false` |
| `enable_alb_log_delivery` | Ajoute la politique autorisant l'ALB à écrire ses journaux d'accès sous le préfixe alb/. | `bool` | `true` |
| `ia_transition_days` | Nombre de jours avant passage des objets en classe STANDARD_IA (minimum 30). | `number` | `30` |
| `log_expiration_days` | Durée de conservation des journaux (préfixes logs/ et alb/), en jours. | `number` | `90` |
| `noncurrent_version_expiration_days` | Durée de conservation des anciennes versions d'objets, en jours. | `number` | `30` |
| `create_bucket_with_cli` | Crée le bucket via l'AWS CLI au lieu de aws_s3_bucket (AWS Academy : une SCP interdit la lecture de la configuration Object Lock). | `bool` | `false` |
| `tags` | Tags supplémentaires appliqués aux ressources du module. | `map(string)` | `{}` |

## Sorties

| Nom | Description |
|-----|-------------|
| `bucket_name` | Nom du bucket applicatif (assets, journaux, sauvegardes). |
| `bucket_arn` | ARN du bucket applicatif. |
| `alb_logs_prefix` | Préfixe des journaux d'accès ALB dans le bucket. |

## Contraintes

- Terraform `>= 1.10.0`, fournisseur `hashicorp/aws ~> 5.0` (voir `versions.tf`).
- Les tags communs (Project, Environment, Owner, ManagedBy) sont appliqués par les `default_tags` du fournisseur dans l'environnement appelant.
