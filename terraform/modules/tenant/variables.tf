variable "name" {
  type     = string
  nullable = false
}

variable "argocd_namespace" {
  type     = string
  nullable = false
  default  = "argocd"
}

variable "keda_namespace" {
  type     = string
  nullable = false
  default  = "keda"
}