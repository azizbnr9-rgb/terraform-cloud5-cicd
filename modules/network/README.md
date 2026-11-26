# Module `network`

VPC multi-AZ, sous-réseaux publics / privés applicatifs / privés base de données, Internet Gateway, NAT Gateway(s), tables de routage et endpoint S3.

## Ressources gérées

- `aws_default_security_group`
- `aws_eip`
- `aws_internet_gateway`
- `aws_nat_gateway`
- `aws_route`
- `aws_route_table`
- `aws_route_table_association`
- `aws_subnet`
- `aws_vpc`
- `aws_vpc_endpoint`

## Exemple d'utilisation

```hcl
module "network" {
  source = "../../modules/network"

  name_prefix         = "cloud5-dev"
  vpc_cidr            = "10.20.0.0/16"
  azs                 = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs = ["10.20.1.0/24", "10.20.2.0/24"]
  app_subnet_cidrs    = ["10.20.11.0/24", "10.20.12.0/24"]
  db_subnet_cidrs     = ["10.20.21.0/24", "10.20.22.0/24"]
  single_nat_gateway  = true
}
```

## Entrées

| Nom | Description | Type | Défaut |
|-----|-------------|------|--------|
| `name_prefix` | Préfixe de nommage des ressources (<projet>-<environnement>). | `string` | **obligatoire** |
| `vpc_cidr` | Bloc CIDR principal du VPC (ex : 10.20.0.0/16). | `string` | **obligatoire** |
| `azs` | Zones de disponibilité utilisées (au moins deux pour la haute disponibilité). | `list(string)` | **obligatoire** |
| `public_subnet_cidrs` | CIDR des sous-réseaux publics (ALB, NAT), un par zone, dans l'ordre de var.azs. | `list(string)` | **obligatoire** |
| `app_subnet_cidrs` | CIDR des sous-réseaux privés applicatifs, un par zone, dans l'ordre de var.azs. | `list(string)` | **obligatoire** |
| `db_subnet_cidrs` | CIDR des sous-réseaux privés dédiés à la base de données, un par zone. | `list(string)` | **obligatoire** |
| `enable_nat_gateway` | Crée des NAT Gateways pour la sortie Internet contrôlée des sous-réseaux applicatifs. | `bool` | `true` |
| `single_nat_gateway` | true : une seule NAT Gateway (économique, dev/test). false : une NAT par zone (haute disponibilité, prod). | `bool` | `true` |
| `enable_s3_endpoint` | Crée un VPC endpoint S3 de type Gateway (gratuit) pour éviter le passage par la NAT vers S3. | `bool` | `true` |
| `tags` | Tags supplémentaires appliqués aux ressources du module. | `map(string)` | `{}` |

## Sorties

| Nom | Description |
|-----|-------------|
| `vpc_id` | Identifiant du VPC. |
| `vpc_cidr` | Bloc CIDR du VPC. |
| `public_subnet_ids` | Sous-réseaux publics, dans l'ordre des zones. |
| `app_subnet_ids` | Sous-réseaux privés applicatifs, dans l'ordre des zones. |
| `db_subnet_ids` | Sous-réseaux privés de base de données, dans l'ordre des zones. |
| `nat_public_ips` | Adresses IP publiques de sortie (NAT). |

## Contraintes

- Terraform `>= 1.10.0`, fournisseur `hashicorp/aws ~> 5.0` (voir `versions.tf`).
- Les tags communs (Project, Environment, Owner, ManagedBy) sont appliqués par les `default_tags` du fournisseur dans l'environnement appelant.
