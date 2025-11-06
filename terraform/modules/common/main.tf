resource "helm_release" "argocd" {
  name             = "argocd"
  chart            = "argo-cd"
  namespace        = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  create_namespace = true
}

resource "kubernetes_role" "argocd_port_foward" {
  metadata {
    name      = "argocd-port-foward"
    namespace = "argocd"
  }

  # See: https://managedkube.com/kubernetes/rbac/port/forward/2018/09/01/kubernetes-rbac-port-forward.html
  rule {
    api_groups = ["*"]
    resources  = ["services", "services/portforward", "pods", "pods/portforward"]
    verbs      = ["get", "list", "create"]
  }
}

resource "helm_release" "cloudflare_tunnel_controller" {
  name             = "cloudflare-tunnel-ingress-controller"
  chart            = "cloudflare-tunnel-ingress-controller"
  namespace        = "cloudflare-tunnel-ingress-controller"
  repository       = "https://helm.strrl.dev"
  create_namespace = true

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

resource "helm_release" "keda" {
  name             = "keda"
  chart            = "keda"
  namespace        = "keda"
  repository       = "https://kedacore.github.io/charts"
  create_namespace = true
}

resource "helm_release" "newrelic" {
  name             = "newrelic-bundle"
  chart            = "nri-bundle"
  namespace        = "newrelic"
  create_namespace = true
  repository       = "https://helm-charts.newrelic.com"
  timeout          = 500

  set {
    name  = "global.licenseKey"
    value = var.new_relic_license_key
  }

  set {
    name  = "global.cluster"
    value = "blogapi-cluster"
  }

  set {
    name  = "global.lowDataMode"
    value = "true"
  }

  set {
    name  = "kube-state-metrics.image.tag"
    value = "v2.13.0"
  }

  set {
    name  = "kube-state-metrics.enabled"
    value = "true"
  }

  set {
    name  = "kubeEvents.enabled"
    value = "true"
  }

  set {
    name  = "newrelic-prometheus-agent.enabled"
    value = "true"
  }

  set {
    name  = "newrelic-prometheus-agent.lowDataMode"
    value = "true"
  }

  set {
    name  = "newrelic-prometheus-agent.config.kubernetes.integrations_filter.enabled"
    value = "false"
  }

  set {
    name  = "k8s-agents-operator.enabled"
    value = "true"
  }

  set {
    name  = "logging.enabled"
    value = "true"
  }

  set {
    name  = "newrelic-logging.lowDataMode"
    value = "false"
  }
}
