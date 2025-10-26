module "lbc_irsa" {
  source       = "../.."
  cluster_name = var.cluster_name
  region       = var.region
}
output "role" { value = module.lbc_irsa.iam_role_arn }
