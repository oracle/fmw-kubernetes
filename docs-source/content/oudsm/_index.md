---
title: "Oracle Unified Directory Services Manager"
description: "Oracle Unified Directory Services Manager provides an interface for managing instances of Oracle Unified Directory"
weight: 2
---

Oracle Unified Directory Services Manager (OUDSM) is an interface for managing instances of Oracle Unified Directory. Oracle Unified Directory Services Manager enables you to configure the structure of the directory, define objects in the directory, add and configure users, groups, and other entries. Oracle Unified Directory Services Manager is also the interface you use to manage entries, schema, security, and other directory features.

This project supports deployment of Oracle Unified Directory Services Manager images based on the 12cPS4 (12.2.1.4.0) release within a Kubernetes environment. The Oracle Unified Directory Services Manager Image refers to binaries for Oracle Unified Directory Services Manager Release 12.2.1.4.0.

Follow the instructions in this guide to set up Oracle Unified Directory Services Manager on Kubernetes.

### Current production release

The current production release for the Oracle Unified Directory 12c PS4 (12.2.1.4.0) deployment on Kubernetes is [22.3.1](https://github.com/oracle/fmw-kubernetes/releases).

### Recent changes and known issues

See the [Release Notes]({{< relref "/oudsm/release-notes.md" >}}) for recent changes and known issues for Oracle Unified Directory deployment on Kubernetes.

### Getting started

This documentation explains how to configure OUDSM on a Kubernetes cluster where no other Oracle Identity Management products will be deployed. For detailed information about this type of deployment, start at [Prerequisites]({{< relref "/oudsm/prerequisites" >}}) and follow this documentation sequentially.

If performing an Enterprise Deployment, refer to the [Enterprise Deployment Guide for Oracle Identity and Access Management in a Kubernetes Cluster](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/index.html) instead.

### Documentation for earlier releases

To view documentation for an earlier release, see:

* [Version 22.2.1](https://oracle.github.io/fmw-kubernetes/22.2.1/oudsm/)
* [Version 21.4.2](https://oracle.github.io/fmw-kubernetes/21.4.2/oudsm/)
* [Version 21.4.1](https://oracle.github.io/fmw-kubernetes/21.4.1/oudsm/)