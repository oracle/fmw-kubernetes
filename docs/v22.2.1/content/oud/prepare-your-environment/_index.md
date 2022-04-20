+++
title=  "Prepare Your Environment"
weight = 3
pre = "<b>3. </b>"
description = "Prepare your environment"
+++


1. [Check the Kubernetes cluster is ready](#check-the-kubernetes-cluster-is-ready)
1. [Obtain the OUD container image](#obtain-the-oud-container-image)
1. [Create a persistent volume directory](#create-a-persistent-volume-directory)
1. [Setup the code repository to deploy OUD](#setup-the-code-repository-to-deploy-oud)

### Check the Kubernetes cluster is ready

As per the [Prerequisites](../prerequisites/#system-requirements-for-oracle-unified-directory-on-kubernetes) a Kubernetes cluster should have already been configured.

1. Run the following command on the master node to check the cluster and worker nodes are running:

   ```bash
   $ kubectl get nodes,pods -n kube-system
   ```

   The output will look similar to the following:

   ```
   NAME                  STATUS   ROLES                  AGE   VERSION
   node/worker-node1     Ready    <none>                 17h   v1.20.10
   node/worker-node2     Ready    <none>                 17h   v1.20.10
   node/master-node      Ready    control-plane,master   23h   v1.20.10

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

### Obtain the OUD container image

The OUD Kubernetes deployment requires access to an OUD container image. The image can be obtained in the following ways:

- Prebuilt OUD container image
- Build your own OUD container image using WebLogic Image Tool

#### Prebuilt OUD container image


The latest prebuilt OUD container image can be downloaded from [Oracle Container Registry](https://container-registry.oracle.com). This image is prebuilt by Oracle and includes Oracle Unified Directory 12.2.1.4.0 and the latest PSU. 

**Note**: Before using this image you must login to [Oracle Container Registry](https://container-registry.oracle.com), navigate to `Middleware` > `oud_cpu` and accept the license agreement.

Alternatively the same image can also be downloaded from [My Oracle Support](https://support.oracle.com) by referring to the document ID 2723908.1.

You can use this image in the following ways:

- Pull the container image from the Oracle Container Registry automatically during the OUD Kubernetes deployment.
- Manually pull the container image from the Oracle Container Registry or My Oracle Support, and then upload it to your own container registry.
- Manually pull the container image from the Oracle Container Registry or My Oracle Support and manually stage it on the master node and each worker node. 

#### Build your own OUD container image using WebLogic Image Tool

You can build your own OUD container image using the WebLogic Image Tool. This is recommended if you need to apply one off patches to a [Prebuilt OUD container image](#prebuilt-oud-container-image). For more information about building your own container image with WebLogic Image Tool, see [Create or update image](../create-or-update-image/).

You can use an image built with WebLogic Image Tool in the following ways:

- Manually upload them to your own container registry. 
- Manually stage them on the master node and each worker node.

**Note**: This documentation does not tell you how to pull or push the above images into a private container registry, or stage them on the master and worker nodes. Details of this can be found in the [Enterprise Deployment Guide](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/procuring-software-enterprise-deployment.html).


### Create a persistent volume directory

As referenced in [Prerequisites](../prerequisites) the nodes in the Kubernetes cluster must have access to a persistent volume such as a Network File System (NFS) mount or a shared file system. 

Make sure the persistent volume path has **full** access permissions, and that the folder is empty. In this example `/scratch/shared/` is a shared directory accessible from all nodes.
   
1. On the master node run the following command to create a `user_projects` directory:

   ```bash 
   $ cd <persistent_volume>
   $ mkdir oud_user_projects   
   $ chmod 777 oud_user_projects
   ```
   
   For example:
   
   ```bash 
   $ cd /scratch/shared
   $ mkdir oud_user_projects   
   $ chmod 777 oud_user_projects
   ```
   
1. On the master node run the following to ensure it is possible to read and write to the persistent volume:
   
   ```
   $ cd <persistent_volume>/oud_user_projects
   $ touch file.txt
   $ ls filemaster.txt
   ```
   
   For example:
   
   ```bash
   $ cd /scratch/shared/oud_user_projects
   $ touch filemaster.txt
   $ ls filemaster.txt
   ```
   
   On the first worker node run the following to ensure it is possible to read and write to the persistent volume:
   
   ```bash
   $ cd /scratch/shared/oud_user_projects
   $ ls filemaster.txt
   $ touch fileworker1.txt
   $ ls fileworker1.txt
   ```
   
   Repeat the above for any other worker nodes e.g fileworker2.txt etc. Once proven that it's possible to read and write from each node to the persistent volume, delete the files created.

### Setup the code repository to deploy OUD

Oracle Unified Directory deployment on Kubernetes leverages deployment scripts provided by Oracle for creating Oracle Unified Directory containers using the Helm charts provided.  To deploy Oracle Unified Directory on Kubernetes you should set up the deployment scripts on the persistent volume as below:

**Note**: The work directory *must* be created on the persistent volume as access to the helm charts is required by a cron job created during OUD deployment.

1. Create a working directory on the persistent volume to setup the source code.

   ```bash
   $ mkdir <persistent_volume>/<workdir>
   ```

   For example:

   ```bash
   $ mkdir /scratch/shared/OUDContainer
   ```

1. Download the latest OUD deployment scripts from the OUD repository:

   ```bash
   $ cd <persistent_volume>/<workdir>
   $ git clone https://github.com/oracle/fmw-kubernetes.git --branch release/22.2.1
   ```
   
   For example:
   
   ```bash
   $ cd /scratch/shared/OUDContainer
   $ git clone https://github.com/oracle/fmw-kubernetes.git --branch release/22.2.1
   ```

1. Set the `$WORKDIR` environment variable as follows:

   ```bash
   $ export WORKDIR=<workdir>/fmw-kubernetes/OracleUnifiedDirectory
   ```
   
   For example:

   ```bash
   $ export WORKDIR=/scratch/shared/OUDContainer/fmw-kubernetes/OracleUnifiedDirectory
   ```

   You are now ready to create the OUD deployment as per [Create OUD instances](../create-oud-instances).
