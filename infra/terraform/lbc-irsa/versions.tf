terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = ">= 2.23" }
    http = { source = "hashicorp/http", version = ">= 3.4" }
    tls = { source = "hashicorp/tls", version = ">= 4.0" }
  }
}
