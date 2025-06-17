#!/bin/bash
kubectl config use arn:aws:eks:eu-west-1:01234567890:cluster/internal-euw1
kubectl delete -n external-secrets -f manifests/ClusterSecretStore.yaml
