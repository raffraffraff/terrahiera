module "sg_ingress" {
  source  = "terraform-aws-modules/security-group/aws"

  for_each    = try(local.config,{}) 
  vpc_id      = each.value.vpc_id
  tags        = try(each.value.tags, {})
  name        = join("-", [
                  "rds", 
                  try(each.value.identifier, each.key),
                  "vpc",
                  each.value.vpc_name
                ])

  description = "Grant VPC ${each.value.vpc_name} CIDR and allowed_cidrs access to RDS instance ${try(each.value.identifier, each.key)}"

  # ingress
  ingress_rules       = ["postgresql-tcp"]
  ingress_cidr_blocks = flatten([
                          each.value.vpc_cidr_block,
                          try(each.value.allowed_cidrs,[])
                        ])


}
