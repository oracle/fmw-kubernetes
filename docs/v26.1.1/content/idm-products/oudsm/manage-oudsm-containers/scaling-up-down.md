---
title: "a) Scaling Up/Down OUDSM Pods "
description: "Describes the steps for scaling up/down for OUDSM pods."
---

### Introduction

This section describes how to increase or decrease the number of OUDSM pods in the Kubernetes deployment.


### View existing OUDSM pods

By default the `oudsm` helm chart deployment starts one pod: `oudsm-1`.

The number of pods started is determined by the `replicaCount`, which is set to `1` by default. A value of `1` starts the pod above.

To scale up or down the number of OUDSM pods, set `replicaCount` accordingly.

Run the following command to view the number of pods in the OUDSM deployment:

```bash
$ kubectl --namespace <namespace> get pods -o wide
```

For example:

```bash
$ kubectl --namespace oudsmns get pods -o wide
```

The output will look similar to the following: 

```
NAME          READY   STATUS    RESTARTS   AGE   IP            NODE             NOMINATED NODE   READINESS GATES
pod/oudsm-1   1/1     Running   0          73m   10.244.0.19   <worker-node>   <none>           <none>
```    

### Scaling up OUDSM pods

In this example, `replicaCount` is increased to `2` which creates a new OUDSM pod `oudsm-2` with associated services created.

You can scale up the number of OUDSM pods using one of the following methods:

1. [Using a YAML file](#using-a-yaml-file)
1. [Using `--set` argument](#using---set-argument)


#### Using a YAML file

1. Navigate to the `$WORKDIR/kubernetes/helm` directory:

   ```bash
   $ cd $WORKDIR/kubernetes/helm
   ```
   
1. Create a `oudsm-scaleup-override.yaml` file that contains:


   ```yaml
   replicaCount: 2
   ```

1. Run the following command to scale up the OUDSM pods:

   ```bash
   $ helm upgrade --namespace <namespace> \
   --values oudsm-scaleup-override.yaml \
   <release_name> oudsm --reuse-values
   ```
   
   For example:
   
   ```bash
   $ helm upgrade --namespace oudsmns \
   --values oudsm-scaleup-override.yaml \
   oudsm oudsm --reuse-values
   ```
   

#### Using `--set` argument

1. Run the following command to scale up the OUDSM pods:

   ```bash
   $ helm upgrade --namespace <namespace> \
   --set replicaCount=2 \
   <release_name> oudsm --reuse-values
   ```

   For example:

   ```bash
   $ helm upgrade --namespace oudsmns \
   --set replicaCount=2 \
   oudsm oudsm --reuse-values
   ```


### Verify the pods

1. Verify the new OUDSM pod `oudsm-2` has started:

   ```bash
   $ kubectl get pod,service -o wide -n <namespace> 
   ```
   
   For example:
   
   ```bash
   $ kubectl get pods,service -n oudsmns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME          READY   STATUS    RESTARTS   AGE   IP            NODE            NOMINATED NODE   READINESS GATES
   pod/oudsm-1   1/1     Running   0          88m   10.244.0.19   <worker-node>   <none>           <none>
   pod/oudsm-2   1/1     Running   0          15m   10.245.3.45   <worker-node>   <none>           <none>
	
   NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE   SELECTOR
   service/oudsm-1     ClusterIP   10.96.108.200   <none>        7001/TCP,7002/TCP   88m   app.kubernetes.io/instance=oudsm,app.kubernetes.io/name=oudsm,oudsm/instance=oudsm-1
   service/oudsm-2     ClusterIP   10.96.31.201    <none>        7001/TCP,7002/TCP   15m   app.kubernetes.io/instance=oudsm,app.kubernetes.io/name=oudsm,oudsm/instance=oudsm-2
   service/oudsm-lbr   ClusterIP   10.96.41.201    <none>        7001/TCP,7002/TCP   73m   app.kubernetes.io/instance=oudsm,app.kubernetes.io/name=oudsm
   ```
   
   **Note**: It will take several minutes before all the services listed above show. While the `oudsm-2` pod has a `STATUS` of `0/1` the pod is started but the OUDSM server associated with it is currently starting. While the pod is starting you can check the startup status in the pod log, by running the following command:

   ```bash
   $ kubectl logs oudsm-2 -n oudsmns
   ```


### Scaling down OUDSM pods

Scaling down OUDSM pods is performed in exactly the same as in [Scaling up OUDSM pods](#scaling-up-oudsm-pods) except the `replicaCount` is reduced to the required number of pods.

Once the kubectl command is executed the pod(s) will move to a `Terminating` state. In the example below `replicaCount` was reduced from `2` to `1` and hence `oudsm-2` has moved to `Terminating`:

```bash
$ kubectl get pods -n oudsmns
   
NAME          READY   STATUS        RESTARTS   AGE   IP            NODE            NOMINATED NODE   READINESS GATES
pod/oudsm-1   1/1     Running       0          92m   10.244.0.19   <worker-node>   <none>           <none>
pod/oudsm-2   1/1     Terminating   0          19m   10.245.3.45   <worker-node>   <none>           <none>
```

The pod will take a minute or two to stop and then will disappear:

```bash
$ kubectl get pods -n oudsmns
   
NAME          READY   STATUS    RESTARTS   AGE   IP            NODE            NOMINATED NODE   READINESS GATES
pod/oudsm-1   1/1     Running   0          94m   10.244.0.19   <worker-node>   <none>           <none>
```


