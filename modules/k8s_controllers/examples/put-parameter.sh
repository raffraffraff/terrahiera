#!/bin/bash
# Use --key-id, but find the id by alias first (alias/external_secrets_default)
KMS_KEY_ID=$(aws \
  --profile dev.admin \
  --region eu-west-1 \
  kms list-aliases \
  | jq -r '.Aliases[] | select(.AliasName == "alias/external_secrets_default") | .TargetKeyId'
)

aws ssm put-parameter \
  --name "/dev-ew1a/test/username" \
  --profile dev.admin \
  --region eu-west-1 \
  --type "SecureString" \
  --value "keycloak-admin" \
  --key-id "$KMS_KEY_ID" \
  --overwrite \
  --no-cli-pager

aws ssm put-parameter \
  --name "/dev-ew1a/test/password" \
  --profile dev.admin \
  --region eu-west-1 \
  --type "SecureString" \
  --value "flimdoo2000£2fa¬;oprfw" \
  --key-id "$KMS_KEY_ID" \
  --overwrite \
  --no-cli-pager

