Deploying Oracle Unified Directory (OUD) Instance(s) on Kubernetes using Helm Chart
===================================================================================

## Contents
1. [Introduction](#1-introduction)
2. [Hardware and Software Requirements](#2-hardware-and-software-requirements)
3. [Prerequisites](#3-prerequisites)
4. [Deploy application using Helm Chart](#4-deploy-application-using-helm-chart)
5. [Uninstalling Chart](#5-uninstalling-chart)
6. [Helm Chart(s) for OUD](#6-helm-charts-for-oud)
7. [Copyright](#copyright)

# 1. Introduction
This project demonstrates how to deploy Oracle Unified Directory 12c (OUD) instance(s) using the Helm package manager for Kubernetes. Helm Chart(s) described here can be used to facilitate installation, configuration, and environment setup for DevOps users.

The Docker Image used here refers to released binaries for OUD and it has the capability to create container(s) targeted for development and testing.

# 2. Hardware and Software Requirements
Oracle Unified Directory Docker Image has been tested and is known to run on following hardware and software:

## 2.1 Hardware Requirements

| Hardware  | Size  |
| :-------: | :---: |
| RAM       | 16GB  |
| Disk Space| 200GB+|

## 2.2 Software Requirements

|       | Version                        | Command to verify version |
| :---: | :----------------------------: | :-----------------------: |
| OS    | Oracle Linux 7.3 or higher     | more /etc/oracle-release  |
| Docker| Docker version 18.03 or higher | docker version            |
| K8s   | Kubernetes version 1.16.0+     | kubectl version           |
| Helm  | Helm 3.0.2+                    | helm version              |

# 3. Prerequisites

## 3.1 Verify OS Version
OS version should be Oracle Linux 7.3 or higher.  To check this, issue the following command:

        # more /etc/oracle-release
        Oracle Linux Server release 7.5

## 3.2 Verify Docker Version and OUD Image
Docker version should be 18.03 or higher.  To check this, issue the following command:

         # docker version
         Client: Docker Engine - Community
         Version:           18.09.8-ol
         ...

The Oracle Unified Directory Image for 12cPS4 (12.2.1.4.0) should be loaded into Docker.  Verify this by running the following:

        # docker images
        REPOSITORY                                     TAG                 IMAGE ID            CREATED             SIZE
        oracle/oud                                     12.2.1.4.0          1855f331f5ef        10 days ago         945MB
        ...

## 3.3 Verify Kubernetes Version
Kubernetes version should be 1.16.0 or higher.  Verify by running the following:

        # kubectl version
        Client Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.4", GitCommit:"c96aede7b5205121079932896c4ad89bb93260af", GitTreeState:"clean", BuildDate:"2020-06-17T11:41:22Z", GoVersion:"go1.13.9", Compiler:"gc", Platform:"linux/amd64"}
        Server Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.4", GitCommit:"c96aede7b5205121079932896c4ad89bb93260af", GitTreeState:"clean", BuildDate:"2020-06-17T11:33:59Z", GoVersion:"go1.13.9", Compiler:"gc", Platform:"linux/amd64"}

## 3.4 Verify Helm Version
Helm version should be 3.0.2 or higher.  To verify, run the following command:

        # helm version
        version.BuildInfo{Version:"v3.0.3", GitCommit:"ac925eb7279f4a6955df663a0128044a8a6b7593", GitTreeState:"clean", GoVersion:"go1.13.6"}

## 3.5 Create Kubernetes Namespace
You should create a Kubernetes namespace to provide a scope for other objects such as pods and services that you create in the environment.  To create your namespace issue the following:

        # kubectl create namespace myhelmns
        namespace/myhelmns created

Confirm that the namespace is created:

        # kubectl get namespaces
        NAME          STATUS   AGE
        default       Active   4d
        kube-public   Active   4d
        kube-system   Active   4d
        myhelmns      Active   53s

## 3.6 Prepare a host directory to be used for Filesystem based PersistentVolume

It's required to prepare directory on Host filesystem to store OUD Instances and other configuration outside container filesystem. That directory from host filesystem would be associated with PersistentVolume.
**In case of multi-node Kubernetes cluster, directory to be associated with PersistentVolume should be accessible on all the nodes at the same path.**

To prepare a host directory (for example: /scratch/test/oud_user_projects) for mounting as file system based PersistentVolume inside containers, execute the command below on host:

> The userid can be anything but it must belong to uid:guid as 1000:1000, which is same as 'oracle' user running in the container.
> This ensures 'oracle' user has access to shared volume/directory.

```
sudo su - root
mkdir -p /scratch/test/oud_user_projects
chown 1000:1000 /scratch/test/oud_user_projects
exit
```

All container operations are performed as **'oracle'** user.

**Note**: If a user already exist with **'-u 1000 -g 1000'** then use the same user. Or modify any existing user to have uid-gid as **'-u 1000 -g 1000'**

# 4. Deploy application using Helm Chart

Using following kind of command, Helm Chart can be deployed.

        # helm install [Deployment NAME] [CHART Reference] [flags]

For example:

        # helm install my-oud-ds-rs oud-ds-rs --namespace myhelmns

# 5. Uninstalling Chart

To uninstall the chart you need to identify the release name and then issue a delete command:

To get the release name:

        # helm --namespace <namespace> list
        
For example:

        # helm --namespace myhelmns list
        NAME                    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
        my-oud-ds-rs-           myhelmns        1               2020-03-31 10:37:30.616927678 -0700 PDT deployed        oud-ds-rs-12.2.1.4.0    12.2.1.4.0
        
To delete the chart:

        # helm uninstall --namespace <namespace> <release>
        
For example:

        # helm uninstall --namespace myhelmns my-oud-ds-rs
        release "my-oud-ds-rs" uninstalled

# 6. Helm Chart(s) for OUD

Details about each Helm Chart can be found from README.md file of individual Chart.

* [oud-ds-rs](oud-ds-rs/README.md) : A Helm chart for deployment of OUD Directory (DS+RS) instances on Kubernetes.

# Licensing & Copyright

## License<br>
To download and run Oracle Fusion Middleware products, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.<br><br>

All scripts and files hosted in this project and GitHub [fmw-kubernetes/OracleUnifiedDirectory](./) repository required to build the Docker images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.<br><br>

## Copyright<br>
Copyright (c) 2020, Oracle and/or its affiliates.<br>
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl<br><br>

