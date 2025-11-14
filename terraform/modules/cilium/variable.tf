variable "kube_config" {
  type      = string
  nullable  = false
  sensitive = true
  default   = "~/.kube/config"
}

variable "kube_context" {
  type      = string
  nullable  = false
  sensitive = true
  default   = "default"
}