locals {
  argocd_cm_patch_date      = jsonencode(templatefile("${path.module}/argocd-cm_patch.yaml.tftpl", { tenants = var.tenants }))
  argocd_rbac_cm_patch_date = templatefile("${path.module}/argocd-rbac-cm_patch.yaml.tftpl", { tenants = var.tenants })
}

resource "terraform_data" "argocd_cm" {
  triggers_replace = local.argocd_cm_patch_date
  provisioner "local-exec" {
    command = <<EOF
    export KUBECONFIG=${pathexpand(var.kube_config)}
    kubectl patch cm argocd-cm --type merge -p '${local.argocd_cm_patch_date}' --context ${var.kube_context} -n argocd
    EOF
  }
}

resource "terraform_data" "argocd_rbac_cm" {
  triggers_replace = local.argocd_rbac_cm_patch_date
  provisioner "local-exec" {
    command = <<EOF
    export KUBECONFIG=${pathexpand(var.kube_config)}
    kubectl patch cm argocd-rbac-cm --type merge -p '${local.argocd_rbac_cm_patch_date}' --context ${var.kube_context} -n argocd
    EOF
  }
}