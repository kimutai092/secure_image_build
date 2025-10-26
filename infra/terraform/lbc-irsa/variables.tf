variable "cluster_name"        { type = string }
variable "region"              { type = string }
variable "k8s_namespace"       { type = string  default = "kube-system" }
variable "k8s_service_account" { type = string  default = "aws-load-balancer-controller" }
variable "policy_name"         { type = string  default = "AWSLoadBalancerControllerIAMPolicy" }
variable "iam_role_name"       { type = string  default = "AmazonEKSLoadBalancerControllerRole" }
variable "lbc_policy_url" {
  type    = string
  default = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.13.3/docs/install/iam_policy.json"
}
variable "oidc_thumbprint_override" { type = string  default = null }
