#!/bin/bash
aws ssm get-parameters-by-path \
  --profile dev.admin \
  --region eu-west-1 \
  --path "/dev-ew1a/test/" \
  --with-decryption
