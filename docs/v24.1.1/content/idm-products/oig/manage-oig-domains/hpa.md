---
title: "f. Kubernetes Horizontal Pod Autoscaler"
description: "Describes the steps for implementing the Horizontal Pod Autoscaler."
---


1. [Prerequisite configuration](#prerequisite-configuration)
1. [Deploy the Kubernetes Metrics Server](#deploy-the-kubernetes-metrics-server)
   1. [Troubleshooting](#troubleshooting)
1. [Deploy HPA](#deploy-hpa)
1. [Testing HPA](#testing-hpa)
1. [Delete the HPA](#delete-the-hpa)
1. [Other considerations](#other-considerations)


Kubernetes Horizontal Pod Autoscaler (HPA) is supported from Weblogic Kubernetes Operator 4.0.X and later.

HPA allows automatic scaling (up and down) of the OIG Managed Servers. If load increases then extra OIG Managed Servers will be started as required, up to the value `configuredManagedServerCount` defined when the domain was created (see [Prepare the create domain script](../../create-oig-domains#prepare-the-create-domain-script)). Similarly, if load decreases, OIG Managed Servers will be automatically shutdown.

For more information on HPA, see [Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/).

The instructions below show you how to configure and run an HPA to scale an OIG cluster (`governancedomain-oim-cluster`) resource, based on CPU utilization or memory resource metrics. If required, you can also perform the following for the `governancedomain-soa-cluster`.

**Note**: If you enable HPA and then decide you want to start/stop/scale OIG Managed servers manually as per [Domain Life Cycle](../domain-lifecycle), it is recommended to delete HPA beforehand as per [Delete the HPA](#delete-the-hpa).

### Prerequisite configuration

In order to use HPA, the OIG domain must have been created with the required `resources` parameter as per [Set the OIM server memory parameters](../../create-oig-domains#setting-the-oim-server-memory-parameters). For example:

   ```
   serverPod:
     env:
     - name: USER_MEM_ARGS
       value: "-XX:+UseContainerSupport -Djava.security.egd=file:/dev/./urandom -Xms8192m -Xmx8192m"
     resources:
       limits:
         cpu: "2"
         memory: "8Gi"
       requests:
         cpu: "1000m"
         memory: "4Gi"
   ```

If you created the OIG domain without setting these parameters, then you can update the domain using the following steps:

1. Run the following command to edit the cluster:

   ```
   $ kubectl edit cluster governancedomain-oim-cluster -n oigns
   ```
   
   **Note**: This opens an edit session for the `governancedomain-oim-cluster` where parameters can be changed using standard vi commands.

1. In the edit session, search for `spec:`, and then look for the replicas parameter under `clusterName: oim_cluster`.  Change the entry so it looks as follows:

   ```
   spec:
     clusterName: oim_cluster
     replicas: 1
     serverPod:
       env:
       - name: USER_MEM_ARGS
         value: -XX:+UseContainerSupport -Djava.security.egd=file:/dev/./urandom -Xms8192m -Xmx8192m
       resources:
         limits:
           cpu: "2"
           memory: 8Gi
         requests:
           cpu: 1000m
           memory: 4Gi
     serverService:
       precreateService: true
	   ...
    ```

1. Save the file and exit (:wq!)

   The output will look similar to the following:

   ```
   cluster.weblogic.oracle/governancedomain-oim-cluster edited
   ```

   The OIG Managed Server pods will then automatically be restarted.

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
E0907 13:07:50.937308       1 scraper.go:140] "Failed to scrape node" err="Get \"https://100.105.18.113:10250/metrics/resource\": x509: cannot validate certificate for 100.105.18.113 because it doesn't contain any IP SANs" node="worker-node1"
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

The steps below show how to configure and run an HPA to scale the `governancedomain-oim-cluster`, based on the CPU or memory utilization resource metrics.

The default OIG deployment creates the cluster `governancedomain-oim-cluster` which starts one OIG Managed Server (`oim_server1`). The deployment also creates, but doesn’t start, four extra OIG Managed Servers (`oim-server2` to `oim-server5`). 

In the following example an HPA resource is created, targeted at the cluster resource `governancedomain-oim-cluster`. This resource will autoscale OIG Managed Servers from a minimum of 1 cluster member up to 5 cluster members. Scaling up will occur when the average CPU is consistently over 70%. Scaling down will occur when the average CPU is consistently below 70%.

 
1. Navigate to the `$WORKDIR/kubernetes/hpa` and create an `autoscalehpa.yaml` file that contains the following.

   ```
   #
   apiVersion: autoscaling/v2
   kind: HorizontalPodAutoscaler
   metadata:
     name: governancedomain-oim-cluster-hpa
     namespace: oigns
   spec:
     scaleTargetRef:
       apiVersion: weblogic.oracle/v1
       kind: Cluster
       name: governancedomain-oim-cluster
     behavior:
       scaleDown:
         stabilizationWindowSeconds: 60
       scaleUp:
         stabilizationWindowSeconds: 60
     minReplicas: 1
     maxReplicas: 5
     metrics:
     - type: Resource
       resource:
         name: cpu
         target:
           type: Utilization
           averageUtilization: 70
   ```
   
   **Note** : `minReplicas` and `maxReplicas` should match your current domain settings.
   
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
   horizontalpodautoscaler.autoscaling/governancedomain-oim-cluster-hpa created
   ```
   
1. Verify the status of the autoscaler by running the following:

   ```
   $ kubectl get hpa -n oigns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                               REFERENCE                              TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
   governancedomain-oim-cluster-hpa   Cluster/governancedomain-oim-cluster   16%/70%   1         5         1          20s
   ```
   
   In the example above, this shows that CPU is currently running at 16% for the `governancedomain-oim-cluster-hpa`.
   

### Testing HPA

1. Check the current status of the OIG Managed Servers:

   ```
   $ kubectl get pods -n oigns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                                                        READY   STATUS      RESTARTS   AGE
   governancedomain-adminserver                                1/1     Running     0          20m
   governancedomain-create-fmw-infra-sample-domain-job-8wd2b   0/1     Completed   0          2d18h
   governancedomain-oim-server1                                1/1     Running     0          17m
   governancedomain-soa-server1                                1/1     Running     0          17m
   helper                                                      1/1     Running     0          2d18h
   ```
   
   In the above only `governancedomain-oim-server1` is running.
   


1. To test HPA can scale up the WebLogic cluster `governancedomain-oim-cluster`, run the following commands:

   ```
   $ kubectl exec --stdin --tty governancedomain-oim-server1 -n oigns -- /bin/bash
   ```
   
   This will take you inside a bash shell inside the `oim_server1` pod:

   ```
   [oracle@governancedomain-oim-server1 oracle]$
   ```
   
   Inside the bash shell, run the following command to increase the load on the CPU:
   
   ```
   [oracle@governancedomain-oim-server1 oracle]$ dd if=/dev/zero of=/dev/null
   ```
   
   This command will continue to run in the foreground.
   
   

1. In a command window outside the bash shell, run the following command to view the current CPU usage:

   ```
   $ kubectl get hpa -n oigns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                               REFERENCE                              TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
   governancedomain-oim-cluster-hpa   Cluster/governancedomain-oim-cluster   386%/70%   1         5         1          2m47s
   ```
   
   In the above example the CPU has increased to 386%. As this is above the 70% limit, the autoscaler increases the replicas on the Cluster resource and the operator responds by starting additional cluster members.
   
1. Run the following to see if any more OIG Managed Servers are started:
   
   ```
   $ kubectl get pods -n oigns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                                                     READY   STATUS      RESTARTS      AGE
   governancedomain-adminserver                                1/1     Running     0          30m
   governancedomain-create-fmw-infra-sample-domain-job-8wd2b   0/1     Completed   0          2d18h
   governancedomain-oim-server1                                1/1     Running     0          27m
   governancedomain-oim-server2                                1/1     Running     0          10m
   governancedomain-oim-server3                                1/1     Running     0          10m
   governancedomain-oim-server4                                1/1     Running     0          10m
   governancedomain-oim-server5                                1/1     Running     0          10m
   governancedomain-soa-server1                                1/1     Running     0          27m
   helper                                                      1/1     Running     0          2d18h
   ```
   
   In the example above four more OIG Managed Servers have been started (`oim-server2` - `oim-server5`).
   
   **Note**: It may take some time for the servers to appear and start. Once the servers are at `READY` status of `1/1`, the servers are started.
   

1. To stop the load on the CPU, in the bash shell, issue a Control C, and then exit the bash shell:

   ```
   [oracle@governancedomain-oim-server1 oracle]$ dd if=/dev/zero of=/dev/null
   ^C
   [oracle@governancedomain-oim-server1 oracle]$ exit
   ```
   
1. Run the following command to view the current CPU usage:

   ```
   $ kubectl get hpa -n oigns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                               REFERENCE                              TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
   governancedomain-oim-cluster-hpa   Cluster/governancedomain-oim-cluster   33%/70%   1         5         5          37m
   ```
   
   In the above example CPU has dropped to 33%. As this is below the 70% threshold, you should see the autoscaler scale down the servers:
   
   ```
   $ kubectl get pods -n oigns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                                                        READY   STATUS        RESTARTS      AGE
   governancedomain-adminserver                                1/1     Running       0             43m
   governancedomain-create-fmw-infra-sample-domain-job-8wd2b   0/1     Completed     0             2d18h
   governancedomain-oim-server1                                1/1     Running       0             40m
   governancedomain-oim-server2                                1/1     Running       0             13m
   governancedomain-oim-server3                                1/1     Running       0             13m
   governancedomain-oim-server4                                1/1     Running       0             13m
   governancedomain-oim-server5                                0/1     Terminating   0             13m
   governancedomain-soa-server1                                1/1     Running       0             40m
   helper                                                      1/1     Running       0             2d19h
   ```
     
   Eventually, all the servers except `oim-server1` will disappear:
   
   ```
   NAME                                                     READY   STATUS      RESTARTS       AGE
   governancedomain-adminserver                                1/1     Running       0             44m
   governancedomain-create-fmw-infra-sample-domain-job-8wd2b   0/1     Completed     0             2d18h
   governancedomain-oim-server1                                1/1     Running       0             41m
   governancedomain-soa-server1                                1/1     Running       0             41m
   helper                                                      1/1     Running       0             2d20h
   ```


### Delete the HPA

1. If you need to delete the HPA, you can do so by running the following command:

   ```
   $ cd $WORKDIR/kubernetes/hpa
   $ kubectl delete -f autoscalehpa.yaml
   ```
  
### Other considerations

+ If HPA is deployed and you need to upgrade the OIG image, then you must delete the HPA before upgrading. Once the upgrade is successful you can deploy HPA again.
+ If you choose to start/stop an OIG Managed Server manually as per [Domain Life Cycle](../domain-lifecycle), then it is recommended to delete the HPA before doing so.


   
   
   
	





