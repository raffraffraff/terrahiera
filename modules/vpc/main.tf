data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {

  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0.0"

  name      = local.config.name
  azs       = try(local.azs,[])

  cidr      = try(local.config.cidr,"0.0.0.0/0")
  tags      = try(local.config.tags,{})
  vpc_tags  = try(local.config.vpc_tags,{})

  # Required for RDS
  create_database_subnet_group           = try(local.config.create_database_subnet_group, false)
  create_database_subnet_route_table     = try(local.config.create_database_subnet_route_table, false)
  create_database_internet_gateway_route = try(local.config.create_database_internet_gateway_route, false)

  # Optional parameters (with defaults)
  enable_nat_gateway   = try(local.config.enable_nat_gateway, true)
  single_nat_gateway   = try(local.config.single_nat_gateway, true)
  enable_dns_hostnames = try(local.config.enable_dns_hostnames, true)
  enable_dns_support   = try(local.config.enable_dns_support, true)

  # Split subnets into 4x CIDRs and take a slice using size local.vpc.az_count
  private_subnets  = local.private_subnets
  public_subnets   = local.public_subnets
  database_subnets = local.database_subnets

  # Subnet tags
  public_subnet_tags   = try(local.config.public_subnet_tags,{})
  private_subnet_tags  = try(local.config.private_subnet_tags,{})
  database_subnet_tags = try(local.config.database_subnet_tags,{})

  # Internet Gateway
  create_igw             =  try(local.config.create_igw,true)
  create_egress_only_igw =  try(local.config.create_egress_only_igw,true)
  igw_tags               =  try(local.config.igw_tags,{})

  # VPN Gateway
  enable_vpn_gateway                 =  try(local.config.enable_vpn_gateway,false)
  vpn_gateway_id                     =  try(local.config.vpn_gateway_id,"")
  vpn_gateway_az                     =  try(local.config.vpn_gateway_az,null)
  propagate_private_route_tables_vgw =  try(local.config.propagate_private_route_tables_vgw,false)
  propagate_public_route_tables_vgw  =  try(local.config.propagate_public_route_tables_vgw,false)
  vpn_gateway_tags                   =  try(local.config.vpn_gateway_tags,{})

  # Flow Logs
  enable_flow_log                                 =  try(local.config.enable_flow_log,false)
  vpc_flow_log_tags                               =  try(local.config.vpc_flow_log_tags,{})
  vpc_flow_log_permissions_boundary               =  try(local.config.vpc_flow_log_permissions_boundary,null)
  create_flow_log_cloudwatch_log_group            =  try(local.config.create_flow_log_cloudwatch_log_group,false)
  create_flow_log_cloudwatch_iam_role             =  try(local.config.create_flow_log_cloudwatch_iam_role,false)
  flow_log_traffic_type                           =  try(local.config.flow_log_traffic_type,"ALL")
  flow_log_destination_type                       =  try(local.config.flow_log_destination_type,"s3")
  flow_log_log_format                             =  try(local.config.flow_log_log_format,null)
  flow_log_destination_arn                        =  try(local.config.enable_flow_log,false) ? aws_s3_bucket.flow_logs_s3[0].arn : ""

  flow_log_cloudwatch_iam_role_arn                =  try(local.config.flow_log_cloudwatch_iam_role_arn,"")
  flow_log_cloudwatch_log_group_name_prefix       =  try(local.config.flow_log_cloudwatch_log_group_name_prefix,"/aws/vpc-flow-log/")
  flow_log_cloudwatch_log_group_name_suffix       =  try(local.config.flow_log_cloudwatch_log_group_name_suffix,"")
  flow_log_cloudwatch_log_group_retention_in_days =  try(local.config.flow_log_cloudwatch_log_group_retention_in_days,null)
  flow_log_cloudwatch_log_group_kms_key_id        =  try(local.config.flow_log_cloudwatch_log_group_kms_key_id,null)
  flow_log_max_aggregation_interval               =  try(local.config.flow_log_max_aggregation_interval,600)
  flow_log_file_format                            =  try(local.config.flow_log_file_format,"plain-text")
  flow_log_hive_compatible_partitions             =  try(local.config.flow_log_hive_compatible_partitions,false)
  flow_log_per_hour_partition                     =  try(local.config.flow_log_per_hour_partition,false)

}
