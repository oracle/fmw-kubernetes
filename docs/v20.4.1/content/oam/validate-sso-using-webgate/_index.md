+++
title = "Validate a Basic SSO Flow using WebGate Registration "
weight = 7
pre = "<b>7. </b>"
description = "Sample for validating a basic SSO flow using WebGate registration."
+++

In this section you validate single-sign on works to the OAM Kubernetes cluster via Oracle WebGate. The instructions below assume you have a running Oracle HTTP Server (for example `ohs_k8s`) and Oracle WebGate installed on an independent server. The instructions also assume basic knowledge of how to register a WebGate agent. 

**Note**: At present Oracle HTTP Server and Oracle WebGate are not supported on a Kubernetes cluster.

#### Update the OAM Hostname and Port for the Loadbalancer

If using an NGINX or Voyager ingress with no load balancer, change `{LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}` to `{MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}` when referenced below.

1. Launch a browser and access the OAM console (`https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}/oamconsole`). Login with the weblogic username and password (`weblogic/<password>`)


1. Navigate to **Configuration** → **Settings ( View )** → **Access Manager**.

1. Under Load Balancing modify the **OAM Server Host** and **OAM Server Port**, to point to the Loadbalancer HTTP endpoint (e.g `loadbalancer.example.com` and `<port>` respectively). In the **OAM Server Protocol** drop down list select **https**.

1. Under **WebGate Traffic Load Balancer** modify the **OAM Server Host** and **OAM Server Port**, to point to the Loadbalancer HTTP endpoint (e.g `loadbalancer.example.com` and `<port>` repectively). In the **OAM Server Protocol** drop down list select **https**. 

1. Click **Apply**.

#### Register a WebGate Agent

In all the examples below, change the directory path as appropriate for your installation.

1. Run the following command on the server with Oracle HTTP Server and WebGate installed:

   ```bash
   $ cd /scratch/export/home/oracle/product/middleware/webgate/ohs/tools/deployWebGate

   $ ./deployWebGateInstance.sh -w /scratch/export/home/oracle/admin/domains/oam_domain/config/fmwconfig/components/OHS/ohs_k8s -oh /scratch/export/home/oracle/product/middleware -ws ohs
   ```

   The output will look similar to the following:
   
   ```bash
   Copying files from WebGate Oracle Home to WebGate Instancedir
   ```
   
1. Run the following command to update the OHS configuration files appropriately:

   ```bash  
   $ export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/scratch/export/home/oracle/product/middleware/lib
   $ cd /scratch/export/home/oracle/product/middleware/webgate/ohs/tools/setup/InstallTools/
   $ ./EditHttpConf -w /scratch/export/home/oracle/admin/domains/oam_domain/config/fmwconfig/components/OHS/ohs_k8s -oh /scratch/export/home/oracle/product/middleware
   ```
   
   The output will look similar to the following:

   ```bash 
   The web server configuration file was successfully updated
   /scratch/export/home/oracle/admin/domains/oam_domain/config/fmwconfig/components/OHS/ohs_k8s/httpd.conf has been backed up as /scratch/export/home/oracle/admin/domains/oam_domain/config/fmwconfig/components/OHS/ohs_k8s/httpd.conf.ORIG   
   ```

1. Launch a browser, and access the OAM console. Navigate to **Application Security** → **Quick Start Wizards** → **SSO Agent Registration**. Register the agent in the usual way, download the configuration zip file and copy to the OHS WebGate server, for example: `/scratch/export/home/oracle/admin/domains/oam_domain/config/fmwconfig/components/OHS/ohs_k8/webgate/config`. Extract the zip file.

1. Copy the Certificate Authority (CA) certificate (`cacert.pem`) for the load balancer/ingress certificate to the same directory e.g: `/scratch/export/home/oracle/admin/domains/oam_domain/config/fmwconfig/components/OHS/ohs_k8/webgate/config`.

   If you used a self signed certificate for the ingress, instead copy the self signed certificate (e.g: `/scratch/ssl/tls.crt`) to the above directory. Rename the certificate to `cacert.pem`.

1. Restart Oracle HTTP Server.

1. Access the configured OHS e.g `http://ohs.example.com:7778`, and check you are redirected to the SSO login page. Login and make sure you are redirected successfully to the home page.





#### Changing WebGate agent to use OAP

**Note**: This section should only be followed if you need to change the OAM/WebGate Agent communication from HTTPS to OAP.

To change the WebGate agent to use OAP:

1. In the OAM Console click **Application Security** and then **Agents**.

1. Search for the agent you want modify and select it.

1. In the **User Defined Parameters** change:

   a) `OAMServerCommunicationMode` from `HTTPS` to `OAP`. For example `OAMServerCommunicationMode=OAP`
   
   b) `OAMRestEndPointHostName=<hostname>` to the `{$MASTERNODE-HOSTNAME}`. For example `OAMRestEndPointHostName=masternode.example.com`

1. In the **Server Lists** section click *Add* to a add new server with the following values:

   * `Access Server`: `oam_server`
   * `Host Name`: `<{$MASTERNODE-HOSTNAME}>`
   * `Host Port`: `<oamoap-service NodePort>`

   **Note**: To find the value for `Host Port` run the following:

   ```bash
   $ kubectl describe svc oamoap-service -n accessns
   ```
   
   The output will look similar to the following:
   
   ```
   Name: oamoap-service
   Namespace: accessns
   Labels: <none>
   Annotations: <none>
   Selector: weblogic.clusterName=oam_cluster
   Type: NodePort
   IP: 10.96.63.13
   Port: <unset> 5575/TCP
   TargetPort: 5575/TCP
   NodePort: <unset> 30540/TCP
   Endpoints: 10.244.0.30:5575,10.244.0.31:5575
   Session Affinity: None
   External Traffic Policy: Cluster
   Events: <none>
   ```

1. Delete all servers in **Server Lists** except for the one just created, and click `Apply`.

1. Click Download to download the webgate zip file. Copy the zip file to the desired WebGate.

