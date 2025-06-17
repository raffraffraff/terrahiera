resource "aws_route53_delegation_set" "apex" {
  for_each       = try(local.config, {})
  reference_name = "Namecheap"
}

resource "aws_route53_zone" "apex" {
  for_each      = try(local.config, {})
  
  name          = try(each.value.domain_name, each.key)
  comment       = try(each.value.comment, null)
  force_destroy = try(each.value.force_destroy, false)

  delegation_set_id = aws_route53_delegation_set.apex[each.key].id

  tags = try(local.config.tags, {})
}
