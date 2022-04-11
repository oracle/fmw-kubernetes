---
title: "Oracle WebCenter Content"
date: 2020-11-27T16:43:45-05:00
weight: 7
description: "WebLogic Kubernetes Operator (the “operator”) supports deployment of Oracle WebCenter Content servers such as Oracle WebCenter Content(Content Server) and Oracle WebCenter Content(Inbound Refinery Server). Follow the instructions in this guide to set up Oracle WebCenter Content domain on Kubernetes."
---


In this release, Oracle WebCenter Content domain is supported using the “domain on a persistent volume”
[model](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/choosing-a-model/) only, where the domain home is located in a persistent volume (PV).

The WebLogic Kubernetes Operator has several key features to assist you with deploying and managing Oracle WebCenter Content domain in a Kubernetes environment. You can:

* Create Oracle WebCenter Content instances(Oracle WebCenter Content server & Oracle WebCenter Content Inbounnd Refinery server) in a Kubernetes persistent volume (PV). This PV can reside in an NFS file system or other Kubernetes volume types.
* Start servers based on declarative startup parameters and desired states.
* Expose the Oracle WebCenter Content services and composites for external access.
* Scale Oracle WebCenter Content domains by starting and stopping Managed Servers on demand, or by integrating with a REST API.
* Publish WebLogic Kubernetes Operator and WebLogic Server logs to Elasticsearch and interact with them in Kibana.
* Monitor the Oracle WebCenter Content instance using Prometheus and Grafana.

#### Current production release

The current supported production release of WebLogic Kubernetes Operator, for Oracle WebCenter Content domain deployment is [3.3.0](https://github.com/oracle/weblogic-kubernetes-operator/releases/tag/v3.3.0).

#### Recent changes

See the [Release Notes]({{< relref "/wccontent-domains/release-notes.md" >}}) for recent changes for Oracle WebCenter Content domain deployment on Kubernetes.

#### Limitations

See [here]({{< relref "/wccontent-domains/installguide/prerequisites#limitations">}}) for limitations in this release.

#### About this documentation

This documentation includes sections targeted to different audiences. To help you find what you are looking for easily,
please consult this table of contents:

* [Quick Start]({{< relref "/wccontent-domains/appendix/quickstart-deployment-guide.md" >}}) explains how to quickly get an Oracle WebCenter Content instance running, using the defaults. Note that this is only for development and test purposes.
* [Install Guide]({{< relref "/wccontent-domains/installguide/_index.md" >}}) and [Administration Guide]({{< relref "/wccontent-domains/adminguide/" >}}) provide detailed information about all aspects of using WebLogic Kubernetes Operator including:

   * Installing and configuring WebLogic Kubernetes Operator.
   * Using WebLogic Kubernetes Operator to create and manage Oracle WebCenter Content domain.
   * Configuring Kubernetes load balancers.
   * Configuring Custom SSL certificates.
   * Configuring Elasticsearch and Kibana to access the WebLogic Kubernetes Operator and WebLogic Server log files.
   * Deploying composite applications for Oracle WebCenter Content.
   * Patching an Oracle WebCenter Content Docker image.
   * Removing/deleting domain.
   * And much more!


#### Additional reading

Oracle WebCenter Content domain deployment on Kubernetes leverages WebLogic Kubernetes Operator framework.
* To develop an understanding of WebLogic Kubernetes Operator, including design, architecture, domain life cycle management, and configuration overrides, review the [WebLogic Kubernetes Operator documentation](https://oracle.github.io/weblogic-kubernetes-operator).
* To learn more about the Oracle WebCenter Content architecture and components, see [Understanding Oracle WebCenter Content](https://docs.oracle.com/en/middleware/webcenter/content/12.2.1.4/index.html).
