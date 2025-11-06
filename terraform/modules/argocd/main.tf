locals {
  argocd_cm_patch_data = toset([
    for v in var.tenants: templatefile("${path.module}/argocd-cm_patch.yaml.tftpl", { tenant = v })
  ])
  argocd_rbac_cm_patch_data = templatefile("${path.module}/argocd-rbac-cm_patch.yaml.tftpl", {
    tenants = var.tenants
  })
}

resource "terraform_data" "argocd_cm" {
  for_each = local.argocd_cm_patch_data
  triggers_replace = local.argocd_cm_patch_data
  provisioner "local-exec" {
    command = <<EOF
    export KUBECONFIG=${pathexpand(var.kube_config)}
    kubectl patch cm argocd-cm --type merge -p '${each.value}' --context ${var.kube_context} -n argocd
    EOF
  }
}

resource "terraform_data" "argocd_rbac_cm" {
  triggers_replace = local.argocd_rbac_cm_patch_data
  provisioner "local-exec" {
    command = <<EOF
    export KUBECONFIG=${pathexpand(var.kube_config)}
    kubectl patch cm argocd-rbac-cm --type merge -p '${local.argocd_rbac_cm_patch_data}' --context ${var.kube_context} -n argocd
    EOF
  }
}