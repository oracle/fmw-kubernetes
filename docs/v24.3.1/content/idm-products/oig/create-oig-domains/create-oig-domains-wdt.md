+++
title = "b. Create OIG domains using WDT Models"
+++

1. [Introduction](#introduction)
1. [Prerequisites](#prerequisites)
1. [Create OIG domains using WDT models](#create-oig-domains-using-wdt-models)

   a. [Prepare the persistent storage](#prepare-the-persistent-storage)
	
	b. [Create Kubernetes secrets for the domain and RCU](#create-kubernetes-secrets-for-the-domain-and-rcu)
	
	c. [Generate WDT models and the domain resource yaml file](#generate-wdt-models-and-the-domain-resource-yaml-file)
	
	d. [Build the Domain Creation Image](#build-the-domain-creation-image)
	
	e. [Deploy the OIG domain resource](#deploy-the-oig-domain-resource)


1. [Verify the results](#verify-the-results)
    
	a. [Verify the domain, pods and services](#verify-the-domain-pods-and-services)
	
	b. [Verify the domain](#verify-the-domain)
	
	c. [Verify the pods](#verify-the-pods)
	
### Introduction

This section demonstrates the creation of an OIG domain home using sample WebLogic Deploy Tooling (WDT) model files.

From WebLogic Kubernetes Operator version 4.1.2 onwards, you can provide a section, `domain.spec.configuration.initializeDomainOnPV`, to automatically initialize an OIG domain on a persistent volume when it is first deployed. This eliminates the need to pre-create your OIG domain using sample WebLogic Scripting Tool (WLST) offline scripts.

With WLST offline scripts it is required to deploy a separate Kubernetes job that creates the domain on a persistent volume, and then deploy the domain with a custom resource YAML. The RCU schema also had to be created and patched manually beforehand. Now, starting from Apr'24 release onwards, using WDT models, all the required information is specified in the domain custom resource YAML file, eliminating the requirement for running a separate Kubernetes job.  With WDT models, the WebLogic Kubernetes Operator will create the PersistentVolume (PV) and PersistenVolumeClaim (PVC), create the RCU schemas and patch them, then create the OIG domain on the persistent volume, prior to starting the servers.


**Note**: This is a one time only initialization. After the domain is created, subsequent updates to this section in the domain resource YAML file will not recreate or update the WebLogic domain. Subsequent domain lifecycle updates must be controlled by the WebLogic Server Administration Console, Enterprise Manager Console, WebLogic Scripting Tool (WLST), or other mechanisms.

WebLogic Deploy Tooling (WDT) models are a convenient and simple alternative to WebLogic Scripting Tool (WLST) configuration scripts. They compactly define a WebLogic domain using model files, variable properties files, and application archive files. For more information about the model format and its integration, see [Usage](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/usage/) and [Working with WDT Model files](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/model-files/). The WDT model format is fully described in the open source, [WebLogic Deploy Tooling GitHub project](https://oracle.github.io/weblogic-deploy-tooling/).

The main benefits of WDT are:

   * A set of single-purpose tools supporting WebLogic domain configuration lifecycle operations.
   * All tools work off of a shared, declarative model, eliminating the need to maintain specialized WLST scripts.
   * WDT knowledge base understands the MBeans, attributes, and WLST capabilities/bugs across WLS versions.

The initializeDomainOnPv section:

1. Creates the PersistentVolume (PV) and/or PersistenVolumeClaim (PVC).
1. Creates and patches the RCU schema.
1. Creates the OIG domain home on the persistent volume based on the provided WDT models

### Prerequisites

Before you begin, perform the following steps:

1. Review the [Domain On PV](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/) documentation.
1. Ensure that the database is up and running.

### Create OIG domains using WDT models


In this section you will:

+ [Prepare the persistent storage](#prepare-the-persistent-storage).
+ [Create Kubernetes secrets for the domain and RCU](#create-kubernetes-secrets-for-the-domain-and-rcu).
+ [Generate WDT models and the domain resource yaml file](#generate-wdt-models-and-the-domain-resource-yaml-file).
+ [Build the domain creation image hosting the WDT models and WDT installation](#build-the-domain-creation-image).
+ [Deploy the OIG domain resource](#deploy-the-oig-domain-resource).

**Note**: In this section a domain creation image is built using the supplied model files and that image is used for domain creation. You will need your own container registry to upload the domain image to. Having your own container repository is a prerequisite before creating an OIG domain with WDT models. If you don't have your own container registry, you can load the image on each node in the cluster instead. This documentation does not explain how to create your own container registry, or how to load the image onto each node. Consult your vendor specific documentation for more information.

**Note:** Building a domain creation image is a one time activity. The domain creation image can be used to create an OIG domain in multiple environments. You do not need to rebuild the domain creation image every time you create a domain.


#### Prepare the persistent storage

As referenced in [Prerequisites](../../prerequisites) the nodes in the Kubernetes cluster must have access to a persistent volume such as a Network File System (NFS) mount or a shared file system.

Domain on persistent volume (Domain on PV) is an operator [domain home source type](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/choosing-a-model/), which requires that the domain home exists on a persistent volume.

When a container is started, it needs to mount that volume. The physical volume should be on a shared disk accessible by all the Kubernetes worker nodes because it is not known on which worker node the container will be started. In the case of Oracle Identity and Access Management, the persistent volume does not get erased when a container stops. This enables persistent configurations.

The example below uses an NFS mounted volume (`<persistent_volume>/governancedomainpv`). Other volume types can also be used. See the official Kubernetes documentation for Volumes.

**Note**: The persistent volume directory needs to be accessible to both the master and worker node(s). In this example `/scratch/shared/governancedomainpv` is accessible from all nodes via NFS.   
    
To create the persistent volume run the following commands:

1. Create the required directories:

   ```bash
   $ mkdir -p <persistent_volume>/governancedomainpv
   $ sudo chown -R 1000:0 <persistent_volume>/governancedomainpv
   ```

   For example,
   
   ```bash
   $ mkdir -p /scratch/shared/governancedomainpv
   $ sudo chown -R 1000:0 /scratch/shared/governancedomainpv
   ```

1. On the master node run the following command to ensure it is possible to read and write to the persistent volume:

   ```bash
   cd <persistent_volume>/governancedomainpv
   touch file.txt
   ls filemaster.txt
   ```

   For example:
   
   ```bash
   cd /scratch/shared/governancedomainpv
   touch filemaster.txt
   ls filemaster.txt
   ```

1. On the first worker node run the following to ensure it is possible to read and write to the persistent volume:

   ```bash
   cd /scratch/shared/governancedomainpv
   ls filemaster.txt
   touch fileworker1.txt
   ls fileworker1.txt
   ```
1. Repeat the above for any other worker nodes e.g fileworker2.txt etc. Once proven that it’s possible to read and write from each node to the persistent volume, delete the files created.

   For more information on PV and PVC requirements, see [Domain on Persistent Volume (PV)](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/usage/#references).

#### Create Kubernetes secrets for the domain and RCU

1. Create a Kubernetes secret for the domain using the `create-secret.sh` script in the same Kubernetes namespace as the domain:

   ```bash
   $ cd $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils
   $ ./create-secret.sh -l "username=weblogic" -l "password=****" -n <domain_namespace> -d <domain_uid> -s <domain_uid>-weblogic-credentials
   ```
   where:

   `-n <domain_namespace>` is the domain namespace you created in [Create a namespace for Oracle Identity Governance](../../prepare-your-environment#create-a-namespace-for-oracle-identity-governance). For example `oigns`.
    
   `-d <domain_uid>` is the domain UID that you want to create. For example, `governancedomain`.
    
   `-s <domain_uid>-weblogic-credentials` is the name of the secret for this namespace. **Note**: The secret name must follow this format (`<domain_uid>-weblogic-credentials`) or domain creation will fail.

   For example:

   ```bash
   $ cd $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils
   $ ./create-secret.sh -l "username=weblogic" -l "password=<password>" -n oigns -d governancedomain -s governancedomain-weblogic-credentials
   ```
   
   The output will look similar to the following:
    
   ```bash
   @@ Info: Setting up secret 'governancedomain-weblogic-credentials'.
   secret/governancedomain-weblogic-credentials created
   secret/governancedomain-weblogic-credentials labeled
   ```
   
1. Verify the secret is created using the following command:
 
   ```bash
   $ kubectl get secret <kubernetes_domain_secret> -o yaml -n <domain_namespace>
   ```
    
   For example:
   
   ```bash
   $ kubectl get secret governancedomain-weblogic-credentials -o yaml -n oigns
   ```
   
   The output will look similar to the following:
    
   ```
   apiVersion: v1
   data:
     password: <password>
     username: d2VibG9naWM=
   kind: Secret
   metadata:
     creationTimestamp: "<DATE>"
     labels:
       weblogic.domainName: governancedomain
       weblogic.domainUID: governancedomain
     name: governancedomain-weblogic-credentials
     namespace: oigns
     resourceVersion: "3216738"
     uid: c2ec07e0-0135-458d-bceb-c648d2a9ac54
   type: Opaque
   ```
   
1. Create a Kubernetes secret for RCU in the same Kubernetes namespace as the domain, using the `create-secrets.sh` script:

   ```bash
   $ cd $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils
   $ ./create-secret.sh -l "rcu_prefix=<rcu_prefix>" -l "rcu_schema_password=<rcu_schema_pwd>" -l "db_host=<db_host.domain>" -l "db_port=<db_port>" -l "db_service=<service_name>" -l "dba_user=<sys_db_user>" -l "dba_password=<sys_db_pwd>" -n <domain_namespace> -d <domain_uid> -s <domain_uid>-rcu-credentials
   ```
   
   where

   `<rcu_prefix>` is the name of the RCU schema to be created.
    
   `<rcu_schema_pwd>` is the password you want to create for the RCU schema prefix.

   `<db_host.domain>` is the database server hostname.
   
   `<db_port>` is the database listener port.
   
   `<service_name>` is the database service name.
    
   `<sys_db_user>` is the database user with sys dba privilege.
    
   `<sys_db_pwd>` is the sys database password.
    
   `<domain_uid>` is the `domain_uid` that you want to create. This must be the same `domain_uid` used in the domain secret. For example, `governancedomain`.
    
   `<domain_namespace>` is the domain namespace you created in [Create a namespace for Oracle Identity Governance](../../prepare-your-environment#create-a-namespace-for-oracle-identity-governance). For example `oigns`.
    
   `<domain_uid>-rcu-credentials` is the name of the rcu secret to create. **Note**: The secret name must follow this format (`<domain_uid>-rcu-credentials`) or domain creation will fail.

   For example:

   ```bash
   $ cd $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils
   $ ./create-secret.sh -l "rcu_prefix=OIGK8S" -l "rcu_schema_password=<rcu_schema_password>" -l "db_host=mydatabasehost.example.com" -l "db_port=1521" -l "db_service=orcl.example.com" -l "dba_user=sys" -l "dba_password=<dba_password>" -n oigns -d governancedomain -s governancedomain-rcu-credentials
   ```

   The output will look similar to the following:

   ```bash
   @@ Info: Setting up secret 'governancedomain-rcu-credentials'.
   secret/governancedomain-rcu-credentials created
   secret/governancedomain-rcu-credentials labeled
   ```
    
1. Verify the secret is created using the following command:
    
   ```bash
   $ kubectl get secret <kubernetes_rcu_secret> -o yaml -n <domain_namespace>
   ```

   For example:
   
   ```bash
   $ kubectl get secret governancedomain-rcu-credentials -o yaml -n oigns
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
       weblogic.domainUID: governancedomain
     name: governancedomain-rcu-credentials
     namespace: oigns
     resourceVersion: "31695660"
     uid: 71cfcc73-4c96-42bd-b9a5-988ea9ed27ff
   type: Opaque
   ```


#### Generate WDT models and the domain resource yaml file

In this section you generate the required WDT models for the OIG domain, along with the domain resource yaml file. 

1. Navigate to the `$WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils/generate_models_utils` directory:

   ```bash
   $ cd $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils/generate_models_utils
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
	
	**Note**: The `<domain_namespace>` and `<domain_uid>` must be the same as those used in [Creating Kubernetes secrets for the domain and RCU](#creating-kubernetes-secrets-for-the-domain-and-rcu)
	
	For example:
	
	```
   domainUID: governancedomain
   domainHome: /u01/oracle/user_projects/domains/governancedomain
   image: container-registry.oracle.com/middleware/oig_cpu:12.2.1.4-jdk8-ol8-<July'24>
   imagePullSecretName: orclcred
   logHome: /u01/oracle/user_projects/domains/logs/governancedomain
   namespace: oigns
   weblogicDomainStorageType: NFS
   weblogicDomainStorageNFSServer: mynfsserver
   weblogicDomainStoragePath: /scratch/shared/governancedomain
   weblogicDomainStorageSize: 10G
	```
	
	**Note** : If using a shared file system instead of NFS, set `weblogicDomainStorageType: HOST_PATH` and remove `weblogicDomainStorageNFSServer`.
  
  
   A full list of parameters in the `create-domain-wdt.yaml` file are shown below:
  
| Parameter | Definition | Default |
| --- | --- | --- |
| `adminPort` | Port number for the Administration Server inside the Kubernetes cluster. | `7001` |
| `adminNodePort` | Port number for the Administration Server outside the Kubernetes cluster. | `30701` |
| `configuredManagedServerCount` | Number of Managed Server instances to generate for the domain. | `5` |
| `datasourceType` | Type of JDBC datasource applicable for the OIG domain. Legal values are `agl` and `generic`. Choose `agl` for Active GridLink datasource and `generic` for Generic datasource. For enterprise deployments, Oracle recommends that you use GridLink data sources to connect to Oracle RAC databases. See the [Enterprise Deployment Guide](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/preparing-existing-database-enterprise-deployment.html#GUID-E3705EFF-AEF2-4F75-B5CE-1A829CDF0A1F) for further details. | `generic` |
| `domainHome` | Home directory of the OIG domain. If not specified, the value is derived from the `domainUID` as `/shared/domains/<domainUID>`. | `/u01/oracle/user_projects/domains/governancedomain` |
| `domainPVMountPath` | Mount path of the domain persistent volume. | `/u01/oracle/user_projects/domains` |
| `domainUID` | Unique ID that will be used to identify this particular domain. Used as the name of the generated WebLogic domain as well as the name of the Kubernetes domain resource. This ID must be unique across all domains in a Kubernetes cluster. This ID cannot contain any character that is not valid in a Kubernetes service name. | `governancedomain` |
| `edgInstall` | Used only if performing an install using the Enterprise Deployment Guide. See, [Enterprise Deployment Guide for Oracle Identity and Access Management in a Kubernetes Cluster](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg). | `false` |
| `exposeAdminNodePort` | Boolean indicating if the Administration Server is exposed outside of the Kubernetes cluster. | `false` |
| `exposeAdminT3Channel` | Boolean indicating if the T3 administrative channel is exposed outside the Kubernetes cluster. | `true` |
| `frontEndHost` | The entry point URL for the OIM. | `example.com` |
| `frontEndHost` | The entry point port for the OIM. | `14000` |
| `image` | OIG container image. The operator requires OIG 12.2.1.4. Refer to [Obtain the OIG container image](../../prepare-your-environment#obtain-the-oig-container-image) for details on how to obtain or create the image. For WDT domains you must use April 24 or later. | `oracle/oig:12.2.1.4.0` |
| `imagePullSecretName` | Name of the Kubernetes secret to access the container registry to pull the OIG container image. The presence of the secret will be validated when this parameter is specified. |  |
| `initialManagedServerReplicas` | Number of Managed Servers to initially start for the domain. | `2` |
| `javaOptions` | Java options for starting the Administration Server and Managed Servers. A Java option can have references to one or more of the following pre-defined variables to obtain WebLogic domain information: `$(DOMAIN_NAME)`, `$(DOMAIN_HOME)`, `$(ADMIN_NAME)`, `$(ADMIN_PORT)`, and `$(SERVER_NAME)`. | `-Dweblogic.StdoutDebugEnabled=false` |
| `logHome` | The in-pod location for the domain log, server logs, server out, and Node Manager log files. If not specified, the value is derived from the `domainUID` as `/shared/logs/<domainUID>`. | `/u01/oracle/user_projects/domains/logs/governancedomain` |
| `namespace` | Kubernetes namespace in which to create the domain. | `oigns` |
| `oimCPU` | Initial CPU Units, 1000m = 1 CPU core. | `1000m` |
| `oimMaxCPU` | Max CPU Cores pod is allowed to consume. | `2` |
| `oimMemory` | Initial memory allocated to a pod. | `4Gi` |
| `oimMaxMemory` | Max memory a pod is allowed to consume. | `8Gi` |
| `oimServerJavaParams` | The memory parameters to use for the OIG managed servers. | `"-Xms8192m -Xmx8192m"` |
| `productionModeEnabled` | Boolean indicating if production mode is enabled for the domain. | `true` |
| `soaCPU` | Initial CPU Units, 1000m = 1 CPU core. | `1000m` |
| `soaMaxCPU` | Max CPU Cores pod is allowed to consume. | `1` |
| `soaMemory` | Initial Memory pod allocated to a pod. | `4Gi` |
| `soaMaxMemory` | Max Memory pod is allowed to consume. | `10Gi` |
| `soaServerJavaParams` | The memory parameters to use for the SOA managed servers. | `"-Xms8192m -Xmx8192m"` |
| `t3PublicAddress` | Public address for the T3 channel.  This should be set to the public address of the Kubernetes cluster.  This would typically be a load balancer address. <p/>For development environments only: In a single server (all-in-one) Kubernetes deployment, this may be set to the address of the master, or at the very least, it must be set to the address of one of the worker nodes. | If not provided, the script will attempt to set it to the IP address of the Kubernetes cluster |
| `weblogicDomainStorageType` | Persistent volume storage type. Options are `NFS` for NFS volumes or `HOST_PATH` for shared file system. | `NFS` |
| `weblogicDomainStorageNFSServer` | Hostname or IP address of the NFS Server. | `nfsServer` |
| `weblogicDomainStoragePath` | Physical path to the persistent volume. | `/scratch/governancedomainpv` |
| `weblogicDomainStorageSize` | Total storage allocated to the persistent storage. | `10Gi` |

**Note**: The above CPU and memory values are for examples only. For Enterprise Deployments, please review the performance recommendations and sizing requirements in [Enterprise Deployment Guide for Oracle Identity and Access Management in a Kubernetes Cluster](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/procuring-resources-oracle-cloud-infrastructure-deployment.html#GUID-2E3C8D01-43EB-4691-B1D6-25B1DC2475AE).
   

4. Run the `generate_wdt_models.sh`, specifying your input file and an output directory to store the generated artifacts:

   ```
	$ cd $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils/generate_models_utils
	$ ./generate_wdt_models.sh -i create-domain-wdt.yaml -o <path_to_output_directory>
   ```


   For example:
   
   ```bash
   $ cd $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils/generate_models_utils
   $ ./generate_wdt_models.sh -i create-domain-wdt.yaml -o output
   ```
	
	The output will look similar to the following:
	
   ```
   input parameters being used
   export version="create-weblogic-sample-domain-inputs-v1"
   export adminPort="7001"
   export domainUID="governancedomain"
   export configuredManagedServerCount="5"
   export initialManagedServerReplicas="1"
   export productionModeEnabled="true"
   export t3ChannelPort="30012"
   export datasourceType="generic"
   export edgInstall="false"
   export domainHome="/u01/oracle/user_projects/domains/governancedomain"
   export image="container-registry.oracle.com/middleware/oig_cpu:12.2.1.4-jdk8-ol8-<July'24>"
   export imagePullSecretName="orclcred"
   export logHome="/u01/oracle/user_projects/domains/logs/governancedomain"
   export exposeAdminT3Channel="false"
   export adminNodePort="30701"
   export exposeAdminNodePort="false"
   export namespace="oigns"
   javaOptions=-Dweblogic.StdoutDebugEnabled=false
   export domainPVMountPath="/u01/oracle/user_projects"
   export weblogicDomainStorageType="NFS"
   export weblogicDomainStorageNFSServer="mynfsServer"
   export weblogicDomainStoragePath="/scratch/shared/governancedomainpv"
   export weblogicDomainStorageReclaimPolicy="Retain"
   export weblogicDomainStorageSize="10Gi"
   export frontEndHost="example.com"
   export frontEndPort="14000"
   export oimServerJavaParams="-Xms8192m -Xmx8192m "
   export soaServerJavaParams="-Xms8192m -Xmx8192m "
   export oimMaxCPU="2"
   export oimCPU="1000m"
   export oimMaxMemory="8Gi"
   export oimMemory="4Gi"
   export soaMaxCPU="1"
   export soaCPU="1000m"
   export soaMaxMemory="10Gi"
   export soaMemory="4Gi"
	
   validateWlsDomainName called with governancedomain
   WDT model file, property file and sample domain.yaml are genereted successfully at output/weblogic-domains/governancedomain
	```
 
   This will generate `domain.yaml`, `oig.yaml` and `oig.properties` in `output/weblogic-domains/governancedomain`.

1. Copy the generated files to a `$WORKDIR/yaml` directory:

   ```
	$ mkdir $WORKDIR/yaml
	$ cp output/weblogic-domains/governancedomain/*.* $WORKDIR/yaml
	```
	
	
#### Build the Domain Creation Image

In this section you build a domain creation image to host the WDT model files and WebLogic Deploy Tooling (WDT) installer.

Domain creation images are used for supplying WDT model files, WDT variables files, WDT application archive files (collectively known as WDT model files), and the directory where the WebLogic Deploy Tooling software is installed (known as the WDT Home), when deploying a domain using a Domain on PV model. You distribute WDT model files and the WDT executable using these images, and the WebLogic Kubernetes Operator uses them to manage the domain.

**Note**: These images are only used for creating the domain and will not be used to update the domain. The domain creation image is used for domain creation only, it is not the product container image used for OIG.

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

The sample scripts for the Oracle Identity Governance domain image creation are available at `$WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image`.

1. Navigate to the `$WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/properties` directory:

   ```bash
   $ cd $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/properties
   ```
   
1. Make a copy of the `build-domain-creation-image.properties`:

   ```bash
   $ cp build-domain-creation-image.properties build-domain-creation-image.properties.orig
   ```

1. Edit the `build-domain-creation-image.properties` and modify the following parameters. Save the file when complete:

   ```
   JAVA_HOME=<Java home location>
   IMAGE_TAG=<Image tag name>
   REPOSITORY=<Container image repository to push the image>
   REG_USER= <Container registry username>
   IMAGE_PUSH_REQUIRES_AUTH=<Whether image push requires authentication to the registry>
   WDT_MODEL_FILE=<Full Path to WDT Model file oig.yaml> 
   WDT_VARIABLE_FILE=<Full path to WDT variable file oig.properties>
   WDT_ARCHIVE_FILE=<Full Path to WDT Archive file> 
   WDT_VERSION="Version of WebLogic Deploy Tool version to use"
   WIT_VERSION="Version of WebLogic Image Tool to use"
   ```
   
   For example:

   ```
   JAVA_HOME=/scratch/jdk
   IMAGE_TAG=oig-aux-generic-v1
   BASE_IMAGE=ghcr.io/oracle/oraclelinux:8-slim
   REPOSITORY=container-registry.example.com/mytenancy/idm
   REG_USER=mytenancy/myemail@example.com
   IMAGE_PUSH_REQUIRES_AUTH=true
   WDT_MODEL_FILE="/scratch/OIGK8S/fmw-kubernetes/OracleIdentityGovernance/yaml/oig.yaml"
   WDT_VARIABLE_FILE="/scratch/OIGK8S/fmw-kubernetes/OracleIdentityGovernance/oig.properties"
   WDT_ARCHIVE_FILE=""
   WDT_VERSION="3.5.3"
   WIT_VERSION="1.12.1"
   ```
	
   A full list of parameters and descriptions in the `build-domain-creation-image.properties` file are shown below:
	
| Parameter |	Definition | Default |
| --- |	--- | --- |
| JAVA_HOME | Path to the JAVA_HOME for the JDK8+. | |
| IMAGE_TAG | Image tag for the final domain creation image.| `oig-aux-generic-v1` |
| BASE_IMAGE | The Oracle Linux product container image to use as a base image.| `ghcr.io/oracle/oraclelinux:8-slim` |
| REPOSITORY | Container image repository that will host the domain creation image.| `iad.ocir.io/mytenancy/idm` |
| REG_USER | Username to authenticate to the `<REPOSITORY>` and push the domain creation image.| `mytenancy/oracleidentitycloudservice/myemail@example.com` |
| IMAGE_PUSH_REQUIRES_AUTH | If authentication to `<REPOSITORY>` is required then set to true, else set to false. If set to false, `<REG_USER>` is not required.| `true` |
| WDT_MODEL_FILE | Absolute path to WDT model file `oig.yaml`. For example `$WORKDIR/yaml/oig.yaml`. | |
| WDT_MODEL_FILE | Absolute path to WDT variable file `oig.properties`. For example `$WORKDIR/yaml/oig.properties`. | |
| WDT_ARCHIVE_FILE | Absolute path to WDT archive file. | |
| WDT_VERSION | WebLogic Deploy Tool version. If not specified the latest available version will be downloaded. It is recommended to use the default value.| `3.5.3` |
| WIT_VERSION | WebLogic Image Tool Version. If not specified the latest available version will be downloaded. It is recommended to use the default value.| `1.12.1` |
| TARGET | Select the target environment in which the created image will be used. Supported values: `Default` or `OpenShift`. See [Additional Information](https://oracle.github.io/weblogic-image-tool/userguide/tools/create-aux-image/#--target).| Default |
| CHOWN | `userid:groupid` to be used for creating files within the image, such as the WDT installer, WDT model, and WDT archive. If the user or group does not exist in the image, they will be added with `useradd`/`groupadd`.| `oracle:oracle` |

**Note**: If `IMAGE_PUSH_REQUIRES_AUTH=true`, you must edit the `$WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/properties/.regpassword` and change `<REGISTRY_PASSWORD>` to your registry password.
	
```
REG_PASSWORD="<REPOSITORY_PASSWORD>"
```


##### Run the build-domain-creation-image script

1. Execute the `build-domain-creation-image.sh` by specifying the input properties parameter files:

   ```
	$ cd $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image
	$ ./build-domain-creation-image.sh -i properties/build-domain-creation-image.properties
	```
	
	**Note**: If using a password file, you must add `-p properties/.regpassword` to the end of the command.
	
	Executing this command will build the image and push it to the container image repository. 
	
	
	The output will look similar to the following:

   {{%expand "Click here to see example output:" %}}
   ```
   using WDT_DIR: /scratch/OIGK8S/fmw-kubernetes/OracleIdentityGovernance/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/workdir
   Using WDT_VERSION 3.5.3
   Using WIT_DIR /scratch/OIGK8S/fmw-kubernetes/OracleIdentityGovernance/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/workdir
   Using WIT_VERSION 1.12.1
   Using Image tag: oig-aux-generic-v1
   using Base Image: ghcr.io/oracle/oraclelinux:8-slim
   using IMAGE_BUILDER_EXE /usr/bin/podman
   JAVA_HOME is set to /home/opc/jdk
   @@  Info: WIT_INSTALL_ZIP_URL is ''
   @@ WIT_INSTALL_ZIP_URL is not set
   @@ imagetool.sh not found in /scratch/OIGK8S/fmw-kubernetes/OracleIdentityGovernance/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/workdir/imagetool/bin. Installing imagetool...
   @@ Info:  Downloading https://github.com/oracle/weblogic-image-tool/releases/download/release-1.12.1/imagetool.zip
   @@ Info:  Downloading https://github.com/oracle/weblogic-image-tool/releases/download/release-1.12.1/imagetool.zip with https_proxy="http://proxy.example.com:80"
   @@ Info: Archive downloaded to /scratch/OIGK8S/fmw-kubernetes/OracleIdentityGovernance/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/workdir/imagetool.zip, about to unzip via '/home/opc/jdk/bin/jar xf'.
   @@ Info: imageTool cache does not contain a valid entry for wdt_3.5.3. Installing WDT
   @@  Info: WDT_INSTALL_ZIP_URL is ''
   @@ WDT_INSTALL_ZIP_URL is not set
   @@ Info:  Downloading https://github.com/oracle/weblogic-deploy-tooling/releases/download/release-3.5.3/weblogic-deploy.zip
   @@ Info:  Downloading https://github.com/oracle/weblogic-deploy-tooling/releases/download/release-3.5.3/weblogic-deploy.zip with https_proxy="http://proxy.example.com:80"
   @@ Info: Archive downloaded to /scratch/OIGK8S/fmw-kubernetes/OracleIdentityGovernance/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/workdir/weblogic-deploy.zip
   [INFO   ] Successfully added to cache. wdt_3.5.3=/scratch/OIGK8S/fmw-kubernetes/OracleIdentityGovernance/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/workdir/weblogic-deploy.zip
   @@ Info: Install succeeded, imagetool install is in the /scratch/OIGK8S/fmw-kubernetes/OracleIdentityGovernance/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/workdir/imagetool directory.
   Starting Building Image container-registry.example.com/mytenancy/idm:oig-aux-generic-v1
   Login Succeeded!
   WDT_MODEL_FILE is set to /scratch/OIGK8S/fmw-kubernetes/OracleIdentityGovernance/yaml/oig.yaml
   WDT_VARIABLE_FILE is set to /scratch/OIGK8S/fmw-kubernetes/OracleIdentityGovernance/yaml/oig.properties
   Additional Build Commands file is set to /scratch/OIGK8S/fmw-kubernetes/OracleIdentityGovernance/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/additonal-build-files/build-files.txt
   Additonal Build file is set to /scratch/OIGK8S/fmw-kubernetes/OracleIdentityGovernance/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/additonal-build-files/OIG.json
   [INFO   ] WebLogic Image Tool version 1.12.1
   [INFO   ] Image Tool build ID: 88fdf00a-d97a-4ff7-b2d1-ad213bffeae1
   [INFO   ] Temporary directory used for image build context: /home/opc/wlsimgbuilder_temp8473580374961408286
   [INFO   ] Copying /scratch/OIGK8S/fmw-kubernetes/OracleIdentityGovernance/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/additonal-build-files/OIG.json to build context folder.
   [INFO   ] User specified fromImage ghcr.io/oracle/oraclelinux:8-slim
   [INFO   ] Inspecting ghcr.io/oracle/oraclelinux:8-slim, this may take a few minutes if the image is not available locally.
   [INFO   ] Copying /scratch/OIGK8S/fmw-kubernetes/OracleIdentityGovernance/yaml/oig.yaml to build context folder.
   [INFO   ] Copying /scratch/OIGK8S/fmw-kubernetes/OracleIdentityGovernance/yaml/oig.properties to build context folder.
   [INFO   ] Copying /scratch/OIGK8S/fmw-kubernetes/OracleIdentityGovernance/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils/build-domain-creation-image/workdir/weblogic-deploy.zip to build context folder.
   [INFO   ] Starting build: /usr/bin/podman build --no-cache --force-rm --tag container-registry.example.com/mytenancy/idm:oig-aux-generic-v1 --pull --build-arg http_proxy=http://proxy.example.com:80 --build-arg https_proxy=http://proxy.example.com:80 --build-arg no_proxy=localhost,127.0.0.0/8,.example.com,,/var/run/crio/crio.sock,X.X.X.X,/var/run/crio/crio.sock,100.105.18.32 /home/opc/wlsimgbuilder_temp8473580374961408286
   [1/3] STEP 1/5: FROM ghcr.io/oracle/oraclelinux:8-slim AS os_update
   [1/3] STEP 2/5: LABEL com.oracle.weblogic.imagetool.buildid="88fdf00a-d97a-4ff7-b2d1-ad213bffeae1"
   --> 58df386c56c0
   [1/3] STEP 3/5: USER root
   --> 14e154f7b87b
   [1/3] STEP 4/5: RUN microdnf update     && microdnf install gzip tar unzip libaio libnsl jq findutils diffutils shadow-utils     && microdnf clean all
   Downloading metadata...
   Downloading metadata...
   Package                                                      Repository           Size
   Installing:
    glibc-gconv-extra-2.28-236.0.1.el8_9.12.x86_64              ol8_baseos_latest  1.6 MB
   Upgrading:
    glibc-2.28-236.0.1.el8_9.12.x86_64                          ol8_baseos_latest  2.3 MB
     replacing glibc-2.28-236.0.1.el8.7.x86_64
    glibc-common-2.28-236.0.1.el8_9.12.x86_64                   ol8_baseos_latest  1.1 MB
     replacing glibc-common-2.28-236.0.1.el8.7.x86_64
    glibc-minimal-langpack-2.28-236.0.1.el8_9.12.x86_64         ol8_baseos_latest 71.1 kB
     replacing glibc-minimal-langpack-2.28-236.0.1.el8.7.x86_64
    systemd-libs-239-78.0.4.el8.x86_64                          ol8_baseos_latest  1.2 MB
      replacing systemd-libs-239-78.0.3.el8.x86_64
   Transaction Summary:
    Installing:        1 packages
    Reinstalling:      0 packages
    Upgrading:         4 packages
    Obsoleting:        0 packages
    Removing:          0 packages
    Downgrading:       0 packages
   Downloading packages...
   Running transaction test...
   Updating: glibc-common;2.28-236.0.1.el8_9.12;x86_64;ol8_baseos_latest
   Updating: glibc-minimal-langpack;2.28-236.0.1.el8_9.12;x86_64;ol8_baseos_latest
   Updating: glibc;2.28-236.0.1.el8_9.12;x86_64;ol8_baseos_latest
   Installing: glibc-gconv-extra;2.28-236.0.1.el8_9.12;x86_64;ol8_baseos_latest
   Updating: systemd-libs;239-78.0.4.el8;x86_64;ol8_baseos_latest
   Cleanup: systemd-libs;239-78.0.3.el8;x86_64;installed
   Cleanup: glibc;2.28-236.0.1.el8.7;x86_64;installed
   Cleanup: glibc-minimal-langpack;2.28-236.0.1.el8.7;x86_64;installed
   Cleanup: glibc-common;2.28-236.0.1.el8.7;x86_64;installed
   Complete.
   Package                              Repository            Size
   Installing:
    diffutils-3.6-6.el8.x86_64          ol8_baseos_latest 369.3 kB
    findutils-1:4.6.0-21.el8.x86_64     ol8_baseos_latest 539.8 kB
    gzip-1.9-13.el8_5.x86_64            ol8_baseos_latest 170.7 kB
    jq-1.6-7.0.3.el8.x86_64             ol8_appstream     206.5 kB
    libaio-0.3.112-1.el8.x86_64         ol8_baseos_latest  33.4 kB
    libnsl-2.28-236.0.1.el8_9.12.x86_64 ol8_baseos_latest 112.3 kB
    oniguruma-6.8.2-2.1.el8_9.x86_64    ol8_appstream     191.5 kB
    unzip-6.0-46.0.1.el8.x86_64         ol8_baseos_latest 201.0 kB
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
   Installing: libnsl;2.28-236.0.1.el8_9.12;x86_64;ol8_baseos_latest
   Installing: libaio;0.3.112-1.el8;x86_64;ol8_baseos_latest
   Installing: gzip;1.9-13.el8_5;x86_64;ol8_baseos_latest
   Installing: findutils;1:4.6.0-21.el8;x86_64;ol8_baseos_latest
   Installing: diffutils;3.6-6.el8;x86_64;ol8_baseos_latest
   Complete.
   Complete.
   --> 62016b4b1988
   [1/3] STEP 5/5: RUN if [ -z "$(getent group oracle)" ]; then groupadd oracle || exit 1 ; fi  && if [ -z "$(getent group oracle)" ]; then groupadd oracle || exit 1 ; fi  && if [ -z "$(getent passwd oracle)" ]; then useradd -g oracle oracle || exit 1; fi  && mkdir -p /u01  && chown oracle:oracle /u01  && chmod 775 /u01
   --> 77099c4f3707
   [2/3] STEP 1/4: FROM 77099c4f37077d45015cebb456b1ce40ba075d7c2d24f5cb9f41c60efa679200 AS wdt_build
   [2/3] STEP 2/4: RUN mkdir -p /auxiliary  && mkdir -p /auxiliary/models  && chown oracle:oracle /auxiliary
   --> 82f0cd380d89
   [2/3] STEP 3/4: COPY --chown=oracle:oracle ["weblogic-deploy.zip", "/tmp/imagetool/"]
   --> a108b42804ca
   [2/3] STEP 4/4: RUN test -d /auxiliary/weblogic-deploy && rm -rf /auxiliary/weblogic-deploy || echo Initial WDT install         && unzip -q "/tmp/imagetool/weblogic-deploy.zip" -d /auxiliary
   Initial WDT install
   --> 1432012f293d
   [3/3] STEP 1/12: FROM 77099c4f37077d45015cebb456b1ce40ba075d7c2d24f5cb9f41c60efa679200 AS final
   [3/3] STEP 2/12: ENV AUXILIARY_IMAGE_PATH=/auxiliary     WDT_HOME=/auxiliary     WDT_MODEL_HOME=/auxiliary/models
   --> fec3c77539d6
   [3/3] STEP 3/12: RUN mkdir -p /auxiliary && chown oracle:oracle /auxiliary
   --> ad9ca2b55f11
   [3/3] STEP 4/12: COPY --from=wdt_build --chown=oracle:oracle /auxiliary /auxiliary/
   --> 9fdf1ed52888
   [3/3] STEP 5/12: RUN mkdir -p /auxiliary/models && chown oracle:oracle /auxiliary/models
   --> 208de9fbed4a
   [3/3] STEP 6/12: COPY --chown=oracle:oracle ["oig.yaml", "/auxiliary/models/"]
   --> c45884e3ad93
   [3/3] STEP 7/12: COPY --chown=oracle:oracle ["oig.properties", "/auxiliary/models/"]
   --> d0ae571589ed
   [3/3] STEP 8/12: RUN chmod -R 640 /auxiliary/models/*
   --> 08fe4c892394
   [3/3] STEP 9/12: USER oracle
   --> 0a0bb84fd90c
   [3/3] STEP 10/12: WORKDIR /auxiliary
   --> aa4d6fe84415
   [3/3] STEP 11/12: COPY --chown=oracle:oracle files/OIG.json /auxiliary/weblogic-deploy/lib/typedefs
   --> 40fabe477af7
   [3/3] STEP 12/12: RUN chmod -R 755 /auxiliary
   [3/3] COMMIT container-registry.example.com/mytenancy/idm:oig-aux-generic-v1
   --> ca9120fdeb0b
   Successfully tagged container-registry.example.com/mytenancy/idm:oig-aux-generic-v1
   ca9120fdeb0b29ef447b959ccba9dae0b7f062a2b6b4c41680e2e72c7f591741
   [INFO   ] Build successful. Build time=63s. Image tag=container-registry.example.com/mytenancy/idm:oig-aux-generic-v1
   Getting image source signatures
   Copying blob fa48179450c3 done
   Copying blob 43cd89792b11 done
   Copying blob db97724803c6 done
   Copying blob 8b4d3bacf0d7 done
   Copying blob 97961b141e48 done
   Copying blob affb88964094 done
   Copying blob cd6baebadbfd done
   Copying blob d1167c2b24bf done
   Copying blob 31b60d1b87d2 done
   Copying blob 2cc6de086f3c done
   Copying blob 4529e99c5305 done
   Copying config ca9120fdeb done
   Writing manifest to image destination
   Pushed image container-registry.example.com/mytenancy/idm:oig-aux-generic-v1 to image repository

   ```
	{{% /expand %}}

	

#### Deploy the OIG domain resource

In this section you modify the OIG `domain.yaml` and deploy the OIG domain using the build image created.

##### Modify the OIG domain.yaml

In this section you modify the `domain.yaml` file in preparation for creating the OIG domain.

1. Edit the `$WORKDIR/yaml/domain.yaml` and update the `%DOMAIN_CREATION_IMAGE%` with the previously generated image name.

   **Note**: `%DOMAIN_CREATION_IMAGE%` takes the format of `<REPOSITORY>:<TAG>`:

   ```
   domain:
            # Domain | DomainAndRCU
            createIfNotExists: DomainAndRCU
            # Image containing WDT installer and Model files.
            domainCreationImages:
                - image: '%DOMAIN_CREATION_IMAGE%'
            domainType: OIG

   ```
	
	For example:
	
	```
   domain:
            # Domain | DomainAndRCU
            createIfNotExists: DomainAndRCU
            # Image containing WDT installer and Model files.
            domainCreationImages:
                - image: 'container-registry.example.com/mytenancy/idm:oig-aux-generic-v1'
            domainType: OIG

   ```

1. In circumstances where you may be pulling the OIG product container image from Oracle Container Registry, and then the domain image from a private registry, you must first create a secret (privatecred) for the private registry. For example:

   ```
   $ kubectl create secret docker-registry "privatecred" --docker-server=container-registry.example.com \
   --docker-username="user@example.com" \
   --docker-password=password --docker-email=user@example.com \
   --namespace=oigns
   ```

   Then specify both secrets for `imagePullSecrets` in the `domain.yaml`. For example:

   ```
	...
   spec:
     # The WebLogic Domain Home
     domainHome: /u01/oracle/user_projects/domains/governancedomain

     # The domain home source type
     # Set to PersistentVolume for domain-in-pv, Image for domain-in-image, or FromModel for model-in-image
     domainHomeSourceType: PersistentVolume

     # The WebLogic Server image that the Operator uses to start the domain
     image: "container-registry.oracle.com/middleware/oig_cpu:12.2.1.4-jdk8-ol8-<July'24>"

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
	# This is an example of how to define an OIG Domain. For details about the fields in domain specification, refer https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-resource/
	#
	apiVersion: "weblogic.oracle/v9"
	kind: Domain
	metadata:
	  name: governancedomain
	  namespace: oigns
	  labels:
		 weblogic.domainUID: governancedomain
	spec:
	  # The WebLogic Domain Home
	  domainHome: /u01/oracle/user_projects/domains/governancedomain

	  # The domain home source type
	  # Set to PersistentVolume for domain-in-pv, Image for domain-in-image, or FromModel for model-in-image
	  domainHomeSourceType: PersistentVolume

	  # The WebLogic Server image that the Operator uses to start the domain
	  image: "container-registry.oracle.com/middleware/oig_cpu:12.2.1.4-jdk8-ol8-<July'24>"

	  # imagePullPolicy defaults to "Always" if image version is :latest
	  imagePullPolicy: IfNotPresent

	  # Add additional secret name if you are using a different registry for domain creation image.
	  # Identify which Secret contains the credentials for pulling an image
	  imagePullSecrets:
	  - name: orclcred
	  - name: privatecred
	  # Identify which Secret contains the WebLogic Admin credentials
	  webLogicCredentialsSecret:
		 name: governancedomain-weblogic-credentials

	  # Whether to include the server out file into the pod's stdout, default is true
	  includeServerOutInPodLog: true

	  # Whether to enable log home
	  logHomeEnabled: true

	  # Whether to write HTTP access log file to log home
	  httpAccessLogInLogHome: true

	  # The in-pod location for domain log, server logs, server out, introspector out, and Node Manager log files
	  logHome: /u01/oracle/user_projects/domains/logs/governancedomain
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
			  # OIG Product image, same as spec.image mentioned above
			  image: "container-registry.oracle.com/middleware/oig_cpu:12.2.1.4-jdk8-ol8-<July'24>"
			  imagePullPolicy: IfNotPresent
			  command: [ "/bin/bash", "-c", "mkdir -p  /u01/oracle/user_projects/domains/ConnectorDefaultDirectory", "mkdir -p  /u01/oracle/user_projects/domains/wdt-logs"]
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
		 - name: FRONTENDHOST
			value: example.com
		 - name: FRONTENDPORT
			value: "14000"
		 - name: WLSDEPLOY_PROPERTIES
			value: "-Dwdt.config.disable.rcu.drop.schema=true"
		 envFrom:
		 - secretRef:
			  name: governancedomain-rcu-credentials
		 volumes:
		 - name: weblogic-domain-storage-volume
			persistentVolumeClaim:
			  claimName: governancedomain-domain-pvc
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

	  configuration:
			secrets: [ governancedomain-rcu-credentials ]
			initializeDomainOnPV:
			  persistentVolume:
				 metadata:
					  name: governancedomain-domain-pv
				 spec:
					storageClassName: governancedomain-domain-storage-class
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
					  server: mynfsserver
					# hostPath:
					  path: "/scratch/shared/governancedomain"
			  persistentVolumeClaim:
				 metadata:
					  name: governancedomain-domain-pvc
				 spec:
					storageClassName: governancedomain-domain-storage-class
					resources:
						 requests:
							  storage: 10Gi
					volumeName: governancedomain-domain-pv
			  domain:
					# Domain | DomainAndRCU
					createIfNotExists: DomainAndRCU
					# Image containing WDT installer and Model files.
					domainCreationImages:
						 - image: 'container-registry.example.com/mytenancy/idm:oig-aux-generic-v1'
					domainType: OIG
	  # References to Cluster resources that describe the lifecycle options for all
	  # the Managed Server members of a WebLogic cluster, including Java
	  # options, environment variables, additional Pod content, and the ability to
	  # explicitly start, stop, or restart cluster members. The Cluster resource
	  # must describe a cluster that already exists in the WebLogic domain
	  # configuration.
	  clusters:
	  - name: governancedomain-oim-cluster
	  - name: governancedomain-soa-cluster

	  # The number of managed servers to start for unlisted clusters
	  # replicas: 1

	---
	# This is an example of how to define a Cluster resource.
	apiVersion: weblogic.oracle/v1
	kind: Cluster
	metadata:
	  name: governancedomain-oim-cluster
	  namespace: oigns
	spec:
	  clusterName: oim_cluster
	  serverService:
		 precreateService: true
	  replicas: 0
	  serverPod:
		 env:
		 - name: USER_MEM_ARGS
			value: "-Djava.security.egd=file:/dev/./urandom -Xms8192m -Xmx8192m  "
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
	  name: governancedomain-soa-cluster
	  namespace: oigns
	spec:
	  clusterName: soa_cluster
	  serverService:
		 precreateService: true
	  replicas: 1
	  serverPod:
		 env:
		 - name: USER_MEM_ARGS
			value: "-Xms8192m -Xmx8192m "
		 resources:
			limits:
			  cpu: "1"
			  memory: "10Gi"
			requests:
			  cpu: "1000m"
			  memory:  "4Gi"
	```
	
	{{% /expand %}}

   **Note**: By default, WebLogic operator will create the RCU schema using WDT tooling and patch them during every domain deployment. If the RCU Schema with the given prefix already exists, and error will be thrown and the domain creation will fail. If you want to delete the schema every time during domain deployment, then can change the value `"-Dwdt.config.disable.rcu.drop.schema=true"` to `"-Dwdt.config.disable.rcu.drop.schema=false"`.
	
#####  Optional WDT Models ConfigMap

If required, you can provide a Kubernetes ConfigMap with additional WDT models and WDT variables files as supplements, or overrides, to those in `domainCreationImages`. For example in the  `output/weblogic-domains/governancedomain/domain.yaml`:

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
	$ cd $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils
	$ ./create-configmap.sh -n oigns -d governancedomain -c mymodel-domain-configmap -f wdt_models/mymodel.yaml
   ```


For more information on the usage of additional configuration, see [Optional WDT models ConfigMap](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/usage/#optional-wdt-models-configmap).




##### Deploy the OIG domain

In this section you deploy the OIG domain using the `domain.yaml`.

1. Run the following command to create OIG domain resources:

   ```bash
   $ kubectl create -f $WORKDIR/yaml/domain.yaml
   ```

   The following steps will be performed by WebLogic Kubernetes Operator:
   
   + Run the introspector job.
	+ The introspection job will create the RCU Schemas and then patch them.
   + The introspector job pod will create the domain on PV using the model provided in the domain creation image.
   + The introspector job pod will execute OIG offline configuration actions post successful creation of domain via WDT.
   + Brings up the Administration Server, and the SOA Managed Server (`soa_server1`).
   
   
   The output will look similar to the following:

   ```
   domain.weblogic.oracle/governancedomain created
   cluster.weblogic.oracle/governancedomain-oim-cluster created
   cluster.weblogic.oracle/governancedomain-soa-cluster created
   ```
   
   Whilst the domain creation is running, you can run the following command to monitor the progress:
   
   ```bash
   $ kubectl get pods -n oigns -w
   ```

   You can also tail the logs for the pods by running:

   ```bash
   $ kubectl logs -f <pod> -n oigns
   ```

   WDT specific logs can be found in `<persistent_volume>/domains/wdt-logs`.

   Once everything is started you should see the Administration Server and SOA server are running:
   
   ```
   NAME                           READY   STATUS    RESTARTS   AGE
   governancedomain-adminserver   1/1     Running   0          13m
   governancedomain-soa-server1   1/1     Running   0          10m
   ```

   If there are any failures, follow **Domain creation failure with WDT models** in the [Troubleshooting](../../troubleshooting/#domain-creation-failure-with-wdt-models) section.
  
   **Note**: Depending on the speed of your cluster, it can take around 25 minutes for all the pods to be in `READY 1/1` state.
	

1. Start the OIM server by running the following command:

   ```
	$ kubectl patch cluster -n oigns governancedomain-oim-cluster --type=merge -p '{"spec":{"replicas":1}}'
	```
	
   The output will look similar to the following:

   ```
	cluster.weblogic.oracle/governancedomain-oim-cluster patched
	```
	
   You can view the status of the OIM server by running:

   ```
	$ kubectl get pods -n oigns -w
	```
	
	Once the OIM server is running, the output will look similar to the following:

   ```
	NAME                           READY   STATUS    RESTARTS   AGE
   governancedomain-adminserver   1/1     Running   0          16m
   governancedomain-soa-server1   1/1     Running   0          13m
   governancedomain-oim-server1   1/1     Running   0          5m22s
	```

### Verify the results

#### Verify the domain, pods and services

1. Verify the domain, servers pods and services are created and in the `READY` state with a `STATUS` of `1/1`, by running the following command:

   ```bash
   $ kubectl get all,domains -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl get all,domains -n oigns
   ```
   
   The output will look similar to the following:

   ```
	NAME                               READY   STATUS    RESTARTS   AGE
	pod/governancedomain-adminserver   1/1     Running   0          25m
	pod/governancedomain-oim-server1   1/1     Running   0          7m18s
	pod/governancedomain-soa-server1   1/1     Running   0          20m

	NAME                                           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)               AGE
	service/governancedomain-adminserver           ClusterIP   None             <none>        7001/TCP              25m
	service/governancedomain-cluster-oim-cluster   ClusterIP   10.102.36.107    <none>        14002/TCP,14000/TCP   20m
	service/governancedomain-cluster-soa-cluster   ClusterIP   10.102.230.187   <none>        8001/TCP              20m
	service/governancedomain-oim-server1           ClusterIP   None             <none>        14002/TCP,14000/TCP   7m18s
	service/governancedomain-oim-server2           ClusterIP   10.111.183.16    <none>        14002/TCP,14000/TCP   20m
	service/governancedomain-oim-server3           ClusterIP   10.107.144.169   <none>        14002/TCP,14000/TCP   20m
	service/governancedomain-oim-server4           ClusterIP   10.110.18.114    <none>        14002/TCP,14000/TCP   20m
	service/governancedomain-oim-server5           ClusterIP   10.106.220.13    <none>        14002/TCP,14000/TCP   20m
	service/governancedomain-soa-server1           ClusterIP   None             <none>        8001/TCP              20m
	service/governancedomain-soa-server2           ClusterIP   10.104.204.68    <none>        8001/TCP              20m
	service/governancedomain-soa-server3           ClusterIP   10.110.104.108   <none>        8001/TCP              20m
	service/governancedomain-soa-server4           ClusterIP   10.103.117.118   <none>        8001/TCP              20m
	service/governancedomain-soa-server5           ClusterIP   10.101.65.38     <none>        8001/TCP              20m

	NAME                                      AGE
	domain.weblogic.oracle/governancedomain   32m

	NAME                                                   AGE
	cluster.weblogic.oracle/governancedomain-oim-cluster   32m
	cluster.weblogic.oracle/governancedomain-soa-cluster   32m
   ```
   
 
   The default domain created by the sample WDT models has the following characteristics:

   * An Administration Server named `AdminServer` listening on port `7001`.
   * A configured OIG cluster named `oig_cluster` of size 5.
   * A configured SOA cluster named `soa_cluster` of size 5.
   * One started OIG managed Server, named `oim_server1`, listening on port `14000`.
   * One started SOA managed Server, named `soa_server1`, listening on port `8001`.
   * Log files that are located in `<persistent_volume>/logs/<domainUID>`


#### Verify the domain

1. Run the following command to describe the domain: 

   ```bash
   $ kubectl describe domain <domain_uid> -n <namespace>
   ```

   For example:
   
   ```bash
   $ kubectl describe domain governancedomain -n oigns
   ```

   {{%expand "Click here to see example output:" %}}
   ```bash
	Name:         governancedomain
	Namespace:    oigns
	Labels:       weblogic.domainUID=governancedomain
	Annotations:  <none>
	API Version:  weblogic.oracle/v9
	Kind:         Domain
	Metadata:
	  Creation Timestamp:  <DATE>
	  Generation:          1
	  Resource Version:    1013312
	  UID:                 b5b4446b-b056-431f-8ae4-db470ac7731e
	Spec:
	  Admin Server:
		 Admin Channel Port Forwarding Enabled:  true
		 Server Pod:
			Env:
			  Name:             USER_MEM_ARGS
			  Value:            -Djava.security.egd=file:/dev/./urandom -Xms512m -Xmx1024m
		 Server Start Policy:  IfNeeded
	  Clusters:
		 Name:  governancedomain-oim-cluster
		 Name:  governancedomain-soa-cluster
	  Configuration:
		 Initialize Domain On PV:
			Domain:
			  Create If Not Exists:  DomainAndRCU
			  Domain Creation Images:
				 Image:      container-registry.example.com/mytenancy/idm:oig-aux-generic-v1
			  Domain Type:  OIG
			Persistent Volume:
			  Metadata:
				 Name:  governancedomain-domain-pv
			  Spec:
				 Capacity:
					Storage:  10Gi
				 Nfs:
					Path:                            /scratch/shared/governancedomainpv
					Server:                          mynfsserver
				 Persistent Volume Reclaim Policy:  Retain
				 Storage Class Name:                governancedomain-domain-storage-class
			Persistent Volume Claim:
			  Metadata:
				 Name:  governancedomain-domain-pvc
			  Spec:
				 Resources:
					Requests:
					  Storage:               10Gi
				 Storage Class Name:        governancedomain-domain-storage-class
				 Volume Name:               governancedomain-domain-pv
		 Override Distribution Strategy:  Dynamic
		 Secrets:
			governancedomain-rcu-credentials
	  Data Home:
	  Domain Home:                     /u01/oracle/user_projects/domains/governancedomain
	  Domain Home Source Type:         PersistentVolume
	  Failure Retry Interval Seconds:  120
	  Failure Retry Limit Minutes:     1440
	  Http Access Log In Log Home:     true
	  Image:                           container-registry.oracle.com/middleware/oig_cpu:12.2.1.4-jdk8-ol8-<July'24>
	  Image Pull Policy:               IfNotPresent
	  Image Pull Secrets:
		 Name:                             orclcred
		 Name:                             privatecred
	  Include Server Out In Pod Log:      true
	  Log Home:                           /u01/oracle/user_projects/domains/logs/governancedomain
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
			Name:   USER_MEM_ARGS
			Value:  -Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx1024m
			Name:   WLSDEPLOY_LOG_DIRECTORY
			Value:  /u01/oracle/user_projects/domains/wdt-logs
			Name:   FRONTENDHOST
			Value:  example.com
			Name:   FRONTENDPORT
			Value:  14000
			Name:   WLSDEPLOY_PROPERTIES
			Value:  -Dwdt.config.disable.rcu.drop.schema=true
		 Env From:
			Secret Ref:
			  Name:  governancedomain-rcu-credentials
		 Init Containers:
			Command:
			  /bin/bash
			  -c
			  mkdir -p  /u01/oracle/user_projects/domains/ConnectorDefaultDirectory
			  mkdir -p  /u01/oracle/user_projects/domains/wdt-logs
			Image:              container-registry.oracle.com/middleware/oig_cpu:12.2.1.4-jdk8-ol8-<July'24>
			Image Pull Policy:  IfNotPresent
			Name:               compat-connector-init
			Volume Mounts:
			  Mount Path:  /u01/oracle/user_projects
			  Name:        weblogic-domain-storage-volume
		 Volume Mounts:
			Mount Path:  /u01/oracle/user_projects
			Name:        weblogic-domain-storage-volume
		 Volumes:
			Name:  weblogic-domain-storage-volume
			Persistent Volume Claim:
			  Claim Name:     governancedomain-domain-pvc
	  Server Start Policy:  IfNeeded
	  Web Logic Credentials Secret:
		 Name:  governancedomain-weblogic-credentials
	Status:
	  Clusters:
		 Cluster Name:  oim_cluster
		 Conditions:
			Last Transition Time:  <DATE>
			Status:                True
			Type:                  Available
			Last Transition Time:  <DATE>
			Status:                True
			Type:                  Completed
		 Label Selector:          weblogic.domainUID=governancedomain,weblogic.clusterName=oim_cluster
		 Maximum Replicas:        5
		 Minimum Replicas:        0
		 Observed Generation:     2
		 Ready Replicas:          1
		 Replicas:                1
		 Replicas Goal:           1
		 Cluster Name:            soa_cluster
		 Conditions:
			Last Transition Time:  <DATE>
			Status:                True
			Type:                  Available
			Last Transition Time:  <DATE>
			Status:                True
			Type:                  Completed
		 Label Selector:          weblogic.domainUID=governancedomain,weblogic.clusterName=soa_cluster
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
		 Node Name:     doc-worker2
		 Pod Phase:     Running
		 Pod Ready:     True
		 Server Name:   AdminServer
		 State:         RUNNING
		 State Goal:    RUNNING
		 Cluster Name:  oim_cluster
		 Health:
			Activation Time:  <DATE>
			Overall Health:   ok
			Subsystems:
			  Subsystem Name:  ServerRuntime
			  Symptoms:
		 Node Name:     doc-worker1
		 Pod Phase:     Running
		 Pod Ready:     True
		 Server Name:   oim_server1
		 State:         RUNNING
		 State Goal:    RUNNING
		 Cluster Name:  oim_cluster
		 Server Name:   oim_server2
		 State:         SHUTDOWN
		 State Goal:    SHUTDOWN
		 Cluster Name:  oim_cluster
		 Server Name:   oim_server3
		 State:         SHUTDOWN
		 State Goal:    SHUTDOWN
		 Cluster Name:  oim_cluster
		 Server Name:   oim_server4
		 State:         SHUTDOWN
		 State Goal:    SHUTDOWN
		 Cluster Name:  oim_cluster
		 Server Name:   oim_server5
		 State:         SHUTDOWN
		 State Goal:    SHUTDOWN
		 Cluster Name:  soa_cluster
		 Health:
			Activation Time:  <DATE>
			Overall Health:   ok
			Subsystems:
			  Subsystem Name:  ServerRuntime
			  Symptoms:
		 Node Name:     doc-worker1
		 Pod Phase:     Running
		 Pod Ready:     True
		 Server Name:   soa_server1
		 State:         RUNNING
		 State Goal:    RUNNING
		 Cluster Name:  soa_cluster
		 Server Name:   soa_server2
		 State:         SHUTDOWN
		 State Goal:    SHUTDOWN
		 Cluster Name:  soa_cluster
		 Server Name:   soa_server3
		 State:         SHUTDOWN
		 State Goal:    SHUTDOWN
		 Cluster Name:  soa_cluster
		 Server Name:   soa_server4
		 State:         SHUTDOWN
		 State Goal:    SHUTDOWN
		 Cluster Name:  soa_cluster
		 Server Name:   soa_server5
		 State:         SHUTDOWN
		 State Goal:    SHUTDOWN
	  Start Time:      <DATE>
	Events:            <none>

   ```
	{{% /expand %}}
	
#### Verify the pods

1. Run the following command to see the pods running the servers and which nodes they are running on:

   ```bash
   $ kubectl get pods -n <namespace> -o wide
   ```

   For example:

   ```bash
   $ kubectl get pods -n oigns -o wide
   ```

   The output will look similar to the following:

   ``` bash
   NAME                                                        READY   STATUS      RESTARTS   AGE     IP            NODE           NOMINATED NODE   READINESS GATES
   governancedomain-adminserver                                1/1     Running     0          26m     10.244.1.42   worker-node2   <none>           <none
   governancedomain-oim-server1                                1/1     Running     0          7m56s   10.244.1.44   worker-node2   <none>           <none>
   governancedomain-soa-server1                                1/1     Running     0          21m     10.244.1.43   worker-node2   <none>           <none>
   ```

   You are now ready to configure an Ingress to direct traffic for your OIG domain as per [Configure an ingress for an OIG domain](../../configure-ingress).
