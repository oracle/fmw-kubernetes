---
title: "Oracle Access Management"
description: "The Oracle WebLogic Server Kubernetes Operator supports deployment of Oracle Access Management (OAM). Follow the instructions in this guide to set up these Oracle Access Management domains on Kubernetes."
weight: 2
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

### Limitations

See [here]({{< relref "/oam/prerequisites#limitations">}}) for limitations in this release.

### Getting started

For detailed information about deploying Oracle Access Management domains, start at [Prerequisites]({{< relref "/oam/prerequisites" >}}) and follow this documentation sequentially.

If performing an Enterprise Deployment, refer to the [Enterprise Deployment Guide for Oracle Identity and Access Management in a Kubernetes Cluster](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/index.html) instead.


### Current release

The current supported release of the WebLogic Kubernetes Operator, for Oracle Access Management domains deployment is [3.0.1](https://github.com/oracle/weblogic-kubernetes-operator/releases/tag/v3.0.1).

