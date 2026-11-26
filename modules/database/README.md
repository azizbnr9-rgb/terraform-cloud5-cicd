# Module `database`

RDS MySQL privé : DB subnet group, groupe de paramètres (TLS obligatoire), stockage chiffré, mot de passe géré par AWS Secrets Manager.

## Ressources gérées

- `aws_db_instance`
- `aws_db_parameter_group`
- `aws_db_subnet_group`

## Exemple d'utilisation

```hcl
module "database" {
  source = "../../modules/database"

  name_prefix   = "cloud5-dev"
  db_subnet_ids = module.network.db_subnet_ids
  db_sg_id      = module.security.db_sg_id
}
```

## Entrées

| Nom | Description | Type | Défaut |
|-----|-------------|------|--------|
| `name_prefix` | Préfixe de nommage des ressources (<projet>-<environnement>). | `string` | **obligatoire** |
| `db_subnet_ids` | Sous-réseaux privés dédiés à la base (au moins deux zones). | `list(string)` | **obligatoire** |
| `db_sg_id` | Security Group de la base de données. | `string` | **obligatoire** |
| `engine_version` | Version majeure.mineure de MySQL. | `string` | `"8.0"` |
| `parameter_group_family` | Famille du groupe de paramètres RDS, cohérente avec engine_version. | `string` | `"mysql8.0"` |
| `instance_class` | Classe d'instance RDS. | `string` | `"db.t3.micro"` |
| `allocated_storage` | Stockage initial (Go). | `number` | `20` |
| `max_allocated_storage` | Plafond de l'extension automatique du stockage (Go, 0 pour désactiver). | `number` | `50` |
| `db_name` | Nom de la base créée à l'initialisation. | `string` | `"appdb"` |
| `master_username` | Utilisateur administrateur. Le mot de passe n'est jamais fourni : RDS le génère et le stocke dans AWS Secrets Manager. | `string` | `"dbadmin"` |
| `multi_az` | Instance de secours synchrone dans une autre zone (recommandé en prod). | `bool` | `false` |
| `backup_retention_period` | Durée de rétention des sauvegardes automatiques (jours). | `number` | `1` |
| `deletion_protection` | Empêche la suppression de la base (true en prod). | `bool` | `false` |
| `skip_final_snapshot` | Ne pas créer d'instantané final lors de la destruction (true en dev/test). | `bool` | `true` |
| `tags` | Tags supplémentaires appliqués aux ressources du module. | `map(string)` | `{}` |

## Sorties

| Nom | Description |
|-----|-------------|
| `db_identifier` | Identifiant de l'instance RDS. |
| `db_address` | Nom DNS privé de la base (résout vers une IP privée du VPC). |
| `db_port` | Port de la base. |
| `db_name` | Nom de la base applicative. |
| `db_master_secret_arn` | ARN du secret Secrets Manager contenant les identifiants administrateur (la valeur n'est jamais exposée). |

## Contraintes

- Terraform `>= 1.10.0`, fournisseur `hashicorp/aws ~> 5.0` (voir `versions.tf`).
- Les tags communs (Project, Environment, Owner, ManagedBy) sont appliqués par les `default_tags` du fournisseur dans l'environnement appelant.
