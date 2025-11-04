variable "name" {
  type     = string
  nullable = false
}

variable "skip_create_namespace" {
  type    = bool
  default = false
}