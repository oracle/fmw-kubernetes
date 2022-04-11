---
title: "Oracle Identity Governance"
description: "The WebLogic Kubernetes Operator supports deployment of Oracle Identity Governance. Follow the instructions in this guide to set up Oracle Identity Governance domains on Kubernetes."
weight: 3
---

The WebLogic Kubernetes Operator supports deployment of Oracle Identity Governance (OIG).

In this release, OIG domains are supported using the “domain on a persistent volume”
[model](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/choosing-a-model/) only, where the domain home is located in a persistent volume (PV).

The operator has several key features to assist you with deploying and managing OIG domains in a Kubernetes
environment. You can:

* Create OIG instances in a Kubernetes persistent volume. This persistent volume can reside in an NFS file system or other Kubernetes volume types.
* Start servers based on declarative startup parameters and desired states.
* Expose the OIG Services for external access.
* Scale OIG domains by starting and stopping Managed Servers on demand.
* Publish operator and WebLogic Server logs into Elasticsearch and interact with them in Kibana.
* Monitor the OIG instance using Prometheus and Grafana.

### Current production release

The current production release for the Oracle Identity Governance domain deployment on Kubernetes is [21.4.2](https://github.com/oracle/fmw-kubernetes/releases). This release uses the WebLogic Kubernetes Operator version 3.3.0.

This release of the documentation can also be used for 3.1.X and 3.2.0 WebLogic Kubernetes Operator.
For 3.0.X WebLogic Kubernetes Operator refer to [Version 21.4.1](https://oracle.github.io/fmw-kubernetes/21.4.1/oig/)

### Limitations

See [here]({{< relref "/oig/prerequisites#limitations">}}) for limitations in this release.

### Getting started

For detailed information about deploying Oracle Identity Governance domains, start at [Prerequisites]({{< relref "/oig/prerequisites" >}}) and follow this documentation sequentially.

If performing an Enterprise Deployment, refer to the [Enterprise Deployment Guide for Oracle Identity and Access Management in a Kubernetes Cluster](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/index.html) instead.

### Documentation for earlier releases

To view documentation for an earlier release, see:

* [Version 21.4.1](https://oracle.github.io/fmw-kubernetes/21.4.1/oig/)
