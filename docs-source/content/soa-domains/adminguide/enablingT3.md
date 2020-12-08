---
title: "Expose the T3/T3S protocol"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 4
pre : "<b> </b>"
description: "Create a T3/T3S channel and the corresponding Kubernetes service to expose the T3/T3S protocol for the Administration Server and Managed Servers in an Oracle SOA Suite domain."
---

{{% notice warning %}}
Oracle strongly recommends that you do not expose non-HTTPS traffic (T3/T3s/LDAP/IIOP/IIOPs) outside of the external firewall. You can control this access using a combination of network channels and firewalls.
{{% /notice %}}

You can create T3/T3S channels and the corresponding Kubernetes service to expose the T3/T3S protocol for the Administration Server and Managed Servers in an Oracle SOA Suite domain.

The WebLogic Kubernetes operator provides an option to expose a T3 channel for the Administration Server using the `exposeAdminT3Channel` setting during domain creation, then the matching T3 service can be used to connect. By default, when `exposeAdminT3Channel` is set, the WebLogic Kubernetes operator environment exposes the  `NodePort` for the T3 channel of the `NetworkAccessPoint` at `30012` (use `t3ChannelPort` to configure the port to a different value).

If you miss enabling `exposeAdminT3Channel` during domain creation, follow these steps to create a T3 channel for Administration Server manually.

![Exposing SOA Managed Server T3 Ports](/fmw-kubernetes/images/soa-domains/ExposeSOAMST3.png)


### Expose a T3/T3S Channel for the Administration Server
To create a custom T3/T3S channel for the Administration Server that has a listen port **listen_port** and a paired public port **public_port**:

1. Create `t3_admin_config.py` with the following content:
   ``` Python
   admin_pod_name = sys.argv[1]
   admin_port = sys.argv[2]
   user_name = sys.argv[3]
   password = sys.argv[4]
   listen_port = sys.argv[5]
   public_port = sys.argv[6]
   public_address = sys.argv[7]
   AdminServerName = sys.argv[8]
   channelType = sys.argv[9]
   print('custom admin_pod_name : [%s]' % admin_pod_name);
   print('custom admin_port : [%s]' % admin_port);
   print('custom user_name : [%s]' % user_name);
   print('custom password : ********');
   print('public address : [%s]' % public_address);
   print('channel listen port : [%s]' % listen_port);
   print('channel public listen port : [%s]' % public_port);
   connect(user_name, password, 't3://' + admin_pod_name + ':' + admin_port)
   edit()
   startEdit()
   cd('/')
   cd('Servers/%s/' % AdminServerName )
   if channelType == 't3':
      create('T3Channel_AS','NetworkAccessPoint')
      cd('NetworkAccessPoints/T3Channel_AS')
      set('Protocol','t3')
      set('ListenPort',int(listen_port))
      set('PublicPort',int(public_port))
      set('PublicAddress', public_address)
      print('Channel T3Channel_AS added')
   elif channelType == 't3s':	  
      create('T3SChannel_AS','NetworkAccessPoint')
      cd('NetworkAccessPoints/T3SChannel_AS')
      set('Protocol','t3s')
      set('ListenPort',int(listen_port))
      set('PublicPort',int(public_port))
      set('PublicAddress', public_address)
      set('HttpEnabledForThisProtocol', true)
      set('OutboundEnabled', false)
      set('Enabled', true)
      set('TwoWaySSLEnabled', true)
      set('ClientCertificateEnforced', false)
   else:
      print('channelType [%s] not supported',channelType)  
   activate()
   disconnect()
   ```

1. Copy `t3_admin_config.py` into the domain home (for example, `/u01/oracle/user_projects/domains/soainfra`) of the Administration Server pod (for example, `soainfra-adminserver` in `soans` namespace).

        $ kubectl cp t3_admin_config.py soans/soainfra-adminserver:/u01/oracle/user_projects/domains/soainfra

1. Run `wlst.sh t3_admin_config.py` by using `exec` into the Administration Server pod with the following  parameters:

    * admin_pod_name: soainfra-adminserver *# Administration Server pod*
    * admin_port:  7001
    * user_name: weblogic
    * password: Welcome1 *# weblogic password*
    * listen_port: 30014 *# New port for T3 Administration Server*
    * public_port: 30014 *# Kubernetes NodePort which will be used to expose T3 port externally*
    * public_address: <Master IP Address>    
    * AdminServerName: AdminServer *# Give administration Server name*
    * channelType: t3  *# t3 or t3s protocol channel*

    ```
    $ kubectl exec -it <Administration Server pod> -n <namespace> -- /u01/oracle/oracle_common/common/bin/wlst.sh  <domain_home>/t3_admin_config.py <Administration Server pod>  <Administration Server port>  weblogic <password for weblogic> <t3 port on Administration Server> <t3 nodeport> <master_ip> <AdminServerName> <channelType t3 or t3s>
    ```
    For example:
    ```
    $ kubectl exec -it soainfra-adminserver -n soans -- /u01/oracle/oracle_common/common/bin/wlst.sh /u01/oracle/user_projects/domains/soainfra/t3_admin_config.py soainfra-adminserver  7001 weblogic Welcome1 30014 30014 xxx.xxx.xxx.xxx AdminServer t3
    ```

1. Create `t3_admin_svc.yaml` with the following contents to expose T3 at NodePort `30014` for `domainName` and `domainUID` as `soainfra` and domain deployed in `soans` namespace:
    > Note: For T3S, replace NodePort `30014` with the appropriate value used with `public_port` while creating the T3S channel using `wlst.sh` in the previous step.
    ```
    apiVersion: v1
    kind: Service
    metadata:
       name: soainfra-adminserver-t3-external
       namespace: soans
       labels:
         weblogic.serverName: AdminServer
         weblogic.domainName: soainfra
         weblogic.domainUID: soainfra
    spec:
      type: NodePort
      selector:
        weblogic.domainName: soainfra
        weblogic.domainUID: soainfra
        weblogic.serverName: AdminServer
      ports:
      - name: t3adminport
        protocol: TCP
        port: 30014
        targetPort: 30014
        nodePort: 30014
    ```

1. Create the NodePort Service for port `30014`:
   ```
   $ kubectl create -f t3_admin_svc.yaml
   ```

1. Verify that you can access T3 for the Administration Server with the following URL:
   ```
   t3://<master_ip>:30014
   ```

1. Similarly, you can access T3S as follows:

   a. First get the certificates from the Administration Server to be used for secured (T3S) connection from the client. You can export the certificate from the Administration Server with WLST commands. For example, to export the default `demoidentity`:
      > Note: If you are using the custom SSL certificate, replace the steps accordingly.
      ```
      $ kubectl exec -it soainfra-adminserver -n soans -- bash
      $ /u01/oracle/oracle_common/common/bin/wlst.sh
      $ connect('weblogic','Welcome1','t3://soainfra-adminserver:7001')
      $ svc = getOpssService(name='KeyStoreService')
      $ svc.exportKeyStoreCertificate(appStripe='system', name='demoidentity', password='DemoIdentityKeyStorePassPhrase', alias='DemoIdetityKeyStorePassPhrase', type='Certificate', filepath='/tmp/cert.txt/')
      ```
      These steps download the certificate at `/tmp/cert.txt`.

   b. Use the same certificates from the client side and connect using `t3s`. For example:
      ```
      $ export JAVA_HOME=/u01/jdk
      $ keytool -import -v -trustcacerts -alias soadomain -file cert.txt -keystore $JAVA_HOME/jre/lib/security/cacerts -keypass changeit -storepass changeit
      $ export WLST_PROPERTIES="-Dweblogic.security.SSL.ignoreHostnameVerification=true"
      $ cd $ORACLE_HOME/oracle_common/common/bin
      $ ./wlst.sh
        Initializing WebLogic Scripting Tool (WLST) ...
        Welcome to WebLogic Server Administration Scripting Shell
        Type help() for help on available commands
      $ wls:/offline> connect('weblogic','Welcome1','t3s://<Master IP address>:30014')
      ```

### Expose T3/T3S for Managed Servers
To create a custom T3/T3S channel for all Managed Servers, with a listen port **listen_port** and a paired public port **public_port**:

1. Create `t3_ms_config.py` with the following content:

    ``` Python
    admin_pod_name = sys.argv[1]
    admin_port = sys.argv[2]
    user_name = sys.argv[3]
    password = sys.argv[4]
    listen_port = sys.argv[5]
    public_port = sys.argv[6]
    public_address = sys.argv[7]
    managedNameBase = sys.argv[8]
    ms_count = sys.argv[9]
    channelType = sys.argv[10]
    print('custom host : [%s]' % admin_pod_name);
    print('custom port : [%s]' % admin_port);
    print('custom user_name : [%s]' % user_name);
    print('custom password : ********');
    print('public address : [%s]' % public_address);
    print('channel listen port : [%s]' % listen_port);
    print('channel public listen port : [%s]' % public_port);

    connect(user_name, password, 't3://' + admin_pod_name + ':' + admin_port)

    edit()
    startEdit()
    for index in range(0, int(ms_count)):
      cd('/')
      msIndex = index+1
      cd('/')
      name = '%s%s' % (managedNameBase, msIndex)
      cd('Servers/%s/' % name )
      if channelType == 't3':
        create('T3Channel_MS','NetworkAccessPoint')
        cd('NetworkAccessPoints/T3Channel_MS')
        set('Protocol','t3')
        set('ListenPort',int(listen_port))
        set('PublicPort',int(public_port))
        set('PublicAddress', public_address)
        print('Channel T3Channel_MS added ...for ' + name)
      elif channelType == 't3s':	  
        create('T3SChannel_MS','NetworkAccessPoint')
        cd('NetworkAccessPoints/T3SChannel_MS')
        set('Protocol','t3s')
        set('ListenPort',int(listen_port))
        set('PublicPort',int(public_port))
        set('PublicAddress', public_address)
        set('HttpEnabledForThisProtocol', true)
        set('OutboundEnabled', false)
        set('Enabled', true)
        set('TwoWaySSLEnabled', true)
        set('ClientCertificateEnforced', false)
        print('Channel T3SChannel_MS added ...for ' + name)
      else:
        print('Protocol [%s] not supported' % channelType)  	
    activate()
    disconnect()
    ```

1. Copy `t3_ms_config.py` into the domain home (for example, `/u01/oracle/user_projects/domains/soainfra`) of the Administration Server pod (for example, `soainfra-adminserver` in `soans` namespace).
   ```
   $ kubectl cp t3_ms_config.py soans/soainfra-adminserver:/u01/oracle/user_projects/domains/soainfra
   ```
1. Run `wlst.sh t3_ms_config.py` by exec into the Administration Server pod with the following  parameters:

    * admin_pod_name: soainfra-adminserver *# Administration Server pod*
    * admin_port:  7001
    * user_name: weblogic
    * password: Welcome1 *# weblogic password*
    * listen_port: 30016 *# New port for T3 Managed Servers*
    * public_port: 30016 *# Kubernetes NodePort which will be used to expose T3 port externally*
    * public_address: <Master IP Address>    
    * managedNameBase: soa_server *# Give Managed Server base name. For osb_cluster this will be osb_server*
    * ms_count: 5 *# Number of configured Managed Servers*
    * channelType: t3 *# channelType is t3 or t3s*

    ```
    $ kubectl exec -it <Administration Server pod> -n <namespace> -- /u01/oracle/oracle_common/common/bin/wlst.sh  <domain_home>/t3_ms_config.py <Administration Server pod>  <Administration Server port>  weblogic <password for weblogic> <t3 port on Managed Server> <t3 nodeport> <master_ip> <managedNameBase> <ms_count> <channelType t3 or t3s>
    ```
    For example:
    ```
    $ kubectl exec -it soainfra-adminserver -n soans -- /u01/oracle/oracle_common/common/bin/wlst.sh /u01/oracle/user_projects/domains/soainfra/t3_ms_config.py soainfra-adminserver  7001 weblogic Welcome1 30016 30016 xxx.xxx.xxx.xxx soa_server 5 t3
    ```
1. Create `t3_ms_svc.yaml` with the following contents to expose T3 at Managed Server port `30016` for `domainName`, `domainUID` as `soainfra`, and `clusterName` as `soa_cluster` for SOA Cluster. Similarly, you can create Kubernetes Service with `clusterName` as `osb_cluster` for OSB Cluster:
    > Note: For T3S, replace NodePort `30016` with the appropriate value used with public_port while creating the T3S channel using `wlst.sh` in the previous step.

    ```
    apiVersion: v1
    kind: Service
    metadata:
       name: soainfra-soa-cluster-t3-external
       namespace: soans
       labels:
         weblogic.clusterName: soa_cluster
         weblogic.domainName: soainfra
         weblogic.domainUID: soainfra
    spec:
      type: NodePort
      selector:
        weblogic.domainName: soainfra
        weblogic.domainUID: soainfra
        weblogic.clusterName: soa_cluster
      ports:
      - name: t3soaport
        protocol: TCP
        port: 30016
        targetPort: 30016
        nodePort: 30016
    ```
1. Create the NodePort Service for port `30016`:
   ```
   $ kubectl create -f t3_ms_svc.yaml
   ```
1. Verify that you can access T3 for the Managed Server with the following URL:
   ```
   t3://<master_ip>:30016
   ```

1. Similarly, you can access T3S as follows:

   a. First get the certificates from the Administration Server to be used for secured (t3s) connection from client. You can export the certificate from the Administration Server with wlst commands. Sample commands to export the default `demoidentity`:
      > Note: In case you are using the custom SSL certificate, replaces the steps accordingly
      ```
      $ kubectl exec -it soainfra-adminserver -n soans -- bash
      $ /u01/oracle/oracle_common/common/bin/wlst.sh
      $ connect('weblogic','Welcome1','t3://soainfra-adminserver:7001')
      $ svc = getOpssService(name='KeyStoreService')
      $ svc.exportKeyStoreCertificate(appStripe='system', name='demoidentity', password='DemoIdentityKeyStorePassPhrase', alias='DemoIdetityKeyStorePassPhrase', type='Certificate', filepath='/tmp/cert.txt/')
      ```
      The above steps download the certificate at `/tmp/cert.txt`.

   b. Use the same certificates from the client side and connect using `t3s`. For example:
      ```
      $ export JAVA_HOME=/u01/jdk
      $ keytool -import -v -trustcacerts -alias soadomain -file cert.txt -keystore $JAVA_HOME/jre/lib/security/cacerts -keypass changeit -storepass changeit
      $ export WLST_PROPERTIES="-Dweblogic.security.SSL.ignoreHostnameVerification=true"
      $ cd $ORACLE_HOME/oracle_common/common/bin
      $ ./wlst.sh
        Initializing WebLogic Scripting Tool (WLST) ...
        Welcome to WebLogic Server Administration Scripting Shell
        Type help() for help on available commands
      $ wls:/offline> connect('weblogic','Welcome1','t3s://<Master IP address>:30016')
      ```

### Remove T3/T3S configuration

#### For Administration Server

1. Create `t3_admin_delete.py` with the following content:
   ``` Python
   admin_pod_name = sys.argv[1]
   admin_port = sys.argv[2]
   user_name = sys.argv[3]
   password = sys.argv[4]
   AdminServerName = sys.argv[5]
   channelType = sys.argv[6]
   print('custom admin_pod_name : [%s]' % admin_pod_name);
   print('custom admin_port : [%s]' % admin_port);
   print('custom user_name : [%s]' % user_name);
   print('custom password : ********');
   connect(user_name, password, 't3://' + admin_pod_name + ':' + admin_port)
   edit()
   startEdit()
   cd('/')
   cd('Servers/%s/' % AdminServerName )
   if channelType == 't3':
      delete('T3Channel_AS','NetworkAccessPoint')
   elif channelType == 't3s':
      delete('T3SChannel_AS','NetworkAccessPoint')
   else:
      print('channelType [%s] not supported',channelType)
   activate()
   disconnect()
   ```

1. Copy `t3_admin_delete.py` into the domain home (for example, `/u01/oracle/user_projects/domains/soainfra`) of the Administration Server pod (for example, `soainfra-adminserver` in `soans` namespace).
   ```
   $ kubectl cp t3_admin_delete.py soans/soainfra-adminserver:/u01/oracle/user_projects/domains/soainfra
   ```
1. Run `wlst.sh t3_admin_delete.py` by exec into the Administration Server pod with the following  parameters:

    * admin_pod_name: soainfra-adminserver *# Administration Server pod*
    * admin_port:  7001
    * user_name: weblogic
    * password: Welcome1 *# weblogic password*
    * AdminServerName: AdminServer *# Give administration Server name*
    * channelType: t3  *# T3 channel*

    ```
    $ kubectl exec -it <Administration Server pod> -n <namespace> -- /u01/oracle/oracle_common/common/bin/wlst.sh  <domain_home>/t3_admin_delete.py <Administration Server pod>  <Administration Server port>  weblogic <password for weblogic> <AdminServerName> <protocol t3 or t3s>
    ```
    For example:
    ```
    $ kubectl exec -it soainfra-adminserver -n soans -- /u01/oracle/oracle_common/common/bin/wlst.sh /u01/oracle/user_projects/domains/soainfra/t3_admin_delete.py soainfra-adminserver 7001 weblogic Welcome1 AdminServer t3
    ```
1. Delete the NodePort Service for port `30014`:
   ```
   $ kubectl delete -f t3_admin_svc.yaml
   ```

#### For Managed Servers

These steps delete the custom T3/T3S channel created by [Expose T3/T3S for Managed Servers]({{< relref "/soa-domains/adminguide/enablingt3#expose-t3t3s-for-managed-servers" >}}) for all Managed Servers.

1. Create `t3_ms_delete.py` with the following content:

    ``` Python
    admin_pod_name = sys.argv[1]
    admin_port = sys.argv[2]
    user_name = sys.argv[3]
    password = sys.argv[4]
    managedNameBase = sys.argv[5]
    ms_count = sys.argv[6]
    channelType = sys.argv[7]
    print('custom host : [%s]' % admin_pod_name);
    print('custom port : [%s]' % admin_port);
    print('custom user_name : [%s]' % user_name);
    print('custom password : ********');
    connect(user_name, password, 't3://' + admin_pod_name + ':' + admin_port)
    edit()
    startEdit()
    for index in range(0, int(ms_count)):
      cd('/')
      msIndex = index+1
      cd('/')
      name = '%s%s' % (managedNameBase, msIndex)
      cd('Servers/%s/' % name )
      if channelType == 't3':
        delete('T3Channel_MS','NetworkAccessPoint')
      elif channelType == 't3s':
        delete('T3SChannel_MS','NetworkAccessPoint')
      else:
        print('Protocol [%s] not supported' % channelType)
    activate()
    disconnect()
    ```
1. Copy `t3_ms_delete.py` into the domain home (for example, `/u01/oracle/user_projects/domains/soainfra`) of the Administration Server pod (for example, `soainfra-adminserver` in `soans` namespace).
   ```
   $ kubectl cp t3_ms_delete.py soans/soainfra-adminserver:/u01/oracle/user_projects/domains/soainfra
   ```
1. Run `wlst.sh t3_ms_delete.py` by exec into the Administration Server pod with the following  parameters:

    * admin_pod_name: soainfra-adminserver *# Administration Server pod*
    * admin_port:  7001
    * user_name: weblogic
    * password: Welcome1 *# weblogic password*
    * managedNameBase: soa_server *# Give Managed Server base name. For osb_cluster this will be osb_server*
    * ms_count: 5 *# Number of configured Managed Servers*
    * channelType: t3 *# channelType is t3 or t3s*

    ```
    $ kubectl exec -it <Administration Server pod> -n <namespace> -- /u01/oracle/oracle_common/common/bin/wlst.sh  <domain_home>/t3_ms_delete.py <Administration Server pod>  <Administration Server port>  weblogic <password for weblogic> <t3 port on Managed Server> <t3 nodeport> <master_ip> <managedNameBase> <ms_count> <channelType t3 or t3s>
    ```
    For example:
    ```
    $ kubectl exec -it soainfra-adminserver -n soans -- /u01/oracle/oracle_common/common/bin/wlst.sh /u01/oracle/user_projects/domains/soainfra/t3_ms_delete.py soainfra-adminserver 7001 weblogic Welcome1 soa_server 5 t3
    ```
1. Delete the NodePort Service for port `30016` (or the NodePort used while creating the Kubernetes Service):
   ```
   $ kubectl delete -f t3_ms_svc.yaml
   ```
