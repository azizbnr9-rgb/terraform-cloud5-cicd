# Module `compute`

Launch Template (Amazon Linux 2023, IMDSv2, EBS chiffré, user_data nginx), Auto Scaling Group multi-AZ rattaché au target group et politique de scaling sur le CPU.

## Ressources gérées

- `aws_autoscaling_group`
- `aws_autoscaling_policy`
- `aws_launch_template`

## Exemple d'utilisation

```hcl
module "compute" {
  source = "../../modules/compute"

  name_prefix           = "cloud5-dev"
  project_name          = "cloud5"
  environment           = "dev"
  app_subnet_ids        = module.network.app_subnet_ids
  app_sg_id             = module.security.app_sg_id
  instance_profile_name = module.security.instance_profile_name
  target_group_arns     = [module.load_balancer.target_group_arn]
}
```

## Entrées

| Nom | Description | Type | Défaut |
|-----|-------------|------|--------|
| `name_prefix` | Préfixe de nommage des ressources (<projet>-<environnement>). | `string` | **obligatoire** |
| `project_name` | Nom du projet, affiché sur la page de démonstration. | `string` | **obligatoire** |
| `environment` | Environnement (dev, test, prod), affiché sur la page de démonstration. | `string` | **obligatoire** |
| `instance_type` | Type d'instance EC2. | `string` | `"t3.micro"` |
| `ami_ssm_parameter` | Paramètre SSM public donnant l'AMI la plus récente (Amazon Linux 2023 par défaut). | `string` | `"/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"` |
| `app_subnet_ids` | Sous-réseaux privés applicatifs où l'Auto Scaling Group lance les instances. | `list(string)` | **obligatoire** |
| `app_sg_id` | Security Group des instances applicatives. | `string` | **obligatoire** |
| `instance_profile_name` | Instance profile IAM attaché aux instances. | `string` | **obligatoire** |
| `target_group_arns` | Target groups de l'ALB dans lesquels les instances sont enregistrées. | `list(string)` | **obligatoire** |
| `min_size` | Nombre minimal d'instances. | `number` | `2` |
| `max_size` | Nombre maximal d'instances. | `number` | `4` |
| `desired_capacity` | Capacité souhaitée (null = min_size). | `number` | `null` |
| `root_volume_size` | Taille du volume racine chiffré, en Go. | `number` | `8` |
| `cpu_target_value` | Utilisation CPU moyenne visée par la politique de scaling (en %). | `number` | `50` |
| `health_check_grace_period` | Délai (secondes) avant la prise en compte du health check ELB après lancement. | `number` | `120` |
| `tags` | Tags propagés aux instances et volumes (les default_tags du provider ne s'y appliquent pas). | `map(string)` | `{}` |

## Sorties

| Nom | Description |
|-----|-------------|
| `asg_name` | Nom de l'Auto Scaling Group. |
| `launch_template_id` | Identifiant du Launch Template. |
| `launch_template_version` | Dernière version du Launch Template. |
| `ami_id` | AMI utilisée par les instances. |

## Contraintes

- Terraform `>= 1.10.0`, fournisseur `hashicorp/aws ~> 5.0` (voir `versions.tf`).
- Les tags communs (Project, Environment, Owner, ManagedBy) sont appliqués par les `default_tags` du fournisseur dans l'environnement appelant.
