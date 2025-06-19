# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

data "oci_core_instance_pool_instances" "pool_instances" {
  compartment_id   = var.compartment_id
  instance_pool_id = oci_core_instance_pool.instance_pool.id
}

data "oci_core_instance" "instances" {
  count       = var.pool_size
  instance_id = data.oci_core_instance_pool_instances.pool_instances.instances[count.index].id
}
