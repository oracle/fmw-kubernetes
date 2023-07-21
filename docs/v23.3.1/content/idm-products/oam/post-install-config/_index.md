+++
title = "Post Install Configuration"
weight = 8
pre = "<b>8. </b>"
description = "Post install configuration."
+++

Follow these post install configuration steps.


1. [Create a Server Overrides File](#create-a-server-overrides-file)
1. [Removing OAM Server from WebLogic Server 12c Default Coherence Cluster](#removing-oam-server-from-weblogic-server-12c-default-coherence-cluster)
1. [WebLogic Server Tuning](#weblogic-server-tuning)
1. [Enable Virtualization](#enable-virtualization)
1. [Restart the domain](#restart-the-domain)

### Create a Server Overrides File

1. Navigate to the following directory:

   ```bash
   $ cd $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/output/weblogic-domains/accessdomain
   ```
   
1. Create a `setUserOverrides.sh` with the following contents:

   ```
   DERBY_FLAG=false
   JAVA_OPTIONS="${JAVA_OPTIONS} -Djava.net.preferIPv4Stack=true"
   MEM_ARGS="-Xms8192m -Xmx8192m"
   ```
   
1. Copy the `setUserOverrides.sh` file to the Administration Server pod:

   ```bash
   $ chmod 755 setUserOverrides.sh
   $ kubectl cp setUserOverrides.sh oamns/accessdomain-adminserver:/u01/oracle/user_projects/domains/accessdomain/bin/setUserOverrides.sh
   ```
   
   Where `oamns` is the OAM namespace and `accessdomain` is the `DOMAIN_NAME/UID`.

1. Stop the OAM domain using the following command:
  
   ```bash
   $ kubectl -n <domain_namespace> patch domains <domain_uid> --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "Never" }]'
   ```
   
   For example:
   
   ```bash
   $ kubectl -n oamns patch domains accessdomain --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "Never" }]'
   ```
   
   The output will look similar to the following:
   
   ```
   domain.weblogic.oracle/accessdomain patched
   ```

1. Check that all the pods are stopped:

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
   accessdomain-adminserver                                 1/1     Terminating   0          27m
   accessdomain-create-oam-infra-domain-job-7c9r9           0/1     Completed     0          4h29m
   accessdomain-oam-policy-mgr1                             1/1     Terminating   0          24m
   accessdomain-oam-policy-mgr2                             1/1     Terminating   0          24m
   accessdomain-oam-server1                                 1/1     Terminating   0          24m
   accessdomain-oam-server2                                 1/1     Terminating   0          24m
   helper                                                   1/1     Running       0          4h44m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running       0          108m
   ```

   The Administration Server pods and Managed Server pods will move to a STATUS of `Terminating`. After a few minutes, run the command again and the pods should have disappeared:
   
   ```
   NAME                                                     READY   STATUS      RESTARTS   AGE
   accessdomain-create-oam-infra-domain-job-7c9r9           0/1     Completed   0          4h30m
   helper                                                   1/1     Running     0          4h45m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          109m
   ```
   
1. Start the domain using the following command:

   ```bash
   $ kubectl -n <domain_namespace> patch domains <domain_uid> --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "IfNeeded" }]'
   ```
   
   For example:
   
   ```bash
   $ kubectl -n oamns patch domains accessdomain --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "IfNeeded" }]'
   ```
   
   Run the following kubectl command to view the pods:
   
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
   accessdomain-create-oam-infra-domain-job-7c9r9           0/1     Completed   0          4h30m
   accessdomain-introspector-mckp2                          1/1     Running     0          8s
   helper                                                   1/1     Running     0          4h46m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          110m
   ```
   
   The Administration Server pod will start followed by the OAM Managed Servers pods. This process will take several minutes, so keep executing the command until all the pods are running with `READY` status `1/1`:

   ```
   NAME                                                     READY   STATUS      RESTARTS   AGE  
   accessdomain-adminserver                                 1/1     Running     0          5m38s
   accessdomain-create-oam-infra-domain-job-7c9r9           0/1     Completed   0          4h37m
   accessdomain-oam-policy-mgr1                             1/1     Running     0          2m51s
   accessdomain-oam-policy-mgr2                             1/1     Running     0          2m51s
   accessdomain-oam-server1                                 1/1     Running     0          2m50s
   accessdomain-oam-server2                                 1/1     Running     0          2m50s
   helper                                                   1/1     Running     0          4h52m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          116m
   ```


### Removing OAM Server from WebLogic Server 12c Default Coherence Cluster

Exclude all Oracle Access Management (OAM) clusters (including Policy Manager and OAM runtime server) from the default WebLogic Server 12c coherence cluster by using the WebLogic Server Administration Console.

From 12.2.1.3.0 onwards, OAM server-side session management uses the database and does not require coherence cluster to be established. In some environments, warnings and errors are observed due to default coherence cluster initialized by WebLogic. To avoid or fix these errors, exclude all of the OAM clusters from default WebLogic Server coherence cluster using the following steps:

1. Login to the WebLogic Server Console at `https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/console`.
1. Click **Lock & Edit**.
1. In **Domain Structure**, expand **Environment** and select **Coherence Clusters**.
1. Click **defaultCoherenceCluster** and select the **Members** tab.
1. From **Servers and Clusters**, deselect all OAM clusters (oam_cluster and policy_cluster).
1. Click **Save**.
1. Click **Activate changes**.

### WebLogic Server Tuning

For production environments, the following WebLogic Server tuning parameters must be set:

#### Add Minimum Thread constraint to worker manager "OAPOverRestWM"

1. Login to the WebLogic Server Console at `https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/console`.
1. Click **Lock & Edit**.
1. In **Domain Structure**, click **Deployments**. 
1. On the **Deployments** page click **Next** until you see **oam_server**.
1. Expand **oam_server** by clicking on the **+** icon, then click **/iam/access/binding**.
1. Click the **Configuration** tab, followed by the **Workload** tab.
1. Click **wm/OAPOverRestWM**
1. Under **Application Scoped Work Managed Components**, click **New**.
1. In **Create a New Work Manager Component**, select **Minumum Threads Constraint** and click **Next**.
1. In **Minimum Threads Constraint Properties** enter the **Count** as **400** and click **Finish**.
1. In the **Save Deployment Plan** change the **Path** to the value **/u01/oracle/user_projects/domains/accessdomain/Plan.xml**, where `accessdomain` is your `domain_UID`.
1.  Click **OK** and then **Activate Changes**.


#### Remove Max Thread Constraint and Capacity Constraint
1. Repeat steps 1-7 above.
1. Under **Application Scoped Work Managed Components** select the check box for **Capacity** and **MaxThreadsCount**. Click **Delete**.
1. In the **Delete Work Manage Components** screen, click **OK** to delete.
1. Click on **Release Configuration** and then **Log Out**.

#### oamDS DataSource Tuning
1. Login to the WebLogic Server Console at `https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/console`.
1. Click **Lock & Edit**.
1. In **Domain Structure**, Expand **Services** and click **Data Sources**.
1. Click on **oamDS**.
1. In **Settings for oamDS**, select the  **Configuration** tab, and then the **Connection Pool** tab.
1. Change **Initial Capacity**, **Maximum Capacity**, and **Minimum Capacity** to **800** and click **Save**.
1. Click **Activate Changes**.

### Enable Virtualization

1. Log in to Oracle Enterprise Manager Fusion Middleware Control at `https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/em`
1. Click **WebLogic Domain** > **Security** > **Security Provider Configuration**.
1. Expand Security Store Provider.
1. Expand Identity Store Provider.
1. Click **Configure**.
1. Add a custom property.
1. Select `virtualize` property with value `true` and click **OK**.
1. Click **OK** again to persist the change.

### Restart the domain

For the above changes to take effect, you must restart the OAM domain:

1. Stop the OAM domain using the following command:
  
   ```bash
   $ kubectl -n <domain_namespace> patch domains <domain_uid> --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "Never" }]'
   ```
   
   For example:
   
   ```bash
   $ kubectl -n oamns patch domains accessdomain --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "Never" }]'
   ```
   
   The output will look similar to the following:
   
   ```
   domain.weblogic.oracle/accessdomain patched
   ```

1. Check that all the pods are stopped:

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
   accessdomain-adminserver                                 1/1     Terminating   0          27m
   accessdomain-create-oam-infra-domain-job-7c9r9           0/1     Completed     0          4h29m
   accessdomain-oam-policy-mgr1                             1/1     Terminating   0          24m
   accessdomain-oam-policy-mgr2                             1/1     Terminating   0          24m
   accessdomain-oam-server1                                 1/1     Terminating   0          24m
   accessdomain-oam-server2                                 1/1     Terminating   0          24m
   helper                                                   1/1     Running       0          4h44m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running       0          108m
   ```

   The Administration Server pods and Managed Server pods will move to a STATUS of `Terminating`. After a few minutes, run the command again and the pods should have disappeared:
   
   ```
   NAME                                                     READY   STATUS      RESTARTS   AGE
   accessdomain-create-oam-infra-domain-job-7c9r9           0/1     Completed   0          4h30m
   helper                                                   1/1     Running     0          4h45m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          109m
   ```
   
1. Start the domain using the following command:

   ```bash
   $ kubectl -n <domain_namespace> patch domains <domain_uid> --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "IfNeeded" }]'
   ```
   
   For example:
   
   ```bash
   $ kubectl -n oamns patch domains accessdomain --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "IfNeeded" }]'
   ```
   
   Run the following kubectl command to view the pods:
   
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
   accessdomain-create-oam-infra-domain-job-7c9r9           0/1     Completed   0          4h30m
   accessdomain-introspector-mckp2                          1/1     Running     0          8s
   helper                                                   1/1     Running     0          4h46m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          110m
   ```
   
   The Administration Server pod will start followed by the OAM Managed Servers pods. This process will take several minutes, so keep executing the command until all the pods are running with `READY` status `1/1`:

   ```
   NAME                                                     READY   STATUS      RESTARTS   AGE  
   accessdomain-adminserver                                 1/1     Running     0          5m38s
   accessdomain-create-oam-infra-domain-job-7c9r9           0/1     Completed   0          4h37m
   accessdomain-oam-policy-mgr1                             1/1     Running     0          2m51s
   accessdomain-oam-policy-mgr2                             1/1     Running     0          2m51s
   accessdomain-oam-server1                                 1/1     Running     0          2m50s
   accessdomain-oam-server2                                 1/1     Running     0          2m50s
   helper                                                   1/1     Running     0          4h52m
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          116m
   ```