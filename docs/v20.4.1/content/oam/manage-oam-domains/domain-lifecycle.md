---
title: "Domain Life Cycle"
draft: false
weight: 1
pre : "<b>1. </b>"
description: "Learn about the domain life cyle of an OAM domain."
---

As OAM domains use the Oracle WebLogic Server Kubernetes Operator, domain lifecyle operations are managed using the Oracle WebLogic Server Kubernetes Operator itself.

This document shows the basic operations for starting, stopping and scaling servers in the OAM domain. 

For more detailed information refer to [Domain Life Cycle](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/domain-lifecycle/) in the [Oracle WebLogic Server Kubernetes Operator](https://oracle.github.io/weblogic-kubernetes-operator/) documentation.
 
{{% notice note %}}
Do not use the WebLogic Server Administration Console or Oracle Enterprise Manager Console to start or stop servers.
{{% /notice %}}
 
### View existing OAM servers

The default OAM deployment starts the AdminServer (`AdminServer`), two OAM Managed Servers (`oam_server1` and `oam_server2`) and one OAM Policy Manager server (`oam_policy_mgr1`).

The deployment also creates, but doesn't start, three extra OAM Managed Servers (`oam-server3` to `oam-server5`) and four more OAM Policy Manager servers (`oam_policy_mgr2` to `oam_policy_mgr5`).

All these servers are visible in the WebLogic Server Console `https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/console` by navigating to *Domain Structure* > *oamcluster* > *Environment* > *Servers*.

To view the running servers using kubectl, run the following command:

```bash
$ kubectl get pods -n <domain_namespace>
```

For example:

```bash
$ kubectl get pods -n accessns
```

The output should look similar to the following:

```bash
NAME                                            READY   STATUS             RESTARTS   AGE
accessinfra-adminserver                         1/1     Running     0          18h
accessinfra-create-oam-infra-domain-job-vj69h   0/1     Completed   0          23h
accessinfra-oam-policy-mgr1                     1/1     Running     0          18h
accessinfra-oam-server1                         1/1     Running     0          18h
accessinfra-oam-server2                         1/1     Running     0          18h
helper                                          1/1     Running     0          40h
voyager-accessinfra-voyager-698764d6d-w8pbt     1/1     Running     0          8m47s
bash-4.2$
```

### Starting/Scaling up OAM Managed Servers

The number of OAM Managed Servers running is dependent on the `replicas` parameter configured for the cluster. To start more OAM Managed Servers perform the following steps:

1. Run the following kubectl command to edit the domain:

   ```bash
   $ kubectl edit domain <domain_uid> -n <domain_namespace>
   ```

   For example:

   ```bash
   $ kubectl edit domain accessinfra -n accessns
   ```

   **Note**: This opens an edit session for the domain where parameters can be changed using standard `vi` commands.

1. In the edit session search for "clusterName: oam_cluster" and look for the `replicas` parameter. By default the replicas parameter is set to "2" hence two OAM Managed Servers are started (`oam_server1` and `oam_server2`):

   ```
     clusters:
     - clusterName: oam_cluster
       replicas: 2
       serverPod:
         affinity:
           podAntiAffinity:
             preferredDuringSchedulingIgnoredDuringExecution:
             - podAffinityTerm:
                 labelSelector:
                   matchExpressions:
                   - key: weblogic.clusterName
                     operator: In
                     values:
                     - $(CLUSTER_NAME)
   ```
   
1. To start more OAM Managed Servers, increase the `replicas` value as desired. In the example below, two more managed servers will be started by setting `replicas` to "4":

   ```
     clusters:
     - clusterName: oam_cluster
       replicas: 4
       serverPod:
         affinity:
           podAntiAffinity:
             preferredDuringSchedulingIgnoredDuringExecution:
             - podAffinityTerm:
                 labelSelector:
                   matchExpressions:
                   - key: weblogic.clusterName
                     operator: In
                     values:
                     - $(CLUSTER_NAME)
   ```
   
1. Save the file and exit (:wq!)

   The output will look similar to the following:

   ```
   domain.weblogic.oracle/accessinfra edited
   ```
   
1. Run the following kubectl command to view the pods:  

   ```bash 
   $ kubectl get pods -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl get pods -n accessns
   ```
   
   The output will look similar to the following:
   
   ```bash
   NAME                                            READY   STATUS      RESTARTS   AGE
   accessinfra-adminserver                         1/1     Running     0          18h
   accessinfra-create-oam-infra-domain-job-vj69h   0/1     Completed   0          23h
   accessinfra-oam-policy-mgr1                     1/1     Running     0          18h
   accessinfra-oam-server1                         1/1     Running     0          18h
   accessinfra-oam-server2                         1/1     Running     0          18h
   accessinfra-oam-server3                         0/1     Running     0          6s
   accessinfra-oam-server4                         0/1     Running     0          6s
   helper                                          1/1     Running     0          40h
   voyager-accessinfra-voyager-698764d6d-w8pbt     1/1     Running     0          10m

   ```
   
   Two new pods (`accessinfra-oam-server3` and `accessinfra-oam-server4`) are started, but currently have a `READY` status of `0/1`. This means `oam_server3` and `oam_server4` are not currently running but are in the process of starting. The servers will take several minutes to start so keep executing the command until `READY` shows `1/1`:
   
   ```bash
   NAME                                            READY   STATUS      RESTARTS   AGE
   accessinfra-adminserver                         1/1     Running     0          18h
   accessinfra-create-oam-infra-domain-job-vj69h   0/1     Completed   0          24h
   accessinfra-oam-policy-mgr1                     1/1     Running     0          18h
   accessinfra-oam-server1                         1/1     Running     0          18h
   accessinfra-oam-server2                         1/1     Running     0          18h
   accessinfra-oam-server3                         1/1     Running     0          5m5s
   accessinfra-oam-server4                         1/1     Running     0          5m5s
   helper                                          1/1     Running     0          41h
   voyager-accessinfra-voyager-698764d6d-w8pbt     1/1     Running     0          15m
   ```
   
   **Note**: To check what is happening during server startup when `READY` is `0/1`, run the following command to view the log of the pod that is starting:
   
   ```bash
   $ kubectl logs <pod> -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl logs accessinfra-oam-server3 -n accessns
   ```

1. To start more OAM Policy Manager servers, repeat the previous commands but change the `replicas` parameter for the `policy_cluster`. In the example below `replicas` has been increased to "2":

   ```bash
     - clusterName: policy_cluster
       replicas: 2
       serverPod:
         affinity:
           podAntiAffinity:
             preferredDuringSchedulingIgnoredDuringExecution:
             - podAffinityTerm:
                 labelSelector:
                   matchExpressions:
                   - key: weblogic.clusterName
                     operator: In
                     values:
                     - $(CLUSTER_NAME)
   ```

   After saving the changes a new pod will be started. After a few minutes it will have a `READY` status of `1/1`. In the example below `accessinfra-oam-policy-mgr2` is started:
   
   ```bash
   NAME                                            READY   STATUS      RESTARTS   AGE
   accessinfra-adminserver                         1/1     Running     0          18h
   accessinfra-create-oam-infra-domain-job-vj69h   0/1     Completed   0          24h
   accessinfra-oam-policy-mgr1                     1/1     Running     0          18h
   accessinfra-oam-policy-mgr2                     1/1     Running     0          4m3s
   accessinfra-oam-server1                         1/1     Running     0          18h
   accessinfra-oam-server2                         1/1     Running     0          18h
   accessinfra-oam-server3                         1/1     Running     0          10m
   accessinfra-oam-server4                         1/1     Running     0          10m
   helper                                          1/1     Running     0          41h
   voyager-accessinfra-voyager-698764d6d-w8pbt     1/1     Running     0          21m
   ```
   
### Stopping/Scaling down OAM Managed Servers

As mentioned in the previous section, the number of OAM Managed Servers running is dependent on the `replicas` parameter configured for the cluster. To stop one or more OAM Managed Servers, perform the following:

1. Run the following kubectl command to edit the domain:

   ```bash
   $ kubectl edit domain <domain_uid> -n <domain_namespace>
   ```

   For example:

   ```bash
   $ kubectl edit domain accessinfra -n accessns
   ```

1. In the edit session search for "clusterName: oam_cluster" and look for the `replicas` parameter. In the example below `replicas` is set to "4", hence four OAM Managed Servers are started (oam_server1 - oam_server4):

   ```bash
     clusters:
     - clusterName: oam_cluster
       replicas: 4
       serverPod:
         affinity:
           podAntiAffinity:
             preferredDuringSchedulingIgnoredDuringExecution:
             - podAffinityTerm:
                 labelSelector:
                   matchExpressions:
                   - key: weblogic.clusterName
                     operator: In
                     values:
                     - $(CLUSTER_NAME)
   ```
   
1. To stop OAM Managed Servers, decrease the `replicas` value as desired. In the example below, we will stop two managed servers by setting replicas to "2":

   ```
     clusters:
     - clusterName: oam_cluster
       replicas: 2
       serverPod:
         affinity:
           podAntiAffinity:
             preferredDuringSchedulingIgnoredDuringExecution:
             - podAffinityTerm:
                 labelSelector:
                   matchExpressions:
                   - key: weblogic.clusterName
                     operator: In
                     values:
                     - $(CLUSTER_NAME)
   ```
   
1. Save the file and exit (:wq!)

1. Run the following kubectl command to view the pods:  

   ```bash 
   $ kubectl get pods -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl get pods -n accessns
   ```
   
   The output will look similar to the following:
   
   ```bash
   NAME                                            READY   STATUS        RESTARTS   AGE
   accessinfra-adminserver                         1/1     Running       0          18h
   accessinfra-create-oam-infra-domain-job-vj69h   0/1     Completed     0          24h
   accessinfra-oam-policy-mgr1                     1/1     Running       0          18h
   accessinfra-oam-policy-mgr2                     1/1     Running       0          5m21s
   accessinfra-oam-server1                         1/1     Running       0          18h
   accessinfra-oam-server2                         1/1     Running       0          18h
   accessinfra-oam-server3                         1/1     Terminating   0          12m
   accessinfra-oam-server4                         1/1     Terminating   0          12m
   helper                                          1/1     Running       0          41h
   voyager-accessinfra-voyager-698764d6d-w8pbt     1/1     Running       0          23m

   ```
   
   Two pods now have a `STATUS` of `Terminating` (accessinfra-oam-server3 and accessinfra-oam-server4). The servers will take a minute or two to stop, so keep executing the command until the pods have disappeared:
   
   ```bash
   NAME                                            READY   STATUS      RESTARTS   AGE
   accessinfra-adminserver                         1/1     Running     0          18h
   accessinfra-create-oam-infra-domain-job-vj69h   0/1     Completed   0          24h
   accessinfra-oam-policy-mgr1                     1/1     Running     0          18h
   accessinfra-oam-policy-mgr2                     1/1     Running     0          6m3s
   accessinfra-oam-server1                         1/1     Running     0          18h
   accessinfra-oam-server2                         1/1     Running     0          18h
   helper                                          1/1     Running     0          41h
   voyager-accessinfra-voyager-698764d6d-w8pbt     1/1     Running     0          23m
   ```

1. To stop OAM Policy Manager servers, repeat the previous commands but change the `replicas` parameter for the `policy_cluster`. In the example below `replicas` has been decreased from "2" to "1":

   ```bash
     - clusterName: policy_cluster
       replicas: 1
       serverPod:
         affinity:
           podAntiAffinity:
             preferredDuringSchedulingIgnoredDuringExecution:
             - podAffinityTerm:
                 labelSelector:
                   matchExpressions:
                   - key: weblogic.clusterName
                     operator: In
                     values:
                     - $(CLUSTER_NAME)
   ```

   After saving the changes one pod will move to a `STATUS` of `Terminating` (accessinfra-oam-policy-mgr2). 
   
   ```bash
   NAME                                            READY   STATUS        RESTARTS   AGE
   accessinfra-adminserver                         1/1     Running       0          18h
   accessinfra-create-oam-infra-domain-job-vj69h   0/1     Completed     0          24h
   accessinfra-oam-policy-mgr1                     1/1     Running       0          18h
   accessinfra-oam-policy-mgr2                     1/1     Terminating   0          7m12s
   accessinfra-oam-server1                         1/1     Running       0          18h
   accessinfra-oam-server2                         1/1     Running       0          18h
   helper                                          1/1     Running       0          41h
   voyager-accessinfra-voyager-698764d6d-w8pbt     1/1     Running       0          24m
   ```
   
   The server will take a minute or two to stop, so keep executing the command until the pod has disappeared:
   
   ```bash
   NAME                                            READY   STATUS      RESTARTS   AGE
   accessinfra-adminserver                         1/1     Running     0          18h
   accessinfra-create-oam-infra-domain-job-vj69h   0/1     Completed   0          24h
   accessinfra-oam-policy-mgr1                     1/1     Running     0          18h
   accessinfra-oam-server1                         1/1     Running     0          18h
   accessinfra-oam-server2                         1/1     Running     0          18h
   helper                                          1/1     Running     0          41h
   voyager-accessinfra-voyager-698764d6d-w8pbt     1/1     Running     0          25m
   ```

### Stopping and Starting the AdminServer and Managed Servers   

To stop all the OAM Managed Servers and the AdminServer in one operation:

1. Run the following kubectl command to edit the domain:

   ```bash
   $ kubectl edit domain <domain_uid> -n <domain_namespace>
   ```

   For example:

   ```bash
   $ kubectl edit domain accessinfra -n accessns
   ```
   
1. In the edit session search for `serverStartPolicy: IF_NEEDED`:

   ```
       volumes:
       - name: weblogic-domain-storage-volume
         persistentVolumeClaim:
           claimName: accessinfra-domain-pvc
     serverStartPolicy: IF_NEEDED
     webLogicCredentialsSecret:
       name: accessinfra-domain-credentials
   ```
   
1. Change `serverStartPolicy: IF_NEEDED` to `NEVER` as follows: 

   ```
       volumes:
       - name: weblogic-domain-storage-volume
         persistentVolumeClaim:
           claimName: accessinfra-domain-pvc
     serverStartPolicy: NEVER
     webLogicCredentialsSecret:
       name: accessinfra-domain-credentials
   ```
   
1. Save the file and exit (:wq!).

1. Run the following kubectl command to view the pods:

   ```bash
   $ kubectl get pods -n <domain_namespace>
   ```
  
   For example:
   
   ```bash
   $ kubectl get pods -n accessns
   ```
   
   The output will look similar to the following:

   ```bash
   NAME                                            READY   STATUS        RESTARTS   AGE
   accessinfra-adminserver                         1/1     Terminating   0          18h
   accessinfra-create-oam-infra-domain-job-vj69h   0/1     Completed     0          24h
   accessinfra-oam-policy-mgr1                     1/1     Terminating   0          18h
   accessinfra-oam-server1                         1/1     Terminating   0          18h
   accessinfra-oam-server2                         1/1     Terminating   0          18h
   helper                                          1/1     Running       0          41h
   voyager-accessinfra-voyager-698764d6d-w8pbt     1/1     Running       0          27m

   ```
   
   The AdminServer pods and Managed Server pods will move to a `STATUS` of `Terminating`. After a few minutes, run the command again and the pods should have disappeared:

   ```bash
   NAME                                            READY   STATUS      RESTARTS   AGE
   accessinfra-create-oam-infra-domain-job-vj69h   0/1     Completed   0          24h
   helper                                          1/1     Running     0          41h
   voyager-accessinfra-voyager-698764d6d-w8pbt     1/1     Running     0          28m
   ```

1. To start the AdminServer and Managed Servers up again, repeat the previous steps but change  `serverStartPolicy: NEVER` to `IF_NEEDED` as follows:

   ```
       volumes:
       - name: weblogic-domain-storage-volume
         persistentVolumeClaim:
           claimName: accessinfra-domain-pvc
     serverStartPolicy: IF_NEEDED
     webLogicCredentialsSecret:
       name: accessinfra-domain-credentials
   ```
1. Run the following kubectl command to view the pods:

   ```bash
   $ kubectl get pods -n <domain_namespace>
   ```
  
   For example:
   
   ```bash
   $ kubectl get pods -n accessns
   ```

   The output will look similar to the following:

   ```bash
   NAME                                            READY   STATUS      RESTARTS   AGE
   accessinfra-create-oam-infra-domain-job-vj69h   0/1     Completed   0          24h
   accessinfra-introspect-domain-job-7qx29         1/1     Running     0          8s
   helper                                          1/1     Running     0          41h
   voyager-accessinfra-voyager-698764d6d-w8pbt     1/1     Running     0          29m
   ```
   
   The AdminServer pod will start followed by the OAM Managed Servers pods. This process will take several minutes, so keep executing the command until all the pods are running with `READY` status `1/1` :
   
   ```bash
   NAME                                            READY   STATUS      RESTARTS   AGE  
   accessinfra-adminserver                         1/1     Running     0          6m4s
   accessinfra-create-oam-infra-domain-job-vj69h   0/1     Completed   0          24h
   accessinfra-oam-policy-mgr1                     1/1     Running     0          3m5s
   accessinfra-oam-server1                         1/1     Running     0          3m5s
   accessinfra-oam-server2                         1/1     Running     0          3m5s
   helper                                          1/1     Running     0          41h
   voyager-accessinfra-voyager-698764d6d-w8pbt     1/1     Running     0          36m
   ```
