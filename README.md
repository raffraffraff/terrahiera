# About
This demo codebase shows one opinionated way to configure infrastructure using Terraform and Hiera.

## main.tf
The main.tf is very simple. It uses local variables to specify specify:
 - Dependencies
 - Module inputs
 - Outputs

## _boilerplate.tf
The _boilerplate.tf will automatically:
- Fetch outputs from dependencies
- Fetch configuration from Hiera
- Write selected outputs to SSM parameter store

# How does it work?
To use this codebase (or this pattern, in your own codebase), you must follow these steps:
- Wrap complex terraform modules to accept a single JSON config (type 'any') and return a single JSON output
- Follow strict directory structure for your stacks, embedding critical context in directory names
- Define configuration at the most appropriate level in your directory structure
- Use interpolation, templating, hierarchical lookups within your YAML

The leaf directories under 'deployment' are the _stack_ directories where you run TF plans and applies. Elements of their full path relate to the deployment _context_:
- account
- region
- group (arbitrary)
- stack

You could extend this, adding other directories that have an explicit purpose (eg: owner, type, purpose etc). 

# Why do this?
- Building context into directory names
  - Eliminates the need to specify those values in code
  - Reduces number of lines of code / config
- Using deployment context in lookups 
  - returns configuration tailored to your stack
  - eliminates large .tfvars
- Interpolation, templating
   - Reduces number of lines of code
   - Eliminates resource name clashes
   - Keeps code DRY
- Minimize differences between stack deployment directories 
   - Enables cloning of stacks, regions, accounts with reduced toil
- Avoids code generators with their own language, cli and performance overhead

# Useful Side Effects
The boilerplate HCL makes use of these declarations in your `main.tf`:
```
locals {
  dependencies = {
    dns = "../dns"
    vpc = "../vpc"
  }

  outputs = [
    cluster_id,
    cluster_name,
    cluster_oidc_url
  ]
}
```

## 1. Dependency graph
One side effect is that we can grab these dependencies across our whole infrastructure project and build a Directed Acyclical Graph. I built a tool called [tforder](https://github.com/raffraffraff/tforder) that does exactly this, and can output a simpled numbered list of deployments, or create `.dot`, `.svg` or `.png` files. It can also execute commands in each deployment directory in order, with configuration parallelism. To install and test it:

```
go install github.com/raffraffraff/tforder@latest
tforder -dir deployments -recursive -out infra.dot
tforder -dir deployments -recursive -relative-to deployments -out infra.svg
```

![infra.svg](https://github.com/raffraffraff/terrahiera/blob/main/infra.svg?raw=true)

### 2. Safe, automatic state sharing
Instead of using `terraform_remote_state` (which opens up access to the entire remote state, including potentially sensitive data), our boilerplate uses AWS SSM Parameter Store to share selected outputs, which are automatically available as follows:

```
zone_id = local.dependency.dns.zone_id
vpc_id  = local.dependency.vpc.vpc_id
``` 

# Directory Structure - Naming Convention
_This_ project contains an example directory structure. (You can come up with your own, but you'll have to update the `hiera.yaml` and consider where you want to store YAML files). The root of this project contains:
- modules: wrapper modules that accept a single JSON encoded configuration
- hiera: a terraform module that accepts context (which the provider calls 'scope') and returns config
- deployments: a directory structure that encodes account, region, environment etc (see below)

## Example Deployment Directories
```
deployments
├── beta             <-- AWS account
│   ├── eu-west-2    <-- region
│   │   └── ew2a     <-- group
│   │       ├── eks  <-- stack
│   │       └── vpc
│   └── global
│       └── shared
│           └── apex_zones
└── dev
    ├── eu-west-1
    │   ├── ew1a
    │   │   ├── eks
    │   │   └── vpc
    │   └── ew1b
    │       ├── eks
    │       └── vpc
    └── global
        └── shared
            └── apex_zones

```

# Demonstration

## What we'll do
1. Clone this repo
2. Create S3 buckets to hold your TF state
3. Use tforder to figure out what order to deploy the stacks
4. Use tforder to deploy the whole infrastructure, in the correct order

## Let's go
```
git clone git@github.com:raffraffraff/terrahiera.git
cd terrahiera

go install github.com/lyraproj/hiera/lookup@latest
go install github.com/raffraffraff/tforder@latest
```

## Create S3 backend buckets. (You should do a better / secure job)
```
export COMPANY_NAME=companyname-${RANDOM}
for BUCKET in \
  ${COMPANY_NAME}-dev-global-tf-state \
  ${COMPANY_NAME}-dev-eu-west-1-tf-state
do
  aws s3api create-bucket \
  --bucket ${BUCKET} \
  --region eu-west-1 \
  --create-bucket-configuration LocationConstraint=eu-west-1
done
```

## Let's see the stack deployment order
`tforder -recursive -out infra.svg`

## YOLO 
Let's use the short flag format. We'll recursively deploy the whole shebang!
`tforder -r -d deployments -x 'tofu init && tofu apply -auto-approve'`

## Cloning deployments?
Let's clone the whole `ew1a` group to deploy in the region eu-west-1. (We'd usually have a lot more than VPC and EKS, also we could have cloned eu-west-1 to us-east-1 or whatever, it's just a demo).

```
deployments
└── dev
     └── eu-west-1    <--- go here
         └── ew1a
             ├── eks
             ├── envs
             ├── s3
             └── vpc
```

..and run:
`rsync --exclude .terraform -aP ew1a/ ew1b/`

Audit all YAML files under ew1b:
```
$ find ew1b -type f -name '*.yaml'
ew2a/vpc/config.yaml
```

Just one file, with just one change! Let's update the VPC CIDR '10.21.0.0/16' and rerun the deployment:
`tforder -r -d deployments -x 'tofu init && tofu apply -auto-approve'`
