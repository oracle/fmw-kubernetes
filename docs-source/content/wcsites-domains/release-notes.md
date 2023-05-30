---
title: "Release Notes"
date: 2019-03-15T11:25:28-04:00
draft: false
weight: 1
pre: "<b>1. </b>"
---

Review the latest changes and known issues for Oracle WebCenter Sites on Kubernetes.

### Recent changes

| Date | Version | Introduces backward incompatibilities | Change |
| --- | --- | --- | --- |
| May 10, 2023 | 23.2.2 | no | Supports Oracle WebCenter Sites 12.2.1.4 domains deployment using April 2023 PSU and known bug fixes - certified for Oracle WebLogic Kubernetes Operator version 4.0.6. Oracle WebCenter Sites 12.2.1.4 container image for this release can be downloaded from My Oracle Support (MOS patch [35370108](https://support.oracle.com/epmos/faces/ui/patch/PatchDetail.jspx?patchId=35370108)) and [container-registry.oracle.com](https://container-registry.oracle.com/).
| May 30, 2022 | 22.2.2 | no | Supports Oracle WebCenter Sites 12.2.1.4 domains deployment using April 2022 PSU and known bug fixes - certified for Oracle WebLogic Kubernetes Operator version 3.3.0. Oracle WebCenter Sites 12.2.1.4 container image for this release can be downloaded from My Oracle Support (MOS patch [34223930](https://support.oracle.com/epmos/faces/ui/patch/PatchDetail.jspx?patchId=34223930)).
| Dec 10, 2021 | 21.4.3 | no | Certified Oracle WebLogic Kubernetes Operator version 3.3.0. Kubernetes 1.16.0+, 1.17.0+, and 1.18.0+ support. Flannel is the only supported CNI in this release. Only Webcenter Sites 12.2.1.4 is supported.
| Jan 15, 2021 | 21.1.1 | no | Certified Oracle WebLogic Kubernetes Operator version 3.0.1. Kubernetes 1.14.8+, 1.15.7+, 1.16.0+, 1.17.0+, and 1.18.0+ support. Flannel is the only supported CNI in this release. Only Webcenter Sites 12.2.1.4 is supported.


### Known issues

| Issue | Description |
| --- | --- |
| Publishing via LoadBalancer Endpoint |  Currenly publishing is only supported via NodePort as described in section `For Publishing Setting in WebCenter Sites` on [page]({{< relref "/wcsites-domains/installguide/create-wcsites-domains">}}).
