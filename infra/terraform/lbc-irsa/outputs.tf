output "iam_role_arn"       { value = aws_iam_role.lbc.arn }
output "iam_policy_arn"     { value = aws_iam_policy.lbc.arn }
output "oidc_provider_arn"  { value = aws_iam_openid_connect_provider.eks.arn }
output "service_account"    { value = kubernetes_service_account.lbc.metadata[0].name }
