#!/bin/bash
kubectl config use arn:aws:eks:eu-west-1:01234567890:cluster/internal-euw1
kubectl apply -n test -f manifests/ExternalSecret1.yaml
kubectl apply -n test -f manifests/ExternalSecret2.yaml
