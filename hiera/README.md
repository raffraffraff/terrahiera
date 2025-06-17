# About
This implements Hiera lookups as a TF module. It accepts the Hiera context and search key, and returns the result of the lookup via an output.

This lookup scope contains _aws_account_ name, _region_, _group_ and finally _stack_ (the collection of resources you are deploying). This whole process is fully automatic, but it depends on your TF code following this directory structure:

```
  ├── dev                             < aws account name
  │   └── eu-west-1                    < region
  │       ├── ew1a                       < group
  │       │   ├── dns-zone               < stack
  │       │   ├── eks
  │       │   ├── rds
  │       │   └── vpc
  │       └── ew1b
  │           ├── database
  │           └── dns-record
  └── prod
      └── eu-west-1
          ├── ops
          │   ├── dns-zone
          │   ├── eks
          │   ├── rds
          │   └── vpc
          ├── blue
          │   ├── database
          │   └── dns-record
          └── green
              ├── database
              └── dns-record
```

# Usage
Use it like a any Terraform module: pass it variables and accept outputs from it. The variables should match the Hiera provider _scope_. The output is the configuration for that stack. The hiera provider uses the `hiera.yaml` in the root of this project to define the hierarchy of lookup paths. The default lookup key is your _stack_ name (eg: 'vpc') but you can also call this module and specify a `lookup_key` variable.

```
module "hiera" {
  source      = "../../../../../hiera"
  stack       = local.stack
  group       = local.group
  region      = local.region
  aws_account = local.aws_account
}
```

By default Hiera assumes your lookup key is the `stack`, but you can also `lookup_key` variable

## 2. Using the `lookup` cli
### Install it
`go install github.com/lyraproj/hiera/lookup@latest`

### Execute a hiera lookup
```
${GOPATH}/bin/lookup --config=hiera.yaml --merge=deep \
   --var account=dev \
   --var region=eu-west-1 \
   --var group=ew1a \
   --var stack=vpc \
   vpc.az_count
```

Other args:
* `--render-as json` is useful for piping the result into `jq`
* `--explain` helps troubleshoot unexpected output

# Deeper Dive into Hiera
Hiera is a file based key-value store that performs context-aware lookups based on facts like _environment_, _region_ etc. If it finds multiple results in different hierarchies, it will return a result based on a configurable _merge strategy_ which can be:
- first (returns highest priority value)
- hash (merges values for top-level key)
- deep (performs a recursive merge)

## How does Hiera's context-aware, hierarchical lookup work?
In order to be able to perform context-aware hierarchical lookups, we need three things:

### Search scope
Before Hiera can search for context-aware data it needs to know some _facts_ about your Terraform deployment. It parses the calling module's directory structure to figure out values for aws_account, region, environment etc, and adds them to the Hiera provider's _scope_ parameter:

```
provider "hiera5" {
  config = "./config/hiera.yaml"
  merge  = "deep"
  scope = {
    aws_account = local.aws_account
    environment = local.environment
    region      = local.region
  }
```

### Hierarchy
We need to give Hiera a _hierarchy_ of data paths to search in. This is defined in `hiera.yaml`. Defaults are applied first with low priority, and higher priority data overrides lower priority):
```
hierarchy:
  - name: Region
    path: region/%{region}.yaml

  - name: Environment
    path: environment/%{environment}.yaml

  - name: AWS Account
    path: aws_account/%{aws_account}.yaml

  - name: Defaults
    glob: defaults/*.yaml
```


### Hiera Terraform Provider
The Hiera Terraform provider exposes a _data resource_ which has the following features:
1. Returns JSON data (this module converts it tonative Terraform data using `jsondecode`)
2. Eliminates the need for templating or code-generation steps - complex data can be directly sourced during plan/apply
3. Hiera supports _internal_ interpolation, so key values can contain lookups to _other keys_ in the Hiera data
4. When values are found in multiple hierarchies, Hiera supports a configurable merge strategy, including _deep merge_ (which [Terraform does not support!](https://github.com/hashicorp/terraform/issues/24987))
