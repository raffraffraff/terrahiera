# Create VPC zone, eg: ew1a.internal.net:
resource "aws_route53_zone" "this" {
  for_each      = try(local.config.apex_zones, {})
  
  name          = join(".", [ local.config.name, each.key ])
  comment       = try(each.value.comment, null)
  force_destroy = try(each.value.force_destroy, false)

  tags          = try(local.config.tags, {})
}

# Add an NS record for the zone to the apex zone, delegating to this zone's name servers
resource "aws_route53_record" "this" {
  for_each        = try(local.config.apex_zones, {})
  
  allow_overwrite = true
  name            = join(".", [ local.config.name, each.key ])
  ttl             = "30"
  type            = "NS"
  zone_id         = local.config.apex_zones[each.key].zone_id

  records         = aws_route53_zone.this[each.key].name_servers
}
