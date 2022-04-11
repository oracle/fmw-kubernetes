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
| Dec 10, 2021 | 21.4.3 | no | Certified Oracle WebLogic Kubernetes Operator version 3.3.0. Kubernetes 1.16.0+, 1.17.0+, and 1.18.0+ support. Flannel is the only supported CNI in this release. Only Webcenter Sites 12.2.1.4 is supported.
| Jan 15, 2021 | 21.1.1 | no | Certified Oracle WebLogic Kubernetes Operator version 3.0.1. Kubernetes 1.14.8+, 1.15.7+, 1.1.6.0+, 1.17.0+, and 1.18.0+ support. Flannel is the only supported CNI in this release. Only Webcenter Sites 12.2.1.4 is supported.


### Known issues

| Issue | Description |
| --- | --- |
| Publishing via LoadBalancer Endpoint |  Currenly publishing is only supported via NodePort as described in section `For Publishing Setting in WebCenter Sites` on [page]({{< relref "/wcsites-domains/installguide/create-wcsites-domains">}}).
