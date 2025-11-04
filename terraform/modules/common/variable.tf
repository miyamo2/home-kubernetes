variable "cloudflare_api_token" {
  type      = string
  nullable  = false
  sensitive = true
}

variable "cloudflare_account_id" {
  type      = string
  nullable  = false
  sensitive = true
}

variable "cloudflare_tunnel_name" {
  type      = string
  nullable  = false
  sensitive = true
}

variable "new_relic_license_key" {
  type      = string
  nullable  = false
  sensitive = true
}