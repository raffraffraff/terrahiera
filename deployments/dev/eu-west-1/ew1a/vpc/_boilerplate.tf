locals {

  # Derive context from deployment directory structure
  pathdirs    = split("/", abspath(path.root))
  stack       = element(local.pathdirs, length(local.pathdirs) - 1)
  group       = element(local.pathdirs, length(local.pathdirs) - 2)
  region      = element(local.pathdirs, length(local.pathdirs) - 3)
  aws_account = element(local.pathdirs, length(local.pathdirs) - 4)

  # NOTES ABOUT REGION:
  # You must use the deployment region in your Terraform Provider and S3 Backend configurations. This guarantees
  # that you are compliant with regulations like GDPR and removes several foot-guns. The only issue with this, is
  # that it makes it necessary to create S3 backend buckets in each region you deploy to.
  # Also note that, since we allow a 'global' region in our deployments directory (to keep global resources like
  # apex DNS zones separate from region-specific deployments) we must provide a default fallback region for the
  # provider, backend, SSM parameter store etc.
  aws_region  = local.region == "global" ? "eu-west-1" : local.region

  # work out dependencies configs
  dependencies_map = { for key, val in local.dependencies :
    key => zipmap(["stack", "group", "region", "aws_account"], slice(reverse(split("/", abspath(val))), 0, 4))
  }

  # expose outputs from each dependency
  dependency = { for key, _ in local.dependencies_map :
    key => jsondecode(nonsensitive(data.aws_ssm_parameter.this[key].value))
  }

  # output only selected keys/vals [default: "all outputs"]
  output = { for key in coalescelist(local.outputs,keys(module.this.output)):
             key => module.this.output[key] 
  }

}

# Save outputs to SSM Parameter Store, for other modules to use
resource "aws_ssm_parameter" "tf_output_to_ssm" {
  name  = "/tfoutput/${local.group}/${local.stack}"
  type  = "String"
  value = jsonencode(local.output)
}

# Read output of dependency modules from their SSM Parameter Store paths
data "aws_ssm_parameter" "this" {
  for_each = local.dependencies_map
  name     = "/tfoutput/${each.value.group}/${each.value.stack}"
}

# NOTE: Using variables in the backend configuration requires OpenTofu, because Terraform does not support them
terraform {
  backend "s3" {
    bucket  = "companyname-${local.aws_account}-${local.region}-tf-state"                    # Assumes single bucket for region, with separate keys per group / stack
    key     = join("-", [local.aws_account, local.group, local.stack, "tfstate"])
    region  = local.aws_region
    # Use AWS_PROFILE with AWS SSO or use aws-vault. This example assumes that your S3 backend region depends on the deployment region.
  }
}

# Hiera module performs data lookup and returns results as output
module "hiera" {
  source      = "../../../../../hiera"
  stack       = local.stack
  group       = local.group
  region      = local.region
  aws_account = local.aws_account
}

# Apply stack wrapper module (matches current directory name)
module "this" {
  source = "../../../../../modules/${local.stack}"
  config = jsonencode(local.stack_config)
}

output "output" {
  value = local.output
}
