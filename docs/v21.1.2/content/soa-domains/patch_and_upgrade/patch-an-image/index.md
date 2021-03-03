---
title: "Patch an image"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 1
pre: "<b>a. </b>"
description: "Create a patched Oracle SOA Suite image using the WebLogic Image Tool."
---

Oracle releases Oracle SOA Suite images regularly with the latest bundle and recommended interim patches in My Oracle Support (MOS). However, if you need to create images with new bundle and interim patches, you can build these images using the WebLogic Image Tool.

If you have access to the Oracle SOA Suite patches, you can patch an existing Oracle SOA Suite image with a bundle patch and interim patches. Oracle recommends that you use the WebLogic Image Tool to patch the Oracle SOA Suite image.

> **Recommendations:**
>  * Use the WebLogic Image Tool [create]({{< relref "/soa-domains/create-or-update-image/#create-an-image" >}}) feature for patching the Oracle SOA Suite Docker image with a bundle patch and multiple interim patches. This is the recommended approach because it optimizes the size of the image.
>  * Use the WebLogic Image Tool [update]({{< relref "/soa-domains/create-or-update-image/#update-an-image" >}}) feature  for patching the Oracle SOA Suite Docker image with a single interim patch. Note that the patched image size may increase considerably due to additional image layers introduced by the patch application tool.


### Apply the patched Oracle SOA Suite image

To update an Oracle SOA Suite domain with a patched image, first make sure the patched image is pulled or created and available on the nodes in your Kubernetes cluster.
Once the patched image is available, you can follow these steps to update the Oracle SOA Suite domain with a patched image:

* [Stop all servers](#stop-all-servers)
* [Address post-installation requirements](#address-post-installation-requirements)
* [Apply the patched image](#apply-the-patched-image)


#### Stop all servers

>**Note**: Following steps are applicable only for non Zero Downtime Patching. In case of Zero Downtime Patching skip to the step [Address post-installation requirements](#address-post-installation-requirements).
 
Before applying the patch, stop all servers in the domain:

1. In the `domain.yaml` configuration file, update the `spec.serverStartPolicy` field value to `NEVER`.

1. Shut down the domain (stop all servers) by applying the updated `domain.yaml` file:

   ```
   $ kubectl apply -f domain.yaml
   ```

#### Address post-installation requirements

If the patches in the patched Oracle SOA Suite image have any post-installation steps or require SOA schema upgrades, follow these steps:

* [Create a Kubernetes pod with domain home access](#create-a-kubernetes-pod-with-domain-home-access)
* [Upgrade SOA schemas](#upgrade-soa-schemas)
* [Perform post-installation steps](#perform-post-installation-steps)

##### Create a Kubernetes pod with domain home access

1. Get domain home persistence volume claim details for the Oracle SOA Suite domain.

   For example, to list the persistent volume claim details in the namespace `soans`:
   ```
   $ kubectl get pvc -n soans   
   ```

   Sample output showing the persistent volume claim is `soainfra-domain-pvc`:
   ```
   NAME                  STATUS   VOLUME               CAPACITY   ACCESS MODES   STORAGECLASS                    AGE
   soainfra-domain-pvc   Bound    soainfra-domain-pv   10Gi       RWX            soainfra-domain-storage-class   xxd
   ```

1. Create a YAML `soapostinstall.yaml` using the domain home persistence volume claim.

   For example, using `soainfra-domain-pvc` per the sample output:

   > Note: Replace `soasuite:12.2.1.4-30761841` with the patched image in the following sample YAML:

   ```
   apiVersion: v1
   kind: Pod
   metadata:
     labels:
        run: soapostinstall
     name: soapostinstall
     namespace: soans
   spec:
    containers:
    - image: soasuite:12.2.1.4-30761841
      name: soapostinstall
      command: ["/bin/bash", "-c", "sleep infinity"]
      imagePullPolicy: IfNotPresent
      volumeMounts:
      - name: soainfra-domain-storage-volume
        mountPath: /u01/oracle/user_projects
    volumes:
    - name: soainfra-domain-storage-volume
      persistentVolumeClaim:
       claimName: soainfra-domain-pvc
   ```

1. Apply the YAML to create the Kubernetes pod:

   ```
   $ kubectl apply -f soapostinstall.yaml
   ```

##### Upgrade SOA schemas

Follow these steps to perform a SOA schema upgrade in a Kubernetes environment.

> Notes:
>  1. All operations are performed from a bash shell of the Kubernetes pod created in the previous step.  
>  2. If you want to use Upgrade Assistant in graphical user interface (GUI) mode, set the DISPLAY to the appropriate value before invoking the Upgrade Assistant.

To use the Upgrade Assistant in silent mode:

1. Create a response file (`response.txt`) required for the SOA schema upgrade.
   {{%expand "Click here to see a sample response file."  %}}
   ```bash
   [GENERAL]
   fileFormatVersion  = 3

   [UAWLSINTERNAL.UAWLS]
   pluginInstance = 1
   UASVR.path = /u01/oracle/user_projects/domains/soainfra

   [OPSS.OPSS_SCHEMA_PLUGIN]
   pluginInstance = 8
   OPSS.databaseType = Oracle Database
   OPSS.databaseConnectionString = //oracle-db.default.svc.cluster.local:1521/DEVPDB.K8S
   OPSS.schemaConnectionString = //oracle-db.default.svc.cluster.local:1521/DEVPDB.K8S
   OPSS.schemaUserName = SOA1_OPSS
   OPSS.cleartextSchemaPassword = yourpassword
   OPSS.dbaUserName = sys as sysdba
   OPSS.cleartextDbaPassword = yourpassword

   [MDS.SCHEMA_UPGRADE]
   pluginInstance = 6
   MDS.databaseType = Oracle Database
   MDS.databaseConnectionString = //oracle-db.default.svc.cluster.local:1521/DEVPDB.K8S
   MDS.schemaConnectionString = //oracle-db.default.svc.cluster.local:1521/DEVPDB.K8S
   MDS.schemaUserName = SOA1_MDS
   MDS.cleartextSchemaPassword = yourpassword
   MDS.dbaUserName = sys as sysdba
   MDS.cleartextDbaPassword = yourpassword

   [ESS.ESS_SCHEMA]
   pluginInstance = 11
   ESS.databaseType = Oracle Database
   ESS.databaseConnectionString = //oracle-db.default.svc.cluster.local:1521/DEVPDB.K8S
   ESS.schemaConnectionString = //oracle-db.default.svc.cluster.local:1521/DEVPDB.K8S
   ESS.schemaUserName = SOA1_ESS
   ESS.cleartextSchemaPassword = yourpassword
   ESS.dbaUserName = sys as sysdba
   ESS.cleartextDbaPassword = yourpassword

   [IAU.AUDIT_SCHEMA_PLUGIN]
   pluginInstance = 13
   IAU.databaseType = Oracle Database
   IAU.databaseConnectionString = //oracle-db.default.svc.cluster.local:1521/DEVPDB.K8S
   IAU.schemaConnectionString = //oracle-db.default.svc.cluster.local:1521/DEVPDB.K8S
   IAU.schemaUserName = SOA1_IAU
   IAU.cleartextSchemaPassword = yourpassword
   IAU.dbaUserName = sys as sysdba
   IAU.cleartextDbaPassword = yourpassword

   [FMWCONFIG.CIE_SCHEMA_PLUGIN]
   pluginInstance = 4
   STB.databaseType = Oracle Database
   STB.databaseConnectionString = oracle-db.default.svc.cluster.local:1521/devpdb.k8s
   STB.schemaConnectionString = oracle-db.default.svc.cluster.local:1521/devpdb.k8s
   STB.schemaUserName = SOA1_STB
   STB.cleartextSchemaPassword = yourpassword
   STB.dbaUserName = sys as sysdba
   STB.cleartextDbaPassword = yourpassword

   [UCSUMS.UCSUMS_SCHEMA_PLUGIN]
   pluginInstance = 2
   UMS.databaseType = Oracle Database
   UMS.databaseConnectionString = //oracle-db.default.svc.cluster.local:1521/DEVPDB.K8S
   UMS.schemaConnectionString = //oracle-db.default.svc.cluster.local:1521/DEVPDB.K8S
   UMS.schemaUserName = SOA1_UMS
   UMS.cleartextSchemaPassword = yourpassword
   UMS.dbaUserName = sys as sysdba
   UMS.cleartextDbaPassword = yourpassword

   [SOA.SOA1]
   pluginInstance = 14
   SOAINFRA.databaseType = Oracle Database
   SOAINFRA.databaseConnectionString = //oracle-db.default.svc.cluster.local:1521/DEVPDB.K8S
   SOAINFRA.schemaConnectionString = //oracle-db.default.svc.cluster.local:1521/DEVPDB.K8S
   SOAINFRA.schemaUserName = SOA1_SOAINFRA
   SOAINFRA.cleartextSchemaPassword = yourpassword
   SOAINFRA.dbaUserName = sys as sysdba
   SOAINFRA.cleartextDbaPassword = yourpassword

   [WLS.WLS]
   pluginInstance = 7
   WLS.databaseType = Oracle Database
   WLS.databaseConnectionString = //oracle-db.default.svc.cluster.local:1521/DEVPDB.K8S
   WLS.schemaConnectionString = //oracle-db.default.svc.cluster.local:1521/DEVPDB.K8S
   WLS.schemaUserName = SOA1_WLS_RUNTIME
   WLS.cleartextSchemaPassword = yourpassword
   WLS.dbaUserName = sys as sysdba
   WLS.cleartextDbaPassword = yourpassword
   ```
   {{% /expand %}}

1. Copy `response.txt` into the `soapostinstall` pod:

   ```
   $ kubectl cp response.txt soans/soapostinstall:/u01/oracle/user_projects
   ```

1. Start a bash shell in the `soapostinstall` pod:

   ```
   $ kubectl exec -it -n soans soapostinstall -- bash
   ```

   This opens a bash shell in the running `soapostinstall` pod:

   ```
   [oracle@soapostinstall oracle]$
   ```

1. You can now launch the Upgrade Assistant for the SOA schema upgrade in silent mode using the response file:

   ```
   $ /u01/oracle/oracle_common/upgrade/bin/ua  -response /u01/oracle/user_projects/response.txt
   ```   

   Sample output:
   ```
   Oracle Fusion Middleware Upgrade Assistant 12.2.1.4.0
   Log file is located at: /u01/oracle/oracle_common/upgrade/logs/ua2021-02-03-06-50-54AM.log
   Reading installer inventory, this will take a few moments...
   ...completed reading installer inventory.
   Using response file /u01/oracle/user_projects/response.txt for input
    Oracle Metadata Services schema examine is in progress
    Oracle Enterprise Scheduler schema examine is in progress
    Oracle Audit Services schema examine is in progress
    Oracle Platform Security Services schema examine is in progress
	.
	.
	.
	.   
   ```

1. Review the SOA schema upgrade log located at `/u01/oracle/oracle_common/upgrade/logs/ua<timestamp>.log`.

   From the sample output of the SOA schema upgrade, the log file is located at `/u01/oracle/oracle_common/upgrade/logs/ua2021-02-03-06-50-54AM.log`. You can copy the log file to your host and review it:

   ```
   [oracle@soapostinstall oracle]$ exit
   $ kubectl cp soans/soapostinstall:/u01/oracle/oracle_common/upgrade/logs/ua2021-02-03-06-50-54AM.log ua2021-02-03-06-50-54AM.log
   $ vim ua2021-02-03-06-50-54AM.log
   ```

##### Perform post-installation steps
If you need to perform any post-installation steps on the domain home:

1. Start a bash shell in the `soapostinstall` pod:

   ```
   $ kubectl exec -it -n soans soapostinstall -- bash
   ```

   This opens a bash shell in the running `soapostinstall` pod:

   ```
   [oracle@soapostinstall oracle]$
   ```

1. Use the bash shell of the `soapostinstall` pod and perform the required  steps on the domain home.

1. After successful completion of the post-installation steps, you can delete the `soapostinstall` pod:

   ```
   $ kubectl delete -f  soapostinstall.yaml
   ```

#### Apply the patched image

After completing the required SOA schema upgrade and post-installation steps, start up the domain:

1. In the `domain.yaml` configuration file, update the `image` field value with the patched image:   
   For example:

   ```
     image: soasuite:12.2.1.4-30761841
   ```

1. In case of non Zero Downtime Patching, update the `spec.serverStartPolicy` field value to `IF_NEEDED` in `domain.yaml`.

1. Apply the updated `domain.yaml` configuration file to start up the domain.

   ```
   $ kubectl apply -f domain.yaml
   ```
   >**Note**: In case of non Zero Downtime Patching, the complete domain startup happens, as the servers in the domain were stopped earlier. For Zero Downtime Patching the servers in the domain gets rolling restarted.

1. Verify the domain is updated with the patched image:

   ```
   $ kubectl describe domain <domainUID> -n <domain-namespace>|grep "Image:"
   ```

   Sample output:
   ```
   $ kubectl describe domain soainfra -n soans |grep "Image:"
   Image:                          soasuite:12.2.1.4-30761841
   $
   ```
