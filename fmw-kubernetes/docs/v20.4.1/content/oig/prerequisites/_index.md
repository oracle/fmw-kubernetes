---
title: "Prerequisites"
weight: 1
pre : "<b>1. </b>"
description: "Sample for creating an OIG Suite domain home on an existing PV or
PVC, and the domain resource YAML file for deploying the generated OIG domain."
---

### Introduction

This document provides information about the system requirements and limitations for deploying and running OIG domains with the Oracle WebLogic Kubernetes Operator 3.0.1.

In this release, OIG domains are supported using the “domain on a persistent volume”
[model](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/choosing-a-model/) only, where the domain home is located in a persistent volume (PV).

### System requirements for OIG domains

* Kubernetes 1.14.8+, 1.15.7+, 1.16.0+, 1.17.0+, and 1.18.0+ (check with `kubectl version`).
* Flannel networking v0.9.1-amd64 or later (check with `docker images | grep flannel`).
* Docker 18.9.1 or 19.03.1 (check with `docker version`).
* Helm 3.1.3+ (check with `helm version`).
* You must have the `cluster-admin` role to install the operator.
* We do not currently support running OIG in non-Linux containers.
* A running Oracle Database 12.2.0.1 or later. The database must be a supported version for OIG as outlined in [Oracle Fusion Middleware 12c certifications](https://www.oracle.com/technetwork/middleware/fmw-122140-certmatrix-5763476.xlsx). It must meet the requirements as outlined in [About Database Requirements for an Oracle Fusion Middleware Installation](http://www.oracle.com/pls/topic/lookup?ctx=fmw122140&id=GUID-4D3068C8-6686-490A-9C3C-E6D2A435F20A) and in [RCU Requirements for Oracle Databases](http://www.oracle.com/pls/topic/lookup?ctx=fmw122140&id=GUID-35B584F3-6F42-4CA5-9BBB-116E447DAB83).
* Java Developer Kit (11.0.3 or later recommended)

### Limitations

Compared to running a WebLogic Server domain in Kubernetes using the operator, the
following limitations currently exist for OIG domains:

* The "domain in image" model is not supported.
* Only configured clusters are supported.  Dynamic clusters are not supported for
  OIG domains.  Note that you can still use all of the scaling features,
  you just need to define the maximum size of your cluster at domain creation time.
* Deploying and running OIG domains is supported only with Oracle WebLogic Kubernetes Operator version 3.0.1
  currently supports the WebLogic MBean trees only.  
* The [WebLogic Monitoring Exporter](https://github.com/oracle/weblogic-monitoring-exporter)
  currently supports the WebLogic MBean trees only.  Support for JRF MBeans has not
  been added yet.


