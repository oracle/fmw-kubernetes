# Automating the Identity and Access Management Enterprise Deployment

A number of sample scripts have been developed which allow you to deploy Oracle Identity and Access Management on Kubernetes. These scripts are provided as samples for you to use to develop your own applications.

You will need to ensure that you are using the April 2021 or later release of Identity and Access Management for this utility to work.

For more information refer to:

Enterprise Deployment Guide for Oracle Identity and Access Management in a Kubernetes Cluster (https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/index.html)

## Scope

### What the Scripts Will do

The scripts will deploy Oracle Unified Directory, Oracle Unified Directory Services Manager, Oracle Access Manager, Oracle Identity Governance and Oracle Identity Role Intelligence. They will integrate each of the products. You can choose to do one or more of the products.

The scripts will perform the following actions:

- Create any number of OUD instances.
- Extend OUD with OAM Object Classes.
- Seed the directory with users and groups required by Oracle Identity and Access Management.
- Create Indexes and ACIs in OUD.
- Set up replication agreements between different OUD instances.
- Create OUDSM.
- Setup Kubernetes Namespaces, Secrets and Persistent Volumes.
- Create Kubernetes NodePort Services as required.
- Create RCU schema objects for the product being installed.
- Deploy the WebLogic Kubernetes Operator.
- Create an Oracle Access Manager Domain with user defined Managed servers.
- Perform an initial configuration of the OAM domain.
- Perform Post configuration tasks.
- Removing the OAM Server from the default Coherence Cluster.
- Tune the oamDS Datasoure.
- Configuring the WebLogic Proxy Plugin.
- Configuring and Integrating OAM with LDAP.
- Add OAM Host Identifiers.
- Add OAM Policies.
- Configure ADF and OPSS.
- Setting the Initial Server count.
- Create an Oracle Identity Governance Domain.
- Integrate OIG and SOA.
- Integrate OIG with LDAP.
- Add Missing Object Classes.
- Integrate OIG and OAM.
- Configure SSO Integration in the Governance Domain.
- Enable OAM Notifications.
- Update the Match Attribute.
- Update the TAP Endpoint.
- Run Reconciliation Jobs.
- Optionally configure an Email Driver.
- Optionally switch notification preferences to Email.
- Enable Design Console Access.
- Add Load balancer Certificates to Oracle Key Store Service.
- Update OIG Intial Server count.
- Set up Business Intelligence Reporting links.
- Configuring OIM to use BIP.
- Storing the BI Credentials in OIG.
- Optionally Copy OHS Config/Webgate Files.


### What the Scripts Won&#39;t do

Whilst the scripts will perform the majority of the deployment, the scripts will not perform the following tasks:

- They will not deploy CRI-O, Docker, Kubernetes or Helm.
- They will not install a database or Oracle HTTP Server.
- They will not configure your load balancer.
- They will not copy your webgate artifacts to your Oracle HTTP Server.
- Tune the WebLogic Server.
- They will not configure Oracle Unified Messaging.
- They will not configure OAM One Time Pin (OTP) forgotten Password Functionality.
- Configure OIM Workflow Notifications to be sent via email.
- Set up OIM Challenge Questions.
- Provision Business Intelligence Publisher (BIP).
- They will not deploy reports into your Oracle BI Publisher environment, but they will set up the links to that environment.
- Enable BI Certification reports in OIG.

### Whats new in this release

This release adds support for:

- Using full container image names.
- Using a container registry.
- Automatic Pulling of container images from a container registry.
- WebLogic Kubernetes Operator 3.3.x
- Oracle Identity Role Intelligence.
- CRI-O and Docker based Container runtimes.
- Validated on OLCNE, OKE and Kubernetes.

## Key Concepts of the Scripts

To make things simple and easy to manage the scripts are based around two concepts:

- A response file with details of your environment.
- Template files which can easily be modified or added to as your needs warrant.

>Note: Provisioning scripts are re-enterant, if something fails it can be restarted at the point at which it failed.

## Installing the scripts

To install the scripts you need to clone them from github using the following commands:

```
$ mkdir /workdir/scripts

$ cd /workdir/scripts

$ git clone https://github.com/oracle/fmw-kubernetes.git

```

The scripts will now be available in /workdir/scripts/fmw-kubernetes/FMWKubernetesMAA/OracleEnterpriseDeploymentAutomation/OracleIdentityManagement

## Getting Started

Before starting, you need to edit the file `common/functions.sh` and set the value of SCRIPTDIR to the location of your Script home directory for example:

SCRIPTDIR=`/workdir/scripts`

## Creating a Response file

A sample response file has been created for you in the `responsefile` directory. You can either edit this file directly, or by running the shell script `start_here.sh` in the script home directory.

For example

./start\_here.sh

You can run the above script as many times as you like on the same file. Pressing enter on any response will leave the existing value in the file unchanged. This will create the file idm.rsp in the directory `responsefile`.

>Note: The file consists of key/value pairs there must be no spaces between the name of the key and its value, for example

Key=value

## Validating your environment

A script called `prereqchecks.sh` which exists in the script home directory can be run to check your environment, it is based on the response file you created above. It will perform several checks such as (but not limited to):

- Container images are available.
- NFS file shares have been created.
- Load balancers are reachable.

## Provisioning your environment

There are a number of provisioning scripts located in the script directory:

| **File** | **Purpose** | 
| --- | --- | 
|provision.sh | Umbrella script that invokes each of the following (which can be invoked manually) |
|provision_oud.sh | Deploy Oracle Unified Directory |
|provision_oudsm.sh | Deploy Oracle Unified Directory Services Manager |
|provision_operator.sh | Deploy WebLogic Operator for Kubernetes |
|provision_oam.sh | Deploy Oracle Access Manager |
|provision_oig.sh | Deploy Oracle Identity Governance |
|provision_oiri.sh | Deploy Oracle Identity Role Intelligence |

These scripts will use a working directory defined in the response file for temporary files. 

## Log Files

The provisioning scripts create log files for each product inside the working directory in a logs sub-directory. This directory will also contain the following two files:

`progressfile` – this file contains the last successfully executed step. Should you wish to restart the process at a different step then simply update this file.

`timings.log` – Used for informational purposes to show how much time was spent on each stage of the provisioning process.

## Files that you need to Keep

Once a provisioning run is completed that creates a domain there are files that you need to keep safely, these files are used to start and stop the domain as well as information on how the domain should be started. A copy of these files will be stored in the working directory under the sub-directory TO\_KEEP.

You also need to keep any Override files that you generate.

## After Installation/Configuration

As part of running the scripts a number of working files are created in the WORKDIR directroy prior to copying to the persistent volume in /u01/user_projects/workdir. Many of these files contain passwords needed for setup. These should be archived away after deployment.

The response file will also have passwords which need to be protected.


## Oracle HTTP server conf files

Each of the provisioning scripts will create sample files for configuring your Oracle HTTP server. These files will be generated and stored in the working directory under the sub-directory OHS.

## Utilities

In the script directory there is a sub-directory called `utils`. This directory contains some sample utilities you may find useful. Utilities for:

- Loading container images to each of the Kubernetes nodes.
- Deleting deployments.

## Reference – Response File

Below is a description of each of the parameters in the response file:

### Products to Deploy

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
| **INSTALL\_OUDSM** | true | Set to true to configure OUDSM |
| **INSTALL\_OUD** | true | Set to true to configure OUD |
| **INSTALL\_OAM** | true | Set to true to configure OAM |
| **INSTALL\_OIG** | true | Set to true to configure OIG |
| **INSTALL\_OIRI** | true | Set to true to configure OIRI |

### Control Parameters

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
| **USE\_REGISTRY** | false | Set to true to pull images from a container registry. |
| **IMAGE\_TYPE** | crio | Set to crio or docker depending on your container engine. |
| **IMAGE\_DIR** | /container/images | Location of where you downloaded your container images to use. Used by load\_images.sh |
| **LOCAL\_WORKDIR** | /workdir | Location where you wish your working directory to be created |
| **K8\_WORKDIR** | /u01/oracle/user\_projects/workdir | Location inside the Kubernetes containers where working files are copied to. |
| **K8\_WORKER\_HOST1** | K8worker1.example.com | Name of a Kubernetes worker node, used in generating OHS sample files |
| **K8\_WORKER\_HOST2** | K8worker2.example.com | Name of a Kubernetes worker node, used in generating OHS sample files |

### Registry Parameters
Only used if you are using a container registry.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
| **REGISTRY** | iad.ocir.io/mytenancy | Set to the location of your container registry. |
| **REG\_USER** | mytenancy/oracleidentitycloudservice/email@example.com | Set to your registry username |
| **REG\_PWD** | | Set to your registry password |
| **CREATE\_REGSECRET** | false| Set to true to create a registry secret to automatically pull images |

### Image Parameters
Used to specify the Container Images to be used. These can include registry prefixes if using a registry. Use the local/ prefix if using OLCNE, for example local/oracle/oud.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
| **OPER\_IMAGE** | ghcr.io/oracle/weblogic-kubernetes-operator | WebLogic Operator Image Name |
| **OUD\_IMAGE** | oracle/oud | OUD Image Name |
| **OUDSM\_IMAGE** | oracle//oudsm | OUDSM Image Name |
| **OAM\_IMAGE** | oracle/oam | OAM Image Name |
| **OIG\_IMAGE** | oracle/oig | OIG Image Name |
| **OIRI\_CLI\_IMAGE** | oracle/oiri-cli | OIRI CLI Image Name |
| **OIRI\_IMAGE** | oracle/oiri | OIRI Image Name |
| **OIRI\_UI\_IMAGE** | oracle/oiri-ui | OIRI UI Image Name |
| **OIRI\_DING\_IMAGE** | oracle/oiri-ding | OIRI DING Image Name |
| **OPER\_VER** | 3.3.0 | WebLogic Operator Version |
| **OUD\_VER** | 12.2.1.4.0-8-ol7-210715.1921 | OUD Version |
| **OUDSM\_VER** | 12.2.1.4.0-8-ol7-210721.0755 | OUDSM Version |
| **OAM\_VER** | 12.2.1.4.0-8-ol7-210721.0755 | OAM Version |
| **OIG\_VER** | 12.2.1.4.0-8-ol7-210721.0748 | OIG Version |
| **OIRICLI\_VER** | 12.2.1.4.211126 | OIRI CLI Version |
| **OIRI\_VER** | 12.2.1.4.211126 | OIRI Version |
| **OIRIUI\_VER** | 12.2.1.4.211126 | OIRI UI Version |
| **OIRIDING\_VER** | 12.2.1.4.211126 | OIRI DING Version |

### Product Namespaces
Kubernetes Namespaces to use for each product.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
| **OAMNS** | oamns | Kubernetes namespace used to hold OAM objects |
| **OUDNS** | oudns | Kubernetes namespace used to hold OUD objects |
| **OIGNS** | oigns | Kubernetes namespace used to hold OIG objects |
| **OPERNS** | opns | Kubernetes namespace used to hold WebLogic Kubernetes Operator |
| **OIRINS** | oirins | Kubernetes namespace used to hold OIRI objects |
| **DINGNS** | dingns | Kubernetes namespace used to hold OIRI DING objects |

### Generic Parameters

Parameters used to control how all products will be deployed.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
| **PVSERVER** | 10.32.212.48 | IP Address of your NFS server, used for persistent volumes. >Note: Use an IP address not a name. |
| **IAM\_PVS** | /export/IAMPVS | IAMPV mount path in the NFS |
| **PV\_MOUNT** | /u01/oracle/user\_projects | Where to mount your PV inside the Kubernetes container. Recommended not to change this value. |

### OUD Parameters

Parameters used to determine how Oracle Unified Directory will be deployed.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
| **OUD\_SHARE** | /export/IAMPVS/OUDPV | Mount point on NFS where OUD persistent volume will be mounted. |
| **OUD\_CONFIG\_SHARE** | /export/IAMPVS/OUDCONFIGPV | Mount point on NFS where OUD Config persistent volume will be mounted. |
| **OUD\_LOCAL\_SHARE** | /nfs\_volumes/oudconfigpv | Local directory where OUD\_CONFIG\_SHARE is mounted. Used to hold seed files. |
| **OUD\_LOCAL\_PVSHARE** | /nfs\_volumes/oudpv | Local directory where OUD\_SHARE is mounted. Used to for deletion. |
| **OUD\_ADMIN\_USER** | cn=oudadmin | Name of OUD administrative user |
| **OUD\_ADMIN\_PWD** | mypassword | Password you wish to use for OUD administrative user. |
| **OUD\_POD\_PREFIX** | edg | Prefix to be used for OUD pods |
| **OUD\_REPLICAS** | 1 | Number of OUD replicas to create. If you require 2 OUD instances set this to 1. The value is in addition to the primary instance. |
| **OUD\_SEARCHBASE** | dc=example,dc=com | OUD Search base. |
| **OUD\_REGION** | us | The OUD Region to use should be the first part of the Searchbase without the dc= |
| **OUD\_GROUP\_SEARCHBASE** | cn= Groups, dc=example,dc=com | Where Groups are stored in the LDAP directory |
| **OUD\_USER\_SEARCHBASE** | cn=Users, dc=example,dc=com | Where Users are stored in the LDAP directory |
| **OUD\_RESERVE\_SEARCHBASE** | cn=Reserve, dc=example,dc=com | Where Reservations are stored in the LDAP directory |
| **OUD\_SYSTEMIDS** | systemids | Special directory tree inside OUD Searchbase to store system users which will not be managed via OIG |
| **OUD\_OAMADMIN\_USER** | oamadmin | Name of the user you wish to create for OAM Administration tasks. |
| **OUD\_OIGADMIN\_GRP** | OIMAdministrators | Name of the group you wish to use for OIG administration tasks. |
| **OUD\_OAMADMIN\_GRP** | OAMAdministrators | Name of the group you wish to use for OAM administration tasks. |
| **OUD\_WLSADMIN\_GRP** | WLSAdministrators | Name of the group you wish to use for WebLogic administration tasks. |
| **OUD\_OAMLDAP\_USER** | oamLDAP | Name of the user you will use to connect your OAM domain to LDAP for user validation. |
| **OUD\_OIGLDAP\_USER** | oimLDAP | Name of the user you will use to connect your OIG domain to LDAP for integration. This is a read/write user. |
| **OUD\_WLSADMIN\_USER** | weblogic\_iam | Name of a user you wish to use for logging in to the WebLogic Admin console and FMW Control |
| **OUD\_XELSYSADM\_USER** | xelsysadm | Name of the user you wish to create to administer OIG |
| **OUD\_USER\_PWD** | Mypassword1 | Password to assign to all users being created in LDAP. <br /> >Note: This value must have at least one Capital letter and one number and be at least 8 characters long. |
| **OUD\_PWD\_EXPIRY** | 2022-01-02 | Date when the passwords for the users you are creating will be expired. |
| **OUD\_CREATE\_NODEPORT** | true | Set to true if you wish to create NodePort services for OUD, used if you will be interacting with OUD from outside of the Kubernetes cluster. |




### WebLogic Operator for Kubernetes Parameters

Parameters used to determine how Oracle WebLogic Operator for Kubernetes will be deployed.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
| **OPER\_ACT** | operadmin | Kubernetes service account to create for use by the WebLogic Kubernetes operator |

### OUDSM Parameters

Parameters used to determine how Oracle Directory Services Manager will be deployed.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
| **OUDSM\_USER** | weblogic | Name of the administration user you wish to use for the WebLogic domain which is created when installing OUDSM |
| **OUDSM\_PWD** | Mypassword1 | Password you wish to use for OUDSM\_USER |
| **OUDSM\_SHARE** | /export/IAMPVS/OUDSMPV | Mount path inside of your NFS for use as your OUDSM Persistent volume. |
| **OUDSM\_LOCAL\_SHARE** | /nfs\_volumes/oudsmpv | Local directory where OUDSM\_SHARE is mounted, used by deletion procedure. |


### OAM Parameters

Parameters used to determine how Oracle Access Manager will be deployed.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
| **OAM\_SHARE** | /export/IAMPVS/OAMPV | Mount path inside of your NFS for use as your OAM Persistent volume. |
| **OAM\_LOCAL\_SHARE** | /nfs\_volumes/oampv | Local directory where OAM\_SHARE is mounted, used by deletion procedure. |
| **OAM\_SERVER\_COUNT** | 5 | Number of OAM Servers to configure, this value should be more than you ever expect to use. |
| **OAM\_SERVER\_INITIAL** | 2 | Number of OAM Managed servers you wish to start for normal running, you need at least 2 for High availability. |
| **OAM\_DB\_SCAN** | dbscan.example.com | Database SCAN address to be used your Grid Infrastructure |
| **OAM\_DB\_LISTENER** | 1521 | Database listener port |
| **OAM\_DB\_SERVICE** | iadedg.example.com | Database service which connects to the database you wish to use for storing your OAM schemas |
| **OAM\_RCU\_PREFIX** | IADEDG | RCU Prefix to use for OAM Schemas |
| **OAM\_DB\_SYS\_PWD** | DBSysPassword | The SYS password of your OAM database. |
| **OAM\_SCHEMA\_PWD** | SchemaPassword | Password to use for the OAM schemas that will get created. If you are using special characters you may need to escape them with \ e.g. Password\\#|
| **OAM\_WEBLOGIC\_USER** | weblogic | OAM WebLogic Administration User |
| **OAM\_WEBLOGIC\_PWD** | MyPassword1 | Password to be used for OAM\_WEBLOGIC\_USER |
| **OAM\_DOMAIN\_NAME** | accessdomain | Name of your OAM domain you wish to create. |
| **OAM\_LOGIN\_LBR\_HOST** | login.example.com | The Load balancer name you will use for logging in. |
| **OAM\_LOGIN\_LBR\_PORT** | 443 | The Load balancer port you will be used for logging in. |
| **OAM\_LOGIN\_LBR\_PROTOCOL** | https | The protocol of the Load Balancer Port you use for logging in. |
| **OAM\_ADMIN\_LBR\_HOST** | iadadmin.example.com | The Load balancer name you will use for accessing OAM Administrative functions. |
| **OAM\_ADMIN\_LBR\_PORT** | 80 | The Load balancer Port you will use for accessing OAM Administrative functions. |
| **OAM\_COOKIE\_DOMAIN** | .example.com | The OAM cookie domain, this will generally be similar to your search base. Ensure you have a . at the beginning. |
| **OAM\_OIG\_INTEG** | true | Set to true if OAM is integrated with OIG. |
| **OAM\_OAP\_HOST** | K8worker1.example.com.com | The name of one of the Kubernetes worker nodes used for OAP calls. |
| **OAMSERVER\_JAVA\_PARAMS** | &quot;-Xms2048m -Xmx8192m &quot; | Java Memory parameters to use for OAM Managed servers |

### OIG Parameters

Parameters used to determine how Oracle Identity Governance will be deployed.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
| **CONNECTOR\_DIR** | /workdir/OIG/connectors/ | Location on the file system where you have downloaded and extracted the OUD connector bundle |
| **OIG\_SHARE** | /export/IAMPVS/OIGPV | Mount path inside of your NFS for use as your OIG Persistent volume. |
| **OIG\_LOCAL\_SHARE** | /nfs\_volumes/oigpv | Local directory where OIG\_SHARE is mounted, used by deletion procedure. |
| **OIG\_SERVER\_COUNT** | 5 | Number of OIM/SOA Servers to configure, this value should be more than you ever expect to use. |
| **OIG\_SERVER\_INITIAL** | 2 | Number of OIM/SOA Managed servers you wish to start for normal running, you need at least 2 for High availability. |
| **OIG\_DOMAIN\_NAME** | governancedomain | Name of the OIG domain you wish to create. |
| **OIG\_DB\_SCAN** | dbscan.example.com | Database SCAN address to be used your Grid Infrastructure |
| **OIG\_DB\_LISTENER** | 1521 | Database listener port |
| **OIG\_DB\_SERVICE** | oim\_s.example.com | Database service which connects to the database you wish to use for storing your OIG schemas |
| **OIG\_RCU\_PREFIX** | IGDEDG | RCU Prefix to use for OIG Schemas |
| **OIG\_DB\_SYS\_PWD** | MySysPassword | The SYS password of your OIG database. |
| **OIG\_SCHEMA\_PWD** | MySchemPassword | Password to use for the OIG schemas that will get created. If you are using special characters you may need to escape them with \ e.g. Password\\#|
| **OIG\_WEBLOGIC\_USER** | weblogic | OIG WebLogic Administration User |
| **OIG\_WEBLOGIC\_PWD** | MyPassword | Password you wish to use for OIG\_WEBLOGIC\_PWD |
| **OIG\_ADMIN\_LBR\_HOST** | igdadmin.example.com | The Load balancer name you will use for accessing OIG Administrative functions. |
| **OIG\_ADMIN\_LBR\_PORT** | 80 | The Load balancer Port you will use for accessing OIG Administrative functions. |
| **OIG\_LBR\_HOST** | prov.example.com | The Load balancer name you will use for accessing OIG identity console. |
| **OIG\_LBR\_PORT** | 443 | The Load balancer Port you will use for accessing OIG Identity Console |
| **OIG\_LBR\_PROTOCOL** | https | The Load balancer Protocol you will use for accessing OIG Identity Console |
| **OIG\_LBR\_INT\_HOST** | igdinternal.example.com | The Load balancer name you will use for accessing OIG Internal callbacks |
| **OIG\_LBR\_INT\_PORT** | 7777 | The Load balancer Port you will use for accessing OIG Internal callbacks |
| **OIG\_LBR\_INT\_PROTOCOL** | http | The Load balancer protocol you will use for accessing OIG Internal callbacks |
| **OIG\_ENABLE\_T3** | false | Set to true to configure Design Console Access |
| **OIG\_BI\_INTEG** | true | Set to true to configure BIP integration. |
| **OIG\_BI\_HOST** | bi.example.com | The Load balancer name you will use for accessing BI Publisher |
| **OIG\_BI\_PORT** | 443 | The Load balancer Port you will use for accessing BI Publisher |
| **OIG\_BI\_PROTOCOL** | https | The Load balancer protocol you will use for accessing BI Publisher |
| **OIG\_BI\_USER** | idm\_report | The BI user you wish to use for running reports in the BIP deployment |
| **OIG\_BI\_USER\_PWD** | BIPassword | The Password of the OIG\_BI\_USER |
| **OIMSERVER\_JAVA\_PARAMS** | &quot;-Xms4096m -Xmx8192m &quot; | The Memory parameters to use for the oim\_servers |
| **OIG\_EMAIL\_CREATE** | true | If Set to true, then OIG will be configured for Email Notifications |
| **OIG\_EMAIL\_SERVER** | sendmail.example.com; | The name of your SMTP email server |
| **OIG\_EMAIL\_PORT** | 25 | The port of your SMTP server valid values are None or TLS|
| **OIG\_EMAIL\_SECURITY**  | None | The security mode of your SMTP server valid values are None, TLS and SSL |
| **OIG\_EMAIL\_ADDRESS** | myemail.example.com | The user used to connect to the SMTP server, if one is required |
| **OIG\_EMAIL\_PWD**  |  | The password of your SMTP server |
| **OIG\_EMAIL\_FROM\_ADDRESS** | from@example.com | The From email address used when emails are sent |
| **OIG\_EMAIL\_REPLY\_ADDRESS** | noreplies@example.com | The reply to email address of emails sent |

### OIRI Parameters

Parameters used to determine how Oracle Identity Role Intelligence will be deployed.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
| **OIRI\_REPLICAS** | 2 | Number of OIRI Servers to start |
| **OIRI\_UI\_REPLICAS** | 2 | Number of OIRI UI Servers to start |
| **OIRI\_SPARK\_REPLICAS** | 2 | Number of OIRI DING Servers to start |
| **OIRI\_SHARE** | /export/IAMPVS/oiripv | Mount path inside of your NFS for use as your OIRI Persistent volume. |
| **OIRI\_LOCAL\_SHARE** | /nfs_volumes/oiripv | Local directory where OIRI\_SHARE is mounted, used by deletion procedure. |
| **OIRI\_SHARE\_SIZE** | 10Gi | Size of the OIRI Persistent Volume |
| **OIRI\_DING\_SHARE** | /export/IAMPVS/dingpv | Mount path inside of your NFS for use as your OIRI DING Persistent volume. |
| **OIRI\_DING\_LOCAL\_SHARE** | /nfs_volumes/dingpv| Local directory where OIRI\_DING\_SHARE is mounted, used by deletion procedure. |
| **OIRI\_DING\_SHARE\_SIZE** | 10Gi | Size of the OIRI DING Persistent Volume |
| **OIRI\_WORK\_SHARE** | /export/IAMPVS/workpv | Mount path inside of your NFS for use as your OIRI Work Persistent volume. |
| **OIRI\_DB\_SCAN** | dbscan.example.com | Database SCAN address of your Grid Infrastructure |
| **OIRI\_DB\_LISTENER** | 1521 | Database listener port |
| **OIRI\_DB\_SERVICE** | oiri\_s.example.com | Database service which connects to the database you wish to use for storing your OIG schemas |
| **OIRI\_RCU\_PREFIX** | ORIEG | RCU Prefix to use for OIG Schemas |
| **OIRI\_DB\_SYS\_PWD** | MySysPassword | The SYS password of your OIG database. |
| **OIRI\_SCHEMA\_PWD** | MySchemPassword | Password to use for the OIG schemas that will get created. If you are using special characters you may need to escape them with \ e.g. Password\\#|
| **OIRI\_KEYSTORE\_PWD** | MyKeystore_Password100 | Password to use for the ORI Keystore |
| **OIRI\_ENG\_GROUP** | OrclOIRIRoleEngineer | OIG OIRI Group Name - DO NOT CHANGE | |
| **OIRI\_ENG\_USER** | oiri | User to be created in OIG for UI Login |
| **OIR\I_ENG\_PWD** | MyPassword1 | Password of the OIRI\_ENG\_USER |
| **OIRI\_SERVICE\_USER** | oirisvc | OIG OIR Service Account User |
| **OIRI\_SERVICE\_PWD** | MyPassword1 | Password of the OIRI\SERVICE\_USER |
| **OIRI\_OIG\_URL** | http://$OIG_DOMAIN_NAME-cluster-oim-cluster.$OIGNS.svc.cluster.local:14000 | URL of your OIG. If internal to the Kubernetes cluster user the Kubernetes Service Name as shown in the sample value, If external use the IGDINTERNAL URL |
| **OIRI\_LOAD\_DATA** | true | Perform an Initial Data Load from your OIG Database as defined in the OIG Parameters. |

### OHS Parameters

Parameters used by Oracle HTTP Server. Used to create sample OHS configuration files.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
| **OHS\_HOST1** | webhost1.example.com | The host name of your Oracle HTTP Server |
| **OHS\_HOST2** | webhost2.example.com | The host name of your secondary Oracle HTTP Server |
| **UPDATE\_OHS** | true | Set to true if you wish the OHS configuration to be automatically copied to your OHS servers. Passwordless SCP must be enabled |
| **COPY\_WG\_FILES** | true | Set to true if you wish the Webgate artifacts to be automatically copied to your OHS servers. Passwordless SCP must be enabled |
| **OHS\_PORT** | 7777 | Set to the OHS listen Port |
| **OHS\_DOMAIN** | /u02/private/oracle/config/domains/ohsDomain | Set to location of your OHS domain on OHS\_HOST1 and OHS\_HOST2 |
| **OHS1\_NAME** | ohs1 | Set to the component name of your OHS instance on OHS\_HOST1 |
| **OHS2\_NAME** | ohs2 | Set to the component name of your OHS instance on OHS\_HOST2 |

### Port Mappings

Parameters used to determine what Ports are used in the deployment.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
| **OUD\_LDAP\_K8** | 31389 | Port to use for OUD LDAP requests. >Note: this must be in the Kubernetes service port range. |
| **OUD\_LDAPS\_K8** | 31636 | Port to use for OUD LDAPS requests. >Note: this must be in the Kubernetes service port range. |
| **OUDSM\_SERVICE\_PORT** | 30901 | Port to use for OUDSM requests. >Note: this must be in the Kubernetes service port range. |
| **OAM\_ADMIN\_PORT** | 7001 | Internal WebLogic Administration port to use for the OAM domain. This is available only in the Kubernetes cluster. |
| **OAM\_ADMIN\_K8** | 30701 | External Port to use for the OAM Administration server requests. >Note: this must be in the Kubernetes service port range. |
| **OAM\_OAM\_K8** | 30410 | External Port to use for the OAM Managed server requests. >Note: this must be in the Kubernetes service port range. |
| **OAM\_POLICY\_K8** | 30510 | External Port to use for the OAM Policy server requests. >Note: this must be in the Kubernetes service port range. |
| **OAM\_OAP\_SERVICE\_PORT** | 30540 | External Port to use for the OAP server requests. This is for legacy webgates and is optional. >Note: this must be in the Kubernetes service port range. |
| **OIG\_SOA\_PORT\_K8** | 30801 | External Port to use for the SOA Managed server requests. >Note: this must be in the Kubernetes service port range. |
| **OAM\_OAP\_PORT** | 5575 | Internal Kubernetes port used for OAM requests. |
| **OIG\_ADMIN\_PORT** | 7101 | Internal port used for the OIG WebLogic Administration server. |
| **OIG\_ADMIN\_K8** | 30711 | External Port to use for the OIG Administration server requests. >Note: this must be in the Kubernetes service port range. |
| **OIG\_OIM\_PORT\_K8** | 30140 | External Port to use for the OIM Managed server requests. >Note: this must be in the Kubernetes service port range. |
| **OIG\_OIM\_T3\_PORT\_K8** | 30142 | External Port to use for the OIM Managed server T3 requests. >Note: this must be in the Kubernetes service port range. |
| **OHS\_PORT** | 7777 | The HTTP Server listen address. |


## Components of the Deployment Scripts

For reference purposes this section includes the name and function of all the objects making up the deployment scripts.

| **Name** | **Location** | **Function** |
| --- | --- | --- |
| **idm.rsp** | responsefile | Contains details of the target environment. Needs to be updated for each deployment. |
| **start\_here.sh** | | Populates the response file |
| **prereqchecks.sh** | | Check the environment prior to provisioning |
| **provision.sh** | | Provision everything |
| **provision\_oud.sh** | | Install/configure OUD |
| **provision\_oudsm.sh** | | Install/configure OUDSM |
| **provision\_oam.sh** | | Install/configure OAM |
| **provision\_oig.sh** | | Install/configure OIG |
| **provision\_oiri.sh** | | Install/configure OIRI |
| **functions.sh** | common | Common functions/procedures used by all provisioning scripts. |
| **oud\_functions.sh** | common | functions/procedures used by OUD and OUDSM provisioning scripts. |
| **oam\_functions.sh** | common | functions/procedures used by oam provisioning scripts. |
| **oig\_functions.sh** | common | Common functions/procedures used by OIG provisioning scripts. |
| **oiri\_functions.sh** | common | Common functions/procedures used by OIRI provisioning scripts. |
| **base.ldif** | templates/oud | Used to seed OUD with users and groups |
| **99-user.ldif** | templates/oud | Used to seed OUD schema changes. |
| **oud\_nodeport.yaml** | templates/oud | Template to create OUD NodePort services for Kubernetes |
| **override\_oud.yaml** | templates/oud | OUD Helm override template file. |
| **oudsm\_nodeport.yaml** | templates/oudsm | Template to create OUDSM NodePort services for Kubernetes |
| **override\_oudsm.yaml** | templates/oudsm | OUD Helm override template file. |
| **add\_admin\_roles.py** | templates/oam | Template to add LDAP Groups to WebLogic Admin Role |
| **configoam.props** | templates/oam | Template property file for running idmConfigTool -configOAM |
| **runidmConfigTool.sh** | templates/oam | Template file to run idmConfigTool in container |
| **fix\_gridlink.sh** | templates/oam | Template file to GridLink Enable Datasources |
| **oamconfig\_modify\_template.xml** | templates/oam | Template file to perform initial OAM setup |
| **oam\_nodeport.yaml** | templates/oam | Template file to create OAM Managed server NodePort service |
| **oap\_clusterip.yaml** | templates/oam | Template file to create OAM OAP internal Managed server NodePort service |
| **oap\_nodeport.yaml** | templates/oam | Template file to create OAM OAP external Managed server NodePort service |
| **policy\_nodeport.yaml** | templates/oam | Template file to create Policy Manager Managed server NodePort service |
| **resource\_list.txt** | templates/oam | List of resources to add to OAM IAMSuite Resource list |
| **set\_weblogic\_plugin.py** | templates/oam | Template file to enable WebLogic plug in in the domain |
| **create\_wg.sh** | templates/oam | Template file to manually create Webgate Agent |
| **Webgate\_IDM.xml** | templates/oam | Template property file to manually create Webgate Agent |
| **config\_adf\_security.py** | templates/oam | Template file to create sso partner app |
| **oamDomain.sedfile** | templates/oam | Template sed file to exit domain.yaml |
| **oamSetUserOverrides.sh** | templates/oam | Template setUserOverrides.sh file |
| **remove\_coherence.py** | templates/oam | Template file to remove OAM from default coherence cluster |
| **update\_oamds.py** | templates/oam | Template file to update the OAMDS data source. |
| **login\_vh.conf** | templates/oam | Template file to create sample OHS Config |
| **iadadmin\_vh.conf** | templates/oam | Template file to create sample OHS Config |
| **create\_admin\_roles.py** | templates/oig | Template to assign LDAP Groups to WebLogic administration role |
| **create\_oud\_authenticator.py** | templates/oig | Template file to create OUD Authenticator |
| **get\_passphrase.sh** | templates/oig | Template file to obtain global passphrase from OAM |
| **get\_passphrase.py** | templates/oig | Template file to obtain OAM Global passphrase |
| **oam\_integration.sh** | templates/oig | Template file to run OIGOAMIntegration.sh -configureSSOIntegration |
| **oigSetUserOverrides.sh** | templates/oig | Template setUserOverrides.sh file |
| **soa\_nodeport.yaml** | templates/oig | Template file to create SOA external Managed server NodePort service |
| **oim\_nodeport.yaml** | templates/oig | Template file to create OIM external Managed server NodePort service |
| **add\_object\_classes.sh** | templates/oig | Template file to run IGOAMIntegration.sh -addMissingObjectClasses |
| **createWLSAuthenticators.sh** | templates/oig | Template file to run OIGOAMIntegration.sh -configureWLSAuthnProviders |
| **oam\_notifications.sh** | templates/oig | Template file to run OIGOAMIntegration.sh -enableOAMSessionDeletion |
| **config\_connector.sh** | templates/oig | Template file to run OIGOAMIntegration.sh -configureLDAPConnector |
| **create\_oim\_auth.sh** | templates/oig | Template file to run OIGOAMIntegration.sh -configureWLSAuthnProviders |
| **runJob.sh** | templates/oig | Template shell script to run the reconciliation jobs. |
| **runJob.java** | templates/oig | Java Script to run Reconciliation jobs |
| **lib** | templates/oig | OIM Libraries required by runJob.java |
| **update\_soa.py** | templates/oig | Template script to update SOA URLS |
| **oamoig.sedfile** | templates/oig | Sedfile to create OIGOAMIntegration property files |
| **autn.sedfile** | templates/oig | Supplementary Sedfile to create OIGOAMIntegration property files |
| **create\_oigoam\_files.sh** | templates/oig | Template script to generate OIGOAMIntegration property files |
| **fix\_gridlink.sh** | templates/oig | Template to enable gridlink on data sources |
| **update\_match\_attr.sh** | templates/oig | Template script to update Match Attribute |
| **oigDomain.sedfile** | templates/oig | Template script to update domain\_soa\_oim.yaml |
| **update\_mds.py** | templates/oig | Template file to update MDS datasource |
| **set\_weblogic\_plugin.py** | templates/oig | Template file to set WebLogic Plugin |
| **update\_bi.py** | templates/oig | Template file to enable BI integration |
| **igdinternal\_vh.conf** | templates/oig | Template file to create sample OHS Config |
| **igdadmin\_vh.conf** | templates/oig | Template file to create sample OHS Config |
| **prov\_vh.conf** | templates/oig | Template file to create sample OHS Config |
| **createAdminUser.java** | templates/oiri | Template file to create OIRI Users in OIG |
| **createAdminUser.sh** | templates/oiri | Template file to create Compile and run createAdminUser.java |
| **setCompliance.java** | templates/oiri | Template file to place OIG into Compliance Mode |
| **setCompliance.sh** | templates/oiri | Template file to create Compile and run setCompliance.java |
| **oiri-cli.yaml** | templates/oiri | Template file to start OIRI CLI |
| **ding-cli.yaml** | templates/oiri | Template file to start OIRI DING CLI |
| **oiri_nodeport.yaml** | templates/oiri | Template file to create OIRI Node Port Service |
| **oiriui_nodeport.yaml** | templates/oiri | Template file to create OIRI UI Node Port Service |
| **ohs1.conf** | templates/oiri | Template file to create sample OHS Config |
| **ohs2.conf** | templates/oiri | Template file to create sample OHS Config |
| **delete\_image.sh** | utils | Delete a container image from Kubernetes Worker hosts |
| **delete\_oam.sh** | utils | Delete OAM deployment |
| **delete\_oig.sh** | utils | Delete OIG deployment |
| **delete\_operator.sh** | utils | Delete WebLogic Kubernetes Operator deployment |
| **delete\_oud.sh** | utils | Delete OUD deployment |
| **delete\_oudsm.sh** | utils | Delete OUDSM deployment |
| **delete\_oiri.sh** | utils | Delete OIRI deployment |
| **load\_images.sh** | utils | Load container image onto each Kubernetes worker host | 
