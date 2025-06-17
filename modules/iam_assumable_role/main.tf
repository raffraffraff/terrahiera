module "iam_assumable_role" {

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  for_each = try(local.config,{}) 

  admin_role_policy_arn               =   try(each.value.admin_role_policy_arn,"arn:aws:iam::aws:policy/AdministratorAccess")
  allow_self_assume_role              =   try(each.value.allow_self_assume_role,false)
  attach_admin_policy                 =   try(each.value.attach_admin_policy,false)
  attach_poweruser_policy             =   try(each.value.attach_poweruser_policy,false)
  attach_readonly_policy              =   try(each.value.attach_readonly_policy,false)
  create_custom_role_trust_policy     =   try(each.value.create_custom_role_trust_policy,false)
  create_instance_profile             =   try(each.value.create_instance_profile,false)
  create_role                         =   try(each.value.create_role,false)
  custom_role_policy_arns             =   try(each.value.custom_role_policy_arns,[])
  custom_role_trust_policy            =   try(each.value.custom_role_trust_policy,"")
  force_detach_policies               =   try(each.value.force_detach_policies,false)
  inline_policy_statements            =   try(each.value.inline_policy_statements,[])
  max_session_duration                =   try(each.value.max_session_duration,3600)
  mfa_age                             =   try(each.value.mfa_age,86400)
  number_of_custom_role_policy_arns   =   try(each.value.number_of_custom_role_policy_arns,null)
  poweruser_role_policy_arn           =   try(each.value.poweruser_role_policy_arn,"arn:aws:iam::aws:policy/PowerUserAccess")
  readonly_role_policy_arn            =   try(each.value.readonly_role_policy_arn,"arn:aws:iam::aws:policy/ReadOnlyAccess")
  role_description                    =   try(each.value.role_description,"")
  role_name                           =   try(each.value.role_name,null)
  role_name_prefix                    =   try(each.value.role_name_prefix,null)
  role_path                           =   try(each.value.role_path,"/")
  role_permissions_boundary_arn       =   try(each.value.role_permissions_boundary_arn,"")
  role_requires_mfa                   =   try(each.value.role_requires_mfa,true)
  role_requires_session_name          =   try(each.value.role_requires_session_name,false)
  role_session_name                   =   try(each.value.role_session_name,["${aws:username}"])
  role_sts_externalid                 =   try(each.value.role_sts_externalid,[])
  tags                                =   try(each.value.tags,{})
  trust_policy_conditions             =   try(each.value.trust_policy_conditions,[])
  trusted_role_actions                =   try(each.value.trusted_role_actions,["sts:AssumeRole","sts:TagSession"])
  trusted_role_arns                   =   try(each.value.trusted_role_arns,[])
  trusted_role_services               =   try(each.value.trusted_role_services,[])

}

