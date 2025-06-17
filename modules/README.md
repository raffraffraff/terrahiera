# Guide
Each module in this directory generally follows this pattern:
1. Has a *single* variable that parses JSON-encoded string into a map of data
3. Iterates over the data to invoke resources or modules

Many of the modules are simply _wrappers_ around a single, complex 3rd party module.

# Auto-generating a wrapper
If you wish to simply wrap an existing 3rd party module, the `./generate_wrapper.sh` script in this directory will automatically create a wrapper module for you. Warning, it's hacky A.F. but works for stuff like:

```
$ ./generate_wrapper.sh \
  --name vpc \
  --url https://github.com/terraform-aws-modules/terraform-aws-vpc \
  > vpc/main.tf

$ cat vpc/main.tf
```

Generally, you'll get a fully working wrapper module. 

# Modifying the wrapper
You may wish to make some overrides or modifications to the wrapper. A very contribed reason to do this can be explained with the following example YAML:

```
s3_buckets:
  bucket1:
    name: bucket1
  bucket2:
    name: bucket2
```

If your wrapper iterates over data using `for_each` it might end up with this:
```
each.key: bucket1
each.value.name: bucket1

each.key: bucket2
each.value.name: bucket2
```

So you might want to set the default value of `name` to `each.key` instead of `each.value.name`

Another example might be a VPC module: maybe you want to fetch data about _availabile_ AZs in a region, and use a `slice()` function with the number number of AZs required. Or if your VPC subnets are generally the same across all deployments, you might want to use `cidrsubnet()` in the module to split your VPC CIDR, instead of doing it in your stack, and passing a bunch of subnet CIDRs to the module every time.

## Example usage
```
./generate_wrapper.sh --name github_organization --url https://github.com/mineiros-io/terraform-github-organization

module "github_org" {

  source  = "mineiros-io/organization/github"
  version = "~> 0.9.0"

  for_each = try(local.config,{}) 

    all_members_team_name        =  try(each.value.all_members_team_name,null)            #type=string
    all_members_team_visibility  =  try(each.value.all_members_team_visibility,"secret")  #type=string
    catch_non_existing_members   =  try(each.value.catch_non_existing_members,false)      #type=bool
    blocked_users                =  try(each.value.blocked_users,[])                      #type=set(string)
    members                      =  try(each.value.members,[])                            #type=set(string)
    admins                       =  try(each.value.admins,[])                             #type=set(string)
    projects                     =  try(each.value.projects,[])                           #type=any
    settings                     =  try(each.value.settings,{})                           #type=any

}

variable "config" {
  type        = any
  description = "A JSON encoded object that contains the full github_organization config"
  default     = "{}"
}

output "output" {
  value = { for k, v in local.config:
    k => {
      out1 = module.github_org[k].out1
    }
  }
```
