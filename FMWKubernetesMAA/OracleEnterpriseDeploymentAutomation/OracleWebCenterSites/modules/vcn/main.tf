## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

# Create VCN

resource "oci_core_virtual_network" "vcn" {
  cidr_block     = var.vcn_cidr
  compartment_id = var.compartment_ocid
  display_name   = "oke-vcn"
  dns_label      = "oke"
}

# Create internet gateway to allow public internet traffic from load balancer subnet

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  display_name   = "internet-gateway"
  vcn_id         = oci_core_virtual_network.vcn.id
}

resource "oci_core_nat_gateway" "natgw" {
  compartment_id = var.compartment_ocid
  display_name   = "nat-gateway"
  vcn_id         = oci_core_virtual_network.vcn.id
}

# Create route table to connect public subnet to internet gateway 

resource "oci_core_route_table" "public_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "public-subnet-rt-table"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

# Create private subnert Route table to connect to NAT gateway

resource "oci_core_route_table" "private_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "private-subnet-rt-table"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.natgw.id
  }
}

# Create security list for public subnet for the load balancers

resource "oci_core_security_list" "lb_sl" {
  compartment_id = var.compartment_ocid
  display_name   = "lb-security-list"
  vcn_id         = oci_core_virtual_network.vcn.id

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"
    stateless   = true
  }

  ingress_security_rules {

    protocol  = "6"
    source    = "0.0.0.0/0"
    stateless = true
  }
}

# Create securty list for the nodes private subnet 

resource "oci_core_security_list" "node_sl" {
  compartment_id = var.compartment_ocid
  display_name   = "nodes-security-list"
  vcn_id         = oci_core_virtual_network.vcn.id

  # tcp to anywhere
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"
    stateless   = false
  }

  # any traffic to cluster Pods subnet
  egress_security_rules {
    protocol    = "all"
    destination = cidrsubnet(var.vcn_cidr, 8, 10)
    stateless   = true
  }

  # any traffic to cluster Services subnet
  egress_security_rules {
    protocol    = "all"
    destination = cidrsubnet(var.vcn_cidr, 8, 20)
    stateless   = true
  }

  # all traffic from cluster Pods subnet
  ingress_security_rules {
    protocol  = "all"
    source    = cidrsubnet(var.vcn_cidr, 8, 10)
    stateless = true
  }

  # all traffic from cluster Services subnet
  ingress_security_rules {
    protocol  = "all"
    source    = cidrsubnet(var.vcn_cidr, 8, 20)
    stateless = true
  }

  # SSH traffic to nodes subnet
  ingress_security_rules {
    protocol  = "6"
    source    = "0.0.0.0/0"
    stateless = false
    tcp_options {
      max = 22
      min = 22
    }
  }

  # DNS traffic from anywhere
  ingress_security_rules {
    protocol  = "17"
    source    = "0.0.0.0/0"
    stateless = false
    udp_options {
      max = 53
      min = 53
    }
  }

  ingress_security_rules {

    protocol  = "6"
    source    = "0.0.0.0/0"
    stateless = false
    tcp_options {
      min = 30000
      max = 32767
    }
  }

  ingress_security_rules {

    protocol  = 1
    source    = "0.0.0.0/0"
    stateless = false

    icmp_options {
      type = 3
      code = 4
    }
  }

  # File Storage ports
  # TCP 111
  ingress_security_rules {

    protocol  = "6"
    source    = var.vcn_cidr
    stateless = false
    tcp_options {
      min = 111
      max = 111
    }
  }

  # TCP 2048-50
  ingress_security_rules {

    protocol  = "6"
    source    = var.vcn_cidr
    stateless = false
    tcp_options {
      min = 2048
      max = 2050
    }
  }


  # UDP 111
  ingress_security_rules {

    protocol  = "17"
    source    = var.vcn_cidr
    stateless = false
    udp_options {
      min = 111
      max = 111
    }
  }

  # UDP 2048
  ingress_security_rules {

    protocol  = "17"
    source    = var.vcn_cidr
    stateless = false
    udp_options {
      min = 2048
      max = 2048
    }
  }

  # UDP 111
  egress_security_rules {

    protocol    = "17"
    destination = var.vcn_cidr
    stateless   = false
    udp_options {
      min = 111
      max = 111
    }
  }

  # TCP 2048-2050
  egress_security_rules {

    protocol    = "6"
    destination = var.vcn_cidr
    stateless   = false
    tcp_options {
      min = 2048
      max = 2050
    }
  }

  # TCP 111
  egress_security_rules {

    protocol    = "6"
    destination = var.vcn_cidr
    stateless   = false
    tcp_options {
      min = 111
      max = 111
    }
  }

}

# Create securty list for the database subnet 

resource "oci_core_security_list" "database_sl" {
  count          = var.provision_database ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "database-security-list"
  vcn_id         = oci_core_virtual_network.vcn.id

  # TCP traffic from cluster Pods subnet
  ingress_security_rules {
    protocol  = "6"
    source    = cidrsubnet(var.vcn_cidr, 8, 10)
    stateless = false
    tcp_options {
      max = 1521
      min = 1521
    }
  }
}

# Create regional subnets in vcn

resource "oci_core_subnet" "cluster_lb_subnet" {
  cidr_block        = cidrsubnet(var.vcn_cidr, 8, 20)
  display_name      = "lb-public-subnet"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_virtual_network.vcn.id
  dhcp_options_id   = oci_core_virtual_network.vcn.default_dhcp_options_id
  route_table_id    = oci_core_route_table.public_rt.id
  security_list_ids = [oci_core_security_list.lb_sl.id]
  dns_label         = "lb"

  provisioner "local-exec" {
    command = "sleep 5"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "sleep 5"
  }
}

resource "oci_core_subnet" "cluster_nodes_subnet" {
  cidr_block                 = cidrsubnet(var.vcn_cidr, 8, 10)
  display_name               = "nodes-private-subnet"
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_virtual_network.vcn.id
  dhcp_options_id            = oci_core_virtual_network.vcn.default_dhcp_options_id
  route_table_id             = oci_core_route_table.private_rt.id
  security_list_ids          = [oci_core_security_list.node_sl.id]
  prohibit_public_ip_on_vnic = true
  dns_label                  = "nodes"

  provisioner "local-exec" {
    command = "sleep 5"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "sleep 5"
  }
}

resource "oci_core_subnet" "database_subnet" {
  count                      = var.provision_database ? 1 : 0
  cidr_block                 = cidrsubnet(var.vcn_cidr, 8, 30)
  display_name               = "db-private-subnet"
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_virtual_network.vcn.id
  dhcp_options_id            = oci_core_virtual_network.vcn.default_dhcp_options_id
  route_table_id             = oci_core_route_table.private_rt.id
  security_list_ids          = [oci_core_security_list.database_sl.0.id]
  prohibit_public_ip_on_vnic = true
  dns_label                  = "db"

  provisioner "local-exec" {
    command = "sleep 5"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "sleep 5"
  }
}
