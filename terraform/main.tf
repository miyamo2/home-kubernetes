terraform {
  required_version = ">= 1.11.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.31.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.14.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
  }
  backend "s3" {
    region = "ap-northeast-1"
  }
}

locals {
  kube_config = pathexpand(var.kube_config)
}

provider "kubernetes" {
  config_path    = local.kube_config
  config_context = var.kube_context
}

provider "helm" {
  kubernetes {
    config_path = local.kube_config
  }
}

module "tenant" {
  source   = "./modules/tenant"
  for_each = var.tenants
  name     = each.value
  depends_on = [
    helm_release.argocd,
    helm_release.keda
  ]
}
