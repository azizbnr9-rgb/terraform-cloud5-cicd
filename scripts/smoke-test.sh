#!/usr/bin/env bash
# Test "Accès Web" + "Répartition" : N requêtes sur l'ALB, comptage des hôtes distincts.
source "$(dirname "$0")/common.sh" "${1:-dev}"
N="${2:-30}"
URL="http://$(alb_dns)"
echo "URL de l'ALB : $URL"
echo "--- État du target group ---"; tg_health
ok=0; : > /tmp/hosts.txt
for i in $(seq 1 "$N"); do
  body=$(curl -s -m 5 -w '\n%{http_code}' "$URL/") || true
  code=$(tail -n1 <<<"$body")
  [ "$code" = "200" ] && ok=$((ok+1))
  grep -oE 'i-[0-9a-f]{8,17}' <<<"$body" | head -n1 >> /tmp/hosts.txt || true
done
echo "--- Résultat ---"
echo "Réponses HTTP 200 : $ok / $N"
echo "Répartition par instance :"; sort /tmp/hosts.txt | uniq -c
distinct=$(sort -u /tmp/hosts.txt | wc -l)
echo "Hôtes distincts observés : $distinct"
[ "$ok" -eq "$N" ] && [ "$distinct" -ge 2 ] && echo "SUCCES : page disponible et trafic réparti" || { echo "ECHEC"; exit 1; }
