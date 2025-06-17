# Stupid simple Helm chart installer
The goal of this module is to allow Kubernetes admins to define a helm_release
in yaml (ie: hiera) that gives Terraform a list of helm charts to install, with
configuration options.

## Parameters
* `name` - release name (defaults to helm chart '${key}')
* `namespace` - namespace to install the chart into (defaults to "default")
* `create_namespace` - creates the namespace if it does not exist (defaults to `false`)
* `chart` - chart to be installed (defaults to `stable/${key}`)
* `repository` - optional repository URL for the chart
* `wait` - wait for all resources to be be in a ready state (defaults to `true`)
* `timeout` - how many seconds to wait for resources to be ready (defaults to `300`)
* `set` - block of keys/values to be merged with `values.yaml`
* `set_sensitive` - block of sensitive keys/values to be merged with `values.yaml`
* `values` - inline `values.yaml`

## Defaults
By default, if you do not provide a "name" or "chart", these will be assumed from
the helm_chart's key. In the following example, `name` defaults to "mychart"
and `chart` defaults to "stable/mychart":
```
helm_charts:
  mychart:
    namespace: myapp
```

## Helm `--set`
You can provide `--set`-compatible overrides in your Hiera chart definition yaml
by adding `set:` or `set_sensitive:` data:

```
helm_releases:
  prometheus-operator:
    namespace: metrics
    create_namespace: true
    set_sensitive:
      grafana.adminPassword: "flimdoo"
    set:
      grafana.ingress.enabled: false
```

In this situation, the Terraform plan output will hide the Grafana adminPassword:
```
      + set {
          + name  = "grafana.ingress.enabled"
          + value = "false"
        }

      + set_sensitive {
          + name  = "grafana.adminPassword"
          + value = (sensitive value)
        }
```

## Helm `values.yaml`
You can provide the contents of a `values.yaml` file directly in the Helm chart
definition, as seen in the following example:
```
helm_releases:
  prometheus-operator:
    namespace: metrics
    create_namespace: true
    values:
      prometheusOperator:
        service:
          loadBalancerSourceRanges:  "%{alias('cloudflare_ip_ranges')}"
```

## Issues

### No support `values.yaml` _files_
Right now we do not support yaml files, you must provide overrides via the values
key, or using `set` / `set_sensitive`

### No templating
Since we are using Hiera as a data source, most of the values that we would end up
interpolating into a template are already defined in Hiera, with the exception of
data from module outputs or from data sources. In the cases where data is available
in Hiera already, templating is irrelevant, since it's easier to use Hiera's built
-in `%{lookup()}` and `%{alias()}` functions.

Furthermore, attempting to use Terraform's templating engine to get around this issue
is not simple. Terraform templating is in flux (changing from a data source to a
function in 0.12) and does not appear to support the use of a "heredoc" as a template
file. But ultimately, if the template needs to interpolate variable data that is not
available in Hiera, then how do we provide it if we define our charts in Hiera?

## Future Changes

### Using Terraform data _in Hiera_?
It is possible to add a plugin to Hiera that can fetch data from Terraform. Barring
circular dependencies, it could be possible to implement this plugin in our Hiera
plugin and use it to reference existing Terraform data for use in our Helm chart YAML.
For example, instead of adding a static list of Cloudflare's IP addresses, we could
use the official Cloudflare data source:
```
helm_charts:
  grafana:
    name: grafana
    namespace: monitoring
    chart: stable/grafana
    set:
      service:
        type: LoadBalancer
        loadBalancerSourceRanges: "%{lookup('terraform.data.cloudflare.ipv4_ranges')}"
```

The major caveats to this work are:
* Is the Hiera terraform plugin stable, and actively developed?
* Does it work with the Terraform Hiera 5 provider? (The provider is based on the Lyra Hiera5 in Go, so it should)
* The data source is the Terraform backend (in S3) so it will be 'one step behind' current Terraform apply

Reference: https://github.com/lyraproj/hiera_terraform

