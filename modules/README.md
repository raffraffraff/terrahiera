# Guide
Each module in this directory generally follows this pattern:
1. Has a *single* variable that parses JSON-encoded string into a map of data
3. Iterates over the data to invoke resources or modules

Many of the modules are simply _wrappers_ around a single, complex 3rd party module.

# Auto-generating a wrapper
If you wish to simply wrap an existing 3rd party module, the `./generate_wrapper.sh` script in this directory will automatically create a wrapper module for you:

```
$ ./generate_wrapper.sh \
  --name vpc \
  --url https://github.com/terraform-aws-modules/terraform-aws-vpc \
  > vpc/main.tf

$ cat vpc/main.tf
```

Generally, you'll get a fully working wrapper module. However, you may want to do some data reformatting using `locals`, or you might wish to set a default value where none is present. A typical reason to do this can be explained with the following example YAML:

```
things:
  thing1:
    foo: bar
    var: val
    this: that
```

When a module takes `things` as its `var.config`, and iterates over it, the `for_each` will end up with:
```
each.key: thing1
each.value.foo: bar
each.value.var: val
each.value.this: that
```

If the module you are invoking has a field called "name", you might wish to pass `each.key` to it instead of `each.value.name`. 

## Modifying the wrapper
There are times when you might want to modify the wrapper. For example, in the case of a VPC, you might want to fetch AWS data about availability zones in the region, and use that with the `slice()` function and the number of required AZs to selec the ones you want to use. Or you could use `cidrsubnet()` to automatically split up your VPC CIDR into a number of subnets, instead of passing them in the config data.

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
