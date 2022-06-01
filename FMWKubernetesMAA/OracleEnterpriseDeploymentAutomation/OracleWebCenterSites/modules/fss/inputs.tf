## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

variable "subnet_id" {}
variable "compartment_ocid" {}
variable "ad_number" {
  default = 2
}
variable "encryption_key_id" {
  default = null
}
variable "mount_path" {}
variable "source_cidr" {}
variable "provision_filesystem" {}
variable "provision_mount_target" {}
variable "provision_export" {}
variable "filesystem_ocid" {}
variable "mount_target_ocid" {}
variable "server_ip" {}
