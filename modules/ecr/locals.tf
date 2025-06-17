locals {
  config = jsondecode(var.config)

  repositories = try(local.config.repositories,{})
  registry     = try(local.config.registry,{})
  policies     = try(local.config.policies,{})

}
