# Choix de sécurité

## 1. Réseau : défense en profondeur

| Couche | Mesure |
|--------|--------|
| Sous-réseaux publics | Seuls l'ALB et la NAT Gateway y résident. `map_public_ip_on_launch = false`. |
| Sous-réseaux privés App | Aucune IP publique, aucune route entrante depuis Internet. Sortie uniquement via la NAT (paquets, SSM). |
| Sous-réseaux privés DB | Table de routage **isolée, sans route 0.0.0.0/0** : la base ne peut ni être jointe ni joindre Internet. |
| SG par défaut | Vidé de toutes ses règles (`aws_default_security_group`). |

## 2. Security Groups chaînés

| SG | Entrée | Sortie |
|----|--------|--------|
| `cloud5-<env>-alb-sg` | TCP 80 et 443 depuis `alb_ingress_cidrs` (0.0.0.0/0 par défaut) | TCP 80 vers le SG App uniquement |
| `cloud5-<env>-app-sg` | TCP 80 **depuis le SG de l'ALB uniquement** | 443/80 vers Internet via NAT, 3306 vers le SG DB |
| `cloud5-<env>-db-sg` | TCP 3306 **depuis le SG App uniquement** | aucune |

Les règles référencent des Security Groups et non des plages IP : une instance ajoutée par l'ASG hérite automatiquement des bons accès.

## 3. Accès administratif limité et justifié

- **Aucun port SSH (22) ouvert, aucune paire de clés.** L'administration passe par AWS Systems Manager Session Manager (rôle `AmazonSSMManagedInstanceCore`), qui est authentifié par IAM et journalisé dans CloudTrail.
- Justification : le seul besoin d'administration est le diagnostic d'une instance ; il ne nécessite aucune ouverture réseau.
- La base n'a pas d'accès administratif public ; l'administration se fait depuis une instance applicative via Session Manager.

## 4. Secrets

- **Aucun secret dans Git** : `.gitignore` exclut états, plans, `*.secret.tfvars`, `.env`, clés.
- **Mot de passe RDS** : `manage_master_user_password = true`. RDS génère le mot de passe et le stocke dans AWS Secrets Manager. Il n'apparaît ni dans le code, ni dans `terraform.tfvars`, ni dans l'état Terraform.
- **Pipeline** : OIDC (jetons d'une heure, aucune clé stockée) sur un compte standard ; sur AWS Academy, identifiants temporaires du lab dans les *secrets* GitHub chiffrés, masqués dans les journaux, expirant avec la session.
- L'identifiant de compte AWS est masqué dans les journaux (`mask-aws-account-id`, `::add-mask::`).

## 5. Chiffrement

| Donnée | Chiffrement |
|--------|-------------|
| État Terraform | SSE-S3 AES-256 + Bucket Key, `encrypt = true` dans le backend, TLS imposé par politique |
| Bucket applicatif | SSE-S3 AES-256 (compatible journaux ALB), TLS imposé |
| RDS | `storage_encrypted = true` (KMS `aws/rds`), `require_secure_transport = 1` (TLS obligatoire) |
| Volumes EC2 | EBS gp3 chiffrés |
| Secret RDS | Secrets Manager (KMS) |

## 6. S3

Tous les buckets : blocage complet de l'accès public (4 options), `BucketOwnerEnforced` (ACL désactivées), versioning, refus des requêtes non TLS. Seule exception documentée : le compte du service Elastic Load Balancing de la région est autorisé à écrire sous `alb/AWSLogs/<compte>/` pour les journaux d'accès, ce qui n'est pas un accès public.

## 7. IAM au moindre privilège

| Identité | Permissions |
|----------|-------------|
| Rôle d'instance (compte standard) | SSM Core ; `s3:GetObject` sur `assets/*`, `s3:PutObject` sur `logs/*` du seul bucket applicatif |
| Rôle pipeline *plan* | `ReadOnlyAccess` + lecture de l'état + écriture des seuls fichiers `*.tflock`. Assumable depuis les PR et `main`. |
| Rôle pipeline *apply* | EC2/ELB/ASG/RDS limités à la région, S3 limité aux buckets du projet, IAM limité aux rôles `cloud5-*`, `PassRole` vers EC2 uniquement. Assumable uniquement depuis les environnements GitHub `dev`, `test`, `prod`. |
| AWS Academy | La création IAM est interdite : `LabInstanceProfile` et le rôle du lab sont utilisés. Écart documenté, imposé par la plateforme. |

## 8. Instances

- IMDSv2 obligatoire (`http_tokens = required`, hop limit 1) : protège contre le vol d'identifiants par SSRF.
- AMI Amazon Linux 2023 la plus récente via paramètre SSM public.
- Remplacement progressif (*instance refresh*) à chaque nouvelle version du Launch Template.

## 9. ALB

- `drop_invalid_header_fields = true` (protection contre le *request smuggling*).
- HTTPS prêt : si `certificate_arn` est fourni, listener 443 avec la politique `ELBSecurityPolicy-TLS13-1-2-2021-06` et redirection 301 de HTTP vers HTTPS.
- Protection contre la suppression activée en prod.

## 10. Pipeline et état

- Un déploiement prod n'est **jamais** déclenché automatiquement : seul `dev` est appliqué sur push vers `main` ; test/prod exigent un lancement manuel depuis `main` **et** l'approbation d'un relecteur (environnements GitHub protégés limités à la branche `main`).
- Le job apply applique le fichier `tfplan` produit et relu au job plan.
- Verrouillage d'état natif S3 (`use_lockfile`), états séparés par environnement, versioning pour restaurer un état corrompu.
- Analyse statique Checkov exécutée à chaque pipeline.
