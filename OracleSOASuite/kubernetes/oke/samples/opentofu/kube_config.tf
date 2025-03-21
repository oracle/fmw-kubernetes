/*
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

variable "cluster_kube_config_expiration" {
  default = 2592000
}

variable "cluster_kube_config_token_version" {
  default = "2.0.0"
}

data "oci_containerengine_cluster_kube_config" "fmw_cluster_kube_config" {
  #Required
  cluster_id = oci_containerengine_cluster.fmw_cluster.id
}

resource "local_file" "fmw_cluster_kube_config_file" {
  content  = data.oci_containerengine_cluster_kube_config.fmw_cluster_kube_config.content
  filename = "${path.module}/${var.cluster_name}_kubeconfig"
}

