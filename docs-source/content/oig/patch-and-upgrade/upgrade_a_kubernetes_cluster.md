---
title: "c. Upgrade a Kubernetes cluster"
description: "Instructions on how to upgrade a Kubernetes cluster."
---

These instructions describe how to upgrade a Kubernetes cluster created using kubeadm on which an OIG domain is deployed. A rolling upgrade approach is used to upgrade nodes (master and worker) of the Kubernetes cluster.

{{% notice note %}}
It is expected that there will be a down time during the upgrade of the Kubernetes cluster as the nodes need to be drained as part of the upgrade process.
{{% /notice %}}

### Prerequisites

* Review [Prerequisites]({{< relref "/oig/prerequisites">}}) and ensure that your Kubernetes cluster is ready for upgrade. Make sure your environment meets all prerequisites.
* Make sure the database used for the OIG domain deployment is up and running during the upgrade process.

### Upgrade the Kubernetes version

An upgrade of Kubernetes is supported from one MINOR version to the next MINOR version, or between PATCH versions of the same MINOR. For example, you can upgrade from 1.x to 1.x+1, but not from 1.x to 1.x+2. To upgrade a Kubernetes version, first all the master nodes of the Kubernetes cluster must be upgraded sequentially, followed by the sequential upgrade of each worker node.

* See [here](https://v1-17.docs.kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/) for Kubernetes official documentation to upgrade from v1.16.x to v1.17.x.
* See [here](https://v1-18.docs.kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/) for Kubernetes official documentation to upgrade from v1.17.x to v1.18.x.