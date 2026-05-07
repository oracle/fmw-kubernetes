---
title: "a. Domain Lifecycle"
description: "Learn about the domain lifecycle of an OHS container."
---

1. [View existing OHS servers](#view-existing-ohs-servers)
1. [Starting/Scaling up OHS servers](#startingscaling-up-ohs-servers)
1. [Stopping/Scaling down OHS servers](#stoppingscaling-down-ohs-servers)



This document shows the basic operations for scaling servers in OHS containers. 

 
### View existing OHS servers

The default OHS deployment starts one OHS server (assuming `replicas: 1` in `ohs.yaml`).

To view the running OHS servers, run the following command:

```bash
$ kubectl get pods -n <namespace>
```

For example:

```bash
$ kubectl get pods -n ohsns
```

The output should look similar to the following:

```
NAME                         READY   STATUS    RESTARTS   AGE
ohs-domain-d5b648bc5-vkp4s   1/1     Running   0          5h17m
```

### Starting/Scaling up OHS Servers

The number of OHS Servers running is dependent on the `replicas` parameter configured for OHS. 

1. Run the following kubectl command to start additional OHS servers:

   ```bash
   $ kubectl -n <namespace> patch deployment ohs-domain -p '{"spec": {"replicas": <replica count>}}' 
   ```
	
   where `<replica count>` is the number of OHS servers to start.

   In the example below, two additional OHS servers are started:

   ```bash
   $ kubectl -n ohsns patch deployment  ohs-domain -p '{"spec": {"replicas": 3}}'
   ```

   The output will look similar to the following:

   ```
   deployment.apps/ohs-domain patched
   ```


1. Whilst the new OHS containers are being started, you can run the following command to monitor the progress:
   
   ```bash
   $ kubectl get pods -n <namespace> -w
   ```
	
   For example:
	
   ```bash
   $ kubectl get pods -n ohsns -w
   ```   

   The output will look similar to the following:
	
   ```
   NAME                         READY   STATUS              RESTARTS   AGE
   ohs-domain-d5b648bc5-2q8bw   0/1     ContainerCreating   0          26s
   ohs-domain-d5b648bc5-qvdjn   0/1     Running             0          26s
   ohs-domain-d5b648bc5-vkp4s   1/1     Running             0          5h21m
   ```
	
   Two new OHS pods have now been created, in this example `ohs-domain-d5b648bc5-2q8bw` and `ohs-domain-d5b648bc5-qvdjn`. 
	
1. To check what is happening while the pods are in `ContainerCreating` status, you can run:
	
   ```
   $ kubectl describe pod <podname> -n <namespace>
   ```
	
1. To check what is happening while the pods are in  `0/1 Running` status, you can run:
	
   ```
   $ kubectl logs -f <pod> -n <namespace>
   ```
	
1. Once everything is started you should see all the additional OHS containers are running (`READY 1/1`):
	
   ```
   NAME                         READY   STATUS    RESTARTS      AGE
   ohs-domain-d5b648bc5-2q8bw   1/1     Running   0             9m34s
   ohs-domain-d5b648bc5-qvdjn   1/1     Running   0             9m34s
   ohs-domain-d5b648bc5-vkp4s   1/1     Running   0             5h30m
   ```



### Stopping/Scaling down OHS Servers

As mentioned in the previous section, the number of OHS servers running is dependent on the `replicas` parameter configured. To stop one or more OHS servers, perform the following steps:

1. Run the following kubectl command to scale down OHS servers:

   ```bash
   $ kubectl -n <namespace> patch deployment ohs-domain -p '{"spec": {"replicas": <replica count>}}' 
   ```
	
   where `<replica count>` is the number of OHS servers you want to run.

   In the example below, replicas is dropped to `1` so only one OHS is running:

   ```bash
   $ kubectl -n ohsns patch deployment  ohs-domain -p '{"spec": {"replicas": 1}}'
   ```

   The output will look similar to the following:

   ```
   deployment.apps/ohs-domain patched
   ```

1. Run the following kubectl command to view the pods:  

   ```bash 
   $ kubectl get pods -n <namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl get pods -n ohsns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                         READY   STATUS        RESTARTS   AGE 
   ohs-domain-d5b648bc5-2q8bw   0/1     Terminating   0          12m
   ohs-domain-d5b648bc5-qvdjn   0/1     Terminating   0          12m
   ohs-domain-d5b648bc5-vkp4s   1/1     Running       0          5h31m
   ```
   
   Two pods now have a `STATUS` of `Terminating`. Keep executing the command until the pods have disappeared and you are left with the one OHS pod:
   
   ```
   NAME                         READY   STATUS    RESTARTS   AGE 
   ohs-domain-d5b648bc5-vkp4s   1/1     Running   0          5h32m
   ```

