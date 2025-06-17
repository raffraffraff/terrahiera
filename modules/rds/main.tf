resource "random_password" "rds_master_password" {
  for_each = try(local.config,{})
  length   = 16
  special  = false
}

module "rds" {

  source  = "terraform-aws-modules/rds/aws"

  for_each = try(local.config,{}) 

  allocated_storage                        =   try(each.value.allocated_storage,null)
  allow_major_version_upgrade              =   try(each.value.allow_major_version_upgrade,false)
  apply_immediately                        =   try(each.value.apply_immediately,false)
  auto_minor_version_upgrade               =   try(each.value.auto_minor_version_upgrade,true)
  availability_zone                        =   try(each.value.availability_zone,null)
  backup_retention_period                  =   try(each.value.backup_retention_period,null)
  backup_window                            =   try(each.value.backup_window,null)
  blue_green_update                        =   try(each.value.blue_green_update,{})
  ca_cert_identifier                       =   try(each.value.ca_cert_identifier,null)
  character_set_name                       =   try(each.value.character_set_name,null)
  cloudwatch_log_group_kms_key_id          =   try(each.value.cloudwatch_log_group_kms_key_id,null)
  cloudwatch_log_group_retention_in_days   =   try(each.value.cloudwatch_log_group_retention_in_days,7)
  copy_tags_to_snapshot                    =   try(each.value.copy_tags_to_snapshot,false)
  create_cloudwatch_log_group              =   try(each.value.create_cloudwatch_log_group,false)
  create_db_instance                       =   try(each.value.create_db_instance,true)
  create_db_option_group                   =   try(each.value.create_db_option_group,true)
  create_db_parameter_group                =   try(each.value.create_db_parameter_group,true)
  create_db_subnet_group                   =   try(each.value.create_db_subnet_group,false)
  create_monitoring_role                   =   try(each.value.create_monitoring_role,false)
  custom_iam_instance_profile              =   try(each.value.custom_iam_instance_profile,null)
  db_instance_tags                         =   try(each.value.db_instance_tags,{})
  db_name                                  =   try(each.value.db_name, "postgres")
  db_option_group_tags                     =   try(each.value.db_option_group_tags,{})
  db_parameter_group_tags                  =   try(each.value.db_parameter_group_tags,{})
  db_subnet_group_description              =   try(each.value.db_subnet_group_description,null)
  db_subnet_group_name                     =   try(each.value.db_subnet_group_name,null)
  db_subnet_group_tags                     =   try(each.value.db_subnet_group_tags,{})
  db_subnet_group_use_name_prefix          =   try(each.value.db_subnet_group_use_name_prefix,true)
  delete_automated_backups                 =   try(each.value.delete_automated_backups,true)
  deletion_protection                      =   try(each.value.deletion_protection,false)
  domain                                   =   try(each.value.domain,null)
  domain_iam_role_name                     =   try(each.value.domain_iam_role_name,null)
  enabled_cloudwatch_logs_exports          =   try(each.value.enabled_cloudwatch_logs_exports,[])
  engine                                   =   try(each.value.engine,null)
  engine_version                           =   try(each.value.engine_version,null)
  family                                   =   try(each.value.family,null)
  final_snapshot_identifier_prefix         =   try(each.value.final_snapshot_identifier_prefix,"final")
  iam_database_authentication_enabled      =   try(each.value.iam_database_authentication_enabled,false)
  identifier                               =   try(each.value.identifier,each.key)
  instance_class                           =   try(each.value.instance_class,null)
  instance_use_identifier_prefix           =   try(each.value.instance_use_identifier_prefix,false)
  iops                                     =   try(each.value.iops,null)
  kms_key_id                               =   try(each.value.kms_key_id,null)
  license_model                            =   try(each.value.license_model,null)
  maintenance_window                       =   try(each.value.maintenance_window,null)
  major_engine_version                     =   try(each.value.major_engine_version,null)
  max_allocated_storage                    =   try(each.value.max_allocated_storage,0)
  monitoring_interval                      =   try(each.value.monitoring_interval,0)
  monitoring_role_arn                      =   try(each.value.monitoring_role_arn,null)
  monitoring_role_description              =   try(each.value.monitoring_role_description,null)
  monitoring_role_name                     =   try(each.value.monitoring_role_name,"${each.key}-rds-monitoring-role")
  monitoring_role_permissions_boundary     =   try(each.value.monitoring_role_permissions_boundary,null)
  monitoring_role_use_name_prefix          =   try(each.value.monitoring_role_use_name_prefix,false)
  multi_az                                 =   try(each.value.multi_az,false)
  nchar_character_set_name                 =   try(each.value.nchar_character_set_name,null)
  network_type                             =   try(each.value.network_type,null)
  option_group_description                 =   try(each.value.option_group_description,null)
  option_group_name                        =   try(each.value.option_group_name,null)
  option_group_timeouts                    =   try(each.value.option_group_timeouts,{})
  option_group_use_name_prefix             =   try(each.value.option_group_use_name_prefix,true)
  options                                  =   try(each.value.options,[])
  parameter_group_description              =   try(each.value.parameter_group_description,null)
  parameter_group_name                     =   try(each.value.parameter_group_name,null)
  parameter_group_use_name_prefix          =   try(each.value.parameter_group_use_name_prefix,true)
  parameters                               =   [ for key, val in try(each.value.parameters,{}): {
                                                 name = key,
                                                 value = val
                                               }]
  manage_master_user_password              =   false
  password                                 =   random_password.rds_master_password[each.key].result
  performance_insights_enabled             =   try(each.value.performance_insights_enabled,false)
  performance_insights_kms_key_id          =   try(each.value.performance_insights_kms_key_id,null)
  performance_insights_retention_period    =   try(each.value.performance_insights_retention_period,7)
  port                                     =   try(each.value.port,null)
  publicly_accessible                      =   try(each.value.publicly_accessible,false)
  replica_mode                             =   try(each.value.replica_mode,null)
  replicate_source_db                      =   try(each.value.replicate_source_db,null)
  restore_to_point_in_time                 =   try(each.value.restore_to_point_in_time,null)
  s3_import                                =   try(each.value.s3_import,null)
  skip_final_snapshot                      =   try(each.value.skip_final_snapshot,false)
  snapshot_identifier                      =   try(each.value.snapshot_identifier,null)
  storage_encrypted                        =   try(each.value.storage_encrypted,true)
  storage_throughput                       =   try(each.value.storage_throughput,null)
  storage_type                             =   try(each.value.storage_type,null)
  subnet_ids                               =   try(each.value.subnet_ids,[])
  tags                                     =   try(each.value.tags,{})
  timeouts                                 =   try(each.value.timeouts,{})
  timezone                                 =   try(each.value.timezone,null)
  username                                 =   try(each.value.username,null)
  vpc_security_group_ids                   =   [
                                                module.sg_ingress[each.key].security_group_id,
                                               ]

}

