---
title: "Introduction"
weight: 1
pre : "<b>1. </b>"
description: "The WebLogic Kubernetes Operator supports deployment of Oracle Access Management (OAM). Follow the instructions in this guide to set up these Oracle Access Management domains on Kubernetes."
---

The WebLogic Kubernetes Operator supports deployment of Oracle Access Management (OAM).

In this release, OAM domains are supported using the “domain on a persistent volume”
[model](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/choosing-a-model/) only, where the domain home is located in a persistent volume (PV).

Domain on persistent volume (Domain on PV) is an operator [domain home source type](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/choosing-a-model/), which requires that the domain home exists on a persistent volume. The domain home can be created either using the Weblogic Scripting Tool (WLST) scripts or Weblogic Deploy Tooling (WDT) model files by specifying the section domain.spec.configuration.initializeDomainOnPV, in the domain resource YAML file. The initial domain topology and resources are described using [WebLogic Deploy Tooling (WDT) models](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/overview/#weblogic-deploy-tooling-models).

NOTE: The initializeDomainOnPV section provides a one time only domain home initialization. The operator creates the domain when the domain resource is first deployed. After the domain is created, this section is ignored. Subsequent domain lifecycle updates must be controlled by the WebLogic Server Administration Console, the WebLogic Remote Console, WebLogic Scripting Tool (WLST), or other mechanisms.

The WebLogic Kubernetes Operator has several key features to assist you with deploying and managing Oracle Access Management domains in a Kubernetes
environment. You can:


* Create OAM instances in a Kubernetes persistent volume. This persistent volume can reside in an NFS file system or other Kubernetes volume types.
* Start servers based on declarative startup parameters and desired states.
* Expose the OAM Services through external access.
* Scale OAM domains by starting and stopping Managed Servers on demand.
* Publish operator and WebLogic Server logs into Elasticsearch and interact with them in Kibana.
* Monitor the OAM instance using Prometheus and Grafana.

### Weblogic Deploy Tooling Models

Weblogic Deploy Tooling (WDT) models are a convenient and simple alternative to WLST configuration scripts. They compactly define a WebLogic domain using model files, variable properties files, and application archive files. For more information about the model format and its integration, see [Usage](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/usage/) and [Working With WDT Model Files](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/model-files/). The WDT model format is fully described in the open source, [WebLogic Deploy Tooling GitHub project](https://oracle.github.io/weblogic-deploy-tooling/).

The main benefits of WDT are:

   + A set of single-purpose tools supporting Weblogic domain configuration lifecycle operations.
   + All tools work off of a shared, declarative model, eliminating the need to maintain specialized WLST scripts.
   + WDT knowledge base understands the MBeans, attributes, and WLST capabilities/bugs across WLS versions.

### Current production release

The current production release for the Oracle Access Management domain deployment on Kubernetes is [23.4.2](https://github.com/oracle/fmw-kubernetes/releases). This release uses the WebLogic Kubernetes Operator version 4.1.2.

For 4.0.X WebLogic Kubernetes Operator refer to [Version 23.3.1](https://oracle.github.io/fmw-kubernetes/23.3.1/idm-products/oam/)

For 3.4.X WebLogic Kubernetes Operator refer to [Version 23.1.1](https://oracle.github.io/fmw-kubernetes/23.1.1/idm-products/oam/)

### Recent changes and known issues

See the [Release Notes](../release-notes/) for recent changes and known issues for Oracle Access Management domain deployment on Kubernetes.

### Limitations

See [here](../prerequisites/#limitations) for limitations in this release.

### Getting started

This documentation explains how to configure OAM on a Kubernetes cluster where no other Oracle Identity Management products will be deployed. For detailed information about this type of deployment, start at [Prerequisites](../prerequisites) and follow this documentation sequentially. Please note that this documentation does not explain how to configure a Kubernetes cluster given the product can be deployed on any compliant Kubernetes vendor.

If you are deploying multiple Oracle Identity Management products on the same Kubernetes cluster, then you must follow the Enterprise Deployment Guide outlined in [Enterprise Deployments](../../enterprise-deployments). 
Please note, you also have the option to follow the Enterprise Deployment Guide even if you are only installing OAM and no other Oracle Identity Management products.

**Note**: If you need to understand how to configure a Kubernetes cluster ready for an Oracle Access Management deployment, you should follow the Enterprise Deployment Guide referenced in [Enterprise Deployments](../../enterprise-deployments). The [Enterprise Deployment Automation](../../enterprise-deployments/enterprise-deployment-automation) section also contains details on automation scripts that can:

   + Automate the creation of a Kubernetes cluster on Oracle Cloud Infrastructure (OCI), ready for the deployment of Oracle Identity Management products. 
   + Automate the deployment of Oracle Identity Management products on any compliant Kubernetes cluster.



### Documentation for earlier releases

To view documentation for an earlier release, see:

* [Version 23.4.1](https://oracle.github.io/fmw-kubernetes/23.3.1/idm-products/oam/)
* [Version 23.3.1](https://oracle.github.io/fmw-kubernetes/23.3.1/idm-products/oam/)
* [Version 23.2.1](https://oracle.github.io/fmw-kubernetes/23.2.1/idm-products/oam/)
* [Version 23.1.1](https://oracle.github.io/fmw-kubernetes/23.1.1/idm-products/oam/)
* [Version 22.4.1](https://oracle.github.io/fmw-kubernetes/22.4.1/oam/)
* [Version 22.3.1](https://oracle.github.io/fmw-kubernetes/22.3.1/oam/)
* [Version 22.2.1](https://oracle.github.io/fmw-kubernetes/22.2.1/oam/)
* [Version 21.4.2](https://oracle.github.io/fmw-kubernetes/21.4.2/oam/)
* [Version 21.4.1](https://oracle.github.io/fmw-kubernetes/21.4.1/oam/)




