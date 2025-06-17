locals {

  # Notes:
  # 1. External DNS is based on _dns zones_ from the VPC module
  # 2. We only install external-dns if there is a config block for it in Hiera
  # 3. The hiera block is added under eks.external_dns

  # TODO: See if we really need a separate External DNS for each zone. Existing one doesn't.

  # Create config block based on DNS zones and External DNS config
  external_dns_config = { for zone_name, zone_config in try(local.config.dns_zones, {}) :
                           zone_name => {
                               role_name      = join("-", [
                                                  "external-dns",
                                                  try(local.config.cluster_name,""),
                                                  replace(zone_name, ".", "-")
                                                ])
                               release_name   = join("-", [
                                                  "external-dns",
                                                  replace(zone_name, ".", "-")
                                                ])
                               namespace      = try(zone_config.namespace, "kube-system")
                               serviceaccount = join("-", ["external-dns", replace(zone_name, ".", "-")])
                               version        = try(zone_config.version, "6.20.3")
                               repository     = try(zone_config.repository, "https://charts.bitnami.com/bitnami")
                               zone_arns      = [ zone_config.arn ]
                               txt_owner_id   = join("-", [
                                                  "external-dns",
                                                  try(local.config.cluster_name,""),
                                                  replace(zone_name, ".", "-")
                                                ])
                           } if try(local.config.external_dns, {}) != {}
                       }
}

module "external_dns_role" {

  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  for_each  = try(local.external_dns_config,{})

  role_name                     = each.value.role_name
  external_dns_hosted_zone_arns = each.value.zone_arns
  attach_external_dns_policy    = true

  oidc_providers = {
    main = {
      provider_arn = local.config.oidc_provider_arn
      namespace_service_accounts = [ join(":", [
                                           each.value.namespace,
                                           each.value.serviceaccount
                                          ])
                                   ]
    }
  }
}

resource "helm_release" "external_dns" {

  for_each   = try(local.external_dns_config,{})

  chart      = "external-dns"
  repository = each.value.repository
  name       = each.value.release_name
  version    = each.value.version
  namespace  = each.value.namespace

  create_namespace = true

  set {
    name  = "metrics.enable"
    value = true
  }

  values  = [ yamlencode(
              {
                aws = {
                  region = local.config.region
                }
                serviceAccount = {
                  annotations = {
                    "eks.amazonaws.com/role-arn" = module.external_dns_role[each.key].iam_role_arn
                  }
                }
                loglevel = "info"
                logformat = "json"
                txtOwnerId = each.value.txt_owner_id
                policy = "sync"
                replicas = 1
                securityContext = {
                  allowPrivilegeEscaltion = false
                  readOnlyRootFilesystem = true
                  capabilities = {
                    drop = [ "ALL" ]
                  }
                }
                podSecurityContext = {
                  fsGroup = 65534
                  runAsUser = 65534   # could be 0 either?
                }
              }
            )]

  depends_on = [
    module.external_dns_role,
  ]
}
