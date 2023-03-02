---
title: "Requirements and limitations"
date: 2019-04-18T07:32:31-05:00
weight: 1
pre : "<b>  </b>"
description: "Understand the system requirements and limitations for deploying and running Oracle SOA Suite domains with the WebLogic Kubernetes Operator, including the SOA cluster sizing recommendations."
---

This section provides information about the system requirements and limitations for deploying and running Oracle SOA Suite domains with the WebLogic Kubernetes Operator.

### System requirements for Oracle SOA Suite domains

For the current production release 23.1.2:

* Operating systems supported:
  * Oracle Linux 7 (UL6+)
  * Red Hat Enterprise Linux 7 (UL3+ only with standalone Kubernetes)
  * Oracle Linux Cloud Native Environment (OLCNE) version 1.5.
* Kubernetes 1.21.10+, 1.22.7+, 1.23.4+, 1.24.0+, and 1.25.0+ (check with `kubectl version`).
* Docker 19.03.1+ (check with `docker version`) or CRI-O 1.20.2+ (check with `crictl version | grep RuntimeVersion`).
* Flannel networking v0.13.0-amd64 or later (check with `docker images | grep flannel`), Calico networking v3.16.1 or later.
* Helm 3.10.2+ (check with `helm version --client --short`).
* WebLogic Kubernetes Operator 4.0.4 (see the [operator releases 4.0.x](https://github.com/oracle/weblogic-kubernetes-operator/releases/tag/v4.0.0) pages).
* You must have the `cluster-admin` role to install the operator. The operator does not need the `cluster-admin` role at runtime.
  For more information, see the role-based access control (RBAC) [documentation](https://oracle.github.io/weblogic-kubernetes-operator/security/rbac/).
* We do not currently support running SOA in non-Linux containers.
* Additionally, see the Oracle SOA Suite [documentation](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/insoa/preparing-install-and-configure-product.html#GUID-E2D4D481-BE80-4600-8078-FD9C03A30210) for other requirements such as database version.

See [here]({{< relref "/soa-domains/appendix/soa-cluster-sizing-info.md" >}}) for resource sizing information for Oracle SOA Suite domains set up on a Kubernetes cluster.

### Limitations

Compared to running a WebLogic Server domain in Kubernetes using the operator, the
following limitations currently exist for Oracle SOA Suite domains:

* In this release, Oracle SOA Suite domains are supported using the
[domain on a persistent volume model](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/choosing-a-model/) only, where the domain home is located in a persistent volume (PV).
* The "domain in image" and "model in image" models are not supported. Also, "WebLogic Deploy Tooling (WDT)" based deployments are currently not supported.   
* Only configured clusters are supported.  Dynamic clusters are not supported for
  Oracle SOA Suite domains.  Note that you can still use all of the scaling features,
  but you need to define the maximum size of your cluster at domain creation time. Mixed clusters (configured servers targeted to a dynamic cluster) are not supported.
* The [WebLogic Logging Exporter](https://github.com/oracle/weblogic-logging-exporter) project has been archived. Users are encouraged to use Fluentd or Logstash.
* The [WebLogic Monitoring Exporter](https://github.com/oracle/weblogic-monitoring-exporter) currently supports WebLogic MBean trees only. Support for JRF and Oracle SOA Suite MBeans is not available. Also, a metrics dashboard specific to Oracle SOA Suite is not available. Instead, use the WebLogic Server dashboard to monitor the Oracle SOA Suite server metrics in Grafana.
* Some features such as multicast, multitenancy, production redeployment, and Node Manager (although it is used internally for the liveness probe and to start WebLogic Server instances) are not supported in this release.
* Features such as Java Messaging Service whole server migration and consensus leasing are not supported in this release.
* Maximum availability architecture (Oracle SOA Suite EDG setup) is available for preview.
* Enabling or disabling the memory resiliency for Oracle Service Bus using the Enterprise Manager Console is not supported in this release.
* Zero downtime upgrade (ZDT) of the domain is not supported.

For up-to-date information about the features of WebLogic Server that are supported in Kubernetes environments, see My Oracle Support Doc ID 2349228.1.
