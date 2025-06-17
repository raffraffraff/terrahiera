locals {
  cluster_autoscaler_values = merge(
                        try(local.config.cluster_autoscaler.values, {}), { 
                          image = {
                            tag = try(local.config.cluster_autoscaler.version, "v1.27.2")
                          }
                          autoDiscovery = {
                            clusterName = local.config.cluster_name
                          }
                          awsRegion = local.config.region
                          rbac = {
                            serviceAccount = {
                              name = "cluster-autoscaler"
                              annotations = {
                                "eks.amazonaws.com/role-arn": module.cluster_autoscaler_role.iam_role_arn
                              }
                            }
                          }
                        })
}
  
module "cluster_autoscaler_role" {

  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = join("-", ["cluster-autoscaler", local.config.cluster_name])

  attach_cluster_autoscaler_policy    = true
  cluster_autoscaler_cluster_ids      = [ local.config.cluster_name ]

  oidc_providers = {
    main = {
      provider_arn = local.config.oidc_provider_arn
      namespace_service_accounts = [ join(":", [
                                       try(local.config.cluster_autoscaler.namespace, "kube-system"),
                                       "cluster-autoscaler"
                                     ])
                                   ]
    }
  }
}

resource "helm_release" "cluster_autoscaler" {

  chart      = "cluster-autoscaler"
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  version    = try(local.config.cluster_autoscaler.chart_version, "")
  namespace  = try(local.config.cluster_autoscaler.namespace, "kube-system")

  create_namespace = true

  values  = [ yamlencode(local.cluster_autoscaler_values) ]
}
