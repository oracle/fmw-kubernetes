---
title: "Additional Configuration"
weight: 4
pre : "<b> </b>"
description: "Describes how to create connections to Oracle WebCenter Content Server to enable content integration within Oracle WebCenter Portal."
---

### Creating a Connection to Oracle WebCenter Content Server

To enable content integration within Oracle WebCenter Portal create a connection to Oracle WebCenter Content Server using JAX-WS. Follow the steps in the documentation [link](https://docs.oracle.com/en/middleware/webcenter/portal/12.2.1.4/admin/managing-connections-oracle-webcenter-content-server.html#GUID-7907C8EA-802F-40B6-A19B-B0CC55CDB532) to create the connection. 

>Note: If the Oracle WebCenter Content Server is configured with SSL, before creating the connection, the SSL certificate should be imported into any location under mount path of domain persistent volume to avoid loss of certificate due pod restart.

### Import SSL Certificate
Import the certificate using below sample command, update the keystore location to a directory under mount path of the domain persistent volume :
```
$ kubectl exec -it wcp-domain-adminserver -n wcpns /bin/bash
$ cd $JAVA_HOME/bin
$ ./keytool -importcert -alias collab_cert -file /filepath/sslcertificate/contentcert.crt -keystore /u01/oracle/user_projects/domains/wcp-domain/DemoTrust.jks

```

### Update the TrustStore
To update the truststore location edit `domain.yaml` file, append `-Djavax.net.ssl.trustStore` to the `spec.serverPod.env.JAVA_OPTIONS` environment variable value. The truststore location used in `-Djavax.net.ssl.trustStore` option should be same as keystore location where the SSL certificate has been imported.
```yaml
serverPod:
  # an (optional) list of environment variable to be set on the servers
  env:
  - name: JAVA_OPTIONS
    value: "-Dweblogic.StdoutDebugEnabled=true -Dweblogic.ssl.Enabled=true -Dweblogic.security.SSL.ignoreHostnameVerification=true -Djavax.net.ssl.trustStore=/u01/oracle/user_projects/domains/wcp-domain/DemoTrust.jks"
  - name: USER_MEM_ARGS
    value: "-Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx1024m "
  volumes:
  - name: weblogic-domain-storage-volume
    persistentVolumeClaim:
      claimName: wcp-domain-domains-pvc
  volumeMounts:
  - mountPath: /u01/oracle/user_projects/domains
    name: weblogic-domain-storage-volume
```

Apply the `domain.yaml` file to restart the Oracle WebCenter Portal domain.

```bash
$ kubectl apply -f domain.yaml
```