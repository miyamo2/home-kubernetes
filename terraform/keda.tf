resource "helm_release" "keda" {
  name             = "keda"
  chart            = "keda"
  namespace        = "keda"
  repository       = "https://kedacore.github.io/charts"
  version          = "2.18.0"
  create_namespace = true
  timeout          = 500

  depends_on = [
    terraform_data.wait_cilium_ready
  ]

  set {
    name  = "image.keda.tag"
    value = "2.18.0@sha256:ab9f9ccbf8e6736e19255d8344c8ad57a59d469877c64d157dfb089cbfc2ddef"
  }

  set {
    name  = "logging.operator.level"
    value = "debug"
  }
}

resource "kubernetes_cluster_role" "keda_clustertriggerauthentications_readonly" {
  metadata {
    name = "keda-clustertriggerauthentications-readonly"
  }
  rule {
    api_groups = ["keda.sh"]
    resources  = ["clustertriggerauthentications"]
    verbs      = ["get", "list"]
  }
}

resource "kubernetes_cluster_role" "get_secret" {
  metadata {
    name = "get-secret"
  }
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "keda" {
  metadata {
    name = "keda-operator-get-secret"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "get_secret"
  }
  subject {
    kind = "ServiceAccount"
    name = "keda-operator"
  }
}