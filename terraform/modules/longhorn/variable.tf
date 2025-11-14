variable "kube_config" {
  type      = string
  nullable  = false
  sensitive = true
  default   = "~/.kube/config"
}