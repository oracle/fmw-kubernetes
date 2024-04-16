---
title: "Introduction"
weight: 1
pre : "<b>1. </b>"
description: "Oracle Unified Directory Services Manager provides an interface for managing instances of Oracle Unified Directory"
---

Oracle Unified Directory Services Manager (OUDSM) is an interface for managing instances of Oracle Unified Directory. Oracle Unified Directory Services Manager enables you to configure the structure of the directory, define objects in the directory, add and configure users, groups, and other entries. Oracle Unified Directory Services Manager is also the interface you use to manage entries, schema, security, and other directory features.

This project supports deployment of Oracle Unified Directory Services Manager images based on the 12cPS4 (12.2.1.4.0) release within a Kubernetes environment. The Oracle Unified Directory Services Manager Image refers to binaries for Oracle Unified Directory Services Manager Release 12.2.1.4.0.

Follow the instructions in this guide to set up Oracle Unified Directory Services Manager on Kubernetes.

### Current production release

The current production release for the Oracle Unified Directory 12c PS4 (12.2.1.4.0) deployment on Kubernetes is [24.2.1](https://github.com/oracle/fmw-kubernetes/releases).

### Recent changes and known issues

See the [Release Notes](../release-notes) for recent changes and known issues for Oracle Unified Directory deployment on Kubernetes.

### Getting started

This documentation explains how to configure OUDSM on a Kubernetes cluster where no other Oracle Identity Management products will be deployed. For detailed information about this type of deployment, start at [Prerequisites](../prerequisites) and follow this documentation sequentially. Please note that this documentation does not explain how to configure a Kubernetes cluster given the product can be deployed on any compliant Kubernetes vendor.

If you are deploying multiple Oracle Identity Management products on the same Kubernetes cluster, then you must follow the Enterprise Deployment Guide outlined in [Enterprise Deployments](../../enterprise-deployments). 
Please note, you also have the option to follow the Enterprise Deployment Guide even if you are only installing OUDSM and no other Oracle Identity Management products.

**Note**: If you need to understand how to configure a Kubernetes cluster ready for an Oracle Unified Directory Services Manager deployment, you should follow the Enterprise Deployment Guide referenced in [Enterprise Deployments](../../enterprise-deployments). The [Enterprise Deployment Automation](../../enterprise-deployments/enterprise-deployment-automation) section also contains details on automation scripts that can:

   + Automate the creation of a Kubernetes cluster on Oracle Cloud Infrastructure (OCI), ready for the deployment of Oracle Identity Management products. 
   + Automate the deployment of Oracle Identity Management products on any compliant Kubernetes cluster.

### Documentation for earlier releases

To view documentation for an earlier release, see:

* [Version 24.1.1](https://oracle.github.io/fmw-kubernetes/24.1.1/idm-products/oudsm/)
* [Version 23.4.1](https://oracle.github.io/fmw-kubernetes/23.4.1/idm-products/oudsm/)
* [Version 23.3.1](https://oracle.github.io/fmw-kubernetes/23.3.1/idm-products/oudsm/)
* [Version 23.2.1](https://oracle.github.io/fmw-kubernetes/23.2.1/idm-products/oudsm/)
* [Version 23.1.1](https://oracle.github.io/fmw-kubernetes/23.1.1/idm-products/oudsm/)
* [Version 22.4.1](https://oracle.github.io/fmw-kubernetes/22.4.1/oudsm/)
* [Version 22.3.1](https://oracle.github.io/fmw-kubernetes/22.3.1/oudsm/)
* [Version 22.2.1](https://oracle.github.io/fmw-kubernetes/22.2.1/oudsm/)
* [Version 21.4.2](https://oracle.github.io/fmw-kubernetes/21.4.2/oudsm/)
* [Version 21.4.1](https://oracle.github.io/fmw-kubernetes/21.4.1/oudsm/)