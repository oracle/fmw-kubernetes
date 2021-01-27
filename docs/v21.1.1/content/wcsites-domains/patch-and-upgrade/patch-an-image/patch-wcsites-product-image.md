---
title: "Patch a Oracle WebCenter Sites product Docker image"
date: 2019-09-21T15:44:42-05:00
draft: false
weight: 1
pre: "<b>a. </b>"
description: "Upgrade the underlying Oracle WebCenter Sites product image in a running Oracle WebCenter Sites Kubernetes environment."
---

These instructions describe how to upgrade a new release of Oracle WebCenter Sites product Docker image in a running Oracle WebCenter Sites Kubernetes environment. A rolling upgrade approach is used to upgrade managed server pods of the domain.

{{% notice info  %}}
It is expecting a Zero down time as a rolling upgrade approach is used.
{{% /notice %}}

### Prerequisites

* Make sure Oracle WebCenter Sites domain is created and all the admin and managed pods are up and running. 
* Make sure the database used for the Oracle WebCenter Sites domain deployment is up and running during the upgrade process.

### Prepare the upgrade-domain-inputs.yaml

Modify the kubernetes/samples/scripts/domain-home-on-pv/upgrade/upgrade-domain-inputs.yaml. Below are given default values. 

```bash
# Name of the Admin Server
adminServerName: adminserver

# Unique ID identifying a domain.
# This ID must not contain an underscope ("_"), and must be lowercase and unique across all domains in a Kubernetes cluster.
domainUID: wcsitesinfra


# Number of managed servers to generate for the domain
configuredManagedServerCount: 3

#Number of managed servers running at the time of upgrade
managedServerRunning: 3

# Base string used to generate managed server names
managedServerNameBase: wcsites-server


# Oracle WebCenter Sites Docker image.
# Refer to build Oracle WebCenter Sites Docker image https://github.com/oracle/docker-images/tree/master/OracleWebCenterSites
# for details on how to obtain or create the image.
# tag image to a new tag for example: oracle/wcsites:12.2.1.4-21.1.1-20210122
image: oracle/wcsites:12.2.1.4-21.1.1-20210122

# Image pull policy
# Legal values are "IfNotPresent", "Always", or "Never"
imagePullPolicy: IfNotPresent

# Name of the domain namespace
namespace: wcsites-ns

```

### Run the upgrade script

Run the upgrade script with the modified upgrade-domain-inputs.yaml file and wait for the script to be finished. 

```bash
$ sh kubernetes/samples/scripts/domain-home-on-pv/upgrade/upgrade.sh -i upgrade-domain-inputs.yaml
```

Monitor the pods rolling out incrementaly. 

```bash
$ kubectl get pods -n wcsites-ns -w
```

### Configure WebCenter Sites patch

Configure WebCenter Sites patch by hitting url http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}/sites/sitespatchsetup

