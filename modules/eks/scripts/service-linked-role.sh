#!/bin/bash

# PURPOSE:
# When deploying to any AWS account for the first time, there will be
# missing service linked roles. Since it is probably the you will deploy
# multiple EKS clusters to a single AWS account, and you cannot deploy
# a service linked role multiple times, we are left with a nasty situation:
#
# 1. We cannot always deploy the service linked role
# 2. If we do not, then the creation of a KMS key policy fails with a 'weird' message
# 3. If we add the service linked role to the EKS module and import it, destruction of a cluster would destroy the role
#
# Nobody seems to have a great solution for it, so this hack exists instead.
# Briefly, this script will create the service linked role if it does not exist.
# It will exit without error if the role does exist.
#

aws iam create-service-linked-role \
  --aws-service-name autoscaling.amazonaws.com \
  --no-cli-pager >/dev/null 2>&1 || exit 0
