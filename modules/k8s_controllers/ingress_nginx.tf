locals {
  nginx_values  = try(local.config.ingress_nginx.values, {})
}

resource "helm_release" "ingress_nginx" {
  count      = try(local.config.ingress_nginx.enabled, true) ? 1 : 0
  name       = "ingress-nginx"
  chart      = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  version    = try(local.config.ingress_nginx.chart_version, null)
  namespace  = try(local.config.ingress_nginx.namespace, "default")

  create_namespace = true

  values     = [ yamlencode(local.nginx_values) ]
  depends_on = [ helm_release.aws_load_balancer_controller ]
}
