### Oracle WebCenter Content on Kubernetes

WebLogic Kubernetes Operator (the “operator”) supports deployment of Oracle WebCenter Content servers such as Oracle WebCenter Content Server and Oracle WebCenter Inbound Refinery Server.

***
The current supported production release is [22.4.1](https://github.com/oracle/fmw-kubernetes/releases).
***

In this release, Oracle WebCenter Content domain is supported using the “domain on a persistent volume”
[model](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/choosing-a-model/) only, where the domain home is located in a persistent volume (PV).

The WebLogic Kubernetes Operator has several key features to assist you with deploying and managing Oracle WebCenter Content domain in a Kubernetes environment. You can:

* Create Oracle WebCenter Content instances in a Kubernetes persistent volume (PV). This PV can reside in an NFS file system or other Kubernetes volume types.
* Start servers based on declarative startup parameters and desired states.
* Expose the Oracle WebCenter Content services for external access.
* Scale Oracle WebCenter Content domain by starting and stopping Managed Servers on demand, or by integrating with a REST API to initiate scaling based on WLDF, Prometheus, Grafana, or other rules.
* Publish WebLogic Kubernetes Operator and WebLogic Server logs to Elasticsearch and interact with them in Kibana.
* Monitor the Oracle WebCenter Content instance using Prometheus and Grafana.

#### Getting started

Refer the following documentation link for detailed information about deploying Oracle WebCenter Content domain on Kubernetes.  
[Documentation](https://oracle.github.io/fmw-kubernetes/wccontent-domains/)

