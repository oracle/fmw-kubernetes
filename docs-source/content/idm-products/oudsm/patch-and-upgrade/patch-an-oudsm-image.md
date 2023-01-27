---
title: "a. Patch an image"
description: "Instructions on how to update your OUDSM Kubernetes cluster with a new OUDSM container image."
---

### Introduction

In this section the Oracle Unified Directory Services Manager (OUDSM) deployment is updated with a new OUDSM container image. 

**Note**: If you are not using Oracle Container Registry or your own container registry, then you must first load the new container image on all nodes in your Kubernetes cluster.

You can update the deployment with a new OUDSM container image using one of the following methods:

1. [Using a YAML file](#using-a-yaml-file)
1. [Using `--set` argument](#using---set-argument)


#### Using a YAML file

1. Navigate to the `$WORKDIR/kubernetes/helm` directory:

   ```bash
   $ cd $WORKDIR/kubernetes/helm
   ```

1. Create a `oudsm-patch-override.yaml` file that contains:

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
     repository: container-registry.oracle.com/middleware/oudsm_cpu
     tag: 12.2.1.4-jdk8-ol7-new
   imagePullSecrets:
     - name: orclcred
   ```
   
   The following caveats exist:
   
   * If you are not using Oracle Container Registry or your own container registry for your oudsm container image, then you can remove the following:
   
      ```
      imagePullSecrets:
        - name: orclcred
      ```

1. Run the following command to upgrade the deployment:

   ```bash
   $ helm upgrade --namespace <namespace> \
   --values oudsm-patch-override.yaml \
   <release_name> oudsm --reuse-values
   ```
   
   For example:
   
   ```bash
   $ helm upgrade --namespace oudsmns \
   --values oudsm-patch-override.yaml \
   oudsm oudsm --reuse-values
   ```

#### Using `--set` argument

1. Navigate to the `$WORKDIR/kubernetes/helm` directory:

   ```bash
   $ cd $WORKDIR/kubernetes/helm
   ```

1. Run the following command to update the deployment with a new OUDSM container image:

   ```bash
   $ helm upgrade --namespace <namespace> \
   --set image.repository=<image_location>,image.tag=<image_tag> \
   --set imagePullSecrets[0].name="orclcred" \
   <release_name> oudsm --reuse-values
   ```

   For example:

   ```bash
   $ helm upgrade --namespace oudsmns \
   --set image.repository=container-registry.oracle.com/middleware/oudsm_cpu,image.tag=12.2.1.4-jdk8-ol7-new \
   --set imagePullSecrets[0].name="orclcred" \
   oudsm oudsm --reuse-values
   ```
   
   The following caveats exist:
   
   * If you are not using Oracle Container Registry or your own container registry for your OUDSM container image, then you can remove the following: `--set imagePullSecrets[0].name="orclcred"`.


### Verify the pods


1. After updating with the new image the pod will restart. Verify the pod is running:

   ```bash
   $ kubectl --namespace <namespace> get pods
   ```

   For example:

   ```bash
   $ kubectl --namespace oudsmns get pods
   ```

   The output will look similar to the following:

   ```
   NAME          READY   STATUS    RESTARTS   AGE   IP            NODE             NOMINATED NODE   READINESS GATES
   pod/oudsm-1   1/1     Running   0          73m   10.244.0.19   <worker-node>   <none>           <none>
   ```

   **Note**: It will take several minutes before the pod starts. While the oudsm pods have a `STATUS` of `0/1` the pod is started but the OUDSM server associated with it is currently starting. While the pod is starting you can check the startup status in the pod logs, by running the following command:


1. Verify the pod is using the new image by running the following command:

   ```bash
   $ kubectl describe pod <pod> -n <namespace>
   ```

   For example:

   ```bash
   $ kubectl describe pod oudsm-1 -n oudsmns
   ```

   The output will look similar to the following:

   ```bash
   Name:         oudsm-1
   Namespace:    oudsmns
   Priority:     0
   Node:         <worker-node>/100.102.48.28
   Start Time:   <DATE>
   Labels:       app.kubernetes.io/instance=oudsm
                 app.kubernetes.io/managed-by=Helm
                 app.kubernetes.io/name=oudsm
                 app.kubernetes.io/version=12.2.1.4.0
                 helm.sh/chart=oudsm-0.1
                 oudsm/instance=oudsm-1
   Annotations:  meta.helm.sh/release-name: oudsm
                 meta.helm.sh/release-namespace: oudsmns
   Status:       Running
   IP:           10.244.1.90


   etc...

   Events:
     Type     Reason     Age                From     Message
     ----     ------     ----               ----     -------
     Normal   Killing    22m                kubelet  Container oudsm definition changed, will be restarted
     Normal   Created    21m (x2 over 61m)  kubelet  Created container oudsm
     Normal   Pulling    21m                kubelet  Container image "container-registry.oracle.com/middleware/oudsm_cpu:12.2.1.4-jdk8-ol7-new"
     Normal   Started    21m (x2 over 61m)  kubelet  Started container oudsm
   ```
