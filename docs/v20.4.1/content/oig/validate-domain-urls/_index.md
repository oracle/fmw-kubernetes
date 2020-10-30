+++
title = "Validate Domain URLs"
weight = 5
pre = "<b>5. </b>"
description = "Sample for validating domain urls."
+++

In this section you validate the OIG domain URLs that are accessible via the NGINX or Voyager ingress.

Make sure you know the master hostname and port before proceeding.

#### Validate the OIG domain urls via the Ingress

Launch a browser and access the following URL's. Use `http` or `https` depending on whether you configured your ingress for non-ssl or ssl. 

Login to the WebLogic Administration Console and Oracle Enterprise Manager Console with the WebLogic username and password (`weblogic/<password>`).

Login to Oracle Identity Governance with the xelsysadm username and password (`xelsysadm/<password>`).

| Console or Page | URL | 
| --- | --- | 
| WebLogic Administration Console | `https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/console` | 
| Oracle Enterprise Manager Console | `https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/em` 
| Oracle Identity System Administration  | `https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/sysadmin` |
| Oracle Identity Self Service | `https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/identity` |

 **Note**: WebLogic Administration Console and Oracle Enterprise Manager Console should only be used to monitor the servers in the OIG domain. To control the Administration Server and OIG Managed Servers (start/stop) you must use Kubernetes. See [Domain Life Cycle ]({{< relref "/oig/manage-oig-domains/domain-lifecycle" >}}) for more information.
 
 The browser will give certificate errors if you used a self signed certifcate and have not imported it into the browsers Certificate Authority store. If this occurs you can proceed with the connection and ignore the errors.

