---
title: "Requirements and pricing"
date: 2019-04-18T07:32:31-05:00
weight: 1
pre : "<b>  </b>"
description: "Understand the system requirements, limitations, licensing, and pricing for deploying and running Oracle SOA Suite domains with the WebLogic Kubernetes Operator, including the SOA cluster sizing."
---

This section provides information about the system requirements, limitations, licensing, and pricing for deploying and running Oracle SOA Suite domains with the WebLogic Kubernetes Operator.

### System requirements for Oracle SOA Suite domains

Release 23.3.2 has the following system requirements:

* Kubernetes 1.23.4+, 1.24.0+, 1.25.0+ and 1.26.2+ (check with `kubectl version`).
* Docker 19.03.11+ (check with `docker version`) or CRI-O 1.20.2+ (check with `crictl version | grep RuntimeVersion`).
* Flannel networking v0.13.0-amd64 or later (check with `docker images | grep flannel`), Calico networking v3.16.1 or later.
* Helm 3.10.2+ (check with `helm version --client --short`).
* WebLogic Kubernetes Operator 4.1.0 (see the [operator releases 4.1.0](https://github.com/oracle/weblogic-kubernetes-operator/releases/tag/v4.1.0) pages).
* You must have the `cluster-admin` role to install the operator. The operator does not need the `cluster-admin` role at runtime.
  For more information, see the role-based access control (RBAC) [documentation](https://oracle.github.io/weblogic-kubernetes-operator/security/rbac/).
* We do not currently support running SOA in non-Linux containers.
* Container images based on Oracle Linux 8 are now supported. My Oracle Support and the Oracle Container Registry host container images based on both Oracle Linux 7 and 8.
* Additionally, see the Oracle SOA Suite [documentation](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/insoa/preparing-install-and-configure-product.html#GUID-E2D4D481-BE80-4600-8078-FD9C03A30210) for other requirements, such as database version.

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

### Pricing and licensing

The WebLogic Kubernetes Operator and Oracle Linux are open source and free; WebLogic Server requires licenses in any environment. All WebLogic Server licenses are suitable for deploying WebLogic to containers and Kubernetes, including free single desktop Oracle Technology Network (OTN) developer licenses. See the following sections for more detailed information:

- [Oracle SOA Suite](#oracle-soa-suite)
- [Oracle Linux](#oracle-linux)
- [Oracle Java](#oracle-java)
- [WebLogic Kubernetes Operator](#weblogic-kubernetes-operator)
- [Oracle SOA Suite images](#oracle-soa-suite-images)
- [Additional references](#additional-references)

#### Oracle SOA Suite

Oracle SOA Suite is licensed as an option to Oracle WebLogic Suite. Valid licenses are needed in at least one of the following combinations:
- WebLogic Suite and Oracle SOA Suite
- WebLogic Suite and Oracle Service Bus
- WebLogic Suite and Oracle BPEL Engine

For more information, see the [Fusion Middleware Licensing Information User Manual - Oracle SOA Suite](https://docs.oracle.com/en/middleware/fusion-middleware/fmwlc/oracle-fusion-middleware-options.html#GUID-19E4223F-1F98-433E-BC7C-2BAC2568964F) and the following sections.

#### Oracle Linux

Oracle Linux is under open source license and is completely free to download and use.

Note that Oracle SOA Suite licenses that include support do not include customer entitlements for direct access to Oracle Linux support or Unbreakable Linux Network (to directly access the standalone Oracle Linux patches). The latest Oracle Linux patches are included with the latest [Oracle SOA Suite images]().

#### Oracle Java

Oracle support for Java is included with Oracle SOA Suite licenses when Java is used for running WebLogic and Coherence servers or clients.

For more information, see the [Fusion Middleware Licensing Information User Manual](https://docs.oracle.com/en/middleware/fusion-middleware/fmwlc/oracle-fusion-middleware.html#GUID-4980E65A-22C8-429D-81C5-86223C362E78).

#### Oracle SOA Suite images

Oracle provides two different types of Oracle SOA Suite images:

- _Critical Patch Update (CPU) images:_
  Images with the latest Oracle SOA Suite, Fusion Middleware Infrastructure, Coherence PSUs, and other fixes released by the Critical Patch Update (CPU) program. CPU images are intended for production use.

- _General Availability (GA) images:_
  Images that are not intended for production use and do not include Oracle SOA Suite, WebLogic, Fusion Middleware Infrastructure, or Coherence PSUs.

All Oracle SOA Suite licenses, including free Oracle Technology Network (OTN) developer licenses, include access to the latest General Availability (GA) Oracle SOA Suite images, which bundle Java SE.

Customers with access to Oracle SOA Suite support additionally have:

- Access to Critical Patch Update (CPU) Oracle SOA Suite images, which bundle Java SE.
- Access to Oracle SOA Suite patches.
- Oracle support for Oracle SOA Suite images.

#### WebLogic Kubernetes Operator

The WebLogic Kubernetes Operator is open source and free, licensed under the Universal Permissive license (UPL), Version 1.0. For support details, see [Get help](https://oracle.github.io/weblogic-kubernetes-operator/introduction/get-help/).

#### Additional references

- [Supported Virtualization and Partitioning Technologies for Oracle Fusion Middleware](https://www.oracle.com/middleware/technologies/ias/oracleas-supported-virtualization.html) (search for keyword 'Kubernetes')
- [Running and Licensing Oracle Programs in Containers and Kubernetes](https://www.oracle.com/a/tech/docs/running-and-licensing-programs-in-containers-and-kubernetes.pdf)
