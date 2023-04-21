---
title: "Release Notes"
weight: 2
pre: "<b>2. </b>"
---

Review the latest changes and known issues for Oracle Identity Governance on Kubernetes.

### Recent changes

| Date | Version | Change |
| --- | --- | --- |
| April, 2023 | 23.2.1 | Supports Oracle Identity Governance 12.2.1.4 domain deployment using the April 2023 container image which contains the April Patch Set Update (PSU) and other fixes released with the Critical Patch Update (CPU) program.|
| | | Support for WebLogic Kubernetes Operator 4.0.4.|
| | | Changes to stopping/starting pods due to domain and cluster configuration being separated and parameter changes (IF_NEEDED, NEVER to IfNeeded, Never).|
| | | If upgrading to April 23 (23.2.1) from October 22 (22.4.1) or later, you must upgrade in the following order:
| | | 1. WebLogic Kubernetes Operator to 4.0.4|
| | | 2. Patch the OIG container image to April 23|
| | | If upgrading to April 23 (23.2.1) from a release prior to October 22 (22.4.1), you must upgrade the following in order:
| | | 1. WebLogic Kubernetes Operator to 4.0.4|
| | | 2. Patch the OIG container image to April 23|
| | | 3. Upgrade the Ingress|
| | | 4. Upgrade Elasticsearch and Kibana <br><br>See [Patch and Upgrade](../patch-and-upgrade) for these instructions.|
| January, 2023 | 23.1.1 | Supports Oracle Identity Governance 12.2.1.4 domain deployment using the January 2023 container image which contains the January Patch Set Update (PSU) and other fixes released with the Critical Patch Update (CPU) program.|
| | | If upgrading to January 23 (23.1.1) from October 22 (22.4.1) release, you only need to patch the OIG container image to January 23.|
| | | If upgrading to January 23 (23.1.1) from a release prior to October 22 (22.4.1) release, you must upgrade the following in order:
| | | 1. WebLogic Kubernetes Operator to 3.4.2|
| | | 2. Patch the OIG container image to January 23|
| | | 3. Upgrade the Ingress|
| | | 4. Upgrade Elasticsearch and Kibana <br><br>See [Patch and Upgrade](../patch-and-upgrade) for these instructions.|
| October, 2022 | 22.4.1 | Supports Oracle Identity Governance 12.2.1.4 domain deployment using the October 2022 container image which contains the October Patch Set Update (PSU) and other fixes released with the Critical Patch Update (CPU) program.|
| | | Support for WebLogic Kubernetes Operator 3.4.2.|
| | | Additional Ingress mappings added.|
| | | Changes to deployment of Logging and Visualization with Elasticsearch and Kibana.
| | | OIG container images are now only available from [container-registry.oracle.com](https://container-registry.oracle.com) and are no longer available from My Oracle Support.|
| | | If upgrading to October 22 (22.4.1) from a previous release, you must upgrade the following in order:|
| | | 1. WebLogic Kubernetes Operator to 3.4.2|
| | | 2. Patch the OIG container image to October 22|
| | | 3. Upgrade the Ingress|
| | | 4. Upgrade Elasticsearch and Kibana |
| | | See [Patch and Upgrade](../patch-and-upgrade) for these instructions.| 
| July, 2022 | 22.3.1 | Supports Oracle Identity Governance 12.2.1.4 domain deployment using the July 2022 container image which contains the July Patch Set Update (PSU) and other fixes released with the Critical Patch Update (CPU) program.|
| April, 2022 | 22.2.1 | Updated for CRI-O support.|
| November, 2021 | 21.4.2 | Supports Oracle Identity Governance domain deployment using WebLogic Kubernetes Operator 3.3.0. Voyager ingress removed as no longer supported.|
| October 2021 | 21.4.1 | **A**) References to supported Kubernetes, Helm and Docker versions removed and replaced with Support note reference. **B**) Namespace and domain names changed to be consistent with [Enterprise Deployment Guide for Oracle Identity and Access Management in a Kubernetes Cluster](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/). **C**) Addtional post configuration tasks added. **D**) New section on how to start Design Console in a container. **E**) *Upgrading a Kubernetes Cluster* and *Security Hardening* removed as vendor specific.|
| November 2020 | 20.4.1 | Initial release of Identity Governance on Kubernetes.|

