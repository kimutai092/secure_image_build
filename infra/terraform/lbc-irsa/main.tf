locals {
  oidc_issuer                = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  oidc_provider_url_noscheme = replace(local.oidc_issuer, "https://", "")
}
data "tls_certificate" "oidc" { url = local.oidc_issuer }
locals {
  computed_thumbprint = try(data.tls_certificate.oidc.certificates[length(data.tls_certificate.oidc.certificates) - 1].sha1_fingerprint, null)
  final_thumbprint    = coalesce(var.oidc_thumbprint_override, local.computed_thumbprint)
}
resource "aws_iam_openid_connect_provider" "eks" {
  url             = local.oidc_issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [local.final_thumbprint]
}
data "http" "lbc_policy" { url = var.lbc_policy_url }
resource "aws_iam_policy" "lbc" {
  name        = var.policy_name
  description = "Permissions for AWS Load Balancer Controller"
  policy      = data.http.lbc_policy.response_body
}
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals { type = "Federated"; identifiers = [aws_iam_openid_connect_provider.eks.arn] }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url_noscheme}:sub"
      values   = ["system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url_noscheme}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "lbc" {
  name               = var.iam_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.lbc.name
  policy_arn = aws_iam_policy.lbc.arn
}
resource "kubernetes_service_account" "lbc" {
  metadata {
    name        = var.k8s_service_account
    namespace   = var.k8s_namespace
    annotations = { "eks.amazonaws.com/role-arn" = aws_iam_role.lbc.arn }
    labels      = { "app.kubernetes.io/name" = "aws-load-balancer-controller" }
  }
  automount_service_account_token = true
}
