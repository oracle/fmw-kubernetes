# oci-adb

These is Terraform module that deploys [Autonomous Database (ADB)](https://docs.oracle.com/en-us/iaas/Content/Database/Concepts/adboverview.htm) on [Oracle Cloud Infrastructure (OCI)](https://cloud.oracle.com/en_US/cloud-infrastructure).

## About
Oracle Cloud Infrastructure's Autonomous Database is a fully managed, preconfigured database environment with four workload types available, which are: Autonomous Transaction Processing, Autonomous Data Warehouse, Oracle APEX Application Development, and Autonomous JSON Database. 

## Prerequisites
1. Download and install Terraform (v1.0 or later)
2. Download and install the OCI Terraform Provider (v4.4.0 or later)
3. Export OCI credentials. (this refer to the https://github.com/oracle/terraform-provider-oci )


## What's a Module?
A Module is a canonical, reusable, best-practices definition for how to run a single piece of infrastructure, such as a database or server cluster. Each Module is created using Terraform, and includes automated tests, examples, and documentation. It is maintained both by the open source community and companies that provide commercial support.
Instead of figuring out the details of how to run a piece of infrastructure from scratch, you can reuse existing code that has been proven in production. And instead of maintaining all that infrastructure code yourself, you can leverage the work of the Module community to pick up infrastructure improvements through a version number bump.

## How to use this Module
This Module has the following folder structure:
* [root](): This folder contains a root module.
* [examples](examples): This folder contains examples of how to use the module:
  - [Fully Private ADB + network deployed by module](examples/adb-fully-private-no-existing-network): This is an example of how to use the oci-adb module to deploy Autonomous Transation Processing Database (ATP) with Private Endpoint support with network cloud infrastrucutre elements deployed within the body of the module.
  - [Fully Private ADB + custom network injected into module](examples/adb-fully-private-use-existing-network): This is an example of how to use the oci-adb module to deploy Autonomous Data Warehouse Database (ADW) with Private Endpoint support but network cloud infrastrucutre elements will be injected into the module.
  - [Fully Public ADB](examples/adb-fully-public): This is an example of how to use the oci-adb module to deploy Autonomous JSON Database (AJD) without Private Endpoint support (exposed to the public Internet).

To deploy OKE using this Module with minimal effort use this:

```hcl
module "oci-adb" {
  source                    = "github.com/oci-quickstart/oci-adb"
  compartment_ocid          = var.compartment_ocid
  adb_password              = var.adb_password
  adb_database_db_workload  = var.adb_database_db_workload
  use_existing_vcn          = true
  vcn                       = var.vcn_id
  adb_subnet_id             = var.adb_subnet_id
}

```

Argument | Description
--- | ---
compartment_ocid | Compartment's OCID where OKE will be created
use_existing_vcn | If you want to inject already exisitng VCN then you need to set the value to TRUE.
vcn_cidr | If use_existing_vcn is set to FALSE then you can define VCN CIDR block and then it will used to create VCN within the module.
vcn_id | If use_existing_vcn is set to TRUE then you can pass VCN OCID and module will use it to create Private Endpoint for ADB.
node_subnet_id | If use_existing_vcn is set to TRUE then you can pass Subnet OCID and module will use it to nest ADB with Private Endpoint.
adb_subnet_cidr | If use_existing_vcn is set to FALSE then you can define ADB Subnet CIDR block and then it will used to nest ADB with Private Endpoint.
adb_nsg_id | If use_existing_vcn is set to TRUE then you can pass Network Security Group OCID and module will use it to nest ADB with Private Endpoint.
adb_free_tier | If you want to use Free Tier then you need to set the value to TRUE.
adb_private_endpoint | If you want to use Autonomous Database Private Endpoint then you need to set the value to TRUE (default value).
whitelisted_ips | If adb_private_endpoint is set to FALSE then you can define whitelisted IP Addresses in the Internet to access publicly exposed Autonomous Database.
is_data_guard_enabled | Enanle or disable ADB Data Guard
is_auto_scaling_enabled | Enable or disable ADB Autoscaling.
adb_private_endpoint_label | If adb_private_endpoint is set to TRUE then you can define Private Endpoint Label.
adb_database_cpu_core_count | Define how many OCPUs shoule be used by Autonomous Database
adb_database_data_storage_size_in_tbs | Define in terabytes what will be the size of Autonomous Database
adb_database_display_name | Define the database display name of your Autonomous Database
adb_database_db_name | Define the database name of your Autonomous Database
adb_database_db_version | Define the version of your Autonomous Database
adb_db_workload | Define the workload type of your Autonomous Database: {OLTP, DW, AJD, APEX}
adb_database_license_model | Define the license model for your Autonomous Database: {LICENSE_INCLUDED, BRING_YOUR_OWN_LICENSE}
adb_data_safe_status | Define the status of DataSafe for your Autonomous Database
adb_database_defined_tags_value | Define values for the defined tags associated with your Autonomous Database
adb_database_freeform_tags | Define values for the freeform tags associated with your Autonomous Database
adb_tde_wallet_zip_file | Define TDE wallet zip file name of your Autonomous Database


