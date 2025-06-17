locals {
  config = jsondecode(var.config)

  # SSO > cluster-admin
  admin_role = replace(
                 one(data.aws_iam_roles.sso-admin.arns),
                 "/[a-z]+-[a-z]+/([a-z]+(\\.[a-z]+)+)\\//", ""
               )

  aws_auth_roles = concat([
                      {
                         rolearn  = local.admin_role
                         username = "cluster-admin"
                         groups   = ["system:masters"]
                      }
                   ],
                   try(local.config.aws_auth_roles,[])
                   )


  # Nodes

  eks_managed_node_groups = { for group, group_config in try(local.config.eks_managed_node_groups,{}):
    group => {
      name            = group
      subnet_ids      = try(group_config.single_az, false) ? slice(local.config.subnet_ids, 0, 1) : local.config.subnet_ids
      key_name        = module.key_pair.key_pair_name

      capacity_type        = try(group_config.capacity_type,"ON_DEMAND")
      force_update_version = try(group_config.force_update_version, true)
      instance_types       = sort(try(group_config.instance_types,
                                 flatten([
                                   for instance_type in data.aws_ec2_instance_type_offerings.all.instance_types : [
                                     for pattern in group_config.instance_type_regexes : 
                                       try(regex(pattern, instance_type), [])
                                   ]
                                 ]),
                                 [ "m5a.large" ]
                             ))

      min_size     = try(group_config.min_size, 1)
      max_size     = try(group_config.max_size, 5)
      desired_size = try(group_config.desired_size, 4)

      taints = [ for taint in try(group_config.taints,[]):
        {
          key    = taint.key
          value  = taint.value
          effect = taint.effect
        }
      ]

      labels = { for key, value in try(group_config.labels,{}):
        key => value
      }

      update_config = {
        max_unavailable_percentage = try(group_config.max_unavailable_percentage, 33)
      }

      ebs_optimized         = true
      block_device_mappings = { 
        xvda = { 
          device_name = "/dev/xvda" 
          ebs = { 
            volume_size           = try(group_config.block_device.size, 50)
            volume_type           = try(group_config.block_device.type, "gp3")
            iops                  = try(group_config.block.device.iops, 3000)
            throughput            = try(group_config.block_device.throughput, 150)
            encrypted             = true 
            kms_key_id            = module.ebs_kms_key.key_arn 
            delete_on_termination = true 
          } 
        } 
      }

      create_iam_role          = true
      iam_role_name            = try(group_config.iam_role_name, "${local.config.cluster_name}-eks-node-group-${group}")
      iam_role_use_name_prefix = false
      iam_role_description     = "Role for EKS cluster ${local.config.cluster_name}, managed node group ${group}"
      iam_role_tags = {
        Purpose = "Protector of the kubelet."
      }
      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }
    }
  }
}
