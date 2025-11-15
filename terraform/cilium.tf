resource "helm_release" "cilium" {
  name       = "cilium"
  chart      = "cilium"
  namespace  = "kube-system"
  repository = "https://helm.cilium.io/"

  set {
    name  = "operator.replicas"
    value = "1"
  }
  set {
    name  = "kubeProxyReplacement"
    value = "true"
  }
  set {
    name  = "l2announcements.enabled"
    value = "true"
  }
  set {
    name  = "k8sClientRateLimit.qps"
    value = "5" # services * (1 / leaseRenewDeadline); See: https://sreake.com/blog/learn-about-cilium-l2-announcement/
  }
  set {
    name  = "k8sClientRateLimit.burst"
    value = "10"
  }
  set {
    name  = "k8sServiceHost"
    value = "192.168.1.200"
  }
  set {
    name  = "k8sServicePort"
    value = "6443"
  }
  set {
    name  = "kubeConfigPath"
    value = "/etc/rancher/k3s/k3s.yaml"
  }
}

resource "terraform_data" "wait_cilium_ready" {
  triggers_replace = helm_release.cilium.manifest
  provisioner "local-exec" {
    command = <<EOF
    export KUBECONFIG=${var.kube_config}
    kubectl wait --for=condition=ready --all pods --all-namespaces --timeout=500s
    EOF
  }
}
