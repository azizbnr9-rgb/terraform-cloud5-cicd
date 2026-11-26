#!/usr/bin/env bash
# Fonctions communes aux scripts de test. Usage : source scripts/common.sh <env>
set -euo pipefail
ENVIRONMENT="${1:-dev}"
PROJECT="${PROJECT_NAME:-cloud5cicd}"
PREFIX="${PROJECT}-${ENVIRONMENT}"
export AWS_REGION="${AWS_REGION:-us-east-1}"

alb_dns() {
  aws elbv2 describe-load-balancers --names "${PREFIX}-alb" \
    --query 'LoadBalancers[0].DNSName' --output text
}

asg_instances() {
  aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "${PREFIX}-asg" \
    --query 'AutoScalingGroups[0].Instances[].[InstanceId,AvailabilityZone,LifecycleState,HealthStatus]' --output text
}

tg_health() {
  local tg_arn
  tg_arn=$(aws elbv2 describe-target-groups --names "${PREFIX}-tg" --query 'TargetGroups[0].TargetGroupArn' --output text)
  aws elbv2 describe-target-health --target-group-arn "$tg_arn" \
    --query 'TargetHealthDescriptions[].[Target.Id,TargetHealth.State]' --output text
}

wait_healthy() {
  local wanted="$1" timeout="${2:-600}" start
  start=$(date +%s)
  while true; do
    local n
    n=$(tg_health | awk '$2=="healthy"' | wc -l)
    echo "$(date -u +%T) cibles healthy : $n / $wanted"
    [ "$n" -ge "$wanted" ] && return 0
    [ $(( $(date +%s) - start )) -gt "$timeout" ] && { echo "Délai dépassé"; return 1; }
    sleep 15
  done
}
