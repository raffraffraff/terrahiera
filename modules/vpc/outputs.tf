locals {
  output = merge(module.vpc, {
               dns_zones =  { for k, v in aws_route53_zone.this :
                 v.name => {
                   zone_id      = v.zone_id
                   arn          = v.arn
                   name_servers = v.name_servers
                 }
               }
               dns_zone_arns =  [ for k, v in aws_route53_zone.this : v.arn ]
               dns_zone_name_servers = { for k, v in aws_route53_zone.this : v.name => v.name_servers }
             }
           )
}

output "output" {
  value = local.output
}
