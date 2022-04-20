---
title: "a. Domain Life Cycle"
description: "Learn about the domain life cycle of an OAM domain."
---

1. [View existing OAM servers](#view-existing-oam-servers)
1. [Starting/Scaling up OAM Managed servers](#startingscaling-up-oam-managed-servers)
1. [Stopping/Scaling down OAM Managed servers](#stoppingscaling-down-oam-managed-servers)
1. [Stopping and starting the Administration Server and Managed Servers](#stopping-and-starting-the-administration-server-and-managed-servers)
1. [Domain lifecycle sample scripts](domain-lifecycle-sample-scripts)


As OAM domains use the WebLogic Kubernetes Operator, domain lifecyle operations are managed using the WebLogic Kubernetes Operator itself.

This document shows the basic operations for starting, stopping and scaling servers in the OAM domain. 

For more detailed information refer to [Domain Life Cycle](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/domain-lifecycle/) in the [WebLogic Kubernetes Operator](https://oracle.github.io/weblogic-kubernetes-operator/) documentation.
 
{{% notice note %}}
Do not use the WebLogic Server Administration Console or Oracle Enterprise Manager Console to start or stop servers.
{{% /notice %}}
 
### View existing OAM servers

The default OAM deployment starts the Administration Server (`AdminServer`), two OAM Managed Servers (`oam_server1` and `oam_server2`) and two OAM Policy Manager server (`oam_policy_mgr1` and `oam_policy_mgr2` ).

The deployment also creates, but doesn't start, three extra OAM Managed Servers (`oam-server3` to `oam-server5`) and three more OAM Policy Manager servers (`oam_policy_mgr3` to `oam_policy_mgr5`).

All these servers are visible in the WebLogic Server Console `https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/console` by navigating to *Domain Structure* > *oamcluster* > *Environment* > *Servers*.

To view the running servers using kubectl, run the following command:

```bash
$ kubectl get pods -n <domain_namespace>
```

For example:

```bash
$ kubectl get pods -n oamns
```

The output should look similar to the following:

```
NAME                                                     READY   STATUS      RESTARTS   AGE
accessdomain-adminserver                                 1/1     Running     0          3h29m
accessdomain-create-oam-infra-domain-job-7c9r9           0/1     Completed   0          3h36m
accessdomain-oam-policy-mgr1                             1/1     Running     0          3h21m
accessdomain-oam-policy-mgr2                             1/1     Running     0          3h21m
accessdomain-oam-server1                                 1/1     Running     0          3h21m
accessdomain-oam-server2                                 1/1     Running     0          3h21m
helper                                                   1/1     Running     0          3h51m
nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          55m
```

### Starting/Scaling up OAM Managed Servers

The number of OAM Managed Servers running is dependent on the `replicas` parameter configured for the cluster. To start more OAM Managed Servers perform the following steps:

1. Run the following kubectl command to edit the domain:

   ```bash
   $ kubectl edit domain <domain_uid> -n <domain_namespace>
   ```

   For example:

   ```bash
   $ kubectl edit domain accessdomain -n oamns
   ```

   **Note**: This opens an edit session for the domain where parameters can be changed using standard `vi` commands.

1. In the edit session search for `clusterName: oam_cluster` and look for the `replicas` parameter. By default the replicas parameter is set to "2" hence two OAM Managed Servers are started (`oam_server1` and `oam_server2`):

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
   domain.weblogic.oracle/accessdomain edited
   ```
   
1. Run the following kubectl command to view the pods:  

   ```bash 
   $ kubectl get pods -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl get pods -n oamns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                                                     READY   STATUS      RESTARTS   AGE
   accessdomain-adminserver                                 1/1     Running     0          3h33m
   accessdomain-create-oam-infra-domain-job-7c9r9           0/1     Completed   0          3h40m
   accessdomain-oam-policy-mgr1                             1/1     Running     0          3h25m
   accessdomain-oam-policy-mgr2                             1/1     Running     0          3h25m
   accessdomain-oam-server1                                 1/1     Running     0          3h25m
   accessdomain-oam-server2                                 1/1     Running     0          3h25m
   accessdomain-oam-server3                                 0/1     Running     0          9s
   accessdomain-oam-server4                                 0/1     Running     0          9s
   helper                                                   1/1     Running     0          3h55m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          59m
   ```
   
   Two new pods (`accessdomain-oam-server3` and `accessdomain-oam-server4`) are started, but currently have a `READY` status of `0/1`. This means `oam_server3` and `oam_server4` are not currently running but are in the process of starting. The servers will take several minutes to start so keep executing the command until `READY` shows `1/1`:
   
   ```
   NAME                                                     READY   STATUS      RESTARTS   AGE
   accessdomain-adminserver                                 1/1     Running     0          3h37m
   accessdomain-create-oam-infra-domain-job-7c9r9           0/1     Completed   0          3h43m
   accessdomain-oam-policy-mgr1                             1/1     Running     0          3h29m
   accessdomain-oam-policy-mgr2                             1/1     Running     0          3h29m
   accessdomain-oam-server1                                 1/1     Running     0          3h29m
   accessdomain-oam-server2                                 1/1     Running     0          3h29m
   accessdomain-oam-server3                                 1/1     Running     0          3m45s
   accessdomain-oam-server4                                 1/1     Running     0          3m45s
   helper                                                   1/1     Running     0          3h59m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          63m

   ```
   
   **Note**: To check what is happening during server startup when `READY` is `0/1`, run the following command to view the log of the pod that is starting:
   
   ```bash
   $ kubectl logs <pod> -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl logs accessdomain-oam-server3 -n oamns
   ```

1. To start more OAM Policy Manager servers, repeat the previous commands but change the `replicas` parameter for the `policy_cluster`. In the example below `replicas` has been increased to "4":

   ```
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

   After saving the changes two new pods will be started (`accessdomain-oam-policy-mgr3` and `accessdomain-oam-policy-mgr4`). After a few minutes they will have a `READY` status of `1/1`. In the example below `accessdomain-oam-policy-mgr3` and `accessdomain-oam-policy-mgr4` are started:
   
   ```
   NAME                                                     READY   STATUS      RESTARTS   AGE
   accessdomain-adminserver                                 1/1     Running     0          3h43m
   accessdomain-create-oam-infra-domain-job-7c9r9           0/1     Completed   0          3h49m
   accessdomain-oam-policy-mgr1                             1/1     Running     0          3h35m
   accessdomain-oam-policy-mgr2                             1/1     Running     0          3h35m
   accessdomain-oam-policy-mgr3                             1/1     Running     0          4m18s
   accessdomain-oam-policy-mgr4                             1/1     Running     0          4m18s
   accessdomain-oam-server1                                 1/1     Running     0          3h35m
   accessdomain-oam-server2                                 1/1     Running     0          3h35m
   accessdomain-oam-server3                                 1/1     Running     0          9m27s
   accessdomain-oam-server4                                 1/1     Running     0          9m27s
   helper                                                   1/1     Running     0          4h4m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          69m
   ```
   
### Stopping/Scaling down OAM Managed Servers

As mentioned in the previous section, the number of OAM Managed Servers running is dependent on the `replicas` parameter configured for the cluster. To stop one or more OAM Managed Servers, perform the following:

1. Run the following kubectl command to edit the domain:

   ```bash
   $ kubectl edit domain <domain_uid> -n <domain_namespace>
   ```

   For example:

   ```bash
   $ kubectl edit domain accessdomain -n oamns
   ```

1. In the edit session search for `clusterName: oam_cluster` and look for the `replicas` parameter. In the example below `replicas` is set to "4", hence four OAM Managed Servers are started (`access-domain-oam_server1` - `access-domain-oam_server4`):

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
   $ kubectl get pods -n oamns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                                                     READY   STATUS        RESTARTS   AGE
   accessdomain-adminserver                                 1/1     Running       0          3h45m
   accessdomain-create-oam-infra-domain-job-7c9r9           0/1     Completed     0          3h51m
   accessdomain-oam-policy-mgr1                             1/1     Running       0          3h37m
   accessdomain-oam-policy-mgr2                             1/1     Running       0          3h37m
   accessdomain-oam-policy-mgr3                             1/1     Running       0          6m18s
   accessdomain-oam-policy-mgr4                             1/1     Running       0          6m18s
   accessdomain-oam-server1                                 1/1     Running       0          3h37m
   accessdomain-oam-server2                                 1/1     Running       0          3h37m
   accessdomain-oam-server3                                 1/1     Running       0          11m
   accessdomain-oam-server4                                 1/1     Terminating   0          11m
   helper                                                   1/1     Running       0          4h6m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running       0          71m
   ```
   
   One pod now has a `STATUS` of `Terminating` (`accessdomain-oam-server4`). The server will take a minute or two to stop. Once terminated the other pod (`accessdomain-oam-server3`) will move to `Terminating` and then stop. Keep executing the command until the pods have disappeared:
   
   ```
   NAME                                            READY   STATUS      RESTARTS   AGE
   accessdomain-adminserver                                 1/1     Running     0          3h48m
   accessdomain-create-oam-infra-domain-job-7c9r9           0/1     Completed   0          3h54m
   accessdomain-oam-policy-mgr1                             1/1     Running     0          3h40m
   accessdomain-oam-policy-mgr2                             1/1     Running     0          3h40m
   accessdomain-oam-policy-mgr3                             1/1     Running     0          9m18s
   accessdomain-oam-policy-mgr4                             1/1     Running     0          9m18s
   accessdomain-oam-server1                                 1/1     Running     0          3h40m
   accessdomain-oam-server2                                 1/1     Running     0          3h40m
   helper                                                   1/1     Running     0          4h9m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          74m
   ```

1. To stop OAM Policy Manager servers, repeat the previous commands but change the `replicas` parameter for the `policy_cluster`. In the example below `replicas` has been decreased from "4" to "2":

   ```
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

   After saving the changes one pod will move to a `STATUS` of `Terminating` (`accessdomain-oam-policy-mgr4`). 
   
   ```
   NAME                                            READY   STATUS        RESTARTS   AGE
   accessdomain-adminserver                                 1/1     Running       0          3h49m
   accessdomain-create-oam-infra-domain-job-7c9r9           0/1     Completed     0          3h55m
   accessdomain-oam-policy-mgr1                             1/1     Running       0          3h41m
   accessdomain-oam-policy-mgr2                             1/1     Running       0          3h41m
   accessdomain-oam-policy-mgr3                             1/1     Running       0          10m
   accessdomain-oam-policy-mgr4                             1/1     Terminating   0          10m
   accessdomain-oam-server1                                 1/1     Running       0          3h41m
   accessdomain-oam-server2                                 1/1     Running       0          3h41m
   helper                                                   1/1     Running       0          4h11m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running       0          75m
   ```
   
   The pods will take a minute or two to stop, so keep executing the command until the pods has disappeared:
   
   ```
   NAME                                                     READY   STATUS      RESTARTS   AGE
   accessdomain-adminserver                                 1/1     Running     0          3h50m
   accessdomain-create-oam-infra-domain-job-7c9r9           0/1     Completed   0          3h57m
   accessdomain-oam-policy-mgr1                             1/1     Running     0          3h42m
   accessdomain-oam-policy-mgr2                             1/1     Running     0          3h42m
   accessdomain-oam-server1                                 1/1     Running     0          3h42m
   accessdomain-oam-server2                                 1/1     Running     0          3h42m
   helper                                                   1/1     Running     0          4h12m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          76m
   ```

### Stopping and Starting the Administration Server and Managed Servers   

To stop all the OAM Managed Servers and the Administration Server in one operation:

1. Run the following kubectl command to edit the domain:

   ```bash
   $ kubectl edit domain <domain_uid> -n <domain_namespace>
   ```

   For example:

   ```bash
   $ kubectl edit domain accessdomain -n oamns
   ```
   
1. In the edit session search for `serverStartPolicy: IF_NEEDED`:

   ```
       volumes:
       - name: weblogic-domain-storage-volume
         persistentVolumeClaim:
           claimName: accessdomain-domain-pvc
     serverStartPolicy: IF_NEEDED
     webLogicCredentialsSecret:
       name: accessdomain-credentials
   ```
   
1. Change `serverStartPolicy: IF_NEEDED` to `NEVER` as follows: 

   ```
       volumes:
       - name: weblogic-domain-storage-volume
         persistentVolumeClaim:
           claimName: accessdomain-domain-pvc
     serverStartPolicy: NEVER
     webLogicCredentialsSecret:
       name: accessdomain-credentials
   ```
   
1. Save the file and exit (:wq!).

1. Run the following kubectl command to view the pods:

   ```bash
   $ kubectl get pods -n <domain_namespace>
   ```
  
   For example:
   
   ```bash
   $ kubectl get pods -n oamns
   ```
   
   The output will look similar to the following:

   ```
   NAME                                                     READY   STATUS        RESTARTS   AGE
   accessdomain-adminserver                                 1/1     Terminating   0          3h52m
   accessdomain-create-oam-infra-domain-job-7c9r9           0/1     Completed     0          3h59m
   accessdomain-oam-policy-mgr1                             1/1     Terminating   0          3h44m
   accessdomain-oam-policy-mgr2                             1/1     Terminating   0          3h44m
   accessdomain-oam-server1                                 1/1     Terminating   0          3h44m
   accessdomain-oam-server2                                 1/1     Terminating   0          3h44m
   helper                                                   1/1     Running       0          4h14m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running       0          78m
   ```
   
   The Administration Server pods and Managed Server pods will move to a `STATUS` of `Terminating`. After a few minutes, run the command again and the pods should have disappeared:

   ```
   NAME                                                     READY   STATUS      RESTARTS   AGE
   accessdomain-create-oam-infra-domain-job-7c9r9           0/1     Completed   0          4h
   helper                                                   1/1     Running     0          4h15m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          80m
   ```

1. To start the Administration Server and Managed Servers up again, repeat the previous steps but change  `serverStartPolicy: NEVER` to `IF_NEEDED` as follows:

   ```
       volumes:
       - name: weblogic-domain-storage-volume
         persistentVolumeClaim:
           claimName: accessdomain-domain-pvc
     serverStartPolicy: IF_NEEDED
     webLogicCredentialsSecret:
       name: accessdomain-credentials
   ```
1. Run the following kubectl command to view the pods:

   ```bash
   $ kubectl get pods -n <domain_namespace>
   ```
  
   For example:
   
   ```bash
   $ kubectl get pods -n oamns
   ```

   The output will look similar to the following:

   ```
   NAME                                                     READY   STATUS      RESTARTS   AGE
   accessdomain-create-oam-infra-domain-job-7c9r9           0/1     Completed   0          4h1m
   accessdomain-introspector-jwqxw                          1/1     Running     0          10s
   helper                                                   1/1     Running     0          4h17m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          81m
   ```
   
   The Administration Server pod will start followed by the OAM Managed Servers pods. This process will take several minutes, so keep executing the command until all the pods are running with `READY` status `1/1` :
   
   ```
   NAME                                                     READY   STATUS      RESTARTS   AGE  
   accessdomain-adminserver                                 1/1     Running     0          10m
   accessdomain-create-oam-infra-domain-job-7c9r9           0/1     Completed   0          4h12m
   accessdomain-oam-policy-mgr1                             1/1     Running     0          7m35s
   accessdomain-oam-policy-mgr2                             1/1     Running     0          7m35s
   accessdomain-oam-server1                                 1/1     Running     0          7m35s
   accessdomain-oam-server2                                 1/1     Running     0          7m35s
   helper                                                   1/1     Running     0          4h28m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          92m
   ```

### Domain lifecycle sample scripts

The WebLogic Kubernetes Operator provides sample scripts to start up or shut down a specific Managed Server or cluster in a deployed domain, or the entire deployed domain.

**Note**: Prior to running these scripts, you must have previously created and deployed the domain.

The scripts are located in the `$WORKDIR/kubernetes/domain-lifecycle` directory. For more information, see the [README](https://github.com/oracle/fmw-kubernetes/tree/master/OracleAccessManagement/kubernetes/domain-lifecycle).
