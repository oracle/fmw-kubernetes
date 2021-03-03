---
title: "Configure Automatic Service Migration"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 7
pre : "<b></b>"
description: "Perform Java Messaging Service (JMS) automatic service migration (ASM) in an Oracle SOA Suite domain setup."
---

Singleton services offer one of the highest qualities of service (QOS) but are very susceptible to *single point of failure*. To address this issue, WebLogic Server offers a solution called *migration*. The process of moving the entire server instance from one physical machine to another upon failure is called *Whole Server Migration (WSM)*. On the other hand, moving only the affected subsystem services from one server instance to another running server instance is called *Service Migration*. For more information on migration, see [here](https://www.oracle.com/technetwork/middleware/weblogic/weblogic-automatic-service-migratio-133948.pdf).

In an Oracle SOA Suite domain deployed in Kubernetes cluster, the Whole Server migration is not supported, Service level migration is supported with DB leasing, however Consensus leasing is not supported.



This section describes the steps to perform Java Messaging Service (JMS) automatic service migration (ASM) in an Oracle SOA Suite domain setup. See [here](https://docs.oracle.com/en/middleware/fusion-middleware/weblogic-server/12.2.1.4/wlach/taskhelp/jms_servers/AutoMigrateJMSServer.html) for more information on this process.

### Configure Automatic Service Migration for Oracle SOA Suite Servers

1. Log in to the Administration Console URL of the domain.  
   For example: `http://<LOADBALANCER-HOST>:<port>/console`

1. In the home page, click **Clusters**. Then click the cluster that you want to use for migration. For example, `soa_cluster`.

1. Click the **Migration** tab and then click **Lock & Edit** in the Change Center panel. Verify that:
    * **Migration Basis** is set to `Database`.
    * **Auto Migration Table Name** is set to `ACTIVE`.
    * **Data Source For Automatic Migration** drop down shows the appropriate data source (for example, `WLSSchemaDataSource`) for migration.

1. (Optional) Click **New** to create a new data source.

1. Click **Save**.

1. Browse to **Environment** -> **Clusters** -> **Migratable Targets**.

1. For each migratable Managed Server (for example, `soa_server1`), go to the **Migration** tab and set **Service Migration Policy** to `Auto-Migrate Exactly-Once-Services`.

1. Click **Save**.

1. Click **Activate Changes** in the Change Center panel.

1. Restart the entire Oracle SOA Suite domain using [these steps](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/domain-lifecycle/startup/#restart-all-the-servers-in-the-domain).

> Note: Do not restart servers from the Administration Console.
