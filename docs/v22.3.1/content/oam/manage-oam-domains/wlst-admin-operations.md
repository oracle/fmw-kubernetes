---
title: "b. WLST Administration Operations"
description: "Describes the steps for WLST administration using helper pod running in the same Kubernetes Cluster as OAM Domain."
---

To use WLST to administer the OAM domain, use the helper pod in the same Kubernetes cluster as the OAM Domain.

1. Check to see if the helper pod exists by running:

   ```bash
   $ kubectl get pods -n <domain_namespace> | grep helper
   ```
   
   For example:
   
   ```bash
   $ kubectl get pods -n oamns | grep helper
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
   $ kubectl exec -it helper -n oamns -- /bin/bash
   ```
	
   This will take you into a bash shell in the running helper pod:
	
   ```bash
   [oracle@helper ~]$
   ```
	
1. Connect to WLST using the following command:

   ```bash
   $ cd $ORACLE_HOME/oracle_common/common/bin
   $ ./wlst.sh
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
   wls:/offline> connect('weblogic','<password>','t3://accessdomain-adminserver:7001')
   ```
   
   The output will look similar to the following:
   
   ```
   Connecting to t3://accessdomain-adminserver:7001 with userid weblogic ...
   Successfully connected to Admin Server "AdminServer" that belongs to domain "accessdomain".

   Warning: An insecure protocol was used to connect to the server.
   To ensure on-the-wire security, the SSL port or Admin port should be used instead.

   wls:/accessdomain/serverConfig/>
   ```

   Or to access t3 for the OAM Cluster service, connect as follows:
   
   ```bash
   connect('weblogic','<password>','t3://accessdomain-cluster-oam-cluster:14100')
   ```
   
   The output will look similar to the following:
   
   ```
   Connecting to t3://accessdomain-cluster-oam-cluster:14100 with userid weblogic ...
   Successfully connected to managed Server "oam_server1" that belongs to domain "accessdomain".

   Warning: An insecure protocol was used to connect to the server.
   To ensure on-the-wire security, the SSL port or Admin port should be used instead.

   wls:/accessdomain/serverConfig/>
   ```
### Sample operations

For a full list of WLST operations refer to [WebLogic Server WLST Online and Offline Command Reference](https://docs.oracle.com/pls/topic/lookup?ctx=en/middleware/fusion-middleware/weblogic-server/12.2.1.4/wlstc&id=GUID-B6001303-FF2D-4EE7-8BB6-354E6D7C1692).

#### Display servers

```bash
wls:/accessdomain/serverConfig/> cd('/Servers')
wls:/accessdomain/serverConfig/Servers> ls()
   
dr--   AdminServer
dr--   oam_policy_mgr1
dr--   oam_policy_mgr2
dr--   oam_policy_mgr3
dr--   oam_policy_mgr4
dr--   oam_policy_mgr5
dr--   oam_server1
dr--   oam_server2
dr--   oam_server3
dr--   oam_server4
dr--   oam_server5

wls:/accessdomain/serverConfig/Servers>
```
   
#### Configure logging for managed servers   

Connect to the Administration Server and run the following:

```bash
wls:/accessdomain/serverConfig/> domainRuntime()
Location changed to domainRuntime tree. This is a read-only tree
with DomainMBean as the root MBean.
For more help, use help('domainRuntime')
   
wls:/accessdomain/domainRuntime/>
   
wls:/accessdomain/domainRuntime/> listLoggers(pattern="oracle.oam.*",target="oam_server1")
------------------------------------------+-----------------
Logger                                    | Level
------------------------------------------+-----------------
oracle.oam                                | <Inherited>
oracle.oam.admin.foundation.configuration | <Inherited>
oracle.oam.admin.service.config           | <Inherited>
oracle.oam.agent                          | <Inherited>
oracle.oam.agent-default                  | <Inherited>
oracle.oam.audit                          | <Inherited>
oracle.oam.binding                        | <Inherited>
oracle.oam.certvalidation                 | <Inherited>
oracle.oam.certvalidation.mbeans          | <Inherited>
oracle.oam.common.healthcheck             | <Inherited>
oracle.oam.common.runtimeent              | <Inherited>
oracle.oam.commonutil                     | <Inherited>
oracle.oam.config                         | <Inherited>
oracle.oam.controller                     | <Inherited>
oracle.oam.default                        | <Inherited>
oracle.oam.diagnostic                     | <Inherited>
oracle.oam.engine.authn                   | <Inherited>
oracle.oam.engine.authz                   | <Inherited>
oracle.oam.engine.policy                  | <Inherited>
oracle.oam.engine.ptmetadata              | <Inherited>
oracle.oam.engine.session                 | <Inherited>
oracle.oam.engine.sso                     | <Inherited>
oracle.oam.esso                           | <Inherited>
oracle.oam.extensibility.lifecycle        | <Inherited>
oracle.oam.foundation.access              | <Inherited>
oracle.oam.idm                            | <Inherited>
oracle.oam.install                        | <Inherited>
oracle.oam.install.bootstrap              | <Inherited>
oracle.oam.install.mbeans                 | <Inherited>
oracle.oam.ipf.rest.api                   | <Inherited>
oracle.oam.oauth                          | <Inherited>
oracle.oam.plugin                         | <Inherited>
oracle.oam.proxy.oam                      | <Inherited>
oracle.oam.proxy.oam.workmanager          | <Inherited>
oracle.oam.proxy.opensso                  | <Inherited>
oracle.oam.pswd.service.provider          | <Inherited>
oracle.oam.replication                    | <Inherited>
oracle.oam.user.identity.provider         | <Inherited>
wls:/accessdomain/domainRuntime/>
```

Set the log level to `TRACE:32`:

```bash
wls:/accessdomain/domainRuntime/> setLogLevel(target='oam_server1',logger='oracle.oam',level='TRACE:32',persist="1",addLogger=1)
wls:/accessdomain/domainRuntime/>

wls:/accessdomain/domainRuntime/> listLoggers(pattern="oracle.oam.*",target="oam_server1")
------------------------------------------+-----------------
Logger                                    | Level
------------------------------------------+-----------------
oracle.oam                                | TRACE:32
oracle.oam.admin.foundation.configuration | <Inherited>
oracle.oam.admin.service.config           | <Inherited>
oracle.oam.agent                          | <Inherited>
oracle.oam.agent-default                  | <Inherited>
oracle.oam.audit                          | <Inherited>
oracle.oam.binding                        | <Inherited>
oracle.oam.certvalidation                 | <Inherited>
oracle.oam.certvalidation.mbeans          | <Inherited>
oracle.oam.common.healthcheck             | <Inherited>
oracle.oam.common.runtimeent              | <Inherited>
oracle.oam.commonutil                     | <Inherited>
oracle.oam.config                         | <Inherited>
oracle.oam.controller                     | <Inherited>
oracle.oam.default                        | <Inherited>
oracle.oam.diagnostic                     | <Inherited>
oracle.oam.engine.authn                   | <Inherited>
oracle.oam.engine.authz                   | <Inherited>
oracle.oam.engine.policy                  | <Inherited>
oracle.oam.engine.ptmetadata              | <Inherited>
oracle.oam.engine.session                 | <Inherited>
oracle.oam.engine.sso                     | <Inherited>
oracle.oam.esso                           | <Inherited>
oracle.oam.extensibility.lifecycle        | <Inherited>
oracle.oam.foundation.access              | <Inherited>
oracle.oam.idm                            | <Inherited>
oracle.oam.install                        | <Inherited>
oracle.oam.install.bootstrap              | <Inherited>
oracle.oam.install.mbeans                 | <Inherited>
oracle.oam.ipf.rest.api                   | <Inherited>
oracle.oam.oauth                          | <Inherited>
oracle.oam.plugin                         | <Inherited>
oracle.oam.proxy.oam                      | <Inherited>
oracle.oam.proxy.oam.workmanager          | <Inherited>
oracle.oam.proxy.opensso                  | <Inherited>
oracle.oam.pswd.service.provider          | <Inherited>
oracle.oam.replication                    | <Inherited>
oracle.oam.user.identity.provider         | <Inherited>
wls:/accessdomain/domainRuntime/>
```

Verify that `TRACE:32` log level is set by connecting to the Administration Server and viewing the logs:

```bash
$ kubectl exec -it accessdomain-adminserver -n oamns -- /bin/bash
[oracle@accessdomain-adminserver oracle]$
[oracle@accessdomain-adminserver oracle]$ cd /u01/oracle/user_projects/domains/accessdomain/servers/oam_server1/logs
[oracle@accessdomain-adminserver logs]$ tail oam_server1-diagnostic.log
2022-07-12T10:26:14.793+00:00] [oam_server1] [TRACE:32] [] [oracle.oam.config] [tid: Configuration Store Observer] [userId: <anonymous>] [ecid: 8b3ac37b-c7cf-46dd-aeee-5ed67886be21-0000000b,0:1795] [APP: oam_server] [partition-name: DOMAIN] [tenant-name: GLOBAL] [SRC_CLASS: oracle.security.am.admin.config.util.observable.ObservableConfigStore$StoreWatcher] [SRC_METHOD: run] Start of run before start of detection at 1,635,848,774,793. Detector: oracle.security.am.admin.config.util.observable.DbStoreChangeDetector:Database configuration store:DSN:jdbc/oamds. Monitor: { StoreMonitor: { disabled: 'false' } }
[2022-07-12T10:26:14.793+00:00] [oam_server1] [TRACE] [] [oracle.oam.config] [tid: Configuration Store Observer] [userId: <anonymous>] [ecid: 8b3ac37b-c7cf-46dd-aeee-5ed67886be21-0000000b,0:1795] [APP: oam_server] [partition-name: DOMAIN] [tenant-name: GLOBAL] [SRC_CLASS: oracle.security.am.admin.config.util.store.StoreUtil] [SRC_METHOD: getContainerProperty] Configuration property CONFIG_HISTORY not specified
[2022-07-12T10:26:14.793+00:00] [oam_server1] [TRACE] [] [oracle.oam.config] [tid: Configuration Store Observer] [userId: <anonymous>] [ecid: 8b3ac37b-c7cf-46dd-aeee-5ed67886be21-0000000b,0:1795] [APP: oam_server] [partition-name: DOMAIN] [tenant-name: GLOBAL] [SRC_CLASS: oracle.security.am.admin.config.util.store.StoreUtil] [SRC_METHOD: getContainerProperty] Configuration property CONFIG not specified
[2022-07-12T10:26:14.795+00:00] [oam_server1] [TRACE:32] [] [oracle.oam.config] [tid: Configuration Store Observer] [userId: <anonymous>] [ecid: 8b3ac37b-c7cf-46dd-aeee-5ed67886be21-0000000b,0:1795] [APP: oam_server] [partition-name: DOMAIN] [tenant-name: GLOBAL] [SRC_CLASS: oracle.security.am.admin.config.util.store.DbStore] [SRC_METHOD: getSelectSQL] SELECT SQL:SELECT  version  from  IDM_OBJECT_STORE  where id = ? and version = (select max(version) from  IDM_OBJECT_STORE  where id = ?)
[2022-07-12T10:26:14.797+00:00] [oam_server1] [TRACE] [] [oracle.oam.config] [tid: Configuration Store Observer] [userId: <anonymous>] [ecid: 8b3ac37b-c7cf-46dd-aeee-5ed67886be21-0000000b,0:1795] [APP: oam_server] [partition-name: DOMAIN] [tenant-name: GLOBAL] [SRC_CLASS: oracle.security.am.admin.config.util.store.DbStore] [SRC_METHOD: load] Time (ms) to load key CONFIG:-1{FIELD_TYPES=INT, SELECT_FIELDS=SELECT  version  from  IDM_OBJECT_STORE }:4
```

### Performing WLST Administration via SSL

1. By default the SSL port is not enabled for the Administration Server or OAM Managed Servers. To configure the SSL port for the Administration Server and Managed Servers login to WebLogic Administration console `https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/console` and navigate to **Lock & Edit** -> **Environment** ->**Servers** -> **server_name** ->**Configuration** -> **General** -> **SSL Listen Port Enabled** -> **Provide SSL Port** ( For Administration Server: 7002 and for OAM Managed Server (oam_server1): 14101) - > **Save** -> **Activate Changes**.

   **Note**: If configuring the OAM Managed Servers for SSL you must enable SSL on the same port for all servers (oam_server1 through oam_server5)

1. Create a `myscripts` directory as follows:

   ```bash
   $ cd $WORKDIR/kubernetes/
   $ mkdir myscripts
   $ cd myscripts
   ```
   
   For example:
   
   ```bash
   $ cd $WORKDIR/kubernetes/
   $ mkdir myscripts
   $ cd myscripts
   ```

1. Create a sample yaml template file in the `myscripts` directory called `<domain_uid>-adminserver-ssl.yaml` to create a Kubernetes service for the Administration Server:

   **Note**: Update the `domainName`, `domainUID` and `namespace` based on your environment. For example:

   ```
   apiVersion: v1
   kind: Service
   metadata:
     labels:
       serviceType: SERVER
       weblogic.domainName: accessdomain
       weblogic.domainUID: accessdomain
       weblogic.resourceVersion: domain-v2
       weblogic.serverName: AdminServer
     name: accessdomain-adminserverssl
     namespace: oamns
   spec:
     clusterIP: None
     ports:
     - name: default
       port: 7002
       protocol: TCP
       targetPort: 7002
     selector:
       weblogic.createdByOperator: "true"
       weblogic.domainUID: accessdomain
       weblogic.serverName: AdminServer
     type: ClusterIP
   ```
   
   and the following sample yaml template file `<domain_uid>-oamcluster-ssl.yaml` for the OAM Managed Server:
   
   ```
   apiVersion: v1
   kind: Service
   metadata:
     labels:
	   serviceType: SERVER
       weblogic.domainName: accessdomain
       weblogic.domainUID: accessdomain
       weblogic.resourceVersion: domain-v2
     name: accessdomain-oamcluster-ssl
     namespace: oamns
   spec:
     clusterIP: None
     ports:
     - name: default
       port: 14101
       protocol: TCP
       targetPort: 14101
     selector:
       weblogic.clusterName: oam_cluster
       weblogic.createdByOperator: "true"
       weblogic.domainUID: accessdomain
     type: ClusterIP
   ```  
   
1. Apply the template using the following command for the AdminServer:

   ```bash
   $ kubectl apply -f <domain_uid>-adminserver-ssl.yaml
   ```
   For example:
   
   ```bash
   $ kubectl apply -f accessdomain-adminserver-ssl.yaml
   service/accessdomain-adminserverssl created
   ```
   
   and using the following command for the OAM Managed Server:
   
   ```bash
   $ kubectl apply -f <domain_uid>-oamcluster-ssl.yaml
   ```
   
   For example:
   
   ```bash
   $ kubectl apply -f accessdomain-oamcluster-ssl.yaml
   service/accessdomain-oamcluster-ssl created
   ```
   
   
1. Validate that the Kubernetes Services to access SSL ports are created successfully:
   
   ```bash
   $ kubectl get svc -n <domain_namespace> |grep ssl
   ```
   
   For example:
   
   ```bash
   $ kubectl get svc -n oamns |grep ssl
   ```
   
   The output will look similar to the following:
   
   ```
   accessdomain-adminserverssl           ClusterIP   None             <none>        7002/TCP                     102s
   accessdomain-oamcluster-ssl           ClusterIP   None             <none>        14101/TCP                    35s
   ```
   
1. Inside the bash shell of the running helper pod, run the following:

   ```bash
   [oracle@helper bin]$ export WLST_PROPERTIES="-Dweblogic.security.SSL.ignoreHostnameVerification=true -Dweblogic.security.TrustKeyStore=DemoTrust"
   [oracle@helper bin]$ cd /u01/oracle/oracle_common/common/bin
   [oracle@helper bin]$ ./wlst.sh
   Initializing WebLogic Scripting Tool (WLST) ...

   Welcome to WebLogic Server Administration Scripting Shell
   
   Type help() for help on available commands
   wls:/offline>
   ```
   
   To connect to the Administration Server t3s service:

   ```bash
   wls:/offline> connect('weblogic','<password>','t3s://accessdomain-adminserverssl:7002')
   Connecting to t3s://accessdomain-adminserverssl:7002 with userid weblogic ...
   <Jul 12, 2022 10:42:05 AM GMT> <Info> <Security> <BEA-090905> <Disabling the CryptoJ JCE Provider self-integrity check for better startup performance. To enable this check, specify -Dweblogic.security.allowCryptoJDefaultJCEVerification=true.>
   <Jul 12, 2022 10:42:05 AM GMT> <Info> <Security> <BEA-090906> <Changing the default Random Number Generator in RSA CryptoJ from ECDRBG128 to HMACDRBG. To disable this change, specify -Dweblogic.security.allowCryptoJDefaultPRNG=true.>
   <Jul 12, 2022 10:42:05 AM GMT> <Info> <Security> <BEA-090909> <Using the configured custom SSL Hostname Verifier implementation: weblogic.security.utils.SSLWLSHostnameVerifier$NullHostnameVerifier.>
   Successfully connected to Admin Server "AdminServer" that belongs to domain "accessdomain".

   wls:/accessdomain/serverConfig/>
   ```
   
   To connect to the OAM Managed Server t3s service:
   
   ```bash
   wls:/offline> connect('weblogic','<password>','t3s://accessdomain-oamcluster-ssl:14101')   
   Connecting to t3s://accessdomain-oamcluster-ssl:14101 with userid weblogic ...
   <Jul 12, 2022 10:43:16 AM GMT> <Info> <Security> <BEA-090905> <Disabling the CryptoJ JCE Provider self-integrity check for better startup performance. To enable this check, specify -Dweblogic.security.allowCryptoJDefaultJCEVerification=true.>
   <Jul 12, 2022 10:43:16 AM GMT> <Info> <Security> <BEA-090906> <Changing the default Random Number Generator in RSA CryptoJ from ECDRBG128 to HMACDRBG. To disable this change, specify -Dweblogic.security.allowCryptoJDefaultPRNG=true.>
   <Jul 12, 2022 10:43:16 AM GMT> <Info> <Security> <BEA-090909> <Using the configured custom SSL Hostname Verifier implementation: weblogic.security.utils.SSLWLSHostnameVerifier$NullHostnameVerifier.>
   Successfully connected to managed Server "oam_server1" that belongs to domain "accessdomain".
   ```
   
