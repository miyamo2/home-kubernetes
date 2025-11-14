locals {
  argocd_cm_patch_data = toset([
    for v in var.tenants : templatefile("${path.module}/argocd-cm_patch.json.tftpl", { tenant = v })
  ])
  argocd_rbac_cm_patch_data = templatefile("${path.module}/argocd-rbac-cm_patch.json.tftpl", {
    tenants = var.tenants
  })
}

resource "helm_release" "argocd" {
  name             = "argocd"
  chart            = "argo-cd"
  namespace        = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  create_namespace = true
  wait             = false

  depends_on = [
    terraform_data.wait_restart_unmanaged_pod
  ]
}

resource "kubernetes_role" "argocd_port_forward" {
  metadata {
    name      = "argocd-port-forward"
    namespace = "argocd"
  }

  # See: https://managedkube.com/kubernetes/rbac/port/forward/2018/09/01/kubernetes-rbac-port-forward.html
  rule {
    api_groups = ["*"]
    resources  = ["services", "services/portforward", "pods", "pods/portforward"]
    verbs      = ["get", "list", "create"]
  }

  depends_on = [
    helm_release.argocd
  ]
}

resource "terraform_data" "argocd_allow_app_in_any_namespace" {
  triggers_replace = helm_release.argocd.manifest
  provisioner "local-exec" {
    command = <<EOF
    export KUBECONFIG=${var.kube_config}
    wget https://raw.githubusercontent.com/argoproj/argo-cd/refs/tags/v3.2.0/examples/k8s-rbac/argocd-server-applications/kustomization.yaml -P ${path.module}/argocd_allow_app_in_any_namespace/
    wget https://raw.githubusercontent.com/argoproj/argo-cd/refs/tags/v3.2.0/examples/k8s-rbac/argocd-server-applications/argocd-server-rbac-clusterrole.yaml -P ${path.module}/argocd_allow_app_in_any_namespace/
    wget https://raw.githubusercontent.com/argoproj/argo-cd/refs/tags/v3.2.0/examples/k8s-rbac/argocd-server-applications/argocd-server-rbac-clusterrolebinding.yaml -P ${path.module}/argocd_allow_app_in_any_namespace/
    wget https://raw.githubusercontent.com/argoproj/argo-cd/refs/tags/v3.2.0/examples/k8s-rbac/argocd-server-applications/argocd-notifications-controller-rbac-clusterrole.yaml -P ${path.module}/argocd_allow_app_in_any_namespace/
    wget https://raw.githubusercontent.com/argoproj/argo-cd/refs/tags/v3.2.0/examples/k8s-rbac/argocd-server-applications/argocd-notifications-controller-rbac-clusterrolebinding.yaml -P ${path.module}/argocd_allow_app_in_any_namespace/
    kubectl apply -k ${path.module}/argocd_allow_app_in_any_namespace/
    kubectl patch cm argocd-cmd-params-cm --type merge -p '{ "data": { "application.namespaces": "*" } }' --context ${var.kube_context} -n argocd
    kubectl rollout restart deployment/argocd-server --context ${var.kube_context} -n argocd
    kubectl rollout restart statefulset/argocd-application-controller --context ${var.kube_context} -n argocd
    EOF
  }
}

resource "terraform_data" "argocd_cm" {
  for_each         = local.argocd_cm_patch_data
  triggers_replace = local.argocd_cm_patch_data

  depends_on = [
    helm_release.argocd
  ]

  provisioner "local-exec" {
    command = <<EOF
    export KUBECONFIG=${var.kube_config}
    kubectl patch cm argocd-cm --type merge -p '${each.value}' --context ${var.kube_context} -n argocd
    EOF
  }
}

resource "terraform_data" "argocd_rbac_cm" {
  triggers_replace = local.argocd_rbac_cm_patch_data

  depends_on = [
    helm_release.argocd
  ]

  provisioner "local-exec" {
    command = <<EOF
    export KUBECONFIG=${var.kube_config}
    kubectl patch cm argocd-rbac-cm --type merge -p '${local.argocd_rbac_cm_patch_data}' --context ${var.kube_context} -n argocd
    EOF
  }
}