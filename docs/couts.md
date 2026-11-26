# Estimation des coûts

Prix publics AWS `us-east-1`, à la demande, hors offre gratuite (novembre 2026). Les montants mensuels supposent 730 h d'exécution continue ; la démonstration ne dure que quelques heures.

## Environnement dev (et test, identique)

| Ressource | Quantité | Prix unitaire | $/heure | $/mois |
|-----------|----------|---------------|---------|--------|
| NAT Gateway | 1 | 0,045 $/h + 0,045 $/Go traité | 0,045 | 32,85 |
| Application Load Balancer | 1 | 0,0225 $/h + ~1 LCU à 0,008 $/h | 0,031 | 22,27 |
| Adresses IPv4 publiques (EIP NAT + 2 IP ALB) | 3 | 0,005 $/h | 0,015 | 10,95 |
| EC2 t3.micro | 2 | 0,0104 $/h | 0,021 | 15,18 |
| EBS gp3 8 Go (racine, chiffré) | 2 | 0,08 $/Go-mois | 0,002 | 1,28 |
| RDS MySQL db.t3.micro Single-AZ | 1 | 0,017 $/h | 0,017 | 12,41 |
| Stockage RDS gp3 20 Go | 20 Go | 0,115 $/Go-mois | 0,003 | 2,30 |
| Secret RDS (Secrets Manager) | 1 | 0,40 $/mois | 0,001 | 0,40 |
| S3 (état + journaux), endpoint S3 Gateway | quelques Mo | négligeable / gratuit | ~0 | < 0,10 |
| **Total** | | | **≈ 0,135** | **≈ 98** |

Soit environ **3,2 $ par jour**. Une démonstration de 3 heures coûte environ **0,40 $**.

## Environnement prod

| Différence | Impact $/mois |
|------------|---------------|
| 2 NAT Gateways (une par zone) + 1 EIP supplémentaire | +36,5 |
| EC2 t3.small × 2 (0,0208 $/h) | +15,2 |
| RDS db.t3.small **Multi-AZ** (2 × 0,034 $/h) | +37,2 |
| Sauvegardes RDS 7 jours | ~+1 |
| **Total prod estimé** | **≈ 190 $/mois** |

## Ressources génératrices de coûts à surveiller

1. **NAT Gateway** : premier poste, facturé à l'heure même sans trafic.
2. **ALB** : facturé à l'heure dès sa création.
3. **IPv4 publiques** : facturées depuis février 2024 (0,005 $/h chacune).
4. **RDS** : facturé à l'heure tant que l'instance existe (même arrêtée au-delà de 7 jours, elle redémarre).
5. **EC2** : l'ASG relance automatiquement des instances : il faut détruire l'ASG, pas arrêter les instances.

## Mesures d'économie appliquées

- Une seule NAT en dev/test (`single_nat_gateway = true`).
- Endpoint S3 Gateway gratuit : le trafic vers S3 ne passe pas par la NAT.
- Instances t3.micro et db.t3.micro hors prod, stockage gp3.
- Cycle de vie S3 : passage en STANDARD_IA après 30 jours, expiration des journaux à 90 jours, des anciennes versions à 30 jours.
- **Destruction de dev/test dès la fin de la démonstration** (`terraform destroy` via le pipeline) ; le bucket d'état, quasi gratuit, est conservé.

Sur AWS Academy, ces coûts sont imputés au crédit du lab (budget limité, en général 50 à 100 $) : un environnement oublié une semaine consomme environ 22 $.
