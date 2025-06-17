resource "aws_route53_record" "this" {
  for_each = try(local.records, {})
  name     = each.value.name
  ttl      = each.value.ttl
  type     = each.value.type
  records  = each.value.records
  zone_id  = each.value.zone_id
}

locals {
  records_set = flatten([ 
                  for apex_zone, zone_conf in try(local.config, {}): [
                    for record, record_conf in try(zone_conf.records,{}): {
                      key     = record   # required to convert set into map
                      name    = try(record_conf.name, aws_route53_zone.apex[apex_zone].name)
                      ttl     = try(record_conf.ttl, 600)
                      type    = record_conf.type
                      zone_id = aws_route53_zone.apex[apex_zone].zone_id
                      records = record_conf.records
                    }
                  ]
                ]) 

 records      = { for set in local.records_set:
                    set.key => set
                }
}
