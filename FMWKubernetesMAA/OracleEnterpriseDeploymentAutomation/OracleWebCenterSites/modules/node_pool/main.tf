## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

resource "oci_containerengine_node_pool" "node_pool" {
  count = var.provision_node_pool ? length(var.node_pools) : 0

  #Required
  cluster_id         = var.cluster_id
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.kubernetes_version
  name               = var.node_pools[count.index]["pool_name"]
  node_shape         = var.node_pools[count.index]["node_shape"]

  #Optional
  dynamic "initial_node_labels" {
    for_each = var.node_pools[count.index]["node_labels"]
    content {
      key   = initial_node_labels.key
      value = initial_node_labels.value
    }
  }

  node_source_details {
    #Required
    image_id    = local.node_pool_images[count.index].0.image_id
    source_type = local.node_pool_images[count.index].0.source_type
  }

  node_config_details {
    dynamic "placement_configs" {
      for_each = [for ad in data.oci_identity_availability_domains.ads.availability_domains : {
        name = ad.name
      }]
      content {
        subnet_id           = var.nodes_subnet_id
        availability_domain = placement_configs.value.name
      }
    }
    size = var.node_pools[count.index]["node_count"]
  }
  ssh_public_key = var.ssh_authorized_key

  provisioner "local-exec" {
    command = "sleep 5"
    when    = destroy
  }
}


