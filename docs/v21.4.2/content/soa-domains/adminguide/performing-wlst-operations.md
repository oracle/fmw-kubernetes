---
title: "Perform WLST operations"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 8
pre : "<b></b>"
description: "Perform WLST administration operations using a helper pod running in the same Kubernetes cluster as the Oracle SOA Suite domain."
---

You can use the WebLogic Scripting Tool (WLST) to manage a domain running in a Kubernetes cluster. Some of the many ways to do this are provided here.

If the Administration Server was configured to expose a T3 channel using `exposeAdminT3Channel` when creating the domain, refer to [Use WLST](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/accessing-the-domain/wlst/).

If you do not want to expose additional ports and perform WLST administration operations using the existing Kubernetes services created by the WebLogic Server Kubernetes operator, then follow this documentation. Here we will be creating and using a helper pod in the same Kubernetes cluster as the Oracle SOA Suite domain to perform WLST operations.

> Note: To avoid any misconfigurations, Oracle recommends that you do not use the Administration Server pod directly for WLST operations.

1. [Create a Kubernetes helper pod](#create-a-kubernetes-helper-pod)
2. [Perform WLST operations](#perform-wlst-operations)
3. [Sample WLST operations](#sample-wlst-operations)

#### Create a Kubernetes helper pod

Before creating a Kubernetes helper pod, make sure that the Oracle SOA Suite Docker image is available on the node, or you can create an image pull secret so that the pod can pull the Docker image on the host where it gets created.

1. Create an image pull secret to pull image `soasuite:12.2.1.4` by the helper pod.

   Note: Skip this step if you are not using an image pull secret.
   ```
   $ kubectl create secret docker-registry <secret-name> --namespace soans \
     --docker-server=<docker-registry-name> \
     --docker-username=<docker-user> \
     --docker-password=<docker-user> \
     --docker-email=<email-id>
   ```

   For example:

   ```
   $ kubectl create secret docker-registry image-secret --namespace soans \
      --docker-server=your-registry.com \
      --docker-username=xxxxxx \
      --docker-password=xxxxxxx  \
      --docker-email=my@company.com
   ```

1. Create a helper pod.

   For Kubernetes 1.18.10+, 1.19.7+, and 1.20.6+:
   ```
   $ kubectl run helper \
     --image <image_name> \
     --namespace <domain_namespace> \
     --overrides='{ "apiVersion": "v1", "spec": { "imagePullSecrets": [{"name": "<secret-name>"}] } }' \
     -- sleep infinity
   ```

   For Kubernetes 1.16.15+, and 1.17.13+:
   ```
   $ kubectl run helper --generator=run-pod/v1 \
     --image <image_name> \
     --namespace <domain_namespace> \
     --overrides='{ "apiVersion": "v1", "spec": { "imagePullSecrets": [{"name": "<secret-name>"}] } }'  \
     -- sleep infinity
   ```

   For example:
   ```
   $ kubectl run helper \
     --image soasuite:12.2.1.4 \
     --namespace soans \
     --overrides='{ "apiVersion": "v1", "spec": { "imagePullSecrets": [{"name": "image-secret"}] } }' \
     -- sleep infinity
   ```

   > **Note**: If you are not using the image pull secret, remove `--overrides='{ "apiVersion": "v1", "spec": { "imagePullSecrets": [{"name": "<secret-name>"}] } }' `.

#### Perform WLST operations

Once the Kubernetes helper pod is deployed, you can exec into the pod, connect to servers using `t3` or `t3s` and perform WLST operations. By default, `t3s` is not enabled for the Administration Server or Managed Servers. If you enabled SSL with `sslEnabled` when creating the domain, then you can use `t3s` to perform WLST operations.

##### Interactive mode
1. Start a bash shell in the helper pod:

   ```
   $ kubectl exec -it helper -n <domain_namespace> -- /bin/bash
   ```

   For example:

   ```
   $ kubectl exec -it helper -n soans -- /bin/bash
   ```

   This opens a bash shell in the running helper pod:

   ```
   [oracle@helper oracle]$


1. Invoke WLST:

   ```
   [oracle@helper oracle]$ cd $ORACLE_HOME/oracle_common/common/bin
   [oracle@helper bin]$ ./wlst.sh
   ```

   The output will look similar to the following:

   ```
   [oracle@helper bin]$ ./wlst.sh

   Initializing WebLogic Scripting Tool (WLST) ...

   Jython scans all the jar files it can find at first startup. Depending on the system, this process may take a few minutes to complete, and WLST may not return a prompt right away.

   Welcome to WebLogic Server Administration Scripting Shell

   Type help() for help on available commands

   wls:/offline>


1. Connect using `t3`:

   a. To connect to the Administration Server or Managed Servers using `t3`, you can use the Kubernetes services created by the WebLogic Server Kubernetes operator:

      ```
      wls:/offline> connect('weblogic','<password>','t3://<domainUID>-<WebLogic Server Name>:<Server Port>')
      ```

      For example, if the domainUID is `soainfra`, Administration Server name is `AdminServer`, and Administration Server port is `7001`, then you can connect to the Administration Server using `t3`:

      ```
      wls:/offline> connect('weblogic','<password>','t3://soainfra-adminserver:7001')
      ```

      The output will look similar to the following:

      ```
      wls:/offline> connect('weblogic','<password>','t3://soainfra-adminserver:7001')
      Connecting to t3://soainfra-adminserver:7001 with userid weblogic ...
      Successfully connected to Admin Server "AdminServer" that belongs to domain "soainfra".

      Warning: An insecure protocol was used to connect to the server.
      To ensure on-the-wire security, the SSL port or Admin port should be used instead.

      wls:/soainfra/serverConfig/>
      ```

   b. To connect a WebLogic Server cluster (SOA or Oracle Service Bus) using `t3`, you can use the Kubernetes services created by the WebLogic Server Kubernetes operator:

      ```
      wls:/offline> connect('weblogic','<password>','t3://<domainUID>-cluster-<Cluster name>:<Managed Server Port>')
      ```

      For example, if the domainUID is `soainfra`, SOA cluster name is `soa-cluster`, and  SOA Managed Server port is `8001`, then you can connect to SOA Cluster using `t3`:

	  ```
      wls:/offline> connect('weblogic','<password>','t3://soainfra-cluster-soa-cluster:8001')
      ```

      The output will look similar to the following:

      ```
      wls:/offline> connect('weblogic','<password>','t3://soainfra-cluster-soa-cluster:8001')
      Connecting to t3://soainfra-cluster-soa-cluster:8001 with userid weblogic ...
      Successfully connected to Managed Server "soa_server1" that belongs to domain "soainfra".

      Warning: An insecure protocol was used to connect to the server.
      To ensure on-the-wire security, the SSL port or Admin port should be used instead.

      wls:/soainfra/serverConfig/>
      ```

1. Connect using `t3s`.

   If you enabled SSL with `sslEnabled` when creating the domain, then you can use `t3s` to perform WLST operations:

   a. Obtain the certificate from the Administration Server to be used for a secured (`t3s`) connection from the client by exporting the certificate from the Administration Server using WLST commands. Sample commands to export the default `demoidentity`:
      ```
      [oracle@helper oracle]$ cd $ORACLE_HOME/oracle_common/common/bin
      [oracle@helper bin]$ ./wlst.sh
      .
      .
      wls:/offline> connect('weblogic','<password>','t3://soainfra-adminserver:7001')
      .
      .
      wls:/soainfra/serverConfig/> svc = getOpssService(name='KeyStoreService')
      wls:/soainfra/serverConfig/> svc.exportKeyStoreCertificate(appStripe='system', name='demoidentity', password='DemoIdentityKeyStorePassPhrase', alias='DemoIdetityKeyStorePassPhrase', type='Certificate', filepath='/tmp/cert.txt/')
      ```
      These commands download the certificate for the default `demoidentity` certificate at `/tmp/cert.txt`.

   b. Import the certificate to the Java trust store:
      ```
      [oracle@helper oracle]$ export JAVA_HOME=/u01/jdk
      [oracle@helper oracle]$ keytool -import -v -trustcacerts -alias soadomain -file /tmp/cert.txt -keystore $JAVA_HOME/jre/lib/security/cacerts -keypass changeit -storepass changeit
      ```

   c. Connect to WLST and set the required environment variable before connecting using `t3s`:
      ```
      [oracle@helper oracle]$ export WLST_PROPERTIES="-Dweblogic.security.SSL.ignoreHostnameVerification=true"
      [oracle@helper oracle]$ cd $ORACLE_HOME/oracle_common/common/bin
      [oracle@helper bin]$ ./wlst.sh
      ```

   d. Access `t3s` for the Administration Server.

      For example, if the domainUID is `soainfra`, Administration Server name is `AdminServer`, and Administration Server SSL port is `7002`, connect to the Administration Server as follows:

      ```
      wls:/offline> connect('weblogic','<password>','t3s://soainfra-adminserver:7002')
      ```

   e. Access `t3s` for the SOA cluster.

      For example, if the domainUID is `soainfra`, SOA cluster name is `soa-cluster`, and SOA Managed Server SSL port is `8002`, connect to the SOA cluster as follows:
      ```
      wls:/offline> connect('weblogic','<password>','t3s://soainfra-cluster-soa-cluster:8002')
      ```   

##### Script mode

In script mode, scripts contain WLST commands in a text file with a `.py` file extension (for example, `mywlst.py`). Before invoking WLST using the script file, you must copy the `.py` file into the helper pod.

To copy the `.py` file into the helper pod using WLST operations in script mode:

1. Create a `.py` file containing all the WLST commands.

1. Copy the `.py` file into the helper pod:

   ```
   $ kubectl cp <filename>.py <domain namespace>/helper:<directory>
   ```

   For example:
   ```
   $ kubectl cp mywlst.py soans/helper:/u01/oracle
   ```


1. Run `wlst.sh` on the `.py` file by exec into the helper pod:

   ```
   $ kubectl exec -it helper -n <domain_namespace> -- /bin/bash
   [oracle@helper oracle]$ cd $ORACLE_HOME/oracle_common/common/bin
   [oracle@helper oracle]$ ./wlst.sh <directory>/<filename>.py
   ```

Note: Refer to [Interactive mode](#interactive-mode) for details on how to connect using `t3` or `t3s`.



#### Sample WLST operations


For a full list of WLST operations, refer to [WebLogic Server WLST Online and Offline Command Reference](https://docs.oracle.com/en/middleware/fusion-middleware/weblogic-server/12.2.1.4/wlstc/quick_ref.html#GUID-B6001303-FF2D-4EE7-8BB6-354E6D7C1692).

##### Display servers

```
$ kubectl exec -it helper -n soans -- /bin/bash
[oracle@helper oracle]$ cd $ORACLE_HOME/oracle_common/common/bin
[oracle@helper bin]$ ./wlst.sh

Initializing WebLogic Scripting Tool (WLST) ...

Jython scans all the jar files it can find at first startup. Depending on the system, this process may take a few minutes to complete, and WLST may not return a prompt right away.

Welcome to WebLogic Server Administration Scripting Shell

Type help() for help on available commands

wls:/offline> connect('weblogic','Welcome1','t3://soainfra-adminserver:7001')
Connecting to t3://soainfra-adminserver:7001 with userid weblogic ...
Successfully connected to Admin Server "AdminServer" that belongs to domain "soainfra".

Warning: An insecure protocol was used to connect to the server.
To ensure on-the-wire security, the SSL port or Admin port should be used instead.

wls:/soainfra/serverConfig/>  cd('/Servers')
wls:/soainfra/serverConfig/Servers> ls()
dr--   AdminServer
dr--   osb_server1
dr--   osb_server2
dr--   osb_server3
dr--   osb_server4
dr--   osb_server5
dr--   soa_server1
dr--   soa_server2
dr--   soa_server3
dr--   soa_server4
dr--   soa_server5

wls:/soainfra/serverConfig/Servers>
```
