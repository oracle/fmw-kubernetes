---
title: "Oracle Unified Directory"
description: "Oracle Unified Directory provides a comprehensive Directory Solution for robust Identity Management"
weight: 2
---

Oracle Unified Directory provides a comprehensive Directory Solution for robust Identity Management.
Oracle Unified Directory is an all-in-one directory solution with storage, proxy, synchronization and virtualization capabilities. While unifying the approach, it provides all the services required for high-performance Enterprise and carrier-grade environments. Oracle Unified Directory ensures scalability to billions of entries, ease of installation, elastic deployments, enterprise manageability and effective monitoring.

This project supports deployment of Oracle Unified Directory (OUD) container images based on the 12cPS4 (12.2.1.4.0) release within a Kubernetes environment. The OUD container image refers to binaries for OUD Release 12.2.1.4.0 and it has the capability to create different types of OUD Instances (Directory Service, Proxy, Replication) in containers.

This project has several key features to assist you with deploying and managing Oracle Unified Directory in a Kubernetes environment. You can:

* Create Oracle Unified Directory instances in a Kubernetes persistent volume (PV). This PV can reside in an NFS file system or other Kubernetes volume types.
* Start servers based on declarative startup parameters and desired states.
* Expose the Oracle Unified Directory services for external access.
* Scale Oracle Unified Directory by starting and stopping servers on demand.
* Monitor the Oracle Unified Directory instance using Prometheus and Grafana.


### Current production release

The current production release for the Oracle Unified Directory 12c PS4 (12.2.1.4.0) deployment on Kubernetes is [22.2.1](https://github.com/oracle/fmw-kubernetes/releases).

### Recent changes and known issues

See the [Release Notes]({{< relref "/oud/release-notes.md" >}}) for recent changes and known issues for Oracle Unified Directory deployment on Kubernetes.

### Getting started

This documentation explains how to configure OUD on a Kubernetes cluster where no other Oracle Identity Management products will be deployed. For detailed information about this type of deployment, start at [Prerequisites]({{< relref "/oud/prerequisites" >}}) and follow this documentation sequentially.

If performing an Enterprise Deployment, refer to the [Enterprise Deployment Guide for Oracle Identity and Access Management in a Kubernetes Cluster](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/index.html) instead.

### Documentation for earlier releases

To view documentation for an earlier release, see:

* [Version 21.4.2](https://oracle.github.io/fmw-kubernetes/21.4.2/oud/)
* [Version 21.4.1](https://oracle.github.io/fmw-kubernetes/21.4.1/oud/)

