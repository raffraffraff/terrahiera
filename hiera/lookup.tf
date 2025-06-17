locals {

  # Effective lookup_key should be the stack name if var.lookup_key is empty
  lookup_key = coalesce(var.lookup_key, var.stack)

  # Create a "scope" map for the Hiera provider, and to return as an output
  scope = {
    aws_account      = var.aws_account
    region           = var.region
    group            = var.group
    vpc              = join("-",[var.aws_account,var.group])
    stack            = var.stack
  }
}

data "hiera5_json" "stack" {
  key     = local.lookup_key
  default = var.default
}

