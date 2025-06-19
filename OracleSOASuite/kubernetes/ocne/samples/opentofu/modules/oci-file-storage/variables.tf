# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

variable "availability_domain" {
  description = "The availability domain for the resources."
  type        = string
}

variable "compartment_ocid" {
  description = "The OCID of the compartment."
  type        = string
}

variable "subnet_id" {
  description = "The OCID of the subnet."
  type        = string
}

variable "cluster_name" {
  description = "The cluster name for naming resources."
  type        = string
}

variable "export_path1" {
  description = "The export path for the file system."
  type        = string
  default     = "/fmw1"
}

variable "export_path2" {
  description = "The export path for the file system."
  type        = string
  default     = "/fmw2"
}
