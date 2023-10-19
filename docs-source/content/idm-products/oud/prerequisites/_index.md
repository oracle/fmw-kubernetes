---
title: "Prerequisites"
weight: 3
pre : "<b>3. </b>"
description: "Oracle Unified Directory Prerequisites."
---

### Introduction

This document provides information about the system requirements for deploying and running Oracle Unified Directory 12c PS4 (12.2.1.4.0) in a Kubernetes environment.

### System Requirements for Oracle Unified Directory on Kubernetes

* A running Kubernetes cluster that meets the following requirements:
	* The Kubernetes cluster must have sufficient nodes and resources.
	* An installation of Helm is required on the Kubernetes cluster. Helm is used to create and deploy the necessary resources on the Kubernetes cluster.
	* A supported container engine must be installed and running on the Kubernetes cluster.
    * The Kubernetes cluster and container engine must meet the minimum version requirements outlined in document ID 2723908.1 on [My Oracle Support](https://support.oracle.com).
	* The nodes in the Kubernetes cluster must have access to a persistent volume such as a Network File System (NFS) mount, a shared file system, or block storage. If you intend to use assured replication in OUD, you must have a persistent volume available that uses a Network File System (NFS) mount, or a shared file system for the config volume. See [Enabling Assured Replication](../create-oud-instances/#enabling-assured-replication-optional).
	
**Note**: This documentation does not tell you how to install a Kubernetes cluster, Helm, the container engine, or how to push container images to a container registry. 
Please refer to your vendor specific documentation for this information. Also see [Getting Started](../introduction#getting-started).