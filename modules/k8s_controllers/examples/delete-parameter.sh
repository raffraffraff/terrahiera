#!/bin/bash
aws ssm delete-parameter \
  --profile dev.admin \
  --region eu-west-1 \
  --name "/dev-ew1a/test/username" \

aws ssm delete-parameter \
  --profile dev.admin \
  --region eu-west-1 \
  --name "/dev-ew1a/test/password" \
