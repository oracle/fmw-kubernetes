---
title: "Release Notes"
weight: 2
pre: "<b>2. </b>"
---

Review the latest changes and known issues for Oracle Unified Directory on Kubernetes.

### Recent changes

| Date | Version | Change |
| --- | --- | --- |
| January, 2024 | 24.1.1 | Supports Oracle Unified Directory 12.2.1.4 domain deployment using the January 2024 container image which contains the January Patch Set Update (PSU) and other fixes released with the Critical Patch Update (CPU) program.|
| | | To upgrade to January 24 (24.1.1) you must follow the instructions in [Patch and Upgrade](../patch-and-upgrade).| 
| October, 2023 | 23.4.1 | Supports Oracle Unified Directory 12.2.1.4 domain deployment using the October 2023 container image which contains the October Patch Set Update (PSU) and other fixes released with the Critical Patch Update (CPU) program.|
| | | + Support for Block Device Storage. See, [Create OUD Instances](../create-oud-instances#using-a-yaml-file).|
| | | + Ability to set resource requests and limits for CPU and memory on an OUD instance. See, [Create OUD Instances](../create-oud-instances#using-a-yaml-file). |
| | | + Support for Assured Replication. See, [Create OUD Instances](../create-oud-instances#using-a-yaml-file).|
| | | + Support for the Kubernetes Horizontal Pod Autoscaler (HPA). See, [Kubernetes Horizontal Pod Autoscaler](../manage-oud-containers/hpa).|
| | | + Supports integration options such as Enterprise User Security (EUS), EBusiness Suite (EBS), and Directory Integration Platform (DIP).
| | | To upgrade to October 23 (23.4.1) you must follow the instructions in [Patch and Upgrade](../patch-and-upgrade).| 
| July, 2023 | 23.3.1 | Supports Oracle Unified Directory 12.2.1.4 domain deployment using the July 2023 container image which contains the July Patch Set Update (PSU) and other fixes released with the Critical Patch Update (CPU) program.|
| | | To upgrade to July 23 (23.3.1) you must follow the instructions in [Patch and Upgrade](../patch-and-upgrade).| 
| April, 2023 | 23.2.1 | Supports Oracle Unified Directory 12.2.1.4 domain deployment using the April 2023 container image which contains the April Patch Set Update (PSU) and other fixes released with the Critical Patch Update (CPU) program.|
| | | To upgrade to April 23 (23.2.1) you must follow the instructions in [Patch and Upgrade](../patch-and-upgrade).| 
| January, 2023 | 23.1.1 | Supports Oracle Unified Directory 12.2.1.4 domain deployment using the January 2023 container image which contains the January Patch Set Update (PSU) and other fixes released with the Critical Patch Update (CPU) program.|
| October, 2022 | 22.4.1 | Supports Oracle Unified Directory 12.2.1.4 domain deployment using the October 2022 container image which contains the October Patch Set Update (PSU) and other fixes released with the Critical Patch Update (CPU) program.|
| | | Changes to deployment of Logging and Visualization with Elasticsearch and Kibana.
| | | OUD container images are now only available from [container-registry.oracle.com](https://container-registry.oracle.com) and are no longer available from My Oracle Support.| 
| July, 2022 | 22.3.1 | Supports Oracle Unified Directory 12.2.1.4 domain deployment using the July 2022 container image which contains the July Patch Set Update (PSU) and other fixes released with the Critical Patch Update (CPU) program. From July 2022 onwards OUD deployment is performed using [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/). |
| April, 2022 | 22.2.1 | Updated for CRI-O support.|
| November 2021 | 21.4.2 | Voyager ingress removed as no longer supported.|
| October 2021 | 21.4.1 | **A**) References to supported Kubernetes, Helm and Docker versions removed and replaced with Support note reference. **B**) Namespace and domain names changed to be consistent with [Enterprise Deployment Guide for Oracle Identity and Access Management in a Kubernetes Cluster](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/). **C**) *Upgrading a Kubernetes Cluster* and *Security Hardening* removed as vendor specific.|
| November 2020 | 20.4.1 | Initial release of Oracle Unified Directory on Kubernetes.|

