---
title: "a. Domain Life Cycle"
description: "Learn about the domain life cycle of an OAM domain."
---

1. [View existing OAM servers](#view-existing-oam-servers)
1. [Starting/Scaling up OAM Managed servers](#startingscaling-up-oam-managed-servers)
1. [Stopping/Scaling down OAM Managed servers](#stoppingscaling-down-oam-managed-servers)
1. [Starting/Scaling up OAM Policy Managed servers](#startingscaling-up-oam-policy-managed-servers)
1. [Stopping/Scaling down OAM Policy Managed servers](#stoppingscaling-down-oam-policy-managed-servers)
1. [Stopping and starting the Administration Server and Managed Servers](#stopping-and-starting-the-administration-server-and-managed-servers)
1. [Domain lifecycle sample scripts](#domain-lifecycle-sample-scripts)


As OAM domains use the WebLogic Kubernetes Operator, domain lifecyle operations are managed using the WebLogic Kubernetes Operator itself.

This document shows the basic operations for starting, stopping and scaling servers in the OAM domain. 

For more detailed information refer to [Domain Life Cycle](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-lifecycle/) in the [WebLogic Kubernetes Operator](https://oracle.github.io/weblogic-kubernetes-operator/) documentation.


{{% notice note %}}
Do not use the WebLogic Server Administration Console or Oracle Enterprise Manager Console to start or stop servers.
{{% /notice %}}

**Note**: The instructions below are for starting, stopping, or scaling servers manually. If you wish to use autoscaling, see [Kubernetes Horizontal Pod Autoscaler](../hpa). Please note, if you have enabled autoscaling, it is recommended to delete the autoscaler before running the commands below. 


 
### View existing OAM servers

The default OAM deployment starts the Administration Server (`AdminServer`), one OAM Managed Server (`oam_server1`) and one OAM Policy Manager server (`oam_policy_mgr1`).

The deployment also creates, but doesn't start, four extra OAM Managed Servers (`oam-server2` to `oam-server5`) and four more OAM Policy Manager servers (`oam_policy_mgr2` to `oam_policy_mgr5`).

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
accessdomain-oam-policy-mgr1                             1/1     Running     0          3h21m
accessdomain-oam-server1                                 1/1     Running     0          3h21m
nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          55m
```

### Starting/Scaling up OAM Managed Servers

The number of OAM Managed Servers running is dependent on the `replicas` parameter configured for the oam-cluster. To start more OAM Managed Servers perform the following steps:

1. Run the following kubectl command to edit the oam-cluster:

   ```bash
   $ kubectl edit cluster accessdomain-oam-cluster -n <domain_namespace>
   ```

   For example:

   ```bash
   $ kubectl edit cluster accessdomain-oam-cluster -n oamns
   ```

   **Note**: This opens an edit session for the oam-cluster where parameters can be changed using standard `vi` commands.

1. In the edit session, search for `spec:`, and then look for the `replicas` parameter under `clusterName: oam_cluster`. By default the replicas parameter is set to "1" hence one OAM Managed Server is started (`oam_server1`):

   ```
   ...
   spec:
     clusterName: oam_cluster
     replicas: 1
     serverPod:
       env:
       - name: USER_MEM_ARGS
         value: -XX:+UseContainerSupport -Djava.security.egd=file:/dev/./urandom -Xms8192m
           -Xmx8192m
   ...
   ```
   
1. To start more OAM Managed Servers, increase the `replicas` value as desired. In the example below, two more managed servers will be started by setting `replicas` to "3":

   ```
   ...
   spec:
     clusterName: oam_cluster
     replicas: 3
     serverPod:
       env:
       - name: USER_MEM_ARGS
         value: -XX:+UseContainerSupport -Djava.security.egd=file:/dev/./urandom -Xms8192m
           -Xmx8192m
   ...
   ```
   
1. Save the file and exit (:wq!)

   The output will look similar to the following:

   ```
   cluster.weblogic.oracle/accessdomain-oam-cluster edited
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
   accessdomain-oam-policy-mgr1                             1/1     Running     0          3h25m
   accessdomain-oam-server1                                 1/1     Running     0          3h25m
   accessdomain-oam-server2                                 0/1     Running     0          3h25m
   accessdomain-oam-server3                                 0/1     Pending     0          9s
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          59m
   ```
   
   Two new pods (`accessdomain-oam-server2` and `accessdomain-oam-server3`) are started, but currently have a `READY` status of `0/1`. This means `oam_server2` and `oam_server3` are not currently running but are in the process of starting. The servers will take several minutes to start so keep executing the command until `READY` shows `1/1`:
   
   ```
   NAME                                                     READY   STATUS      RESTARTS   AGE
   accessdomain-adminserver                                 1/1     Running     0          3h37m
   accessdomain-oam-policy-mgr1                             1/1     Running     0          3h29m
   accessdomain-oam-server1                                 1/1     Running     0          3h29m
   accessdomain-oam-server2                                 1/1     Running     0          3h29m
   accessdomain-oam-server3                                 1/1     Running     0          3m45s
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


### Stopping/Scaling down OAM Managed Servers

As mentioned in the previous section, the number of OAM Managed Servers running is dependent on the `replicas` parameter configured for the cluster. To stop one or more OAM Managed Servers, perform the following:

1. Run the following kubectl command to edit the oam-cluster:

   ```bash
   $ kubectl edit cluster accessdomain-oam-cluster -n <domain_namespace>
   ```

   For example:

   ```bash
   $ kubectl edit cluster accessdomain-oam-cluster -n oamns
   ```

1. In the edit session, search for `spec:`, and then look for the `replicas` parameter under `clusterName: oam_cluster`. In the example below `replicas` is set to "3", hence three OAM Managed Servers are started (`access-domain-oam_server1` - `access-domain-oam_server3`):

   ```
   ...
   spec:
     clusterName: oam_cluster
     replicas: 3
     serverPod:
       env:
       - name: USER_MEM_ARGS
         value: -XX:+UseContainerSupport -Djava.security.egd=file:/dev/./urandom -Xms8192m
           -Xmx8192m
   ...
   ```
   
1. To stop OAM Managed Servers, decrease the `replicas` value as desired. In the example below, we will stop two managed servers by setting replicas to "1":

   ```
   spec:
     clusterName: oam_cluster
     replicas: 1
     serverPod:
       env:
       - name: USER_MEM_ARGS
         value: -XX:+UseContainerSupport -Djava.security.egd=file:/dev/./urandom -Xms8192m
           -Xmx8192m
   ...
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
   accessdomain-oam-policy-mgr1                             1/1     Running       0          3h37m
   accessdomain-oam-server1                                 1/1     Running       0          3h37m
   accessdomain-oam-server2                                 1/1     Running       0          3h37m
   accessdomain-oam-server3                                 1/1     Terminating   0          11m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running       0          71m
   ```
   
   One pod now has a `STATUS` of `Terminating` (`accessdomain-oam-server3`). The server will take a minute or two to stop. Once terminated the other pod (`accessdomain-oam-server2`) will move to `Terminating` and then stop. Keep executing the command until the pods have disappeared:
   
   ```
   NAME                                            READY   STATUS      RESTARTS   AGE
   accessdomain-adminserver                                 1/1     Running     0          3h48m
   accessdomain-oam-policy-mgr1                             1/1     Running     0          3h40m
   accessdomain-oam-server1                                 1/1     Running     0          3h40m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          74m
   ```

### Starting/Scaling up OAM Policy Managed Servers

The number of OAM Policy Managed Servers running is dependent on the `replicas` parameter configured for the policy-cluster. To start more OAM Policy Managed Servers perform the following steps:

1. Run the following kubectl command to edit the policy-cluster:

   ```bash
   $ kubectl edit cluster accessdomain-policy-cluster -n <domain_namespace>
   ```

   For example:

   ```bash
   $ kubectl edit cluster accessdomain-policy-cluster -n oamns
   ```

   **Note**: This opens an edit session for the policy-cluster where parameters can be changed using standard `vi` commands.

1. In the edit session, search for `spec:`, and then look for the `replicas` parameter under `clusterName: policy_cluster`. By default the replicas parameter is set to "1" hence one OAM Policy Managed Server is started (`oam_policy_mgr1`):

   ```
   ...
   spec:
     clusterName: policy_cluster
     replicas: 1
     serverService:
       precreateService: true
   ...
   ```
   
1. To start more OAM Policy Managed Servers, increase the `replicas` value as desired. In the example below, two more managed servers will be started by setting `replicas` to "3":

   ```
   ...
   spec:
     clusterName: policy_cluster
     replicas: 3
     serverService:
       precreateService: true
   ...
   ```
   
1. Save the file and exit (:wq!)

   The output will look similar to the following:

   ```
   cluster.weblogic.oracle/accessdomain-policy-cluster edited
   ```

   After saving the changes two new pods will be started (`accessdomain-oam-policy-mgr2` and `accessdomain-oam-policy-mgr3`). After a few minutes they will have a `READY` status of `1/1`. In the example below `accessdomain-oam-policy-mgr2` and `accessdomain-oam-policy-mgr3` are started:
   
   ```
   NAME                                                     READY   STATUS      RESTARTS   AGE
   accessdomain-adminserver                                 1/1     Running     0          3h43m
   accessdomain-oam-policy-mgr1                             1/1     Running     0          3h35m
   accessdomain-oam-policy-mgr2                             1/1     Running     0          3h35m
   accessdomain-oam-policy-mgr3                             1/1     Running     0          4m18s
   accessdomain-oam-server1                                 1/1     Running     0          3h35m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          69m
   ```



### Stopping/Scaling down OAM Policy Managed Servers

As mentioned in the previous section, the number of OAM Policy Managed Servers running is dependent on the `replicas` parameter configured for the cluster. To stop one or more OAM Policy Managed Servers, perform the following:

1. Run the following kubectl command to edit the policy-cluster:

   ```bash
   $ kubectl edit cluster accessdomain-policy-cluster -n <domain_namespace>
   ```

   For example:

   ```bash
   $ kubectl edit cluster accessdomain-policy-cluster -n oamns
   ```

1. In the edit session, search for `spec:`, and then look for the `replicas` parameter under `clusterName: policy_cluster`. To stop OAM Policy Managed Servers, decrease the `replicas` value as desired. In the example below, we will stop two managed servers by setting replicas to "1":

   ```
   ...
   spec:
     clusterName: policy_cluster
     replicas: 1
     serverService:
       precreateService: true
   ...
   ```

   After saving the changes one pod will move to a `STATUS` of `Terminating` (`accessdomain-oam-policy-mgr3`). 
   
   ```
   NAME                                            READY   STATUS        RESTARTS   AGE
   accessdomain-adminserver                                 1/1     Running       0          3h49m
   accessdomain-oam-policy-mgr1                             1/1     Running       0          3h41m
   accessdomain-oam-policy-mgr2                             1/1     Running       0          3h41m
   accessdomain-oam-policy-mgr3                             1/1     Terminating   0          10m
   accessdomain-oam-server1                                 1/1     Running       0          3h41m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running       0          75m
   ```
   
   The pods will take a minute or two to stop, so keep executing the command until the pods has disappeared:
   
   ```
   NAME                                                     READY   STATUS      RESTARTS   AGE
   accessdomain-adminserver                                 1/1     Running     0          3h50m
   accessdomain-oam-policy-mgr1                             1/1     Running     0          3h42m
   accessdomain-oam-server1                                 1/1     Running     0          3h42m
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
   
1. In the edit session, search for `serverStartPolicy: IfNeeded` under the domain spec:

   ```
   ...
      volumeMounts:
      - mountPath: /u01/oracle/user_projects/domains
        name: weblogic-domain-storage-volume
      volumes:
      - name: weblogic-domain-storage-volume
        persistentVolumeClaim:
          claimName: accessdomain-domain-pvc
    serverStartPolicy: IfNeeded
   ...
   ```
   
1. Change `serverStartPolicy: IfNeeded` to `Never` as follows: 

   ```
   ...
      volumeMounts:
      - mountPath: /u01/oracle/user_projects/domains
        name: weblogic-domain-storage-volume
      volumes:
      - name: weblogic-domain-storage-volume
        persistentVolumeClaim:
          claimName: accessdomain-domain-pvc
    serverStartPolicy: Never
   ...
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
   accessdomain-oam-policy-mgr1                             1/1     Terminating   0          3h44m
   accessdomain-oam-server1                                 1/1     Terminating   0          3h44m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running       0          78m
   ```
   
   The Administration Server pods and Managed Server pods will move to a `STATUS` of `Terminating`. After a few minutes, run the command again and the pods should have disappeared:

   ```
   NAME                                                     READY   STATUS      RESTARTS   AGE
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          80m
   ```

1. To start the Administration Server and Managed Servers up again, repeat the previous steps but change  `serverStartPolicy: Never` to `IfNeeded` as follows:

   ```
   ...
      volumeMounts:
      - mountPath: /u01/oracle/user_projects/domains
        name: weblogic-domain-storage-volume
      volumes:
      - name: weblogic-domain-storage-volume
        persistentVolumeClaim:
          claimName: accessdomain-domain-pvc
    serverStartPolicy: IfNeeded
   ...
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
   accessdomain-introspector-jwqxw                          1/1     Running     0          10s
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          81m
   ```
   
   The Administration Server pod will start followed by the OAM Managed Servers pods. This process will take several minutes, so keep executing the command until all the pods are running with `READY` status `1/1` :
   
   ```
   NAME                                                     READY   STATUS      RESTARTS   AGE  
   accessdomain-adminserver                                 1/1     Running     0          10m
   accessdomain-oam-policy-mgr1                             1/1     Running     0          7m35s
   accessdomain-oam-server1                                 1/1     Running     0          7m35s
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          92m
   ```

### Domain lifecycle sample scripts

The WebLogic Kubernetes Operator provides sample scripts to start up or shut down a specific Managed Server or cluster in a deployed domain, or the entire deployed domain.

**Note**: Prior to running these scripts, you must have previously created and deployed the domain.

The scripts are located in the `$WORKDIR/kubernetes/domain-lifecycle` directory. For more information, see the [README](https://github.com/oracle/fmw-kubernetes/tree/master/OracleAccessManagement/kubernetes/domain-lifecycle).
