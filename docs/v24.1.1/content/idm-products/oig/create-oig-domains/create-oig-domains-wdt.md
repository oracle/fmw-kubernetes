+++
title = "b. Create OIG domains using WDT Models"
+++

1. [Introduction](#introduction)
1. [Prerequisites](#prerequisites)
1. [Working with WDT Model files](#working-with-wdt-model-files)
1. [Preparing the environment for domain creation](#preparing-the-environment-for-domain-creation)
1. [Create Domain Creation Image](#create-domain-creation-image)
1. [Create the OIG Domain](#create-the-oig-domain)
1. [Verify the results](#verify-the-results)

    a. [Verify the domain, pods and services](#verify-the-domain-pods-and-services)
	
    b. [Verify the domain](#verify-the-domain)
	
    c. [Verify the pods](#verify-the-pods)
	
### Introduction

This section demonstrates the creation of an OIG domain home using sample WebLogic Deploy Tooling (WDT) model files.

Beginning with WebLogic Kubernetes Operator version 4.1.2, you can provide a section, `domain.spec.configuration.initializeDomainOnPV`, to initialize an OIG domain on a persistent volume when it is first deployed. 
This eliminates the need to pre-create your OIG domain using sample Weblogic Scripting Tool (WLST) offline scripts.  

**Note** This is a one time only initialization. After the domain is created, subsequent updates to this section in the domain resource YAML file will not recreate or update the WebLogic domain.
Subsequent domain lifecycle updates must be controlled by the WebLogic Server Administration Console, Enterprise Manager Console, WebLogic Scripting Tool (WLST), or other mechanisms.

WebLogic Deploy Tooling (WDT) models are a convenient and simple alternative to WebLogic Scripting Tool (WLST) configuration scripts. They compactly define a WebLogic domain using model files, variable properties files, and application archive files. For more information about the model format and its integration, see [Usage](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/usage/) and [Working with WDT Model files](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/model-files/). The WDT model format is fully described in the open source, [WebLogic Deploy Tooling GitHub project](https://oracle.github.io/weblogic-deploy-tooling/).

The main benefits of WDT are:

* A set of single-purpose tools supporting WebLogic domain configuration lifecycle operations.
* All tools work off of a shared, declarative model, eliminating the need to maintain specialized WLST scripts.
* WDT knowledge base understands the MBeans, attributes, and WLST capabilities/bugs across WLS versions.

The initializeDomainOnPv section:

1. Creates the PersistentVolume (PV) and/or PersistenVolumeClaim (PVC).
1. Creates the OIG domain home on the persistent volume based on the provided WDT models.

### Prerequisites

Before you begin, perform the following steps:

1. Review the [domain-on-pv](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/) documentation.
1. Ensure that the database is up and running. RCU Schemas are created and patched.

**Note**: In this section a domain creation image is built using the supplied model files and then that image is used for domain creation. You will need your own container registry to upload the domain image to. Having your own container repository is a prerequisite before creating an OIG domain with WDT models. If you don't have your own container registry, you can instead load the image on each node in the cluster. This documentation does not explain how to either create your own container registry or how to load the image onto each node. Consult your vendor specific documentation for more information.

### Working with WDT Model Files

The code repository (`$WORKDIR`) contains different WDT model files to create an OIG domain. The following table defines these files:

More information on the WDT Metadata model see, [Metadata model](https://oracle.github.io/weblogic-deploy-tooling/concepts/model/).

| Model File | Definition | Required for base domain creation image |
| --- | --- | --- |
| domainInfo.yaml | The location where special information not represented in WLST is specified (for example, OPSS Initialization parameters). In most of the cases, you do not need to customize this file| Y |
| topology.yaml |  The location where servers, clusters and other domain-level configuration is specified. You can customize this based on the topology that you need.| Y |
| resources.yaml | The location where resources and services are specified (for example, data sources, JMS, WLDF). You can customize this based on your environment specific requirement. For example, if you want to use different datasource connection pool parameters from the ones coming via template, you can add details here.| Y |
| oig.properties | The location where you can customize the default values for different parameters  such as Listen Port, T3 Channel port etc. | Y |
|agl_jdbc.yaml | This is an optional model file specifying parameters needed to use Active Gridlink type of datasources for your domain | N (Optional) |




### Preparing the environment for domain creation

In this section you prepare the environment for the OIG domain creation using WDT models. This involves the following steps:

1. Creating Kubernetes secrets for the domain and RCU

1. Creating a persistent volume

#### Creating Kubernetes secrets for the domain and RCU

1. Create a Kubernetes secret for the domain using the `create-secret.sh` script in the same Kubernetes namespace as the domain:

   ```bash
   $ cd $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-utils
   $ ./create-secret.sh -l "username=weblogic" -l "password=****" -n <domain_namespace> -d <domain_uid> -s <kubernetes_domain_secret>
   ```
   where:

   `-n <domain_namespace>` is the domain namespace.
    
   `-d <domain_uid>` is the domain UID to be created.
    
   `-s <kubernetes_domain_secret>` is the name you want to create for the secret for this namespace.

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
   $ ./create-secret.sh -l "rcu_prefix=<rcu_prefix>" -l "rcu_schema_password=<rcu_schema_pwd>" -l "db_host=<db_host.domain>" -l "db_port=<db_port>" -l "db_service=<service_name>" -l "dba_user=<sys_db_user>" -l "dba_password=<sys_db_pwd>" -n <domain_namespace> -d <domain_uid> -s <kubernetes_rcu_secret>
   ```
   
   where

   `<rcu_prefix>` is the name of the RCU schema prefix created previously.
    
   `<rcu_schema_pwd>` is the password for the RCU schema prefix.

   `<db_host.domain>` is the database server hostname.
   .
   `<db_port>` is the database listener port.
   
   `<service_name>` is the database service name.
    
   `<sys_db_user>` is the database user with sys dba privilege.
    
   `<sys_db_pwd>` is the sys database password.
    
   `<domain_uid>` is the domain_uid that you created earlier.
    
   `<domain_namespace>` is the domain namespace.
    
   `<kubernetes_rcu_secret>` is the name of the rcu secret to create.

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

#### Create Persistent Volume

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

### Create Domain Creation Image

Domain creation images are used for supplying WebLogic Deploy Tooling (WDT) model files, WDT variables files, WDT application archive files (collectively known as WDT model files), and the directory where the WebLogic Deploy Tooling software is installed (known as the WDT Home) when deploying a domain using a Domain on PV model. You distribute WDT model files and the WDT executable using these images, then the WebLogic Kubernetes Operator uses them to manage the domain.

**Note**: These images are only used for creating the domain and will not be used to update the domain.

**Note**: The domain creation image is used for domain creation only, it is not the product container image used for OIG.

For more details on creating the domain image, see [Domain creation images](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/domain-creation-images/).

The steps to create the domain creation image are shown in the sections below.

#### Set up the WebLogic Image Tool

* [Image tool prerequisites](#image-tool-prerequisites)
* [Prepare the WebLogic Image Tool](#prepare-the-weblogic-image-tool)
* [Validate setup](#validate-setup)
* [WebLogic Image Tool build directory](#weblogic-image-tool-build-directory)
* [WebLogic Image Tool cache](#weblogic-image-tool-cache)


##### Image tool prerequisites

Verify that your environment meets the following prerequisites:

* A container image client on the build machine, such as Docker or Podman.
  * For Docker, a minimum version of 18.03.1.ce is required.
  * For Podman, a minimum version of 3.0.1 is required.
* Bash version 4.0 or later, to enable the <tab> command complete feature.
* An installed version of Java to run Image Tool, version 8+. JAVA_HOME environment variable set to the appropriate JDK location e.g: /scratch/export/oracle/product/jdk

##### Prepare the WebLogic Image Tool

To set up the WebLogic Image Tool:

1. Create a working directory and change to it:

   ```bash
   $ mkdir <workdir>
   $ cd <workdir>
   ```
   
   For example:

   ```bash
   $ mkdir /scratch/imagetool-setup
   $ cd /scratch/imagetool-setup
   ```
1. Download the latest version of the WebLogic Image Tool from the [releases page](https://github.com/oracle/weblogic-image-tool/releases/latest).

   ```bash
   $ wget https://github.com/oracle/weblogic-image-tool/releases/download/release-X.X.X/imagetool.zip
   ```
	
   where X.X.X is the latest release referenced on the [releases page](https://github.com/oracle/weblogic-image-tool/releases/latest).

	
1. Unzip the release ZIP file in the `imagetool-setup` directory.

   ```bash
   $ unzip imagetool.zip
   ````
 
1. Execute the following commands to set up the WebLogic Image Tool:

    ```bash
    $ export JAVA_HOME=<JAVA_HOME>
    $ cd <workdir>/imagetool-setup/imagetool/bin
    $ source setup.sh
    ```
	
	For example:
	
    ```bash
    $ export JAVA_HOME=/scratch/imagetool-setup/jdk1.8.0_341
    $ cd /scratch/imagetool-setup/imagetool/bin
    $ source setup.sh
    ```

##### Validate setup

To validate the setup of the WebLogic Image Tool:

1. Enter the following command to retrieve the version of the WebLogic Image Tool:

   ``` bash
   $ imagetool --version
   ```

2. Enter `imagetool` then press the Tab key to display the available `imagetool` commands:

   ``` bash
   $ imagetool <TAB>
   cache           create          createAuxImage  inspect         rebase          update
   ```

##### WebLogic Image Tool Build Directory
The WebLogic Image Tool creates a temporary Docker context directory, prefixed by wlsimgbuilder_temp, every time the tool runs. Under normal circumstances, this context directory will be deleted. However, if the process is aborted or the tool is unable to remove the directory, it is safe for you to delete it manually. By default, the WebLogic Image Tool creates the Docker context directory under the user’s home directory. If you prefer to use a different directory for the temporary context, set the environment variable WLSIMG_BLDDIR:

   ```bash
   $ export WLSIMG_BLDDIR="/path/to/buid/dir"
   ```

##### WebLogic Image Tool Cache
The WebLogic Image Tool maintains a local file cache store. This store is used to look up where the Java, WebLogic Server installers, and WebLogic Server patches reside in the local file system. By default, the cache store is located in the user’s $HOME/cache directory. Under this directory, the lookup information is stored in the .metadata file. All automatically downloaded patches also reside in this directory. You can change the default cache store location by setting the environment variable WLSIMG_CACHEDIR:

   ```bash
   $ export WLSIMG_CACHEDIR="/path/to/cachedir"
   ```
   
   
#### Download WDT Installer

WDT models are a convenient and simple alternative to WLST configuration scripts. They compactly define a WebLogic domain using model files, variable properties files, and application archive files. For more information about the model format and its integration, see [Usage](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/usage/) and [Working with WDT Model files](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/model-files/). The WDT model format is fully described in the open source, [WebLogic Deploy Tooling GitHub project](https://oracle.github.io/weblogic-deploy-tooling/).

Creation of an OIG domain using sample WDT model files is supported from WDT version 3.2.4 onwards.

Run the following steps to download and configure WDT for OIG deployment:

1. Create a working directory:

   ```bash
   $ mkdir <workdir>
   $ cd <workdir>
   ```

1. For example:

   ```bash
   $ mkdir /scratch/wdt-setup
   $ cd /scratch/wdt-setup
   ```

1. Download the WDT tool from [releases page](https://github.com/oracle/weblogic-deploy-tooling/releases/tag/release-3.2.4):

   ```bash
   $ wget https://github.com/oracle/weblogic-deploy-tooling/releases/download/release-3.2.4/weblogic-deploy.zip
   ```

1. Unzip and add OIG domain type definition in WDT:

   ```bash
   $ unzip weblogic-deploy.zip
   $ cp $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-artifacts/OIG.json weblogic-deploy/lib/typedefs/
   $ zip -r weblogic-deploy.zip weblogic-deploy
   ```

#### Create OIG domain creation image

1. Add WDT installer in imagetool cache:

   ```bash
   $ imagetool cache addInstaller --type wdt --version latest --path /scratch/wdt-setup/weblogic-deploy.zip
   ```

1. Create the image:

   ```bash
   $ imagetool createAuxImage --tag oig-aux:v1 \
   --wdtModel $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-artifacts/domainInfo.yaml,\
   $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-artifacts/resource.yaml,\
   $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-artifacts/topology.yaml \
   --wdtVariables $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-artifacts/oig.properties \
   --fromImage ghcr.io/oracle/oraclelinux:7-slim
   ```

	**Note**: If using podman add `--builder podman` to the command. Make sure podman is on the $PATH before executing.
	
	The output will look similar to the following:
   
   ```
	[INFO   ] WebLogic Image Tool version 1.12.1
	[INFO   ] Image Tool build ID: 7e0cc147-9b68-4350-bef4-c04eff5f5490
	[INFO   ] User specified fromImage ghcr.io/oracle/oraclelinux:7-slim
	[INFO   ] Temporary directory used for image build context: /scratch/wlsimgbuilder_temp8804718050511845993
	[INFO   ] Inspecting ghcr.io/oracle/oraclelinux:7-slim, this may take a few minutes if the image is not available locally.
	[INFO   ] Copying $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-artifacts/domainInfo.yaml to build context folder.
	[INFO   ] Copying $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-artifacts/resource.yaml to build context folder.
	[INFO   ] Copying $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-artifacts/topology.yaml to build context folder.
	[INFO   ] Copying $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/wdt-artifacts/oig.properties to build context folder.
	[INFO   ] Copying /scratch/wdt-setup/weblogic-deploy.zip to build context folder.
	[INFO   ] Starting build: docker build --no-cache --force-rm --tag oig-aux:v1 --build-arg http_proxy=http://proxy.example.com:80 --build-arg https_proxy=http://proxy.example.com:80 --build-arg no_proxy=localhost,127.0.0.0/8,.example.com,/var/run/crio/crio.sock /scratch/wlsimgbuilder_temp8804718050511845993
	[1/3] STEP 1/5: FROM ghcr.io/oracle/oraclelinux:7-slim AS os_update
	[1/3] STEP 2/5: LABEL com.oracle.weblogic.imagetool.buildid="7e0cc147-9b68-4350-bef4-c04eff5f5490"
	--> 23fca4e2d80
   ...
   etc
   ...
	[3/3] COMMIT oig-aux:v1
	--> e3aa2755aac
	Successfully tagged localhost/oig-aux:v1
	e3aa2755aacb23a622c8daa44b81f7ce74a202e3caa947214e5d2deb91691806
	[INFO   ] Build successful. Build time=615s. Image tag=oig-aux:v1
   ```
	
1. Tag and push the image to your container registry:

   **Note**: If you are not using your own container registry for storing images, then you must export the image as a tar file, and then load it on every worker node.

   ```bash
   $ docker tag oig-aux:v1 container-registry.example.com/oig-aux:v1
   $ docker push container-registry.example.com/oig-aux:v1
   ```
   
   Or if using podman:

   ```bash
   $ podman tag oig-aux:v1 container-registry.example.com/oig-aux:v1
   $ podman push container-registry.example.com/oig-aux:v1
   ```
	
	

#### Customize sample WDT models (Optional)

If you want to customize the WDT models on top of the already created domain image, you can provide additional WDT model and variables as supplements or overrides to those values in domainCreationImages.

For more information on the usage of additional configuration, see [Optional WDT models ConfigMap](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/usage/#optional-wdt-models-configmap).

The example below will change the JDBC datasource type from generic (default option) to Active Gridlink. Similarly you can use this option to modify existing or supplements additional values to use while creating the domain:

1. Create the configmap with the configuration:

   ```bash
   $ cd $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/
   $ wdt-utils/create-configmap.sh -n <namespace> -d <domain-name> -c <Config Map name> -f <configuration file location>
   ```

   For example:

   ```bash
   $ cd $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/
   $ wdt-utils/create-configmap.sh -n oigns -d governancedomain -c agl-cm -f wdt-artifacts/agl_jdbc.yaml 
   ```

   The output will look similar to the following:
   
   ```bash
   kubectl -n oigns delete configmap agl-cm --ignore-not-found
   kubectl -n oigns create configmap agl-cm --from-file=wdt-artifacts/agl_jdbc.yaml
   configmap/agl-cm created
   kubectl -n oigns label configmap agl-cm weblogic.domainUID=governancedomain
   configmap/agl-cm labeled
   ```

1. Modify the existing `domain.yaml` to use the configmap:

   ```bash
     domain:
          ...
          domainCreationImages:
              ...
          domainCreationConfigMap: mymodel-domain-configmap
   ```

   For example:

   ```bash
        domain:
            # Domain | DomainAndRCU
            createIfNotExists: Domain
            domainCreationImages:
                - image: 'oracle/oigaux:v1'
            domainCreationConfigMap: agl-cm
            domainType: OIG
   ```

### Create the OIG domain

In this section you create the OIG domain. 

#### Modify the OIG domain.yaml

In this section you modify the `domain.yaml` file in preparation for creating the OIG domain.

1. Navigate to the `$WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/domain-resources` directory and take a backup of the `domain.yaml`:

   ```bash
   cd $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/domain-resources
   cp domain.yaml domain.yaml.orig
   ```

1. Edit the `domain.yaml` file and modify the following parameters where applicable. Save the file when complete:

   If you have used the default naming conventions in the documentation for namespace (`oigns`), domain UID (`governancedomain`), secrets (`orclcred`, `governancedomain-rcu-credentials` and `governancedomain-weblogic-credentials`), then you only need to change the following parameters:
	
	```
	image: <container_image_name>
	initContainers.image: <container_image_name>
	nfs.server: <NFS_server_IP_address_used_for_persistent_storage>
	nfs.path: <physical_path_of_persistent_storage>
	domainCreationImages.image: <domain_image_name>
	```
	
	For example:
	
	```
   image: container-registry.oracle.com/middleware/oig_cpu:12.2.1.4-jdk8-ol8-<January'24>
	initContainers.image: container-registry.oracle.com/middleware/oig_cpu:12.2.1.4-jdk8-ol8-<January'24>
	nfs.server: mynfsserver
	nfs.path: /scratch/shared/governancedomainpv
	domainCreationImages.image: container-registry.example.com/oig-aux:v1
	```
	
	If you have changed any of the default naming conventions you will also have to edit other parameters accordingly. A full list of parameters in the `domain.yaml` file are shown below:

   Domain definition:- 

   | Parameter | definition | default |
   | --- | --- | --- |
   | metadata.name | `<Domain name>` | governancedomain |
   | namespace |  Kubernetes namespace in which to create the domain,cluster,pv etc | oigns |
   | domainUID | Unique ID that will be used to identify this particular domain. Used as the name of the generated WebLogic domain as well as the name of the Kubernetes domain resource. This ID must be unique across all domains in a Kubernetes cluster. This ID cannot contain any character that is not valid in a Kubernetes service name. | governancedomain |
   |spec.domainHome | Home directory of the OIG domain, `/u01/oracle/user_projects/domains/<domain name>` | `/u01/oracle/user_projects/domains/governancedomain` |
   | image | OIG container image. The operator requires OIG 12.2.1.4. Refer to [Obtain the OIG container image](../prepare-your-environment#obtain-the-oig-container-image) for details on how to obtain or create the image. Note that OIG domain creation via WDT models is supported from Oct'23 BP image onwards. | `oracle/oig:12.2.1.4.0` |
   | imagePullSecrets | Name of the Kubernetes secret to access the container registry to pull the OIG product container image and domain creation image. The presence of the secret will be validated when this parameter is specified. | `orclcred` | 
   | webLogicCredentialsSecret | Name of the Kubernetes secret for the Administration Server’s user name and password. If not specified, then the value is derived from the domainUID as `<domainUID>-weblogic-credentials`. | `governancedomain-weblogic-credentials` |
   | logHome | The in-pod location for the domain log, server logs, server out, and Node Manager log files.  | `/u01/oracle/user_projects/domains/logs/governancedomain` |
   | initContainers.image |OIG container image. The operator requires OIG 12.2.1.4. Refer to [Obtain the OIG container image](../prepare-your-environment#obtain-the-oig-container-image) for details on how to obtain or create the image. **Note**:OIG domain creation via WDT models is supported from Oct'23 BP image onwards. | `oracle/oig:12.2.1.4.0` |
   | persistentVolumeClaim.claimName | Name of the persistent volume claim created to host the domain home. | `governancedomain-domain-pvc` |
   | configuration.secrets | The Kubernetes secret containing the database credentials. |`governancedomain-rcu-credentials` |
   | persistentVolume.metadata.name | Persistent Volume name | `governancedomain-domain-pv` |
   | storageClassName | Storage class name for the PV and PVC | `governancedomain-domain-storage-class` |
   | nfs.server | NFS server IP address used for the PV and PVC | `nfsServer` |
   | nfs.path | NFS server Path - physical_path_of_persistent_storage | `/scratch/k8s_dir` |
   | persistentVolumeClaim.metadata.name | Name of the persistent volume claim created to host the domain home | `governancedomain-domain-pvc` |
   | volumeName | PV name to bing PV with PVC | `governancedomain-domain-pv` |
   | domainCreationImages.image | Domain creation image name, containing WDT Installer and Model files. Can be one or more images specifying models in a layered manner.  Refer to [Multiple Images](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/domain-creation-images/#multiple-images) for more details.  | `oracle/oig:oct23-aux-12.2.1.4.0` |
   | clusters.name | list of cluster name for managed oim-server and soa-server - format as `<domainUID>-oim-cluster and <domainUID-soa-cluster>`| `governancedomain-oim-cluster` and `governancedomain-soa-cluster` |

   Cluster Definition:-

   | Parameter | definition | default |
   | --- | --- | --- |
   | metadata.name | oim and soa cluster name `<domainUID>-oim-cluster` or `<domainUID>-soa-cluster` | for soa cluster - governancedomain-soa-cluster and for oim cluster governancedomain-oim-cluster |
   | metadata.namespace | cluster namespace - should be same as of domain namespace | `oigns` |



   For more details about these configuration parameters please see [Domain Resources](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-resource/). 
	
{{%expand "Click here to see an example domain.yaml:" %}}
```
# Copyright (c) 2023, Oracle and/or its affiliates.
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
  image: "container-registry.oracle.com/middleware/oig_cpu:12.2.1.4-jdk8-ol8-<January'24>"

  # imagePullPolicy defaults to "Always" if image version is :latest
  imagePullPolicy: IfNotPresent

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
        image: "container-registry.oracle.com/middleware/oig_cpu:12.2.1.4-jdk8-ol8-<January'24>"
        imagePullPolicy: IfNotPresent
        command: [ "/bin/bash", "-c", "mkdir -p /u01/oracle/user_projects/domains/ConnectorDefaultDirectory", "mkdir -p  /u01/oracle/user_projects/domains/wdt-logs"]
        volumeMounts:
          - mountPath: /u01/oracle/user_projects/
            name: weblogic-domain-storage-volume
    # a mandatory list of environment variable to be set on the servers
    env:
    - name: JAVA_OPTIONS
      value: "-Dweblogic.StdoutDebugEnabled=false"
    - name: USER_MEM_ARGS
      value: "-Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx1024m "
    - name: WLSDEPLOY_LOG_DIRECTORY
      value: "/u01/oracle/user_projects/domains/wdt-logs"
    - name: FRONTENDHOST
      value: "example.com"
    - name: FRONTENDPORT
      value: "14000"
    volumes:
    - name: weblogic-domain-storage-volume
      persistentVolumeClaim:
        claimName: governancedomain-domain-pvc
    volumeMounts:
    - mountPath: /u01/oracle/user_projects/
      name: weblogic-domain-storage-volume

  # adminServer is used to configure the desired behavior for starting the administration server.
  adminServer:
    # adminService:
    #   channels:
    # The Admin Server's NodePort
    #    - channelName: default
    #      nodePort: 30711
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
              path: "/scratch/shared/governancedomainpv"
              server: mynfsserver
            #hostPath:
              #path: "/scratch/k8s_dir"
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
            createIfNotExists: Domain
            # Image containing WDT installer and Model files.
            domainCreationImages:
                - image: 'container-registry.example.com/oig-aux:v1'
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
      value: "-Djava.security.egd=file:/dev/./urandom -Xms4096m -Xmx8192m "

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
      value: "-Xms4096m -Xmx8192m"                                                  
```
{{% /expand %}}
	

**Note**: In circumstances where you may be pulling the OIG product container image from Oracle Container Registry, and then the domain image from a private container registry, you must first create a secret (`privatecred`) for the private registry. For example:
	
```
kubectl create secret docker-registry "privatecred" --docker-server=container-registry.example.com \
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
  image: "container-registry.oracle.com/middleware/oig_cpu:12.2.1.4-jdk8-ol8-<January'24>"

  # imagePullPolicy defaults to "Always" if image version is :latest
  imagePullPolicy: IfNotPresent

  imagePullSecrets:
  - name: orclcred
  - name: privatecred
  # Identify which Secret contains the WebLogic Admin credentials
...
```

#### Deploy the OIG Domain

In this section you deploy the OIG domain using the `domain.yam1'.

1. Run the following command to create OIG domain resources,

   ```bash
   $ kubectl create -f domain.yaml
   ```

   The following steps will be performed by WebLogic Kubernetes Operator

   + Run the introspector job.
   + The introspector job pod will create the domain on PV using the model provided in the domain creation image.
   + The introspector job pod will execute OIG offline configuration actions post successful creation of domain via WDT.
   + Brings up the Administration Server and then the SOA server.

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

   You can also tail the logs for the introspector pod by running:

   ```bash
   $ kubectl logs -f <introspector_pod_name> -n oigns
   ```

   WDT specific logs can be found in `<persistent_volume>/domains/wdt-logs`.

   Once everything is started you should see the Administration Server and SOA server are running:
   
   ```
	NAME                           READY   STATUS    RESTARTS   AGE
	governancedomain-adminserver   1/1     Running   0          8m57s
	governancedomain-soa-server1   1/1     Running   0          4m14s
	helper                         1/1     Running   0          5h9m
   ```
   
	If there are any failures, follow **Domain creation failure with WDT models** in the [Troubleshooting](../../troubleshooting/#domain-creation-failure-with-wdt-models) section.
	
1. Start the OIM server by running the following command:

   ```bash
   kubectl patch cluster -n oigns governancedomain-oim-cluster --type=merge -p '{"spec":{"replicas":1}}'
   ```

   The output will look similar to the following:
   
   ```
   cluster.weblogic.oracle/governancedomain-oim-cluster patched
   ```
	
   You can view the status of the OIM server by running:

   ```bash
   $ kubectl get pods -n oigns -w
   ```
	
   Once the OIM server is running, the output will look similar to the following:
	
	```
	NAME                           READY   STATUS    RESTARTS   AGE
	governancedomain-adminserver   1/1     Running   0          23m
	governancedomain-oim-server1   1/1     Running   0          5m31s
	governancedomain-soa-server1   1/1     Running   0          19m
	helper                         1/1     Running   0          5h24m	
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
	pod/helper                         1/1     Running   0          5h26m

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
	  Resource Version:  9694962
	  UID:               faf836b1-fb6c-4d5a-9f3f-2a6d06aa58d0
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
			  Create If Not Exists:  Domain
			  Domain Creation Images:
				 Image:      container-registry.example.com/oig-aux:v1
			  Domain Type:  OIG
			Persistent Volume:
			  Metadata:
				 Name:  governancedomain-domain-pv
			  Spec:
				 Capacity:
					Storage:  10Gi
				 Nfs:
					Path:                            <NFS_PATH>/governancedomainpv
					Server:                          <IPADDRESS>
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
	  Image:                           container-registry.oracle.com/middleware/oig_cpu:12.2.1.4-jdk8-ol8-<January'24>
	  Image Pull Policy:               IfNotPresent
	  Image Pull Secrets:
		 Name:                             orclcred
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
		 Init Containers:
			Command:
			  /bin/bash
			  -c
			  mkdir -p /u01/oracle/user_projects/domains/ConnectorDefaultDirectory
			  mkdir -p  /u01/oracle/user_projects/domains/wdt-logs
			Image:              container-registry.oracle.com/middleware/oig_cpu:12.2.1.4-jdk8-ol8-<January'24>
			Image Pull Policy:  IfNotPresent
			Name:               compat-connector-init
			Volume Mounts:
			  Mount Path:  /u01/oracle/user_projects/
			  Name:        weblogic-domain-storage-volume
		 Volume Mounts:
			Mount Path:  /u01/oracle/user_projects/
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
			Last Transition Time:  2<DATE>
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
		 Node Name:     worker-node2
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
		 Node Name:     worker-node1
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
		 Node Name:     worker-node1
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
	Events:
	  Type    Reason     Age                From               Message
	  ----    ------     ----               ----               -------
	  Normal  Available  58m (x2 over 74m)  weblogic.operator  Domain governancedomain is available: a sufficient number of its servers have reached the ready state.
	  Normal  Completed  58m (x2 over 74m)  weblogic.operator  Domain governancedomain is complete because all of the following are true: there is no failure detected, there are no pending server shutdowns, and all servers expected to be running are ready and at their target image, auxiliary images, restart version, and introspect version.

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
   helper                                                      1/1     Running     0          5h26m   10.244.1.39   worker-node2   <none>           <none>
   ```

   You are now ready to configure an Ingress to direct traffic for your OIG domain as per [Configure an ingress for an OIG domain](../../configure-ingress).
