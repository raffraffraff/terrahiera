#resource "aws_ecr_repository_policy" "this" {
#  for_each   = { for repository, conf in try(local.config.repositories, {}) :
#                 repository => {
#                   policy = data.aws_iam_policy_document.this[conf.policy].json
#                 } if try(conf.policy, "") != ""
#               }
#  repository = each.key
#  policy     = each.value.policy
#
#  depends_on = [ module.ecr ]
#}

data "aws_iam_policy_document" "this" {
  for_each = try(local.policies, {})

  dynamic statement {
    for_each  = try(each.value.statements,{})
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

      dynamic condition {
        for_each = try(statement.value.conditions, {})
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }

    }
  }
}
