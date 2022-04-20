+++
title = "Patch and Upgrade"
weight = 8 
pre = "<b>8. </b>"
description=  "This document provides steps to patch or upgrade an OID image"
+++

### Introduction

In this section the Oracle Internet Directory (OID) deployment is updated with a new OID container image. 

**Note**: If you are not using Oracle Container Registry or your own container registry, then you must first load the new container image on all nodes in your Kubernetes cluster.

You can update the deployment with a new OID container image using one of the following methods:

1. [Using a YAML file](#using-a-yaml-file)
1. [Using `--set` argument](#using---set-argument)


#### Using a YAML file

1. Navigate to the `$WORKDIR/kubernetes/helm` directory:

   ```bash
   $ cd $WORKDIR/kubernetes/helm
   ```

1. Create a `oid-patch-override.yaml` file that contains:

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
     repository: container-registry.oracle.com/middleware/oid_cpu
     tag: 12.2.1.4-jdk8-ol7-new
   imagePullSecrets:
     - name: orclcred
   ```
   
   The following caveats exist:
   
   * If you are not using Oracle Container Registry or your own container registry for your OID container image, then you can remove the following:
   
      ```
      imagePullSecrets:
        - name: orclcred
      ```

1. Run the following command to upgrade the deployment:

   ```bash
   $ helm upgrade --namespace <namespace> \
   --values oid-patch-override.yaml \
   <release_name> oid --reuse-values
   ```
   
   For example:
   
   ```bash
   $ helm upgrade --namespace oidns \
   --values oid-patch-override.yaml \
   oid oid --reuse-values
   ```

#### Using `--set` argument

1. Navigate to the `$WORKDIR/kubernetes/helm` directory:

   ```bash
   $ cd $WORKDIR/kubernetes/helm
   ```

1. Run the following command to update the deployment with a new OID container image:

   ```bash
   $ helm upgrade --namespace <namespace> \
   --set image.repository=<image_location>,image.tag=<image_tag> \
   --set imagePullSecrets[0].name="orclcred" \
   <release_name> oid --reuse-values
   ```

   For example:

   ```bash
   $ helm upgrade --namespace oidns \
   --set image.repository=container-registry.oracle.com/middleware/oid_cpu,image.tag=12.2.1.4-jdk8-ol7-new \
   --set imagePullSecrets[0].name="orclcred" \
   oid oid --reuse-values
   ```
   
   The following caveats exist:
   
   * If you are not using Oracle Container Registry or your own container registry for your OID container image, then you can remove the following: `--set imagePullSecrets[0].name="orclcred"`.


### Verify the pods

1. After updating with the new image the pods will restart. Verify the pods are running:

   ```bash
   $ kubectl --namespace <namespace> get pods -o wide
   ```

   For example:

   ```bash
   $ kubectl --namespace oidns get pods -o wide
   ```

   The output will look similar to the following:
   
   ```
   NAME           READY   STATUS    RESTARTS   AGE   IP             NODE            NOMINATED NODE   READINESS GATES
   pod/oidhost1   1/1     Running   0          45m   10.244.0.195   <Worker Node>   <none>           <none>
   pod/oidhost2   1/1     Running   0          45m   10.244.0.194   <Worker Node>   <none>           <none>
   ```
   
   **Note**: It will take several minutes before the pods start. While the oid pods have a `STATUS` of `0/1` the pods are started but the OID server associated with it is currently starting. While the pods are starting you can check the startup status in the pod logs, by running the following command:
   
1. Verify the pods are using the new image by running the following command:

   ```bash
   $ kubectl describe pod <pod> -n <namespace>
   ```

   For example:

   ```bash
   $ kubectl describe pod oid-0 -n oidns
   ```

   The output will look similar to the following:

   ```bash
   Name:         oid-0
   Namespace:    oidns
   Priority:     0
   Node:         <Worker Node>/100.102.48.28
   Start Time:   Wed, 16 Mar 2022 12:07:36 +0000
   Labels:       app.kubernetes.io/instance=oid
                 app.kubernetes.io/managed-by=Helm
                 app.kubernetes.io/name=oid
                 app.kubernetes.io/version=12.2.1.4.0
                 helm.sh/chart=oid-0.1
                 oid/instance=oid-0
   Annotations:  meta.helm.sh/release-name: oid
                 meta.helm.sh/release-namespace: oidns
   Status:       Running
   IP:           10.244.1.44

   etc...

   Events:
     Type     Reason     Age                   From     Message
     ----     ------     ----                  ----     -------
     Normal   Killing    4m26s                 kubelet  Container oid definition changed, will be restarted
     Warning  Unhealthy  3m56s                 kubelet  Readiness probe failed:
     Normal   Pulling    3m56s                 kubelet  Pulling image "container-registry.oracle.com/middleware/oid_cpu:12.2.1.4-jdk8-ol7-new"
     Warning  Unhealthy  3m27s                 kubelet  Liveness probe failed: dial tcp 10.244.1.44:1389: connect: connection refused
     Normal   Created    3m22s (x2 over 142m)  kubelet  Created container oid
     Normal   Started    3m22s (x2 over 142m)  kubelet  Started container oid
     Normal   Pulled     3m22s                 kubelet  Successfully pulled image "container-registry.oracle.com/middleware/oid_cpu:12.2.1.4-jdk8-ol7-new" in 33.477063844s
   ```