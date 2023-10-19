# Automating the Identity and Access Management Enterprise Disaster Recovery

A number of sample scripts have been developed which allow you to deploy Oracle Identity and Access Management Disaster recovery. These scripts are provided as samples for you to use to develop your own applications.

You must ensure that you are using the October 2023 or later release of Identity and Access Management for this utility to work.

The main script enable_dr.sh is designed to be run on each site, that is to say run it on the Primary then Run it on the Standby.

The scripts can be run from any host which has access to the local Kubernetes cluster. 

The scripts work by taking a backup of objects on the primary site and restoring them on the standby.

If you wish the scripts to automatically copy backup files between your primary and standby deployment hosts then you must have passwordless ssh set up between your two deployment hosts.

These scripts are provided as examples and can be customized as desired.

## Obtaining the Scripts

The automation scripts are available for download from GitHub.

To obtain the scripts, use the following command:

```
git clone https://github.com/oracle/fmw-Kubernetes.git
```

The scripts appear in the following directory:

```
fmw-kubernetes/FMWKubernetesMAA/OracleEnterpriseDeploymentAutomation/OracleIdentityManagement
```

Move these template scripts to your working directory. For example:

```
cp -R fmw-Kubernetes/FMWKubernetesMAA/OracleEnterpriseDeploymentAutomation/OracleIdentityManagement/* /workdir/scripts
```


## Scope
This section lists the actions that the scripts perform as part of the deployment process. It also lists the tasks the scripts do not perform.

### What the Scripts Will do

The scripts will enable disaster recovery for Oracle Unified Directory (OUD), Oracle Access Manager (OAM), Oracle Identity Governance (OIG), Oracle Identity Role Intelligence (OIRI), Oracle Advanced Authentication (OAA) and Oracle HTTP Servers.

The scripts perform the following actions:

* Create a backup job to periodically take a backup of the persistent volumes associated with an application and transfer these files to a staging area on your standby system.
* Create a restore job to periodically restore the PV backup to the standby site, modifying database connection information and Kubernetes access files as needed.
* Use the MAA Kubernetes Snapshot tool to take a backup of the Kubernetes Objects in the application namespace.
* Use the MAA Kubernetes Snapshot tool to restore the backup of the Kubernetes Objects to the same namespace on the standby system.
* If the MAA Kubernetes Snapshot tool is not being used then they will sanitize the deployment created on the standby system, prior to Syncing with the primary.
* Backup the Oracle HTTP Server configuration on the primary, and restore it on the standby making routing updates as needed.
* Provide Management Operations on the Primary and Standby Sites including:
    * Manually running and instantiation Job.
    * Start and Stop s deployment
    * Suspend and Resume the Cronjob's responsible for PV Synchronization.
    * Change the role of a site to reverse the direction on the PV Synchronization.

### What the Scripts Will Not Do

While the scripts perform the majority of the deployment, they do not perform the following tasks:

* Deploy Container Runtime Environment, Kubernetes, or Helm.
* Configure load balancer, and ensure that any SSL certificates are consistent between the load balancers on the Primary and Standby Systems.
* Deploy your Primary Site.
* Install the WebLogic Operator.
* Install Ingress.
* Install Oracle HTTP Server.
* Create a Dataguard database on the Standby Site.
* Enable Disaster Recovery for Prometheus and Grafana.
* Enable Disaster Recovery for Elastic Search and Kibana.


## Key Concepts of the Scripts

To make things simple and easy to manage the scripts are based around two concepts:

* A response file with details of your environment.
* Template files you can easily modify or add to as required.

> Note: Scripts are reentrant, if something fails it can be restarted at the point at which it failed.


## Getting Started

All operations are controlled via two scripts which are located in the utils directory.

* enable_dr.sh - This script takes one parameter, the product.   Valid products are ohs, oud, oam, oig, oaa and oiri.   

 For example, to enable DR for OAM
 
 On the Primary Site

 ```
 utils/enable_dr.sh oam
 ```
 
 Then on the Standby Site
 
 ```
 utils/enable_dr.sh oam
 ```
 
* idmdrctl.sh - This script takes two arguments.

    -a Action
    -p Product
    
    Valid Actions are:
    
    * initial (Create initialization job)
    * switch (Switch the sites role STANDBY/PRIMARY)
    * stop (Stop a deployment)
    * start (Start a deployment)
    * suspend (Suspend the PV backup/restore job)
    * resume (Resume the PV backup/restore job)

    Valid products are
    
    * oud
    * oam
    * oig
    * oaa
    * oiri

 For example, to shutdown OAM issue the command:

 ```
 utils/idmdrctl.sh -a stop -p oam
 ```

## Creating a Response File

Sample response and password files are created for you in the `responsefile` directory. You can edit these files.  The files can be edited directly.


Values are stored in the files `dr.rsp` and `.drpwd` 

> Note: 
> * The file consists of key/value pairs. There should be no spaces between the name of the key and its value. For example:
> `Key=value`
>* If you are using complex passwords, that is, passwords which contain characters such as `!`, `*`, and `$`, then these characters must be separated by a `\`. For example: 'hello!$' should be entered as `hello\!\$`. 

> Note: The reference sections below detail all parameters.  Parameters associated with passwords are stored in a hidden file in the same directory.  This is an added security measure.

## Log Files

The enable_dr.sh script creates log files in the Directory \<WORKDIR\>/\<PRODUCT\>/DR in a `logs` sub-directory. This directory also contains the following two files:

* `progressfile` – This file contains the last successfully executed step. If you want to restart the process at a different step, update this file.

* `timings.log` – This file is used for informational purposes to show how much time was spent on each stage of the provisioning process.

For example:
/workdir/OAM/DR/logs


## Reference – Response File

The following sections describe the parameters in the response file that is used to control the provisioning of the various products in the Kubernetes cluster. The parameters are divided into generic and product-specific parameters.



### Products to Deploy
These parameters determine which products the deployment scripts attempt to deploy.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
| **DR\_OHS** | `true` | Set to `true` to Enable DR for Oracle HTTP Server. |
| **DR\_OUD** | `true` | Set to `true` to Enable DR for  OUD. |
| **DR\_OAM** | `true` | Set to `true` to Enable DR for OAM. |
| **DR\_OIG** | `true` | Set to `true` to Enable DR for OIG. |
| **DR\_OIRI** | `true` | Set to `true` to Enable DR for OIRI. |
| **DR\_OAA** | `true` | Set to `true` to Enable DR for OAA.|


### Control Parameters
These parameters are used to specify the type of Kubernetes deployment and the names of the temporary directories you want the deployment to use, during the provisioning process.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**USE\_REGISTRY** | `true` | Set to `true` to obtain images from a Container Registry.|
| **USE\_INGESS** | `true` | Set to `true` if using and ingress controller|

### Generic Parameters
These parameters are used to specify Generic properties.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
| **LOCAL\_WORKDIR** | `/workdir` | The location where you want to create the working directory.|
| **K8\_DRDIR** | `/u01/oracle/user_projects/dr_scripts` | The location inside the Kubernetes containers to which DR files are copied.|


### Container Registry Parameters
These parameters are used to determine whether or not you are using a container registry. If you are, then it allows you to store the login credentials to the repository as registry secrets in the individual product namespaces.

If you are pulling images from GitHub or Docker hub, then you can also specify the login parameters here so that you can create the appropriate Kubernetes secrets.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**REGISTRY** | `iad.ocir.io/mytenancy` | Set to the location of your container registry.|
|**REG\_USER** | `mytenancy/oracleidentitycloudservice/email@example.com` | Set to your registry user name.|
|**REG\_PWD** | *`<password>`* | Set to your registry password. |
|**CREATE\_REGSECRET** | `false` | Set to `true` to create a registry secret for automatically pulling images.|


### Image Parameters
These parameters are used to specify the names and versions of the container images you want to use for the deployment. These images must be available either locally or in your container registry. The names and versions must be identical to the images in the registry or the images stored locally.

These can include registry prefixes if you use a registry. Use the `local/` prefix if you use the Oracle Cloud Native Environment. 

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**RSYNC\_IMAGE** | `ghcr.io/oracle/weblogic-Kubernetes-operator` | The name of the rsync image you wish to use. |
|**OPER\_VER** | `4.1.2` | The version of the WebLogic Kubernetes Operator.|
|**RSYNC\_VER** | `latest` | The version of the RSYNC image.|

### DR Parameters
These parameters are specific to DR.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**DR\_TYPE** | `PRIMARY` | The role of the current site PRIMARY or STANDBY|
|**DRNS** | `drns` | The Kubernetes namespace used to hold the DR PV sync jobs|

### NFS Parameters
These generic parameters apply to all deployments.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**DR\_PRIMARY\_PVSERVER** | `primnfsserver.example.com` | The name or IP address of the NFS server used for persistent volumes in the primary site. **Note**: If you use a name, then the name must be resolvable inside the Kubernetes cluster. If it is not resolvable, you can add it by updating CoreDNS. See [Adding Individual Host Entries to CoreDNS](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/preparing-premises-enterprise-deployment.html#GUID-CC0AE601-6D0A-4000-A8CE-F83D2E1F836E).
|**DR\_PRIMARY\_NFS\_EXPORT** | `/export/IAMPVS` | The export path on the primary NFS where persistent volumes are located.|
|**DR\_STANDBY\_PVSERVER** | `stbynfsserver.example.com` | The name or IP address of the NFS server used for persistent volumes in the primary site. **Note**: If you use a name, then the name must be resolvable inside the Kubernetes cluster. If it is not resolvable, you can add it by updating CoreDNS. See [Adding Individual Host Entries to CoreDNS](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/preparing-premises-enterprise-deployment.html#GUID-CC0AE601-6D0A-4000-A8CE-F83D2E1F836E).
|**DR\_STANDBY\_NFS\_EXPORT** | `/export/IAMPVS` | The export path on the primary NFS where persistent volumes are located.|

### OUD Parameters
These parameters are specific to OUD. When deploying OUD, you also require the generic LDAP parameters.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**OUDNS** | `oudns` | The Kubernetes namespace used to hold the OUD objects.|
|**OUD\_POD\_PREFIX** | `edg`| The prefix used for the OUD pods.|
|**OUD\_REPLICAS** | `2`| The number of OUD replicas to create. |
|**OUD\_PRIMARY\_SHARE** | `$DR_PRIMARY_NFS_EXPORT/oudpv` | Mount point on the primary NFS where OUD persistent volume is exported.|
|**OUD\_PRIMARY\_CONFIG\_SHARE** | `$DR_PRIMARY_NFS_EXPORT/oudconfigpv`| The mount point on the primary NFS where OUD Configuration persistent volume is exported.|
|**OUD\_STANDBY\_SHARE** | `$DR_STANDBY_NFS_EXPORT/oudpv` | Mount point on the Standby NFS where OUD persistent volume is exported.|
|**OUD\_STANDBY\_CONFIG\_SHARE** | `$DR_STANDBY_NFS_EXPORT/oudconfigpv`| The mount point on the standby NFS where OUD Configuration persistent volume is exported.|**
|**OUD\_LOCAL\_SHARE** | `/nfs_volumes/oudconfigpv` | The local directory where the local OUD\_CONFIG\_SHARE is mounted. Used to hold seed files.|
|**DR\_OUD\_MINS** | `5`| The frequency in minutes to run the PV sync job.|
|**DR\_CREATE\_OUD\_JOB** | `true` | Determines whether or not to create a cron job to sync the PVs.  Set to false if using hardware synchronization.|


### Oracle HTTP Server Parameters
These parameters are specific to OHS.  These parameters are used to construct the Oracle HTTP Server configuration files and Install the Oracle HTTP Server if requested. 

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**OHS\_BASE** |`/u02/private`| The location of your OHS base directory.  Binaries and Configuration files are below this location.  The OracleInventory is also placed into this location when installing the Oracle HTTP Server.|
|**OHS\_ORACLE\_HOME** |`$OHS_BASE/oracle/products/ohs`| The location of your OHS binaries.|
|**OHS\_DOMAIN** |`$OHS_BASE/oracle/config/domains/ohsDomain`| The location of your OHS domain.|
|**OHS\_USER** |`opc`| The Oracle HTTP Software account user.|
|**OHS\_HOST1** |`webhost1.example.com`| The fully qualified name of the host running the first Oracle HTTP Server.|
|**OHS\_HOST2** |`webhost2.example.com`| The fully qualified name of the host running the second Oracle HTTP Server, leave it blank if you do not have a second Oracle HTTP Server.|
|**OHS1\_NAME** |`ohs1`| The component name of your first OHS instance.|
|**OHS2\_NAME** |`ohs2`| The component name of your second OHS instance.|


### OAM Parameters
These parameters determine how OAM is deployed and configured.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**OAMNS** | `oamns` | The Kubernetes namespace used to hold the OAM objects.|
|**OAM\_DOMAIN\_NAME** | `accessdomain` | The name of the OAM domain you want to create.|
|**OAM\_PRIMARY\_SHARE** | `$DR_PRIMARY_NFS_EXPORT/oampv` | The mount point on the primary NFS where OAM persistent volume is exported.|
|**OAM\_STANDBY\_SHARE** | `$DR_STANDBY_NFS_EXPORT/oampv` | The mount point on the standby NFS where OAM persistent volume is exported.|
|**OAM\_LOCAL\_SHARE** | `/nfs_volumes/oampv` | The local directory where OAM_SHARE is mounted. It is used by the deletion procedure.|
|**OAM\_SERVER\_INITIAL** | `2` | The number of OAM Managed Servers you want to start for normal running. You will need at least two servers for high availability.|
|**OAM\_PRIMARY\_DB\_SCAN** | `dbscan.example.com` | The database scan address of the primary grid infrastructure.|
|**OAM\_PRIMARY\_DB\_SERVICE** | `iadedg.example.com` | The database service that connects to the primary database where the OAM schemas are located.|
|**OAM\_STANDBY\_DB\_SCAN** | `stbyscan.example.com` | The database scan address of the standby grid infrastructure.|
|**OAM\_STANDBY\_DB\_SERVICE** | `iadedg.example.com` | The database service that connects to the standby database where the OAM schemas are located.|
|**OAM\_DB\_LISTENER** | `1521` | The database listener port.|
|**COPY\_WG\_FILES** | `true` | Set to true if you wish the DR scripts to copy the WebGate Artifacts to your Oracle HTTP Server(s).|
|**DR\_OAM\_MINS** | `720`| The frequency in minutes to run the PV sync job.|
|**DR\_CREATE\_OAM\_JOB** | `true` | Determines whether or not to create a cron job to sync the PVs.  Set to false if using hardware synchronization.|

### OIG Parameters
These parameters determine how OIG is provisioned and configured.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**OIGNS** | `oigns` | The Kubernetes namespace used to hold the OIG objects.|
|**OIG\_DOMAIN\_NAME** | `governancedomain` | The name of the OIG domain you want to create.|
|**OIG\_PRIMARY\_SHARE** | `$DR_PRIMARY_NFS_EXPORT/oigpv` | The mount point on the primary NFS where OIG persistent volume is exported.|
|**OIG\_STANDBY\_SHARE** | `$DR_STANDBY_NFS_EXPORT/oigpv` | The mount point on the standby NFS where OIG persistent volume is exported.|
|**OIG\_LOCAL\_SHARE** | `/local_volumes/oigpv` |The local directory where OIG\_SHARE is mounted. It is used by the deletion procedure.|
|**OIG\_SERVER\_INITIAL** | `2` | The number of OIM/SOA Managed Servers you want to start for normal running. You will need at least two servers for high availability.|
|**OIG\_PRIMARY\_DB\_SCAN** | `dbscan.example.com` | The database scan address used by the primary grid infrastructure.|
|**OIG\_STANDBY\_DB\_SCAN** | `stbyscan.example.com` | The database scan address used by the standby grid infrastructure.|
|**OIG\_DB\_LISTENER** | `1521` | The database listener port.|
|**OIG\_PRIMARY\_DB\_SERVICE** | `edgigd.example.com` | The database service that connects to the primary database where the OIG schemas are located.|
|**OIG\_STANDBY\_DB\_SERVICE** | `edgigd.example.com` | The database service that connects to the standby database where the OIG schemas are located.|
|**DR\_OIG\_MINS** | `720`| The frequency in minutes to run the PV sync job.|
|**DR\_CREATE\_OIG\_JOB** | `true` | Determines whether or not to create a cron job to sync the PVs.  Set to false if using hardware synchronization.|


### OIRI Parameters
These parameters determine how OIRI is provisioned and configured.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**OIRINS** | `oirins` | The Kubernetes namespace used to hold the OIRI objects.|
|**DINGNS** | `dingns` | The Kubernetes namespace used to hold the OIRI DING objects.|
|**OIRI\_PRIMARY\_SHARE** |`$DR_PRIMARY_NFS_EXPORT/oiripv`| The mount point on the primary NFS where OIRI persistent volume is exported.|
|**OIRI\_STANDBY\_SHARE** |`$DR_STANDBY_NFS_EXPORT/oiripv`| The mount point on the primary NFS where OIRI persistent volume is exported.|
|**OIRI\_LOCAL\_SHARE** |`/nfs_volumes/oiripv`| The local directory where the local OIRI_SHARE is mounted. It is used by the deletion procedure.|
|**OIRI\_PRIMARY\_DING\_SHARE** |`$DR_PRIMARY_NFS_EXPORT/dingpv`|  The mount point on primary NFS where OIRI DING persistent volume is exported.|
|**OIRI\_STANDBY\_DING\_SHARE** |`$DR_STANDBY_NFS_EXPORT/dingpv`|  The mount point on standby NFS where OIRI DING persistent volume is exported.|
|**OIRI\_DING\_LOCAL\_SHARE** |`/nfs_volumes/dingpv`| The local directory where local DING_SHARE is mounted. It is used by the deletion procedure.|
|**OIRI\_PRIMARY\_WORK\_SHARE** |`$DR_PRIMARY_NFS_EXPORT/workpv`|  The mount point on primary NFS where OIRI work persistent volume is exported.|
|**OIRI\_STANDBY\_WORK\_SHARE** |`$DR_STANDBY_NFS_EXPORT/workpv`|  The mount point on standby NFS where OIRI work persistent volume is exported.|
|**OIRI\_PRIMARY\_DB\_SCAN** |`dbscan.example.com`| The database SCAN address of the primary grid infrastructure.|
|**OIRI\_STANDBY\_DB\_SCAN** |`stbyscan.example.com`| The database SCAN address of the standby grid infrastructure.|
|**OIRI\_DB\_LISTENER** |`1521`| The database listener port.|
|**OIRI\_DB\_PRIMARY\_SERVICE** |`edgoiri.example.com`| The database service that connects to the primary database where the OIRI schemas are located.|
|**OIRI\_STANDBY\_DB\_SERVICE** | `edgoiri.example.com` | The database service that connects to the standby database where the OIRI schemas are located.|
|**OIRI\_PRIMARY\_K8CONFIG** |`primary_k8config`| The name to call the Kubernetes configfile for the primary Kubernetes cluster|
|**OIRI\_STANDBY\_K8CONFIG** |`standby_k8config`| The name to call the Kubernetes configfile for the standby Kubernetes cluster|
|**OIRI\_PRIMARY\_K8CA** |`primary_ca.crt`| The name to call the Kubernetes certificate authority for the primary Kubernetes cluster.|
|**OIRI\_STANDBY\_K8CA** |`standby_ca.crt`| The name to call the Kubernetes certificate authority for the standby Kubernetes cluster.|
|**OIRI\_PRIMARY\_K8** |`10.0.0.5:6443`| Host and port of the Kubernetes primary cluster (obtained from kubeconfig file).|
|**OIRI\_STANDBY\_K8** |`10.1.0.5:6443`| Host and port of the Kubernetes standby cluster (obtained from kubeconfig file).|
|**DR\_OIRI\_MINS** | `720`| The frequency in minutes to run the PV sync job.|
|**DR\_CREATE\_OIRI\_JOB** | `true` | Determines whether or not to create a cron job to sync the PVs.  Set to false if using hardware synchronization.|

### OAA Parameters
These parameters determine how OAA is provisioned and configured.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**OAANS** |`oaans`| The Kubernetes namespace used to hold the OAA objects.|
|**OAA\_MGT\_IMAGE** |`$REGISTRY/oaa-mgmt`| The OAA Management container image.|
|**OAAMGT\_VER** |`latest`| The OAA version.|
|**OAA\_PRIMARY\_CONFIG\_SHARE** |`$DR_PRIMARY_NFS_EXPORT/oaaconfigpv`| The mount point on primary NFS where OAA config persistent volume is exported.|
|**OAA\_STANDBY\_CONFIG\_SHARE** |`$DR_STANDBY_NFS_EXPORT/oaaconfigpv`| The mount point on standby NFS where OAA config persistent volume is exported.|
|**OAA\_PRIMARY\_CRED\_SHARE** |`$DR_PRIMARY_NFS_EXPORT/oaacredpv`| The mount point on the primary NFS where OAA credentials persistent volume is exported.|
|**OAA\_STANDBY\_CRED\_SHARE** |`$DR_STANDBY_NFS_EXPORT/oaacredpv`| The mount point on the standby NFS where OAA credentials persistent volume is exported.|
|**OAA\_PRIMARY\_LOG\_SHARE** |`$DR_PRIMARY_NFS_EXPORT/oaalogpv`| The mount point on the primary NFS where OAA logfiles persistent volume is exported.|
|**OAA\_PRIMARY\_VAULT\_SHARE** |`$DR_PRIMARY_NFS_EXPORT/oaavaultpv`| The mount point on the primary NFS where OAA vault persistent volume is exported.|
|**OAA\_STANDBY\_VAULT\_SHARE** |`$DR_STANDBY_NFS_EXPORT/oaavaultpv`| The mount point on the standby NFS where OAA vault persistent volume is exported.|
|**OAA\_STANDBY\_LOG\_SHARE** |`$DR_STANDBY_NFS_EXPORT/oaalogpv`| The mount point on the standby NFS where OAA logfiles persistent volume is exported.|
|**OAA\_LOCAL\_CONFIG\_SHARE** |`/nfs_volumes/oaaconfigpv`| The local directory where the local OAA_CONFIG_SHARE PV is mounted. It is used by the deletion procedure. |
|**OAA\_LOCAL\_CRED\_SHARE** |`/nfs_volumes/oaacredpv`| The local directory where the local OAA_CRED PV is mounted. It is used by the deletion procedure.|
|**OAA\_LOCAL\_LOG_SHARE** |`/nfs_volumes/oaalogpv`| The local directory where local OAA_LOG PV is mounted. It is used by the deletion procedure. |
|**OAA\_VAULT\_LOG_SHARE** |`/nfs_volumes/oaavaultpv`| The local directory where local OAA_VAULT PV is mounted. It is used by the deletion procedure. |
|**OAA\_PRIMARY\_DB\_SCAN** |`dbscan.example.com`| The database SCAN address of the primary grid infrastructure.|
|**OAA\_STANDBY\_DB\_SCAN** |`stbyscan.example.com`| The database SCAN address of the standby grid infrastructure.|
|**OAA\_DB\_LISTENER** |`1521`| The database listener port.|
|**OAA\_DB\_PRIMARY\_SERVICE** |`edgoaa.example.com`| The database service that connects to the primary database where the OAA schemas are located.|
|**OAA\_DB\_STANDBY\_SERVICE** |`edgoaa.example.com`| The database service that connects to the standby database where the OAA schemas are located.|
|**OAA\_VAULT\_TYPE** |`file or oci`| The type of vault to use: file system or OCI.|
|**OAA\_REPLICAS** |`2`| The number of OAA service pods to be created. For HA, the minimum number is two.|

