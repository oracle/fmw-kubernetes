+++
title = "Validate Domain URLs"
weight = 5
pre = "<b>5. </b>"
description = "Sample for validating domain urls."
+++

In this section you validate the OAM domain URLs are accessible via the NGINX or Voyager ingress.

Make sure you know the master hostname and ingress port for NGINX or Voyager before proceeding.


#### Validate the OAM domain urls via the Ingress

Launch a browser and access the following URL's. Login with the weblogic username and password (`weblogic/<password>`).

| Console or Page | URL | 
| --- | --- | 
| WebLogic Administration Console | `https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/console` | 
| Oracle Enterprise Manager Console | `https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/em` 
| Oracle Access Management Console | `https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/oamconsole` |
| Oracle Access Management Console | `https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/access` |
| Logout URL | `https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/oam/server/logout` |


 **Note**: WebLogic Administration Console and Oracle Enterprise Manager Console should only be used to monitor the servers in the OAM domain. To control the Administration Server and OAM Managed Servers (start/stop) you must use Kubernetes. See [Domain Life Cycle ]({{< relref "/oam/manage-oam-domains/domain-lifecycle" >}}) for more information.
 
 The browser will give certificate errors if you used a self signed certifcate and have not imported it into the browsers Certificate Authority store. If this occurs you can proceed with the connection and ignore the errors.

