---
title: "a) Scaling Up/Down OUD Pods "
description: "Describes the steps for scaling up/down for OUD pods."
---

### Introduction

This section describes how to increase or decrease the number of OUD pods in the Kubernetes deployment.


### View existing OUD pods

By default the `oud-ds-rs` helm chart deployment starts three pods:  `oud-ds-rs-0` and two replica pods `oud-ds-rs-1` and `oud-ds-rs-2`.

The number of pods started is determined by the `replicaCount`, which is set to `3` by default. A value of `3` starts the three pods above.

To scale up or down the number of OUD pods, set `replicaCount` accordingly.

Run the following command to view the number of pods in the OUD deployment:

```bash
$ kubectl --namespace <namespace> get pods -o wide
```

For example:

```bash
$ kubectl --namespace oudns get pods -o wide
```

The output will look similar to the following: 

```
NAME              READY   STATUS    RESTARTS   AGE     IP             NODE          NOMINATED NODE   READINESS GATES
pod/oud-ds-rs-0   1/1     Running   0          22h   10.244.0.195   <Worker Node>   <none>           <none>
pod/oud-ds-rs-1   1/1     Running   0          22h   10.244.0.194   <Worker Node>   <none>           <none>
pod/oud-ds-rs-2   1/1     Running   0          22h   10.244.0.193   <Worker Node>   <none>           <none>
```    



### Scaling up OUD pods

In this example, `replicaCount` is increased to `4` which creates a new OUD pod `oud-ds-rs-3` with associated services created.

You can scale up the number of OUD pods using one of the following methods:

1. [Using a YAML file](#using-a-yaml-file)
1. [Using `--set` argument](#using---set-argument)


#### Using a YAML file

1. Navigate to the `$WORKDIR/kubernetes/helm` directory:

   ```bash
   $ cd $WORKDIR/kubernetes/helm
   ```
   
1. Create a `oud-scaleup-override.yaml` file that contains:


   ```yaml
   replicaCount: 4
   ```

1. Run the following command to scale up the OUD pods:

   ```bash
   $ helm upgrade --namespace <namespace> \
   --values oud-scaleup-override.yaml \
   <release_name> oud-ds-rs --reuse-values
   ```
   
   For example:
   
   ```bash
   $ helm upgrade --namespace oudns \
   --values oud-scaleup-override.yaml \
   oud-ds-rs oud-ds-rs --reuse-values
   ```

#### Using `--set` argument

1. Run the following command to scale up the OUD pods:

   ```bash
   $ helm upgrade --namespace <namespace> \
   --set replicaCount=4 \
   <release_name> oud-ds-rs --reuse-values
   ```

   For example:

   ```bash
   $ helm upgrade --namespace oudns \
   --set replicaCount=4 \
   oud-ds-rs oud-ds-rs --reuse-values
   ```

### Verify the pods

1. Verify the new OUD pod `oud-ds-rs-3` and has started:

   ```bash
   $ kubectl get pod,service -o wide -n <namespace> 
   ```
   
   For example:
   
   ```bash
   $ kubectl get pods,service -n oudns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME              READY   STATUS    RESTARTS   AGE     IP             NODE          NOMINATED NODE   READINESS GATES
   pod/oud-ds-rs-0   1/1     Running   0          22h   10.244.0.195   <Worker Node>   <none>           <none>
   pod/oud-ds-rs-1   1/1     Running   0          22h   10.244.0.194   <Worker Node>   <none>           <none>
   pod/oud-ds-rs-2   1/1     Running   0          22h   10.244.0.193   <Worker Node>   <none>           <none>
   pod/oud-ds-rs-3   1/1     Running   0          17m   10.244.0.193   <Worker Node>   <none>           <none>
     
   NAME                          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE     SELECTOR
   service/oud-ds-rs             ClusterIP   None             <none>        1444/TCP,1888/TCP,1389/TCP,1636/TCP,1080/TCP,1081/TCP,1898/TCP   22h    app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
   service/oud-ds-rs-0           ClusterIP   None             <none>        1444/TCP,1888/TCP,1898/TCP                                       22h    app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-0
   service/oud-ds-rs-1           ClusterIP   None             <none>        1444/TCP,1888/TCP,1898/TCP                                       22h    app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-1
   service/oud-ds-rs-2           ClusterIP   None             <none>        1444/TCP,1888/TCP,1898/TCP                                       22h    app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-2
   service/oud-ds-rs-3           ClusterIP   None             <none>        1444/TCP,1888/TCP,1898/TCP                                       9m9s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-3
   service/oud-ds-rs-http-0      ClusterIP   10.104.112.93    <none>        1080/TCP,1081/TCP                                                22h    app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-0
   service/oud-ds-rs-http-1      ClusterIP   10.103.105.70    <none>        1080/TCP,1081/TCP                                                22h    app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-1
   service/oud-ds-rs-http-2      ClusterIP   10.110.160.107   <none>        1080/TCP,1081/TCP                                                22h    app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-2
   service/oud-ds-rs-http-3      ClusterIP   10.102.93.179    <none>        1080/TCP,1081/TCP                                                9m9s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-3
   service/oud-ds-rs-lbr-admin   ClusterIP   10.99.238.222    <none>        1888/TCP,1444/TCP                                                22h    app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
   service/oud-ds-rs-lbr-http    ClusterIP   10.101.250.196   <none>        1080/TCP,1081/TCP                                                22h    app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
   service/oud-ds-rs-lbr-ldap    ClusterIP   10.104.149.90    <none>        1389/TCP,1636/TCP                                                22h    app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
   service/oud-ds-rs-ldap-0      ClusterIP   10.109.255.221   <none>        1389/TCP,1636/TCP                                                22h    app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-0
   service/oud-ds-rs-ldap-1      ClusterIP   10.111.135.142   <none>        1389/TCP,1636/TCP                                                22h    app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-1
   service/oud-ds-rs-ldap-2      ClusterIP   10.100.8.145     <none>        1389/TCP,1636/TCP                                                22h    app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-2
   service/oud-ds-rs-ldap-3      ClusterIP   10.111.177.46    <none>        1389/TCP,1636/TCP                                                9m9s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-3
   ```
   
   **Note**: It will take several minutes before all the services listed above show. While the `oud-ds-rs-3` pod has a `STATUS` of `0/1` the pod is started but the OUD server associated with it is currently starting. While the pod is starting you can check the startup status in the pod log, by running the following command:

   ```bash
   $ kubectl logs oud-ds-rs-3 -n oudns
   ```


### Scaling down OUD pods

Scaling down OUD pods is performed in exactly the same as in [Scaling up OUD pods](#scaling-up-oud-pods) except the `replicaCount` is reduced to the required number of pods.

Once the kubectl command is executed the pod(s) will move to a `Terminating` state. In the example below `replicaCount` was reduced from `4` to `3` and hence `oud-ds-rs-3` has moved to `Terminating`:

```bash
$ kubectl get pods -n oudns
   
NAME              READY   STATUS        RESTARTS   AGE     IP             NODE          NOMINATED NODE   READINESS GATES
pod/oud-ds-rs-0   1/1     Running       0          22h   10.244.0.195   <Worker Node>   <none>           <none>
pod/oud-ds-rs-1   1/1     Running       0          22h   10.244.0.194   <Worker Node>   <none>           <none>
pod/oud-ds-rs-2   1/1     Running       0          22h   10.244.0.193   <Worker Node>   <none>           <none>
pod/oud-ds-rs-3   1/1     Terminating   0          21m   10.244.0.193   <Worker Node>   <none>           <none>
```

The pod will take a minute or two to stop and then will disappear:

```bash
$ kubectl get pods -n oudns
   
NAME              READY   STATUS        RESTARTS   AGE     IP             NODE          NOMINATED NODE   READINESS GATES
pod/oud-ds-rs-0   1/1     Running       0          22h   10.244.0.195   <Worker Node>   <none>           <none>
pod/oud-ds-rs-1   1/1     Running       0          22h   10.244.0.194   <Worker Node>   <none>           <none>
pod/oud-ds-rs-2   1/1     Running       0          22h   10.244.0.193   <Worker Node>   <none>           <none>
```


