locals {

  dependencies = {
    apex_zones = "../../../global/shared/apex_zones"
  }

  custom_config = {
    apex_zones       = local.dependency.apex_zones.zone_map
  }

  stack_config = merge(local.custom_config, local.hiera_output)

  outputs = [
    "name",
    "vpc_id",
    "azs",
    "dns_zones",
    "private_subnets",
    "public_subnets",
    "database_subnets",
  ]

}
