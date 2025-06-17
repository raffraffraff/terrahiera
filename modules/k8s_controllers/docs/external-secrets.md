# What?
External Secrets Operator can sync secrets from secrets stores (like AWS Secrets Manager or Parameter Store) to the Kubernetes secret store

# Why?
It avoids the need to locally encrypt secrets using blackbox or sealed secrets. This avoids the possibility of accidentally pushing unencrypted secrest to git. It also keeps secrets out of the Terraform state, which are visible in the `terraform state pull` command output.

# How?
## The Operator
First, you install the External Secrets Operator and annotate its service account with a role that gives it access to the secret backend. That's what _this_ module does. 

## The Secret Configurations
Before ESO will sync secrets to your cluster namespaces you need apply additional Kubernetes manifests to configure ESO. There are some options, but the simplest method appears to be:

1. Deploy a ClusterSecretStore
A ClusterSecretStore runs inside the Kubernetes cluster and performs secret sync with a backend. It can sync secrets to any namespace. It's usually deployed to the namespace that ESO is in (eg: `external-secrets`

```
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: awsps-secret-store
spec:
  provider:
    aws:
      service: ParameterStore
      region: eu-west-1
      auth:
        jwt:                               # IRSA method
          serviceAccountRef:
            name: my-service-account
            namespace: my-namespace
```

2. Deploy an ExternalSecret
An ExternalSecret tells the ClusterSecretStore _what to sync_, and _what to call the secrets_. It is deployed to the namespace that you want to sync the secret to. 

```
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-secrets
spec:
  backendType: systemManager
  secretStoreRef:                          # optional, if there is only one?
    name: aws-ssm-parameter-store
    kind: SecretStore
  data:
    key: /secrets/clustername/namespace/service/secretname
    name: password
```

Insteald of using `data:` to sync one secret, you can use `dataFrom` to sync all values from the path:

```
  dataFrom:
  - extract:
      key: /secrets/clustername/namespace/
```

But I don't know if that works with Parameter Store. There's a totally different example given [here](https://github.com/DNXLabs/terraform-aws-eks-external-secrets#aws-ssm-parameter-store), where they don't use `dataFrom`, and make the distinction between a single secret or scraping values from a path (with the option for recursively doing it)..


```
apiVersion: kubernetes-client.io/v1
kind: ExternalSecret
metadata:
  name: my-secret
spec:
  backendType: systemManager
  data:
    - path: /internal-euw1/test/
      recursive: false
```

Q: If you want multiple k8s secrets, do you need multiple ExternalSecrets?
Q: How do recursive scrapes populate the secrets?
Q: How do `path:` secrets get populated? Into separate secrets, or as a secret with multiple values?

NOTE: You don't need to provide a roleArn with ExternalSecret, but you _can_. I don't understand why you can give a role / service account to the ESO, the ClusterSecretStore and the ExternalSecret... 

NOTE: You can provide other optional parameters to the ExternalSecret, like region, scrape interval, role etc. We probably don't have to do this, unless we deploy to multiple regions and need to keep our secrets in a central region. I'd prefer not to do that though!
