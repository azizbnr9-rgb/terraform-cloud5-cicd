#!/usr/bin/env bash
# Test "Sécurité DB" : la base ne doit pas être joignable depuis Internet.
source "$(dirname "$0")/common.sh" "${1:-dev}"
read -r addr port public <<<"$(aws rds describe-db-instances --db-instance-identifier "${PREFIX}-db" \
  --query 'DBInstances[0].[Endpoint.Address,Endpoint.Port,PubliclyAccessible]' --output text)"
echo "Endpoint RDS : $addr:$port (PubliclyAccessible=$public)"
ip=$(getent hosts "$addr" | awk '{print $1}' | head -n1)
echo "Résolution DNS depuis Internet : $ip (adresse privée du VPC)"
if timeout 10 bash -c "</dev/tcp/$addr/$port" 2>/dev/null; then
  echo "ECHEC : port $port joignable depuis Internet"; exit 1
else
  echo "Connexion TCP vers $addr:$port depuis Internet : REFUSÉE / injoignable"
fi
[ "$public" = "False" ] && echo "SUCCES : base non accessible depuis Internet" || { echo "ECHEC"; exit 1; }
