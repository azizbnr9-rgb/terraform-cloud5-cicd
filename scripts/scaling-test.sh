#!/usr/bin/env bash
# Test "Auto Scaling" : capacité portée temporairement à 3 puis remise à la valeur Terraform.
source "$(dirname "$0")/common.sh" "${1:-dev}"
TARGET="${2:-3}"
orig=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "${PREFIX}-asg" --query 'AutoScalingGroups[0].DesiredCapacity' --output text)
echo "Capacité initiale : $orig -> nouvelle capacité : $TARGET"
aws autoscaling set-desired-capacity --auto-scaling-group-name "${PREFIX}-asg" --desired-capacity "$TARGET"
wait_healthy "$TARGET" 600
echo "--- Instances ---"; asg_instances
echo "Retour à la capacité gérée par Terraform : $orig"
aws autoscaling set-desired-capacity --auto-scaling-group-name "${PREFIX}-asg" --desired-capacity "$orig"
sleep 60; asg_instances
echo "SUCCES : le nombre d'instances suit la capacité demandée"
