+++
title = "Patch and Upgrade"
weight = 8 
pre = "<b>8. </b>"
description=  "This document provides steps to patch or upgrade an OUD image"
+++

1. [Introduction](#introduction)
1. [Upgrading to July 22 (22.3.1) or later from earlier versions](#upgrading-to-july-22-2231-or-later-from-earlier-versions)
1. [Upgrading from July 22 (22.3.1) to a later release](#upgrading-from-july-22-2231-to-a-later-release)

### Introduction

In this section the Oracle Unified Directory (OUD) deployment is updated with a new OUD container image. 


### Upgrading to July 22 (22.3.1) or later from earlier versions

In releases prior to July 22 ([22.3.1](https://github.com/oracle/fmw-kubernetes/releases)) OUD used pod based deployment. From July 22 ([22.3.1](https://github.com/oracle/fmw-kubernetes/releases)) onwards OUD is deployed using [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/).

If you are upgrading from a release prior to July 22 ([22.3.1](https://github.com/oracle/fmw-kubernetes/releases)) you must follow the steps below to deploy a new OUD instance to use your existing OUD data in `<persistent_volume>/oud_user_projects`.

**Note**: The steps below will incur a small outage.

#### Delete the existing deployment

1. Find the deployment release name as follows:

   ```bash
   $ helm --namespace <namespace> list
   ```
        
   For example:
        
   ```bash
   $ helm --namespace oudns list
   ```
   
   The output will look similar to the following:
   
   ```
   NAME            NAMESPACE       REVISION        UPDATED                                    STATUS          CHART           APP VERSION
   oud-ds-rs       oudns           1               2022-07-11 09:46:17.613632382 +0000 UTC    deployed        oud-ds-rs-0.2   12.2.1.4.0
   ```
        
1. Delete the deployment using the following command:

   ```bash
   $ helm uninstall --namespace <namespace> <release>
   ```
        
   For example:

   ```bash
   $ helm uninstall --namespace oudns oud-ds-rs
   release "oud-ds-rs" uninstalled
   ```
   
1. Run the following command to view the status:

   ```bash
   $ kubectl --namespace oudns get pod,service,secret,pv,pvc,ingress -o wide
   ```
   
   Initially the pods and persistent volume (PV) and persistent volume claim (PVC) will move to a `Terminating` status:
   
   ```
   NAME              READY   STATUS        RESTARTS   AGE   IP             NODE            NOMINATED NODE   READINESS GATES

   pod/oud-ds-rs-0   1/1     Terminating   0          24m   10.244.1.180   <Worker Node>   <none>           <none>
   pod/oud-ds-rs-1   1/1     Terminating   0          18m   10.244.1.181   <Worker Node>   <none>           <none>
   pod/oud-ds-rs-2   1/1     Terminating   0          12m   10.244.1.182   <Worker Node>   <none>           <none>

   NAME                         TYPE                                  DATA   AGE
   secret/default-token-msmmd   kubernetes.io/service-account-token   3      3d20h
   secret/dockercred            kubernetes.io/dockerconfigjson        1      3d20h
   secret/orclcred              kubernetes.io/dockerconfigjson        1      3d20h

   NAME                                 CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS        CLAIM                       STORAGECLASS        REASON   AGE    VOLUMEMODE
   persistentvolume/oud-ds-rs-pv        20Gi       RWX            Delete           Terminating   oudns/oud-ds-rs-pvc         manual                       24m    Filesystem

   NAME                                  STATUS        VOLUME         CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE
   persistentvolumeclaim/oud-ds-rs-pvc   Terminating   oud-ds-rs-pv   20Gi       RWX            manual         24m   Filesystem
   ```
   
   Run the command again until the pods, PV and PVC disappear.
   

#### Setup the code repository to deploy OUD

1. Create a working directory on the persistent volume to setup the latest source code:

   ```bash
   $ mkdir <persistent_volume>/<workdir>
   ```

   For example:

   ```bash
   $ mkdir /scratch/shared/OUDLatestSource
   ```
   

1. Download the latest OUD deployment scripts from the OUD repository:

   ```bash
   $ cd <persistent_volume>/<workdir>
   $ git clone https://github.com/oracle/fmw-kubernetes.git --branch release/22.3.1
   ```
   
   For example:
   
   ```bash
   $ cd /scratch/shared/OUDLatestSource
   $ git clone https://github.com/oracle/fmw-kubernetes.git --branch release/22.3.1
   ```

1. Set the `$WORKDIR` environment variable as follows:

   ```bash
   $ export WORKDIR=<workdir>/fmw-kubernetes/OracleUnifiedDirectory
   ```
   
   For example:

   ```bash
   $ export WORKDIR=/scratch/shared/OUDLatestSource/fmw-kubernetes/OracleUnifiedDirectory
   ```


#### 2.	Create a new instance against your existing persistent volume


1. Navigate to the `$WORKDIR/kubernetes/helm` directory

   ```bash
   $ cd $WORKDIR/kubernetes/helm
   ```

1. Create an `oud-ds-rs-values-override.yaml` as follows:

   ```yaml
   image:
     repository: <image_location>
     tag: <image_tag>
     pullPolicy: IfNotPresent
   imagePullSecrets:
     - name: orclcred
   oudConfig:
     rootUserPassword: <password>
   persistence:
     type: filesystem
     filesystem:
       hostPath:
         path: <persistent_volume>/oud_user_projects
   cronJob:
     kubectlImage:
       repository: bitnami/kubectl
       tag: <version>
       pullPolicy: IfNotPresent
 
     imagePullSecrets:
       - name: dockercred
   ```
   
   For example:
   
   ```yaml
   image:
     repository: container-registry.oracle.com/middleware/oud_cpu
     tag: 12.2.1.4-jdk8-ol7-<jul22>
     pullPolicy: IfNotPresent
   imagePullSecrets:
     - name: orclcred
   oudConfig:
     rootUserPassword: <password>
   persistence:
     type: filesystem
     filesystem:
       hostPath:
         path: /scratch/shared/oud_user_projects
   cronJob:
     kubectlImage:
       repository: bitnami/kubectl
       tag: 1.21.6
       pullPolicy: IfNotPresent
 
     imagePullSecrets:
       - name: dockercred
   ```   
   
  
   The following caveats exist:
   
   * The `<persistent_volume>/oud_user_projects` must point to the directory used in your previous deployment otherwise your existing OUD data will not be used. Make sure you take a backup of the `<persistent_volume>/oud_user_projects` directory before proceeding further.
   * Replace `<password>` with the password used in your previous deployment.
   * The `<version>` in *kubectlImage* `tag:` should be set to the same version as your Kubernetes version (`kubectl version`). For example if your Kubernetes version is `1.21.6` set to `1.21.6`.
   * If you are not using Oracle Container Registry or your own container registry for your OUD container image, then you can remove the following:
   
      ```
      imagePullSecrets:
        - name: orclcred
      ```
  
   * If using NFS for your persistent volume then change the `persistence` section as follows:
  
      ```yaml
      persistence:
        type: networkstorage
        networkstorage:
          nfs: 
            path: <persistent_volume>/oud_user_projects
            server: <NFS IP address>
      ```

   

1. Run the following command to deploy OUD:

   ```bash
   $ helm install --namespace <namespace> \
   --values oud-ds-rs-values-override.yaml \
   <release_name> oud-ds-rs
   ```

   For example:

   ```bash
   $ helm install --namespace oudns \
   --values oud-ds-rs-values-override.yaml \
   oud-ds-rs oud-ds-rs
   ```

1. Check the OUD deployment as per [Verify the OUD deployment](../create-oud-instances/#verify-the-oud-deployment) and [Verify the OUD replication](../create-oud-instances#verify-the-oud-replication).


### Upgrading from July 22 (22.3.1) to a later release

The instructions below are for upgrading from Jul 22 ([22.3.1](https://github.com/oracle/fmw-kubernetes/releases)) to a later release.

**Note**: If you are not using Oracle Container Registry or your own container registry, then you must first load the new container image on all nodes in your Kubernetes cluster.

You can update the deployment with a new OUD container image using one of the following methods:

1. [Using a YAML file](#using-a-yaml-file)
1. [Using `--set` argument](#using---set-argument)


#### Using a YAML file

1. Navigate to the `$WORKDIR/kubernetes/helm` directory:

   ```bash
   $ cd $WORKDIR/kubernetes/helm
   ```

1. Create a `oud-patch-override.yaml` file that contains:

   ```yaml
   image:
     repository: <image_location>
     tag: <image_tag>
    imagePullSecrets:
      - name: orclcred
   ```

   For example:

   ```yaml
   image:
     repository: container-registry.oracle.com/middleware/oud_cpu
     tag: 12.2.1.4-jdk8-ol7-new
   imagePullSecrets:
     - name: orclcred
   ```
   
   The following caveats exist:
   
   * If you are not using Oracle Container Registry or your own container registry for your OUD container image, then you can remove the following:
   
      ```
      imagePullSecrets:
        - name: orclcred
      ```

1. Run the following command to upgrade the deployment:

   ```bash
   $ helm upgrade --namespace <namespace> \
   --values oud-patch-override.yaml \
   <release_name> oud-ds-rs --reuse-values
   ```
   
   For example:
   
   ```bash
   $ helm upgrade --namespace oudns \
   --values oud-patch-override.yaml \
   oud-ds-rs oud-ds-rs --reuse-values
   ```

#### Using `--set` argument

1. Navigate to the `$WORKDIR/kubernetes/helm` directory:

   ```bash
   $ cd $WORKDIR/kubernetes/helm
   ```

1. Run the following command to update the deployment with a new OUD container image:

   ```bash
   $ helm upgrade --namespace <namespace> \
   --set image.repository=<image_location>,image.tag=<image_tag> \
   --set imagePullSecrets[0].name="orclcred" \
   <release_name> oud-ds-rs --reuse-values
   ```

   For example:

   ```bash
   $ helm upgrade --namespace oudns \
   --set image.repository=container-registry.oracle.com/middleware/oud_cpu,image.tag=12.2.1.4-jdk8-ol7-new \
   --set imagePullSecrets[0].name="orclcred" \
   oud-ds-rs oud-ds-rs --reuse-values
   ```
   
   The following caveats exist:
   
   * If you are not using Oracle Container Registry or your own container registry for your OUD container image, then you can remove the following: `--set imagePullSecrets[0].name="orclcred"`.


### Verify the pods

1. After updating with the new image the pods will restart. Verify the pods are running:

   ```bash
   $ kubectl --namespace <namespace> get pods
   ```

   For example:

   ```bash
   $ kubectl --namespace oudns get pods
   ```

   The output will look similar to the following:
   
   ```
   NAME              READY   STATUS    RESTARTS   AGE     IP             NODE          NOMINATED NODE   READINESS GATES
   pod/oud-ds-rs-0   1/1     Running   0          45m   10.244.0.195   <Worker Node>   <none>           <none>
   pod/oud-ds-rs-1   1/1     Running   0          45m   10.244.0.194   <Worker Node>   <none>           <none>
   pod/oud-ds-rs-2   1/1     Running   0          45m   10.244.0.193   <Worker Node>   <none>           <none>
   ```
   
   **Note**: It will take several minutes before the pods start. While the oudsm pods have a `STATUS` of `0/1` the pods are started but the OUD server associated with it is currently starting.
   
1. Verify the pods are using the new image by running the following command:

   ```bash
   $ kubectl describe pod <pod> -n <namespace>
   ```

   For example:

   ```bash
   $ kubectl describe pod oud-ds-rs-0 -n oudns
   ```

   The output will look similar to the following:

   ```bash
   Name:         oud-ds-rs-0
   Namespace:    oudns
   Priority:     0
   Node:         <Worker Node>/100.102.48.28
   Start Time:   Wed, 16 Mar 2022 12:07:36 +0000
   Labels:       app.kubernetes.io/instance=oud-ds-rs
                 app.kubernetes.io/managed-by=Helm
                 app.kubernetes.io/name=oud-ds-rs
                 app.kubernetes.io/version=12.2.1.4.0
                 helm.sh/chart=oud-ds-rs-0.1
                 oud/instance=oud-ds-rs-0
   Annotations:  meta.helm.sh/release-name: oud-ds-rs
                 meta.helm.sh/release-namespace: oudns
   Status:       Running
   IP:           10.244.1.44

   etc...

   Events:
     Type     Reason     Age                   From     Message
     ----     ------     ----                  ----     -------
     Normal   Killing    4m26s                 kubelet  Container oud-ds-rs definition changed, will be restarted
     Warning  Unhealthy  3m56s                 kubelet  Readiness probe failed:
     Normal   Pulling    3m56s                 kubelet  Pulling image "container-registry.oracle.com/middleware/oud_cpu:12.2.1.4-jdk8-ol7-new"
     Warning  Unhealthy  3m27s                 kubelet  Liveness probe failed: dial tcp 10.244.1.44:1389: connect: connection refused
     Normal   Created    3m22s (x2 over 142m)  kubelet  Created container oud-ds-rs
     Normal   Started    3m22s (x2 over 142m)  kubelet  Started container oud-ds-rs
     Normal   Pulled     3m22s                 kubelet  Successfully pulled image "container-registry.oracle.com/middleware/oud_cpu:12.2.1.4-jdk8-ol7-new" in 33.477063844s
   ```
