output "iam_instance_profile_arn" {
  value = { for k, v in module.iam_assumable_role : k => v.iam_instance_profile_arn }
}

output "iam_instance_profile_id" {
  value = { for k, v in module.iam_assumable_role : k => v.iam_instance_profile_id }
}

output "iam_instance_profile_name" {
  value = { for k, v in module.iam_assumable_role : k => v.iam_instance_profile_name }
}

output "iam_instance_profile_path" {
  value = { for k, v in module.iam_assumable_role : k => v.iam_instance_profile_path }
}

output "iam_role_arn" {
  value = { for k, v in module.iam_assumable_role : k => v.iam_role_arn }
}

output "iam_role_name" {
  value = { for k, v in module.iam_assumable_role : k => v.iam_role_name }
}

output "iam_role_path" {
  value = { for k, v in module.iam_assumable_role : k => v.iam_role_path }
}

output "iam_role_unique_id" {
  value = { for k, v in module.iam_assumable_role : k => v.iam_role_unique_id }
}

output "role_requires_mfa" {
  value = { for k, v in module.iam_assumable_role : k => v.role_requires_mfa }
}

output "role_sts_externalid" {
  value = { for k, v in module.iam_assumable_role : k => v.role_sts_externalid }
}

