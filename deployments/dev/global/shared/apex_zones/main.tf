locals {

  dependencies = {
  }

  custom_config = {
  }

  stack_config = merge(local.custom_config, jsondecode(module.hiera.json))

  outputs = [
    "zone_map"
  ]

}
