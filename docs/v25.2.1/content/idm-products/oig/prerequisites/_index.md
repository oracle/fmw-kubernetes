---
title: "Prerequisites"
weight: 3
pre : "<b>3. </b>"
description: "System requirements and limitations for deploying and running an OIG domain"
---

### Introduction

This document provides information about the system requirements and limitations for deploying and running OIG 12.2.1.4 domains with the WebLogic Kubernetes Operator 4.2.10.

### System requirements for OIG domains

#### Kubernetes requirements

* A running Kubernetes cluster that meets the following requirements:
   * The Kubernetes cluster and container engine must meet the minimum version requirements outlined in document ID 2723908.1 on [My Oracle Support](https://support.oracle.com).
	* An administrative host from which to deploy the products. This host could be a Kubernetes Control host, a Kubernetes Worker host, or an independent host. This host must have kubectl deployed using the same version as your cluster.
	**Note**: All the commands in this guide should be run from the Kubernetes administrative host unless otherwise stated.
	* The Kubernetes cluster must have sufficient nodes and resources.
	* An installation of Helm is required on the Kubernetes cluster. Helm is used to create and deploy the necessary resources on the Kubernetes cluster
	* A supported container engine such as CRI-O or Docker must be installed and running on the Kubernetes cluster.
	* You must have the `cluster-admin` role to install the WebLogic Kubernetes Operator.
	* The nodes in the Kubernetes cluster must have access to a persistent volume such as a Network File System (NFS) mount or a shared file system.
	* The system clocks on node of the Kubernetes cluster must be synchronized. Run the `date` command simultaneously on all the nodes in each cluster and then syncrhonize accordingly.

#### Database requirements

* A running Oracle Database 12.2.0.1 or later. The database must be a supported version for OIG as outlined in [Oracle Fusion Middleware 12c certifications](https://www.oracle.com/technetwork/middleware/fmw-122140-certmatrix-5763476.xlsx). It must meet the requirements as outlined in [About Database Requirements for an Oracle Fusion Middleware Installation](http://www.oracle.com/pls/topic/lookup?ctx=fmw122140&id=GUID-4D3068C8-6686-490A-9C3C-E6D2A435F20A) and in [RCU Requirements for Oracle Databases](http://www.oracle.com/pls/topic/lookup?ctx=fmw122140&id=GUID-35B584F3-6F42-4CA5-9BBB-116E447DAB83).

**Note**: This documentation does not tell you how to install a Kubernetes cluster, Helm, or the container engine. 
Please refer to your vendor specific documentation for this information. Also see [Getting Started](../introduction#getting-started).

#### Container Registry Requirements

You must have your own container registry to store container and domain images in the following circumstances:

* If your Kubernetes cluster does not have network access to [Oracle Container Registry](https://container-registry.oracle.com), then you must have your own container registry to store the OIG container images.
* If you intend to deploy OIG with WDT models, you must have a container registry to store the domain image.

Your container registry must be accessible from all nodes in the Kubernetes cluster.

Alternatively if you don’t have your own container registry, you can load the images on each worker node in the cluster. Loading the images on each worker node is not recommended as it incurs a large administrative overhead.

**Note**: This documentation does not tell you how to install a container registry. Please refer to your vendor specific documentation for this information.


### Limitations

Compared to running a WebLogic Server domain in Kubernetes using the operator, the following limitations currently exist for OIG domains:

* In this release, OIG domains are supported using the “domain on a persistent volume”
[model](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/choosing-a-model/) only, where the domain home is located in a persistent volume (PV).
* The "domain in image" model is not supported.
* Only configured clusters are supported.  Dynamic clusters are not supported for OIG domains.  Note that you can still use all of the scaling features, you just need to define the maximum size of your cluster at domain creation time.
* The [WebLogic Monitoring Exporter](https://github.com/oracle/weblogic-monitoring-exporter) currently supports the WebLogic MBean trees only.  Support for JRF MBeans has not been added yet.
* We do not currently support running OIG in non-Linux containers.


