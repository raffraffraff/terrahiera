data "aws_ec2_instance_type_offerings" "all" {}
data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  # provides info about the IAM source role of an STS assumed role, required for KMS key admins
  arn = data.aws_caller_identity.current.arn
}

data "aws_iam_roles" "sso-admin" {
  name_regex = ".*AWSReservedSSO_Administrator.*"
}

data "aws_iam_roles" "sso-ro" {
  name_regex = ".*AWSReservedSSO_Administrator.*"
}

