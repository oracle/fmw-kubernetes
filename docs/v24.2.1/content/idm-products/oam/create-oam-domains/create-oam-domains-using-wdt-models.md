+++
title = "b. Create OAM domains using WDT models"
+++

1. [Introduction](#introduction)
1. [Prerequisites](#prerequisites)
1. [Create OAM domains using WDT models](#create-oam-domains-using-wdt-models)
   
	a. [Prepare the persistent storage](#prepare-the-persistent-storage)
	
	b. [Create Kubernetes secrets for the domain and RCU](#create-kubernetes-secrets-for-the-domain-and-rcu)
	
	c. [Generate WDT models and the domain resource yaml file](#generate-wdt-models-and-the-domain-resource-yaml-file)
	
	d. [Build the Domain Creation Image](#build-the-domain-creation-image)
	
	e. [Deploy the OAM domain resource](#deploy-the-oam-domain-resource)
	
1. [Verify the results](#verify-the-results)
    
	a. [Verify the domain, pods and services](#verify-the-domain-pods-and-services)
	
	b. [Verify the domain](#verify-the-domain)
	
	c. [Verify the pods](#verify-the-pods)
	
	
### Introduction

This section demonstrates the creation of an OAM domain home using sample WebLogic Deploy Tooling (WDT) model files.

From WebLogic Kubernetes Operator version 4.1.2 onwards, you can provide a section, `domain.spec.configuration.initializeDomainOnPV`, to initialize an OAM domain on a persistent volume when it is first deployed. This eliminates the need to pre-create your OAM domain using sample Weblogic Scripting Tool (WLST) offline scripts.

With WLST offline scripts it is required to deploy a separate Kubernetes job that creates the domain on a persistent volume, and then deploy the domain with a custom resource YAML. The RCU schema also had to be created manually. Now, using WDT models, all the required information is specified in the domain custom resource YAML file, eliminating the requirement for a separate Kubernetes job.  With WDT models, the WebLogic Kubernetes Operator will create the RCU schemas, create the persistent volume and claim, then create the WebLogic domain on the persistent volume, prior to starting the servers.


**Note**: This is a one time only initialization. After the domain is created, subsequent updates to this section in the domain resource YAML file will not recreate or update the WebLogic domain. Subsequent domain lifecycle updates must be controlled by the WebLogic Server Administration Console, Enterprise Manager Console, WebLogic Scripting Tool (WLST), or other mechanisms.

Weblogic Deploy Tooling (WDT) models are a convenient and simple alternative to WebLogic Scripting Tool (WLST) configuration scripts. They compactly define a WebLogic domain using model files, variable properties files, and application archive files. For more information about the model format and its integration, see [Usage](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/usage/) and [Working with WDT Model files](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/model-files/). The WDT model format is fully described in the open source, [WebLogic Deploy Tooling GitHub project](https://oracle.github.io/weblogic-deploy-tooling/).

The main benefits of WDT are:

   * A set of single-purpose tools supporting Weblogic domain configuration lifecycle operations.
   * All tools work off of a shared, declarative model, eliminating the need to maintain specialized WLST scripts.
   * WDT knowledge base understands the MBeans, attributes, and WLST capabilities/bugs across WLS versions.

The initializeDomainOnPv section:

1. Creates the PersistentVolume (PV) and/or PersistenVolumeClaim (PVC).
1. Creates the RCU schema.
1. Creates the OAM domain home on the persistent volume based on the provided WDT models

### Prerequisites

Before you begin, perform the following steps:

1. Review the [Domain On PV](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/) documentation.
1. Ensure that the database is up and running.



### Create OAM domains using WDT models


In this section you will:

+ [Prepare the persistent storage](#prepare-the-persistent-storage).
+ [Create Kubernetes secrets for the domain and RCU](#create-kubernetes-secrets-for-the-domain-and-rcu).
+ [Generate the WDT models and the domain resource yaml file](#generate-wdt-models-and-the-domain-resource-yaml-file).
+ [Build the domain creation image hosting the WDT models and WDT installation](#build-the-domain-creation-image).
+ [Deploy the OAM domain resource](#deploy-the-oam-domain-resource)



**Note**: In this section a domain creation image is built using the supplied model files and that image is used for domain creation. You will need your own container registry to upload the domain image to. Having your own container repository is a prerequisite before creating an OAM domain with WDT models. If you don't have your own container registry, you can load the image on each node in the cluster instead. This documentation does not explain how to create your own container registry, or how to load the image onto each node. Consult your vendor specific documentation for more information.

**Note:** Building a domain creation image is a one time activity. The domain creation image can be used to create an OAM domain in multiple environments. You do not need to rebuild the domain creation image every time you create a domain.



#### Prepare the persistent storage

As referenced in [Prerequisites](../../prerequisites) the nodes in the Kubernetes cluster must have access to a persistent volume such as a Network File System (NFS) mount or a shared file system.

Domain on persistent volume (Domain on PV) is an operator [domain home source type](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/choosing-a-model/), which requires that the domain home exists on a persistent volume.

When a container is started, it needs to mount that volume. The physical volume should be on a shared disk accessible by all the Kubernetes worker nodes because it is not known on which worker node the container will be started. In the case of Oracle Identity and Access Management, the persistent volume does not get erased when a container stops. This enables persistent configurations.

The example below uses an NFS mounted volume (`<persistent_volume>/accessdomainpv`). Other volume types can also be used. See the official Kubernetes documentation for Volumes.

**Note**: The persistent volume directory needs to be accessible to both the master and worker node(s). In this example `/scratch/shared/accessdomainpv` is accessible from all nodes via NFS.

To create the persistent volume run the following commands:

1. Create the required directories:

   ```bash
   $ mkdir -p <persistent_volume>/accessdomainpv
   $ sudo chown -R 1000:0 <persistent_volume>/accessdomainpv
   ```

   For example:

   ```bash
   $ mkdir -p /scratch/shared/accessdomainpv
   $ sudo chown -R 1000:0 /scratch/shared/accessdomainpv
   ```

1. On the master node run the following command to ensure it is possible to read and write to the persistent volume:

   ```bash
   cd <persistent_volume>/accessdomainpv
   touch file.txt
   ls filemaster.txt
   ```

   For example:

   ```bash
   cd /scratch/shared/accessdomainpv
   touch filemaster.txt
   ls filemaster.txt
   ```

1. On the first worker node run the following to ensure it is possible to read and write to the persistent volume:

   ```bash
   cd /scratch/shared/accessdomainpv
   ls filemaster.txt
   touch fileworker1.txt
   ls fileworker1.txt
   ```
1. Repeat the above for any other worker nodes e.g fileworker2.txt etc. Once proven that it’s possible to read and write from each node to the persistent volume, delete the files created.

   For more information on PV and PVC requirements, see [Domain on Persistent Volume (PV)](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/usage/#references).

#### Create Kubernetes secrets for the domain and RCU

In this section you create the Kubernetes secrets for the OAM doman and RCU.

1. Create a Kubernetes secret for the domain using the create-weblogic-credentials script in the same Kubernetes namespace as the domain:

   ```bash
   $ cd $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils
   $ ./create-secret.sh -l "username=weblogic" -l "password=<password>" -n <domain_namespace> -d <domain_uid> -s <domain-uid>-weblogic-credentials
   ```

   where:

   `-n <domain_namespace>` is the domain namespace you created in [Create a namespace for Oracle Access Management](../../prepare-your-environment#create-a-namespace-for-oracle-access-management). For example `oamns`.

   `-d <domain_uid>` is the domain UID that you want to create. For example, `accessdomain`.

   `-s <domain-uid>-weblogic-credentials` is the name of the secret for this namespace. **Note**: the secret name must follow this format (`<domain-uid>-weblogic-credentials`) or domain creation will fail.

   For example:

   ```bash
   $ cd $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils
   $ ./create-secret.sh -l "username=weblogic" -l "password=<password>" -n oamns -d accessdomain -s accessdomain-weblogic-credentials
   ```
	
	
   
   The output will look similar to the following:


   ```bash
   @@ Info: Setting up secret 'accessdomain-weblogic-credentials'.
   secret/accessdomain-weblogic-credentials created
   secret/accessdomain-weblogic-credentials labeled
   ```

1. Verify the secret is created using the following command:

   ```bash
   $ kubectl get secret <kubernetes_domain_secret> -o yaml -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl get secret accessdomain-weblogic-credentials -o yaml -n oamns
   ```
   
   ```bash
   apiVersion: v1
   data:
     password: <password>
     username: d2VibG9naWM=
   kind: Secret
   metadata:
     creationTimestamp: "<DATE>"
     labels:
       weblogic.domainUID: accessdomain
     name: accessdomain-weblogic-credentials
     namespace: oamns
     resourceVersion: "44175245"
     uid: a135780e-6f3b-4be1-8643-f81bfb9ba399
   type: Opaque
   ```

1. Create a Kubernetes secret for RCU in the same Kubernetes namespace, using the `create-secrets.sh` script:


   ```bash
   $ cd $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils
   $ ./create-secret.sh -l "rcu_prefix=<rcu_prefix>" -l "rcu_schema_password=<rcu_schema_pwd>" -l "db_host=<db_host.domain>" -l "db_port=1521" -l "db_service=<service_name>" -l "dba_user=<sys_db_user>" -l "dba_password=<sys_db_pwd>" -n <domain_namespace> -d <domain_uid> -s <domain_uid>-rcu-credentials
   ```
   
   where

   `<rcu_prefix>` is the name of the RCU schema to be created.

   `<rcu_schema_pwd>` is the password you want to create for the RCU schema prefix.
   
   `<db_host.domain>` is the hostname.domain of the database.

   `<sys_db_user>` is the database user with sys dba privilege.

   `<sys_db_pwd>` is the sys database password.

   `<domain_uid>` is the `domain_uid` that you want to create. This must be the same `domain_uid` used in the domain secret. For example, `accessdomain`.

   `<domain_namespace>` is the domain namespace. This the domain namespace you created in [Create a namespace for Oracle Access Management](../../prepare-your-environment#create-a-namespace-for-oracle-access-management). For example `oamns`.

   `<domain_uid>-rcu-credentials` is the name of the rcu secret to create. **Note**: The secret name must follow this format (`<domain_uid>-rcu-credentials`) or domain creation will fail.

   For example:

   ```bash
   $ cd $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils
   $ ./create-secret.sh -l "rcu_prefix=OAMK8S" -l "rcu_schema_password=<password>" -l "db_host=mydatabasehost.example.com" -l "db_port=1521" -l "db_service=orcl.example.com" -l "dba_user=sys" -l "dba_password=<password>" -n oamns -d accessdomain -s accessdomain-rcu-credentials
   ```

   The output will look similar to the following:
   
   ```bash   
   @@ Info: Setting up secret 'accessdomain-rcu-credentials'.
   secret/accessdomain-rcu-credentials created
   secret/accessdomain-rcu-credentials labeled
   ```

1. Verify the secret is created using the following command:
   
   ```bash  
   $ kubectl get secret <kubernetes_rcu_secret> -o yaml -n <domain_namespace>
   ```
   For example:

   ```bash
   $ kubectl get secrets -n oamns accessdomain-rcu-credentials -o yaml
   ```

   The output will look similar to the following:

   ```bash
   apiVersion: v1
   data:
     db_host: <DB_HOST>
     db_port: MTUyMQ==
     db_service: <SERVICE_NAME>
     dba_password: <PASSWORD>
     dba_user: c3lz
     rcu_prefix: <RCU_PREFIX>
     rcu_schema_password: <RCU_PWD>
   kind: Secret
   metadata:
     creationTimestamp: "<DATE>"
     labels:
       weblogic.domainUID: accessdomain
     name: accessdomain-rcu-credentials
     namespace: oamns
     resourceVersion: "866948"
     uid: b5e3b4e0-9458-4413-a6ff-874e9af7511b
   type: Opaque
   ```


#### Generate WDT models and the domain resource yaml file

In this section you generate the required WDT models for the OAM domain, along with the domain resource yaml file. 

1. Navigate to the `$WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils/generate_models_utils` directory:

   ```bash
   $ cd $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils/generate_models_utils
   ```
   
1. Make a copy of the `create-domain-wdt.yaml` file:

   ```bash
   $ cp create-domain-wdt.yaml create-domain-wdt.yaml.orig
   ```

1. Edit the `create-domain-wdt.yaml` and modify the following parameters. Save the file when complete: 

   ```
   domainUID: <domain_uid>
   domainHome: /u01/oracle/user_projects/domains/<domain_uid>
   image: <image_name>:<tag>
   imagePullSecretName: <container_registry_secret>
   logHome: /u01/oracle/user_projects/domains/logs/<domain_uid>
   namespace: <domain_namespace>
   weblogicDomainStorageType: NFS
   weblogicDomainStorageNFSServer: <nfs_server>
   weblogicDomainStoragePath: <physical_path_of_persistent_storage>
   weblogicDomainStorageSize: 10G
   ```
	
	For example:
	
	```
   domainUID: accessdomain
   domainHome: /u01/oracle/user_projects/domains/accessdomain
   image: container-registry.oracle.com/middleware/oam_cpu:12.2.1.4-jdk8-ol8-<April'24>
   imagePullSecretName: orclcred
   logHome: /u01/oracle/user_projects/domains/logs/accessdomain
   namespace: oamns
   weblogicDomainStorageType: NFS
   weblogicDomainStorageNFSServer: mynfsserver
   weblogicDomainStoragePath: /scratch/shared/accessdomainpv
   weblogicDomainStorageSize: 10G
	```
	
	**Note** : If using a shared file system instead of NFS, set `weblogicDomainStorageType: HOST_PATH` and remove `weblogicDomainStorageNFSServer`.
  
  
   A full list of parameters in the `create-domain-wdt.yaml` file are shown below:
  
| Parameter | Definition | Default |
| --- | --- | --- |
| `adminPort` | Port number for the Administration Server inside the Kubernetes cluster. | `7001` |
| `adminNodePort` | Port number for the Administration Server outside the Kubernetes cluster. | `30701` |
| `configuredManagedServerCount` | Number of Managed Server instances to generate for the domain. | `5` |
| `datasourceType` | Type of JDBC datasource applicable for the OAM domain. Legal values are `agl` and `generic`. Choose `agl` for Active GridLink datasource and `generic` for Generic datasource. For enterprise deployments, Oracle recommends that you use GridLink data sources to connect to Oracle RAC databases. See the [Enterprise Deployment Guide](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/preparing-existing-database-enterprise-deployment.html#GUID-E3705EFF-AEF2-4F75-B5CE-1A829CDF0A1F) for further details. | `generic` |
| `domainHome` | Home directory of the OAM domain. If not specified, the value is derived from the `domainUID` as `/shared/domains/<domainUID>`. | `/u01/oracle/user_projects/domains/accessdomain` |
| `domainPVMountPath` | Mount path of the domain persistent volume. | `/u01/oracle/user_projects/domains` |
| `domainUID` | Unique ID that will be used to identify this particular domain. Used as the name of the generated WebLogic domain as well as the name of the Kubernetes domain resource. This ID must be unique across all domains in a Kubernetes cluster. This ID cannot contain any character that is not valid in a Kubernetes service name. | `accessdomain` |
| `edgInstall` | Used only if performing an install using the Enterprise Deployment Guide. See, [Enterprise Deployment Guide for Oracle Identity and Access Management in a Kubernetes Cluster](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg). | `false` |
| `exposeAdminNodePort` | Boolean indicating if the Administration Server is exposed outside of the Kubernetes cluster. | `false` |
| `exposeAdminT3Channel` | Boolean indicating if the T3 administrative channel is exposed outside the Kubernetes cluster. | `true` |
| `image` | OAM container image. The operator requires OAM 12.2.1.4. Refer to [Obtain the OAM container image](../../prepare-your-environment#obtain-the-oam-container-image) for details on how to obtain or create the image. For WDT domains you must use April 24 or later. | `oracle/oam:12.2.1.4.0` |
| `imagePullSecretName` | Name of the Kubernetes secret to access the container registry to pull the OAM container image. The presence of the secret will be validated when this parameter is specified. |  |
| `initialManagedServerReplicas` | Number of Managed Servers to initially start for the domain. | `2` |
| `javaOptions` | Java options for starting the Administration Server and Managed Servers. A Java option can have references to one or more of the following pre-defined variables to obtain WebLogic domain information: `$(DOMAIN_NAME)`, `$(DOMAIN_HOME)`, `$(ADMIN_NAME)`, `$(ADMIN_PORT)`, and `$(SERVER_NAME)`. | `-Dweblogic.StdoutDebugEnabled=false` |
| `logHome` | The in-pod location for the domain log, server logs, server out, and Node Manager log files. If not specified, the value is derived from the `domainUID` as `/shared/logs/<domainUID>`. | `/u01/oracle/user_projects/domains/logs/accessdomain` |
| `namespace` | Kubernetes namespace in which to create the domain. | `oamns` |
| `oamCPU` | Initial CPU Units, 1000m = 1 CPU core. | `1000m` |
| `oamMaxCPU` | Initial memory allocated to pod. | `2` |
| `oamMemory` | Initial memory allocated to a pod. | `4Gi` |
| `oamMaxMemory` | Max memory a pod is allowed to consume. | `8Gi` |
| `oamServerJavaParams` | The memory parameters to use for the OAM managed servers. | `"-Xms8192m -Xmx8192m"` |
| `productionModeEnabled` | Boolean indicating if production mode is enabled for the domain. | `true` |
| `t3PublicAddress` | Public address for the T3 channel.  This should be set to the public address of the Kubernetes cluster.  This would typically be a load balancer address. <p/>For development environments only: In a single server (all-in-one) Kubernetes deployment, this may be set to the address of the master, or at the very least, it must be set to the address of one of the worker nodes. | If not provided, the script will attempt to set it to the IP address of the Kubernetes cluster |
| `weblogicDomainStorageType` | Persistent volume storage type. Options are `NFS` for NFS volumes or `HOST_PATH` for shared file system. | `NFS` |
| `weblogicDomainStorageNFSServer` | Hostname or IP address of the NFS Server. | `nfsServer` |
| `weblogicDomainStoragePath` | Physical path to the persistent volume. | `/scratch/accessdomainpv` |
| `weblogicDomainStorageSize` | Total storage allocated to the persistent storage. | `10Gi` |
   
**Note**: The above CPU and memory values are for examples only. For Enterprise Deployments, please review the performance recommendations and sizing requirements in [Enterprise Deployment Guide for Oracle Identity and Access Management in a Kubernetes Cluster](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/procuring-resources-oracle-cloud-infrastructure-deployment.html#GUID-2E3C8D01-43EB-4691-B1D6-25B1DC2475AE). 

4. Run the `generate_wdt_models.sh`, specifying your input file and an output directory to store the generated artifacts:

   ```
	$ cd $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils/generate_models_utils
	$ ./generate_wdt_models.sh -i create-domain-wdt.yaml -o <path_to_output_directory>
   ```


   For example:
   
   ```bash
   $ cd $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils/generate_models_utils
   $ ./generate_wdt_models.sh -i create-domain-wdt.yaml -o output
   ```
	
	The output will look similar to the following:
	
   ```
   input parameters being used
   export version="create-weblogic-sample-domain-inputs-v1"
   export adminPort="7001"
   export domainUID="accessdomain"
   export configuredManagedServerCount="5"
   export initialManagedServerReplicas="1"
   export productionModeEnabled="true"
   export t3ChannelPort="30012"
   export datasourceType="generic"
   export edgInstall="false"
   export domainHome="/u01/oracle/user_projects/domains/accessdomain"
   export image="container-registry.oracle.com/middleware/oam_cpu:12.2.1.4-jdk8-ol8-<April'24>"
   export imagePullSecretName="orclcred"
   export logHome="/u01/oracle/user_projects/domains/logs/accessdomain"
   export exposeAdminT3Channel="false"
   export adminNodePort="30701"
   export exposeAdminNodePort="false"
   export namespace="oamns"
   javaOptions=-Dweblogic.StdoutDebugEnabled=false
   export domainPVMountPath="/u01/oracle/user_projects"
   export weblogicDomainStorageType="NFS"
   export weblogicDomainStorageNFSServer="mynfsServer"
   export weblogicDomainStoragePath="/scratch/shared/accessdomainpv"
   export weblogicDomainStorageReclaimPolicy="Retain"
   export weblogicDomainStorageSize="10Gi"
   export oamServerJavaParams="-Xms8192m -Xmx8192m"
   export oamMaxCPU="2"
   export oamCPU="1000m"
   export oamMaxMemory="8Gi"
   export oamMemory="4Gi"
	
   validateWlsDomainName called with accessdomain
   WDT model file, property file and sample domain.yaml are genereted successfully at output/weblogic-domains/accessdomain
	```
 
   This will generate `domain.yaml`, `oam.yaml` and `oam.properties` in `output/weblogic-domains/accessdomain`.

1. Copy the generated files to a `$WORKDIR/yaml` directory:

   ```
	$ mkdir $WORKDIR/yaml
	$ cp output/weblogic-domains/accessdomain/*.* $WORKDIR/yaml
	```


#### Build the Domain Creation Image

In this section you build a domain creation image to host the WDT model files and WebLogic Deploy Tooling (WDT) installer.

Domain creation images are used for supplying WDT model files, WDT variables files, WDT application archive files (collectively known as WDT model files), and the directory where the WebLogic Deploy Tooling software is installed (known as the WDT Home), when deploying a domain using a Domain on PV model. You distribute WDT model files and the WDT executable using these images, and the WebLogic Kubernetes Operator uses them to manage the domain.

**Note**: These images are only used for creating the domain and will not be used to update the domain. The domain creation image is used for domain creation only, it is not the product container image used for OAM.

For more details on creating the domain image, see [Domain creation images](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/domain-creation-images/).

The steps to build the domain creation image are shown in the sections below.

##### Prerequisites

Verify that your environment meets the following prerequisites:

* You have created the yaml files are per [Generate WDT models and the domain resource yaml file](#generate-wdt-models-and-the-domain-resource-yaml-file).
* You have a container registry available to push the domain creation image to.
* A container image client on the build machine, such as Docker or Podman.
  * For Docker, a minimum version of 18.03.1.ce is required.
  * For Podman, a minimum version of 3.0.1 is required.
* An installed version of JDK to run Image Tool, version 8+.
* Proxies are set accordingly at the OS level if required.

##### Prepare the build domain image script

The sample scripts for the Oracle Access Management domain image creation are available at `$WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image`.

1. Navigate to the `$WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/properties` directory:

   ```bash
   $ cd $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/properties
   ```
   
1. Make a copy of the `build-domain-creation-image.properties`:

   ```bash
   $ cp build-domain-creation-image.properties build-domain-creation-image.properties.orig
   ```

1. Edit the `build-domain-creation-image.properties` and modify the following parameters. Save the file when complete:

   ```
   JAVA_HOME=<Java home location>
   IMAGE_TAG=<Image tag name>
   REPOSITORY= <Container image repository to push the image>
   REG_USER= <Container registry username>
   IMAGE_PUSH_REQUIRES_AUTH=<Whether image push requires authentication to the registry>
   WDT_MODEL_FILE=<Full Path to WDT Model file oam.yaml> 
   WDT_VARIABLE_FILE=<Full path to WDT variable file oam.properties>
   WDT_ARCHIVE_FILE=<Full Path to WDT Archive file> 
   WDT_VERSION="Version of WebLogic Deploy Tool version to use"
   WIT_VERSION="Version of WebLogic Image Tool to use"
   ```
   
   For example:

   ```
   JAVA_HOME=/scratch/jdk
   IMAGE_TAG=oam-aux-generic-v1
   BASE_IMAGE=ghcr.io/oracle/oraclelinux:8-slim
   REPOSITORY=container-registry.example.com/mytenancy/idm
   REG_USER=mytenancy/myemail@example.com
   IMAGE_PUSH_REQUIRES_AUTH=true
   WDT_MODEL_FILE="/scratch/OAMK8S/fmw-kubernetes/OracleAccessManagement/yaml/oam.yaml"
   WDT_VARIABLE_FILE="/scratch/OAMK8S/fmw-kubernetes/OracleAccessManagement/oam.properties"
   WDT_ARCHIVE_FILE=""
   WDT_VERSION="3.5.3"
   WIT_VERSION="1.12.1"
   ```
	
   A full list of parameters and descriptions in the `build-domain-creation-image.properties` file are shown below:
	
| Parameter |	Definition | Default |
| --- |	--- | --- |
| JAVA_HOME | Path to the JAVA_HOME for the JDK8+. | |
| IMAGE_TAG | Image tag for the final domain creation image.| `oam-aux-generic-v1` |
| BASE_IMAGE | The Oracle Linux product container image to use as a base image.| `ghcr.io/oracle/oraclelinux:8-slim` |
| REPOSITORY | Container image repository that will host the domain creation image.| `iad.ocir.io/mytenancy/idm` |
| REG_USER | Username to authenticate to the `<REGISTRY>` and push the domain creation image.| `mytenancy/oracleidentitycloudservice/myemail@example.com` |
| IMAGE_PUSH_REQUIRES_AUTH | If authentication to `<REGISTRY>` is required then set to true, else set to false. If set to false, `<REG_USER>` is not required.| `true` |
| WDT_MODEL_FILE | Absolute path to WDT model file `oam.yaml`. For example `$WORKDIR/yaml/oam.yaml`. | |
| WDT_MODEL_FILE | Absolute path to WDT variable file `oam.properties`. For example `$WORKDIR/yaml/oam.properties`. | |
| WDT_ARCHIVE_FILE | Absolute path to WDT archive file. | |
| WDT_VERSION | WebLogic Deploy Tool version. If not specified the latest available version will be downloaded. It is recommended to use the default value.| `3.5.3` |
| WIT_VERSION | WebLogic Image Tool Version. If not specified the latest available version will be downloaded. It is recommended to use the default value.| `1.12.1` |
| TARGET | Select the target environment in which the created image will be used. Supported values: `Default` or `OpenShift`. See [Additional Information](https://oracle.github.io/weblogic-image-tool/userguide/tools/create-aux-image/#--target).| Default |
| CHOWN | `userid:groupid` to be used for creating files within the image, such as the WDT installer, WDT model, and WDT archive. If the user or group does not exist in the image, they will be added with `useradd`/`groupadd`.| `oracle:oracle` |

**Note**: If `IMAGE_PUSH_REQUIRES_AUTH=true`, you must edit the `$WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/properties/.regpassword` and change `<REGISTRY_PASSWORD>` to your registry password:
	
```
REG_PASSWORD="<REGISTRY_PASSWORD>"
```


##### Run the build-domain-creation-image script

1. Execute the `build-domain-creation-image.sh` by specifying the input properties parameter files:

   ```
	$ cd $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image
	$ ./build-domain-creation-image.sh -i properties/build-domain-creation-image.properties
	```
	
	**Note**: If using a password file, you must add `-p properties/.regpassword` to the end of the command.
	
	Executing this command will build the image and push it to the container registry. 
	
	**Note**: You can use the same same domain creation image to create a domain in multiple environments, based on your need. You do not need to rebuild it every time during domain creation. This is a one time activity.
	
	The output will look similar to the following:

   {{%expand "Click here to see example output:" %}}
   ```
   using WDT_DIR: /scratch/OAMK8S/fmw-kubernetes/OracleAccessManagement/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/workdir
   Using WDT_VERSION 3.5.3
   Using WIT_DIR /scratch/OAMK8S/fmw-kubernetes/OracleAccessManagement/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/workdir
   Using WIT_VERSION 1.12.1
   Using Image tag: oam-aux-generic-v1
   using Base Image: ghcr.io/oracle/oraclelinux:8-slim
   using IMAGE_BUILDER_EXE /usr/bin/podman
   JAVA_HOME is set to /scratch/jdk
   @@  Info: WIT_INSTALL_ZIP_URL is ''
   @@ WIT_INSTALL_ZIP_URL is not set
   @@ imagetool.sh not found in /scratch/OAMK8S/fmw-kubernetes/OracleAccessManagement/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/workdir/imagetool/bin. Installing imagetool...
   @@ Info:  Downloading https://github.com/oracle/weblogic-image-tool/releases/download/release-1.12.1/imagetool.zip
   @@ Info:  Downloading https://github.com/oracle/weblogic-image-tool/releases/download/release-1.12.1/imagetool.zip with https_proxy="http://proxy.example.com:80"
   @@ Info: Archive downloaded to /scratch/OAMK8S/fmw-kubernetes/OracleAccessManagement/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/workdir/imagetool.zip, about to unzip via '/home/opc/jdk/bin/jar xf'.
   @@ Info: imageTool cache does not contain a valid entry for wdt_3.5.3. Installing WDT
   @@  Info: WDT_INSTALL_ZIP_URL is ''
   @@ WDT_INSTALL_ZIP_URL is not set
   @@ Info:  Downloading https://github.com/oracle/weblogic-deploy-tooling/releases/download/release-3.5.3/weblogic-deploy.zip
   @@ Info:  Downloading https://github.com/oracle/weblogic-deploy-tooling/releases/download/release-3.5.3/weblogic-deploy.zip with https_proxy="http://proxy.example.com:80"
   @@ Info: Archive downloaded to /scratch/OAMK8S/fmw-kubernetes/OracleAccessManagement/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/workdir/weblogic-deploy.zip
   [INFO   ] Successfully added to cache. wdt_3.5.3=/scratch/OAMK8S/fmw-kubernetes/OracleAccessManagement/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/workdir/weblogic-deploy.zip
   @@ Info: Install succeeded, imagetool install is in the /scratch/OAMK8S/fmw-kubernetes/OracleAccessManagement/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/workdir/imagetool directory.
   Starting Building Image registry.example.com/mytenancy/idm:oam-aux-generic-v1
	Login Succeeded!
   WDT_MODEL_FILE is set to /scratch/OAMK8S/fmw-kubernetes/OracleAccessManagement/yaml/oam.yaml
   WDT_VARIABLE_FILE is set to /scratch/OAMK8S/fmw-kubernetes/OracleAccessManagement/yaml/oam.properties
   Additional Build Commands file is set to /scratch/OAMK8S/fmw-kubernetes/OracleAccessManagement/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/additonal-build-files/build-files.txt
   Additonal Build file is set to /scratch/OAMK8S/fmw-kubernetes/OracleAccessManagement/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/additonal-build-files/OAM.json
   [INFO   ] WebLogic Image Tool version 1.12.1
   [INFO   ] Image Tool build ID: 0c9aa58f-808b-4707-a11a-7766fb301cbb
   [INFO   ] Temporary directory used for image build context: /home/oracle/wlsimgbuilder_temp1198331326550546381
   [INFO   ] Copying /scratch/OAMK8S/fmw-kubernetes/OracleAccessManagement/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/additonal-build-files/OAM.json to build context folder.
   [INFO   ] User specified fromImage ghcr.io/oracle/oraclelinux:8-slim
   [INFO   ] Inspecting ghcr.io/oracle/oraclelinux:8-slim, this may take a few minutes if the image is not available locally.
   [INFO   ] Copying /scratch/OAMK8S/fmw-kubernetes/OracleAccessManagement/yaml/oam.yaml to build context folder.
   [INFO   ] Copying /scratch/OAMK8S/fmw-kubernetes/OracleAccessManagement/yaml/oam.properties to build context folder.
   [INFO   ] Copying /scratch/OAMK8S/fmw-kubernetes/OracleAccessManagement/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/workdir/weblogic-deploy.zip to build context folder.
   [INFO   ] Starting build: /usr/bin/podman build --no-cache --force-rm --tag registry.example.com/mytenancy/idm:oam-aux-generic-v1 --pull --build-arg http_proxy=http://proxy.example.com:80 --build-arg https_proxy=http://proxy.example.com:80 --build-arg no_proxy=localhost,127.0.0.0/8,.example.com,,/var/run/crio/crio.sock,X.X.X.X /home/oracle/wlsimgbuilder_temp1198331326550546381
   [1/3] STEP 1/5: FROM ghcr.io/oracle/oraclelinux:8-slim AS os_update
   [1/3] STEP 2/5: LABEL com.oracle.weblogic.imagetool.buildid="0c9aa58f-808b-4707-a11a-7766fb301cbb"
   --> ba91c351bf94
   [1/3] STEP 3/5: USER root
   --> d8f89c65892a
   [1/3] STEP 4/5: RUN microdnf update     && microdnf install gzip tar unzip libaio libnsl jq findutils diffutils shadow-utils     && microdnf clean all
   Downloading metadata...
   Downloading metadata...
   Package                                         Repository            Size
   Upgrading:
    libgcc-8.5.0-20.0.3.el8.x86_64                 ol8_baseos_latest  93.4 kB
     replacing libgcc-8.5.0-20.0.2.el8.x86_64
    libstdc++-8.5.0-20.0.3.el8.x86_64              ol8_baseos_latest 474.6 kB
     replacing libstdc++-8.5.0-20.0.2.el8.x86_64
    systemd-libs-239-78.0.4.el8.x86_64             ol8_baseos_latest   1.2 MB
      replacing systemd-libs-239-78.0.3.el8.x86_64
   Transaction Summary:
    Installing:        0 packages
    Reinstalling:      0 packages
    Upgrading:         3 packages
    Obsoleting:        0 packages
    Removing:          0 packages
    Downgrading:       0 packages
   Downloading packages...
   Running transaction test...
   Updating: libgcc;8.5.0-20.0.3.el8;x86_64;ol8_baseos_latest
   Updating: libstdc++;8.5.0-20.0.3.el8;x86_64;ol8_baseos_latest
   Updating: systemd-libs;239-78.0.4.el8;x86_64;ol8_baseos_latest
   Cleanup: libstdc++;8.5.0-20.0.2.el8;x86_64;installed
   Cleanup: systemd-libs;239-78.0.3.el8;x86_64;installed
   Cleanup: libgcc;8.5.0-20.0.2.el8;x86_64;installed
   Complete.
   Package                           Repository            Size
   Installing:
    diffutils-3.6-6.el8.x86_64       ol8_baseos_latest 369.3 kB
    findutils-1:4.6.0-21.el8.x86_64  ol8_baseos_latest 539.8 kB
    gzip-1.9-13.el8_5.x86_64         ol8_baseos_latest 170.7 kB
    jq-1.6-7.0.3.el8.x86_64          ol8_appstream     206.5 kB
    libaio-0.3.112-1.el8.x86_64      ol8_baseos_latest  33.4 kB
    libnsl-2.28-236.0.1.el8.7.x86_64 ol8_baseos_latest 111.4 kB
    oniguruma-6.8.2-2.1.el8_9.x86_64 ol8_appstream     191.5 kB
    unzip-6.0-46.0.1.el8.x86_64      ol8_baseos_latest 201.0 kB
   Transaction Summary:
   Installing:        8 packages
    Reinstalling:      0 packages
    Upgrading:         0 packages
    Obsoleting:        0 packages
    Removing:          0 packages
    Downgrading:       0 packages
   Downloading packages...
   Running transaction test...
   Installing: oniguruma;6.8.2-2.1.el8_9;x86_64;ol8_appstream
   Installing: jq;1.6-7.0.3.el8;x86_64;ol8_appstream
   Installing: unzip;6.0-46.0.1.el8;x86_64;ol8_baseos_latest
   Installing: libnsl;2.28-236.0.1.el8.7;x86_64;ol8_baseos_latest
   Installing: libaio;0.3.112-1.el8;x86_64;ol8_baseos_latest
   Installing: gzip;1.9-13.el8_5;x86_64;ol8_baseos_latest
   Installing: findutils;1:4.6.0-21.el8;x86_64;ol8_baseos_latest
   Installing: diffutils;3.6-6.el8;x86_64;ol8_baseos_latest
   Complete.
   Complete.
   --> 73fb79fa40b2
   [1/3] STEP 5/5: RUN if [ -z "$(getent group oracle)" ]; then groupadd oracle || exit 1 ; fi  && if [ -z "$(getent group oracle)" ]; then groupadd oracle || exit 1 ; fi  && if [ -z "$(getent passwd oracle)" ]; then useradd -g oracle oracle || exit 1; fi  && mkdir -p /u01  && chown oracle:oracle /u01  && chmod 775 /u01
   --> ff6cf74351d1
   [2/3] STEP 1/4: FROM ff6cf74351d1e0124121321174eaa64ebefa0bc3eef80ec88caec12feb9e8fb3 AS wdt_build
   [2/3] STEP 2/4: RUN mkdir -p /auxiliary  && mkdir -p /auxiliary/models  && chown oracle:oracle /auxiliary
   --> a061b678fa0a
   [2/3] STEP 3/4: COPY --chown=oracle:oracle ["weblogic-deploy.zip", "/tmp/imagetool/"]
   --> 3daccfef2f06
   [2/3] STEP 4/4: RUN test -d /auxiliary/weblogic-deploy && rm -rf /auxiliary/weblogic-deploy || echo Initial WDT install         && unzip -q "/tmp/imagetool/weblogic-deploy.zip" -d /auxiliary
   Initial WDT install
   --> b77b02f66a83
   [3/3] STEP 1/12: FROM ff6cf74351d1e0124121321174eaa64ebefa0bc3eef80ec88caec12feb9e8fb3 AS final
   [3/3] STEP 2/12: ENV AUXILIARY_IMAGE_PATH=/auxiliary     WDT_HOME=/auxiliary     WDT_MODEL_HOME=/auxiliary/models
   --> 10dc1832266f
   [3/3] STEP 3/12: RUN mkdir -p /auxiliary && chown oracle:oracle /auxiliary
   --> 0b85f8e7399a
   [3/3] STEP 4/12: COPY --from=wdt_build --chown=oracle:oracle /auxiliary /auxiliary/
   --> c64bf2bef430
   [3/3] STEP 5/12: RUN mkdir -p /auxiliary/models && chown oracle:oracle /auxiliary/models
   --> d8817f84ab58
   [3/3] STEP 6/12: COPY --chown=oracle:oracle ["oam.yaml", "/auxiliary/models/"]
   --> 45b1d25264b9
   [3/3] STEP 7/12: COPY --chown=oracle:oracle ["oam.properties", "/auxiliary/models/"]
   --> 2ceba77ee226
   [3/3] STEP 8/12: RUN chmod -R 640 /auxiliary/models/*
   --> 34385bac7974
   [3/3] STEP 9/12: USER oracle
   --> 409f6e3ccce4
   [3/3] STEP 10/12: WORKDIR /auxiliary
   --> aaa2f154f512
   [3/3] STEP 11/12: COPY --chown=oracle:oracle files/OAM.json /auxiliary/weblogic-deploy/lib/typedefs
   --> c8a9d29106d3
   [3/3] STEP 12/12: RUN chmod -R 755 /auxiliary
   [3/3] COMMIT registry.example.com/mytenancy/idm:oam-aux-generic-v1
   --> 0797418499a1
   Successfully tagged registry.example.com/mytenancy/idm:oam-aux-generic-v1
   0797418499a1dfd6d2a28672948c17ed747291ad069cebca5fac1b0410978d75
   [INFO   ] Build successful. Build time=72s. Image tag=registry.example.com/mytenancy/idm:oam-aux-generic-v1
   Getting image source signatures
	Copying blob 462ffb36555c done
   Copying blob 3db4d3748983 done
   Copying blob 7e9f3f6c7a0a done
   Copying blob 32aa5f13e19b done
   Copying blob d979da323f64 done
   Copying blob f18b9e5f415f done
   Copying blob aaaea7c1392f done
   Copying blob 5504fa641a87 done
   Copying blob 5aa81493c602 done
   Copying blob f56f992ba90d done
   Copying blob 2b1e0644fbd3 done
   Copying config a39dc6ae7f done
   Writing manifest to image destination
   Pushed image registry.example.com/mytenancy/idm/oam-aux-generic-v1 to image registry Docker Hub	
   ```
	{{% /expand %}}



#### Deploy the OAM domain resource

In this section you modify the OAM `domain.yaml` and deploy the OAM domain using the build image created.

##### Modify the OAM domain.yaml

In this section you modify the `domain.yaml` file in preparation for creating the OAM domain.

1. Edit the `$WORKDIR/yaml/domain.yaml` and update the `%DOMAIN_CREATION_IMAGE%` with the previously generated image name.

   **Note**: `%DOMAIN_CREATION_IMAGE%` takes the format of `<REPOSITORY>:<TAG>`:

   ```
   domain:
            # Domain | DomainAndRCU
            createIfNotExists: DomainAndRCU
            # Image containing WDT installer and Model files.
            domainCreationImages:
                - image: '%DOMAIN_CREATION_IMAGE%'
            domainType: OAM

   ```
	
	For example:
	
	```
   domain:
            # Domain | DomainAndRCU
            createIfNotExists: DomainAndRCU
            # Image containing WDT installer and Model files.
            domainCreationImages:
                - image: 'container-registry.example.com/mytenancy/idm:oam-aux-generic-v1'
            domainType: OAM

   ```

1. In circumstances where you may be pulling the OAM product container image from Oracle Container Registry, and then the domain image from a private registry, you must first create a secret (privatecred) for the private registry. For example:

   ```
   $ kubectl create secret docker-registry "privatecred" --docker-server=container-registry.example.com \
   --docker-username="user@example.com" \
   --docker-password=password --docker-email=user@example.com \
   --namespace=oamns
   ```

   Then specify both secrets for `imagePullSecrets` in the `domain.yaml`. For example:

   ```
	...
   spec:
     # The WebLogic Domain Home
     domainHome: /u01/oracle/user_projects/domains/accessdomain

     # The domain home source type
     # Set to PersistentVolume for domain-in-pv, Image for domain-in-image, or FromModel for model-in-image
     domainHomeSourceType: PersistentVolume

     # The WebLogic Server image that the Operator uses to start the domain
     image: "container-registry.oracle.com/middleware/oam_cpu:12.2.1.4-jdk8-ol8-<April'24>"

     # imagePullPolicy defaults to "Always" if image version is :latest
     imagePullPolicy: IfNotPresent

     imagePullSecrets:
     - name: orclcred
     - name: privatecred
     # Identify which Secret contains the WebLogic Admin credentials
   ...
   ```

   For more information about the configuration parameters in `domain.yaml`, see [Domain Resources](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-resource/). 
   
   
   {{%expand "Click here to see an example domain.yaml:" %}}
   ```
   # Copyright (c) 2024, Oracle and/or its affiliates.
   # Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
   #
   # This is an example of how to define an OAM Domain. For details about the fields in domain specification, refer https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-resource/
   #
   apiVersion: "weblogic.oracle/v9"
   kind: Domain
   metadata:
     name: accessdomain
     namespace: oamns
     labels:
       weblogic.domainUID: accessdomain
   spec:
     # The WebLogic Domain Home
     domainHome: /u01/oracle/user_projects/domains/accessdomain
   
     # The domain home source type
     # Set to PersistentVolume for domain-in-pv, Image for domain-in-image, or FromModel for model-in-image
     domainHomeSourceType: PersistentVolume
   
     # The WebLogic Server image that the Operator uses to start the domain
     image: "container-registry.oracle.com/middleware/oam_cpu:12.2.1.4-jdk8-ol8-<April'24>"
   
     # imagePullPolicy defaults to "Always" if image version is :latest
     imagePullPolicy: IfNotPresent
   
     # Add additional secret name if you are using a different registry for domain creation image.
     # Identify which Secret contains the credentials for pulling an image
     imagePullSecrets:
     - name: orclcred
     - name: privatecred
     # Identify which Secret contains the WebLogic Admin credentials
     webLogicCredentialsSecret:
       name: accessdomain-weblogic-credentials
   
     # Whether to include the server out file into the pod's stdout, default is true
     includeServerOutInPodLog: true
   
     # Whether to enable log home
     logHomeEnabled: true
   
     # Whether to write HTTP access log file to log home
     httpAccessLogInLogHome: true
   
     # The in-pod location for domain log, server logs, server out, introspector out, and Node Manager log files
     logHome: /u01/oracle/user_projects/domains/logs/accessdomain
     # An (optional) in-pod location for data storage of default and custom file stores.
     # If not specified or the value is either not set or empty (e.g. dataHome: "") then the
     # data storage directories are determined from the WebLogic domain home configuration.
     dataHome: ""
   
     # serverStartPolicy legal values are "Never, "IfNeeded", or "AdminOnly"
     # This determines which WebLogic Servers the Operator will start up when it discovers this Domain
     # - "Never" will not start any server in the domain
     # - "AdminOnly" will start up only the administration server (no managed servers will be started)
     # - "IfNeeded" will start all non-clustered servers, including the administration server and clustered servers up to the replica count
     serverStartPolicy: IfNeeded
   
     serverPod:
       initContainers:
         #DO NOT CHANGE THE NAME OF THIS INIT CONTAINER
         - name: compat-connector-init
           # OAM Product image, same as spec.image mentioned above
           image: "container-registry.oracle.com/middleware/oam_cpu:12.2.1.4-jdk8-ol8-<April'24>"
           imagePullPolicy: IfNotPresent
           command: [ "/bin/bash", "-c", "mkdir -p  /u01/oracle/user_projects/domains/wdt-logs"]
           volumeMounts:
             - mountPath: /u01/oracle/user_projects
               name: weblogic-domain-storage-volume
       # a mandatory list of environment variable to be set on the servers
       env:
       - name: JAVA_OPTIONS
         value: -Dweblogic.StdoutDebugEnabled=false
       - name: USER_MEM_ARGS
         value: "-Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx1024m "
       - name: WLSDEPLOY_LOG_DIRECTORY
         value: "/u01/oracle/user_projects/domains/wdt-logs"
       - name: WLSDEPLOY_PROPERTIES
         value: "-Dwdt.config.disable.rcu.drop.schema=true"
       volumes:
       - name: weblogic-domain-storage-volume
         persistentVolumeClaim:
           claimName: accessdomain-domain-pvc
       volumeMounts:
       - mountPath: /u01/oracle/user_projects
         name: weblogic-domain-storage-volume

     # adminServer is used to configure the desired behavior for starting the administration server.
     adminServer:
       # adminService:
       #   channels:
       # The Admin Server's NodePort
       #    - channelName: default
       #      nodePort: 30701
       # Uncomment to export the T3Channel as a service
       #    - channelName: T3Channel
       serverPod:
         # an (optional) list of environment variable to be set on the admin servers
         env:
         - name: USER_MEM_ARGS
           value: "-Djava.security.egd=file:/dev/./urandom -Xms512m -Xmx1024m "
         - name: CLASSPATH
           value: "/u01/oracle/wlserver/server/lib/weblogic.jar"
   
     configuration:
         secrets: [ accessdomain-rcu-credentials ]
         initializeDomainOnPV:
           persistentVolume:
             metadata:
                 name: accessdomain-domain-pv
             spec:
               storageClassName: accessdomain-domain-storage-class
               capacity:
             # Total storage allocated to the persistent storage.
                   storage: 10Gi
             # Reclaim policy of the persistent storage
             # # The valid values are: 'Retain', 'Delete', and 'Recycle'
               persistentVolumeReclaimPolicy: Retain
             # Persistent volume type for the persistent storage.
             # # The value must be 'hostPath' or 'nfs'.
             # # If using 'nfs', server must be specified.
              nfs:
                 server: mynfserver
               # hostPath:
                 path: "/scratch/shared/accessdomainpv"
           persistentVolumeClaim:
             metadata:
                 name: accessdomain-domain-pvc
             spec:
               storageClassName: accessdomain-domain-storage-class
               resources:
                   requests:
                       storage: 10Gi
               volumeName: accessdomain-domain-pv
           domain:
               # Domain | DomainAndRCU
               createIfNotExists: DomainAndRCU
               # Image containing WDT installer and Model files.
               domainCreationImages:
                   - image: 'container-registry.example.com/mytenancy/idm:oam-aux-generic-v1'
               domainType: OAM
     # References to Cluster resources that describe the lifecycle options for all
     # the Managed Server members of a WebLogic cluster, including Java
     # options, environment variables, additional Pod content, and the ability to
     # explicitly start, stop, or restart cluster members. The Cluster resource
     # must describe a cluster that already exists in the WebLogic domain
     # configuration.
     clusters:
     - name: accessdomain-oam-cluster
     - name: accessdomain-policy-cluster
   
     # The number of managed servers to start for unlisted clusters
     # replicas: 1
   
   ---
   # This is an example of how to define a Cluster resource.
   apiVersion: weblogic.oracle/v1
   kind: Cluster
   metadata:
     name: accessdomain-oam-cluster
     namespace: oamns
   spec:
     clusterName: oam_cluster
     serverService:
       precreateService: true
     replicas: 1
     serverPod:
     serverPod:
       env:
       - name: USER_MEM_ARGS
         value: "-XX:+UseContainerSupport -Djava.security.egd=file:/dev/./urandom -Xms8192m -Xmx8192m "
       resources:
         limits:
           cpu: "2"
           memory: "8Gi"
         requests:
           cpu: "1000m"
           memory: "4Gi"


   ---  
   # This is an example of how to define a Cluster resource.
   apiVersion: weblogic.oracle/v1
   kind: Cluster
   metadata:
     name: accessdomain-policy-cluster
     namespace: oamns
   spec:
     clusterName: policy_cluster
     serverService:
       precreateService: true
     replicas: 1
	```
	
	{{% /expand %}}

    **Note**: By default, WebLogic operator will create the RCU schema using WDT tooling during every domain deployment. If the RCU Schema with the given prefix already exists, and error will be thrown and the domain creation will fail. If you want to delete the schema every time during domain deployment, then can use change the value `"-Dwdt.config.disable.rcu.drop.schema=true"` to `"-Dwdt.config.disable.rcu.drop.schema=false"`.
	 
#####  Optional WDT Models ConfigMap

If required, you can provide a Kubernetes ConfigMap with additional WDT models and WDT variables files as supplements, or overrides, to those in `domainCreationImages`. For example in the  `output/weblogic-domains/accessdomain/domain.yaml`:

```
      domain:
          ...
          domainCreationImages:
              ...
          domainCreationConfigMap: mymodel-domain-configmap
```

The files inside `domainCreationConfigMap` must have file extensions, `.yaml`, `.properties`, or `.zip`.

1. To create a configmap run the following command:

   ```
	$ cd $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils
	$ ./create-configmap.sh -n oamns -d accessdomain -c mymodel-domain-configmap -f wdt_models/mymodel.yaml
   ```


For more information on the usage of additional configuration, see [Optional WDT models ConfigMap](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/usage/#optional-wdt-models-configmap).

##### Deploy the OAM domain

In this section you deploy the OAM domain using the `domain.yaml`.

1. Run the following command to create OAM domain resources:

   ```bash
   $ kubectl create -f $WORKDIR/yaml/domain.yaml
   ```

   The following steps will be performed by WebLogic Kubernetes Operator:
   
   + Run the introspector job.
	+ The introspection job will create the RCU Schemas.
   + The introspector job pod will create the domain on PV using the model provided in the domain creation image.
   + The introspector job pod will execute OAM offline configuration actions post successful creation of domain via WDT.
   + Brings up the Administration Server, OAM server (`oam_server1`), and the OAM Policy Managed Server (`oam_policy_mgr1`).
   
   
   The output will look similar to the following:

   ```
   domain.weblogic.oracle/accessdomain created
   cluster.weblogic.oracle/accessdomain-oam-cluster created
   cluster.weblogic.oracle/accessdomain-policy-cluster created
   ```
   
   Whilst the domain creation is running, you can run the following command to monitor the progress:
   
   ```bash
   $ kubectl get pods -n oamns -w
   ```

   You can also tail the logs for the pods by running:

   ```bash
   $ kubectl logs -f <pod> -n oamns
   ```

   WDT specific logs can be found in `<persistent_volume>/domains/wdt-logs`.

   Once everything is started you should see the Administration Server and OAM servers are running:
   
   ```
   NAME                           READY   STATUS    RESTARTS        AGE
   accessdomain-adminserver       1/1     Running   0               11m
   accessdomain-oam-policy-mgr1   1/1     Running   0               3m53s
   accessdomain-oam-server1       1/1     Running   0               3m53s
   ```

  If there are any failures, follow **Domain creation failure with WDT models** in the [Troubleshooting](../../troubleshooting/#domain-creation-failure-with-wdt-models) section.

### Verify the results

### Verify the domain, pods and services

1. Verify the domain, servers pods and services are created and in the `READY` state with a `STATUS` of `1/1`, by running the following command:

   ```bash
   $ kubectl get all,domains -n <domain_namespace>
   ```

   For example:

   ```bash
   $ kubectl get all,domains -n oamns
   ```

   The output will look similar to the following:

   ```bash
   NAME                               READY   STATUS    RESTARTS        AGE
   pod/accessdomain-adminserver       1/1     Running   0               12m
   pod/accessdomain-oam-policy-mgr1   1/1     Running   0               4m19s
   pod/accessdomain-oam-server1       1/1     Running   0               4m19s

   NAME                                          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)     AGE
   service/accessdomain-adminserver              ClusterIP   None             <none>        7001/TCP    12m
   service/accessdomain-cluster-oam-cluster      ClusterIP   10.104.17.83     <none>        14100/TCP   4m19s
   service/accessdomain-cluster-policy-cluster   ClusterIP   10.98.157.157    <none>        15100/TCP   4m19s
   service/accessdomain-oam-policy-mgr1          ClusterIP   None             <none>        15100/TCP   4m19s
   service/accessdomain-oam-policy-mgr2          ClusterIP   10.101.141.238   <none>        15100/TCP   4m19s
   service/accessdomain-oam-policy-mgr3          ClusterIP   10.107.167.143   <none>        15100/TCP   4m19s
   service/accessdomain-oam-policy-mgr4          ClusterIP   10.106.100.191   <none>        15100/TCP   4m19s
   service/accessdomain-oam-policy-mgr5          ClusterIP   10.105.5.126     <none>        15100/TCP   4m19s
   service/accessdomain-oam-server1              ClusterIP   None             <none>        14100/TCP   4m19s
   service/accessdomain-oam-server2              ClusterIP   10.98.248.74     <none>        14100/TCP   4m19s
   service/accessdomain-oam-server3              ClusterIP   10.106.224.54    <none>        14100/TCP   4m19s
   service/accessdomain-oam-server4              ClusterIP   10.104.241.109   <none>        14100/TCP   4m19s
   service/accessdomain-oam-server5              ClusterIP   10.96.189.205    <none>        14100/TCP   4m19s

   NAME                                  AGE
   domain.weblogic.oracle/accessdomain   18m

   NAME                                                  AGE
   cluster.weblogic.oracle/accessdomain-oam-cluster      18m
   cluster.weblogic.oracle/accessdomain-policy-cluster   18m
   ```

   The default domain created by the script has the following characteristics:

   * An Administration Server named `AdminServer` listening on port 7001.
   * A configured OAM cluster named `oam_cluster` of size 5.
   * A configured Policy cluster named `policy_cluster` of size 5.
   * One started OAM managed Server, named `oam_server1`, listening on port 14100.
   * One started Policy managed Server, named `oam-policy-mgr1`, listening on port 15100.
   * Log files that are located in `<persistent_volume>/logs/<domainUID>`.

### Verify the domain

1. Run the following command to describe the domain:

   ```bash
   $ kubectl describe domain <domain_uid> -n <namespace>
   ```

   For example:

   ```bash
   $ kubectl describe domain accessdomain -n oamns
   ```

   
	
	{{%expand "Click here to see example output:" %}}
   ```bash
	Name:         accessdomain
	Namespace:    oamns
	Labels:       weblogic.domainUID=accessdomain
	Annotations:  <none>
	API Version:  weblogic.oracle/v9
	Kind:         Domain
	Metadata:
	  Creation Timestamp:  <DATE>
	  Generation:          1
	  Managed Fields:
		API Version:  weblogic.oracle/v9
		Fields Type:  FieldsV1
		fieldsV1:
		  f:metadata:
			f:labels:
			  .:
			  f:weblogic.domainUID:
		  f:spec:
			.:
			f:adminServer:
			  .:
			  f:adminChannelPortForwardingEnabled:
			  f:serverPod:
				.:
				f:env:
			  f:serverStartPolicy:
			f:clusters:
			f:configuration:
			  .:
			  f:initializeDomainOnPV:
				.:
				f:domain:
				  .:
				  f:createIfNotExists:
				  f:domainCreationImages:
				  f:domainType:
				f:persistentVolume:
				  .:
				  f:metadata:
					.:
					f:name:
				  f:spec:
					.:
					f:capacity:
					  .:
					  f:storage:
					f:nfs:
					  .:
					  f:path:
					  f:server:
					f:persistentVolumeReclaimPolicy:
					f:storageClassName:
				f:persistentVolumeClaim:
				  .:
				  f:metadata:
					.:
					f:name:
					f:namespace:
				  f:spec:
					.:
					f:resources:
					  .:
					  f:requests:
						.:
						f:storage:
					f:storageClassName:
					f:volumeName:
			  f:overrideDistributionStrategy:
			  f:secrets:
			f:dataHome:
			f:domainHome:
			f:domainHomeSourceType:
			f:failureRetryIntervalSeconds:
			f:failureRetryLimitMinutes:
			f:httpAccessLogInLogHome:
			f:image:
			f:imagePullPolicy:
			f:imagePullSecrets:
			f:includeServerOutInPodLog:
			f:logHome:
			f:logHomeEnabled:
			f:maxClusterConcurrentShutdown:
			f:maxClusterConcurrentStartup:
			f:maxClusterUnavailable:
			f:replaceVariablesInJavaOptions:
			f:replicas:
			f:serverPod:
			  .:
			  f:env:
			  f:initContainers:
			  f:volumeMounts:
			  f:volumes:
			f:serverStartPolicy:
			f:webLogicCredentialsSecret:
			  .:
			  f:name:
		Manager:      kubectl-create
		Operation:    Update
		Time:         <DATE>
		API Version:  weblogic.oracle/v9
		Fields Type:  FieldsV1
		fieldsV1:
		  f:status:
			.:
			f:clusters:
			f:conditions:
			f:observedGeneration:
			f:servers:
			f:startTime:
		Manager:         Kubernetes Java Client
		Operation:       Update
		Subresource:     status
		Time:            <DATE>
	  Resource Version:  981416
	  UID:               e42ea8c3-9e23-44b9-bb27-e61040f972f5
	Spec:
	  Admin Server:
		Admin Channel Port Forwarding Enabled:  true
		Server Pod:
		  Env:
			Name:             USER_MEM_ARGS
			Value:            -Djava.security.egd=file:/dev/./urandom -Xms512m -Xmx1024m
			Name:             CLASSPATH
			Value:            /u01/oracle/wlserver/server/lib/weblogic.jar
		Server Start Policy:  IfNeeded
	  Clusters:
		Name:  accessdomain-oam-cluster
		Name:  accessdomain-policy-cluster
	  Configuration:
		Initialize Domain On PV:
		  Domain:
			Create If Not Exists:  Domain
			Domain Creation Images:
			  Image:      container-registry.example.com/mytenancy/idm:oam-aux-generic-v1
			Domain Type:  OAM
		  Persistent Volume:
			Metadata:
			  Name:  accessdomain-domain-pv
			Spec:
			  Capacity:
				Storage:  10Gi
			  Nfs:
				Path:                            /<NFS_PATH>/accessdomainpv
				Server:                          <IPADDRESS>
			  Persistent Volume Reclaim Policy:  Retain
			  Storage Class Name:                accessdomain-domain-storage-class
		  Persistent Volume Claim:
			Metadata:
			  Name:       accessdomain-domain-pvc
			  Namespace:  oamns
			Spec:
			  Resources:
				Requests:
				  Storage:               10Gi
			  Storage Class Name:        accessdomain-domain-storage-class
			  Volume Name:               accessdomain-domain-pv
		Override Distribution Strategy:  Dynamic
		Secrets:
		  accessdomain-rcu-credentials
	  Data Home:
	  Domain Home:                     /u01/oracle/user_projects/domains/accessdomain
	  Domain Home Source Type:         PersistentVolume
	  Failure Retry Interval Seconds:  120
	  Failure Retry Limit Minutes:     1440
	  Http Access Log In Log Home:     true
	  Image:                           container-registry.oracle.com/middleware/oam_cpu:12.2.1.4-jdk8-ol8-<April'24>
	  Image Pull Policy:               IfNotPresent
	  Image Pull Secrets:
		Name:                             orclcred
	  Include Server Out In Pod Log:      true
	  Log Home:                           /u01/oracle/user_projects/domains/logs/accessdomain
	  Log Home Enabled:                   true
	  Max Cluster Concurrent Shutdown:    1
	  Max Cluster Concurrent Startup:     0
	  Max Cluster Unavailable:            1
	  Replace Variables In Java Options:  false
	  Replicas:                           1
	  Server Pod:
		Env:
		  Name:   JAVA_OPTIONS
		  Value:  -Dweblogic.StdoutDebugEnabled=false
		  Name:   WLSDEPLOY_LOG_DIRECTORY
		  Value:  /u01/oracle/user_projects/domains/wdt-logs
		  Name:   USER_MEM_ARGS
		  Value:  -Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx1024m
		Init Containers:
		  Command:
			/bin/bash
			-c
			mkdir -p  /u01/oracle/user_projects/domains/wdt-logs
		  Image:              container-registry.oracle.com/middleware/oam_cpu:12.2.1.4-jdk8-ol8-<April'24>
		  Image Pull Policy:  IfNotPresent
		  Name:               compat-connector-init
		  Volume Mounts:
			Mount Path:  /u01/oracle/user_projects/
			Name:        weblogic-domain-storage-volume
		Volume Mounts:
		  Mount Path:  /u01/oracle/user_projects
		  Name:        weblogic-domain-storage-volume
		Volumes:
		  Name:  weblogic-domain-storage-volume
		  Persistent Volume Claim:
			Claim Name:     accessdomain-domain-pvc
	  Server Start Policy:  IfNeeded
	  Web Logic Credentials Secret:
		Name:  accessdomain-weblogic-credentials
	Status:
	  Clusters:
		Cluster Name:  oam_cluster
		Conditions:
		  Last Transition Time:  <DATE>
		  Status:                True
		  Type:                  Available
		  Last Transition Time:  <DATE>
		  Status:                True
		  Type:                  Completed
		Label Selector:          weblogic.domainUID=accessdomain,weblogic.clusterName=oam_cluster
		Maximum Replicas:        5
		Minimum Replicas:        0
		Observed Generation:     1
		Ready Replicas:          1
		Replicas:                1
		Replicas Goal:           1
		Cluster Name:            policy_cluster
		Conditions:
		  Last Transition Time:  <DATE>
		  Status:                True
		  Type:                  Available
		  Last Transition Time:  <DATE>
		  Status:                True
		  Type:                  Completed
		Label Selector:          weblogic.domainUID=accessdomain,weblogic.clusterName=policy_cluster
		Maximum Replicas:        5
		Minimum Replicas:        0
		Observed Generation:     1
		Ready Replicas:          1
		Replicas:                1
		Replicas Goal:           1
	  Conditions:
		Last Transition Time:  <DATE>
		Status:                True
		Type:                  Available
		Last Transition Time:  <DATE>
		Status:                True
		Type:                  Completed
	  Observed Generation:     1
	  Servers:
		Health:
		  Activation Time:  <DATE>
		  Overall Health:   ok
		  Subsystems:
			Subsystem Name:  ServerRuntime
			Symptoms:
		Node Name:     worker-node2
		Pod Phase:     Running
		Pod Ready:     True
		Server Name:   AdminServer
		State:         RUNNING
		State Goal:    RUNNING
		Cluster Name:  oam_cluster
		Health:
		  Activation Time:  <DATE>
		  Overall Health:   ok
		  Subsystems:
			Subsystem Name:  ServerRuntime
			Symptoms:
		Node Name:     worker-node1
		Pod Phase:     Running
		Pod Ready:     True
		Server Name:   oam_server1
		State:         RUNNING
		State Goal:    RUNNING
		Cluster Name:  oam_cluster
		Server Name:   oam_server2
		State:         SHUTDOWN
		State Goal:    SHUTDOWN
		Cluster Name:  oam_cluster
		Server Name:   oam_server3
		State:         SHUTDOWN
		State Goal:    SHUTDOWN
		Cluster Name:  oam_cluster
		Server Name:   oam_server4
		State:         SHUTDOWN
		State Goal:    SHUTDOWN
		Cluster Name:  oam_cluster
		Server Name:   oam_server5
		State:         SHUTDOWN
		State Goal:    SHUTDOWN
		Cluster Name:  policy_cluster
		Health:
		  Activation Time:  <DATE>
		  Overall Health:   ok
		  Subsystems:
			Subsystem Name:  ServerRuntime
			Symptoms:
		Node Name:     worker-node1
		Pod Phase:     Running
		Pod Ready:     True
		Server Name:   oam_policy_mgr1
		State:         RUNNING
		State Goal:    RUNNING
		Cluster Name:  policy_cluster
		Server Name:   oam_policy_mgr2
		State:         SHUTDOWN
		State Goal:    SHUTDOWN
		Cluster Name:  policy_cluster
		Server Name:   oam_policy_mgr3
		State:         SHUTDOWN
		State Goal:    SHUTDOWN
		Cluster Name:  policy_cluster
		Server Name:   oam_policy_mgr4
		State:         SHUTDOWN
		State Goal:    SHUTDOWN
		Cluster Name:  policy_cluster
		Server Name:   oam_policy_mgr5
		State:         SHUTDOWN
		State Goal:    SHUTDOWN
	  Start Time:      <DATE>
	Events:
	  Type     Reason                      Age                From               Message
	  ----     ------                      ----               ----               -------
	  Normal   Created                     19m                weblogic.operator  Domain accessdomain was created.
	  Warning  Failed                      19m                weblogic.operator  Domain accessdomain failed due to 'Persistent volume claim unbound': PersistentVolumeClaim 'accessdomain-domain-pvc' is not bound; the status phase is 'Pending'.. Operator is waiting for the persistent volume claim to be bound, it may be a temporary condition. If this condition persists, then ensure that the PVC has a correct volume name or storage class name and is in bound status..
	  Normal   PersistentVolumeClaimBound  19m                weblogic.operator  The persistent volume claim is bound and ready.
	  Normal   Available                   3m19s              weblogic.operator  Domain accessdomain is available: a sufficient number of its servers have reached the ready state.
	  Normal   Completed                   3m19s              weblogic.operator  Domain accessdomain is complete because all of the following are true: there is no failure detected, there are no pending server shutdowns, and all servers expected to be running are ready and at their target image, auxiliary images, restart version, and introspect version.
   ```
{{% /expand %}}


### Verify the pods

1. Run the following command to see the pods running the servers and which nodes they are running on:

   ```bash
   $ kubectl get pods -n <namespace> -o wide
   ```

   For example:

   ```bash
   $ kubectl get pods -n oamns -o wide
   ```

   The output will look similar to the following:

   ```bash
	NAME                           READY   STATUS    RESTARTS      AGE   IP            NODE               NOMINATED NODE   READINESS GATES
	accessdomain-adminserver       1/1     Running   0             24m   10.244.2.14   worker-node2   <none>           <none>
	accessdomain-oam-policy-mgr1   1/1     Running   0             16m   10.244.1.23   worker-node1   <none>           <none>
	accessdomain-oam-server1       1/1     Running   0             16m   10.244.1.24   worker-node1   <none>           <none>
   ```


You are now ready to configure an Ingress to direct traffic for your OAM domain as per [Configure an ingress For an OAM Domain](../configure-ingress).
