locals {
  aws_load_balancer_controller_values = merge(
                          try(local.config.aws_load_balancer_controller.values, {}), { 
                          clusterName = local.config.cluster_name
                          region = local.config.region
                          defaultTargetType = "ip"
                          serviceAccount = {
                            annotations = {
                              "eks.amazonaws.com/role-arn": try(module.aws_load_balancer_controller_role[0].iam_role_arn,"DISABLED")
                            }
                          }
                        })
}
  
module "aws_load_balancer_controller_role" {
  count     = try(local.config.aws_load_balancer_controller.enabled, true) ? 1 : 0
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = join("-", [
                "aws-load-balancer-controller",
                local.config.cluster_name
              ])

  attach_load_balancer_controller_policy = true
  oidc_providers = {
    main = {
      provider_arn = local.config.oidc_provider_arn
      namespace_service_accounts = [ join(":", [
                                       try(local.config.aws_load_balancer_controller.namespace, "kube-system"),
                                       "aws-load-balancer-controller"
                                     ])
                                   ]
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  count      = try(local.config.aws_load_balancer_controller.enabled, true) ? 1 : 0
  chart      = "aws-load-balancer-controller"
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  version    = try(local.config.aws_load_balancer_controller.version, "")
  namespace  = try(local.config.aws_load_balancer_controller.namespace, "kube-system")

  create_namespace = false

  values  = [ yamlencode(local.aws_load_balancer_controller_values) ]
}
