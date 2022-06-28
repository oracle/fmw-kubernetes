---
title: "Oracle WebCenter Portal"
date: 2021
weight: 8
description: "The WebLogic Kubernetes operator (the “operator”) supports deployment of Oracle WebCenter Portal. Follow the instructions in this guide to set up Oracle WebCenter Portal domain on Kubernetes."
---


With the WebLogic Kubernetes operator (operator), you can deploy your Oracle WebCenter Portal on Kubernetes.

In this release, Oracle WebCenter Portal domain is based on the “domain on a persistent volume”
[model](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/choosing-a-model/), where the domain home is located in a persistent volume. 

In this release the support for Portlet Managed Server has been added. 

The operator has several key features to assist you with deploying and managing the Oracle WebCenter Portal domain in a Kubernetes environment. You can:

* Create Oracle WebCenter Portal instances in a Kubernetes PV. This PV can reside in an Network File System (NFS) or other Kubernetes volume types.
* Start servers based on declarative startup parameters and desired states.
* Expose the Oracle WebCenter Portal services for external access.
* Scale Oracle WebCenter Portal domain by starting and stopping Managed Servers on demand, or by integrating with a REST API.
* Publish operator and WebLogic Server logs to Elasticsearch and interact with them in Kibana.
* Monitor the Oracle WebCenter Portal instance using Prometheus and Grafana.
#### Current release

The current release for the Oracle WebCenter Portal domain deployment on Kubernetes is [22.2.3](https://github.com/oracle/fmw-kubernetes/releases/tag/v22.2.3). This release uses the WebLogic Kubernetes Operator version [3.3.0](https://github.com/oracle/weblogic-kubernetes-operator/releases/tag/v3.3.0).

>Note that this release is only for evaluation purposes and hence applicable to Development and Test deployments only.

#### Recent changes and known issues

See the [Release Notes]({{< relref "/wcportal-domains/release-notes.md" >}}) for recent changes and known issues with the Oracle WebCenter Portal domain deployment on Kubernetes.


#### About this documentation

This documentation includes sections targeted to different audiences. To help you find what you are looking for more easily,
please use this table of contents:

* [Quick Start]({{< relref "/wcportal-domains/appendix/quickstart-deployment-on-prem.md" >}}) explains how to quickly get an Oracle WebCenter Portal domain instance running, using the defaults, nothing special. Note that this is only for development and test purposes.
* [Install Guide]({{< relref "/wcportal-domains/installguide" >}}) and [Administration Guide]({{< relref "/wcportal-domains/manage-wcportal-domains/" >}}) provide detailed information about all aspects of using the Kubernetes operator including:

   * Installing and configuring the operator
   * Using the operator to create and manage Oracle WebCenter Portal domain
   * Configuring WebCenter Portal for Search
   * Configuring Kubernetes load balancers
   * Configuring Prometheus and Grafana to monitor WebCenter Portal
   * Configuring Logging using ElasticSearch

#### Documentation for earlier releases

To view documentation for an earlier release, see:

* [Version 21.2.3](https://oracle.github.io/fmw-kubernetes/21.2.3/wcportal-domains/)
