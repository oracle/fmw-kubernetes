+++
title = "Post Install Configuration"
weight = 6
pre = "<b>6. </b>"
description = "Post install configuration."
+++

Follow these mandatory post install configuration steps.

1. [WebLogic Server Tuning](#weblogic-server-tuning)
1. [Modify oamconfig.properties](#modify-oamconfigproperties)


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
1. In the **Save Deployment Plan** change the **Path** to the value **/u01/oracle/user_projects/domains/accessinfra/Plan.xml**, where `accessinfra` is your `domain_UID`.
1.  Click **OK** and then **Activate Changes**.


#### Remove Max Thread Constraint and Capacity Constraint
1. Repeat steps 1-7 above.
1. Under **Application Scoped Work Managed Components** select the check box for **Capacity** and **MaxThreadsCount**. Click **Delete**.
1. In the **Delete Work Manage Components** screen, click **OK** to delete.
1. Click on **Release Configuration** and then **Log Out**.

#### oamDS DataSource Tuning
1. Login to the WebLogic Server Console at `https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/console`.
1. Click **Lock & Edit**.
1. In **Domain Structure**, Expand **Data Sources** and click **Data Sources**.
1. Click on **oamDS**.
1. In **Settings for oamDS**, select the  **Configuration** tab, and then the **Connection Pool** tab.
1. Change **Initial Capacity**, **Maximum Capacity**, and **Minimum Capacity** to **800** and click **Save**.
1. Click **Activate Changes**.

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
   OAM_NAMESPACE='accessns'
 
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
   domainUID: accessinfra
   OAM_SERVER: accessinfra-oam-server
   OAM_NAMESPACE: accessns
   INGRESS: nginx
   INGRESS_NAME: nginx-ingress
   ING_TYPE : NodePort
   LBR_HOST: masternode.example.com
   LBR_PORT: 32190
   Started Executing Command
   % Total % Received % Xferd Average Speed Time Time Time Current
   Dload Upload Total Spent Left Speed
   100 762k 0 762k 0 0 3276k 0 --:--:-- --:--:-- --:--:-- 3273k
   new_cluster_id: abcd-accessinfra
   oamoap-service NodePort 10.96.63.13 <none> 5575:30540/TCP 5h9m
   HTTP/1.1 100 Continue
   HTTP/1.1 201 Created
   Date: Thu, 15 Oct 2020 11:22:46 GMT
   Content-Type: text/plain
   Content-Length: 76
   Connection: keep-alive
   X-ORACLE-DMS-ECID: 9aadbcc3-e0a5-46d7-882a-484b17587cf2-00005839
   X-ORACLE-DMS-RID: 0
   Set-Cookie: JSESSIONID=XmIr_3-T4iesEkMJxp5NCqZxjr5M-0icByML5hkwMQn9-KCg_zno!-992913931; path=/; HttpOnly
   Set-Cookie: _WL_AUTHCOOKIE_JSESSIONID=t2cmxfVqXI.sZLm.8tPo; path=/; secure; HttpOnly
   Strict-Transport-Security: max-age=15724800; includeSubDomains
   https://masternode.example.com:32190/iam/admin/config/api/v1/config?path=%2F
   /home/rest/output/oamconfig_modify.xml executed successfully
   ---------------------------------------------------------------------------
   Initializing WebLogic Scripting Tool (WLST) ...
   Welcome to WebLogic Server Administration Scripting Shell
   Type help() for help on available commands
   Connecting to t3://accessinfra-adminserver:7001 with userid weblogic ...
   Successfully connected to Admin Server "AdminServer" that belongs to domain "accessinfra".
   Warning: An insecure protocol was used to connect to the server.
   To ensure on-the-wire security, the SSL port or Admin port should be used instead.
   Location changed to domainRuntime tree. This is a read-only tree
   with DomainMBean as the root MBean.
   For more help, use help('domainRuntime')
   Exiting WebLogic Scripting Tool.
   Please wait for some time for the server to restart
   pod "accessinfra-oam-server1" deleted
   pod "accessinfra-oam-server2" deleted
   ```
   
   The script will delete the `accessinfra-oam-server1` and `accessinfra-oam-server2` pods and then create new ones. Check the pods are running again by issuing the following command:
   
      
   ```bash
   $ kubectl get pods -n accessns
   ```
   
   The output will look similar to the following:

   ```bash   
   NAME                                                READY   STATUS      RESTARTS   AGE
   pod/accessinfra-adminserver                         1/1     Running     0          1h17m
   pod/accessinfra-create-oam-infra-domain-job-vj69h   0/1     Completed   0          1h42m
   pod/accessinfra-oam-policy-mgr1                     1/1     Running     0          1h9m
   pod/accessinfra-oam-server1                         0/1     Running     0          31s
   pod/accessinfra-oam-server2                         0/1     Running     0          31s
   ```   
   
   The `accessinfra-oam-server1` and `accessinfra-oam-server2` are started, but currently have a `READY` status of `0/1`. This means `oam_server1` and `oam_server2` are not currently running but are in the process of starting. The servers will take several minutes to start so keep executing the command until READY shows 1/1:
   
   ```bash   
   NAME                                                READY   STATUS      RESTARTS   AGE
   pod/accessinfra-adminserver                         1/1     Running     0          1h23m
   pod/accessinfra-create-oam-infra-domain-job-vj69h   0/1     Completed   0          1h48m
   pod/accessinfra-oam-policy-mgr1                     1/1     Running     0          1h15m
   pod/accessinfra-oam-server1                         1/1     Running     0          6m
   pod/accessinfra-oam-server2                         1/1     Running     0          6m
   ```   
   