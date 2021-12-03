---
title: "Oracle Internet Directory"
date: 2019-02-23T16:43:45-05:00
description: "Oracle Internet Directory provides a comprehensive Directory Solution for robust Identity Management"
weight: 2
---

Oracle Internet Directory provides a comprehensive Directory Solution for robust Identity Management.
Oracle Internet Directory is an all-in-one directory solution with storage, proxy, synchronization and virtualization capabilities. While unifying the approach, it provides all the services required for high-performance Enterprise and carrier-grade environments. Oracle Internet Directory ensures scalability to billions of entries, ease of installation, elastic deployments, enterprise manageability and effective monitoring.

This project supports deployment of Oracle Internet Directory (OID) Docker images based on the 12cPS4 (12.2.1.4.0) release within a Kubernetes environment. The OID Docker Image refers to binaries for OID Release 12.2.1.4.0.

***Image***: oracle/oid:12.2.1.4.0

This project has several key features to assist you with deploying and managing Oracle Internet Directory in a Kubernetes environment. You can:

* Create Oracle Internet Directory instances in a Kubernetes persistent volume (PV). This PV can reside in an NFS file system or other Kubernetes volume types.
* Start servers based on declarative startup parameters and desired states.
* Expose the Oracle Internet Directory services for external access.
* Scale Oracle Internet Directory by starting and stopping servers on demand.
* Monitor the Oracle Internet Directory instance using Prometheus and Grafana.

Follow the instructions in this guide to set up Oracle Internet Directory on Kubernetes.

### Getting started

For detailed information about deploying Oracle Internet Directory, start at [Prerequisites]({{< relref "/oid/prerequisites">}}) and follow this documentation sequentially.

### Current release

The current production release for Oracle Internet Directory 12c PS4 (12.2.1.4.0) deployment on Kubernetes is [21.4.1](https://github.com/oracle/fmw-kubernetes/releases).

