---
title: "WLST administration operations"
weight: 2
pre : "<b>2. </b>"
description: "Describes the steps for WLST administration using helper pod running in the same Kubernetes Cluster as OIG Domain."
---

### Invoke WLST and access Administration Server

To use WLST to administer the OIG domain, use a helper pod in the same Kubernetes cluster as the OIG Domain.

1. Check to see if the helper pod exists by running:

   ```bash
   $ kubectl get pods -n <domain_namespace> | grep helper
   ```
   
   For example:
   
   ```bash
   $ kubectl get pods -n oigns | grep helper
   ```
   
   The output should look similar to the following:
   
   ```
   helper                                  1/1     Running     0          26h
   ```
   
   If the helper pod doesn't exist then see Step 1 in [Prepare your environment ](../../prepare-your-environment/#rcu-schema-creation) to create it.

1. Run the following command to start a bash shell in the helper pod:

   ```bash
   $ kubectl exec -it helper -n <domain_namespace> -- /bin/bash
   ```
	
   For example:
	
   ```bash
   $ kubectl exec -it helper -n oigns -- /bin/bash
   ```
	
   This will take you into a bash shell in the running helper pod:
	
   ```bash
   [oracle@helper ~]$
   ```
	
1. Connect to WLST using the following commands:

   ```bash
   [oracle@helper ~]$ cd $ORACLE_HOME/oracle_common/common/bin
   [oracle@helper ~]$ ./wlst.sh
   ```
   
   The output will look similar to the following:
   
   ```
   Initializing WebLogic Scripting Tool (WLST) ...

   Jython scans all the jar files it can find at first startup. Depending on the system, this process may take a few minutes to complete, and WLST may not return a prompt right away.

   Welcome to WebLogic Server Administration Scripting Shell

   Type help() for help on available commands

   wls:/offline>
   ```
 
1. To access t3 for the Administration Server connect as follows:

   ```bash
   wls:/offline> connect('weblogic','<password>','t3://governancedomain-adminserver:7001')
   ```
   
   The output will look similar to the following:
   
   ```
   Connecting to t3://governancedomain-adminserver:7001 with userid weblogic ...
   Successfully connected to Admin Server "AdminServer" that belongs to domain "governancedomain".

   Warning: An insecure protocol was used to connect to the server.
   To ensure on-the-wire security, the SSL port or Admin port should be used instead.

   wls:/governancedomain/serverConfig/>
   ```

   Or to access t3 for the OIG Cluster service, connect as follows:

   ```bash
   wls:/offline> connect('weblogic','<password>','t3://governancedomain-cluster-oim-cluster:14000')
   ```

   The output will look similar to the following:
   
   ```
   Connecting to t3://governancedomain-cluster-oim-cluster:14000 with userid weblogic ...
   Successfully connected to managed Server "oim_server1" that belongs to domain "governancedomain".

   Warning: An insecure protocol was used to connect to the server.
   To ensure on-the-wire security, the SSL port or Admin port should be used instead.

   wls:/governancedomain/serverConfig/>
   ```

### Sample operations

For a full list of WLST operations refer to [WebLogic Server WLST Online and Offline Command Reference](https://docs.oracle.com/pls/topic/lookup?ctx=en/middleware/fusion-middleware/weblogic-server/12.2.1.4/wlstc&id=GUID-B6001303-FF2D-4EE7-8BB6-354E6D7C1692).

#### Display servers

```
wls:/governancedomain/serverConfig/> cd('/Servers')
wls:/governancedomain/serverConfig/Servers> ls ()
dr--   AdminServer
dr--   oim_server1
dr--   oim_server2
dr--   oim_server3
dr--   oim_server4
dr--   oim_server5
dr--   soa_server1
dr--   soa_server2
dr--   soa_server3
dr--   soa_server4
dr--   soa_server5

wls:/governancedomain/serverConfig/Servers>
```

### Performing WLST administration via SSL

1. By default the SSL port is not enabled for the Administration Server or OIG Managed Servers. To configure the SSL port for the Administration Server and Managed Servers login to WebLogic Administration console `https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/console` and navigate to **Lock & Edit** -> **Environment** ->**Servers** -> **server_name** ->**Configuration** -> **General** -> **SSL Listen Port Enabled** -> **Provide SSL Port** ( For Administration Server: 7002 and for OIG Managed Server (oim_server1): 14101) - > **Save** -> **Activate Changes**.

   **Note**: If configuring the OIG Managed Servers for SSL you must enable SSL on the same port for all servers (oim_server1 through oim_server4)


1. Create a `myscripts` directory as follows:
   
   ```bash
   $ cd $WORKDIR/kubernetes
   $ mkdir myscripts
   $ cd myscripts
   ```
   
1. Create a sample yaml template file in the `myscripts` directory called `<domain_uid>-adminserver-ssl.yaml` to create a Kubernetes service for the Administration Server:

   **Note**: Update the `domainName`, `domainUID` and `namespace` based on your environment.

   ```
   apiVersion: v1
   kind: Service
   metadata:
     labels:
       serviceType: SERVER
       weblogic.domainName: governancedomain
       weblogic.domainUID: governancedomain
       weblogic.resourceVersion: domain-v2
       weblogic.serverName: AdminServer
     name: governancedomain-adminserver-ssl
     namespace: oigns
   spec:
     clusterIP: None
     ports:
     - name: default
       port: 7002
       protocol: TCP
       targetPort: 7002
     selector:
       weblogic.createdByOperator: "true"
       weblogic.domainUID: governancedomain
       weblogic.serverName: AdminServer
     type: ClusterIP
   ```
  
   and create the following sample yaml template file `<domain_uid>-oim-cluster-ssl.yaml` for the OIG Managed Server:
   
   ```
   apiVersion: v1
   kind: Service
   metadata:
     labels:
       serviceType: SERVER
       weblogic.domainName: governancedomain
       weblogic.domainUID: governancedomain
       weblogic.resourceVersion: domain-v2
     name: governancedomain-cluster-oim-cluster-ssl
     namespace: oigns
   spec:
     clusterIP: None
     ports:
     - name: default
       port: 14101
       protocol: TCP
       targetPort: 14101
     selector:
       weblogic.clusterName: oim_cluster
	   weblogic.createdByOperator: "true"
       weblogic.domainUID: governancedomain
     type: ClusterIP
   ```  


1. Apply the template using the following command for the Administration Server:

   ```bash
   $ kubectl apply -f governancedomain-adminserver-ssl.yaml
   service/governancedomain-adminserver-ssl created
   ```
   
   or using the following command for the OIG Managed Server:
   
   ```bash
   $ kubectl apply -f governancedomain-oim-cluster-ssl.yaml
   service/governancedomain-cluster-oim-cluster-ssl created
   ```
   
1. Validate that the Kubernetes Services to access SSL ports are created successfully:

   ```bash
   $ kubectl get svc -n <domain_namespace> |grep ssl
   ```
   
   For example:
   
   ```bash
   $ kubectl get svc -n oigns |grep ssl
   ```
   
   The output will look similar to the following:
   
   ```
   governancedomain-adminserver-ssl           ClusterIP   None             <none>        7002/TCP                     74s
   governancedomain-cluster-oim-cluster-ssl   ClusterIP   None             <none>        14101/TCP                    21s
   ```

1. Connect to a bash shell of the helper pod:

   ```bash
   $ kubectl exec -it helper -n oigns -- /bin/bash
   ```

1. In the bash shell run the following:

   ```bash
   [oracle@governancedomain-adminserver oracle]$ export WLST_PROPERTIES="-Dweblogic.security.SSL.ignoreHostnameVerification=true -Dweblogic.security.TrustKeyStore=DemoTrust"
   [oracle@governancedomain-adminserver oracle]$ cd /u01/oracle/oracle_common/common/bin
   [oracle@governancedomain-adminserver oracle]$ ./wlst.sh
   Initializing WebLogic Scripting Tool (WLST) ...
   
   Welcome to WebLogic Server Administration Scripting Shell
   
   Type help() for help on available commands
   wls:/offline>
   ```

   Connect to the Administration Server t3s service:

   ```bash
   wls:/offline> connect('weblogic','<password>','t3s://governancedomain-adminserver-ssl:7002')
   Connecting to t3s://governancedomain-adminserver-ssl:7002 with userid weblogic ...
   <DATE> <Info> <Security> <BEA-090905> <Disabling the CryptoJ JCE Provider self-integrity check for better startup performance. To enable this check, specify -Dweblogic.security.allowCryptoJDefaultJCEVerification=true.>
   <DATE> <Info> <Security> <BEA-090906> <Changing the default Random Number Generator in RSA CryptoJ from ECDRBG128 to HMACDRBG. To disable this change, specify -Dweblogic.security.allowCryptoJDefaultPRNG=true.>
   <DATE> <Info> <Security> <BEA-090909> <Using the configured custom SSL Hostname Verifier implementation: weblogic.security.utils.SSLWLSHostnameVerifier$NullHostnameVerifier.>
   Successfully connected to Admin Server "AdminServer" that belongs to domain "governancedomain".

   wls:/governancedomain/serverConfig/>
   ```

   To connect to the OIG Managed Server t3s service:
   
   ```bash
   wls:/offline> connect('weblogic','<password>','t3s://governancedomain-cluster-oim-cluster-ssl:14101')
   Connecting to t3s://governancedomain-cluster-oim-cluster-ssl:14101 with userid weblogic ...
   <DATE> <Info> <Security> <BEA-090905> <Disabling the CryptoJ JCE Provider self-integrity check for better startup performance. To enable this check, specify -Dweblogic.security.allowCryptoJDefaultJCEVerification=true.>
   <DATE> <Info> <Security> <BEA-090906> <Changing the default Random Number Generator in RSA CryptoJ from ECDRBG128 to HMACDRBG. To disable this change, specify -Dweblogic.security.allowCryptoJDefaultPRNG=true.>
   <DATE> <Info> <Security> <BEA-090909> <Using the configured custom SSL Hostname Verifier implementation: weblogic.security.utils.SSLWLSHostnameVerifier$NullHostnameVerifier.>
   Successfully connected to managed Server "oim_server1" that belongs to domain "governancedomain".

   wls:/governancedomain/serverConfig/>
   ```