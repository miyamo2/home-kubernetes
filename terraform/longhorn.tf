resource "helm_release" "longhorn" {
  name             = "longhorn"
  chart            = "longhorn"
  namespace        = "longhorn-system"
  repository       = "https://charts.longhorn.io"
  create_namespace = true
  timeout          = 500

  depends_on = [
    terraform_data.wait_restart_unmanaged_pod
  ]
}

resource "terraform_data" "storageclass_patch" {
  triggers_replace = helm_release.longhorn.manifest
  depends_on = [
    helm_release.longhorn
  ]
  provisioner "local-exec" {
    command = <<EOF
    export KUBECONFIG=${var.kube_config}
    kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
    kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    EOF
  }
}
