locals {
  cert_issuers_values = {
                          email = local.config.cert_manager.email
                          aws   = flatten([ for dns_zone, params in try(local.config.dns_zones, {}) : 
                                    [{
                                      "region"           = local.config.region
                                      "hostedZoneID"     = params.zone_id
                                      "dnsZoneSelectors" = [ dns_zone ]
                                    }]
                                  ])
                          }

  cert_manager_values = merge(
                          try(local.config.cert_manager.values, {}), { 
                          serviceAccount = {
                            annotations = {
                              "eks.amazonaws.com/role-arn": module.cert_manager_role.iam_role_arn
                            }
                          }
                        })
}

module "cert_manager_role" {

  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                     = join("-", [
                                    "cert-manager",
                                    try(local.config.cluster_name,""),
                                  ])
  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = flatten([ for zone, params in try(local.config.dns_zones, {}) :
                                    params.arn 
                                  ])


  oidc_providers = {
    main = {
      provider_arn = local.config.oidc_provider_arn
      namespace_service_accounts = [ join(":", [
                                       try(local.config.cert_manager.namespace, "cert-manager"),
                                       "cert-manager"
                                     ])
                                   ]
    }
  }
}

resource "helm_release" "cert_manager_crds" {
  name      = "cert-manager-crds"
  chart     = "${path.module}/charts/cert-manager-crds"
  namespace = try(local.config.cert_manager.namespace, "cert-manager")
  create_namespace = true
}

resource "helm_release" "cert_manager" {

  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  name       = "cert-manager"
  version    = try(local.config.cert_manager.version, "1.12.1")
  namespace  = try(local.config.cert_manager.namespace, "cert-manager")
  create_namespace = true

  values     = [ yamlencode(local.cert_manager_values) ]

  depends_on = [
    module.cert_manager_role,
    helm_release.cert_manager_crds
  ]
}

resource "helm_release" "cert_manager_cluster_issuers" {
  name      = "cert-manager-issuers-config"
  chart     = "${path.module}/charts/cert-manager-issuers-config"
  namespace = try(local.config.cert_manager.namespace, "cert-manager")

  values    = [ yamlencode(local.cert_issuers_values) ]

  depends_on = [ helm_release.cert_manager ]
}
