module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "~> 2.0" 
    
  key_name_prefix    = local.config.cluster_name
  create_private_key = true
                         
  tags = local.config.tags  
}

resource "aws_iam_role" "breakglass_role" {
  # If anything happens to our AWS SSO admin role, we can fall back to this
  assume_role_policy = data.aws_iam_policy_document.trust_current_account.json
}

resource "aws_iam_role_policy" "breakglass_permissions" {
  name = join("-", [ local.config.cluster_name, "breakglass"])
  role = aws_iam_role.breakglass_role.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "kms:*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}

data "aws_iam_policy_document" "trust_current_account" {
  statement {
    actions = ["sts:AssumeRole"]
    # trust the current account
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "null_resource" "service_linked_role" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "${path.module}/scripts/service-linked-role.sh"
  }
}

module "ebs_kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 1.5"

  aliases     = ["eks/${local.config.cluster_name}/ebs"]
  description = "Customer managed key to encrypt EKS managed node group volumes"

  key_administrators = [
    data.aws_iam_session_context.current.issuer_arn,
    aws_iam_role.breakglass_role.arn
  ]

  key_service_roles_for_autoscaling = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
    module.eks.cluster_iam_role_arn,
  ]
  
  depends_on = [ null_resource.service_linked_role ]
  tags        = local.config.tags
}
