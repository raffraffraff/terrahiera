# About
This demo codebase shows one very opinionated way to deploy infrastructure using Terraform and Hiera.

The big idea:
- Wrap complex terraform modules to accept a single JSON config (type 'any') and return a single JSON output
- Follow strict directory structure for your stacks, embedding critical context in directory names
- Define blocks of configuration at the most appropriate level in your directory structure, and use interpolation and templating
- Use Hiera to perform context-aware hierarchical lookups during terraform runs, with support for deep merge
- Use boilerplate HCL to enable simple the declaration of stack dependencies and of outputs to share with other stacks
- Create final stack configuration by mixing outputs from Hiera, stack dependencies and custom values
- Write specific outputs to AWS SSM Parameter Store (so they are available to other stacks)

Each deployment directory (which I call a 'stack') is the directory where Terraform plans and applies run. The full path provides context (eg: account, region, group, stack). Since hiera lookups are context aware, and it supports YAML with interpolation and internal lookups, we can have minimal (and sometimes zero!) hard-coded values, even in TFVARS. This means that you can clone whole branches of the deployment directory tree and deploy to a different account, region or VPC with minimal changes.

## Why
- Build context into directory names to eliminate the need to ever have to specify those values in a file
- Use that context in lookups so you only get back the values that apply to your exact deployment
- Use interpolation in your YAML so you can things by convention, instead of hard-coding explicit names
- Perform deep merge so you can override only the individual values that you need to, while benefiting from hierarchical values
- Why not!

## Interesting side effects
The boilerplate HCL uses these local variables:
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

Each stack will save a subset of the wrapped module's outputs to SSM Parameter Store in an automatically derived path. This means that we can easily look up the dependencies 'vpc' and 'dns', and provide their outputs to our stack, eg:

```
vpc_id = local.dependency.vpc.vpc_id
```

This is safer than using Terraform remote state lookups, which make it necessary to expose all of the module outputs to dependents. It also reduces manual effort in writing multiple Terraform remote state lookups. But there is another interesting side effect. If we compile all of these dependencies across our stacks, we can build a Directed Acyclical Graph that shows us a dependency tree for our stack, or for the entire infrastructure. 

```
go install github.com/raffraffraff/tforder@latest
tforder -dir deployments -recursive -out infra.dot
tforder -dir deployments -recursive -out infra.svg
```

The tforder project creates visual dependency relationships between your infrastructure deployments (in much the same way that Terraform can generate a graph of dependency relationships between resources within a deployment). See the [tforder](https://github.com/raffraffraff/tforder) project for more information.

# Results
- Minimize differences between stack directories
- Reduce toil of cloning infrastructure to new AWS accounts, regions, stacks
- Eliminate resource name clashes (eg: S3 buckets, DNS records, VPC CIDRs) by with naming _patterns_ that use context variables, instead of hard coded names
- Avoid the need for tools that generate Terraform, and have their own language and tooling to run it

# Directory Naming Convention
This project contains an example directory structure. It's designed to minimize the differences between each environment, region etc. The root of this project contains:
- modules: wrapper modules that accept a single JSON encoded configuration
- hiera: a terraform module that accepts 'context' and returns 'config'
- deployments: directory structure that uses AWS account, region, environment etc (see below)

## Example Deployment Directories
```
deployments
├── dev               <--- one of many AWS accounts
│    ├── eu-west-1    <--- one of many regions
│    │   └── ew1a     <--- one of many groups
│    │       ├── eks  <--- one of many stacks
│    │       ├── envs
│    │       ├── s3
│    │       └── vpc
│    └── global       <--- kind of a region?
│        └── shared   <--- kind of a group?
│            └── apex_zones
└── beta              
    ├── eu-west-1
    │   └── ew1a
    │       ├── eks
    │       ├── envs
    │       ├── s3
    │       └── vpc
    └── us-east-1
        ...
```

# Less talk more showme
## The steps
1. Clone this repo
2. Create S3 buckets to hold your TF state
3. Run tforder to figure out what order to deploy the stacks
4. Work through the deployments in the order given, running `tofu init && tofu apply`

## Let's go
```
git clone git@github.com:raffraffraff/terrahiera.git
cd terrahiera

go install github.com/lyraproj/hiera/lookup@latest
go install github.com/raffraffraff/tforder@latest
```

# Let's see the stack deployment order
`tforder -recursive -out infra.svg`

# Create S3 backend buckets. (You should do a better / secure job)
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

## Optional: look at the hiera config for a stack
You can do this for any of your deployments. I haven't bothered putting this into a script (some day...)
```
lookup --config=hiera.yaml \
  --var aws_account=dev \
  --var region=eu-west-1 \
  --var group=ew1a \
  --var stack=eks \
  eks
```

## YOLO (following the order in infra.svg)
```
for dir in \
  deployments/dev/global/shared/apex_zones \
  deployments/dev/eu-west-1/ew1a/vpc \
  deployments/dev/eu-west-1/ew1a/eks
do
  (cd $dir && tofu init && tofu apply -auto-approve)
done
```

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

* Just one file, with just one change. Let's update the VPC CIDR '10.21.0.0/16'
* Rerun tforder
* Apply the changes in the correct order

