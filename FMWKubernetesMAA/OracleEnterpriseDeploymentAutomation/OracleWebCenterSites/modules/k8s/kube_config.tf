## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

variable "cluster_kube_config_expiration" {
  default = 2592000
}

variable "cluster_kube_config_token_version" {
  default = "2.0.0"
}

data "oci_containerengine_cluster_kube_config" "cluster_kube_config" {
  #Required
  cluster_id = oci_containerengine_cluster.cluster[0].id

  #Optional
  expiration    = var.cluster_kube_config_expiration
  token_version = var.cluster_kube_config_token_version
}

output "kube_config" {
  value = data.oci_containerengine_cluster_kube_config.cluster_kube_config.content
}