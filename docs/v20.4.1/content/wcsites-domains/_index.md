---
title: "Oracle WebCenter Sites"
date: 2019-02-23T16:43:45-05:00
description: "The WebLogic Kubernetes operator supports deployment of Oracle WebCenter Sites. Follow the instructions in this guide to set up Oracle WebCenter Sites domains on Kubernetes."
weight: 6
---

The WebLogic Kubernetes operator supports deployment of Oracle WebCenter Sites.

{{% notice warning %}}
Oracle WebCenter Sites is currently supported only for non-production use in Docker and Kubernetes.  The information provided
in this document is a *preview* for early adopters who wish to experiment with Oracle WebCenter Sites in Kubernetes before
it is supported for production use.
{{% /notice %}}

In this release, Oracle WebCenter Sites domains are supported using the `domain on a persistent volume`
[model](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/choosing-a-model/) only, where the domain home is located in a persistent volume (PV).

The operator has several key features to assist you with deploying and managing Oracle WebCenter Sites domains in a Kubernetes
environment. You can:

* Create Oracle WebCenter Sites instances in a Kubernetes persistent volume. This persistent volume can reside in an NFS file system or other Kubernetes volume types.
* Start servers based on declarative startup parameters and desired states.
* Expose the WebCenter Sites Services and Composites for external access.
* Scale WebCenter Sites domains by starting and stopping Managed Servers on demand, or by integrating with a REST API to initiate scaling based on WLDF, Prometheus, Grafana, or other rules.
* Publish operator and WebLogic Server logs into Elasticsearch and interact with them in Kibana.
* Monitor the WebCenter Sites instance using Prometheus and Grafana.

### Limitations

Refer [here]({{< relref "pre-requisites/#limitations">}}) for limitations in this release.

