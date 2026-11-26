# Architecture

## Flux global

```
Développeurs -> Dépôt Git (GitHub) -> Pipeline CI/CD (GitHub Actions) -> Terraform -> AWS
                                                                            ├─ Réseau (module network)
                                                                            ├─ Load Balancer (module load-balancer)
                                                                            ├─ Auto Scaling (module compute)
                                                                            ├─ Base de données (module database)
                                                                            └─ Stockage (module storage)
```

Le schéma d'architecture détaillé (image) figure dans le rapport ; le diagramme Mermaid du README en donne une version texte.

## Chemin d'une requête

1. Le navigateur résout `cloud5-dev-alb-*.us-east-1.elb.amazonaws.com` vers les IP publiques de l'ALB, présent dans les deux sous-réseaux publics.
2. Le listener HTTP 80 transmet au target group `cloud5-dev-tg`, qui répartit en *round robin* entre les instances **saines** (health check `GET /health` toutes les 10 s).
3. L'instance nginx (sous-réseau privé App) répond une page indiquant son nom d'hôte, son identifiant et sa zone.
4. Les instances joignent RDS (sous-réseau privé DB) sur le port 3306, autorisé par le SG DB uniquement depuis le SG App.
5. Les mises à jour de paquets sortent par la NAT Gateway ; le trafic vers S3 passe par l'endpoint Gateway.

## Haute disponibilité

| Panne | Comportement |
|-------|-------------|
| Une instance | Le health check la marque *unhealthy* en ~20 s, l'ALB cesse de lui envoyer du trafic, l'ASG (health check ELB) la remplace. |
| Une zone (App) | L'ALB et l'ASG continuent sur l'autre zone ; l'ASG relance la capacité dans la zone restante. |
| Base (prod) | RDS Multi-AZ bascule sur le secours synchrone (60 à 120 s). |
| Charge CPU | Politique de suivi de cible : CPU moyen 50 %, entre `min_size` et `max_size`. |

## Dépendances entre modules

```
network ──► security ──► load-balancer ──► compute
   │            ▲              ▲
   │         storage ──────────┘ (journaux ALB, depends_on explicite)
   └──────────► database ◄── security
```

Les dépendances passent toutes par des sorties de modules explicites (`module.network.vpc_id`, `module.security.app_sg_id`, ...). La seule dépendance d'ordre non portée par une valeur (la politique du bucket doit exister avant l'ALB qui y écrit ses journaux) est déclarée par un `depends_on` commenté.

## Environnements

Les trois environnements appellent les mêmes modules avec un `main.tf` identique ; seules les valeurs de `terraform.tfvars` et la clé d'état diffèrent. Les plages réseau sont disjointes (10.20, 10.30, 10.40) pour permettre un appairage futur.
