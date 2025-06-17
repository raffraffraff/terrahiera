provider "helm" {
  kubernetes {
    host                   = var.kubernetes_config["host"]
    cluster_ca_certificate = var.kubernetes_config["cluster_ca_certificate"]
    token                  = var.kubernetes_config["token"]
  }
}
