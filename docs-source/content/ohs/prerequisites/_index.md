---
title: "Prerequisites"
weight: 3
pre : "<b>3. </b>"
description: "System requirements and limitations for deploying and running OHS on Kubernetes"
---

### Introduction

This document provides information about the system requirements and limitations for deploying and running Oracle HTTP Server (OHS) on Kubernetes.

### System requirements for OHS on Kubernetes


* A running Kubernetes cluster that meets the following requirements:
   * The Kubernetes cluster must have sufficient nodes and resources.
   * A supported container engine must be installed and running on the Kubernetes cluster.
   * The Kubernetes cluster and container engine must meet the minimum version requirements outlined in document ID 3058838.1 on [My Oracle Support](https://support.oracle.com).
   * The system clocks on node of the Kubernetes cluster must be synchronized. Run the `date` command simultaneously on all the nodes in each cluster and then syncrhonize accordingly.
 

**Note**: This documentation does not tell you how to install a Kubernetes cluster, the container engine, or how to push container images to a container registry. 

Please refer to your vendor specific documentation for this information.


### Oracle Access Management prerequisites

If you intend to use OHS with Oracle WebGate and Oracle Access Management (OAM), then Oracle Access Management must have been deployed beforehand, either in an on-premises environment, or in a Kubernetes cluster.
You must have an understanding of Oracle Access Management and Oracle WebGate before proceeding.

Instructions for deploying OAM in a Kubernetes cluster can be found in [Oracle Access Management](../../idm-products/oam). OAM in a Kubernetes cluster must be deployed as per one of the [Supported Architectures](../introduction#supported-architectures) defined. 

To use Oracle WebGate with OHS you must perform the following before deploying OHS:

+ Update the Load Balancing and WebGate Traffic Load Balancer to the entry point for OAM. For example, if OAM is accessed via the load balancer (`https://loadbalancer.example.com`), then the **OAM Server Host**, **OAM Server Port**, and **OAM Server Protocol** should be updated to `loadbalancer.example.com`, `443`, and `HTTPS` respectively. For more information, see [Update the OAM Hostname and Port for the Loadbalancer](../../idm-products/oam/validate-sso-using-webgate/#update-the-oam-hostname-and-port-for-the-loadbalancer).

+ Create an Agent in the Oracle Access Management console.  After creating the agent, make sure the User Defined Parameters for `OAMRestEndPointHostName`, `OAMRestEndPointPort`, and `OAMServerCommunicationMode` are set to the same values as the load balancing settings above. See, [Register a WebGate Agent](../../idm-products/oam/validate-sso-using-webgate/#register-a-webgate-agent). 

+ In the Application Domain created for the WebGate, update the resources with any resources you wish to protect.

+ Create any `Host Identifier(s)` for any URL's you require. For example if you access OAM via a load balancer, create a host identifier for both the load balancer hostname.domain and the OHS hostname.domain. If you access OAM directly via OHS, created a host identifier for the OHS hostname.domain. See [Create Host Identifiers](../../idm-products/oam/validate-sso-using-webgate/#create-host-identifiers).

+ Download the zip file for the Agent from the OAM Console. This zip file will later be copied and extracted to the `$WORKDIR/ohsConfig/webgate/config` directory. See, [Prepare your OHS configuration files](../prepare-your-environment/#prepare-your-ohs-configuration-files).



### Next Steps

You are now ready to [Prepare your environment](../prepare-your-environment).






