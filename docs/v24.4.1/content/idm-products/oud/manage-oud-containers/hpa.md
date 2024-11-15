---
title: "d. Kubernetes Horizontal Pod Autoscaler"
description: "Describes the steps for implementing the Horizontal Pod Autoscaler."
---


1. [Prerequisite configuration](#prerequisite-configuration)
1. [Deploy the Kubernetes Metrics Server](#deploy-the-kubernetes-metrics-server)
   1. [Troubleshooting](#troubleshooting)
1. [Deploy HPA](#deploy-hpa)
1. [Testing HPA](#testing-hpa)
1. [Delete the HPA](#delete-the-hpa)
1. [Other considerations](#other-considerations)


Kubernetes Horizontal Pod Autoscaler (HPA) allows automatic scaling (up and down) of the OUD servers. If load increases then extra OUD servers will be started as required. Similarly, if load decreases, OUD servers will be automatically shutdown.

For more information on HPA, see [Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/).

The instructions below show you how to configure and run an HPA to scale OUD servers, based on CPU utilization or memory resource metrics. 

**Note**: If you enable HPA and then decide you want to start/stop/scale OUD servers manually as per [Scaling Up/Down OUD Pods](../scaling-up-down), it is recommended to delete HPA beforehand as per [Delete the HPA](#delete-the-hpa).

### Prerequisite configuration

In order to use HPA, OUD must have been created with the required `resources` parameter as per [Create OUD instances](../../create-oud-instances#create-oud-instances). For example:

   ```
   oudConfig:
    # memory, cpu parameters for both requests and limits for oud instances
     resources:
       limits:
         cpu: "1"
         memory: "8Gi"
       requests:
         cpu: "500m" 
         memory: "4Gi"
   ```

If you created the OUD servers at any point since July 22 (22.3.1) then these values are the defaults. You can check using the following command:

   ```
   $ helm show values oud-ds-rs -n oudns
   ```
   
   The output will look similar to the following:
   
   ```
   ...
   # memory, cpu parameters for both requests and limits for oud instances
     resources:
       requests:
         memory: "4Gi"
         cpu: "500m"
       limits:
         memory: "8Gi"
         cpu: "2"
    ...
   ```

### Deploy the Kubernetes Metrics Server

Before deploying HPA you must deploy the Kubernetes Metrics Server.

1. Check to see if the Kubernetes Metrics Server is already deployed:

   ```
   $ kubectl get pods -n kube-system | grep metric
   ```
   If a row is returned as follows, then Kubernetes Metric Server is deployed and you can move to [Deploy HPA](#deploy-hpa).
   
   ```
   metrics-server-d9694457-mf69d           1/1     Running   0             5m13s
   ```
   
1. If no rows are returned by the previous command, then the Kubernetes Metric Server needs to be deployed. Run the following commands to get the `components.yaml`:
   
   ```
   $ mkdir $WORKDIR/kubernetes/hpa
   $ cd $WORKDIR/kubernetes/hpa
   $ wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
   ```
   
1. Deploy the Kubernetes Metrics Server by running the following command:

   ```
   $ kubectl apply -f components.yaml
   ```
   
   The output will look similar to the following:
   
   ```
   serviceaccount/metrics-server created
   clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader created
   clusterrole.rbac.authorization.k8s.io/system:metrics-server created
   rolebinding.rbac.authorization.k8s.io/metrics-server-auth-reader created
   clusterrolebinding.rbac.authorization.k8s.io/metrics-server:system:auth-delegator created
   clusterrolebinding.rbac.authorization.k8s.io/system:metrics-server created
   service/metrics-server created
   deployment.apps/metrics-server created
   apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io created
   ```
   
1. Run the following command to check Kubernetes Metric Server is running:

   ```
   $ kubectl get pods -n kube-system | grep metric
   ```
   
   Make sure the pod has a `READY` status of `1/1`:
   
   ```
   metrics-server-d9694457-mf69d           1/1     Running   0             39s
   ```
   
 
#### Troubleshooting

If the Kubernetes Metric Server does not reach the `READY 1/1` state, run the following commands:
   
```
$ kubectl describe pod <metrics-server-pod> -n kube-system
$ kubectl logs <metrics-server-pod> -n kube-system
```
   
If you see errors such as:
   
```
Readiness probe failed: HTTP probe failed with statuscode: 500
```
   
and:
   
```
E0907 13:07:50.937308       1 scraper.go:140] "Failed to scrape node" err="Get \"https://X.X.X.X:10250/metrics/resource\": x509: cannot validate certificate for 100.105.18.113 because it doesn't contain any IP SANs" node="worker-node1"
```
   
then you may need to install a valid cluster certificate for your Kubernetes cluster.

For testing purposes, you can resolve this issue by:
   
1. Delete the Kubernetes Metrics Server by running the following command:

   ```
   $ kubectl delete -f $WORKDIR/kubernetes/hpa/components.yaml
   ``` 
   
1. Edit the `$WORKDIR/hpa/components.yaml` and locate the `args:` section. Add  `kubelet-insecure-tls` to the arguments. For example:

   ```
   spec:
     containers:
     - args:
       - --cert-dir=/tmp
       - --secure-port=4443
       - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
       - --kubelet-use-node-status-port
       - --kubelet-insecure-tls
       - --metric-resolution=15s
       image: registry.k8s.io/metrics-server/metrics-server:v0.6.4
	...
   ```

1. Deploy the Kubenetes Metrics Server using the command:

   ```
   $ kubectl apply -f components.yaml
   ```
   
   Run the following and make sure the READY status shows `1/1`:
   
   ```
   $ kubectl get pods -n kube-system | grep metric
   ```
   
   The output should look similar to the following:
      
   ```
   metrics-server-d9694457-mf69d           1/1     Running   0             40s
   ```
   
   
### Deploy HPA

The steps below show how to configure and run an HPA to scale OUD, based on the CPU or memory utilization resource metrics.

Assuming the example OUD configuration in [Create OUD instances](../../create-oud-instances#create-oud-instances), three OUD servers are started by default (`oud-ds-rs-0`, `oud-ds-rs-1`, `oud-ds-rs-2`). 

In the following example an HPA resource is created, targeted at the statefulset `oud-ds-rs`. This resource will autoscale OUD servers from a minimum of 3 OUD servers up to 5 OUD servers. Scaling up will occur when the average CPU is consistently over 70%. Scaling down will occur when the average CPU is consistently below 70%.

 
1. Navigate to the `$WORKDIR/kubernetes/hpa` and create an `autoscalehpa.yaml` file that contains the following.

   ```
   #
   apiVersion: autoscaling/v2
   kind: HorizontalPodAutoscaler
   metadata:
     name: oud-sts-hpa
     namespace: oudns
   spec:
	 scaleTargetRef:
       apiVersion: apps/v1
       kind: StatefulSet
       name: oud-ds-rs #statefulset name of oud
     behavior:
       scaleDown:
         stabilizationWindowSeconds: 60
       scaleUp:
         stabilizationWindowSeconds: 60
     minReplicas: 3
     maxReplicas: 5
     metrics:
     - type: Resource
       resource:
         name: cpu
         target:
           type: Utilization
           averageUtilization: 70
   ```
   
   **Note** : `minReplicas` should match the number of OUD servers started by default. Set `maxReplicas` to the maximum amount of OUD servers that can be started.
      
   **Note**:  To find the statefulset name, in this example `oud-ds-rs`, run "`kubectl get statefulset -n oudns`".
   
   **Note**: For setting HPA based on Memory Metrics, update the metrics block with the following content. Please note we recommend using only CPU or Memory, not both.
   
   ```
   metrics:
   - type: Resource
     resource:
       name: memory
       target:
         type: Utilization
         averageUtilization: 70
    ```
 

1. Run the following command to create the autoscaler:

   ```
   $ kubectl apply -f autoscalehpa.yaml
   ```
   
   The output will look similar to the following:
   
   ```
   horizontalpodautoscaler.autoscaling/oud-sts-hpa created
   ```
   
1. Verify the status of the autoscaler by running the following:

   ```
   $ kubectl get hpa -n oudns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME          REFERENCE               TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
   oud-sts-hpa   StatefulSet/oud-ds-rs   5%/70%    3         5         3          33s
   ```
   
   In the example above, this shows that CPU is currently running at 5% for the `oud-sts-hpa`.
   

### Testing HPA

1. Check the current status of the OUD servers:

   ```
   $ kubectl get pods -n oudns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                              READY   STATUS      RESTARTS   AGE
   oud-ds-rs-0                       1/1     Running     0          5h15m
   oud-ds-rs-1                       1/1     Running     0          5h9m
   oud-ds-rs-2                       1/1     Running     0          5h2m
   oud-pod-cron-job-28242120-bwtcz   0/1     Completed   0          61m
   oud-pod-cron-job-28242150-qf8fg   0/1     Completed   0          31m
   oud-pod-cron-job-28242180-q69lm   0/1     Completed   0          92s
   ```
   
   In the above `oud-ds-rs-0`, `oud-ds-rs-0`, `oud-ds-rs-2` are running.
   


1. To test HPA can scale up the OUD servers, run the following commands:

   ```
   $ kubectl exec --stdin --tty oud-ds-rs-0 -n oudns -- /bin/bash
   ```
   
   This will take you inside a bash shell inside the `oud-ds-rs-0` pod:

   ```
   [oracle@oud-ds-rs-0 oracle]$
   ```
   
   Inside the bash shell, run the following command to increase the load on the CPU:
   
   ```
   [oracle@oud-ds-rs-0 oracle]$ dd if=/dev/zero of=/dev/null
   ```
   
   This command will continue to run in the foreground.

1. Repeat the step above for the oud-ds-rs-1 pod:

   ```
   $ kubectl exec --stdin --tty oud-ds-rs-1 -n oudns -- /bin/bash
   [oracle@oud-ds-rs-1 oracle]$
   [oracle@oud-ds-rs-1 oracle]$ dd if=/dev/zero of=/dev/null
   ```
   
   

1. In a command window outside the bash shells, run the following command to view the current CPU usage:

   ```
   $ kubectl get hpa -n oudns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME          REFERENCE               TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
   oud-sts-hpa   StatefulSet/oud-ds-rs   125%/70%   3         5         3          5m15s
   ```
   
   In the above example the CPU has increased to 125%. As this is above the 70% limit, the autoscaler increases the replicas by starting additional OUD servers.
   
1. Run the following to see if any more OUD servers are started:
   
   ```
   $ kubectl get pods -n oudns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                              READY   STATUS      RESTARTS   AGE
   oud-ds-rs-0                       1/1     Running     0          5h50m
   oud-ds-rs-1                       1/1     Running     0          5h44m
   oud-ds-rs-2                       1/1     Running     0          5h37m
   oud-ds-rs-3                       1/1     Running     0          9m29s
   oud-ds-rs-4                       1/1     Running     0          5m17s
   oud-pod-cron-job-28242150-qf8fg   0/1     Completed   0          66m
   oud-pod-cron-job-28242180-q69lm   0/1     Completed   0          36m
   oud-pod-cron-job-28242210-kn7sv   0/1     Completed   0          6m28s
   ```
   
   In the example above one more OUD server has started (`oud-ds-rs-4`).
   
   **Note**: It may take some time for the server to appear and start. Once the server is at `READY` status of `1/1`, the server is started.
   

1. To stop the load on the CPU, in both bash shells, issue a Control C, and then exit the bash shell:

   ```
   [oracle@oud-ds-rs-0 oracle]$ dd if=/dev/zero of=/dev/null
   ^C
   [oracle@oud-ds-rs-0 oracle]$ exit
   ```
   
1. Run the following command to view the current CPU usage:

   ```
   $ kubectl get hpa -n oudns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME          REFERENCE               TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
   oud-sts-hpa   StatefulSet/oud-ds-rs   4%/70%    3         5         5          40m
   ```
   
   In the above example CPU has dropped to 4%. As this is below the 70% threshold, you should see the autoscaler scale down the servers:
   
   ```
   $ kubectl get pods -n oudns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                              READY   STATUS        RESTARTS   AGE
   oud-ds-rs-0                       1/1     Running       0          5h54m
   oud-ds-rs-1                       1/1     Running       0          5h48m
   oud-ds-rs-2                       1/1     Running       0          5h41m
   oud-ds-rs-3                       1/1     Running       0          13m
   oud-ds-rs-4                       1/1     Terminating   0          8m27s
   oud-pod-cron-job-28242150-qf8fg   0/1     Completed     0          70m
   oud-pod-cron-job-28242180-q69lm   0/1     Completed     0          40m
   oud-pod-cron-job-28242210-kn7sv   0/1     Completed     0          10m
   ```
     
   Eventually, the extra server will disappear:
   
   ```
   NAME                              READY   STATUS        RESTARTS   AGE
   oud-ds-rs-0                       1/1     Running       0          5h57m
   oud-ds-rs-1                       1/1     Running       0          5h51m
   oud-ds-rs-2                       1/1     Running       0          5h44m
   oud-ds-rs-3                       1/1     Running       0          16m
   oud-pod-cron-job-28242150-qf8fg   0/1     Completed     0          73m
   oud-pod-cron-job-28242180-q69lm   0/1     Completed     0          43m
   oud-pod-cron-job-28242210-kn7sv   0/1     Completed     0          13m
   ```


### Delete the HPA

1. If you need to delete the HPA, you can do so by running the following command:

   ```
   $ cd $WORKDIR/kubernetes/hpa
   $ kubectl delete -f autoscalehpa.yaml
   ```
  
### Other considerations

+ If HPA is deployed and you need to upgrade the OUD image, then you must delete the HPA before upgrading. Once the upgrade is successful you can deploy HPA again.
+ If you choose to scale up or scale down an OUD server manually as per [Scaling Up/Down OUD Pods](../scaling-up-down), then it is recommended to delete the HPA before doing so.


   
   
   
	





