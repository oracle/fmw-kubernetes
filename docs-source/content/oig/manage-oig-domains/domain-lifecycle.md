---
title: "Domain life cycle"
weight: 1
pre : "<b>1. </b>"
description: "Learn about the domain life cyle of an OIG domain."
---

1. [View existing OIG servers](#view-existing-oig-servers)
1. [Starting/Scaling up OIG Managed servers](#startingscaling-up-oig-managed-servers)
1. [Stopping/Scaling down OIG Managed servers](#stoppingscaling-down-oig-managed-servers)
1. [Stopping and starting the Administration Server and Managed Servers](#stopping-and-starting-the-administration-server-and-managed-servers)
1. [Domain lifecycle sample scripts](#domain-lifecycle-sample-scripts)

As OIG domains use the WebLogic Kubernetes Operator, domain lifecyle operations are managed using the WebLogic Kubernetes Operator itself.

This document shows the basic operations for starting, stopping and scaling servers in the OIG domain. 

For more detailed information refer to [Domain Life Cycle](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/domain-lifecycle/) in the [WebLogic Kubernetes Operator](https://oracle.github.io/weblogic-kubernetes-operator/) documentation.
 
{{% notice note %}}
Do not use the WebLogic Server Administration Console or Oracle Enterprise Manager Console to start or stop servers.
{{% /notice %}}
 
### View existing OIG Servers

The default OIG deployment starts the Administration Server (`AdminServer`), one OIG Managed Server (`oim_server1`) and one SOA Managed Server (`soa_server1`).

The deployment also creates, but doesn't start, four extra OIG Managed Servers (`oim-server2` to `oim-server5`) and four more SOA Managed Servers (`soa_server2` to `soa_server5`).

All these servers are visible in the WebLogic Server Administration Console `https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/console` by navigating to **Domain Structure** > **governancedomain** > **Environment** > **Servers**.

To view the running servers using kubectl, run the following command:

```bash
$ kubectl get pods -n <domain_namespace>
```

For example:

```bash
$ kubectl get pods -n oigns
```

The output should look similar to the following:

```
NAME                                                        READY   STATUS      RESTARTS   AGE
governancedomain-adminserver                                1/1     Running     0          23h
governancedomain-create-fmw-infra-sample-domain-job-8cww8   0/1     Completed   0          24h
governancedomain-oim-server1                                1/1     Running     0          23h
governancedomain-soa-server1                                1/1     Running     0          23h
```

### Starting/Scaling up OIG Managed Servers

The number of OIG Managed Servers running is dependent on the `replicas` parameter configured for the cluster. To start more OIG Managed Servers perform the following steps:

1. Run the following kubectl command to edit the domain:

   ```
   $ kubectl edit domain <domain_uid> -n <domain_namespace>
   ```

   For example:

   ```
   $ kubectl edit domain governancedomain -n oigns
   ```

   **Note**: This opens an edit session for the domain where parameters can be changed using standard `vi` commands.

1. In the edit session search for `clusterName: oim_cluster` and look for the `replicas` parameter. By default the replicas parameter is set to "1" hence a single OIG Managed Server is started (`oim_server1`):

   ```
     - clusterName: oim_cluster
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
   
1. To start more OIG Managed Servers, increase the `replicas` value as desired. In the example below, one more Managed Server will be started by setting `replicas` to "2":

   ```
     - clusterName: oim_cluster
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
   
1. Save the file and exit (:wq)

   The output will look similar to the following:

   ```
   domain.weblogic.oracle/governancedomain edited
   ```
   
1. Run the following kubectl command to view the pods:  

   ```bash
   $ kubectl get pods -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl get pods -n oigns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                                                        READY   STATUS      RESTARTS   AGE
   governancedomain-adminserver                                1/1     Running     0          23h
   governancedomain-create-fmw-infra-sample-domain-job-8cww8   0/1     Completed   0          24h
   governancedomain-oim-server1                                1/1     Running     0          23h
   governancedomain-oim-server2                                0/1     Running     0          7s
   governancedomain-soa-server1                                1/1     Running     0          23h
   ```
   
   One new pod (`governancedomain-oim-server2`) is started, but currently has a `READY` status of `0/1`. This means `oim_server2` is not currently running but is in the process of starting. The server will take several minutes to start so keep executing the command until `READY` shows `1/1`:
   
   ```
   NAME                                                        READY   STATUS      RESTARTS   AGE 
   governancedomain-adminserver                                1/1     Running     0          23h
   governancedomain-create-fmw-infra-sample-domain-job-8cww8   0/1     Completed   0          24h
   governancedomain-oim-server1                                1/1     Running     0          23h
   governancedomain-oim-server2                                1/1     Running     0          5m27s
   governancedomain-soa-server1                                1/1     Running     0          23h
   ```
   
   **Note**: To check what is happening during server startup when `READY` is `0/1`, run the following command to view the log of the pod that is starting:
   
   ```bash
   $ kubectl logs <pod> -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl logs governancedomain-oim-server2 -n oigns
   ```

### Stopping/Scaling down OIG Managed Servers

As mentioned in the previous section, the number of OIG Managed Servers running is dependent on the `replicas` parameter configured for the cluster. To stop one or more OIG Managed Servers, perform the following:

1. Run the following kubectl command to edit the domain:

   ```bash
   $ kubectl edit domain <domain_uid> -n <domain_namespace>
   ```

   For example:

   ```bash
   $ kubectl edit domain governancedomain -n oigns
   ```

1. In the edit session search for `clusterName: oim_cluster` and look for the `replicas` parameter. In the example below `replicas` is set to "2" hence two OIG Managed Servers are started (`oim_server1` and `oim_server2`):

   ```
     - clusterName: oim_cluster
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
   
1. To stop OIG Managed Servers, decrease the `replicas` value as desired. In the example below, we will stop one Managed Server by setting replicas to "1":

   ```
     - clusterName: oim_cluster
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
   
1. Save the file and exit (:wq)

1. Run the following kubectl command to view the pods:  

   ```bash
   $ kubectl get pods -n <domain_namespace>
   ```

   For example:

   ```bash
   $ kubectl get pods -n oigns
   ```
   
   The output will look similar to the following:

   ```
   NAME                                                        READY   STATUS      RESTARTS   AGE
   governancedomain-adminserver                                1/1     Running       0          23h
   governancedomain-create-fmw-infra-sample-domain-job-8cww8   0/1     Completed     0          24h
   governancedomain-oim-server1                                1/1     Running       0          23h
   governancedomain-oim-server2                                1/1     Terminating   0          7m30s
   governancedomain-soa-server1                                1/1     Running       0          23h
   ```
   
   The exiting pod shows a `STATUS` of `Terminating` (`governancedomain-oim-server2`). The server may take a minute or two to stop, so keep executing the command until the pod has disappeared:
   
   ```
   NAME                                                        READY   STATUS      RESTARTS   AGE
   governancedomain-adminserver                                1/1     Running     0          23h
   governancedomain-create-fmw-infra-sample-domain-job-8cww8   0/1     Completed   0          24h
   governancedomain-oim-server1                                1/1     Running     0          23h
   governancedomain-soa-server1                                1/1     Running     0          23h
   ```

### Stopping and Starting the Administration Server and Managed Servers   

To stop all the OIG Managed Servers and the Administration Server in one operation:

1. Run the following kubectl command to edit the domain:

   ```bash
   $ kubectl edit domain <domain_uid> -n <domain_namespace>
   ```

   For example:

   ```bash
   $ kubectl edit domain governancedomain -n oigns
   ```
   
1. In the edit session search for `serverStartPolicy: IF_NEEDED`:

   ```
       volumeMounts:
       - mountPath: /u01/oracle/user_projects/domains
         name: weblogic-domain-storage-volume
       volumes:
       - name: weblogic-domain-storage-volume
         persistentVolumeClaim:
           claimName: governancedomain-domain-pvc
     serverStartPolicy: IF_NEEDED
   ```
   
1. Change `serverStartPolicy: IF_NEEDED` to `NEVER` as follows: 

   ```
       volumeMounts:
       - mountPath: /u01/oracle/user_projects/domains
         name: weblogic-domain-storage-volume
       volumes:
       - name: weblogic-domain-storage-volume
         persistentVolumeClaim:
           claimName: governancedomain-domain-pvc
     serverStartPolicy: NEVER
   ```
   
1. Save the file and exit (:wq).

1. Run the following kubectl command to view the pods:

   ```bash
   $ kubectl get pods -n <domain_namespace>
   ```

   For example:

   ```bash
   $ kubectl get pods -n oigns
   ```
   
   The output will look similar to the following:

   ```
   NAME                                                        READY   STATUS        RESTARTS   AGE
   governancedomain-adminserver                                1/1     Terminating   0          23h
   governancedomain-create-fmw-infra-sample-domain-job-8cww8   0/1     Completed     0          24h
   governancedomain-oim-server1                                1/1     Terminating   0          23h
   governancedomain-soa-server1                                1/1     Terminating   0          23h
   ```
   
   The AdminServer pod and Managed Server pods will move to a `STATUS` of `Terminating`. After a few minutes, run the command again and the pods should have disappeared:

   ```
   NAME                                                        READY   STATUS      RESTARTS   AGE
   governancedomain-create-fmw-infra-sample-domain-job-8cww8   0/1     Completed   0          24h
   ```

1. To start the Administration Server and Managed Servers up again, repeat the previous steps but change  `serverStartPolicy: NEVER` to `IF_NEEDED` as follows:

   ```
       volumeMounts:
       - mountPath: /u01/oracle/user_projects/domains
         name: weblogic-domain-storage-volume
       volumes:
       - name: weblogic-domain-storage-volume
         persistentVolumeClaim:
           claimName: governancedomain-domain-pvc
     serverStartPolicy: IF_NEEDED
   ```
   
1. Run the following kubectl command to view the pods:

   ```bash
   $ kubectl get pods -n <domain_namespace>
   ```

   For example:

   ```bash
   $ kubectl get pods -n oigns
   ```

   The output will look similar to the following:

   ```
   NAME                                                        READY   STATUS      RESTARTS   AGE
   governancedomain-adminserver                                0/1     Running     0          4s
   governancedomain-create-fmw-infra-sample-domain-job-8cww8   0/1     Completed   0          24h
   ```
   
   The Administration Server pod will start followed by the OIG Managed Servers pods. This process will take several minutes, so keep executing the command until all the pods are running with `READY` status `1/1` :
   
   ```
   NAME                                                        READY   STATUS      RESTARTS   AGE
   governancedomain-adminserver                                1/1     Running     0          6m57s
   governancedomain-create-fmw-infra-sample-domain-job-8cww8   0/1     Completed   0          24h
   governancedomain-oim-server1                                1/1     Running     0          4m33s
   governancedomain-soa-server1                                1/1     Running     0          4m33s
   ```


### Domain lifecycle sample scripts

The WebLogic Kubernetes Operator provides sample scripts to start up or shut down a specific Managed Server or cluster in a deployed domain, or the entire deployed domain.

**Note**: Prior to running these scripts, you must have previously created and deployed the domain.

The scripts are located in the `$WORKDIR/kubernetes/domain-lifecycle` directory. For more information, see the [README]( https://github.com/oracle/fmw-kubernetes/tree/master/OracleIdentityGovernance/kubernetes/domain-lifecycle).
