## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

terraform {
  required_version = ">= 0.14.0"
  required_providers {
    oci = {
      version = ">= 4.27.0"
    }
  }
}

provider "oci" {
  region               = var.region
  disable_auto_retries = "true"
  config_file_profile = "DEFAULT"
}
