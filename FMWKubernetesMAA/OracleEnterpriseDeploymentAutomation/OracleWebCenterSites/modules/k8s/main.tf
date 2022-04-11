## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

# Cluster dynamic group needed for nodes to apply the key access policy if it was defined.
resource "oci_identity_dynamic_group" "cluster_dynamic_group" {
  count = var.secrets_encryption_key_ocid == null ? 0 : 1
  #Required
  compartment_id = var.tenancy_ocid
  description    = "OKE Clusters"
  matching_rule  = "ALL {resource.type = 'cluster', resource.compartment.id = '${var.compartment_ocid}'}"
  name           = "oke_${md5(var.compartment_ocid)}"
}

# Cluster dynamic group policy needed for nodes to access the encryption key if it was defined
resource "oci_identity_policy" "k8s_secrets_policy" {
  count      = var.secrets_encryption_key_ocid == null ? 0 : 1
  depends_on = [oci_identity_dynamic_group.cluster_dynamic_group]
  #Required
  compartment_id = var.tenancy_ocid
  description    = "OKE Secrets encryption policies"
  name           = "OKE_Secrets"
  statements = [
    "Allow dynamic-group oke_${md5(var.compartment_ocid)} to use keys in tenancy where target.key.id = '${var.secrets_encryption_key_ocid}'",
    "Allow service oke to use keys in tenancy where target.key.id = '${var.secrets_encryption_key_ocid}'"
  ]
}


resource "oci_containerengine_cluster" "cluster" {
  count = var.provision_cluster ? 1 : 0

  depends_on = [oci_identity_policy.k8s_secrets_policy]
  #Required
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.oke_cluster["k8s_version"]
  name               = var.cluster_name
  vcn_id             = var.vcn_id
  kms_key_id         = var.secrets_encryption_key_ocid

  #Optional
  options {
    service_lb_subnet_ids = var.cluster_lb_subnet_ids

    #Optional
    add_ons {
      #Optional
      is_kubernetes_dashboard_enabled = var.cluster_options_add_ons_is_kubernetes_dashboard_enabled
      is_tiller_enabled               = var.cluster_options_add_ons_is_tiller_enabled
    }

    kubernetes_network_config {
      #Optional
      pods_cidr     = var.oke_cluster["pods_cidr"]
      services_cidr = var.oke_cluster["services_cidr"]
    }
  }
}
