## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "region" {}
variable "ssh_authorized_key" {}

## General inputs

variable "deployment_name" {
  default = "sites-k8s"
}


## Selector to define what to provision
variable "provision_cluster" {
  default = true
}
variable "provision_filesystem" {
  default = true
}
variable "provision_mount_target" {
  default = true
}
variable "provision_export" {
  default = true
}
variable "provision_database" {
  default = true
}
variable "provision_weblogic_operator" {
  default = true
}
variable "provision_traefik" {
  default = true
}
variable "provision_secrets" {
  default = true
}
variable "provision_sites" {
  default = true
}


## File Storage details
# If file storage is provisioned by this template but the VCN is not, the subnet ocid is required.
variable "fss_subnet_id" {
  default = null
}
# If the cluster is not provisioned by this template, the fss_source_cidr must be specified.
variable "fss_source_cidr" {
  default = "0.0.0.0/0"
}
variable "ad_number" {
  default = 2
}

variable "mount_path" {
  default = "/scratch/K8SVolume/WCSites"
}
variable "mount_target_ip" {
  default = null
}

variable "filesystem_ocid" {
  default = null
}

variable "mount_target_ocid" {
  default = null
}

## Kubernetes Namespaces to use
variable "sites_kubernetes_namespace" {
  default = "wcsites-ns"
}
variable "weblogic_operator_namespace" {
  default = "operator-ns"
}
variable "ingress_controller_namespace" {
  default = "traefik"
}

## Credentials for Oracle Container Registry
variable "container_registry_email" {}
variable "container_registry_password" {}
variable "container_registry_username" {}
variable "container_registry" {}
variable "container_registry_image" {}


## Sites domain details

variable "sites_domain_name" {
    type      = string
    default = "wcsitesinfra"
}
variable "sites_domain_type" {
    type      = string
    default = "wcsites"
}

variable "sites_domain_admin_username" {}
variable "sites_domain_admin_password" {
  type      = string
  sensitive = true
}
## Schema Database details
variable "jdbc_connection_url" {
  # if provisioned by this template, this should be null, otherwise provide for externally provisioned database
  default = null
}

variable "db_sys_password" {
  type      = string
  sensitive = true
}

variable "db_sys_username" {
  type      = string
  default = "sys"
}

variable "rcu_prefix" {
  default = "Sites"
}
variable "rcu_username" {
  default = "sys"
}
variable "rcu_password" {
  type      = string
  sensitive = true
}
## Autonomous database related variables
variable "provision_adb" {
  default = false
}

variable "adb_database_db_workload" {
  default = "OLTP"
}

variable "adb_password" {}
variable "adb_username" {
  default = "Admin"
}

## Database provisioning details
variable "database_name" {}
variable "database_unique_name" {}
variable "db_version" {
  default = "19.0.0.0"
}
variable "pdb_name" {
  default = "pdb"
}
variable "db_system_shape" {
  default = "VM.Standard2.1"
}
variable "db_system_cpu_core_count" {
  default = 1
}
variable "db_system_license_model" {
  default = "LICENSE_INCLUDED"
}
variable "db_system_db_system_options_storage_management" {
  default = "LVM"
}

## Domain name
variable "sites_dns_name" {
    type      = string
    default   = null
}

## VCN details
variable "vcn_cidr" {
  default = "10.0.0.0/16"
}

## OKE cluster details
variable "oke_cluster" {
  default = {
    k8s_version                                             = "v1.20.8"
    pods_cidr                                               = "10.1.0.0/16"
    services_cidr                                           = "10.2.0.0/16"
    cluster_options_add_ons_is_kubernetes_dashboard_enabled = true
    cluster_options_add_ons_is_tiller_enabled               = true
  }
}

variable "node_pools" {
  default = [
    {
      pool_name  = "pool1"
      node_shape = "VM.Standard2.4"
      node_count = 3
      node_labels = {
        "pool_name" = "pool1"
      }
    }
  ]
}

## Optional KMS Key for encrypting File system and Kubernetes secrets at rest
variable "secrets_encryption_key_ocid" {
  default = null
}
