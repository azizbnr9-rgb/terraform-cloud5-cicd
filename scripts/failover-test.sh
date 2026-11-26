#!/usr/bin/env bash
# Test "Panne" : arrêt brutal d'une instance pendant un trafic continu.
source "$(dirname "$0")/common.sh" "${1:-dev}"
DURATION="${2:-240}"
URL="http://$(alb_dns)"
echo "--- Instances avant la panne ---"; asg_instances
victim=$(asg_instances | awk '$3=="InService"{print $1; exit}')
echo "Instance arrêtée : $victim"
aws ec2 stop-instances --instance-ids "$victim" --output text >/dev/null
start=$(date +%s); total=0; ok=0; fail=0
while [ $(( $(date +%s) - start )) -lt "$DURATION" ]; do
  code=$(curl -s -o /dev/null -m 5 -w '%{http_code}' "$URL/" || echo 000)
  total=$((total+1)); if [ "$code" = "200" ]; then ok=$((ok+1)); else fail=$((fail+1)); echo "$(date -u +%T) HTTP $code"; fi
  sleep 1
done
echo "--- Instances après la panne (l'ASG remplace l'instance défaillante) ---"; asg_instances
echo "--- Target group ---"; tg_health
pct=$(awk -v o="$ok" -v t="$total" 'BEGIN{printf "%.2f", 100*o/t}')
echo "Requêtes : $total, succès : $ok, échecs : $fail, disponibilité : $pct %"
awk -v p="$pct" 'BEGIN{exit !(p>=95)}' && echo "SUCCES : service toujours disponible" || { echo "ECHEC"; exit 1; }
