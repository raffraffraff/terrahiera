locals {
  role_arn_prefix = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role"
  vpc_cni_role    = join("-", [local.config.cluster_name,"vpc_cni_irsa"])
  ebs_csi_role    = join("-", [local.config.cluster_name,"ebs_csi_irsa"])

  addon_irsa = {
    "vpc-cni"            = join("/", [local.role_arn_prefix, local.vpc_cni_role])
    "aws-ebs-csi-driver" = join("/", [local.role_arn_prefix, local.ebs_csi_role])

    #"vpc-cni"            = module.vpc_cni_irsa.iam_role_arn
    #"aws-ebs-csi-driver" = module.ebs_csi_irsa.iam_role_arn
  }

  cluster_addons_with_sa = { for k, v in try(local.config.cluster_addons,{}):
    k => {
        addon_name                  = try(v.name, k)
        addon_version               = try(v.addon_version, null)
        configuration_values        = try(jsonencode(v.configuration_values), null)
        most_recent                 = try(v.most_recent, null)
        preserve                    = try(v.preserve, null)
        resolve_conflicts_on_create = try(v.resolve_conflicts_on_create, "OVERWRITE")
        resolve_conflicts_on_update = try(v.resolve_conflicts_on_update, "OVERWRITE")
        service_account_role_arn    = try(local.addon_irsa[k],null)
    }
  }
}

module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = join("-", [local.config.cluster_name,"vpc_cni_irsa"])
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = local.config.tags
}

module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = join("-", [local.config.cluster_name,"ebs_csi_irsa"])
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.config.tags
}

resource "kubernetes_annotations" "gp2_default_false" {
  annotations = {
    "storageclass.kubernetes.io/is-default-class" : "false"
  }
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  metadata {
    name = "gp2"
  }

  force = true

  depends_on = [module.ebs_csi_irsa]
}

resource "kubernetes_storage_class" "ebs_csi_encrypted_gp3_storage_class" {
  metadata {
    name = "ebs-csi-encrypted-gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" : "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
  parameters = {
    fsType    = "ext4"
    encrypted = true
    type      = "gp3"
  }

  depends_on = [kubernetes_annotations.gp2_default_false]
}

