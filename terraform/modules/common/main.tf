resource "helm_release" "kube_vip" {
  name       = "kube-vip"
  chart      = "kube-vip"
  namespace  = "kube-system"
  repository = "https://kube-vip.github.io/helm-charts"

  set {
    name  = "config.address"
    value = "192.168.1.200"
  }
  set {
    name  = "env.vip_interface"
    value = "eth0"
  }
  set {
    name  = "env.vip_cidr"
    value = "24"
  }
  set {
    name  = "env.dns_mode"
    value = "first"
  }
  set {
    name  = "env.cp_enable"
    value = "true"
  }
  set {
    name  = "env.cp_namespace"
    value = "kube-system"
  }
  set {
    name  = "env.svc_enable"
    value = "true"
  }
  set {
    name  = "env.svc_leasename"
    value = "vip_leaderelection"
  }
  set {
    name  = "env.vip_leaderelection"
    value = "true"
  }
  set {
    name  = "env.vip_leasename"
    value = "plndr-cp-lock"
  }
  set {
    name  = "env.vip_leaseduration"
    value = "5"
  }
  set {
    name  = "env.vip_renewdeadline"
    value = "3"
  }
  set {
    name  = "env.vip_retryperiod"
    value = "1"
  }
  set {
    name  = "serviceAccount.name"
    value = "kube-vip"
  }
  set {
    name  = "nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key"
    value = "node-role.kubernetes.io/master"
  }
  set {
    name  = "nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator"
    value = "Exists"
  }
  set {
    name  = "nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[1].matchExpressions[0].key"
    value = "node-role.kubernetes.io/control-plane"
  }
  set {
    name  = "nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[1].matchExpressions[0].operator"
    value = "Exists"
  }
  set {
    name  = "securityContext.capabilities.add[0]"
    value = "NET_ADMIN"
  }
  set {
    name  = "securityContext.capabilities.add[1]"
    value = "NET_RAW"
  }
  set {
    name  = "tolerations[0].effect"
    value = "NoSchedule"
  }
  set {
    name  = "tolerations[0].operator"
    value = "Exists"
  }
  set {
    name  = "tolerations[1].effect"
    value = "NoSchedule"
  }
  set {
    name  = "tolerations[1].operator"
    value = "Exists"
  }
}

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
    name  = "kubeProxyReplacement"
    value = "strict"
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

resource "helm_release" "longhorn" {
  name             = "longhorn"
  chart            = "longhorn"
  namespace        = "longhorn-system"
  repository       = "https://charts.longhorn.io"
  create_namespace = true
  depends_on = [
    terraform_data.restart_unmanaged_pod
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

resource "helm_release" "argocd" {
  name             = "argocd"
  chart            = "argo-cd"
  namespace        = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  create_namespace = true

  depends_on = [
    terraform_data.restart_unmanaged_pod
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

  depends_on = [
    terraform_data.restart_unmanaged_pod
  ]
}

resource "helm_release" "keda" {
  name             = "keda"
  chart            = "keda"
  namespace        = "keda"
  repository       = "https://kedacore.github.io/charts"
  create_namespace = true

  depends_on = [
    terraform_data.restart_unmanaged_pod
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

  depends_on = [
    terraform_data.restart_unmanaged_pod
  ]
}