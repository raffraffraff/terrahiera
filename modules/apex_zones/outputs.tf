locals {
  output = {
             "zone_map" = { for k, v in aws_route53_zone.apex :
                  k => {
                   zone_id      = v.zone_id
                   arn          = v.arn
                   name_servers = v.name_servers
                  }
                }

             "apex_zone_arns" = [ for k, v in aws_route53_zone.apex : v.arn ]
             "apex_zone_name_servers" = { for k, v in aws_route53_zone.apex : v.name => v.name_servers }
  }
}

output "output" {
  value = local.output
}
