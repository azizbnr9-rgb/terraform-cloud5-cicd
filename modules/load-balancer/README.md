# Module `load-balancer`

Application Load Balancer public, target group avec health check, listener HTTP (redirection HTTPS si certificat) et listener HTTPS optionnel.

## Ressources gérées

- `aws_lb`
- `aws_lb_listener`
- `aws_lb_target_group`

## Exemple d'utilisation

```hcl
module "load_balancer" {
  source = "../../modules/load-balancer"

  name_prefix       = "cloud5-dev"
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
}
```

## Entrées

| Nom | Description | Type | Défaut |
|-----|-------------|------|--------|
| `name_prefix` | Préfixe de nommage des ressources (<projet>-<environnement>). | `string` | **obligatoire** |
| `vpc_id` | VPC du target group. | `string` | **obligatoire** |
| `public_subnet_ids` | Sous-réseaux publics (au moins deux zones) où l'ALB est déployé. | `list(string)` | **obligatoire** |
| `alb_sg_id` | Security Group de l'ALB. | `string` | **obligatoire** |
| `app_port` | Port des instances ciblées. | `number` | `80` |
| `health_check_path` | Chemin HTTP vérifié par le health check du target group. | `string` | `"/health"` |
| `certificate_arn` | ARN d'un certificat ACM. S'il est fourni, un listener HTTPS est créé et HTTP redirige vers HTTPS. | `string` | `null` |
| `access_logs_bucket` | Bucket S3 recevant les journaux d'accès de l'ALB (null pour désactiver). | `string` | `null` |
| `enable_deletion_protection` | Protection contre la suppression de l'ALB (recommandé en prod). | `bool` | `false` |
| `tags` | Tags supplémentaires appliqués aux ressources du module. | `map(string)` | `{}` |

## Sorties

| Nom | Description |
|-----|-------------|
| `alb_dns_name` | Nom DNS public de l'ALB. |
| `alb_url` | URL d'accès à l'application. |
| `alb_arn_suffix` | Suffixe d'ARN de l'ALB (métriques CloudWatch). |
| `target_group_arn` | ARN du target group à associer à l'Auto Scaling Group. |

## Contraintes

- Terraform `>= 1.10.0`, fournisseur `hashicorp/aws ~> 5.0` (voir `versions.tf`).
- Les tags communs (Project, Environment, Owner, ManagedBy) sont appliqués par les `default_tags` du fournisseur dans l'environnement appelant.
