---
title: "Oracle WebCenter Sites"
date: 2019-02-23T16:43:45-05:00
description: "The WebLogic Kubernetes Operator supports deployment of Oracle WebCenter Sites. Follow the instructions in this guide to set up Oracle WebCenter Sites domains on Kubernetes."
---

In this release, Oracle WebCenter Sites domains are supported using the "domain on a persistent volume" 
[model](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/choosing-a-model/) only, where the domain home is located in a persistent volume (PV).

The operator has several key features to assist you with deploying and managing Oracle WebCenter Sites domains in a Kubernetes environment. You can:

* Create Oracle WebCenter Sites instances in a Kubernetes persistent volume (PV). This PV can reside in an NFS file system or other Kubernetes volume types.
* Start servers based on declarative startup parameters and desired states.
* Expose the Oracle WebCenter Sites services and composites for external access.
* Scale Oracle WebCenter Sites domains by starting and stopping Managed Servers on demand, or by integrating with a REST API to initiate scaling based on WLDF, Prometheus, Grafana, or other rules.
* Publish operator and WebLogic Server logs to Elasticsearch and interact with them in Kibana.
* Monitor the Oracle WebCenter Sites instance using Prometheus and Grafana.

#### Current production release

The current supported production release of the Oracle WebLogic Server Kubernetes Operator, for Oracle WebCenter Sites domains deployment is [3.0.1](https://github.com/oracle/weblogic-kubernetes-operator/releases/tag/v3.0.1)

#### Recent changes and known issues

See the [Release Notes]({{< relref "/wcsites-domains/release-notes.md" >}}) for recent changes and known issues for Oracle WebCenter Sites domains deployment on Kubernetes.

#### Limitations

See [here]({{< relref "/wcsites-domains/installguide/prerequisites#limitations">}}) for limitations in this release.

#### About this documentation

This documentation includes sections targeted to different audiences.  To help you find what you are looking for more easily,
please consult this table of contents:

* [Quick Start]({{< relref "/wcsites-domains/appendix/quickstart-deployment-on-prem.md" >}}) explains how to quickly get an Oracle WebCenter Sites domain instance running, using the defaults, nothing special. Note that this is only for development and test purposes.
* [Install Guide]({{< relref "/wcsites-domains/installguide/_index.md" >}}) and [Administration Guide]({{< relref "/wcsites-domains/adminguide/" >}}) provide detailed information about all aspects of using the Kubernetes operator including:

   * Installing and configuring the operator.
   * Using the operator to create and manage Oracle WebCenter Sites domains.
   * Configuring Kubernetes load balancers.
   * Configuring Elasticsearch and Kibana to access the operator and WebLogic Server log files.
   * Patching an Oracle WebCenter Sites Docker image.
   * Removing/deleting domains.
   * And much more!


#### Additional reading

Oracle WebCenter Sites domains deployment on Kubernetes leverages the Oracle WebLogic Server Kubernetes operator framework.
* To develop an understanding of the operator, including design, architecture, domain life cycle management, and configuration overrides, review the [operator documentation](https://oracle.github.io/weblogic-kubernetes-operator).
* To learn more about the Oracle WebCenter Sites architecture and components, see [Understanding Oracle WebCenter Sites](https://docs.oracle.com/en/middleware/webcenter/sites/12.2.1.4/index.html).
* To understand the known issues and common questions for Oracle WebCenter Sites domains deployment on Kubernetes, see the  [frequently asked questions]({{< relref "/wcsites-domains/faq.md" >}}).
