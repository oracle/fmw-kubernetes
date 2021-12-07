---
title: "Oracle Unified Directory"
date: 2019-02-23T16:43:45-05:00
description: "Oracle Unified Directory provides a comprehensive Directory Solution for robust Identity Management"
weight: 5 
---

Oracle Unified Directory provides a comprehensive Directory Solution for robust Identity Management.
Oracle Unified Directory is an all-in-one directory solution with storage, proxy, synchronization and virtualization capabilities. While unifying the approach, it provides all the services required for high-performance Enterprise and carrier-grade environments. Oracle Unified Directory ensures scalability to billions of entries, ease of installation, elastic deployments, enterprise manageability and effective monitoring.

This project supports deployment of Oracle Unified Directory (OUD) Docker images based on the 12cPS4 (12.2.1.4.0) release within a Kubernetes environment. The OUD Docker Image refers to binaries for OUD Release 12.2.1.4.0 and it has the capability to create different types of OUD Instances (Directory Service, Proxy, Replication) in containers.

***Image***: oracle/oud:12.2.1.4.0

This project has several key features to assist you with deploying and managing Oracle Unified Directory in a Kubernetes environment. You can:

* Create Oracle Unified Directory instances in a Kubernetes persistent volume (PV). This PV can reside in an NFS file system or other Kubernetes volume types.
* Start servers based on declarative startup parameters and desired states.
* Expose the Oracle Unified Directory services for external access.
* Scale Oracle Unified Directory by starting and stopping servers on demand.
* Monitor the Oracle Unified Directory instance using Prometheus and Grafana.

Follow the instructions in this guide to set up Oracle Unified Directory on Kubernetes.

### Getting started

For detailed information about deploying Oracle Unified Directory, start at [Prerequisites]({{< relref "/oud/prerequisites">}}) and follow this documentation sequentially.

If performing an Enterprise Deployment, refer to the [Enterprise Deployment Guide for Oracle Identity and Access Management in a Kubernetes Cluster](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/index.html) instead.

### Current release

The current production release for Oracle Unified Directory 12c PS4 (12.2.1.4.0) deployment on Kubernetes is [21.4.2](https://github.com/oracle/fmw-kubernetes/releases).


