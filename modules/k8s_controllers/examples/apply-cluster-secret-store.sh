#!/bin/bash
kubectl config use arn:aws:eks:eu-west-1:0123456789:cluster/internal-euw1
kubectl apply -n external-secrets -f manifests/ClusterSecretStore.yaml
