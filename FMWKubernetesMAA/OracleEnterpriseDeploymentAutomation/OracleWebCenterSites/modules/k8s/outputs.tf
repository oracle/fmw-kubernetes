## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

output "cluster" {
  value = var.provision_cluster ? {
    id                 = oci_containerengine_cluster.cluster[0].id
    kubernetes_version = oci_containerengine_cluster.cluster[0].kubernetes_version
    name               = oci_containerengine_cluster.cluster[0].name
  } : {}
}
