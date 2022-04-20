---
title: "Prerequisites"
weight: 2
pre : "<b>2. </b>"
description: "Prerequisites for deploying and running Oracle Internet Directory in a Kubernetes environment."
---

### Introduction

This document provides information about the system requirements for deploying and running Oracle Internet Directory 12c PS4 (12.2.1.4.0) in a Kubernetes environment.

### System Requirements for Oracle Internet Directory on Kubernetes

* A running Kubernetes cluster that meets the following requirements:
	* The Kubernetes cluster must have sufficient nodes and resources.
	* An installation of Helm is required on the Kubernetes cluster. Helm is used to create and deploy the necessary resources on the Kubernetes cluster.
	* A supported container engine must be installed and running on the Kubernetes cluster.
    * The Kubernetes cluster and container engine must meet the minimum version requirements outlined in document ID 2723908.1 on [My Oracle Support](https://support.oracle.com).
	* The nodes in the Kubernetes cluster must have access to a persistent volume such as a Network File System (NFS) mount or a shared file system.

* A running Oracle Database 12.2.0.1 or later. The database must be a supported version for OID as outlined in [Oracle Fusion Middleware 12c certifications](https://www.oracle.com/technetwork/middleware/fmw-122140-certmatrix-5763476.xlsx). It must meet the requirements as outlined in [About Database Requirements for an Oracle Fusion Middleware Installation](http://www.oracle.com/pls/topic/lookup?ctx=fmw122140&id=GUID-4D3068C8-6686-490A-9C3C-E6D2A435F20A) and in [RCU Requirements for Oracle Databases](http://www.oracle.com/pls/topic/lookup?ctx=fmw122140&id=GUID-35B584F3-6F42-4CA5-9BBB-116E447DAB83).
	
**Note**: This documentation does not tell you how to install a Kubernetes cluster, Helm, the container engine, or how to push container images to a container registry. 
Please refer to your vendor specific documentation for this information.
