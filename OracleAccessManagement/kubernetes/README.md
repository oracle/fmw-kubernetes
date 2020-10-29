## Oracle Access Management (OAM) on Kubernetes

The Oracle WebLogic Server Kubernetes Operator (the "operator") supports deployment of Oracle Access Management.

In this release, OAM domains are supported using the "domain on a persistent volume" model only, where the domain home is located in a persistent volume (PV).

The operator has several key features to assist you with deploying and managing OAM domains in a Kubernetes environment. You can:

* Create OAM instances in a Kubernetes persistent volume. This persistent volume can reside in an NFS file system or other Kubernetes volume types.
* Start servers based on declarative startup parameters and desired states.
* Expose the OAM Services for external access.
* Scale OAM domains by starting and stopping Managed Servers on demand.
* Publish operator and WebLogic Server logs into Elasticsearch and interact with them in Kibana.
* Monitor the OAM instance using Prometheus and Grafana.

### Getting Started

For detailed information about deploying OAM on Kubernetes refer to the [Oracle Access Management on Kubernetes](https://oracle.github.io/fmw-kubernetes/oam/) documentation.
