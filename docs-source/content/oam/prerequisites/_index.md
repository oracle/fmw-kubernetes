---
title: "Prerequisites"
weight: 2
pre : "<b>2. </b>"
description: "System requirements and limitations for deploying and running an OAM domain home"
---

### Introduction

This document provides information about the system requirements and limitations for deploying and running OAM domains with the WebLogic Kubernetes Operator 3.4.2.



### System requirements for oam domains


* A running Kubernetes cluster that meets the following requirements:
	* The Kubernetes cluster must have sufficient nodes and resources.
	* An installation of Helm is required on the Kubernetes cluster. Helm is used to create and deploy the necessary resources and run the WebLogic Kubernetes Operator in a Kubernetes cluster
	* A supported container engine must be installed and running on the Kubernetes cluster.
    * The Kubernetes cluster and container engine must meet the minimum version requirements outlined in document ID 2723908.1 on [My Oracle Support](https://support.oracle.com).
	* You must have the `cluster-admin` role to install the WebLogic Kubernetes Operator.
	* The nodes in the Kubernetes cluster must have access to a persistent volume such as a Network File System (NFS) mount or a shared file system.
	* The system clocks on node of the Kubernetes cluster must be synchronized. Run the `date` command simultaneously on all the nodes in each cluster and then syncrhonize accordingly.
 
* A running Oracle Database 12.2.0.1 or later. The database must be a supported version for OAM as outlined in [Oracle Fusion Middleware 12c certifications](https://www.oracle.com/technetwork/middleware/fmw-122140-certmatrix-5763476.xlsx). It must meet the requirements as outlined in [About Database Requirements for an Oracle Fusion Middleware Installation](http://www.oracle.com/pls/topic/lookup?ctx=fmw122140&id=GUID-4D3068C8-6686-490A-9C3C-E6D2A435F20A) and in [RCU Requirements for Oracle Databases](http://www.oracle.com/pls/topic/lookup?ctx=fmw122140&id=GUID-35B584F3-6F42-4CA5-9BBB-116E447DAB83).

**Note**: This documentation does not tell you how to install a Kubernetes cluster, Helm, the container engine, or how to push container images to a container registry. 
Please refer to your vendor specific documentation for this information.



### Limitations

Compared to running a WebLogic Server domain in Kubernetes using the operator, the following limitations currently exist for OAM domains:

* In this release, OAM domains are supported using the “domain on a persistent volume” [model](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/choosing-a-model/) only, where the domain home is located in a persistent volume (PV).The "domain in image" model is not supported.
* Only configured clusters are supported.  Dynamic clusters are not supported for OAM domains.  Note that you can still use all of the scaling features, you just need to define the maximum size of your cluster at domain creation time.
* The [WebLogic Monitoring Exporter](https://github.com/oracle/weblogic-monitoring-exporter) currently supports the WebLogic MBean trees only.  Support for JRF MBeans has not been added yet.
* We do not currently support running OAM in non-Linux containers.

