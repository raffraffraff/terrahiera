resource "helm_release" "all" {
  for_each         = local.helm_releases
  name             = each.value.name
  namespace        = each.value.namespace
  repository       = each.value.repository
  wait             = each.value.wait
  timeout          = each.value.timeout
  create_namespace = each.value.create_namespace
  chart            = each.value.chart
  version          = each.value.version
  force_update     = each.value.force_update
  values           = each.value.values
  dynamic "set" {
    for_each       = each.value["set"]
    content {
      name         = set.key
      value        = try("{${join(",", set.value)}}", set.value)
    }
  }
  dynamic "set_sensitive" {
    for_each       = each.value["set_sensitive"]
    content {
      name         = set_sensitive.key
      value        = try("{${join(",", set_sensitive.value)}}", set_sensitive.value)
    }
  }
}
