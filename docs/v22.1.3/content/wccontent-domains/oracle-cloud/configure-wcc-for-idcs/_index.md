+++
title = "Configuring Oracle WebCenter Content for  Oracle Identity Cloud Service (IDCS)"
date =  2021-02-14T16:43:45-05:00
weight = 5
pre = "<b>5.  </b>"
description = "Configuring Oracle WebCenter Content for  Oracle Identity Cloud Service (IDCS)"
+++

#### Contents
* [Introduction](#introduction)
* [Updating SSL.hostnameVerifier Property](#updating-sslhostnameverifier-property)
* [Configuring IDCS Security Provider](#configuring-idcs-security-provider)
* [Configuring Oracle Identity Cloud Integrator Provider](#configuring-oracle-identity-cloud-integrator-provider)
* [Setting Up Trust between IDCS and WebLogic](#setting-up-trust-between-idcs-and-weblogic)
* [Creating Admin User in IDCS Admin Console for WebCenter Content](#creating-admin-user-in-idcs-admin-console-for-webcenter-content)
* [Managing Group Memberships, Roles, and Accounts](#managing-group-memberships-roles-and-accounts)
* [Configuring WebCenter Content for User Logout](#configuring-webcenter-content-for-user-logout)



#### Introduction

Configuring WebCenter Content for Oracle Identity Cloud Service (IDCS) on OKE.
Configuration information is provided in the following sections:

* Updating SSL.hostnameVerifier Property
* Configuring IDCS Security Provider
* Configuring WebCenter Content for User Logout

#### Updating SSL.hostnameVerifier Property

To update SSL.hostnameVerifier property, do the following:
This is necessary for the IDCS provider to access IDCS.

1. Stop all the servers in the domain including Administration server and all Managed WebLogic servers.

1. Update the SSL.hostnameVerifier property:

   edit the file <DOMAIN_HOME>/<domain name>/bin/setDomainEnv.sh:
   go to pv location file system and modify the file setDomainEnv.sh 
   sample: /WCCFS/wccinfra/bin/setDomainEnv.sh

   OR 

   Alternatively create or modify the file 
   `<DOMAIN_HOME>/<domain_name>/bin/setUserOverrides.sh`. Add the `SSL.hostnameVerifier` property for the IDCS Authenticator:
   sample: /WCCFS/wccinfra/bin/setUserOverrides.sh

   ```bash
    EXTRA_JAVA_PROPERTIES="${EXTRA_JAVA_PROPERTIES} -Dweblogic.security.SSL.hostnameVerifier=weblogic.security.utils.SSLWLSWildcardHostnameVerifier"
 
    export EXTRA_JAVA_PROPERTIES
   ```
1. Start the Administration server  and all Managed WebLogic servers.

#### Configuring IDCS Security Provider

1. Log in to the IDCS administration console.

1. Create a trusted application. In the Add Confidential Application wizard:
   1. Enter the client name and the description (optional).
   1. Select the Configure this application as a client now option. To configure this application, expand the Client Configuration in the Configuration tab.
   1. In the Allowed Grant Types , select Client Credentials field the check box.
   1. In the Grant the client access to Identity Cloud Service Admin APIs section, click Add to add the APP Roles (application roles). You can add the Identity Domain Administrator role.
   1. Keep the default settings for the pages and click Finish.
   1. Record/Copy the Client ID and Client Secret.This is needed when you will create the IDCS provider.
   1. Activate the application.

#### Configuring Oracle Identity Cloud Integrator Provider

To configure Identity Cloud Integrator Provider:

1. Log in to the WebLogic Server Administration console.
1. Select `Security Realm` in the Domain Structure pane.
1. On the Summary of `Security Realms` page, select the name of the realm (for example, myrealm). Click `myrealm`. The `Settings for myrealm` page appears.
1. On the Settings for Realm Name page, select `Providers` and then `Authentication`. To create a new Authentication Provider, in the Authentication Providers table, click New.
1. In the `Create a New Authentication Provider` page, enter the name of the authentication provider, for example, IDCSIntegrator and select the `OracleIdentityCloudIntegrator` type of authentication provider from the drop-down list and click OK.
1. In the Authentication Providers table, click the newly created Oracle Identity Cloud Integrator, `IDCSIntegrator` link.
1. In the `Settings for IDCSIntegrator` page, for the Control Flag field, select the `Sufficient` option from the drop-down list Click `Save`.
1. Go to the Provider Specific page to configure the additional attributes for the security provider. Enter the values for the following fields & Click `Save`: 
   * Host
   * Port 443(default)
   * select SSLEnabled
   * Tenant
   * Client Id
   * Client Secret.   
   > NOTE: If IDCS URL is idcs-abcde.identity.example.com, then IDCS host would be identity.example.com and tenant name would be idcs-abcde. Keep the default settings for other sections of the page.
   
1. Select `Security Realm`, then `myrealm`, and then `Providers`. In the Authentication Providers table, click `Reorder`.
1. In the `Reorder Authentication Providers` page, move `IDCSIntegrator` on the top and click OK.
1. In the Authentication Providers table, click the `DefaultAuthenticator` link. In the `Settings for DefaultAuthenticator` page, for the Control Flag field, select the `Sufficient` option from the drop-down list. Click `Save`.
1. All changes will be activated. Restart the Administration server.

#### Setting Up Trust between IDCS and WebLogic

To set up trust between IDCS and WebLogic
1. Import certificate in KSS store.
   * Run this from the Administration Server node.
   * Get IDCS certificate:
     ```bash
     echo -n | openssl s_client -showcerts -servername <IDCS_URL> -connect <IDCS_URL>:443|sed -ne '/-BEGIN CERTIFICATE-/,/-END
     CERTIFICATE-/p' > /tmp/idcs_cert_chain.crt     

     #sample
     echo -n | openssl s_client -showcerts -servername xyz.identity.oraclecloud.com -connect idcs-xyz.identity.oraclecloud.com:443|sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /tmp/idcs_cert_chain.crt

     #copy the certificate inside the admin_pod
     kubectl cp /tmp/idcs_cert_chain.crt wccns/xyz-adminserver:/u01/idcs_cert_chain.crt
     ```
   * Import certificate. Run <ORACLE_HOME>/oracle_common/common/bin/wlst.sh file.
     ```bash
	 connect('weblogic','Welcome_1','t3://<WEBLOGIC_HOST>:7001')
     svc=getOpssService(name='KeyStoreService')        svc.importKeyStoreCertificate(appStripe='system',name='trust',password='',alias='idcs_cert_chain',type='TrustedCertificate',filepath='/tmp/idcs_cert_chain.crt',keypassword='')
     syncKeyStores(appStripe='system',keystoreFormat='KSS')

     #sample
     $./wlst.sh
     wls:/offline> connect('weblogic','welcome','t3://xyz-adminserver:7001')

     wls:/wccinfra/serverConfig/> svc=getOpssService(name='KeyStoreService')

     wls:/wccinfra/serverConfig/>svc.importKeyStoreCertificate(appStripe='system',name='trust',password='',alias='idcs_cert_chain',type='TrustedCertificate',filepath='/u01/idcs_cert_chain.crt',keypassword='')

     wls:/wccinfra/domainRuntime/>syncKeyStores(appStripe='system',keystoreFormat='KSS')
	 ```
   * exit()
1. Restart the Administration server and Managed servers

#### Creating Admin User in IDCS Administration Console for WebCenter Content

It is important to create the Admin user in IDCS because once the Managed servers are configured for SAML, the domain admin user (typically weblogic user) will not be able to log into the Managed servers.

To create WebLogic Admin user in IDCS for WebCenter Content JaxWS connection:

1. Go to the Groups tab and create Administrators and sysmanager roles in IDCS.
1. Go to the Users tab and create a wls admin user, for example, weblogic and assign it to Administrators and sysmanager groups.
1. Restart all the Managed servers.

#### Managing Group Memberships, Roles, and Accounts

This will require modifying OPSS and libOVD to access IDCS. The following steps are required if using IDCS for user authorization. Do not run these steps if you are using IDCS only for user authentication.
Ensure that all the servers are stopped (including Administration) before proceeding with the following steps:
> NOTE: Shutdown all the servers using WebLogic Server Administration Console. 
**Please keep in mind - `kubectl patch domain` command is the recommended way for starting/stopping pods. Please refrain from using WebLogic Server Administration Console for the same, anywhere else.**


1. Run the following script:
   ```bash
   #exec the Administration server
   kubectl exec -n wccns -it wccinfra-adminserver -- /bin/bash
 
   #Run the wlst.sh
   cd /u01/oracle/oracle_common/common/bin/
   ./wlst.sh
   ```
   > NOTE: It's not required to connect to WebLogic Administration Server.
1. Read the domain:
   ```bash
   readDomain(<DOMAIN_HOME>)
   
   #sample
   wls:/offline> readDomain('/u01/oracle/user_projects/domains/wccinfra')
   ```
   
1. Add the template:
   ```bash
   addTemplate(<MIDDLEWARE_HOME>/oracle_common/common/templates/wls/oracle.opss_scim_template.jar")
 
   #sample
   wls:/offline/wccinfra>addTemplate('/u01/oracle/oracle_common/common/templates/wls/oracle.opss_scim_template.jar')
   ```
   > NOTE: This step may throw a warning, which can be ignored. The addTemplate is deprecated. Use selectTemplate followed by loadTemplates in place of addTemplate.
1. Update the domain:
   ```bash
   updateDomain()
 
   #sample
   wls:/offline/wccinfra> updateDomain()
   ```
1. Close the domain:
   ```bash
   closeDomain()
 
   #sample
   wls:/offline/wccinfra> closeDomain()
   ```
1. Exit from the Administration server container:
   ```bash
   exit
   ```    
1. Start the servers (Administration and Managed).

#### Configuring WebCenter Content for User Logout
If the Logout link is selected, you will be re-authenticated by SAML. To be able to select the Logout link:

1. Log in to WebCenter Content Server  as an administrator. Select Administration, then Admin Server, and then General Configuration.
1. In the Additional Configuration Variables pane, add the following parameter:
   ```bash
   EXTRA_JAVA_PROPERTIES="${EXTRA_JAVA_PROPERTIES} -Dweblogic.security.SSL.hostnameVerifier=weblogic.security.utils.SSLWLSWildcardHostnameVerifier"
   ```
1. Click Save.
1. Restart the Administration and Managed servers.

   