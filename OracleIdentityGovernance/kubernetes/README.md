## Oracle Identity Governance (OIG) on Kubernetes

The Oracle WebLogic Server Kubernetes Operator (the “operator”) supports deployment of Oracle Identity Governance.

In this release, OIG domains are supported using the “domain on a persistent volume” model only, where the domain home is located in a persistent volume (PV).

The operator has several key features to assist you with deploying and managing OIG domains in a Kubernetes environment. You can:

* Create OIG instances in a Kubernetes persistent volume. This persistent volume can reside in an NFS file system or other Kubernetes volume types.
* Start servers based on declarative startup parameters and desired states.
* Expose the OIG Services for external access.
* Scale OIG domains by starting and stopping Managed Servers on demand.
* Publish operator and WebLogic Server logs into Elasticsearch and interact with them in Kibana.
* Monitor the OIG instance using Prometheus and Grafana.

### Getting Started

For detailed information about deploying OIG on Kubernetes refer to the [Oracle Identity Governance on Kubernetes](https://oracle.github.io/fmw-kubernetes/oig/) documentation.

## Copyright
Copyright (c) 2020, Oracle and/or its affiliates.