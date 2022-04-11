---
title: "Oracle SOA Suite"
date: 2019-02-23T16:43:45-05:00
description: "The Oracle WebLogic Kubernetes Operator (the “operator”) supports deployment of Oracle SOA Suite components such as Oracle Service-Oriented Architecture (SOA), Oracle Service Bus, and Oracle Enterprise Scheduler (ESS). Follow the instructions in this guide to set up these Oracle SOA Suite domains on Kubernetes."
weight: 4
---

The WebLogic Kubernetes Operator (the “operator”) supports deployment of Oracle SOA Suite components such as Oracle Service-Oriented Architecture (SOA), Oracle Service Bus, and Oracle Enterprise Scheduler (ESS). Currently the operator supports these domain types:

* `soa`       : Deploys a SOA domain with Oracle Enterprise Scheduler (ESS)
* `osb`       : Deploys an Oracle Service Bus domain
* `soaosb`    : Deploys a domain with SOA, Oracle Service Bus, and Oracle Enterprise Scheduler (ESS)

In this release, Oracle SOA Suite domains are supported using the “domain on a persistent volume”
[model](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/choosing-a-model/) only, where the domain home is located in a persistent volume (PV).

The operator has several key features to assist you with deploying and managing Oracle SOA Suite domains in a Kubernetes environment. You can:

* Create Oracle SOA Suite instances in a Kubernetes persistent volume (PV). This PV can reside in an NFS file system or other Kubernetes volume types.
* Start servers based on declarative startup parameters and desired states.
* Expose the Oracle SOA Suite services and composites for external access.
* Scale Oracle SOA Suite domains by starting and stopping Managed Servers on demand, or by integrating with a REST API.
* Publish operator and WebLogic Server logs to Elasticsearch and interact with them in Kibana.
* Monitor the Oracle SOA Suite instance using Prometheus and Grafana.

#### Current production release

The current production release for the Oracle SOA Suite domains deployment on Kubernetes is [22.1.2](https://github.com/oracle/fmw-kubernetes/releases). This release uses the WebLogic Kubernetes Operator version [3.3.0](https://github.com/oracle/weblogic-kubernetes-operator/releases/tag/v3.3.0).


#### Recent changes and known issues

See the [Release Notes]({{< relref "/soa-domains/release-notes.md" >}}) for recent changes and known issues for Oracle SOA Suite domains deployment on Kubernetes.

#### Limitations

See [here]({{< relref "/soa-domains/installguide/prerequisites#limitations">}}) for limitations in this release.

#### About this documentation

This documentation includes sections targeted to different audiences.  To help you find what you are looking for more easily,
please consult this table of contents:

* [Quick Start]({{< relref "/soa-domains/appendix/quickstart-deployment-on-prem.md" >}}) explains how to quickly get an Oracle SOA Suite domain instance running using default settings. Note that this is only for development and test purposes.
* [Install Guide]({{< relref "/soa-domains/installguide/_index.md" >}}) and [Administration Guide]({{< relref "/soa-domains/adminguide/" >}}) provide detailed information about all aspects of using the Kubernetes operator including:

   * Installing and configuring the operator.
   * Using the operator to create and manage Oracle SOA Suite domains.
   * Configuring Kubernetes load balancers.
   * Configuring custom SSL certificates.
   * Configuring Elasticsearch and Kibana to access the operator and WebLogic Server log files.
   * Deploying composite applications for Oracle SOA Suite and Oracle Service Bus.
   * Patching an Oracle SOA Suite Docker image.
   * Removing domains.
   * And much more!

#### Documentation for earlier releases

To view documentation for an earlier release, see:

* [Version 21.4.2](https://oracle.github.io/fmw-kubernetes/21.4.2/soa-domains/)
* [Version 21.3.2](https://oracle.github.io/fmw-kubernetes/21.3.2/soa-domains/)
* [Version 21.2.2](https://oracle.github.io/fmw-kubernetes/21.2.2/soa-domains/)
* [Version 21.1.2](https://oracle.github.io/fmw-kubernetes/21.1.2/soa-domains/)
* [Version 20.4.2](https://oracle.github.io/fmw-kubernetes/20.4.2/soa-domains/)
* [Version 20.3.3](https://oracle.github.io/fmw-kubernetes/20.3.3/soa-domains/)

#### Additional reading

Oracle SOA Suite domains deployment on Kubernetes leverages the WebLogic Kubernetes Operator framework.
* To develop an understanding of the operator, including design, architecture, domain life cycle management, and configuration overrides, review the [operator documentation](https://oracle.github.io/weblogic-kubernetes-operator).
* To learn more about the Oracle SOA Suite architecture and components, see [Understanding Oracle SOA Suite](https://docs.oracle.com/en/middleware/soa-suite/soa/12.2.1.4/develop/introduction-building-applications.html#GUID-AED865D0-2FFF-4243-B8C5-473F8572D6F0).
* To review the known issues and common questions for Oracle SOA Suite domains deployment on Kubernetes, see the  [frequently asked questions]({{< relref "/soa-domains/faq.md" >}}).
