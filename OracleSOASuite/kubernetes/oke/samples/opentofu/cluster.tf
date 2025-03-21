/*
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/
variable "cluster_kubernetes_version" {
  default = "v1.29.1"
}

variable "cluster_name" {
  default = "fmwCluster"
}

variable "cluster_options_add_ons_is_kubernetes_dashboard_enabled" {
  default = true
}

variable "cluster_options_add_ons_is_tiller_enabled" {
  default = true
}

variable "cluster_options_kubernetes_network_config_pods_cidr" {
  default = "10.1.0.0/16"
}

variable "cluster_options_kubernetes_network_config_services_cidr" {
  default = "10.2.0.0/16"
}

variable "node_pool_initial_node_labels_key" {
  default = "key"
}

variable "node_pool_initial_node_labels_value" {
  default = "value"
}

variable "node_pool_kubernetes_version" {
  default = "v1.29.1"
}

variable "node_pool_name" {
  default = "fmwCluster_workers"
}

variable "node_pool_node_image_name" {
  default = "Oracle-Linux-8"
}

variable "node_pool_node_shape" {
  default = "VM.Standard2.1"
}

variable "node_pool_quantity_per_subnet" {
  default = 2
}

variable "node_pool_ssh_public_key" {
}

data "oci_identity_availability_domains" "fmw_availability_domains" {
  compartment_id = var.compartment_ocid
}

resource "oci_containerengine_cluster" "fmw_cluster" {
  #Required
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.cluster_kubernetes_version
  name               = var.cluster_name
  vcn_id             = oci_core_virtual_network.oke-vcn.id

  #Optional
  options {
    service_lb_subnet_ids = [oci_core_subnet.oke-subnet-loadbalancer-1.id, oci_core_subnet.oke-subnet-loadbalancer-2.id]

    #Optional
    add_ons {
      #Optional
      is_kubernetes_dashboard_enabled = var.cluster_options_add_ons_is_kubernetes_dashboard_enabled
      is_tiller_enabled               = var.cluster_options_add_ons_is_tiller_enabled
    }
  }
}


output "cluster_id" {
  value = oci_containerengine_cluster.fmw_cluster.id
}

