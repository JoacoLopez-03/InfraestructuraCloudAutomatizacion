#!/usr/bin/env bash
# FinOps: escala el node group a 0 fuera de horario para ahorrar costos.
# Pensado para ejecutarse desde un cron / EventBridge Scheduler.
set -euo pipefail

CLUSTER="devops-final-dev-eks"
NODEGROUP="devops-final-dev-eks-ng"
REGION="us-east-1"
ACTION="${1:-down}"   # up | down

if [ "$ACTION" = "down" ]; then
  echo "Apagando cluster (escala a 0)..."
  aws eks update-nodegroup-config --cluster-name "$CLUSTER" \
    --nodegroup-name "$NODEGROUP" --region "$REGION" \
    --scaling-config minSize=0,maxSize=4,desiredSize=0
else
  echo "Encendiendo cluster..."
  aws eks update-nodegroup-config --cluster-name "$CLUSTER" \
    --nodegroup-name "$NODEGROUP" --region "$REGION" \
    --scaling-config minSize=1,maxSize=4,desiredSize=2
fi
