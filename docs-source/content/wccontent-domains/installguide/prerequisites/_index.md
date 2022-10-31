---
title: "Requirements and limitations"
date: 2020-12-3T07:32:31-05:00
weight: 1
pre : "<b>  </b>"
description: "Understand the system requirements and limitations for deploying and running Oracle WebCenter Content with the WebLogic Kubernetes Operator, including the Oracle WebCenter Content cluster sizing recommendations."
---

This section provides information about the system requirements and limitations for deploying and running Oracle WebCenter Content domains with the WebLogic Kubernetes Operator.

### System requirements for Oracle WebCenter Content domains

For the current production release 22.4.1:

* Oracle Linux 7 (UL6+) and Red Hat Enterprise Linux 7 (UL3+ only with standalone Kubernetes) are supported.
* Supported Kubernetes versions are: 1.19.15+, 1.20.11+, 1.21.5+, 1.22.5+ and 1.23.4+ (check with `kubectl version`).
* Docker 19.03.1+ (check with `docker version`).
* Flannel networking v0.13.0-amd64 or later (check with `docker images | grep flannel`).
* Helm 3.3.4+ (check with `helm version --client --short`).
* Oracle WebLogic Kubernetes Operator 3.4.2 (see [WebLogic Kubernetes Operator releases](https://github.com/oracle/weblogic-kubernetes-operator/releases) page).
* Oracle WebCenter Content 12.2.1.4 Docker image downloaded from My Oracle Support (MOS patch [34409720](https://support.oracle.com/epmos/faces/ui/patch/PatchDetail.jspx?patchId=34409720)). This image contains the latest bundle patch and one-off patches for Oracle WebCenter Content.
* You must have the `cluster-admin` role to install WebLogic Kubernetes Operator. The WebLogic Kubernetes Operator does not need the `cluster-admin` role at runtime.
* We do not currently support running Oracle WebCenter Content in non-Linux containers.
* Additionally, see the Oracle WebCenter Content [documentation](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/inecm/preparing-install-and-configure-product.html#GUID-16F78BFD-4095-45EE-9C3B-DB49AD5CBAAD) for other requirements such as database version.

See [here]({{< relref "/wccontent-domains/appendix/wcc-cluster-sizing-info.md" >}}) for resourse sizing information for Oracle WebCenter Content domains setup on Kubernetes cluster.

### Limitations

Compared to running a WebLogic Server domain in Kubernetes using the WebLogic Kubernetes Operator, the
following limitations currently exist for Oracle WebCenter Content domains:

* In this release, Oracle WebCenter Content domains are supported using the
[domain on a persistent volume model](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/choosing-a-model/) only, where the domain home is located in a persistent volume (PV).
* The "domain in image" and "model in image" models are not supported. Also, "WebLogic Deploy Tooling (WDT)" based deployments are currently not supported.   
* Only configured clusters are supported.  Dynamic clusters are not supported for
  Oracle WebCenter Content domains.  Note that you can still use all of the scaling features,
  but you need to define the maximum size of your cluster at domain creation time. Mixed clusters (configured servers targeted to a dynamic cluster) are not supported.
* The [WebLogic Logging Exporter](https://github.com/oracle/weblogic-logging-exporter)
  currently supports WebLogic Server logs only.  Other logs will not be sent to
  Elasticsearch.  Note, however, that you can use a sidecar with a log handling tool
  like Logstash or Fluentd to get logs.
* The [WebLogic Monitoring Exporter](https://github.com/oracle/weblogic-monitoring-exporter)
  currently supports WebLogic MBean trees only. Support for JRF and Oracle WebCenter Content MBeans is not available. Also, a metrics dashboard specific to Oracle WebCenter Content is not available. Instead, use the WebLogic Server dashboard to monitor the Oracle WebCenter Content server metrics in Grafana.
* Some features such as multicast, multitenancy, production redeployment, and Node Manager (although it is used internally for the liveness probe and to start WebLogic Server instances) are not supported in this release.
* Features such as Java Messaging Service whole server migration, consensus leasing, and maximum availability architecture (Oracle WebCenter Content setup) are not supported in this release.
* You can have multiple UCM servers on your domain but you can have only one IBR server.
* There is a generic limitation with all load-balancers in end-to-end SSL configuration - accessing multiple types of servers (different Managed Servers and/or Administration Server) at the same time, is currently not supported.

For up-to-date information about the features of WebLogic Server that are supported in Kubernetes environments, see My Oracle Support Doc ID 2349228.1.
