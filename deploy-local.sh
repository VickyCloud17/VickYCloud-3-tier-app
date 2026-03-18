#!/bin/bash
set -e
NAMESPACE="vickycloud"
cd ~/projects/vickycloud
eval $(minikube docker-env)
TIER=${1:-both}
if [[ "$TIER" == "web" || "$TIER" == "both" ]]; then
  echo "🐳 Building web-tier..."
  docker build --no-cache -t vickycloud/web-tier:latest ./web-tier/
  kubectl rollout restart deployment/web-deployment -n $NAMESPACE
  kubectl rollout status deployment/web-deployment -n $NAMESPACE --timeout=60s
  echo "✅ web-tier deployed"
fi
if [[ "$TIER" == "app" || "$TIER" == "both" ]]; then
  echo "🐳 Building app-tier..."
  docker build --no-cache -t vickycloud/app-tier:latest ./app-tier/
  kubectl rollout restart deployment/app-deployment -n $NAMESPACE
  kubectl rollout status deployment/app-deployment -n $NAMESPACE --timeout=60s
  echo "✅ app-tier deployed"
fi
echo "🎉 Done! → http://localhost:9090"
