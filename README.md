# DevSecOps E2E Starter — FastAPI • GitHub Actions • ECR • Snyk • Helm • ArgoCD • EKS • Prometheus/Grafana • ALB+ACM
**Date:** 2025-09-11

## Etechdevops MasterClass:

- App: **FastAPI** e‑commerce demo (receipt UI + `/metrics`)
- CI/CD: **GitHub Actions** → build & push to **ECR** → **Snyk** scan → bless tag → bump Helm values
- GitOps: **ArgoCD** deploys the Helm chart to **EKS**
- Observability: **kube‑prometheus‑stack** (Prometheus + Grafana)
- Public access: **AWS Load Balancer Controller** (ALB) + **ACM** TLS for: App, ArgoCD UI, Grafana UI, Prometheus UI
- Terraform: **ACM** (DNS validation) + **IRSA for ALB Controller** (OIDC provider, policy, role, SA)

---

## 0) What you need
- AWS account with ECR & EKS ready (kubectl works)
- A public domain in Route53 (for ACM + Ingress hostnames)
- GitHub repo (to push this code) and **GitHub OIDC → AWS role** for Actions

---

## 1) Clone & set placeholders
Search/replace the placeholders below (or run `scripts/setup.sh`):
- `<AWS_ACCOUNT_ID>`
- `<AWS_REGION>`
- `<ECR_REPO>` (e.g., `ecommerce`)
- `<EKS_CLUSTER_NAME>`
- `<VPC_ID>`
- `<ACM_CERT_ARN>`
- Hostnames:
  - `shop.example.com` (app)
  - `argocd.example.com`
  - `grafana.example.com`
  - `prom.example.com`
- `repoURL` in `argocd/app-ecommerce.yaml` and `argocd/platform-ui.yaml` (set to your GitHub repo)

---

## 2) GitHub Action secrets (Repo → Settings → Secrets and variables → Actions)
Required:
- `AWS_ACCOUNT_ID`, `AWS_REGION`, `ECR_REPO`, `EKS_CLUSTER_NAME`, `SNYK_TOKEN`, `AWS_IAM_ROLE_ARN`

Optional (manual Argo sync workflow):
- `ARGOCD_SERVER`, `ARGOCD_AUTH_TOKEN`, `ARGOCD_APP_NAME`

---

## 3) Terraform: ACM certificate + IRSA for ALB Controller
```bash
# ACM DNS-validated cert for your hostnames
cd infra/terraform/acm
# Edit terraform.tfvars or export TF_VAR_* for: region, domain_name, hosted_zone_id
terraform init && terraform apply
# Copy output acm_certificate_arn → use as <ACM_CERT_ARN>

# IRSA for AWS Load Balancer Controller (creates OIDC, IAM policy, role, SA)
cd ../lbc-irsa/example
# Set vars in terraform.tfvars (cluster_name, region). Namespace/SA default to kube-system/aws-load-balancer-controller
terraform init && terraform apply
# Output iam_role_arn → already consumed by the SA annotation
```

> The ALB Controller Helm values (_ArgoCD app_) are set to **reuse** this ServiceAccount (`serviceAccount.create: false`).

---

## 4) Install ArgoCD & apps
```bash
# ArgoCD core
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# AWS Load Balancer Controller (uses existing SA/IRSA)
kubectl apply -f argocd/aws-load-balancer-controller.yaml

# Monitoring stack (Prometheus + Grafana)
kubectl apply -f argocd/monitoring.yaml

# Platform UI Ingresses (ArgoCD/Grafana/Prometheus via ALB+ACM)
# - Edit hosts and ACM ARN in k8s/platform-ui-ingress/*.yaml OR set them with scripts/setup.sh
kubectl apply -f argocd/platform-ui.yaml

# App (set repoURL + image repo placeholders first)
kubectl apply -f argocd/app-ecommerce.yaml
```

After syncs, ALB will be provisioned. Point Route53 **CNAME** records:
- `shop.example.com` → ALB DNS (from the Ecommerce Ingress)
- `argocd.example.com` → ALB DNS (from Platform UI Ingress)
- `grafana.example.com` → ALB DNS
- `prom.example.com` → ALB DNS

(If you use ExternalDNS, it can manage these automatically.)

---

## 5) CI/CD usage
- Open a PR → `PR Verify` builds + Snyk scan
- Merge to `main` → `Build → Bless → Bump`:
  - Builds image `:<sha>` → ECR
  - Snyk scan gates release
  - Retag `:<sha>-blessed`
  - Update Helm values → ArgoCD auto‑deploys

---

## 6) Access UIs
- **ArgoCD:** https://argocd.example.com (admin + reset password; prefer SSO)
- **Grafana:** https://grafana.example.com (default admin: `admin` / pwd in `argocd/monitoring.yaml` values)
- **Prometheus:** https://prom.example.com
- **App:** https://shop.example.com

See `k8s/platform-ui-ingress/*.yaml` and `charts/ecommerce-app/values.yaml` for ALB annotations & TLS policy.

---

## 7) Security checklist
- Change **Grafana** admin password
- Configure ArgoCD **SSO/OIDC**; restrict by IP with `alb.ingress.kubernetes.io/inbound-cidrs`
- Keep containers **non-root**, read‑only, capabilities dropped (already in chart)
- Keep Snyk thresholds high; fix before bless
- Apply stricter **NetworkPolicies** per namespace in production
