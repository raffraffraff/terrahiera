locals {
  external_dns_values = merge(
                          try(local.config.external_dns.values, {}), { 
                          serviceAccount = {
                            annotations = {
                              "eks.amazonaws.com/role-arn": module.external_dns_role.iam_role_arn
                            }
                          }
                        })
}
  
module "external_dns_role" {

  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                     = join("-", ["external-dns", local.config.cluster_name])
  external_dns_hosted_zone_arns = flatten([ for zone, params in try(local.config.dns_zones, {}) :
                                    params.arn 
                                  ])
  attach_external_dns_policy    = true

  oidc_providers = {
    main = {
      provider_arn = local.config.oidc_provider_arn
      namespace_service_accounts = [ join(":", [
                                       try(local.config.external_dns.namespace, "kube-system"),
                                       "external-dns"
                                     ])
                                   ]
    }
  }
}

resource "helm_release" "external_dns" {

  chart      = "external-dns"
  name       = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"
  version    = try(local.config.external_dns.version, "6.20.3")
  namespace  = try(local.config.external_dns.namespace, "kube-system")

  create_namespace = true

  values  = [ yamlencode(local.external_dns_values) ]
}
