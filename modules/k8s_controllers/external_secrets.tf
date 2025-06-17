locals {

  external_secrets_values= yamlencode(
                             merge(
                               try(local.config.external_secrets.values, {}), { 
                               serviceAccount = {
                                 annotations = {
                                   "eks.amazonaws.com/role-arn": module.external_secrets_role.iam_role_arn
                                 }
                               }
                             })
                           )
}

module "external_secrets_role" {

  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                     = join("-", [
                                    "external-secrets",
                                    try(local.config.cluster_name,""),
                                  ])
  external_secrets_kms_key_arns           = [ aws_kms_key.external_secrets_default.arn ]
  attach_external_secrets_policy          = true
  external_secrets_secrets_manager_arns   = try(local.config.external_secrets.secrets_manager_arns,["arn:aws:secretsmanager:*:*:secret:*"])
  external_secrets_ssm_parameter_arns     = try(local.config.external_secrets.ssm_parameter_arns,["arn:aws:ssm:*:*:parameter/*"])

  oidc_providers = {
    main = {
      provider_arn = local.config.oidc_provider_arn
      namespace_service_accounts = [ join(":", [
                                       try(local.config.external_secrets.namespace, "external-secrets"),
                                       "external-secrets"
                                     ])
                                   ]
    }
  }
}

# Create one or more customer managed KMS keys for encrypting secrets
resource "aws_kms_key" "external_secrets_default" {
  description = "External Secrets Operator KMS key for use in SSM Parameter Store"
  enable_key_rotation = true
}

resource "aws_kms_alias" "external_secrets_default" {
  name          = "alias/external_secrets_${local.config.cluster_name}"
  target_key_id = aws_kms_key.external_secrets_default.key_id
}

# Deploy External Secrets Operator
resource "helm_release" "external-secrets" {

  chart      = "external-secrets"
  repository = "https://charts.external-secrets.io"
  name       = "external-secrets"
  version    = try(local.config.external_secrets.version, "0.8.3")
  namespace  = try(local.config.external_secrets.namespace, "external-secrets")

  create_namespace = true

  values     = [ local.external_secrets_values ]

  set {
    name  = "installCRDs"
    value = true
  }

  depends_on = [
    module.external_secrets_role
  ]
}

# Create a ClusterSecretStore
resource "helm_release" "external_secrets_cluster_store" {
  name       = "external-secrets-cluster-store"
  chart      = "${path.module}/charts/raw"
  namespace  = try(local.config.external_secrets.namespace, "external-secrets")
  version    = "0.2.5"
  values = [
    <<-EOF
    resources:
    - apiVersion: external-secrets.io/v1beta1
      kind: ClusterSecretStore
      metadata:
        name: aws-parameter-store
      spec:
        provider:
          aws:
            service: ParameterStore
            region: ${local.config.region}
            auth:
              jwt:
                serviceAccountRef:
                  name: external-secrets
                  namespace: ${try(local.config.external_secrets.namespace, "external-secrets")}
    EOF
  ]
  depends_on = [ helm_release.external-secrets ]

}
