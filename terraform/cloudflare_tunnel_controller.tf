resource "helm_release" "cloudflare_tunnel_controller" {
  name             = "cloudflare-tunnel-ingress-controller"
  chart            = "cloudflare-tunnel-ingress-controller"
  namespace        = "cloudflare-tunnel-ingress-controller"
  repository       = "https://helm.strrl.dev"
  create_namespace = true

  depends_on = [
    helm_release.cilium
  ]

  set {
    name  = "cloudflare.apiToken"
    value = var.cloudflare_api_token
  }

  set {
    name  = "cloudflare.accountId"
    value = var.cloudflare_account_id
  }

  set {
    name  = "cloudflare.tunnelName"
    value = var.cloudflare_tunnel_name
  }
}