data "aws_iam_policy_document" "registry" {
  count = try(local.registry.policy, {}) == {} ? 0 : 1

  dynamic statement {
    for_each  = try(local.registry.policy,{})
    content {
      sid        = try(statement.value.sid, statement.key, null)
      effect     = try(statement.value.effect, "Allow")
      actions    = try(statement.value.actions, [
                     "ecr:ListTagsForResource",
                     "ecr:ListImages",
                     "ecr:DescribeImages",
                     "ecr:GetDownloadUrlForLayer",
                     "ecr:BatchGetImage",
                     "ecr:GetAuthorizationToken",
                     "ecr:BatchCheckLayerAvailability"
                   ])

      dynamic principals {
        for_each = try(statement.value.principals, {})
        content {
          type        = principals.key
          identifiers = [ principals.value ]
        }
      }
    }
  }
}

module "ecr_registry" {
  source   = "terraform-aws-modules/ecr/aws"

  create_repository      = false
  create_registry_policy = try(local.registry.policy, {}) == {} ? false : true
  registry_policy        = try(local.registry.policy, {}) == {} ? "" : data.aws_iam_policy_document.registry[0].json
  registry_replication_rules = try(local.registry.replication_rules, {})
  manage_registry_scanning_configuration = true
  registry_scan_type     = try(local.registry.registry_scan_type, "BASIC")
  registry_scan_rules    = try(local.registry.registry_scan_rules, [])
  registry_pull_through_cache_rules = try(local.registry.pull_through_cache, {})
  tags        =   try(local.registry.tags,{})
}

# Registry scan rules needs a _list of rules_ and each rule should have:
# - scan_frequency (string)
# - filter (list of objects containin filter and filter_type)
#
# Hiera example:
# registry_scan_rules:
# - scan_frequency: "ON_PUSH"
#   filter:
#   - filter: "*"
#     filter_type: "WILDCARD"
#
# Example code in upstream module:
#
#   registry_scan_rules = [
#     {
#       scan_frequency = "SCAN_ON_PUSH"
#       filter = [
#         {
#           filter      = "example1"
#           filter_type = "WILDCARD"
#         },
#         { filter      = "example2"
#           filter_type = "WILDCARD"
#         }
#       ]
#     }
#   ]
