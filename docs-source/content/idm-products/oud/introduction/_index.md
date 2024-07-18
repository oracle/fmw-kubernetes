---
title: "Introduction"
weight: 1
pre : "<b>1. </b>"
description: "Oracle Unified Directory provides a comprehensive Directory Solution for robust Identity Management"
---

Oracle Unified Directory provides a comprehensive Directory Solution for robust Identity Management.
Oracle Unified Directory is an all-in-one directory solution with storage, proxy, synchronization and virtualization capabilities. While unifying the approach, it provides all the services required for high-performance Enterprise and carrier-grade environments. Oracle Unified Directory ensures scalability to billions of entries, ease of installation, elastic deployments, enterprise manageability and effective monitoring.

This project supports deployment of Oracle Unified Directory (OUD) container images based on the 12cPS4 (12.2.1.4.0) release within a Kubernetes environment. The OUD container image refers to binaries for OUD Release 12.2.1.4.0 and it has the capability to create different types of OUD Instances (Directory Service, Proxy, Replication) in containers.

This project has several key features to assist you with deploying and managing Oracle Unified Directory in a Kubernetes environment. You can:

* Create Oracle Unified Directory instances in a Kubernetes persistent volume (PV). This PV can reside in an NFS file system, block storage device, or other Kubernetes volume types.
* Start servers based on declarative startup parameters and desired states.
* Expose the Oracle Unified Directory services for external access.
* Scale Oracle Unified Directory by starting and stopping servers on demand.
* Monitor the Oracle Unified Directory instance using Prometheus and Grafana.


### Current production release

The current production release for the Oracle Unified Directory 12c PS4 (12.2.1.4.0) deployment on Kubernetes is [24.3.1](https://github.com/oracle/fmw-kubernetes/releases).

### Recent changes and known issues

See the [Release Notes](../release-notes) for recent changes and known issues for Oracle Unified Directory deployment on Kubernetes.

### Getting started

This documentation explains how to configure OUD on a Kubernetes cluster where no other Oracle Identity Management products will be deployed. For detailed information about this type of deployment, start at [Prerequisites](../prerequisites) and follow this documentation sequentially. Please note that this documentation does not explain how to configure a Kubernetes cluster given the product can be deployed on any compliant Kubernetes vendor.

If you are deploying multiple Oracle Identity Management products on the same Kubernetes cluster, then you must follow the Enterprise Deployment Guide outlined in [Enterprise Deployments](../../enterprise-deployments). 
Please note, you also have the option to follow the Enterprise Deployment Guide even if you are only installing OUD and no other Oracle Identity Management products.

**Note**: If you need to understand how to configure a Kubernetes cluster ready for an Oracle Unified Directory deployment, you should follow the Enterprise Deployment Guide referenced in [Enterprise Deployments](../../enterprise-deployments). The [Enterprise Deployment Automation](../../enterprise-deployments/enterprise-deployment-automation) section also contains details on automation scripts that can:

   + Automate the creation of a Kubernetes cluster on Oracle Cloud Infrastructure (OCI), ready for the deployment of Oracle Identity Management products. 
   + Automate the deployment of Oracle Identity Management products on any compliant Kubernetes cluster.

### Documentation for earlier releases

To view documentation for an earlier release, see:

* [Version 24.2.1](https://oracle.github.io/fmw-kubernetes/24.2.1/idm-products/oud/)
* [Version 24.1.1](https://oracle.github.io/fmw-kubernetes/24.1.1/idm-products/oud/)
* [Version 23.4.1](https://oracle.github.io/fmw-kubernetes/23.4.1/idm-products/oud/)
* [Version 23.3.1](https://oracle.github.io/fmw-kubernetes/23.3.1/idm-products/oud/)
* [Version 23.2.1](https://oracle.github.io/fmw-kubernetes/23.2.1/idm-products/oud/)
* [Version 23.1.1](https://oracle.github.io/fmw-kubernetes/23.1.1/idm-products/oud/)
* [Version 22.4.1](https://oracle.github.io/fmw-kubernetes/22.4.1/oud/)
* [Version 22.3.1](https://oracle.github.io/fmw-kubernetes/22.3.1/oud/)
* [Version 22.2.1](https://oracle.github.io/fmw-kubernetes/22.2.1/oud/)
* [Version 21.4.2](https://oracle.github.io/fmw-kubernetes/21.4.2/oud/)
* [Version 21.4.1](https://oracle.github.io/fmw-kubernetes/21.4.1/oud/)

