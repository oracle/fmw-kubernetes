---
title: "Introduction"
weight: 1
pre : "<b>1. </b>"
description: "The WebLogic Kubernetes Operator supports deployment of Oracle Access Management (OAM). Follow the instructions in this guide to set up these Oracle Access Management domains on Kubernetes."
---

The WebLogic Kubernetes Operator supports deployment of Oracle Access Management (OAM).

In this release, OAM domains are supported using the “domain on a persistent volume”
[model](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/choosing-a-model/) only, where the domain home is located in a persistent volume (PV).

The WebLogic Kubernetes Operator has several key features to assist you with deploying and managing Oracle Access Management domains in a Kubernetes
environment. You can:


* Create OAM instances in a Kubernetes persistent volume. This persistent volume can reside in an NFS file system or other Kubernetes volume types.
* Start servers based on declarative startup parameters and desired states.
* Expose the OAM Services through external access.
* Scale OAM domains by starting and stopping Managed Servers on demand.
* Publish operator and WebLogic Server logs into Elasticsearch and interact with them in Kibana.
* Monitor the OAM instance using Prometheus and Grafana.

### Current production release

The current production release for the Oracle Access Management domain deployment on Kubernetes is [23.2.1](https://github.com/oracle/fmw-kubernetes/releases). This release uses the WebLogic Kubernetes Operator version 4.0.4.

For 3.4.X WebLogic Kubernetes Operator refer to [Version 23.1.1](https://oracle.github.io/fmw-kubernetes/23.1.1/idm-products/oam/)

### Recent changes and known issues

See the [Release Notes](../release-notes/) for recent changes and known issues for Oracle Access Management domain deployment on Kubernetes.

### Limitations

See [here](../prerequisites/#limitations) for limitations in this release.

### Getting started

This documentation explains how to configure OAM on a Kubernetes cluster where no other Oracle Identity Management products will be deployed. For detailed information about this type of deployment , start at [Prerequisites](../prerequisites) and follow this documentation sequentially.

If performing an Enterprise Deployment where multiple Oracle Identity Management products are deployed, refer to the [Enterprise Deployment Guide for Oracle Identity and Access Management in a Kubernetes Cluster](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/index.html) instead.


### Documentation for earlier releases

To view documentation for an earlier release, see:

* [Version 23.1.1](https://oracle.github.io/fmw-kubernetes/23.1.1/idm-products/oam/)
* [Version 22.4.1](https://oracle.github.io/fmw-kubernetes/22.4.1/oam/)
* [Version 22.3.1](https://oracle.github.io/fmw-kubernetes/22.3.1/oam/)
* [Version 22.2.1](https://oracle.github.io/fmw-kubernetes/22.2.1/oam/)
* [Version 21.4.2](https://oracle.github.io/fmw-kubernetes/21.4.2/oam/)
* [Version 21.4.1](https://oracle.github.io/fmw-kubernetes/21.4.1/oam/)




