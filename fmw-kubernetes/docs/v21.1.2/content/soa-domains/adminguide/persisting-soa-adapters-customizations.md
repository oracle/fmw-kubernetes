---
title: "Persist adapter customizations"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 8
pre : "<b></b>"
description: "Persist the customizations done for Oracle SOA Suite adapters."
---

The lifetime for any customization done in a file on a server pod is up to the lifetime of that pod. The changes are not persisted once the pod goes down or is restarted.

For example, the following configuration updates `DbAdapter.rar` to create a new connection instance and creates data source CoffeeShop on the Administration Console for the same with `jdbc/CoffeeShopDS`.

File location: `/u01/oracle/soa/soa/connectors/DbAdapter.rar`
```
<connection-instance>
  <jndi-name>eis/DB/CoffeeShop</jndi-name>
  <connection-properties>
    <properties>
      <property>
        <name>XADataSourceName</name>
        <value>jdbc/CoffeeShopDS</value>
      </property>
      <property>
        <name>DataSourceName</name>
	    <value></value>
      </property>
      <property>
        <name>PlatformClassName</name>
	    <value>org.eclipse.persistence.platform.database.Oracle10Platform</value>
      </property>
    </properties>
   </connection-properties>
</connection-instance>
```
If you need to persist the customizations for any of the adapter files under the SOA Oracle Home in the server pod, use one of the following methods.

### Method 1: Customize the Adapter file using the WebLogic Administration Console:

1. Log in to the WebLogic Administration Console, and go to **Deployments** > **ABC.rar** > **Configuration** > **Outbound Connection Pools**.

1. Click **New** to create a new connection, then provide a new connection name, and click **Finish**.

1. Go back to the new connection, update the properties as required, and save.

1. Under **Deployments**, select **ABC.rar**, then **Update**.

   This step asks for the `Plan.xml` location. This location by default will be in `${ORACLE_HOME}/soa/soa` which is not under Persistent Volume (PV). Therefore, provide the domain's PV location such as `{DOMAIN_HOME}/soainfra/servers`.  
  Now the `Plan.xml` will be persisted under this location for each Managed Server.

### Method 2: Customize the Adapter file on the Worker Node:

1. Copy `ABC.rar` from the server pod to a PV path:
   ```
   $ kubectl cp <namespace>/<SOA Managed Server pod name>:<full path of .rar file>  <destination path inside PV>
   ```
   For example:
   ```
   $ kubectl cp soans/soainfra-soa-server1:/u01/oracle/soa/soa/connectors/ABC.rar ${DockerVolume}/domains/soainfra/servers/ABC.rar
   ```
   or
   do a normal file copy between these locations after entering (using `kubectl exec`) in to the Managed Server pod.

1. Unrar `ABC.rar`.

1. Update the new connection details in the `weblogic-ra.xml` file under `META_INF`.

1. In the WebLogic Administration Console, under **Deployments**, select **ABC.rar**, then **Update**.

1. Select the `ABC.rar` path as the new location, which is `${DOMAIN_HOME}/user_projects/domains/soainfra/servers/ABC.rar` and click **Update**.

1. Verify that the `plan.xml` or updated `.rar` should be persisted in the PV.
