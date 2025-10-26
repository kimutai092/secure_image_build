#!/usr/bin/env bash
set -euo pipefail
usage() {
  cat <<EOF
Usage: scripts/setup.sh \

  --account <AWS_ACCOUNT_ID> --region <AWS_REGION> --ecr <ECR_REPO> \

  --cluster <EKS_CLUSTER_NAME> --vpc <VPC_ID> --cert <ACM_CERT_ARN> \

  --app-host <shop.example.com> --argocd-host <argocd.example.com> \

  --grafana-host <grafana.example.com> --prom-host <prom.example.com> \

  --repo-url <https://github.com/you/repo.git>
EOF
}
ACCOUNT=""; REGION=""; ECR=""; CLUSTER=""; VPC=""; CERT=""
APP_HOST="shop.example.com"; ARGOCD_HOST="argocd.example.com"; GRAFANA_HOST="grafana.example.com"; PROM_HOST="prom.example.com"
REPO_URL=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --account) ACCOUNT="$2"; shift 2;;
    --region) REGION="$2"; shift 2;;
    --ecr) ECR="$2"; shift 2;;
    --cluster) CLUSTER="$2"; shift 2;;
    --vpc) VPC="$2"; shift 2;;
    --cert) CERT="$2"; shift 2;;
    --app-host) APP_HOST="$2"; shift 2;;
    --argocd-host) ARGOCD_HOST="$2"; shift 2;;
    --grafana-host) GRAFANA_HOST="$2"; shift 2;;
    --prom-host) PROM_HOST="$2"; shift 2;;
    --repo-url) REPO_URL="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done
[[ -z "$ACCOUNT" || -z "$REGION" || -z "$ECR" || -z "$CLUSTER" || -z "$VPC" || -z "$CERT" || -z "$REPO_URL" ]] && { usage; exit 1; }
sed_i() { if sed --version >/dev/null 2>&1; then sed -i "$@"; else sed -i '' "$@"; fi; }
files=$(find . -type f -not -path "*/.git/*")
for f in $files; do
  sed_i "s#<AWS_ACCOUNT_ID>#$ACCOUNT#g" "$f" || true
  sed_i "s#<AWS_REGION>#$REGION#g" "$f" || true
  sed_i "s#<ECR_REPO>#$ECR#g" "$f" || true
  sed_i "s#<EKS_CLUSTER_NAME>#$CLUSTER#g" "$f" || true
  sed_i "s#<VPC_ID>#$VPC#g" "$f" || true
  sed_i "s#<ACM_CERT_ARN>#$CERT#g" "$f" || true
  sed_i "s#shop.example.com#$APP_HOST#g" "$f" || true
  sed_i "s#argocd.example.com#$ARGOCD_HOST#g" "$f" || true
  sed_i "s#grafana.example.com#$GRAFANA_HOST#g" "$f" || true
  sed_i "s#prom.example.com#$PROM_HOST#g" "$f" || true
  sed_i "s#https://github.com/your-org/your-repo.git#$REPO_URL#g" "$f" || true
done
echo "Placeholders replaced. Next:"
echo "1) Commit changes; push to GitHub"
echo "2) Create GitHub secrets (AWS*, SNYK*)"
echo "3) kubectl apply -f argocd/aws-load-balancer-controller.yaml"
echo "   kubectl apply -f argocd/monitoring.yaml"
echo "   kubectl apply -f argocd/platform-ui.yaml"
echo "   kubectl apply -f argocd/app-ecommerce.yaml"
