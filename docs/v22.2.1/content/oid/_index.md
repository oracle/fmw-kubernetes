---
title: "Oracle Internet Directory"
description: "Oracle Internet Directory provides a comprehensive Directory Solution for robust Identity Management"
---

Oracle Internet Directory provides a comprehensive Directory Solution for robust Identity Management.
Oracle Internet Directory is an all-in-one directory solution with storage, proxy, synchronization and virtualization capabilities. While unifying the approach, it provides all the services required for high-performance Enterprise and carrier-grade environments. Oracle Internet Directory ensures scalability to billions of entries, ease of installation, elastic deployments, enterprise manageability and effective monitoring.

This project supports deployment of Oracle Internet Directory (OID) container images based on the 12cPS4 (12.2.1.4.0) release within a Kubernetes environment. The OID container image refers to binaries for OID Release 12.2.1.4.0.

This project has several key features to assist you with deploying and managing Oracle Internet Directory in a Kubernetes environment. You can:

* Create Oracle Internet Directory instances in a Kubernetes persistent volume (PV). This PV can reside in an NFS file system or other Kubernetes volume types.
* Start servers based on declarative startup parameters and desired states.
* Expose the Oracle Internet Directory services for external access.
* Scale Oracle Internet Directory by starting and stopping servers on demand.
* Monitor the Oracle Internet Directory instance using Prometheus and Grafana.

Follow the instructions in this guide to set up Oracle Internet Directory on Kubernetes.

### Current production release

The current production release for the Oracle Internet Directory 12c PS4 (12.2.1.4.0) deployment on Kubernetes is [22.2.1](https://github.com/oracle/fmw-kubernetes/releases).

### Recent changes and known issues

See the [Release Notes]({{< relref "/oid/release-notes.md" >}}) for recent changes and known issues for Oracle Internet Directory deployment on Kubernetes.


### Getting started

This documentation explains how to configure OID on a Kubernetes cluster where no other Oracle Identity Management products will be deployed. For detailed information about this type of deployment, start at [Prerequisites]({{< relref "/oid/prerequisites" >}}) and follow this documentation sequentially.

If performing an Enterprise Deployment, refer to the [Enterprise Deployment Guide for Oracle Identity and Access Management in a Kubernetes Cluster](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/index.html) instead.

### Documentation for earlier releases

To view documentation for an earlier release, see:

* [Version 21.4.1](https://oracle.github.io/fmw-kubernetes/21.4.1/oid/)

