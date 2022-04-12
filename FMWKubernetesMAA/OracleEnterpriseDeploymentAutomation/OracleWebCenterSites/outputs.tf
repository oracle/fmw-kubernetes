## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

output "kube_config" {
  value = module.cluster.kube_config
}

# output "images" {
#   value = module.node_pools.images
# }

output "jdbc_connection_url" {
  value = module.database.jdbc_connection_url
}

output "nfs_server_ip" {
  value = module.fss.server_ip
}

output "nfs_path" {
  value = module.fss.path
}


resource "local_file" "helm_values" {
  filename = "./fromtf.auto.yaml"
  content = templatefile("./templates/helm.values.tpl", {
    sites_domain_name        = var.sites_domain_name
    sites_domain_type        = var.sites_domain_type
    sites_domain_secret      = "${var.sites_domain_name}-domain-credentials"
    rcu_prefix               = var.rcu_prefix
    rcu_secret               = "${var.sites_domain_name}-rcu-credentials"
    db_secret                = "${var.sites_domain_name}-db-credentials"
    jdbc_connection_url      = var.jdbc_connection_url != null ? var.jdbc_connection_url : module.database.jdbc_connection_url
    nfs_server_ip            = module.fss.server_ip
    path                     = module.fss.path
    sites_dns_name           = var.sites_dns_name
    container_registry_image = var.container_registry_image
  })
}
