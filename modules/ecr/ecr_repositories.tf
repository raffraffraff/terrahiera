module "ecr" {
  source   = "terraform-aws-modules/ecr/aws"
  for_each = try(local.repositories,{}) 

  attach_repository_policy                    =   try(each.value.attach_repository_policy,true)
  create                                      =   try(each.value.create,true)
  create_lifecycle_policy                     =   try(each.value.lifecycle_rules, {}) != {} ? true : false
  create_registry_policy                      =   try(each.value.create_registry_policy,false)
  create_registry_replication_configuration   =   try(each.value.create_registry_replication_configuration,false)
  create_repository                           =   try(each.value.create_repository,true)
  create_repository_policy                    =   try(each.value.policy_name,"") == "" ? true : false
  manage_registry_scanning_configuration      =   try(each.value.manage_registry_scanning_configuration,false)
  public_repository_catalog_data              =   try(each.value.public_repository_catalog_data,{})
  registry_policy                             =   try(each.value.registry_policy,null)
  registry_pull_through_cache_rules           =   try(each.value.registry_pull_through_cache_rules,{})
  registry_replication_rules                  =   try(each.value.registry_replication_rules,[])
  registry_scan_rules                         =   try(each.value.registry_scan_rules,[])
  registry_scan_type                          =   try(each.value.registry_scan_type,"ENHANCED")
  repository_encryption_type                  =   try(each.value.repository_encryption_type,null)
  repository_force_delete                     =   try(each.value.repository_force_delete,null)
  repository_image_scan_on_push               =   try(each.value.repository_image_scan_on_push,true)
  repository_image_tag_mutability             =   try(each.value.repository_image_tag_mutability,"IMMUTABLE")
  repository_kms_key                          =   try(each.value.repository_kms_key,null)
  repository_lambda_read_access_arns          =   try(each.value.repository_lambda_read_access_arns,[])
  repository_lifecycle_policy                 =   jsonencode({
                                                    rules = [ for rule, rule_conf in try(each.value.lifecycle_rules,{}) :
                                                      {
                                                        rulePriority = tonumber(rule)
                                                        description  = try(rule_conf.description, "")
                                                        selection    = rule_conf.selection
                                                        action = {
                                                          type = "expire"
                                                        }
                                                      }
                                                    ]
                                                  })
  repository_name                             =   try(each.value.repository_name,each.key)
  repository_policy                           =   try(each.value.policy_name,"") == "" ? "" : data.aws_iam_policy_document.this[each.value.policy_name].json
  repository_read_access_arns                 =   try(each.value.repository_read_access_arns,[])
  repository_read_write_access_arns           =   try(each.value.repository_read_write_access_arns,[])
  repository_type                             =   try(each.value.repository_type,"private")
  tags                                        =   try(each.value.tags,{})
}
