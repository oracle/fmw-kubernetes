---
title: "Oracle SOA Suite"
date: 2019-02-23T16:43:45-05:00
description: "The Oracle WebLogic Server Kubernetes Operator (the “operator”) supports deployment of Oracle SOA Suite components such as Oracle Service-Oriented Architecture (SOA), Oracle Service Bus (OSB), and Oracle Enterprise Scheduler (ESS). Follow the instructions in this guide to set up these Oracle SOA Suite domains on Kubernetes."
---

The Oracle WebLogic Server Kubernetes Operator (the “operator”) supports deployment of Oracle SOA Suite components such as Oracle Service-Oriented Architecture (SOA), Oracle Service Bus (OSB), and Oracle Enterprise Scheduler (ESS). Currently the operator supports these domain types:

* `soa`: Deploys a SOA domain
* `osb`: Deploys an OSB domain
* `soaess`: Deploys a SOA domain with ESS
* `soaosb`: Deploys a domain with SOA and OSB
* `soaessosb`: Deploys a domain with SOA, OSB, and ESS

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

The current supported production release of the Oracle WebLogic Server Kubernetes Operator, for Oracle SOA Suite domains deployment is [3.0.1](https://github.com/oracle/weblogic-kubernetes-operator/releases).

#### Recent changes and known issues

See the [Release Notes]({{< relref "/soa-domains/release-notes.md" >}}) for recent changes and known issues for Oracle SOA Suite domains deployment on Kubernetes.

#### Limitations

See [here]({{< relref "/soa-domains/installguide/prerequisites#limitations">}}) for limitations in this release.

#### About this documentation

This documentation includes sections targeted to different audiences.  To help you find what you are looking for more easily,
please consult this table of contents:

* [Quick Start]({{< relref "/soa-domains/appendix/quickstart-deployment-on-prem.md" >}}) explains how to quickly get an Oracle SOA Suite domain instance running, using the defaults, nothing special. Note that this is only for development and test purposes.
* [Install Guide]({{< relref "/soa-domains/installguide/_index.md" >}}) and [Administration Guide]({{< relref "/soa-domains/adminguide/" >}}) provide detailed information about all aspects of using the Kubernetes operator including:

   * Installing and configuring the operator.
   * Using the operator to create and manage Oracle SOA Suite domains.
   * Configuring Kubernetes load balancers.
   * Configuring Custom SSL certificates.
   * Configuring Elasticsearch and Kibana to access the operator and WebLogic Server log files.
   * Deploying composite applications for Oracle SOA Suite and Oracle Service Bus.
   * Patching an Oracle SOA Suite Docker image.
   * Removing/deleting domains.
   * And much more!


#### Additional reading

Oracle SOA Suite domains deployment on Kubernetes leverages the Oracle WebLogic Server Kubernetes operator framework.
* To develop an understanding of the operator, including design, architecture, domain life cycle management, and configuration overrides, review the [operator documentation](https://oracle.github.io/weblogic-kubernetes-operator).
* To learn more about the Oracle SOA Suite architecture and components, see [Understanding Oracle SOA Suite](https://docs.oracle.com/en/middleware/soa-suite/soa/12.2.1.4/concepts/overview.html).
* To understand the known issues and common questions for Oracle SOA Suite domains deployment on Kubernetes, see the  [frequently asked questions]({{< relref "/soa-domains/faq.md" >}}).
