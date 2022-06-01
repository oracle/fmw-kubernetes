---
title: "a) Scaling Up/Down OID Pods "
description: "Describes the steps for scaling up/down for OID pods."
---

### Introduction

This section describes how to increase or decrease the number of OID pods in the Kubernetes deployment.


### View existing OID pods

By default the `oid` helm chart deployment starts two pods:  `oidhost1` and `oidhost2`.

The number of pods started is determined by the `replicaCount`, which is set to `1` by default. A value of `1` starts the two pods above.

To scale up or down the number of OID pods, set `replicaCount` accordingly.

Run the following command to view the number of pods in the OID deployment:

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
pod/oidhost1   1/1     Running   0          34m   10.244.0.195   <Worker Node>   <none>           <none>
pod/oidhost2   1/1     Running   0          34m   10.244.0.194   <Worker Node>   <none>           <none>
```    


### Scaling up OID pods

In this example, `replicaCount` is increased to `2` which creates a new OID pod `oidhost3` with associated services created.

You can scale up the number of OID pods using one of the following methods:

1. [Using a YAML file](#using-a-yaml-file)
1. [Using `--set` argument](#using---set-argument)


#### Using a YAML file

1. Navigate to the `$WORKDIR/kubernetes/helm` directory:

   ```bash
   $ cd $WORKDIR/kubernetes/helm
   ```
   
1. Create a `oid-scaleup-override.yaml` file that contains:


   ```yaml
   replicaCount: 2
   ```

1. Run the following command to scale up the OID pods:

   ```bash
   $ helm upgrade --namespace <namespace> \
   --values oid-scaleup-override.yaml \
   <release_name> oid --reuse-values
   ```
   
   For example:
   
   ```bash
   $ helm upgrade --namespace oidns \
   --values oid-scaleup-override.yaml \
   oid oid --reuse-values
   ```

#### Using `--set` argument

1. Run the following command to scale up the OID pods:

   ```bash
   $ helm upgrade --namespace <namespace> \
   --set replicaCount=2 \
   <release_name> oid --reuse-values
   ```

   For example:

   ```bash
   $ helm upgrade --namespace oidns \
   --set replicaCount=2 \
   oid oid --reuse-values
   ```

### Verify the pods

1. Verify the new OID pod `oidhost3` and has started:

   ```bash
   $ kubectl get pod,service -o wide -n <namespace> 
   ```
   
   For example:
   
   ```bash
   $ kubectl get pods -n oidns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME           READY   STATUS    RESTARTS   AGE     IP           NODE            NOMINATED NODE   READINESS GATES
   pod/oidhost1   1/1     Running   0          45m   10.244.0.194   <Worker Node>   <none>           <none>
   pod/oidhost2   1/1     Running   0          45m   10.244.0.193   <Worker Node>   <none>           <none>
   pod/oidhost3   1/1     Running   0          17m   10.244.0.195   <Worker Node>   <none>           <none>
     
   NAME                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                               AGE
   service/oid-lbr-ldap   ClusterIP   10.110.118.113   <none>        3060/TCP,3131/TCP                     45m
   service/oidhost1       ClusterIP   10.97.17.125     <none>        3060/TCP,3131/TCP,7001/TCP,7002/TCP   45m
   service/oidhost2       ClusterIP   10.106.32.187    <none>        3060/TCP,3131/TCP                     45m
   service/oidhost3       ClusterIP   10.105.33.184    <none>        3060/TCP,3131/TCP                     17m
   ```
   
   **Note**: It will take several minutes before all the services listed above show. While the `oidhost3` pod has a `STATUS` of `0/1` the pod is started but the OID server associated with it is currently starting. While the pod is starting you can check the startup status in the pod log, by running the following command:

   ```bash
   $ kubectl logs oidhost3 -n oidns
   ```


### Scaling down OID pods

Scaling down OID pods is performed in exactly the same as in [Scaling up OID pods](#scaling-up-oid-pods) except the `replicaCount` is reduced to the required number of pods.

Once the kubectl command is executed the pod(s) will move to a `Terminating` state. In the example below `replicaCount` was reduced from `2` to `1` and hence `oidhost3` has moved to `Terminating`:

```bash
$ kubectl get pods -n oidns
   
NAME           READY   STATUS        RESTARTS   AGE   IP             NODE            NOMINATED NODE   READINESS GATES
pod/oidhost1   1/1     Running       0          49m   10.244.0.194   <Worker Node>   <none>           <none>
pod/oidhost2   1/1     Running       0          49m   10.244.0.193   <Worker Node>   <none>           <none>
pod/oidhost3   1/1     Terminating   0          21m   10.244.0.195   <Worker Node>   <none>           <none>
```

The pod will take a minute or two to stop and then will disappear:

```bash
$ kubectl get pods -n oidns
   
NAME           READY   STATUS        RESTARTS   AGE   IP             NODE            NOMINATED NODE   READINESS GATES
pod/oidhost1   1/1     Running       0          51m   10.244.0.194   <Worker Node>   <none>           <none>
pod/oidhost2   1/1     Running       0          51m   10.244.0.193   <Worker Node>   <none>           <none>
```


