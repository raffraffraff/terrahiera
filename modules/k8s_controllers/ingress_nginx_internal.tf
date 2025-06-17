locals {
  nginx_internal_values  = try(local.config.ingress_nginx_internal.values, {})
}

resource "helm_release" "ingress_nginx_internal" {
  count      = try(local.config.ingress_nginx_internal.enabled, true) ? 1 : 0
  name       = "ingress-nginx-internal"
  chart      = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  version    = try(local.config.ingress_nginx_internal.chart_version, null)
  namespace  = try(local.config.ingress_nginx_internal.namespace, "default")

  create_namespace = true

  values     = [ yamlencode(local.nginx_internal_values) ]
  depends_on = [ helm_release.aws_load_balancer_controller ]

}
