+++
title = "Post Install Configuration"
weight = 7
pre = "<b>7. </b>"
description = "Post install configuration."
+++

Follow these post install configuration steps.


1. [Create a Server Overrides File](#create-a-server-overrides-file)
1. [Removing OAM Server from WebLogic Server 12c Default Coherence Cluster](#removing-oam-server-from-weblogic-server-12c-default-coherence-cluster)
1. [WebLogic Server Tuning](#weblogic-server-tuning)
1. [Enable Virtualization](#enable-virtualization)
1. [Modify oamconfig.properties](#modify-oamconfigproperties)

### Create a Server Overrides File

1. Navigate to the following directory:

   ```
   $ cd <work directory>/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-access-domain/domain-home-on-pv/output/weblogic-domains/accessdomain
   ```
   
   For example:
   
   ```
   $ cd /scratch/OAMDockerK8S/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-access-domain/domain-home-on-pv/output/weblogic-domains/accessdomain
   ```
   
1. Create a `setUserOverrides.sh` with the following contents:

   ```
   DERBY_FLAG=false
   JAVA_OPTIONS="${JAVA_OPTIONS} -Djava.net.preferIPv4Stack=true"
   MEM_ARGS="-Xms8192m -Xmx8192m"
   ```
   
1. Copy the `setUserOverrides.sh` file to the Administration Server pod:

   ```
   $ chmod 755 setUserOverrides.sh
   $ kubectl cp setUserOverrides.sh oamns/accessdomain-adminserver:/u01/oracle/user_projects/domains/accessdomain/bin/setUserOverrides.sh
   ```
   
   Where `oamns` is the OAM namespace and `accessdomain` is the `DOMAIN_NAME/UID`.

1. Stop the OAM domain using the following command:
  
   ```
   $ kubectl -n <domain_namespace> patch domains <domain_uid> --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "NEVER" }]'
   ```
   
   For example:
   
   ```
   $ kubectl -n oamns patch domains accessdomain --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "NEVER" }]'
   ```
   
   The output will look similar to the following:
   
   ```
   domain.weblogic.oracle/accessdomain patched
   ```

1. Check that all the pods are stopped:

   ```
   $ kubectl get pods -n <domain_namespace>
   ```
   
   For example:
   
   ```
   $ kubectl get pods -n oamns
   ```
   
   The output will look similar to the following:

   ```
   NAME                                            READY    STATUS        RESTARTS   AGE
   accessdomain-adminserver                         1/1     Terminating   0          18h
   accessdomain-create-oam-infra-domain-job-vj69h   0/1     Completed     0          24h
   accessdomain-oam-policy-mgr1                     1/1     Terminating   0          18h
   accessdomain-oam-server1                         1/1     Terminating   0          18h
   accessdomain-oam-server2                         1/1     Terminating   0          18h
   helper                                           1/1     Running       0          41h
   ```

   The Administration Server pods and Managed Server pods will move to a STATUS of `Terminating`. After a few minutes, run the command again and the pods should have disappeared:
   
   ```
   NAME                                            READY   STATUS      RESTARTS   AGE
   accessdomain-create-oam-infra-domain-job-vj69h  0/1     Completed   0          24h
   helper                                          1/1     Running     0          41h
   ```
   
1. Start the domain using the following command:

   ```
   $ kubectl -n <domain_namespace> patch domains <domain_uid> --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "IF_NEEDED" }]'
   ```
   
   For example:
   
   ```
   $ kubectl -n oamns patch domains accessdomain --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "IF_NEEDED" }]'
   ```
   
   Run the following kubectl command to view the pods:
   
   ```
   $ kubectl get pods -n <domain_namespace>
   ```
   
   For example:
   
   ```
   $ kubectl get pods -n oamns
   ```
   
   The output will look similar to the following:

   ```
   NAME                                            READY   STATUS      RESTARTS   AGE
   accessdomain-create-oam-infra-domain-job-vj69h  0/1     Completed   0          24h
   accessdomain-introspect-domain-job-7qx29        1/1     Running     0          8s
   helper                                          1/1     Running     0          41h
   ```
   
   The Administration Server pod will start followed by the OAM Managed Servers pods. This process will take several minutes, so keep executing the command until all the pods are running with `READY` status `1/1`:

   ```
   NAME                                            READY   STATUS      RESTARTS   AGE  
   accessdomain-adminserver                        1/1     Running     0          6m4s
   accessdomain-create-oam-infra-domain-job-vj69h  0/1     Completed   0          24h
   accessdomain-oam-policy-mgr1                    1/1     Running     0          3m5s
   accessdomain-oam-server1                        1/1     Running     0          3m5s
   accessdomain-oam-server2                        1/1     Running     0          3m5s
   helper                                          1/1     Running     0          41h
   ```


### Removing OAM Server from WebLogic Server 12c Default Coherence Cluster

Exclude all Oracle Access Management (OAM) clusters (including Policy Manager and OAM runtime server) from the default WebLogic Server 12c coherence cluster by using the WebLogic Server Administration Console.

From 12.2.1.3.0 onwards, OAM server-side session management uses database and does not require coherence cluster to be established. In some environments, warnings and errors are observed due to default coherence cluster initialized by WebLogic. To avoid or fix these errors, exclude all of the OAM clusters from default WebLogic Server coherence cluster using the following steps:

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


### Modify oamconfig.properties

1. Navigate to the following directory and change permissions for the `oamconfig_modify.sh`:

   ```bash
   $ cd <work directory>/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-access-domain/domain-home-on-pv/common
   $ chmod 777 oamconfig_modify.sh
   ```
   
   For example:
   
   ```bash
   $ cd /scratch/OAMDockerK8S/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-access-domain/domain-home-on-pv/common
   $ chmod 777 oamconfig_modify.sh
   ```

1. Edit the `oamconfig.properties` and change the `OAM_NAMESPACE`, `INGRESS`, `INGRESS_NAME`, and `LBR_HOST` to match the values for your OAM Kubernetes environment. For example:

   ```   
   #Below are only the sample values, please modify them as per your setup
 
   # The name space where OAM servers are created
   OAM_NAMESPACE='oamns'
 
   # Define the INGRESS CONTROLLER used. typical values are voyager/nginx
   INGRESS="nginx"
 
   # Define the INGRESS CONTROLLER name used during installation.
   INGRESS_NAME="nginx-ingress"
 
   # FQDN of the LBR Host i.e the host from where you access oam console
   LBR_HOST="masternode.example.com"
   ```

1. Run the `oamconfig_modify.sh` script as follows:

   ```bash
   $ ./oamconfig_modify.sh <OAM_ADMIN_USER>:<OAM_ADMIN_PASSWORD>
   ```
   
   where:
   
   `OAM_ADMIN_USER` is the OAM administrator username
   
   `OAM_ADMIN_PASSWORD` is the OAM administrator password

   For example:
   
   ```bash
   $ ./oamconfig_modify.sh weblogic:<password>
   ```
   
   **Note**: Make sure port `30540` is free before running the command.
   
   The output will look similar to the following:
   
   ```
   LBR_PROTOCOL: https
   domainUID: accessdomain
   OAM_SERVER: accessdomain-oam-server
   OAM_NAMESPACE: oamns
   INGRESS: nginx
   INGRESS_NAME: nginx-ingress
   ING_TYPE : NodePort
   LBR_HOST: masternode.example.com
   LBR_PORT: 32190
   Started Executing Command
   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
   Dload  Upload   Total   Spent    Left  Speed
   100  752k    0  752k    0     0   526k      0 --:--:--  0:00:01 --:--:--  526k
   new_cluster_id: 5e3ce-masternode
   service/oamoap-service created
   nginx-ingress-ingress-nginx-controller   NodePort    10.104.229.200   <none>        80:32412/TCP,443:30555/TCP   2d17h
   oamoap-service                           NodePort    10.106.155.193   <none>        5575:30540/TCP               0s
   HTTP/1.1 100 Continue

   HTTP/1.1 201 Created
   Content-Type: text/plain
   Content-Length: 76
   Connection: keep-alive
   X-ORACLE-DMS-ECID: a9222626-7c7a-4506-94fd-b2acfbb4e146-0000047f
   X-ORACLE-DMS-RID: 0
   Set-Cookie: JSESSIONID=y21yaD9mWO5lPBv808bEYugB7cyRAJ4yUxryfLZ08puDjXUG_sd2!-1157379773; path=/; HttpOnly
   Set-Cookie: _WL_AUTHCOOKIE_JSESSIONID=Twy1lPz58QhVjCheOfWp; path=/; secure; HttpOnly
   Strict-Transport-Security: max-age=15724800; includeSubDomains

   https://masternode.example.com:32190/iam/admin/config/api/v1/config?path=%2F

    /scratch/OAMDockerK8S/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-access-domain/domain-home-on-pv/common/output/oamconfig_modify.xml executed successfully
   ---------------------------------------------------------------------------

   Initializing WebLogic Scripting Tool (WLST) ...

   Welcome to WebLogic Server Administration Scripting Shell

   Type help() for help on available commands

   Connecting to t3://accessdomain-adminserver:7001 with userid weblogic ...
   Successfully connected to Admin Server "AdminServer" that belongs to domain "accessdomain".

   Warning: An insecure protocol was used to connect to the server.
   To ensure on-the-wire security, the SSL port or Admin port should be used instead.

   Location changed to domainRuntime tree. This is a read-only tree
   with DomainMBean as the root MBean.
   For more help, use help('domainRuntime')

   Exiting WebLogic Scripting Tool.

   Please wait for some time for the server to restart
   pod "accessdomain-oam-server1" deleted
   pod "accessdomain-oam-server2" deleted
   Waiting continuously at an interval of 10 secs for servers to start..
   Waiting continuously at an interval of 10 secs for servers to start..
   Waiting continuously at an interval of 10 secs for servers to start..
   Waiting continuously at an interval of 10 secs for servers to start..
   Waiting continuously at an interval of 10 secs for servers to start..
   Waiting continuously at an interval of 10 secs for servers to start..
   Waiting continuously at an interval of 10 secs for servers to start..
   Waiting continuously at an interval of 10 secs for servers to start..
   Waiting continuously at an interval of 10 secs for servers to start..
   accessdomain-oam-server1 1/1 Running 0 2m23s
   accessdomain-oam-server2 1/1 Running 0 2m24s
   OAM servers started successfully
   ```
   
   The script will delete the `accessdomain-oam-server1` and `accessdomain-oam-server2` pods and then create new ones. Check the pods are running again by issuing the following command:
   
      
   ```bash
   $ kubectl get pods -n oamns
   ```
   
   The output will look similar to the following:

   ```bash   
   NAME                                                READY   STATUS      RESTARTS   AGE
   pod/accessdomain-adminserver                         1/1     Running     0          1h17m
   pod/accessdomain-create-oam-infra-domain-job-vj69h   0/1     Completed   0          1h42m
   pod/accessdomain-oam-policy-mgr1                     1/1     Running     0          1h9m
   pod/accessdomain-oam-server1                         0/1     Running     0          31s
   pod/accessdomain-oam-server2                         0/1     Running     0          31s
   ```   
   
   The `accessdomain-oam-server1` and `accessdomain-oam-server2` are started, but currently have a `READY` status of `0/1`. This means `oam_server1` and `oam_server2` are not currently running but are in the process of starting. The servers will take several minutes to start so keep executing the command until READY shows 1/1:
   
   ```bash   
   NAME                                                READY   STATUS      RESTARTS   AGE
   pod/accessdomain-adminserver                         1/1     Running     0          1h23m
   pod/accessdomain-create-oam-infra-domain-job-vj69h   0/1     Completed   0          1h48m
   pod/accessdomain-oam-policy-mgr1                     1/1     Running     0          1h15m
   pod/accessdomain-oam-server1                         1/1     Running     0          6m
   pod/accessdomain-oam-server2                         1/1     Running     0          6m
   ```   
   