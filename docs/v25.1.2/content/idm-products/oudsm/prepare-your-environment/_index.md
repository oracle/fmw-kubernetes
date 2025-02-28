+++
title=  "Prepare Your Environment"
weight = 4
pre = "<b>4. </b>"
description = "Prepare your environment"
+++


1. [Check the Kubernetes cluster is ready](#check-the-kubernetes-cluster-is-ready)
1. [Obtain the OUDSM container image](#obtain-the-oudsm-container-image)
1. [Setup the code repository to deploy OUDSM](#setup-the-code-repository-to-deploy-oudsm)


### Check the Kubernetes cluster is ready

As per the [Prerequisites](../prerequisites/#system-requirements-for-oracle-unified-directory-services-manager-on-kubernetes) a Kubernetes cluster should have already been configured.

1. Run the following command on the master node to check the cluster and worker nodes are running:

   ```bash
   $ kubectl get nodes,pods -n kube-system
   ```

   The output will look similar to the following:

   ```
   NAME                  STATUS   ROLES    AGE   VERSION
   node/worker-node1     Ready    <none>   17h   v1.29.9+3.el8
   node/worker-node2     Ready    <none>   17h   v1.29.9+3.el8
   node/master-node      Ready    master   23h   v1.29.9+3.el8

   NAME                                     READY   STATUS    RESTARTS   AGE
   pod/coredns-66bff467f8-fnhbq             1/1     Running   0          23h
   pod/coredns-66bff467f8-xtc8k             1/1     Running   0          23h
   pod/etcd-master                          1/1     Running   0          21h
   pod/kube-apiserver-master-node           1/1     Running   0          21h
   pod/kube-controller-manager-master-node  1/1     Running   0          21h
   pod/kube-flannel-ds-amd64-lxsfw          1/1     Running   0          17h
   pod/kube-flannel-ds-amd64-pqrqr          1/1     Running   0          17h
   pod/kube-flannel-ds-amd64-wj5nh          1/1     Running   0          17h
   pod/kube-proxy-2kxv2                     1/1     Running   0          17h
   pod/kube-proxy-82vvj                     1/1     Running   0          17h
   pod/kube-proxy-nrgw9                     1/1     Running   0          23h
   pod/kube-scheduler-master                1/1     Running   0          21$
   ```

### Obtain the OUDSM container image

The Oracle Unified Directory Services Manager (OUDSM) Kubernetes deployment requires access to an OUDSM container image. The image can be obtained in the following ways:

- Prebuilt OUDSM container image
- Build your own OUDSM container image using WebLogic Image Tool

#### Prebuilt OUDSM container image


The prebuilt OUDSM January 2025 container image can be downloaded from [Oracle Container Registry](https://container-registry.oracle.com). This image is prebuilt by Oracle and includes Oracle Unified Directory Services Manager 12.2.1.4.0, the January Patch Set Update (PSU) and other fixes released with the Critical Patch Update (CPU) program.

**Note**: Before using this image you must login to [Oracle Container Registry](https://container-registry.oracle.com), navigate to `Middleware` > `oudsm_cpu` and accept the license agreement.

You can use this image in the following ways:

- Pull the container image from the Oracle Container Registry automatically during the OUDSM Kubernetes deployment.
- Manually pull the container image from the Oracle Container Registry and then upload it to your own container registry.
- Manually pull the container image from the Oracle Container Registry and manually stage it on the master node and each worker node.

#### Build your own OUDSM container image using WebLogic Image Tool

You can build your own OUDSM container image using the WebLogic Image Tool. This is recommended if you need to apply one off patches to a [Prebuilt OUDSM container image](#prebuilt-oudsm-container-image). For more information about building your own container image with WebLogic Image Tool, see [Create or update image](../create-or-update-image/)

You can use an image built with WebLogic Image Tool in the following ways:

- Manually upload them to your own container registry.
- Manually stage them on the master node and each worker node.

**Note**: This documentation does not tell you how to pull or push the above images into a private container registry, or stage them on the master and worker nodes. Details of this can be found in the [Enterprise Deployment Guide](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/procuring-software-enterprise-deployment.html).


### Setup the code repository to deploy OUDSM

Oracle Unified Directory Services Manager deployment on Kubernetes leverages deployment scripts provided by Oracle for creating Oracle Unified Directory Services Manager containers using the Helm charts provided.  To deploy Oracle Unified Directory Services Manager on Kubernetes you should set up the deployment scripts on the **master** node as below:

1. Create a working directory to setup the source code.

   ```bash
   $ mkdir <workdir>
   ```

   For example:

   ```bash
   $ mkdir /scratch/OUDSMContainer
   ```

1. Download the latest OUDSM deployment scripts from the OUDSM repository:

   ```bash
   $ cd <workdir>
   $ git clone https://github.com/oracle/fmw-kubernetes.git
   ```
   
   For example:
   
   ```bash
   $ cd /scratch/OUDSMContainer
   $ git clone https://github.com/oracle/fmw-kubernetes.git
   ```

1. Set the `$WORKDIR` environment variable as follows:

   ```bash
   $ export WORKDIR=<workdir>/fmw-kubernetes/OracleUnifiedDirectorySM
   ```
   
   For example:

   ```bash
   $ export WORKDIR=/scratch/OUDSMContainer/fmw-kubernetes/OracleUnifiedDirectorySM
   ```

   You are now ready to create the OUDSM deployment as per [Create OUDSM instances](../create-oudsm-instances).










