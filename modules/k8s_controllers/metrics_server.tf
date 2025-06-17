resource "helm_release" "metrics-server" {
  name          = "metrics-server"
  repository    = "https://kubernetes-sigs.github.io/metrics-server"
  chart         = "metrics-server"
  version       = try(local.config.metrics_server.chart_version, null)
  namespace     = try(local.config.metrics_server.namespace, "monitoring")

  create_namespace = true

  values        = [ yamlencode(local.metrics_server_helm_values) ]
 
  depends_on = [
    # The namespace and secrets should already exist
  ]
}
