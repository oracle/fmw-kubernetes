---
title: "Introduction"
weight: 1
pre : "<b>1. </b>"
description: "The WebLogic Kubernetes Operator supports deployment of Oracle Identity Governance. Follow the instructions in this guide to set up Oracle Identity Governance domains on Kubernetes."
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

The current production release for the Oracle Identity Governance domain deployment on Kubernetes is [23.4.1](https://github.com/oracle/fmw-kubernetes/releases). This release uses the WebLogic Kubernetes Operator version 4.1.2.

For 4.0.X WebLogic Kubernetes Operator refer to [Version 23.3.1](https://oracle.github.io/fmw-kubernetes/23.3.1/idm-products/oig/)

For 3.4.X WebLogic Kubernetes Operator refer to [Version 23.1.1](https://oracle.github.io/fmw-kubernetes/23.1.1/idm-products/oig/)

### Recent changes and known issues

See the [Release Notes](../release-notes) for recent changes and known issues for Oracle Identity Governance domain deployment on Kubernetes.

### Limitations

See [here](../prerequisites#limitations) for limitations in this release.

### Getting started

This documentation explains how to configure OIG on a Kubernetes cluster where no other Oracle Identity Management products will be deployed. For detailed information about this type of deployment, start at [Prerequisites](../prerequisites) and follow this documentation sequentially. Please note that this documentation does not explain how to configure a Kubernetes cluster given the product can be deployed on any compliant Kubernetes vendor.

If you are deploying multiple Oracle Identity Management products on the same Kubernetes cluster, then you must follow the Enterprise Deployment Guide outlined in [Enterprise Deployments](../../enterprise-deployments). 
Please note, you also have the option to follow the Enterprise Deployment Guide even if you are only installing OIG and no other Oracle Identity Management products.

**Note**: If you need to understand how to configure a Kubernetes cluster ready for an Oracle Identity Governance deployment, you should follow the Enterprise Deployment Guide referenced in [Enterprise Deployments](../../enterprise-deployments). The [Enterprise Deployment Automation](../../enterprise-deployments/enterprise-deployment-automation) section also contains details on automation scripts that can:

   + Automate the creation of a Kubernetes cluster on Oracle Cloud Infrastructure (OCI), ready for the deployment of Oracle Identity Management products. 
   + Automate the deployment of Oracle Identity Management products on any compliant Kubernetes cluster.

### Documentation for earlier releases

To view documentation for an earlier release, see:

* [Version 23.3.1](https://oracle.github.io/fmw-kubernetes/23.3.1/idm-products/oig/)
* [Version 23.2.1](https://oracle.github.io/fmw-kubernetes/23.2.1/idm-products/oig/)
* [Version 23.1.1](https://oracle.github.io/fmw-kubernetes/23.1.1/idm-products/oig/)
* [Version 22.4.1](https://oracle.github.io/fmw-kubernetes/22.4.1/oig/)
* [Version 22.3.1](https://oracle.github.io/fmw-kubernetes/22.3.1/oig/)
* [Version 22.2.1](https://oracle.github.io/fmw-kubernetes/22.2.1/oig/)
* [Version 21.4.2](https://oracle.github.io/fmw-kubernetes/21.4.2/oig/)
* [Version 21.4.1](https://oracle.github.io/fmw-kubernetes/21.4.1/oig/)
