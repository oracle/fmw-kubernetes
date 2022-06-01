+++
title = "Patch and Upgrade"
weight = 8 
pre = "<b>8. </b>"
description=  "This document provides steps to patch or upgrade an OUD image"
+++

### Introduction

In this section the Oracle Unified Directory (OUD) deployment is updated with a new OUD container image. 

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
   
   **Note**: It will take several minutes before the pods start. While the oudsm pods have a `STATUS` of `0/1` the pods are started but the OUD server associated with it is currently starting. While the pods are starting you can check the startup status in the pod logs, by running the following command:
   
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