module "fluxcd_role" {

  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name        = join("-", ["fluxcd", local.config.cluster_name])
  role_policy_arns = {
    policy = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }

  oidc_providers = {
    main = {
      provider_arn = local.config.oidc_provider_arn
      namespace_service_accounts = [ join(":", [
                                       try(local.config.fluxcd.namespace, "flux-system"),
                                       "image-reflector-controller"
                                     ])
                                   ]
    }
  }
}

# NEXT STEPS
#
# Manually annotate the service account:
#
#                     serviceAccount = {
#                       annotations = {
#                         "eks.amazonaws.com/role-arn": module.fluxcd_role.iam_role_arn
#                       }
#                     }
# 
# TODO
#
# Update cluster_extras module to install fluxcd using the Terraform provider 
# https://github.com/fluxcd/terraform-provider-flux
#
# TL;DR:
# - Generate a personal access token (PAT) with repo permissions
# - Store it in Parameter Store and use Hiera to look it up (via the plugin!)
# - Complete the work on this module and deployment
# - Import existing fluxcd OR uninstall it and bootstrap it with terraform
# 
# # FluxCD terraform provider
# https://github.com/fluxcd/terraform-provider-flux
# 
# This provider lets you install FluxCD on a Kubernetes cluster and configure it to
# reconsile with a git repo.
# 
# ## Provider config
# We need FluxCD, Kubernetes and GitHub providers. Possible helm too. When configuring
# 'flux', we need to give it our Kubernetes and Git configs separately.
# 
# ```
# provider "flux" {
#   kubernetes = {
#     host                   = endpoint
#     client_certificate     = client_certificate
#     client_key             = client_key
#     cluster_ca_certificate = cluster_ca_certificate
#   }
#   git = {
#     url  = var.repository_ssh_url
#     ssh = {
#       username    = "git"
#       private_key = var.private_key_pem
#     }
#   }
# }
# 
# provider "github" {
#   owner = var.github_org
#   token = var.github_token
# }
# ```
# 
# ## Git repo config
# Whether we create the repo manually or with Terraform doesn't matter. For FluxCD to
# work we need to create a TLS key and add it to the repo. This is something that we
# could do entirely within the github module, and read the TLS private key from the
# output via `remote_state`. Or we could just do it here. IF we do it here, you need
# make sure that the TLS private key exists first, so you may need to add a depends_on
# to the `flux_bootstrap_git` resource
# 
# ```
# resource "tls_private_key" "flux" {
#   algorithm   = "ECDSA"
#   ecdsa_curve = "P256"
# }
# 
# resource "github_repository_deploy_key" "this" {
#   title      = "Flux"
#   repository = var.github_repository
#   key        = tls_private_key.flux.public_key_openssh
#   read_only  = "false"
# }
# ```
# 
# Finally, you can bootstrap Flux with the git repo:
# ```
# resource "flux_bootstrap_git" "this" {
#   path = "clusters/my-cluster"
# }
# ```
