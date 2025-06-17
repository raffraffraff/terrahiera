locals {
  output = merge(module.eks, {
            # if you add resources along with the wrapped module, put their
            # outputs here
           })
}

output "output" {
  value = local.output
}
