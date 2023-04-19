# Automating the Identity and Access Management Enterprise Deployment

A number of sample scripts have been developed which allow you to deploy Oracle Identity and Access Management on Kubernetes. These scripts are provided as samples for you to use to develop your own applications.

You must ensure that you are using the April 2023 or later release of Identity and Access Management for this utility to work.

The scripts can be run from any host which has access to your Kubernetes cluster. 

If you wish the scripts to automatically copy files to your Oracle HTTP Servers then you must have passwordless ssh set up from the deployment host to each of your webhosts.

These scripts are provided as examples and can be customized as desired.

## Obtaining the Scripts

The automation scripts are available for download from GitHub.

To obtain the scripts, use the following command:

```
git clone https://github.com/oracle/fmw-kubernetes.git
```

The scripts appear in the following directory:

```
fmw-kubernetes/FMWKubernetesMAA/OracleEnterpriseDeploymentAutomation/OracleIdentityManagement
```

Move these template scripts to your working directory. For example:

```
cp -R fmw-kubernetes/FMWKubernetesMAA/OracleEnterpriseDeploymentAutomation/OracleIdentityManagement/* /workdir/scripts
```

If you are provisioning Oracle Identity Governance you must also Download the Oracle connector Bundle for OUD and extract it to a location which is accessible by the provisioning scripts.  For example, /workdir/connectors/OID-12.2.1.3.0.    The connector directory name must start with OID-12.2.1.

## Scope
This section lists the actions that the scripts perform as part of the deployment process. It also lists the tasks the scripts do not perform.

### What the Scripts Will do

The scripts will deploy Oracle Unified Directory (OUD), Oracle Access Manager (OAM), and Oracle Identity Governance (OIG). They will integrate each of the products. You can choose to integrate one or more products.

The scripts perform the following actions:

* Create an Ingress controller as described in [Creating the Ingress Controller](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-ingress-controller.html).
* Create an Elastic Search deployment as described in [Installing the Logging and Visualization Software](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-monitoring-and-visualization-software.html#GUID-CB3E079B-A17C-4A04-A727-889511325093).
* Create a Prometheus and Grafana installation as described in [Installing the Monitoring Software] (https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-monitoring-and-visualization-software.html#GUID-865DFA94-47EA-4B14-AE2D-FC5B75F49746).
* Install and configure Oracle HTTP Server as described in [Installing and Configuring Oracle HTTP Server](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-http-server.html#GUID-6D1AC6B0-EA4B-4413-AD6D-B21A30C3C441).
* Deploy and configure Oracle WebGate as described in [Configuring Single Sign-On for an Enterprise Deployment](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/configuring-single-sign-enterprise-deployment.html#GUID-10906355-241B-4B74-B8A9-39721E1F6CA0).
* Create any number of OUD instances as described in [Configuring Oracle Unified Directory](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-unified-directory.html). 
* Extend OUD with OAM object classes as described in [Creating the Schema Extensions File](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-unified-directory.html#GUID-C064336F-E112-4F8A-AF32-3CC9E9D363DC).
* Seed the directory with users and groups required by Oracle Identity and Access Management as described in [Creating the Seeding File](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-unified-directory.html#GUID-71732A8A-6353-41EF-AA58-CDE65D95B17A).
* Create indexes and ACI’s in OUD as described in [Creating OUD Containers](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-unified-directory.html#GUID-EEC7A9AB-3BA8-4558-9A81-3F64539B0731).
* Set up replication agreements between different OUD instances.
* Create OUDSM as described in [Installing and Configuring Oracle Unified Directory Service Manager](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-unified-directory.html#GUID-260F2B41-DE57-46B8-B63A-A1B0DE639AAD)
* Setup Kubernetes Namespaces, Secrets, and Persistent Volumes.
* Create Kubernetes NodePort Services as required.
* Create the RCU schema objects for the product being installed.
* Deploy the WebLogic Kubernetes Operator as described in [Installing the WebLogic Kubernetes Operator](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-weblogic-kubernetes-operator.html#GUID-C9D2A88B-9A25-4746-97F0-2ECA79D1870E). 
* Create an Oracle Access Manager Domain with user defined Managed Servers as described in [Creating the Access Domain](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-access-manager.html#GUID-FF3351D2-E799-42CE-80DB-C716D2C88ED9).
* Perform an initial configuration of the OAM domain as described in [Updating the Domain](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-access-manager.html#GUID-25C771AF-248E-45E2-B6FF-DE81DE1C7337).
* Perform post configuration tasks as described in [Performing the Post-Configuration Tasks for Oracle Access Management Domain](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-access-manager.html#GUID-25BBC3EB-BB05-4358-9593-0BB7C1621D41).
* Removing the OAM server from the default Coherence cluster.
* Tune the oamDS Datasource as described in [Tuning the oamDS Data Source](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-access-manager.html#GUID-E8DE356A-2075-4DE7-AB23-B77BE76DBD1D).
* Configure the WebLogic Proxy Plug-in as described in [Configuring the WebLogic Proxy Plug-In](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-access-manager.html#GUID-248D5494-A25B-483F-92A7-E40E44E93BF9).
* Configure and Integrate OAM with LDAP as described in [Configuring and Integrating with LDAP](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-access-manager.html#GUID-CE7F5B44-C409-4DC0-915F-9523DC0FDB71).
* Add OAM Host Identifiers as described in [Updating Host Identifiers](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-access-manager.html#GUID-71694403-3989-4C64-A102-773BFB78F9C0).
* Add OAM policies as described in [Adding Missing Policies to OAM](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-access-manager.html#GUID-E8285EDD-24A1-48D4-9F75-C5783D85EDE7).
* Configure ADF and OPSS as described in [Configuring Oracle ADF and OPSS Security with Oracle Access Manager](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-access-manager.html#GUID-BBEB6E0F-4D78-4975-A772-FB52674FB484).
* Set the initial server count as described in [Setting the Initial Server Count](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-access-manager.html#GUID-DAE29639-FC4B-4339-9452-AE2C485E2659). 
* Create an Oracle Identity Governance Domain as described in [Installing and Configuring Oracle Identity Governance](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-identity-governance.html#GUID-14196492-4391-4547-B395-5E2AE19A93B3)
* Integrate OIG and SOA as described in [Integrating Oracle Identity Governance with Oracle SOA Suite](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-identity-governance.html#GUID-85C54A4D-BED6-4F80-99DE-9A6E0AFD481F).
* Integrate OIG with LDAP as described in [Integrating Oracle Identity Governance with LDAP](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-identity-governance.html#GUID-C3E85C57-2D54-47C5-811D-152C21E96493).
* Add missing object classes as described in [Adding Missing Object Classes](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-identity-governance.html#GUID-1256BC51-E785-430A-B415-E3CCC2653487).
* Integrate OIG and OAM as described in [Integrating Oracle Identity Governance and Oracle Access Manager](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-identity-governance.html#GUID-750F7004-33BA-46D6-ABA5-F67D94DE4E50).
* Configure SSO integration in the Governance domain [Configuring SSO Integration in the Governance Domain](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-identity-governance.html#GUID-323F65C5-3BE9-4D64-AE87-96E589F8B2B7).
* Enable OAM Notifications as described in [Enabling OAM Notifications](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-identity-governance.html#GUID-010C785C-0F08-44DE-9D96-4A88F28E202C).
* Update the Match Attribute as described in [Updating the Value of MatchLDAPAttribute in oam-config.xml](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-identity-governance.html#GUID-76DA4F90-F680-435A-A7D4-C257A7D366B3).
* Update the TAP Endpoint as described in [Updating the TapEndpoint URL](https://docs-uat.us.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-identity-governance.html#GUID-68065DA4-E2D3-479C-8A2B-AD19EDE290B7).
* Copy the WebGate artifacts to Oracle HTTP Server, if desired.
* Run Reconciliation Jobs as described in [Running the Reconciliation Jobs](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-identity-governance.html#GUID-B44989D1-1E86-4EF3-BCBD-A490113E4BB8).
* Configure Oracle Unified Messaging with Email/SMS server details as described in [Managing the Notification Service](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-identity-governance.html#GUID-89B15DCA-B712-4415-BAC2-E42728CA22BA).
* Enable Design Console access as described in [Enabling Design Console Access](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-identity-governance.html#GUID-4F460034-1129-41FD-B8BC-5F78742C3D24).
* Add load balancer certificates to Oracle Key Store Service as described in [Adding the Oracle Access Manager Load Balancer Certificate to the Oracle Keystore Service](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-identity-governance.html#GUID-9598E1AF-56A8-468A-835B-AAD3AE3CED0D) and [Adding the Business Intelligence Load Balancer Certificate to Oracle Keystore Trust Service](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-identity-governance.html#GUID-EBBD5C06-610B-4000-AEE1-EB53A8B3E56C). 
* Update the OIG initial server count as described in [Setting the Initial Server Count](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-identity-governance.html#GUID-421763A2-FF49-40D5-9E16-567EE95E3510).
* Set up the Business Intelligence Reporting links.
* Configure OIM to use BIP as described in [Configuring Oracle Identity Manager to Use BI Publisher](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-identity-governance.html#GUID-54FC6318-5716-4A3A-A205-A741E1F9FA65).
* Store the BI credentials in OIG as described in [Storing the BI Credentials in Oracle Identity Governance](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-identity-governance.html#GUID-77533B2C-2314-4883-AE98-80970655E153).
* Deploy Oracle Identity Role Intelligence as described in [Deploying OIRI Using Helm](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-identity-role-intelligence.html#GUID-2B42BAFF-499B-4348-BB2E-4444587154E5).
* Create OIRI users in Oracle Identity Governance as described in [Creating User Names and Groups in Oracle Identity Governance](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-identity-role-intelligence.html).
* Perform an initial OIG data load into OIRI as described in [Performing an Initial Data Load Using the Data Ingester](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-identity-role-intelligence.html#GUID-38ECFCFD-E80F-4F29-B90E-644BE522C058).
* Create OIRI Kubernetes Services either NodePort or Ingress as described in [Creating the Kubernetes NodePort Services](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-identity-role-intelligence.html#GUID-9368D654-3A45-40D3-82E1-EFB7EFE45929).
* Deploy Oracle Advanced Authentication and Risk Management as described in [Deploying Oracle Advanced Authentication](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-advanced-authentication-oaa.html#GUID-C0B16343-3E9C-41FB-9E32-9FDCA9A4025B).
* Create OAA Users as described in [Creating Users and Groups in LDAP](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-advanced-authentication-oaa.html#GUID-278C0CB3-9CC1-400C-B06B-B5DF8603B2EC).
* Create OAA Test User as described in [Creating a Test User](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-advanced-authentication-oaa.html#GUID-10B461F2-C309-4273-936A-35387EF7332C).
* Integrate OAA with Unified Messaging Service as described in [Configuring Email/SMS Servers](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-advanced-authentication-oaa.html#GUID-2020B622-4AAB-485E-8965-1BF071B32B48).
* Integrate OAA with OAM as described in [Integrating Oracle Advanced Authentication with Oracle Access Manager](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-advanced-authentication-oaa.html#GUID-D4FE27D2-6441-4C27-B720-79396A898C8F).
* Optionally Send OUD, OUDSM, OAM and OIG logfiles to Elastic Search

### What the Scripts Will Not Do

While the scripts perform the majority of the deployment, they do not perform the following tasks:

* Deploy Container Runtime Environment, Kubernetes, or Helm.
* Configure load balancer.
* Download the container images for these products.
* Tune the WebLogic Server.
* Configure OAM One Time Pin (OTP) forgotten password functionality
* Configure OIM workflow notifications to be sent by email.
* Set up OIM challenge questions.
* Provision Business Intelligence Publisher (BIP).
* Set up the links to the Oracle BI Publisher environment. However, the scripts will deploy reports into the environment.
* Enable BI certification reports in OIG as described in [Enable Certification Reports](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-and-configuring-oracle-identity-governance.html#GUID-7DBE7D6E-3F62-45F9-8063-398128D6B462).
* Configure Oracle HTTP Server to send log files and monitoring data to Elastic Search and Prometheus.
* Configure Oracle Database Server to send log files and monitoring data to Elastic Search and Prometheus.
* Send Oracle HTTP Monitoring data to Prometheus.
* Send Oracle Database Monitioring data to Prometheus.

## Key Concepts of the Scripts

To make things simple and easy to manage the scripts are based around two concepts:

* A response file with details of your environment.
* Template files you can easily modify or add to as required.

> Note: Provisioning scripts are re-enterant, if something fails it can be restarted at the point at which it failed.


## Getting Started

If you are provisioning Oracle Identity Governance, you must also download the Oracle Connector Bundle for OUD and extract it to a location which is accessible by the provisioning scripts. For example, `/workdir/connectors/OID-12.2.1.3.0`. The connector directory name must start with `OID-12.2.1.`

If you are provisioning the Oracle HTTP Server, you must download the Oracle HTTP installer and place it in the location `$SCRIPTDIR/templates/ohs/installer` the installer MUST be the ZIP file for example, fmw\_12.2.1.4.0\_ohs\_linux64\_Disk1\_1of1.zip.

If you wish to Install the Oracle HTTP Server or copy files to it, you must setup passwordless SSH from the deployment host, during the provisioning.

## Creating a Response File

Sample response and password files are created for you in the `responsefile` directory. You can edit these files or create your own file in the same directory using these files as templates.  The files can be editied directly or by running the shell script `start_here.sh` in the script's home directory.

For example

```
./start_here.sh [ -r responsefile -p passwordfile ]
```

You can run the above script as many times as you want on the same file. Pressing the Enter key on any response retains the existing value.

Values are stored in the files `idm.rsp` and `.idmpwds` files unless the command is started with the -r and -p options in which case the files updated will be those specified..

> Note: 
> * The file consists of key/value pairs. There should be no spaces between the name of the key and its value. For example:
> `Key=value`
>* If you are using complex passwords, that is, passwords which contain characters such as `!`, `*`, and `$`, then these characters must be separated by a `\`. For example: 'hello!$' should be entered as `hello\!\$`. 

## Validating Your Environment

Run the `prereqchecks.sh` script, which exists in the script's home directory, to check your environment. The script is based on the response file you created above. See [Creating a Response File](#creating-a-response-file). 

The script performs several checks such as (but not limited to) the following:

* Ensures that the Container images are available on each node.
* Checks that the NFS file shares have been created.
* Ensures that the Load balancers are reachable.

To invoke the script use the following command:

`cd <SCRIPTDIR>`

`./prereqchecks.sh [ -r responsefile -p passwordfile ]`

-r and -p are optional.

## Provisioning the Environment

There are a number of provisioning scripts located in the script directory:

| **File** | **Purpose** | 
| --- | --- | 
|provision.sh | Umbrella script that invokes each of the scripts (which can be invoked manually) mentioned in the following rows.|
|provision_ingress.sh| Deploys an Ingress controller. |
|provision_elk.sh| Deploys Elastic Search and Kibana. |
|provision_prom.sh| Deploys Prometheus and Grafana. |
|provision_ohs.sh| Installs Oracle HTTP Server and Deploys WebGate. |
|provision_oud.sh | Deploys Oracle Unified Directory. |
|provision_oudsm.sh | Deploys Oracle Unified Directory Services Manager. |
|provision_operator.sh| Deploys WebLogic Kubernetes Operator.|
|provision_oam.sh | Deploys Oracle Access Manager. |
|provision_oig.sh | Deploys Oracle Identity Governance. |
|provision_oiri.sh| Deploys Oracle Identity Role Intelligence.|
|provision_oaa.sh | Deploy Oracle Advanced Authentication.|


These scripts will use a working directory defined in the response file for temporary files. 

Each of the above commands can be provided with a specific responsefile (default is idm.rsp) and passwordfile (default is .idmpwds), by appending:

-r responsefile -p passwordfile

Examples: 

`./provision.sh`

`./provision.sh -r my.rsp -p .mypwds`

These files must exist in the responsefile directory.

## Log Files

The provisioning scripts create log files for each product inside the working directory in a `logs` sub-directory. This directory also contains the following two files:

* `progressfile` – This file contains the last successfully executed step. If you want to restart the process at a different step, update this file.

* `timings.log` – This file is used for informational purposes to show how much time was spent on each stage of the provisioning process.

## Files You Need to Keep
After a provisioning run that creates a domain is complete, there are files that you need to keep safely. These files are used to start and stop the domain as well as contain instructions to start the domain. A copy of these files is stored in the working directory under the `TO_KEEP` subdirectory. 

You should also keep any override files that are generated.

## After Installation/Configuration
As part of running the scripts, a number of working files are created in the `WORKDIR` directory prior to copying to the persistent volume in `/u01/user_projects/workdir`. Many of these files contain passwords required for the setup. You should archive these files after completing the deployment. 

The responsfile uses a hidden file in the responsefile directory to store passwords.

## Oracle HTTP Server Configuration Files

Each provisioning script creates sample files for configuring your Oracle HTTP server. These files are generated and stored in the working directory under the `OHS` subdirectory. If required, the scripts can also copy these configuration files to Oracle HTTP server and restart it.


## Utilities

In the `scripts` directory there is a subdirectory called `utils` . This directory contains sample utilities you may find useful. Utilities for:

* Loading container images to each of the Kubernetes nodes.
* Deleting deployments.

## Reference – Response File

The following sections describe the parameters in the response file that is used to control the provisioning of the various products in the Kubernetes cluster. The parameters are divided into generic and product-specific parameters.

### Products to Deploy
These parameters determine which products the deployment scripts attempt to deploy.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
| **INSTALL\_INGRESS** | `true` | Set to `true` to configure an Ingress controller. |
| **INSTALL\_ELK** | `false` | Set to `true` to deploy and configure an Elastic Search and Kibana. |
| **INSTALL\_PROM** | `false` | Set to `true` to deploy and configure an Prometheus and Grafana. |
| **INSTALL\_OHS** | `true` | Set to `true` to Install Oracle HTTP Server. |
| **INSTALL\_OUD** | `true` | Set to `true` to configure OUD. |
| **INSTALL\_OUDSM** | `true` | Set to `true` to configure OUDSM. |
| **INSTALL\_WLSOPER** | `true` | Set to `true` to deploy WebLogic Kubernetes Operator. |
| **INSTALL\_OAM** | `true` | Set to `true` to configure OAM. |
| **INSTALL\_OIG** | `true` | Set to `true` to configure OIG. |
|**INSTALL\_OIRI** | `true` | Set to `true` to configure OIRI. |
| **INSTALL\_OAA** | `true` | Set to `true` to configure OAA.|


### Control Parameters
These parameters are used to specify the type of Kubernetes deployment and the names of the temporary directories you want the deployment to use, during the provisioning process.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**USE\_REGISTRY** | `false` | Set to `true` to configure OAA.|
|**IMAGE\_TYPE** | `crio` | Set to `crio` or `docker` depending on your container engine.|
|**IMAGE\_DIR** | `/container/images` | The location where you have downloaded the container images. Used by the `load_images.sh` script.|
| **LOCAL\_WORKDIR** | `/workdir` | The location where you want to create the working directory.|
| **K8\_WORKDIR** | `/u01/oracle/user_projects/workdir` | The location inside the Kubernetes containers to which working files are copied.|
| **K8\_WORKER\_HOST1** | `k8worker1.example.com` | The name of a Kubernetes worker node used in generating the OHS sample files.|
| **K8\_WORKER\_HOST2** | `k8worker2.example.com` | The name of a Kubernetes worker node used in generating the OHS sample files.|


### Registry Parameters
These parameters are used to determine whether or not you are using a container registry. If you are, then it allows you to store the login credentials to the repository so that you are able to store the credentials as registry secrets in the individual product namespaces.

If you are pulling images from GitHub or Docker hub, then you can also specify the login parameters here so that you can create the appropriate Kubernetes secrets.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**REGISTRY** | `iad.ocir.io/mytenancy` | Set to the location of your container registry.|
|**REG\_USER** | `mytenancy/oracleidentitycloudservice/email@example.com` | Set to your registry user name.|
|**REG\_PWD** | *`<password>`* | Set to your registry password.|
|**CREATE\_REGSECRET** | `false` | Set to `true` to create a registry secret for automatically pulling images.|
|**CREATE\_GITSECRET** | `true` | Specify whether to create a secret for GitHub. This parameter ensures that you do not see errors relating to GitHub not allowing anonymous downloads.|
|**GIT\_USER** | `gituser` | The GitHub user's name.|
|**GIT\_TOKEN** | `ghp_aO8fqRNVdfsfshOxsWk40uNMS` | The GitHub token.|
|**DH\_USER** | *`username`* | The Docker user name for `hub.docker.com`. Used for CronJob images.|
|**DH\_PWD** | *`mypassword`* | The Docker password for `hub.docker.com`. Used for CronJob images.|


### Image Parameters
These parameters are used to specify the names and versions of the container images you want to use for the deployment. These images must be available either locally or in your container registry. The names and versions must be identical to the images in the registry or the images stored locally.

These can include registry prefixes if you use a registry. Use the `local/` prefix if you use the Oracle Cloud Native Environment. 

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**OPER\_IMAGE** | `ghcr.io/oracle/weblogic-kubernetes-operator` | The WebLogic Kubernetes Operator image name.|
|**OUD\_IMAGE** | `$REGISTRY/oud` | The OUD image name.|
|**OUDSM\_IMAGE** | `$REGISTRY/oudsm` | The OUDSM image name.|
|**OAM\_IMAGE** | `$REGISTRY/oam` | The OAM image name.|
|**OIG\_IMAGE** | `$REGISTRY/oig` | The OIG image name.|
|**OIRI\_CLI\_IMAGE** | `$REGISTRY/oiri-cli` | The OIRI CLI image name.|
|**OIRI\_IMAGE** | `$REGISTRY/oiri` | The OIRI image name.|
|**OIRI\_UI\_IMAGE** | `$REGISTRY/oiri-ui` | The OIRI UI image name.|
|**OIRI\_DING\_IMAGE** | `$REGISTRY/oiri-ding` | The OIRI DING image name.|
|**OAA\_MGT\_IMAGE** | `$REGISTRY/oracle/shared/oaa-mgmt` | The OAA Management container image.|
|**KUBECTL\_REPO** | `bitnami/kubectl` | The kubectl image used by OUD.|
|**BUSYBOX\_REPO** | `docker.io/busybox` | The busybox image used by OUD.|
|**OPER\_VER** | `4.0.4` | The version of the WebLogic Kubernetes Operator.|
|**OUD\_VER** | `12.2.1.4.0-8-ol7-210715.1921` | The OUD version.|
|**OUDSM\_VER** | `12.2.1.4.0-8-ol7-210721.0755` | The OUDSM version.|
|**OAM\_VER** | `12.2.1.4.0-8-ol7-210721.0755` | The OAM version.|
|**OIG\_VER** | `12.2.1.4.0-8-ol7-210721.0748` | The OIG version.|
|**OIRICLI\_VER** | `12.2.1.4.02106` | The OIRI CLI version.|
|**OIRI\_VER** | `12.2.1.4.02106` | The OIRI version.|
|**OIRIUI\_VER** | `12.2.1.4.02106` | The OIRI UI version.|
|**OIRIDING\_VER** | `12.2.1.4.02106` | The OIRI DING version.|
|**OAAMGT\_VER** | `oaa_122140-20210721` | The OAA MGMT container version.|
|**OAA\_VER** | `oaa_122140-20210721` | The OAA version.|


### Generic Parameters
These generic parameters apply to all deployments.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**PVSERVER** | `nfsserver.example.com` | The name or IP address of the NFS server used for persistent volumes. **Note**: If you use a name, then the name must be resolvable inside the Kubernetes cluster. If it is not resolvable, you can add it by updating CoreDNS. See [Adding Individual Host Entries to CoreDNS](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/preparing-premises-enterprise-deployment.html#GUID-CC0AE601-6D0A-4000-A8CE-F83D2E1F836E).
|**IAM\_PVS** | `/export/IAMPVS` | The export path on the NFS where persistent volumes are located.|
|**PV\_MOUNT** | `/u01/oracle/user_projects` | The path to mount the PV inside the Kubernetes container. Oracle recommends you to not change this value.|

### Ingress Parameters
These parameters determine how the Ingress controller is deployed.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**INGRESSNS** |`ingressns`| The Kubernetes namespace used to hold the Ingress objects.|
|**INGRESS\_TYPE** |`nginx`| The type of Ingress controller you wan to deploy. At this time, the script supports only `nginx`.|
|**INGRESS\_ENABLE\_TCP** |`true`| Set to `true` if you want the controller to forward LDAP requests.|
|**INGRESS\_NAME** |`idmedg`| The name of the Ingress controller used to create an Nginx Class.|
|**INGRESS\_SSL** |`false`| Set to `true` if you want to configure the Ingress controller for SSL.|
|**INGRESS\_DOMAIN** |`example.com`| Used when creating self-signed certificates for the Ingress controller.|
|**INGRESS\_REPLICAS** |`2`| The number of Ingress controller replicas to start with. This value should be a minimum of two for high availability.|

### Elastic Search Parameters
These parameters determine how to send log files to Elastic Search.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**USE\_ELK** |`false`| Set to `true` if you wish to send logfiles to Elastic Search|
|**ELKNS** |`elkns`| The Kubernetes namespace used to hold the Elastic Search objects.|
|**ELK\_VER** |`8.3.1`| The version of Elastic Search/Logstash to use.|
|**ELK\_HOST** |`https://elasticsearch-es-http.<ELKNS>.svc:9200`| The address of the elastic search server to send log files to.   If you are using ELK inside a Kubernetes cluster then specify the address as in the example.  If you are using an Elastic Search outside of the Kubernetes cluster then specify the external address.  The host name specified must be resolvable inside the Kubernetes cluster.|
|**ELK\_SHARE** | `/export/IAMPVS/elkpv` | Mount point on NFS where ELK persistent volume is exported.|
|**ELK\_STORAGE** | `nfs-client` | The storage class to use for Elastic Search Stateful Sets.|

### Prometheus Parameters
These parameters determine how to send monitoring information to Prometheus.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**USE\_PROM** |`false`| Set to `true` if you send monitoring data to Prometheus|
|**PROMNS** |`monitoring`| The Kubernetes namespace used to hold the Prometheus Deployement.|


### Oracle HTTP Server Parameters
These parameters are specific to OHS.  These parameters are used to construct the Oracle HTTP Server configuration files and Install the Oracle HTTP Server if requested. 

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**UPDATE\_OHS** |`true`| Set this to true if you wish the scripts to automatically copy the generated OHS configuration files.  Once copied the Oracle HTTP server will be restarted. `Note: This is independent of whether you are installing the Oracle HTTP server or not`|
|**OHS\_HOST1** |`webhost1.example.com`| The fully qualified name of the host running the first Oracle HTTP Server|
|**OHS\_HOST2** |`webhost2.example.com`| The fully qualified name of the host running the second Oracle HTTP Server, leave blank if you do not have a second Oracle HTTP Server.|
|**OHS\_INSTALLER** |`fmw_12.2.1.4.0_ohs_linux64_Disk1_1of1.zip`| The name of the OHS installer ZIP file.|
|**DEPLOY\_WG** |`true`| Deploy WebGate in the `OHS_ORACLE_HOME`.|
|**COPY\_WG\_FILES** |`true`| Set this to true if you wish the scripts to automatically copy the generated Webgate Artifacts to your OHS Server.  Note: You must first have deployed your Webgate.|
|**OHS\_BASE** |`/u02/private`| The location of your OHSbase directory.  Binaries and Configuration files are below this location.  The OracleInventory is also placed into this location when installing the Oracle HTTP Server|
|**OHS\_ORACLE\_HOME** |`$OHS_BASE/oracle/products/ohs`| The location of your OHS binaries|
|**OHS\_DOMAIN** |`$OHS_BASE/oracle/config/domains/ohsDomain`| The location of your OHS domain|
|**OHS1\_NAME** |`ohs1`| The component name of your first OHS instance|
|**OHS2\_NAME** |`ohs1`| The component name of your second OHS instance|
|**NM\_ADMIN\_USER** |`admin`| The name of the admin user you wish to assign to Node Manager if Installing the Oracle HTTP Server.|
|**NM\_ADMIN\_PWD** |`password`| The password of the admin user you wish to assign to Node Manager if Installing the Oracle HTTP Server.|
|**OHS\_PORT** |`7777`| The port your Oracle HTTP Servers listen on.|
|**OHS\_HTTPS\_PORT** |`4443`| The SSL port your Oracle HTTP Servers listen on.|
|**NM\_PORT** |`5556`| The port to use for Node Manager.|
### OUD Parameters
These parameters are specific to OUD. When deploying OUD, you also require the generic LDAP parameters.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**OUDNS** | `oudns` | The Kubernetes namespace used to hold the OUD objects.|
|**OUD\_SHARE** | `$IAM_PVS/oudpv` | Mount point on NFS where OUD persistent volume is exported.|
|**OUD\_CONFIG\_SHARE** | `$IAM_PVS/oudconfigpv`| The mount point on NFS where OUD Configuration persistent volume is exported.|
|**OUD\_LOCAL\_SHARE** | `/nfs_volumes/oudconfigpv` | The local directory where **OUD\_CONFIG\_SHARE** is mounted. Used to hold seed files.|
|**OUD\_LOCAL\_PVSHARE** | `/nfs_volumes/oudpv`| The local directory where **OUD_SHARE** is mounted. Used for deletion.|
|**OUD\_POD\_PREFIX** | `edg`| The prefix used for the OUD pods.|
|**OUD\_REPLICAS** | `1`| The number of OUD replicas to create. If you require two OUD instances, set this to 1. This value is in addition to the primary instance.|
|**OUD\_REGION** | `us`| The OUD region to use should be the first part of the searchbase without the `dc=`.|
|**LDAP\_USER\_PWD** | *`<password1>`* | The password to assign to all users being created in LDAP. **Note**: This value should have at least one capital letter, one number, and should be at least eight characters long.
|**OUD\_PWD\_EXPIRY** | `2024-01-02`| The date when the user passwords you are creating expires.|
|**OUD\_CREATE\_NODEPORT** | `true`| Set to `true` if you want to create NodePort services for OUD. These services are used to interact with OUD from outside of the Kubernetes cluster.|

### OUDSM Parameters
List of parameters used to determine how Oracle Directory Services Manager will be deployed.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**OUDSM\_USER** | `weblogic` | The name of the administration user you want to use for the WebLogic domain that is created when you install OUDSM.|
|**OUDSM\_PWD** | *`<password>`* | The password you want to use for **OUDSM_USER**.|
|**OUDSM\_SHARE** | `$IAM_PVS/OUDSMPV` |  The mount point on NFS where OUDSM persistent volume is exported.|
|**OUDSM\_LOCAL\_SHARE** | `/nfs_volumes/oudsmpv` | The local directory where **OUDSM\_SHARE** is mounted. It is used by the deletion procedure.|
|**OUDSM\_INGRESS\_HOST** | `oudsm.example.com` | Used when you are using an Ingress controller. This name must resolve in DNS and point to one of the Kubernetes worker nodes or to the network load balancer entry for the Kubernetes workers.|


### LDAP Parameters
This table lists the parameters which are common to all LDAP type of deployments.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**LDAP\_OAMADMIN\_USER** | `oamadmin` | The name of the user you want to create for the OAM administration tasks.|
|**LDAP\_ADMIN\_USER** | `cn=oudadmin` | The name of the OUD administrator user.|
|**LDAP\_ADMIN\_PWD** | *`<password>`* | The password you want to use for the OUD administrator user.|
|**LDAP\_SEARCHBASE** | `dc=example,dc=com` | The OUD search base.|
|**LDAP\_GROUP\_SEARCHBASE** | `cn=Groups,dc=example,dc=com` | The search base where names of groups are stored in the LDAP directory.|
|**LDAP\_USER\_SEARCHBASE** | `cn=Users,dc=example,dc=com` | The search base where names of users are stored in the LDAP directory.|
|**LDAP\_RESERVE\_SEARCHBASE** | `cn=Reserve,dc=example,dc=com` | The search base where reservations are stored in the LDAP directory.|
|**LDAP\_SYSTEMIDS** | `systemids` | The special directory tree inside the OUD search base to store system user names, which will not be managed through OIG.|
|**LDAP\_OIGADMIN\_GRP** | `OIMAdministrators` | The name of the group you want to use for the OIG administration tasks.|
|**LDAP\_OAMADMIN\_GRP** | `OAMAdministrators` | The name of the group you want to use for the OAM administration tasks.|
|**LDAP\_WLSADMIN\_GRP** | `WLSAdministrators` | The name of the group you want to use for the WebLogic administration tasks.|
|**LDAP\_OAMLDAP\_USER** | `oamLDAP` | The name of the user you want to use to connect the OAM domain to LDAP for user validation.|
|**LDAP\_OIGLDAP\_USER** | `oimLDAP` | The name of the user you want to use to connect the OIG domain to LDAP for integration. This user will have read/write access.|
|**LDAP\_WLSADMIN\_USER** | `weblogic_iam` | The name of a user to use for logging in to the WebLogic Administration Console and Fusion Middleware Control.|
|**LDAP\_XELSYSADM\_USER** |`xelsysadm` | The name of the user to administer OIG.|
|**LDAP\_USER\_PWD** |*`<userpassword>`* | The password to be assigned to all the LDAP user accounts.|


### SSL Parameters
The deployment scripts create self-signed certificates. The parameters are used to determine what values will be added to those certificates.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**SSL\_COUNTRY** | `US` | The abbreviation for the name of the country.|
|**SSL\_ORG** | `Example Company`| The name of the organization.|
|**SSL\_CITY** | `City` | The name of the city.|
|**SSL\_STATE** | `State` | The name of the state.|


### WebLogic Kubernetes Operator Parameters
These parameters determines how the WebLogic Kubernetes Operator is provisioned.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**OPERNS** | `opns` | The Kubernetes namespace used to hold the WebLogic Kubernetes Operator.|
|**OPER\_ACT** | `operadmin` | The Kubernetes service account for use by the WebLogic Kubernetes Operator.|

### OAM Parameters
These parameters determine how OAM is deployed and configured.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**OAMNS** | `oamns` | The Kubernetes namespace used to hold the OAM objects.|
|**OAM\_SHARE** | `$IAM_PVS/oampv` | The mount point on NFS where OAM persistent volume is exported.|
|**OAMNS** | `oamns` | The Kubernetes namespace used to hold the OAM objects.|
|**OAM\_LOCAL\_SHARE** | `/nfs_volumes/oampv` | The local directory where **OAM_SHARE** is mounted. It is used by the deletion procedure.|
|**OAM\_SERVER\_COUNT** | `5` | The number of OAM servers to configure. This value should be more than you expect to use.|
|**OAM\_SERVER\_INITIAL** | `2` | The number of OAM Managed Servers you want to start for normal running. You will need at least two servers for high availability.|
|**OAM\_DB\_SCAN** | `dbscan.example.com` | The database scan address to be used by the grid infrastructure.|
|**OAM\_DB\_LISTENER** | `1521` | The database listener port.|
|**OAM\_DB\_SERVICE** | `iadedg.example.com` | The database service that connects to the database you want to use for storing the OAM schemas.|
|**OAM\_DB\_SYS\_PWD** | `DBSysPassword` | The SYS password of the OAM database.|
|**OAM\_RCU\_PREFIX** | `IADEDG` | The RCU prefix to use for the OAM schemas.|
|**OAM\_SCHEMA\_PWD** | `SchemaPassword` | The password to use for the OAM schemas that get created. If you are using special characters, you may need to escape them with a '`\`'. For example: '`Password\#`'.|
|**OAM\_WEBLOGIC\_USER** | `weblogic` | The OAM WebLogic administration user name.|
|**OAM\_WEBLOGIC\_PWD** | *`<password1>`* | The password to be used for **OAM\_WEBLOGIC\_USER**.|
|**OAM\_DOMAIN\_NAME** | `accessdomain` | The name of the OAM domain you want to create.|
|**OAM\_LOGIN\_LBR\_HOST** | `login.example.com` | The load balancer name for logging in to OAM.|
|**OAM\_LOGIN\_LBR\_PORT** | `443` | The load balancer port to use for logging in to OAM.|
|**OAM\_LOGIN\_LBR\_PROTOCOL** | `https` | The protocol of the load balancer port to use for logging in to OAM.|
|**OAM\_ADMIN\_LBR\_HOST** | `iadadmin.example.com` | The load balancer name to use for accessing OAM administrative functions.|
|**OAM\_ADMIN\_LBR\_PORT** | `80` | The load balancer port to use for accessing OAM administrative functions.|
|**OAM\_COOKIE\_DOMAIN** | `.example.com` | The OAM cookie domain is generally similar to the search base. Ensure that you have a '`.`' (dot) at the beginning.|
|**OAM\_OIG\_INTEG** | `true` | Set to `true` if OAM is integrated with OIG.|
|**OAM\_OAP\_HOST** | `k8worker1.example.com` | The name of one of the Kubernetes worker nodes used for OAP calls.|
|**OAM\_OAP\_PORT** | `5575` | The internal Kubernetes port used for OAM requests.|
|**OAMSERVER\_JAVA\_PARAMS** | "`-Xms2048m -Xmx8192m`" | The internal Kubernetes port used for OAM requests.|

### OIG Parameters
These parameters determine how OIG is provisioned and configured.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**OIGNS** | `oigns` | The Kubernetes namespace used to hold the OIG objects.|
|**CONNECTOR\_DIR** | `/workdir/OIG/connectors/` | The location on the file system where you have downloaded and extracted the OUD connector bundle.|
|**OIG\_SHARE** | `$IAM_PVS/oigpv` | The mount point on NFS where OIG persistent volume is exported.|
|**OIG\_LOCAL\_SHARE** | `/local_volumes/oigpv` |The local directory where **OIG\_SHARE** is mounted. It is used by the deletion procedure.|
|**OIG\_SERVER\_COUNT** | `5` | The number of OIM/SOA servers to configure. This value should be more than you expect to use.|
|**OIG\_SERVER\_INITIAL** | `2` | The number of OIM/SOA Managed Servers you want to start for normal running. You will need at least two servers for high availability.|
|**OIG\_DOMAIN\_NAME** | `governancedomain` | The name of the OIG domain you want to create.|
|**OIG\_DB\_SCAN** | `dbscan.example.com` | The database scan address used by the grid infrastructure.|
|**OIG\_DB\_LISTENER** | `1521` | The database listener port.|
|**OIG\_DB\_SERVICE** | `edgigd.example.com` | The database service which connects to the database you want to use for storing the OIG schemas.|
|**OIG\_DB\_SYS\_PWD** | `MySysPassword` | The SYS password of the OIG database.|
|**OIG\_RCU\_PREFIX** | `IGDEDG` | The RCU prefix to use for OIG schemas.|
|**OIG\_SCHEMA\_PWD** | `MySchemPassword` | The password to use for the OIG schemas that get created. If you are using special characters, you may need to escape them with a '`\`'. For example: '`Password\#`'.|
|**OIG\_WEBLOGIC\_USER** | `weblogic` | The OIG WebLogic administration user.|
|**OIG\_WEBLOGIC\_PWD** | *`<password>`* | The OIG WebLogic administration user.|
|**OIG\_ADMIN\_LBR\_HOST** | `igdadmin.example.com` | The load balancer name to use for accessing OIG administrative functions.|
|**OIG\_ADMIN\_LBR\_PORT** | `80` | The load balancer port you use for accessing the OIG administrative functions.|
|**OIG\_LBR\_HOST** | `prov.example.com` | The load balancer name to use for accessing the OIG Identity Console.|
|**OIG\_LBR\_PORT** | `443` | The load balancer port to use for accessing the OIG Identity Console.|
|**OIG\_LBR\_PROTOCOL** | `https` | The load balancer protocol to use for accessing the OIG Identity Console.|
|**OIG\_LBR\_INT\_HOST** | `igdinternal.example.com` | The load balancer name you will use for accessing OIG internal callbacks.|
|**OIG\_LBR\_INT\_PORT** | `7777` | The load balancer port to use for accessing the OIG internal callbacks.|
|**OIG\_LBR\_INT\_PROTOCOL** | `http` | The load balancer protocol to use for accessing OIG Internal callbacks.|
|**OIG\_ENABLE\_T3** | `false` | Set this value to `true` if you want to enable access to the Design Console.|
|**OIG\_BI\_INTEG** | `true` | Set to `true` to configure BIP integration.|
|**OIG\_BI\_HOST** | `bi.example.com` | The load balancer name you will use for accessing BI Publisher.|
|**OIG\_BI\_PORT** | `443` | The load balancer port you will use for accessing BI Publisher.|
|**OIG\_BI\_PROTOCOL** | `https` | The load balancer protocol you will use for accessing BI Publisher.|
|**OIG\_BI\_USER** | `idm_report` | The BI user name you want to use for running reports in the BI Publisher deployment.|
|**OIG\_BI\_USER\_PWD** | `BIPassword` | The password of the **OIG_BI_USER**.|
|**OIMSERVER\_JAVA\_PARAMS** | "`-Xms4096m -Xmx8192m`" | The memory parameters to use for `oim_servers`.|
|**SOASERVER\_JAVA\_PARAMS** | "`-Xms4096m -Xmx8192m`" | The memory parameters to use for `soa_servers`.|
|**OIG\_EMAIL\_CREATE** | `true` | If set to `true`, OIG will be configured for email notifications.|
|**OIG\_EMAIL\_SERVER** | `sendmail.example.com` | The name of your SMTP email server.|
|**OIG\_EMAIL\_PORT** | `25` | The port of your SMTP server. The valid values are `None` or `TLS`.|
|**OIG\_EMAIL\_SECURITY** | `None` | The security mode of your SMTP server.|
|**OIG\_EMAIL\_ADDRESS** | `myemail.example.com` | The user name that is used to connect to the SMTP server, if one is required.|
|**OIG\_EMAIL\_PWD** | *`<password>`* | The password of your SMTP server.|
|**OIG\_EMAIL\_FROM\_ADDRESS** | `from@example.com` | The '`From`' email address used when emails are sent.|
|**OIG\_EMAIL\_REPLY\_ADDRESS** | `noreplies@example.com` | The '`Reply`' to email address of the emails that are sent.|


### OIRI Parameters
These parameters determine how OIRI is provisioned and configured.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**OIRINS** | `oirins` | The Kubernetes namespace used to hold the OIRI objects.|
|**DINGNS** | `dingns` | The Kubernetes namespace used to hold the OIRI DING objects.|
|**OIRI\_REPLICAS** | `noreplies@example.com` | The number of OIRI servers to start the deployment.|
|**OIRI\_UI\_REPLICAS** | `2` | The number of OIRI UI Servers to start the deployment.|
|**OIRI\_SPARK\_REPLICAS** | `2` | The number of OIRI UI servers to start the deployment.|
|**OIRI\_SHARE** |`$IAM_PVS/oiripv`| The mount point on NFS where OIRI persistent volume is exported.|
|**OIRI\_LOCAL\_SHARE** |`/nfs_volumes/oiripv`| The local directory where **OIRI\_SHARE** is mounted. It is used by the deletion procedure.|
|**OIRI\_SHARE\_SIZE** |`10Gi`| The size of the OIRI persistent volume.|
|**OIRI\_DING\_SHARE** |`$IAM_PVS/dingpv`|  The mount point on NFS where OIRI DING persistent volume is exported.|
|**OIRI\_DING\_LOCAL\_SHARE** |`/nfs_volumes/dingpv`| The local directory where **OIRI\_DING\_SHARE** is mounted. It is used by the deletion procedure.|
|**OIRI\_DING\_SHARE\_SIZE** |`10Gi`| The size of the OIRI DING persistent volume.|
|**OIRI\_WORK\_SHARE** |`$IAM_PVS/workpv`|  The mount point on NFS where OIRI work persistent volume is exported.|
|**OIRI\_DB\_SCAN** |`dbscan.example.com`| The database SCAN address of the grid infrastructure.|
|**OIRI\_DB\_LISTENER** |`1521`| The database listener port.|
|**OIRI\_DB\_SERVICE** |`edgoiri.example.com`| The database service which connects to the database you want to use for storing the OIRI schemas.|
|**OIRI\_DB\_SYS\_PWD** |`MySysPassword`| The SYS password of the OIRI database.|
|**OIRI\_RCU\_PREFIX** |`ORIEDG`| The RCU prefix to use for the OIRI schemas.|
|**OIRI\_SCHEMA\_PWD** |`MySchemPassword`| The password to use for the OIRI schemas that get created. If you are using special characters, you may need to escape them with a '`\`'. For example: '`Password\#`'.|
|**OIRI\_CREATE\_OHS** |`true`| This value instructs the scripts to generate OHS entries for connecting to OIRI. You should set this to `true` unless you are configuring a standalone OIRI.|
|**OIRI\_INGRESS\_HOST** |`igdadmin.example.com`| If you are creating a fully integrated deployment and want OIRI to be included in the OHS deployment, then this value should be set to the OIG Administration host name. For example: `iagadmin.example.com`. <p><p>If you are deploying OIRI standalone using Ingress to route requests, then set this value to the virtual hostname you want to use. For example: `oiri.example.com`.|
|**OIRI\_KEYSTORE\_PWD** |`MyKeystore_Password100`| The password to use for the OIRI keystore.|
|**OIRI\_ENG\_GROUP** |`OrclOIRIRoleEngineer`| The name of the OIG OIRI group - DO NOT CHANGE.|
|**OIRI\_ENG\_USER** |`oiri`| The user to be created in OIG for UI login.|
|**OIRI\_ENG\_PWD** |`MyPassword1`| The password of the **OIRI_ENG_USER**.|
|**OIRI\_SERVICE\_USER** |`oirisvc`| The user name for the OIG OIRI service account.|
|**OIRI\_SERVICE\_PWD** |`MyPassword1`| The password for  **OIRI_SERVICE_USER**.|
|**OIRI\_OIG\_URL** |`http://$OIG_DOMAIN_NAME-cluster-oim-cluster.$OIGNS.svc.cluster.local:14000`| The URL to access OIG. If internal to the Kubernetes cluster, use the Kubernetes service name as shown in the sample value. If external, use the `IGDINTERNAL` URL.|
|**OIRI\_LOAD\_DATA** |`true`| Set to `true` if you want to load data from the OIG database.|



### OAA Parameters
These parameters determine how OAA is provisioned and configured.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**OAANS** |`oaans`| The Kubernetes namespace used to hold the OAA objects.|
|**OAACONS** |`cons`| The Kubernetes namespace used to hold the Coherence objects.|
|**OAA\_DEPLOYMENT** |`edg`| A name for your OAA deployment. Do not use the name `oaa` because this is reserved for internal use.|
|**OAA\_DOMAIN** |`OAADomain`| The name of the OAM OAuth domain you want to create.|
|**OAA\_VAULT\_TYPE** |`file|oci`| The type of vault to use: file system or OCI.|
|**OAA\_CREATE\_OHS** |`true`| Set to `false` if you are installing OAA standalone front ended by Ingress. |
|**OAA\_CONFIG\_SHARE** |`$IAM_PVS/oaaconfigpv`| The mount point on NFS where OAA config persistent volume is exported..|
|**OAA\_CRED\_SHARE** |`$IAM_PVS/oaacredpv`| The mount point on NFS where OAA credentials persistent volume is exported..|
|**OAA\_LOG\_SHARE** |`$IAM_PVS/oaalogpv`| The mount point on NFS where OAA logfiles persistent volume is exported..|
|**OAA\_LOCAL\_CONFIG\_SHARE** |`/nfs_volumes/oaaconfigpv`| The local directory where **OAA\_CONFIG\_SHARE** is mounted. It is used by the deletion procedure. |
|**OAA\_LOCAL\_CRED\_SHARE** |`/nfs_volumes/oaacredpv`| The local directory where **OAA\_CRED\_SHARE** is mounted. It is used by the deletion procedure.|
|**OAA\_LOCAL\_LOG_SHARE** |`/nfs_volumes/oaalogpv`| The local directory where **OAA\_LOG\_SHARE** is mounted. It is used by the deletion procedure. |
|**OAA\_DB\_SCAN** |`dbscan.example.com`| The database SCAN address of the grid infrastructure.|
|**OAA\_DB\_LISTENER** |`1521`| The database listener port.|
|**OAA\_DB\_SERVICE** |`edgoaa.example.com`| The database service which connects to the database you want to use for storing the OAA schemas.|
|**OAA\_DB\_SYS\_PWD** |`MySysPassword`| The SYS password of the OAA database.|
|**OAA\_RCU\_PREFIX** |`OAAEDG RCU`| The prefix to use for the OAA schemas.|
|**OAA\_SCHEMA\_PWD** |`MySchemPassword`| The password to use for the OAA schemas that are created. If you are using special characters, you may need to escape them with a '`\`'. For example: '`Password\#`'.|

#### OAA Users/Groups/Passwords

| **Users/Groups** | **Example** | **Description** |
| --- | --- | --- |
|**OAA\_ADMIN\_GROUP** |`OAA-Admin-Role`| The OIG role to create for OAA administration functions. This group is created in OIG.|
|**OAA\_USER\_GROUP** |`OAA-App-User`| The group which will be assigned to the OAA users. This group is created in OIG.|
|**OAA\_ADMIN\_USER** |`oaaadmin`| The name of the user to use for OAA administration functions. This user name is created in OIG.|
|**OAA\_ADMIN\_PWD** |`oaaAdminPassword`| The password to be assigned to the **OAA\_ADMIN\_USER**. |
|**OAA\_KEYSTORE\_PWD** |`oaapassword`| The password to be used for OAA keystores. |
|**OAA\_OAUTH\_PWD** |`oaapassword`| The password to be used for OAA OAuth domain.|
|**OAA\_API\_PWD** |`oaapassword`| The password to be used for OAA API interactions.|
|**OAA\_POLICY\_PWD** |`oaapassword`| The password to be used for OAA policy interactions.|
|**OAA\_FACT\_PWD** |`oaapassword`| The password to be used for OAA keystores for factor interactions.|


#### OAA Filesystem Vault Parameters

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**OAA\_VAULT\_SHARE** |`$IAM_PVS/oaavaultpv`| The mount point on NFS where OAA file vault persistent volume is exported.|
|**OAA\_LOCAL\_VAULT\_SHARE** |`/nfs_volumes/oaavaultpv`| The local directory where **OAA\_VAULT\_SHARE** is mounted. It is used by the deletion procedure. |
|**OAA\_VAULT\_PWD** |`oaapassword`| The password to use for file-based vault.|


#### OAA OCI Vault Parameters

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**OAA\_OCI\_OPER** | - | To obtain this value, encode the value of the API key that you downloaded at the time of creating the vault. See [Creating a Vault](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/preparing-oracle-cloud-infrastructure-enterprise-deployment.html).|
|**OAA\_OCI\_TENANT** |-| To obtain this value, log in to the OCI console, navigate to **Profile** and click **Tenancy**. Use the **OCID** value.|
|**OAA\_OCI\_USER** |-| To obtain this value, log in to the OCI console, navigate to **Profile** and click **Username**. Use the **OCID** value. |
|**OAA\_OCI\_FP** |-| To obtain this value, log in to the OCI console, navigate to **Profiles**, select **User Settings**, and then click **API Keys**. Use the value of the fingerprint for the API Key you created earlier. See [Creating a Vault](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/preparing-oracle-cloud-infrastructure-enterprise-deployment.html).|
|**OAA\_OCI\_COMPARTMENT** |-| To obtain this value, log in to the OCI console, navigate to **Identity and Security** and click **Compartments**. Select the compartment in which you created the vault and use the **OCID** value.|
|**OAA\_OCI\_VAULT_ID** |-| To obtain this value, log in to the OCI console, navigate to **Identity and Security** and select **Vault**. Select the vault you created earlier. See [Creating a Vault](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/preparing-oracle-cloud-infrastructure-enterprise-deployment.html). Use the **OCID** value.|
|**OAA\_OCI\_KEY** |-| To obtain this value, log in to the OCI console, navigate to **Identity and Security**, select **Vault**, and then click the vault you created earlier. See [Creating a Vault](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/preparing-oracle-cloud-infrastructure-enterprise-deployment.html). Click the key you created earlier. For example, `vaultkey`. Use the **OCID** value.|

#### Ingress Parameters

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**OAA\_ADMIN\_HOST** |`iadadmin.example.com`| The virtual host used for administration operations. Unless you are using OAA in the standalone mode, set this value to the OAM admin virtual host.|
|**OAA\_RUNTIME\_HOST** |`login.example.com`| The virtual host used for OAA runtime operations. Unless you are using OAA in the standalone mode, set this vale to the OAM virtual host.|


#### Email Server Parameters

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**OAA_EMAIL\_SERVER** |`http://governancedomain-cluster-soa-cluster.oigns.svc.cluster.local:8001/ucs/messaging/webservice`| The entry point of the Oracle Unified Messaging server. If the OIG domain is internal to the Kubernetes cluster, you can use the internal Kubernetes service name. For example: `http://<OIG_DOMAIN_NAME>-cluster-soa-cluster.<OIGNS>.svc.cluster.local:8001/ucs/messaging/webservice`. <p><p>If your UMS server is external to the Kubernetes cluster, you can use the URL you configured to access it. For example: `http://igdinternal.example.com/ucs/messaging/webservice`. |
|**OAA\_EMAIL\_USER** |`weblogic`| The user name you use to connect to the UMS server.|
|**OAA\_EMAIL\_PWD** |`umspassword`| The password you use to connect to the UMS server.|
|**OAA\_SMS\_SERVER** |`http://$OIG_DOMAIN_NAME-cluster-soa-cluster.$OIGNS.svc.cluster.local:8001/ucs/messaging/webservice`| The entry point of the Oracle Unified Messaging server you use to send SMS messages. This is usually the same as **OAA\_EMAIL\_SERVER**. |
|**OAA\_SMS\_USER** |`weblogic`| The user name you use to connect to the UMS server.|
|**OAA\_SMS_\PWD** |`umspassword`| The password you use to connect to the UMS server.|


#### Test User Parameters

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**OAA\_CREATE\_TESTUSER** |`true`| Set this value to `true` if you want the scripts to create a test user for OAA. |
|**OAA\_USER** |`oaauser`| The name you want to assign to the test user.|
|**OAA\_USER\_PWD** |`testpassword`| The password you want to assign to the test user.|
|**OAA\_USER\_EMAIL** |`test_user@example.com`| The email address of the test user you are creating.|
|**OAA\_USER\_POSTCODE** |-| The post code/zip code of the test user you are creating.|


#### HA Parameters

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**OAA\_REPLICAS** |`2`| The number of OAA service pods to be created. For HA, the minimum number is two.|
|**OAA\_ADMIN\_REPLICAS** |`2`| The number of OAA administration pods to be created. For HA, the minimum number is two.|
|**OAA\_POLICY\_REPLICAS** |`2`| The number of OAA policy pods to be created. For HA, the minimum number is two.|
|**OAA\_SPUI\_REPLICAS** |`2`| The number of OAA SPUI service pods to be created. For HA, the minimum number is two.|
|**OAA\_TOTP\_REPLICAS** |`2`| The number of OAA TOTP service pods to be created. For HA, the minimum number is two.|
|**OAA\_YOTP\_REPLICAS** |`2`| The number of OAA YOTP service pods to be created. For HA, the minimum number is two.|
|**OAA\_FIDO\_REPLICAS** |`2`| The number of OAA FIDO service pods to be created. For HA, the minimum number is two.|
|**OAA\_EMAIL\_REPLICAS** |`2`| The number of OAA EMAIL service pods to be created. For HA, the minimum number is two.|
|**OAA\_SMS\_REPLICAS** |`2`| The number of OAA SMS service pods to be created. For HA, the minimum number is two.|
|**OAA\_PUS\H_REPLICAS** |`2`| The number of OAA PUSH service pods to be created. For HA, the minimum number is two.|
|**OAA\_RISK\_REPLICAS** |`2`| The number of OAA RISK service pods to be created. For HA, the minimum number is two.|
|**OAA\_RISKCC\_REPLICAS** |`2`| The number of OAA RISK CC service pods to be created. For HA, the minimum number is two.|

### Port Mappings

In some cases, you can specify your own ports. The scripts allow you to override the default values by setting these parameters.

| **Parameter** | **Sample Value** | **Comments** |
| --- | --- | --- |
|**ELK\_KIBANA\_K8** |`31800`| The port to use for Kibana requests. <p>**Note**: This value must be within the Kubernetes service port range.|
|**ELK\_K8** |`31920`| The port to use for Elastic Search requests. <p>**Note**: This value must be within the Kubernetes service port range.|
|**PROM\_GRAF\_K8** |`30900`| The port to use for Grafana requests. <p>**Note**: This value must be within the Kubernetes service port range.|
|**PROM\_K8** |`30901`| The port to use for Prometheus requests. <p>**Note**: This value must be within the Kubernetes service port range.|
|**PROM\_ALERT\_K8** |`30902`| The port to use for Alert Manager requests. <p>**Note**: This value must be within the Kubernetes service port range.|
|**OUD\_LDAP\_K8** |`31389`| The port to use for OUD LDAP requests. <p>**Note**: This value must be within the Kubernetes service port range.|
|**OUD\_LDAPS\_K8** |`31636`| The port to use for OUD LDAPS requests. <p>**Note**: This value must be within the Kubernetes service port range.|
|**OUDSM\_SERVICE\_PORT** |`30901`| The port to use for OUDSM requests. <p>**Note**: This value must be within the Kubernetes service port range.|
|**OAM\_ADMIN\_PORT** |`7001`| The internal WebLogic administration port to use for the OAM domain. This port is available only in the Kubernetes cluster.|
|**OAM\_ADMIN\_K8** |`30701`| The external port to use for the OAM Administration Server requests.<p>**Note**: This value must be within the Kubernetes service port range.|
|**OAM\_OAM\_K8** |`30410`| The external port to use for the OAM Managed Server requests. <p>**Note**: This value must be within the Kubernetes service port range.|
|**OAM\_POLICY\_K8** |`30510`| The external port to use for the OAM Policy server requests. <p>**Note**: This value must be within the Kubernetes service port range.|
|**OAM\_OAP\_SERVICE\_PORT** |`30540`| The external port to use for the OAP server requests. This port is for legacy WebGates and is optional. <p>**Note**: This value must be within the Kubernetes service port range.|
|**OIG\_SO\A_PORT\_K8** |`30801`| The external port to use for the SOA Managed Server requests. <p>**Note**: This value must be within the Kubernetes service port range.|
|**OAM_OAP_PORT** |`5575`| The internal Kubernetes port used for OAM requests. <p>**Note**: This value must be within the Kubernetes service port range.|
|**OIG\_ADMIN\_PORT** |`7101`| The internal port used for the OIG WebLogic Administration Server.|
|**OIG\_ADMIN\_K8** |`30711`| The external port to use for the OIG Administration Server requests.<p>**Note**: This value must be within the Kubernetes service port range.|
|**OIG\_OIM\_PORT\_K8** |`30140`| The external port to use for the OIM Managed Server requests. <p>**Note**: This value must be within the Kubernetes service port range.|
|**OIG\_OIM\_T3\_PORT\_K8** |`30142`| The external port to use for the OIM Managed Server T3 requests. <p>**Note**: This value must be within the Kubernetes service port range.|
|**OHS\_PORT** |`7777`| The HTTP Server listen address.|


## Components of the Deployment Scripts

For reference purposes this section includes the name and function of all the objects making up the deployment scripts.

| **Name** | **Location** | **Function** |
| --- | --- | --- |
| **idm.rsp** | responsefile | Contains details of passwords used in the target environment. Needs to be updated for each deployment. |
| **.idmpwds** | responsefile | Contains details of the target environment. Needs to be updated for each deployment. |
| **start\_here.sh** | | Populates the responsefile. |
| **prereqchecks.sh** | | Checks the environment prior to provisioning. |
| **provision.sh** | | Provisions everything. |
| **provision\_ingress.sh** | | Installs/configures the Ingress controller.|
| **provision\_elk.sh** | | Installs/configures Elastic Search and Kibana.|
| **provision\_prom.sh** | | Installs/configures Prometheus and Grafana.|
| **provision\_oud.sh** | | Installs/configures OUD. |
| **provision\_oudsm.sh** | | Installs/configures OUDSM. |
| **provision\_oam.sh** | | Installs/configures OAM. |
| **provision\_oig.sh** | | Installs/configures OIG. |
| **provision\_oiri.sh** | | Installs/configures OIRI. |
| **provision\_oaa.sh** | | Installs/configures OAA.|
| **ingress\_functions.sh** | common | The common functions/procedures used by the Ingress provisioning scripts.|
| **functions.sh** | common | The common functions/procedures used by all provisioning scripts. |
| **prom\_functions.sh** | common | functions/procedures used by Prometheus provisioning scripts. |
| **oud\_functions.sh** | common | functions/procedures used by OUD and OUDSM provisioning scripts. |
| **oam\_functions.sh** | common | Common functions/procedures used by the oam provisioning scripts. |
| **oig\_functions.sh** | common | The common functions/procedures used by the OIG provisioning scripts. |
| **oiri\_functions.sh** | common | The common functions/procedures used by OIRI provisioning scripts. |
| **oaa\_functions.sh** | common | The common functions/procedures used by the OAA provisioning scripts. |
| **elk\_cluster.yaml** | templates/elk | Used to create an ELK Cluster. |
| **kibana.yaml** | templates/elk | Used to create an a Kibana Deployment. |
| **elk\_nodeport.yaml** | templates/elk | The template file to create an ELK NodePort service. |
| **kibana\_nodeport.yaml** | templates/elk | The template file to create an Kibana NodePort service. |
| **override_prom.yaml** | templates/prometheus | Used to create a Prometheus deployment. |
| **alert\_nodeport.yaml** | templates/prometheus | Used to create Alert Manager Node Port Service. |
| **grafana\_nodeport.yaml** | templates/prometheus | Used to create Grafana Node Port Service. |
| **prometheus\_nodeport.yaml** | templates/prometheus | Used to create Prometheus Node Port Service. |
| **base.ldif** | templates/oud | Used to seed OUD with users and groups. |
| **99-user.ldif** | templates/oud | Used to seed OUD schema changes. |
| **oud\_nodeport.yaml** | templates/oud | The template to create OUD NodePort services for Kubernetes. |
| **override\_oud.yaml** | templates/oud | OUD Helm override template file. |
| **oudsm\_nodeport.yaml** | templates/oudsm | The template to create OUDSM NodePort services for Kubernetes. |
| **override\_oudsm.yaml** | templates/oudsm | The OUD Helm override template file. |
| **add\_admin\_roles.py** | templates/oam | The template to add LDAP Groups to WebLogic Admin Role. |
| **configoam.props** | templates/oam | The template property file for running idmConfigTool -configOAM. |
| **runidmConfigTool.sh** | templates/oam | The template file to run idmConfigTool in container. |
| **fix\_gridlink.sh** | templates/oam | The template file to GridLink Enable Datasources. |
| **oamconfig\_modify\_template.xml** | templates/oam | Template file to perform initial OAM setup. |
| **oam\_nodeport.yaml** | templates/oam | The template file to create OAM Managed server NodePort service. |
| **oap\_clusterip.yaml** | templates/oam | The template file to create OAM OAP internal Managed server NodePort service. |
| **oap\_nodeport.yaml** | templates/oam | The template file to create OAM OAP external Managed server NodePort service. |
| **policy\_nodeport.yaml** | templates/oam | The template file to create Policy Manager Managed server NodePort service. |
| **resource\_list.txt** | templates/oam | The list of resources to add to OAM IAMSuite Resource list. |
| **set\_weblogic\_plugin.py** | templates/oam | The template file to enable WebLogic plug in in the domain. |
| **create\_wg.sh** | templates/oam | The template file to manually create Webgate Agent. |
| **Webgate\_IDM.xml** | templates/oam | The template property file to manually create Webgate Agent. |
| **config\_adf\_security.py** | templates/oam | Template file to create sso partner app. |
| **oamDomain.sedfile** | templates/oam | Template sed file to exit domain.yaml. |
| **oamSetUserOverrides.sh** | templates/oam | The template setUserOverrides.sh file. |
| **remove\_coherence.py** | templates/oam | The template file to remove OAM from default coherence cluster. |
| **update\_oamds.py** | templates/oam | The template file to update the OAMDS data source. |
| **login\_vh.conf** | templates/oam | The template file to create sample OHS Config. |
| **iadadmin\_vh.conf** | templates/oam | The template file to create sample OHS Config. |
| **create\_admin\_roles.py** | templates/oig | The template to assign LDAP Groups to WebLogic administration role. |
| **create\_oud\_authenticator.py** | templates/oig | The template file to create OUD Authenticator. |
| **get\_passphrase.sh** | templates/oig | The template file to obtain global passphrase from OAM. |
| **get\_passphrase.py** | templates/oig | The template file to obtain OAM Global passphrase. |
| **oam\_integration.sh** | templates/oig | The template file to run OIGOAMIntegration.sh -configureSSOIntegration. |
| **oigSetUserOverrides.sh** | templates/oig | The template setUserOverrides.sh file. |
| **soa\_nodeport.yaml** | templates/oig | The template file to create SOA external Managed server NodePort service. |
| **oim\_nodeport.yaml** | templates/oig | The template file to create OIM external Managed server NodePort service. |
| **add\_object\_classes.sh** | templates/oig | The template file to run IGOAMIntegration.sh -addMissingObjectClasses. |
| **createWLSAuthenticators.sh** | templates/oig | Template file to run OIGOAMIntegration.sh -configureWLSAuthnProviders. |
| **oam\_notifications.sh** | templates/oig | The template file to run OIGOAMIntegration.sh -enableOAMSessionDeletion. |
| **config\_connector.sh** | templates/oig | The template file to run OIGOAMIntegration.sh -configureLDAPConnector. |
| **create\_oim\_auth.sh** | templates/oig | The template file to run OIGOAMIntegration.sh -configureWLSAuthnProviders. |
| **runJob.sh** | templates/oig | The template shell script to run the reconciliation jobs. |
| **runJob.java** | templates/oig | The Java Script to run Reconciliation jobs. |
| **lib** | templates/oig | The OIM Libraries required by runJob.java. |
| **update\_soa.py** | templates/oig | The template script to update SOA URLS. |
| **oamoig.sedfile** | templates/oig | The Sedfile to create OIGOAMIntegration property files. |
| **autn.sedfile** | templates/oig | The supplementary Sedfile to create OIGOAMIntegration property files. |
| **create\_oigoam\_files.sh** | templates/oig | The template script to generate OIGOAMIntegration property files. |
| **fix\_gridlink.sh** | templates/oig | The template to enable gridlink on data sources. |
| **update\_match\_attr.sh** | templates/oig | The template script to update Match Attribute. |
| **oigDomain.sedfile** | templates/oig | The template script to update domain\_soa\_oim.yaml. |
| **update\_mds.py** | templates/oig | The template file to update MDS datasource. |
| **set\_weblogic\_plugin.py** | templates/oig | The template file to set WebLogic Plugin. |
| **update\_bi.py** | templates/oig | The template file to enable BI integration. |
| **igdinternal\_vh.conf** | templates/oig | The template file to create sample OHS Config. |
| **igdadmin\_vh.conf** | templates/oig | The template file to create sample OHS Config. |
| **prov\_vh.conf** | templates/oig | The template file to create sample OHS Config. |
| **createAdminUser.java** | templates/oiri | The template file to create the OIRI user names in OIG.|
| **createAdminUser.sh** | templates/oiri | Template file to create, compile, and run **createAdminUser.java**.|
| **setCompliance.java** | templates/oiri | The template file to place OIG into the Compliance Mode.|
| **setCompliance.sh** | templates/oiri | The template file to create, compile, and run **setCompliance.java**. |
| **oiri-cli.yaml** | templates/oiri | The template file to start OIRI CLI.|
| **ding-cli.yaml** | templates/oiri | The template file to start OIRI DING CLI.|
| **oiri\_nodeport.yaml** | templates/oiri | The template file to create the OIRI NodePort Service.|
| **oiriui\_nodeport.yaml** | templates/oiri | The template file to create the OIRI UI NodePort Service.|
| **ohs1.conf** | templates/oiri | The template file to create the sample OHS Config.|
| **ohs2.conf** | templates/oiri | The template file to create the sample OHS Config.|
| **create\_auth\_module.xml** | templates/oaa | The template file used to create the OAM authentication module.|
| **create\_auth\_policy.json** | templates/oaa | The template file to create the OAM authentication policy.|
| **create\_auth\_scheme.xml** | templates/oaa | The template file used to create the OAM authentication scheme.|
| **create\_ohs\_wallet.sh** | templates/oaa | The template file to create an Oracle HTTP server wallet.|
| **create\_ohs\_wallet.sh** | templates/oaa | The template file to create an Oracle HTTP server wallet.|
| **create\_schemas.sh** | templates/oaa | The template file used to create the OAA schemas.|
| **delete\_schemas** | templates/oaa | The template file used to delete OAA schemas.|
| **create\_tap\_partner.py** | templates/oaa | The template file to create the OAM TAP partner.|
| **enable\_oauth.xml** | templates/oaa | The template file to enable OAM OAuth.|
| **helmconfig** | templates/oaa | Template file for `helm`.|
| **oaa-mgmt-oci.yaml** | templates/oaa | The template file to create the OAA management pod when using the OCI vault.|
| **oaa-mgmt-vfsi.yaml** | templates/oaa | The template file to create OAA management pod when using the filesystem vault.|
| **oaaoverride.yaml** | templates/oaa | The template file for `helm` to set pod counts.|
| **ohs\_admin.conf** | templates/oaa | The template file for OAA administration OHS entries.|
| **ohs\_login.conf** | templates/oaa | The template file for OAA runtime OHS entries.|
| **ohs\_header.conf** | templates/oaa | The template file for OAM OAuth header entries for OHS.|
| **oud\_add\_existing\_users.sh** | templates/oaa | The template file to add existing user names to the OAA LDAP group.|
| **oud\_add\_users.sh** | templates/oaa | The template file to create OAA users and groups.|
| **users.ldif** | templates/oaa | The template file to create OAA users and groups in LDAP.|
| **oud\_test\_user.sh** | templates/oaa | The template file to create the OAA test user.|
| **test\_user.ldif** | templates/oaa | The template file used to create OAA test user in LDAP.|
| **test\_user.ldif** | templates/oaa | The template file used to create OAA test user in LDAP.|
| **delete\_image.sh** | utils | Deletes a container image from the Kubernetes worker hosts. |
| **delete\_all.sh** | utils | Deletes all deployments. |
| **delete\_elk.sh** | utils | Deletes Elastic Search deployment. |
| **delete\_prom.sh** | utils | Deletes Prometheus deployment. |
| **delete\_oam.sh** | utils | Deletes the OAM deployment. |
| **delete\_oig.sh** | utils | Deletes the OIG deployment. |
| **delete\_operator.sh** | utils | Deletes the WebLogic Kubernetes Operator deployment. |
| **delete\_oud.sh** | utils | Deletes the OUD deployment. |
| **delete\_oudsm.sh** | utils | Deletes the OUDSM deployment. |
| **delete\_oiri.sh** | utils | Deletes the OIRI deployment. |
| **delete\_oaa.sh** | utils | Deletes the OAA deployment. |
| **delete\_ingress.sh** | utils | Deletes the Ingress controller. |
| **load\_images.sh** | utils | Loads the container image onto each Kubernetes worker host. | 
