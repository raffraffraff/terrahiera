output "json" {
  value = data.hiera5_json.stack.value
}

output "provider_config" {
  value = {
    config = join("/", [ dirname(abspath(path.module)), "hiera.yaml" ])
    scope = local.scope
  }
}
           
output "scope" {
  value = local.scope
}

