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
    name  = "env.vip_arp"
    value = "true"
  }
  set {
    name  = "env.port"
    value = "6443"
  }
  set {
    name  = "envValueFrom.vip_nodename.fieldRef.fieldPath"
    value = "spec.nodeName"
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
    value = "plndr-svcs-lock"
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
    name  = "env.prometheus_server"
    value = ":2112"
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
    name  = "securityContext.capabilities.drop[0]"
    value = "ALL"
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