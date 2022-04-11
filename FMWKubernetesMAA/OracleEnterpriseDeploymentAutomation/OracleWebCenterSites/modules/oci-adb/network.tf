## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

resource "oci_core_vcn" "adb_vcn" {
  count          = (!var.use_existing_vcn && var.adb_private_endpoint) ? 1 : 0
  cidr_block     = var.vcn_cidr
  compartment_id = var.compartment_ocid
  display_name   = "adb_vcn"
  dns_label      = "adbvcn"
  defined_tags   = var.defined_tags
}

resource "oci_core_service_gateway" "adb_sg" {
  count          = (!var.use_existing_vcn && var.adb_private_endpoint) ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "adb_sg"
  vcn_id         = oci_core_vcn.adb_vcn[0].id
  services {
    service_id = lookup(data.oci_core_services.AllOCIServices[0].services[0], "id")
  }
  defined_tags = var.defined_tags
}

resource "oci_core_nat_gateway" "adb_natgw" {
  count          = (!var.use_existing_vcn && var.adb_private_endpoint) ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "adb_natgw"
  vcn_id         = oci_core_vcn.adb_vcn[0].id
  defined_tags   = var.defined_tags
}

resource "oci_core_route_table" "adb_rt_via_natgw_and_sg" {
  count          = (!var.use_existing_vcn && var.adb_private_endpoint) ? 1 : 0
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.adb_vcn[0].id
  display_name   = "adb_rt_via_natgw"
  defined_tags   = var.defined_tags

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.adb_natgw[0].id
  }

  route_rules {
    destination       = lookup(data.oci_core_services.AllOCIServices[0].services[0], "cidr_block")
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.adb_sg[0].id
  }
}

resource "oci_core_network_security_group" "adb_nsg" {
  count          = (!var.use_existing_vcn && var.adb_private_endpoint) ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "adb_nsg"
  vcn_id         = oci_core_vcn.adb_vcn[0].id
  defined_tags   = var.defined_tags
}

resource "oci_core_network_security_group_security_rule" "adb_nsg_egress_group_sec_rule" {
  count                     = (!var.use_existing_vcn && var.adb_private_endpoint) ? 1 : 0
  network_security_group_id = oci_core_network_security_group.adb_nsg[0].id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = var.vcn_cidr
  destination_type          = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "adb_nsg_ingress_group_sec_rule" {
  count                     = (!var.use_existing_vcn && var.adb_private_endpoint) ? 1 : 0
  network_security_group_id = oci_core_network_security_group.adb_nsg[0].id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      max = 1522
      min = 1522
    }
  }
}

resource "oci_core_subnet" "adb_subnet" {
  count                      = (!var.use_existing_vcn && var.adb_private_endpoint) ? 1 : 0
  cidr_block                 = var.adb_subnet_cidr
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.adb_vcn[0].id
  display_name               = "adb_subnet"
  dns_label                  = "adbnet"
  security_list_ids          = [oci_core_vcn.adb_vcn[0].default_security_list_id]
  route_table_id             = oci_core_route_table.adb_rt_via_natgw_and_sg[0].id
  prohibit_public_ip_on_vnic = true
  defined_tags               = var.defined_tags
}



