---
title: "Prerequisites"
weight: 3
pre : "<b>3. </b>"
description: "Oracle Unified Directory Services Manager Prerequisites."
---

### Introduction

This document provides information about the system requirements for deploying and running Oracle Unified Directory Services Manager 12c PS4 (12.2.1.4.0) in a Kubernetes environment.

### System Requirements for Oracle Unified Directory Services Manager on Kubernetes

#### Kubernetes Requirements

You must have a running Kubernetes cluster that meets the following requirements:

   * The Kubernetes cluster and container engine must meet the minimum version requirements outlined in document ID 2723908.1 on [My Oracle Support](https://support.oracle.com).
   * An administrative host from which to deploy the products. This host could be a Kubernetes Control host, a Kubernetes Worker host, or an independent host. This host must have kubectl deployed using the same version as your cluster.
   * The Kubernetes cluster must have sufficient nodes and resources.
   * An installation of Helm is required on the Kubernetes cluster. Helm is used to create and deploy the necessary resources on the Kubernetes cluster.
   * A supported container engine such as CRI-O or Docker must be installed and running on the Kubernetes cluster.
   * The nodes in the Kubernetes cluster must have access to a persistent volume such as a Network File System (NFS) mount or a shared file system.
   * The system clocks on node of the Kubernetes cluster must be synchronized. Run the date command simultaneously on all the nodes in each cluster and then synchronize accordingly.
	
**Note**: This documentation does not tell you how to install a Kubernetes cluster, Helm, the container engine, or how to push container images to a container registry. 
Please refer to your vendor specific documentation for this information. Also see [Getting Started](../introduction#getting-started).

#### Container Registry Requirements

If your Kubernetes cluster does not have network access to Oracle Container Registry, then you must have your own container registry to store the OUDSM container images.

Your container registry must be accessible from all nodes in the Kubernetes cluster.

Alternatively if you don’t have your own container registry, you can load the images on each worker node in the cluster. Loading the images on each worker node is not recommended as it incurs a large administrative overhead.

**Note**: This documentation does not tell you how to install a container registry. Please refer to your vendor specific documentation for this information.