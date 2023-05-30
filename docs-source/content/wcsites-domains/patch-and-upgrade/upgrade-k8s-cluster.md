---
title: "Upgrade a Kubernetes cluster"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 3
pre: "<b>c. </b>"
description: "Upgrade the underlying Kubernetes cluster version in a running Oracle WebCenter Sites Kubernetes environment."
---

These instructions describe how to upgrade a Kubernetes cluster created using `kubeadm` on which an Oracle WebCenter Sites domain is deployed. A rolling upgrade approach is used to upgrade nodes (master and worker) of the Kubernetes cluster.

{{% notice warning  %}}
It is expected that there will be a down time during the upgrade of the Kubernetes cluster as the nodes need to be drained as part of the upgrade process.
{{% /notice %}}

### Prerequisites

* Review [Prerequisites]({{< relref "/wcsites-domains/installguide/prerequisites/#system-requirements" >}}) and ensure that your Kubernetes cluster is ready for upgrade. Make sure your environment meets all prerequisites.
* Make sure the database used for the Oracle WebCenter Sites domain deployment is up and running during the upgrade process.

### Upgrade the Kubernetes version
 An upgrade of Kubernetes is supported from one MINOR version to the next MINOR version, or between PATCH versions of the same MINOR.
 For example, you can upgrade from 1.x to 1.x+1, but not from 1.x to 1.x+2.
 To upgrade a Kubernetes version, first all the master nodes of the Kubernetes cluster must be  upgraded sequentially, followed by the sequential upgrade of each worker node.

*  See [here](https://v1-21.docs.kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/) for Kubernetes official documentation to upgrade from 1.20 to 1.21
*  See [here](https://v1-22.docs.kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/) for Kubernetes official documentation to upgrade from 1.21 to 1.22
*  See [here](https://v1-23.docs.kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/) for Kubernetes official documentation to upgrade from 1.22 to 1.23
*  See [here](https://v1-24.docs.kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/) for Kubernetes official documentation to upgrade from 1.23 to 1.24
*  See [here](https://v1-25.docs.kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/) for Kubernetes official documentation to upgrade from 1.24 to 1.25
