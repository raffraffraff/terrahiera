locals {
  config  = jsondecode(var.config)

  azs          = slice(reverse(data.aws_availability_zones.available.names), 0, local.config.az_count)

  subnet_cidrs  = cidrsubnets(local.config.cidr, 4, 4, 4, 4)
  private_cidr  = element(local.subnet_cidrs, 0)
  public_cidr   = element(local.subnet_cidrs, 1)
  database_cidr = element(local.subnet_cidrs, 2)

  private_subnets  = try(local.config.create_private_subnets,true)  ? slice(cidrsubnets(local.private_cidr,4,4,4,4), 0, local.config.az_count) : []
  public_subnets   = try(local.config.create_public_subnets,true)   ? slice(cidrsubnets(local.public_cidr,4,4,4,4), 0, local.config.az_count)  : []
  database_subnets = try(local.config.create_database_subnets,true) ? slice(cidrsubnets(local.database_cidr,4,4,4,4), 0, local.config.az_count): []

}
