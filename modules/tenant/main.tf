locals {
  user_name = "${var.name}-user"
  role_name = "${var.name}-admin"
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "public_key" {
  content  = tls_private_key.this.public_key_pem
  filename = pathexpand("~/.ssh/${local.user_name}.pub")
}

resource "local_file" "private_key" {
  for_each = toset([
    pathexpand("~/.ssh/${local.user_name}"),
    "${path.root}/credentials/${var.name}/${local.user_name}.key"
  ])
  content         = tls_private_key.this.private_key_pem
  filename        = each.value
  file_permission = "0600"
}

resource "tls_cert_request" "this" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.this.private_key_pem

  subject {
    common_name = local.user_name
  }
}

resource "local_file" "csr" {
  content  = tls_cert_request.this.cert_request_pem
  filename = "${path.root}/credentials/${var.name}/${local.user_name}.csr"
}

resource "kubernetes_certificate_signing_request_v1" "this" {
  metadata {
    name = local.user_name
  }
  spec {
    usages      = ["client auth"]
    signer_name = "kubernetes.io/kube-apiserver-client"

    request = tls_cert_request.this.cert_request_pem
  }

  auto_approve = true
}

resource "local_file" "cert" {
  content  = kubernetes_certificate_signing_request_v1.this.certificate
  filename = "${path.root}/credentials/${var.name}/${local.user_name}.crt"
}

resource "kubernetes_namespace" "this" {
  metadata {
    annotations = {
      name = var.name
    }
    name = var.name
  }
}

resource "kubernetes_secret" "this" {
  metadata {
    name      = "${local.user_name}-tls"
    namespace = var.name
  }
  data = {
    "tls.crt" = kubernetes_certificate_signing_request_v1.this.certificate
    "tls.key" = tls_private_key.this.private_key_pem
  }
  type = "kubernetes.io/tls"
  depends_on = [
    kubernetes_namespace.this
  ]
}

resource "kubernetes_role" "this" {
  metadata {
    name      = local.role_name
    namespace = var.name
  }

  # TODO: Grant least privilege
  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
  depends_on = [
    kubernetes_namespace.this
  ]
}

resource "kubernetes_role_binding_v1" "this" {
  metadata {
    name      = "${local.user_name}-${var.name}-${local.role_name}"
    namespace = var.name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = local.role_name
  }
  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "User"
    name      = local.user_name
    namespace = var.name
  }
  depends_on = [
    kubernetes_role.this,
  ]
}



