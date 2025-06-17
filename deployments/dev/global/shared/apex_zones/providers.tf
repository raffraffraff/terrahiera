provider "aws" {
  region = local.aws_region
  # Use AWS SSO and export AWS_PROFILE, or use aws-vault
}

terraform {
  required_version = "~> 1.0"
 
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
