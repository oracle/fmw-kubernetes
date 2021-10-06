---
title: "Prerequisites"
weight: 2
pre : "<b>2. </b>"
description: "System requirements and limitations for deploying and running an OAM domain home"
---

### Introduction

This document provides information about the system requirements and limitations for deploying and running OAM domains with the WebLogic Kubernetes Operator 3.0.1.

In this release, OAM domains are supported using the “domain on a persistent volume”
[model](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/choosing-a-model/) only, where the domain home is located in a persistent volume (PV).

### System requirements for oam domains


* A running Kubernetes cluster with Helm and Docker installed. For the minimum version requirements refer to document ID 2723908.1 on [My Oracle Support](https://support.oracle.com).
* You must have the `cluster-admin` role to install the operator.
* We do not currently support running OAM in non-Linux containers.
* A running Oracle Database 12.2.0.1 or later. The database must be a supported version for OAM as outlined in [Oracle Fusion Middleware 12c certifications](https://www.oracle.com/technetwork/middleware/fmw-122140-certmatrix-5763476.xlsx). It must meet the requirements as outlined in [About Database Requirements for an Oracle Fusion Middleware Installation](http://www.oracle.com/pls/topic/lookup?ctx=fmw122140&id=GUID-4D3068C8-6686-490A-9C3C-E6D2A435F20A) and in [RCU Requirements for Oracle Databases](http://www.oracle.com/pls/topic/lookup?ctx=fmw122140&id=GUID-35B584F3-6F42-4CA5-9BBB-116E447DAB83).

### Limitations

Compared to running a WebLogic Server domain in Kubernetes using the operator, the
following limitations currently exist for OAM domains:

* The "domain in image" model is not supported.
* Only configured clusters are supported.  Dynamic clusters are not supported for
  OAM domains.  Note that you can still use all of the scaling features,
  you just need to define the maximum size of your cluster at domain creation time.
* Deploying and running OAM domains is supported only with WebLogic Kubernetes Operator version 3.0.1
* The [WebLogic Monitoring Exporter](https://github.com/oracle/weblogic-monitoring-exporter)
  currently supports the WebLogic MBean trees only.  Support for JRF MBeans has not
  been added yet.

