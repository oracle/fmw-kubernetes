---
title: "a. Patch an image"
description: "Instructions on how to update your OIG Kubernetes cluster with a new OIG container image."
---

Choose one of the following options to update your OIG kubernetes cluster to use the new image:

1. Run the `kubectl edit domain` command
2. Run the `kubectl patch domain` command

In all of the above cases, the WebLogic Kubernetes Operator will restart the Administration Server pod first and then perform a rolling restart on the OIG Managed Servers.

**Note**: If you are not using Oracle Container Registry or your own container registry, then you must first load the new container image on all nodes in your Kubernetes cluster. 


### Run the kubectl edit domain command

1. To update the domain with  the `kubectl edit domain` command, run the following:

   ```bash
   $ kubectl edit domain <domainname> -n <namespace>
   ```

   For example:

   ```bash
   $ kubectl edit domain governancedomain -n oigns
   ```

   If using Oracle Container Registry or your own container registry for your OIG container image, update the `image` <tag> to point at the new image, for example:

   ```
   domainHomeInImage: false
   image: container-registry.oracle.com/middleware/oig_cpu:<tag>
   imagePullPolicy: IfNotPresent
   ```
   
   If you are not using a container registry and have loaded the image on each of the master and worker nodes, update the `image` <tag> to point at the new image:
   
   ```
   domainHomeInImage: false
   image: oracle/oig:<tag>
   imagePullPolicy: IfNotPresent
   ```

1. Save the file and exit (:wq!)


### Run the kubectl patch command

1. To update the domain with the `kubectl patch domain` command, run the following:

   ```bash
   $ kubectl patch domain <domain> -n <namespace> --type merge  -p '{"spec":{"image":"newimage:tag"}}'
   ```
   

   For example, if using Oracle Container Registry or your own container registry for your OIG container image:

   ```bash
   $ kubectl patch domain governancedomain -n oigns --type merge  -p '{"spec":{"image":"container-registry.oracle.com/middleware/oig_cpu:<tag>"}}'
   ```
   
   For example, if you are not using a container registry and have loaded the image on each of the master and worker nodes:
   
   ```bash
   $ kubectl patch domain governancedomain -n oigns --type merge  -p '{"spec":{"image":"oracle/oig:<tag>"}}'
   ```

   The output will look similar to the following:

   ```
   domain.weblogic.oracle/governancedomain patched
   ```

### Patch the database schemas

Once the image has been updated you must patch the schemas in the database.


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

   If the helper pod exists delete the pod with following command:
   
   ```bash
   $ kubectl delete pod helper -n <namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl delete pod helper -n oigns
   ```
   
1. Create a new helper pod by following the instructions in [Prepare you environment ](../../prepare-your-environment/#rcu-schema-creation). **Note**: The new helper pod should be started using the new image.


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
   
1. In the helper bash shell run the following commands to set the environment:

   ```bash
   [oracle@helper oracle]$ export DB_HOST=<db_host.domain>
   [oracle@helper oracle]$ export DB_PORT=<db_port>
   [oracle@helper oracle]$ export DB_SERVICE=<service_name>
   [oracle@helper oracle]$ export RCUPREFIX=<rcu_schema_prefix>
   [oracle@helper oracle]$ export RCU_SCHEMA_PWD=<rcu_schema_pwd>
   [oracle@helper oracle]$ echo -e <db_pwd>"\n"<rcu_schema_pwd> > /tmp/pwd.txt
   [oracle@helper oracle]$ cat /tmp/pwd.txt
   ```
   
   where: 
	
   `<db_host.domain>` is the database server hostname
   
   `<db_port>` is the database listener port
   
   `<service_name>` is the database service name
   
   `<rcu_schema_prefix>` is the RCU schema prefix you want to set
   
   `<rcu_schema_pwd>` is the password you want to set for the `<rcu_schema_prefix>`
	
   `<db_pwd>` is the SYS password for the database
	
   For example:
	
   ```bash
   [oracle@helper oracle]$ export DB_HOST=mydatabasehost.example.com
   [oracle@helper oracle]$ export DB_PORT=1521
   [oracle@helper oracle]$ export DB_SERVICE=orcl.example.com
   [oracle@helper oracle]$ export RCUPREFIX=OIGK8S
   [oracle@helper oracle]$ export RCU_SCHEMA_PWD=<password>
   ```

1. Run the following command to patch the schemas:

   {{% notice note %}}
   This command should be run if you are using an OIG image that contains OIG bundle patches. If using an OIG image without OIG bundle patches, then you can skip this step.
   {{% /notice %}}  

   ```bash
   [oracle@helper oracle]$ /u01/oracle/oracle_common/modules/thirdparty/org.apache.ant/1.10.5.0.0/apache-ant-1.10.5/bin/ant \
   -f /u01/oracle/idm/server/setup/deploy-files/automation.xml \
   run-patched-sql-files \
   -logger org.apache.tools.ant.NoBannerLogger \
   -logfile /u01/oracle/idm/server/bin/patch_oim_wls.log \
   -DoperationsDB.host=$DB_HOST \
   -DoperationsDB.port=$DB_PORT \
   -DoperationsDB.serviceName=$DB_SERVICE \
   -DoperationsDB.user=${RCUPREFIX}_OIM \
   -DOIM.DBPassword=$RCU_SCHEMA_PWD \
   -Dojdbc=/u01/oracle/oracle_common/modules/oracle.jdbc/ojdbc8.jar
   ```
   
   The output will look similar to the following:
   
   ```
   Buildfile: /u01/oracle/idm/server/setup/deploy-files/automation.xml
   ```
   
1. Verify the database was patched successfully by viewing the `patch_oim_wls.log`:

   ```bash
   [oracle@helper oracle]$ cat /u01/oracle/idm/server/bin/patch_oim_wls.log
   ```
   
   The output should look similar to below:
   
   ```
    ...
      [sql] Executing resource: /u01/oracle/idm/server/db/oim/oracle/StoredProcedures/OfflineDataPurge/oim_pkg_offline_datapurge_pkg_body.sql
      [sql] Executing resource: /u01/oracle/idm/server/db/oim/oracle/Upgrade/oim12cps4/list/oim12cps4_dml_pty_insert_sysprop_RequestJustificationLocale.sql
      [sql] Executing resource: /u01/oracle/idm/server/db/oim/oracle/Upgrade/oim12cps4/list/oim12cps4_dml_pty_insert_sysprop_reportee_chain_for_mgr.sql
      [sql] 36 of 36 SQL statements executed successfully


   BUILD SUCCESSFUL
   Total time: 5 second
   ```
