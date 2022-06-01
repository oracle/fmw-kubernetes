## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

variable "compartment_ocid" {
  default = ""
}

variable "provision_adb" {}

variable "adb_password" {}

variable "use_existing_vcn" {
  default = true
}

variable "vcn_cidr" {
  default = "10.0.0.0/16"
}

variable "vcn_id" {
  default = ""
}

variable "adb_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "adb_subnet_id" {
  default = ""
}

variable "adb_nsg_id" {
  default = ""
}

variable "adb_free_tier" {
  default = false
}

variable "adb_private_endpoint" {
  default = true
}

variable "adb_database_cpu_core_count" {
  default = 1
}

variable "adb_database_data_storage_size_in_tbs" {
  default = 1
}

variable "adb_database_db_name" {
  default = "ociadb"
}

variable "adb_database_db_version" {
  default = "19c"
}

variable "adb_database_db_workload" {
  default = "OLTP"
}

variable "adb_data_safe_status" {
  default = "NOT_REGISTERED"
}

variable "adb_database_defined_tags_value" {
  default = ""
}

variable "adb_database_display_name" {
  default = "ADB"
}

variable "adb_database_freeform_tags" {
  default = {
    "Owner" = "ADB"
  }
}

variable "adb_database_license_model" {
  default = "LICENSE_INCLUDED"
}

variable "adb_tde_wallet_zip_file" {
  default = "tde_wallet_adb1.zip"
}

variable "adb_private_endpoint_label" {
  default = "adbprivendpoint"
}

variable "whitelisted_ips" {
  default = [""]
}

variable "is_data_guard_enabled" {
  default = false
}

variable "is_auto_scaling_enabled" {
  default = false
}

variable "adb_wallet_password_specials" {
  default = true
}

variable "adb_wallet_password_length" {
  default = 16
}

variable "adb_wallet_password_min_numeric" {
  default = 2
}

variable "adb_wallet_password_override_special" {
  default = ""
}

variable "defined_tags" {
  default = {}
}
