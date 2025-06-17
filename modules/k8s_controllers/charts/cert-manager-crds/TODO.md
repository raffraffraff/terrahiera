- Update the Chart.yaml version to match the cert-manager version it supports
- Create a simple script to curl the correct CRD version
  eg: https://github.com/cert-manager/cert-manager/releases/download/v1.12.13/cert-manager.crds.yaml

[alternatively download all of them? we could pass a version number and have
this chart install the CRDs depending on the version?]
