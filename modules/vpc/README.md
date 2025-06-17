# Usage
This wrapper module is intended to bridge the gap between Hiera data and the [https://github.com/terraform-aws-modules/terraform-aws-vpc](terraform-aws-vpc) module.

## Example VPC

```
vpc:
  name: "%{group}"
  az_count: 3
  cidr: "10.0.0.0/16"
  public_subnet_tags:
    "kubernetes.io/cluster/%{group}": "shared"
    "kubernetes.io/role/elb": 1
  private_subnet_tags:
    "kubernetes.io/cluster/%{group}": "shared"
    "kubernetes.io/role/internal-elb": 1
    "karpenter.sh/discovery" = "%{group}"
  manage_default_security_group: true
  default_security_group_ingress: []
  default_security_group_egress: []
  enable_nat_gateway: true
  single_nat_gateway: true
  enable_dns_hostnames: true
  enable_dns_support: true
  tags: "%{alias('tags')}"
```

In the eu-west-1 region, this configuration depdeploys the following availability zones and subnets:
```
azs:
 - eu-west-1d
 - eu-west-1c
 - eu-west-1b

private_cidr: 10.0.0.0/20
private_subnets:
 - 10.0.0.0/24
 - 10.0.1.0/24
 - 10.0.2.0/24

public_cidr: 10.0.16.0/20
public_subnets:
 - 10.0.16.0/24
 - 10.0.17.0/24
 - 10.0.18.0/24

database_cidr: 10.0.32.0/20
database_subnets:
 - 10.0.32.0/24
 - 10.0.33.0/24
 - 10.0.34.0/24

intra_cidr: 10.0.48.0/20
intra_subnets:
 - 10.0.48.0/24
 - 10.0.49.0/24
 - 10.0.50.0/24
```

