+++
title = "Validate Domain URLs"
weight = 7
pre = "<b>7. </b>"
description = "Sample for validating domain urls."
+++

In this section you validate the OAM domain URLs are accessible via the NGINX ingress.


#### Validate the OAM domain urls via the Ingress

Launch a browser and access the following URL's. Login with the weblogic username and password (`weblogic/<password>`).

**Note**: The `${HOSTNAME}:${PORT}` depends on the architecture configured, and your ingress setup as per [Configuring an ingress for NGINX for the OAM Domain](../configure-ingress).

| Console or Page | URL | 
| --- | --- | 
| WebLogic Administration Console | `http(s)://${HOSTNAME}:${PORT}/console` | 
| Oracle Enterprise Manager Console | `http(s)://${HOSTNAME}:${PORT}/em` 
| Oracle Access Management Console | `http(s)://${HOSTNAME}:${PORT}/oamconsole` |
| Oracle Access Management Console | `http(s)://${HOSTNAME}:${PORT}/access` |
| Logout URL | `http(s)://${HOSTNAME}:${PORT}/oam/server/logout` |


**Note**: WebLogic Administration Console and Oracle Enterprise Manager Console should only be used to monitor the servers in the OAM domain. To control the Administration Server and OAM Managed Servers (start/stop) you must use Kubernetes. See [Domain Life Cycle ](../manage-oam-domains/domain-lifecycle) for more information.
 
The browser will give certificate errors if you used a self signed certificate and have not imported it into the browsers Certificate Authority store. If this occurs you can proceed with the connection and ignore the errors.
 
After validating the URL's proceed to [Post Install Configuration](../post-install-config).

