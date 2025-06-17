output "repository_arn" {
  value = { for k, v in module.ecr : k => v.repository_arn }
}

output "repository_registry_id" {
  value = { for k, v in module.ecr : k => v.repository_registry_id }
}

output "repository_url" {
  value = { for k, v in module.ecr : k => v.repository_url }
}
