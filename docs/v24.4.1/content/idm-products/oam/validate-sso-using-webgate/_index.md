+++
title = "Validate a Basic SSO Flow using WebGate Registration "
weight = 9
pre = "<b>9. </b>"
description = "Sample for validating a basic SSO flow using WebGate registration."
+++

In this section you validate single-sign on works to the OAM Kubernetes cluster via Oracle WebGate. 

The instructions below assume you have a running Oracle HTTP Server (OHS) (for example `ohs1`) and Oracle WebGate installed either in an on-premises setup, or in a Kubernetes cluster. If you are deploying OHS on a Kubernetes cluster, see the [Supported Architectures](../../../ohs/introduction/#supported-architectures).

The instructions also assume you have a working knowledge of OHS and WebGate.


## Update the OAM Hostname and Port for the Loadbalancer

You must update OAM with the protocol, hostname.domain, and port for your OAM entry point. 


For example:

+ `https://loadbalancer.example.com` - if OAM URL's are accessed directly via a load balancer URL, with hostname `loadbalancer.example.com` and port `443`.
+ `https://ohs.example.com:4443` - if OAM URL's are accessed directly via an OHS URL, with hostname `ohs.example.com` and port `4443`.
+ `https://masternode.example.com:31501` - if OAM URL's are accessed directly via the ingress controller, with hostname `masternode.example.com` and port `31501`.


In the following examples change `{HOSTNAME}:${PORT}` accordingly.


1. Launch a browser and access the OAM console (`https://${HOSTNAME}:${PORT}/oamconsole`). Login with the weblogic username and password (`weblogic/<password>`).

1. Navigate to **Configuration** → **Settings ( View )** → **Access Manager**.

1. Under Load Balancing modify the **OAM Server Host** and **OAM Server Port**, to point to the hostname.domain of your OAM entry point, for example `loadbalancer.example.com` and `443` respectively. In the **OAM Server Protocol** drop down list select **https**.

1. Under **WebGate Traffic Load Balancer** modify the **OAM Server Host** and **OAM Server Port**, to point to the hostname.domain of your OAM entry point, for example `loadbalancer.example.com` and `443` respectively. In the **OAM Server Protocol** drop down list select **https**. 

1. Click **Apply**.




## Register a WebGate Agent



1. Launch a browser, and access the OAM console. 

1. Navigate to **Application Security** → **Quick Start Wizards** → **SSO Agent Registration**. Register the agent in the usual way.

1. After creating the agent, make sure the **User Defined Parameters** for **OAMRestEndPointHostName**, **OAMRestEndPointPort**, and **OAMServerCommunicationMode** are set to the same values as per [Update the OAM Hostname and Port for the Loadbalancer](#update-the-oam-hostname-and-port-for-the-loadbalancer). Click **Apply**.

1. Click **Download** to download the agent zip file and keep in a safe place. This file this will be required in [Configure OHS to use the WebGate](#configure-ohs-to-use-the-webgate).



## Configure the Application Domain

1. In the OAM console, navigate to  **Application Security** → **Application Domains**. Click **Search**, and click the domain for the agent just created. 

1. In the Application Domain page, under **Resources**, click **Create** and protect a simple resource, for example `/myapp/**`. Change the following:

   + **Type**: `HTTP`
	+ **Host Identifier**: `<your_application_domain>`
	+ **Protection Level**: `Protected`
	+ **Authentication Policy**: `Protected Resource Policy`
	+ **Authorization Policy**: `Protected Resource Policy`

   **Note**: The purpose of the above is to test a simple page protection works. Once everything is confirmed as working, you can configure your desired resources and policies.

1. Click **Apply**.


## Create Host Identifiers

1. In the OAM console, navigate to  **Application Security** → **Access Manager** → **Host Identifiers**. Click **Search**, and click the **Name** for the agent just created. 

1. In the **Host Name Variations**, click **Add**.

1. In the new line that appears, add the details for any URL that will be used for this WebGate, for example if you access a protected URL via `https://loadbalancer.example.com`, then under **Host Name** enter `loadbalancer.example.com` and under **Port** enter 443. Click **Apply**.

1. Repeat for any other required URL's.



## Configure OHS to use the WebGate

Follow the relevant section depending on whether your are using on-premises OHS, or OHS deployed in Kubernetes.


### On-premises OHS installation 

The instructions in this section are for on-premises OHS installations only.

In all the examples below, change the directory path as appropriate for your installation.

1. Run the following command on the server with Oracle HTTP Server and WebGate installed:

   ```bash
   $ cd <OHS_ORACLE_HOME>/webgate/ohs/tools/deployWebGate

   $ ./deployWebGateInstance.sh -w <OHS_DOMAIN_HOME>/config/fmwconfig/components/OHS/ohs1 -oh <OHS_ORACLE_HOME> -ws ohs
   ```

   The output will look similar to the following:
   
   ```
   Copying files from WebGate Oracle Home to WebGate Instancedir
   ```
   
1. Run the following command to update the OHS configuration files appropriately:

   ```bash  
   $ export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:<OHS_ORACLE_HOME>/lib
   $ cd <OHS_ORACLE_HOME>/webgate/ohs/tools/setup/InstallTools/
   $ ./EditHttpConf -w <OHS_DOMAIN_HOME>/config/fmwconfig/components/OHS/ohs1 -oh <OHS_ORACLE_HOME>
   ```
   
   The output will look similar to the following:

   ```
   The web server configuration file was successfully updated
   <OHS_DOMAIN_HOME>/config/fmwconfig/components/OHS/ohs1/httpd.conf has been backed up as <OHS_DOMAIN_HOME>/config/fmwconfig/components/OHS/ohs1/httpd.conf.ORIG   
   ```


1. Copy the agent zip file downloaded earlier and copy to the OHS server, for example: `<OHS_DOMAIN_HOME>/config/fmwconfig/components/OHS/ohs1/webgate/config`. Extract the zip file.

1. Obtain the Certificate Authority (CA) certificate (`cacert.pem`) that signed the certificate for your OAM entry point. Copy to the to the same directory, for example: `<OHS_DOMAIN_HOME>/config/fmwconfig/components/OHS/ohs1/webgate/config`.

   **Note**: 
	
	+ The CA certificate is the certificate that signed the certificate for your OAM entry point. For example if you access OAM directly via a load balancer, then this is the CA of the load balancer certificate.
	+ The file must be renamed to `cacert.pem`.

1. Restart Oracle HTTP Server.

1. Access the protected resource, for example `https://ohs.example.com/myapp`, and check you are redirected to the SSO login page. Login and make sure you are redirected successfully to the home page.


### OHS deployed on Kubernetes

If deploying OHS on Kubernetes you must copy the agent zip file downloaded earlier to the `$WORKDIR/ohsConfig/webgate/config` directory and extract it.

See [Prepare your OHS configuration files](../../../ohs/prepare-your-environment/#prepare-your-ohs-configuration-files) for detailed instructions.


### Changing WebGate agent to use OAP

**Note**: This section should only be followed if you need to change the OAM/WebGate Agent communication from HTTPS to OAP.

To change the WebGate agent to use OAP:

1. In the OAM Console click **Application Security** and then **Agents**.

1. Search for the agent you want modify and select it.

1. In the **User Defined Parameters** change:

   a) `OAMServerCommunicationMode` from `HTTPS` to `OAP`. For example `OAMServerCommunicationMode=OAP`
   
   b) `OAMRestEndPointHostName=<hostname>` to the `{$MASTERNODE-HOSTNAME}`. For example `OAMRestEndPointHostName=masternode.example.com`

1. In the **Server Lists** section click *Add* to add a new server with the following values:

   * `Access Server`: `Other`
   * `Host Name`: `<{$MASTERNODE-HOSTNAME}>`
   * `Host Port`: `<oamoap-service NodePort>`

   **Note**: To find the value for `Host Port` run the following:

   ```bash
   $ kubectl describe svc accessdomain-oamoap-service -n oamns
   ```
   
   The output will look similar to the following:
   
   ```
   Name:                     accessdomain-oamoap-service
   Namespace:                oamns
   Labels:                   <none>
   Annotations:              <none>
   Selector:                 weblogic.clusterName=oam_cluster
   Type:                     NodePort
   IP Families:              <none>
   IP:                       10.100.202.44
   IPs:                      10.100.202.44
   Port:                     <unset>  5575/TCP
   TargetPort:               5575/TCP
   NodePort:                 <unset>  30540/TCP
   Endpoints:                10.244.5.21:5575,10.244.6.76:5575
   Session Affinity:         None
   External Traffic Policy:  Cluster
   Events:                   <none>
   ```
   
   In the example above the `NodePort` is `30540`.
   
1. Delete all servers in **Server Lists** except for the one just created, and click `Apply`.

1. Click **Download** to download the webgate zip file. Copy the zip file to the desired WebGate.

1. Delete the cache from `<OHS_DOMAIN_HOME>/servers/ohs1/cache` and restart Oracle HTTP Server.

