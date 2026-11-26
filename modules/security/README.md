# Module `security`

Security Groups chaînés (Internet -> ALB -> App -> DB) et rôle IAM d'instance au moindre privilège (SSM + accès S3 limité), ou réutilisation d'un instance profile existant.

## Ressources gérées

- `aws_iam_instance_profile`
- `aws_iam_role`
- `aws_iam_role_policy`
- `aws_iam_role_policy_attachment`
- `aws_security_group`
- `aws_vpc_security_group_egress_rule`
- `aws_vpc_security_group_ingress_rule`

## Exemple d'utilisation

```hcl
module "security" {
  source = "../../modules/security"

  name_prefix    = "cloud5-dev"
  vpc_id         = module.network.vpc_id
  app_bucket_arn = module.storage.bucket_arn
}
```

## Entrées

| Nom | Description | Type | Défaut |
|-----|-------------|------|--------|
| `name_prefix` | Préfixe de nommage des ressources (<projet>-<environnement>). | `string` | **obligatoire** |
| `vpc_id` | VPC dans lequel les Security Groups sont créés. | `string` | **obligatoire** |
| `alb_ingress_cidrs` | Plages IPv4 autorisées à joindre le Load Balancer en HTTP/HTTPS. | `list(string)` | `["0.0.0.0/0"]` |
| `app_port` | Port d'écoute de l'application sur les instances. | `number` | `80` |
| `db_port` | Port de la base de données (3306 pour MySQL). | `number` | `3306` |
| `create_instance_role` | true : crée un rôle IAM d'instance au moindre privilège. false : réutilise un instance profile existant (comptes AWS Academy où la création de rôles est interdite). | `bool` | `true` |
| `existing_instance_profile_name` | Nom de l'instance profile existant à utiliser lorsque create_instance_role = false (ex : LabInstanceProfile). | `string` | `null` |
| `app_bucket_arn` | ARN du bucket S3 applicatif auquel les instances peuvent accéder (lecture assets/, écriture logs/). | `string` | **obligatoire** |
| `tags` | Tags supplémentaires appliqués aux ressources du module. | `map(string)` | `{}` |

## Sorties

| Nom | Description |
|-----|-------------|
| `alb_sg_id` | Security Group du Load Balancer. |
| `app_sg_id` | Security Group des instances applicatives. |
| `db_sg_id` | Security Group de la base de données. |
| `instance_profile_name` | Instance profile IAM à attacher aux instances (créé par le module ou existant). |

## Contraintes

- Terraform `>= 1.10.0`, fournisseur `hashicorp/aws ~> 5.0` (voir `versions.tf`).
- Les tags communs (Project, Environment, Owner, ManagedBy) sont appliqués par les `default_tags` du fournisseur dans l'environnement appelant.
