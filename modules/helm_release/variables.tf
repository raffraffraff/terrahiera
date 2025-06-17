variable "kubernetes_config" {
  type        = map
  description = "Configuration for the helm kubernetes parameter, containing host, CA cert, token etc"
}

variable "forced_dependency" {
  type        = map
  description = "We don't actually use this variable, but it forces a dependence on the ingress Cloudflare resources"
}
