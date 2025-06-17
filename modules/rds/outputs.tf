# RDS Instance

output "db_instance_address" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_instance_address,null)
  }
}

output "db_instance_arn" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_instance_arn,null)
  }
}

output "db_instance_availability_zone" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_instance_availability_zone,null)
  }
}

output "db_instance_ca_cert_identifier" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_instance_ca_cert_identifier,null)
  }
}

output "db_instance_cloudwatch_log_groups" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_instance_cloudwatch_log_groups,null)
  }
}

output "db_instance_domain" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_instance_domain,null)
  }
}

output "db_instance_domain_iam_role_name" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_instance_domain_iam_role_name,null)
  }
}

output "db_instance_endpoint" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_instance_endpoint,null)
  }
}

output "db_instance_engine" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_instance_engine,null)
  }
}

output "db_instance_engine_version_actual" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_instance_engine_version_actual,null)
  }
}

output "db_instance_hosted_zone_id" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_instance_hosted_zone_id,null)
  }
}

output "db_instance_id" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_instance_id,null)
  }
}

output "db_instance_name" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_instance_name,null)
  }
}

output "db_instance_password" {
  value = { for key, val in local.config:
            key => try(random_password.rds_master_password[key].result, null)
  }
  sensitive = true
}

output "db_instance_port" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_instance_port,null)
  }
}

output "db_instance_resource_id" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_instance_resource_id,null)
  }
}

output "db_instance_status" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_instance_status,null)
  }
}

output "db_instance_username" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_instance_username,null)
  }
}

output "db_listener_endpoint" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_listener_endpoint,null)
  }
}

output "db_option_group_arn" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_option_group_arn,null)
  }
}

output "db_option_group_id" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_option_group_id,null)
  }
}

output "db_parameter_group_arn" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_parameter_group_arn,null)
  }
}

output "db_parameter_group_id" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_parameter_group_id,null)
  }
}

output "db_subnet_group_arn" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_subnet_group_arn,null)
  }
}

output "db_subnet_group_id" {
  value = { for key, val in local.config:
            key => try(module.rds[key].db_subnet_group_id,null)
  }
}

output "enhanced_monitoring_iam_role_arn" {
  value = { for key, val in local.config:
            key => try(module.rds[key].enhanced_monitoring_iam_role_arn,null)
  }
}

output "enhanced_monitoring_iam_role_name" {
  value = { for key, val in local.config:
            key => try(module.rds[key].enhanced_monitoring_iam_role_name,null)
  }
}

# VPC Security Groups
output "ingress_security_group_arn" {
  value = { for key, val in local.config:
            key => try(module.sg_ingress[key].security_group_arn,null)
  }
}

output "ingress_security_group_id" {
  value = { for key, val in local.config:
            key => try(module.sg_ingress[key].security_group_id,null)
  }
}
