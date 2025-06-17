output "cert_manager_role" {
  value = module.cert_manager_role.iam_role_name
}

output "cert_manager_dns_zones" {
  value = flatten([ for dns_zone, params in try(local.config.dns_zones, {}) : 
                    { "${dns_zone}" = params.zone_id }
                  ])
}

output "external_dns_role" {
  value = module.external_dns_role.iam_role_name
}

output "cluster_autoscaler_role" {
  value = module.cluster_autoscaler_role.iam_role_name
}

output "eso_role" {
  value = module.external_secrets_role.iam_role_name
}

output "eso_kms_key_alias" {
  value = aws_kms_alias.external_secrets_default.name
}

output "eso_kms_key_id" {
  value = aws_kms_key.external_secrets_default.key_id
}

output "eso_cluster_secret_store_name" {
  value = "aws-parameter-store"
}

output "ingress_nginx" {
  value = try(local.config.ingress_nginx.enabled, true)
}

output "ingress_nginx_internal" {
  value = try(local.config.ingress_nginx_internal.enabled, true)
}
