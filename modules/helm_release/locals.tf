locals {

  # This should receive a single variable called "config" that comes from the hiera
  # key "helm_releases", which might look something like this:
  #
  # helm_releases:
  #   my-release:
  #     chart: stable/my-app
  #     namespace: iam
  #     version: 1.2.3
  #     repository: codecentric 
  #
  # While we could easily send it a whole bunch of charts, do we want to do that?
  # Or do we want to invoke each chart with a separate `module "helm_chart" "this" {`?
  # The difference is that with the latter, we pass _one_ chart + config and get back
  # _one_ output. 
  manifests        = jsondecode(var.config)

  helm_releases    = { for release_name, params in local.manifests :
                       release_name => {
                         "name"                  = try(params.name, release_name)
                         "chart"                 = params.chart
                         "repository"            = try(params.repository,"")
                         "repository_key_file"   = try(params.repository_key_file,"")
                         "repository_cert_file"  = try(params.repository_cert_file,"")
                         "repository_ca_file"    = try(params.repository_ca_file,"")
                         "repository_username"   = try(params.repository_username,"")
                         "repository_password"   = try(params.repository_password,"")
                         "version"               = try(params.version,"")
                         "namespace"             = try(params.namespace,"default")
                         "verify"                = try(params.verify, false)
                         "keyring"               = try(params.keyring, null)
                         "timeout"               = try(params.timeout,300)
                         "disable_webhooks"      = try(params.disable_webhooks, false)
                         "reuse_values"          = try(params.reuse_values, false)
                         "reset_values"          = try(params.reset_values, false)
			 "force_update"          = try(params.force_update, false)
                         "recreate_pods"         = try(params.recreate_pods, false)
                         "cleanup_on_fail"       = try(params.cleanup_on_fail, false)
                         "max_history"           = try(params.max_history, 0)
                         "atomic"                = try(params.atomic, false)
                         "skip_crds"             = try(params.skip_crds, false)
                         "render_subchart_notes" = try(params.render_subchart_notes, true)
                         "wait"                  = try(params.wait, true)
                         "wait_for_jobs"         = try(params.wait_for_jobs, false)
                         "values"                = [ try(yamlencode(params.values),"") ]
                         "set"                   = try(params.set, [])
                         "set_sensitive"         = try(params.set_sensitive, [])
                         "dependency_update      = try(params.dependency_update, false)
                         "lint"                  = try(params.lint, false)
                         "create_namespace"      = try(params.create_namespace, false)
                       } if try(params.enable, false)
                    } 

  outputs           = { for chart, params in local.manifests :
                       chart => {
                         "install" = join("/", [
                                                 try(params["namespace"],"default"),
                                                 try(params["name"],chart)
                                               ])
                         "chart"   = join("/", [
                                                 try(params["repository"],""),
                                                 try(params["chart"],"stable/${chart}")
                                               ])
                       } if try(params.enable, false)
                    }
}
