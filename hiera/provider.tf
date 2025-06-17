terraform {
  required_providers {
    hiera5 = {
      source = "chriskuchin/hiera5"  # yo bud, nice provider there
    }
  }
}

provider "hiera5" {
  config = join("/", [ dirname(abspath(path.module)), "hiera.yaml" ])
  scope = local.scope
}
