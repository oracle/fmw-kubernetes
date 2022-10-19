---
title: "Release Notes"
weight: 1
pre: "<b>1. </b>"
---

Review the latest changes and known issues for Oracle Access Management on Kubernetes.

### Recent changes

| Date | Version | Change |
| --- | --- | --- |
| October, 2022 | 22.4.1 | Supports Oracle Access Management 12.2.1.4 domain deployment using the October 2022 container image which contains the October Patch Set Update (PSU) and other fixes released with the Critical Patch Update (CPU) program.|
| | | Support for WebLogic Kubernetes Operator 3.4.2.|
| | | Additional Ingress mappings added.|
| | | Changes to deployment of Logging and Visualization with Elasticsearch and Kibana.|
| | | OAM container images are now only available from [container-registry.oracle.com](https://container-registry.oracle.com) and are no longer available from My Oracle Support.|
| | | If upgrading to October 22 (22.4.1) from a previous release, you must upgrade the following in order:
| | | 1. WebLogic Kubernetes Operator to 3.4.2|
| | | 2. Patch the OAM container image to October 22|
| | | 3. Upgrade the Ingress|
| | | 4. Upgrade Elasticsearch and Kibana <br><br>See [Patch and Upgrade](../patch-and-upgrade) for these instructions.|
| July, 2022 | 22.3.1 | Supports Oracle Access Management 12.2.1.4 domain deployment using the July 2022 container image which contains the July Patch Set Update (PSU) and other fixes released with the Critical Patch Update (CPU) program.|
| April, 2022 | 22.2.1 | Updated for CRI-O support.|
| November, 2021 | 21.4.2 | Supports Oracle Access Management domain deployment using WebLogic Kubernetes Operator 3.3.0. Voyager ingress removed as no longer supported.|
| October 2021 | 21.4.1 | **A**) References to supported Kubernetes, Helm and Docker versions removed and replaced with Support note reference. **B**) Namespace and domain names changed to be consistent with [Enterprise Deployment Guide for Oracle Identity and Access Management in a Kubernetes Cluster](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/). **C**) Additional post configuration tasks added. **D**) *Upgrading a Kubernetes Cluster* and *Security Hardening* removed as vendor specific.|
| November 2020 | 20.4.1 | Initial release of Oracle Access Management on Kubernetes.|

