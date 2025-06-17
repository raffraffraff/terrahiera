# EBS KMS key
## Problem: Cannot create KMS key because policy has an invalid principal
When you deploy the EKS module with a node group that uses encrypted EBS volumes, you may encounter this error:
```
│ Error: creating KMS Key: MalformedPolicyDocumentException: Policy contains a statement with one or more invalid principals.
│
│   with module.eks.module.ebs_kms_key.aws_kms_key.this[0],
│   on .terraform/modules/eks.ebs_kms_key/main.tf line 8, in resource "aws_kms_key" "this":
│    8: resource "aws_kms_key" "this" {
```

This failure prevents Terraform from deploying EKS managed node groups with encrypted EBS volumes.

## Cause: AWSServiceRoleForAutoScaling service-linked role does not exist! 
When you create an AWS account, it won't have any service-linked roles. These are created automatically when you take certain actions. In this case, the AWSServiceRoleForAutoScaling service-linked role gets created automatically when you create your first Auto Scaling Group. Otherwise, you must create the role yourself


## Solution: Create the service-linked role
```
aws \
  iam create-service-linked-role \
 --aws-service-name autoscaling.amazonaws.com
```
