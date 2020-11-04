+++
title=  "Prepare Your Environment"
date = 2019-04-18T06:46:23-05:00
weight = 2
pre = "<b>2. </b>"
description = "Prepare your environment"
+++


1. [Set up your Kubernetes Cluster](#set-up-your-kubernetes-cluster)
1. [Check the Kubernetes Cluster is Ready](#check-the-kubernetes-cluster-is-ready)
1. [Install the Oracle Unified Directory Image](#install-the-oracle-unified-directory-image)
1. [Setup the Code Repository To Deploy Oracle Unified Directory](#setup-the-code-repository-to-deploy-oracle-unified-directory)

### Set up your Kubernetes Cluster

If you need help setting up a Kubernetes environment, check our [cheat sheet](https://oracle.github.io/weblogic-kubernetes-operator/userguide/overview/k8s-setup/).

It is recommended you have a master node and one or more worker nodes. The examples in this documentation assume one master and two worker nodes.

After creating Kubernetes clusters, you can optionally:

* Configure an Ingress to direct traffic to backend instances.

### Check the Kubernetes Cluster is Ready

1. Run the following command on the master node to check the cluster and worker nodes are running:

```
$ kubectl get nodes,pods -n kube-system
```

The output will look similar to the following:

```
NAME                STATUS   ROLES    AGE   VERSION
node/10.89.73.203   Ready    <none>   66d   v1.18.4
node/10.89.73.204   Ready    <none>   66d   v1.18.4
node/10.89.73.42    Ready    master   67d   v1.18.4

NAME                                      READY   STATUS    RESTARTS   AGE
pod/coredns-66bff467f8-slxdq              1/1     Running   1          67d
pod/coredns-66bff467f8-v77qt              1/1     Running   1          67d
pod/etcd-10.89.73.42                      1/1     Running   1          67d
pod/kube-apiserver-10.89.73.42            1/1     Running   1          67d
pod/kube-controller-manager-10.89.73.42   1/1     Running   27         67d
pod/kube-flannel-ds-amd64-r2m8r           1/1     Running   2          48d
pod/kube-flannel-ds-amd64-rdhrf           1/1     Running   2          6d1h
pod/kube-flannel-ds-amd64-vpcbj           1/1     Running   3          66d
pod/kube-proxy-jtcxm                      1/1     Running   1          67d
pod/kube-proxy-swfmm                      1/1     Running   1          66d
pod/kube-proxy-w6x6t                      1/1     Running   1          66d
pod/kube-scheduler-10.89.73.42            1/1     Running   29         67d
```

### Install the Oracle Unified Directory Image

You can deploy [Oracle Unified Directory images](https://github.com/oracle/docker-images/tree/master/OracleUnifiedDirectory) in the following ways:

1. Download a pre-built Oracle Unified Directory image from [My Oracle Support](https://support.oracle.com).  by referring to the document ID 2723908.1. This image is prebuilt by Oracle and includes Oracle Unified Directory 12.2.1.4.0 and the latest PSU.
1. Build your own Oracle Unified Directory container image either by using the WebLogic Image Tool or by using the dockerfile, scripts and base image from Oracle Container Registry (OCR). You can also build your own image by using only the dockerfile and scripts. For more information about the various ways in which you can build your own container image, see [Installing the Oracle Unified Directory Image](https://github.com/oracle/docker-images/tree/master/OracleUnifiedDirectory/README.md#installing-the-oracle-unified-directory-image).

Choose one of these options based on your requirements.

{{% notice note %}}
The Oracle Unified Directory image must be installed on the master node and each of the worker nodes in your Kubernetes cluster. Alternatively you can place the image in a docker registry that your cluster can access.
{{% /notice %}}

After installing the Oracle Unified Directory image run the following command to make sure the image is installed correctly on the master and worker nodes:

```
$ docker images
```

The output will look similar to the following:

```
REPOSITORY                                                                   TAG                       IMAGE ID            CREATED             SIZE
oracle/oud                                                                   12.2.1.4.0                8a937042bef3        3 weeks ago         992MB
k8s.gcr.io/kube-proxy                                                        v1.18.4                   718fa77019f2        3 months ago        117MB
k8s.gcr.io/kube-scheduler                                                    v1.18.4                   c663567f869e        3 months ago        95.3MB
k8s.gcr.io/kube-controller-manager                                           v1.18.4                   e8f1690127c4        3 months ago        162MB
k8s.gcr.io/kube-apiserver                                                    v1.18.4                   408913fc18eb        3 months ago        173MB
quay.io/coreos/flannel                                                       v0.12.0-amd64             4e9f801d2217        6 months ago        52.8MB
k8s.gcr.io/pause                                                             3.2                       80d28bedfe5d        7 months ago        683kB
k8s.gcr.io/coredns                                                           1.6.7                     67da37a9a360        8 months ago        43.8MB
k8s.gcr.io/etcd                                                              3.4.3-0                   303ce5db0e90        11 months ago       288MB
quay.io/prometheus/node-exporter                                             v0.18.1                   e5a616e4b9cf        16 months ago       22.9MB
quay.io/coreos/kube-rbac-proxy                                               v0.4.1                    70eeaa7791f2        20 months ago       41.3MB
...
```

### Setup the Code Repository To Deploy Oracle Unified Directory

Oracle Unified Directory deployment on Kubernetes leverages deployment scripts provided by Oracle for creating Oracle Unified Directory containers using samples or Helm charts provided.  To deploy Oracle Unified Directory on Kubernetes you should set up the deployment scripts on the **master** node as below:

Create a working directory to setup the source code.

```
$ mkdir <work directory>
```

For example:

```
$ mkdir /scratch/OUDContainer
```

From the directory you created, download the Oracle Unified Directory deployment scripts from the Oracle Unified Directory [repository](https://github.com/oracle/fmw-kubernetes.git).

```
$ git clone https://github.com/oracle/fmw-kubernetes.git
```

You can now use the deployment scripts from `<work directory>/fmw-kubernetes/OracleUnifiedDirectory/kubernetes/samples/` to set up the Oracle Unified Directory environments as further described in this document.
