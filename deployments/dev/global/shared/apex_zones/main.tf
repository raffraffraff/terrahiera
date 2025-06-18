locals {

  dependencies = {
  }

  custom_config = {
  }

  stack_config = merge(local.custom_config, local.hiera_output)

  outputs = [
    "zone_map"
  ]

}
