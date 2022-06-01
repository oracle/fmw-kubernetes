## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

data "oci_containerengine_node_pool_option" "node_pool_options" {
  node_pool_option_id = var.cluster_id
}

data "oci_core_images" "compatible_images" {
  count          = length(var.node_pools)
  compartment_id = var.compartment_ocid
  shape          = var.node_pools[count.index].node_shape
  state          = "AVAILABLE"
  sort_by        = "TIMECREATED"
  sort_order     = "DESC"
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

locals {
  node_pool_images = [for i in data.oci_core_images.compatible_images[*].images[*].id : [for x in data.oci_containerengine_node_pool_option.node_pool_options.sources : x if contains(i, x.image_id)]]
}

output "images" {
  value = data.oci_core_images.compatible_images[*].images[*].id
}