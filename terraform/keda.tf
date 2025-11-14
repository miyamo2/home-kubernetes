resource "helm_release" "keda" {
  name             = "keda"
  chart            = "keda"
  namespace        = "keda"
  repository       = "https://kedacore.github.io/charts"
  create_namespace = true
  timeout          = 500
  wait             = false

  depends_on = [
    terraform_data.wait_restart_unmanaged_pod
  ]
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