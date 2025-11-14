resource "helm_release" "cilium" {
  name       = "cilium"
  chart      = "cilium"
  namespace  = "kube-system"
  repository = "https://helm.cilium.io/"

  depends_on = [
    helm_release.kube_vip
  ]

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
    value = "127.0.0.1" # See: https://speakerdeck.com/logica0419/kube-vip-cilium-k3s?slide=56
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

# See: https://docs.cilium.io/en/stable/installation/k8s-install-helm/#restart-unmanaged-pods
resource "terraform_data" "restart_unmanaged_pod" {
  triggers_replace = helm_release.cilium.manifest
  depends_on = [
    helm_release.cilium
  ]
  provisioner "local-exec" {
    command = <<EOF
    export KUBECONFIG=${var.kube_config}
    kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork --no-headers=true | grep '<none>' | awk '{print "-n "$1" "$2}' | xargs -L 1 -r kubectl delete pod
    EOF
  }
}

# See: https://docs.cilium.io/en/stable/installation/k8s-install-helm/#restart-unmanaged-pods
resource "terraform_data" "wait_restart_unmanaged_pod" {
  triggers_replace = helm_release.cilium.manifest
  depends_on = [
    terraform_data.restart_unmanaged_pod
  ]
  provisioner "local-exec" {
    command = <<EOF
    export KUBECONFIG=${var.kube_config}
    kubectl wait --for=condition=ready --all pods --all-namespaces --timeout=300s
    EOF
  }
}
