+++
title = "b. Create OAM domains using WDT models"
+++

1. [Introduction](#introduction)
1. [Prerequisites](#prerequisites)
1. [Working with WDT Model Files](#working-with-wdt-model-files)
1. [Preparing the environment for domain creation](#preparing-the-environment-for-domain-creation)
1. [Create Domain Creation Image](#create-domain-creation-image)
1. [Customize sample WDT models (Optional)](#customize-sample-wdt-models-optional)
1. [Create the OAM domain](#create-the-oam-domain)
1. [Verify the results](#verify-the-results)
    
	a. [Verify the domain, pods and services](#verify-the-domain-pods-and-services)
	
	b. [Verify the domain](#verify-the-domain)
	
	c. [Verify the pods](#verify-the-pods)
	
	
### Introduction

This section demonstrates the creation of an OAM domain home using sample Weblogic Deploy Tooling (WDT) model files.

Beginning with WebLogic Kubernetes Operator version 4.1.2, you can provide a section, `domain.spec.configuration.initializeDomainOnPV`, to initialize an OAM domain on a persistent volume when it is first deployed. This eliminates the need to pre-create your OAM domain using sample Weblogic Scripting Tool (WLST) offline scripts.

**Note**: This is a one time only initialization. After the domain is created, subsequent updates to this section in the domain resource YAML file will not recreate or update the WebLogic domain. Subsequent domain lifecycle updates must be controlled by the WebLogic Server Administration Console, Enterprise Manager Console, WebLogic Scripting Tool (WLST), or other mechanisms.

Weblogic Deploy Tooling (WDT) models are a convenient and simple alternative to WebLogic Scripting Tool (WLST) configuration scripts. They compactly define a WebLogic domain using model files, variable properties files, and application archive files. For more information about the model format and its integration, see [Usage](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/usage/) and [Working with WDT Model files](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/model-files/). The WDT model format is fully described in the open source, [WebLogic Deploy Tooling GitHub project](https://oracle.github.io/weblogic-deploy-tooling/).

The main benefits of WDT are:

   * A set of single-purpose tools supporting Weblogic domain configuration lifecycle operations.
   * All tools work off of a shared, declarative model, eliminating the need to maintain specialized WLST scripts.
   * WDT knowledge base understands the MBeans, attributes, and WLST capabilities/bugs across WLS versions.

The initializeDomainOnPv section:

1. Creates the PersistentVolume (PV) and/or PersistenVolumeClaim (PVC).
1. Creates the OAM domain home on the persistent volume based on the provided WDT models

### Prerequisites

Before you begin, perform the following steps:

1. Review the [Domain On PV](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/) documentation.
1. Ensure that the database is up and running.


### Working with WDT Model Files

The code repository (`$WORKDIR`) contains different WDT model files to create an OAM domain. The following table defines these files:

More information on the WDT Metadata model see, [Metadata model](https://oracle.github.io/weblogic-deploy-tooling/concepts/model/).

| Model File | Definition | Required for base domain creation image |
| --- | --- | --- |
| domainInfo.yaml | The location where special information not represented in WLST is specified (for example, OPSS Initialization parameters). In most of the cases, you do not need to customize this. | Y |
| topology.yaml |  The location where servers, clusters and other domain-level configuration is specified. You can customize this based on the topology that you need. | Y |
| resources.yaml | The location where resources and services are specified (for example, data sources, JMS, WLDF). You can customize this based on your environment specific requirement. For example, if you want to use different datasource connection pool parameters from the ones coming via template, you can add details here. | Y |
| oam.properties | The location where you can customize the default values for different parameters  such as Listen Port, T3 Channel port etc. | Y |
| agl_jdbc.yaml | This is an optional model file specifying parameters needed to use Active Gridlink type of datasources for your domain | N (Optional) |

### Preparing the environment for domain creation

In this section you prepare the environment for the OAM domain creation using WDT models. This involves the following steps:

1. Creating Kubernetes secrets for the domain and RCU.
1. Creating a persistent volume.


#### Creating Kubernetes secrets for the domain and RCU

1. Create a Kubernetes secret for the domain using the create-weblogic-credentials script in the same Kubernetes namespace as the domain:

   ```bash
   $ cd $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils
   $ ./create-secret.sh -l "username=weblogic" -l "password=<password>" -n <domain_namespace> -d <domain_uid> -s <kubernetes_domain_secret>
   ```

   where:

   `-n <domain_namespace>` is the domain namespace.

   `-d <domain_uid>` is the domain UID to be created. The default is domain1 if not specified.

   `-s <kubernetes_domain_secret>` is the name you want to create for the secret for this namespace.

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

1. Create a Kubernetes secret for RCU in the same Kubernetes namespace as the domain, using the `create-secrets.sh` script:


   ```bash
   $ cd $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-utils
   $ ./create-secret.sh -l "rcu_prefix=<rcu_prefix>" -l "rcu_schema_password=<rcu_schema_pwd>" -l "db_host=<db_host.domain>" -l "db_port=1521" -l "db_service=<service_name>" -l "dba_user=<sys_db_user>" -l "dba_password=<sys_db_pwd>" -n <domain_namespace> -d <domain_uid> -s <kubernetes_rcu_secret>
   ```
   
   where

   `<rcu_prefix>` is the name of the RCU schema prefix created previously.

   `<rcu_schema_pwd>` is the password for the RCU schema prefix.
   
   `<db_host.domain>` is the hostname.domain of the database.

   `<sys_db_user>` is the database user with sys dba privilege.

   `<sys_db_pwd>` is the sys database password.

   `<domain_uid>` is the domain_uid that you created earlier.

   `<domain_namespace>` is the domain namespace.

   `<kubernetes_rcu_secret>` is the name of the rcu secret to create.

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

#### Create Persistent Volume

As referenced in [Prerequisites](../../prerequisites) the nodes in the Kubernetes cluster must have access to a persistent volume such as a Network File System (NFS) mount or a shared file system.

Domain on persistent volume (Domain on PV) is an operator [domain home source type](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/choosing-a-model/), which requires that the domain home exists on a persistent volume.

When a container is started, it needs to mount that volume. The physical volume should be on a shared disk accessible by all the Kubernetes worker nodes because it is not known on which worker node the container will be started. In the case of Identity and Access Management, the persistent volume does not get erased when a container stops. This enables persistent configurations.

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

### Create Domain Creation Image

Domain creation images are used for supplying WebLogic Deploy Tooling (WDT) model files, WDT variables files, WDT application archive files (collectively known as WDT model files), and the directory where the WebLogic Deploy Tooling software is installed (known as the WDT Home) when deploying a domain using a Domain on PV model. You distribute WDT model files and the WDT executable using these images, then the WebLogic Kubernetes Operator uses them to manage the domain.

**Note**: These images are only used for creating the domain and will not be used to update the domain.

**Note**: The domain creation image is used for domain creation only, it is not the product container image used for OAM.

For more details on creating the domain image, see [Domain creation images](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/domain-creation-images/).

The steps to create the domain creation image are shown in the sections below.

#### Set up the WebLogic Image Tool

* [Prerequisites](#image-tool-prerequisites)
* [Prepare the WebLogic Image Tool](#prepare-the-weblogic-image-tool)
* [Validate Setup](#validate-setup)
* [WebLogic Image Tool Build Directory](#weblogic-image-tool-build-directory)
* [WebLogic Image Tool Cache](#weblogic-image-tool-cache)


##### Image tool prerequisites

Verify that your environment meets the following prerequisites:

* A container image client on the build machine, such as Docker or Podman.
  * For Docker, a minimum version of 18.03.1.ce is required.
  * For Podman, a minimum version of 3.0.1 is required.
* Bash version 4.0 or later, to enable the <tab> command complete feature.
* An installed version of Java to run Image Tool, version 8+. JAVA_HOME environment variable set to the appropriate JDK location e.g: /scratch/export/oracle/product/jdk

##### Prepare the WebLogic Image Tool

To set up the WebLogic Image Tool:

1. Create a working directory and navigate to it:

   ```bash
   $ mkdir <workdir>/imagetool-setup
   $ cd <workdir>/imagetool-setup
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

##### Validate Setup

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

Creation of OAM domain using sample WDT files is supported from WDT version 3.2.4 onwards.

Run the following steps to download and configure WDT for OAM deployment:

1. Create a working directory:

   ```bash
   $ mkdir <workdir>/wdt-setup
   $ cd <workdir>/wdt-setup
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

1. Unzip and add the OAM domain type definition in WDT:

   ```bash
   $ unzip weblogic-deploy.zip
   $ cp $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-artifacts/OAM.json weblogic-deploy/lib/typedefs/
   $ zip -r weblogic-deploy.zip weblogic-deploy
   ```

#### Create OAM domain creation image

1. Add the WDT installer in imagetool:

   ```bash
   $ imagetool cache addInstaller --type wdt --version latest --path /scratch/wdt-setup/weblogic-deploy.zip
   ```
  
   The output should look similar to the following:
   
   ```
   [INFO   ] Successfully added to cache. wdt_latest=/scratch/wdt-setup/weblogic-deploy.zip
   ```

1. Create the image:

   ```bash
   $ imagetool createAuxImage --tag oam-aux:v1 \
   --wdtModel $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-artifacts/domainInfo.yaml,\
   $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-artifacts/resource.yaml,\
   $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-artifacts/topology.yaml \
   --wdtVariables $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-artifacts/oam.properties \
   --fromImage ghcr.io/oracle/oraclelinux:7-slim
   ```
   
   **Note**: If using podman add `--builder podman` to the command. Make sure podman is on the $PATH before executing.
   
   The output will look similar to the following:
   
   ```
   [INFO   ] WebLogic Image Tool version 1.12.1
   [INFO   ] Image Tool build ID: aa6348c9-a8e6-4da5-8d4e-b630939617f4
   [INFO   ] User specified fromImage ghcr.io/oracle/oraclelinux:7-slim
   [INFO   ] Temporary directory used for image build context: $WORKDIR/wlsimgbuilder_temp10923643321786345730
   [INFO   ] Inspecting ghcr.io/oracle/oraclelinux:7-slim, this may take a few minutes if the image is not available locally.
   [INFO   ] Copying $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-artifacts/domainInfo.yaml to build context folder.
   [INFO   ] Copying $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-artifacts/resource.yaml to build context folder.
   [INFO   ] Copying $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-artifacts/topology.yaml to build context folder.
   [INFO   ] Copying $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/wdt-artifacts/oam.properties to build context folder.
   [INFO   ] Copying /scratch/wdt-setup/weblogic-deploy.zip to build context folder.
   [INFO   ] Starting build: podman build --no-cache --force-rm --tag oam-aux:v1 --build-arg http_proxy=http://proxy.example.com:80 --build-arg https_proxy=http://proxy.example.com:80 --build-arg no_proxy=localhost,127.0.0.1,example.com,/var/run/docker.sock,/var/run/crio/crio.sock,/var/run/containerd/containerd.sock /scratch/wlsimgbuilder_temp10923643321786345730
   [1/3] STEP 1/5: FROM ghcr.io/oracle/oraclelinux:7-slim AS os_update
   [1/3] STEP 2/5: LABEL com.oracle.weblogic.imagetool.buildid="aa6348c9-a8e6-4da5-8d4e-b630939617f4"
   ...
   etc
   ...
   [3/3] STEP 12/12: WORKDIR /auxiliary
   [3/3] COMMIT oam-aux:v1
   --> f71537aed4c
   Successfully tagged localhost/oam-aux:v1
   f71537aed4c1c0abc6589b5411f36fc46a1634d2b7f8a0627bce89c90d6a3bfe
   [INFO   ] Build successful. Build time=42s. Image tag=oam-aux:v1
   ```

1. Tag and push the image to your local container registry:

   **Note**: If you are not using your own container registry for storing images, then you must export the image as a tar file, and then load it on every worker node.

   ```bash
   $ docker tag oam-aux:v1 container-registry.example.com/oam-aux:v1
   $ docker push container-registry.example.com/oam-aux:v1
   ```
   
   Or if using podman:
   
   ```bash
   $ podman tag oam-aux:v1 container-registry.example.com/oam-aux:v1
   $ podman push container-registry.example.com/oam-aux:v1
   ```

####  Customize sample WDT models (Optional)

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
   $ cd $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/
   $ wdt-utils/create-configmap.sh -n oamns -d accessdomain -c agl-cm -f wdt-artifacts/agl_jdbc.yaml 
   ```
   
   The output will look similar to the following:
   
   ```
   kubectl -n oamns delete configmap agl-cm --ignore-not-found
   kubectl -n oamns create configmap agl-cm --from-file=wdt-artifacts/agl_jdbc.yaml
   configmap/agl-cm created
   kubectl -n oamns label configmap agl-cm weblogic.domainUID=accessdomain
   configmap/agl-cm labeled
   ```

1. Modify the existing `domain.yaml` to use that configmap

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
                   - image: 'oracle/oamaux:final'
               domainCreationConfigMap: agl-cm
               domainType: OAM
   ```

### Create the OAM domain

In this section you create the OAM domain. 

### Modify the OAM domain.yaml

In this section you modify the `domain.yaml` file in preparation for creating the OAM domain.

1. Navigate to the `$WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/domain-resources` directory and take a backup of the domain.yaml:

   ```bash
   cd $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/domain-resources
   cp domain.yaml domain.yaml.orig
   ```

1. Edit the `domain.yaml` and modify the following parameters where applicable.

   A full list of parameters in the `domain.yaml` file are shown below:

   **Domain definition**: 

   | Parameter | definition | default |
   | --- | --- | --- |
   | `metadata.name` | The domain name <`domainUID`>. | `accessdomain` |
   | `namespace` |  Kubernetes namespace in which to create the domain,cluster,pv. | `oamns` |
   | `domainUID` | Unique ID that will be used to identify this particular domain. Used as the name of the generated WebLogic domain as well as the name of the Kubernetes domain resource. This ID must be unique across all domains in a Kubernetes cluster. This ID cannot contain any character that is not valid in a Kubernetes service name. | `accessdomain` |
   |`spec.domainHome` | Home directory of the OAM domain, `/u01/oracle/user_projects/domains/<domainUID>`. | `/u01/oracle/user_projects/domains/accessdomain` |
   | `image` | OAM container image. The WebLogic Kubernetes Operator requires OAM 12.2.1.4. Refer to [Obtain the OAM container image](../prepare-your-environment#obtain-the-oam-container-image) for details on how to obtain or create the image. Note: Creating domains with WDT is supported from October 23 BP image onwards. | `oracle/oam:12.2.1.4.0` |
   | `imagePullSecrets` | Name of the Kubernetes secret to access the container registry to pull the OAM product container image and domain creation image. The presence of the secret will be validated when this parameter is specified. | `orclcred` | 
   | `webLogicCredentialsSecret` | Name of the Kubernetes secret for the Administration Server’s user name and password. If not specified, then the value is derived from the domainUID as `<domainUID>-weblogic-credentials`. | `accessdomain-weblogic-credentials` |
   | `logHome` | The in-pod location for the domain log, server logs, server out, and Node Manager log files.  | `/u01/oracle/user_projects/domains/logs/accessdomain` |
   | `initContainers.image` | OAM container image. The operator requires OAM 12.2.1.4. Refer to [Obtain the OAM container image](../prepare-your-environment#obtain-the-oam-container-image) for details on how to obtain or create the image. Note: Creating domains with WDT is supported from October 23 BP image onwards. | `oracle/oam:12.2.1.4.0` |
   | `persistentVolumeClaim.claimName` | Name of the persistent volume claim created to host the domain home. | `accessdomain-domain-pvc` |
   | `configuration.secrets` | The Kubernetes secret containing the database credentials. |`accessdomain-rcu-credentials` |
   | `persistentVolume.metadata.name` | Persistent Volume name. | `accessdomain-domain-pv` |
   | `storageClassName` | Storage class name for the PV and PVC. | `accessdomain-domain-storage-class` |
   | `nfs.server` | NFS server IP address used for the PV and PVC. | |
   | `nfs.path` | NFS server Path - physical path of the persistentstorage. |  |
   | `persistentVolumeClaim.metadata.name` | Name of the persistent volume claim created to host the domain home. | `accessdomain-domain-pvc` |
   | `volumeName` | PV name to bind PV with PVC. | `accessdomain-domain-pv` |
   | `domainCreationImages.image` | Domain creation image name, containing WDT Installer and Model files. Can be one or more images specifying models in a layered manner.  Refer to [Multiple Images](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-on-pv/domain-creation-images/#multiple-images) for more details. | |
   | `clusters.name` | List of cluster name for managed oam-server and policy-server - format as `<domainUID>-oam-cluster and <domainUID-policy-cluster>`.| `accessdomain-oam-cluster` and `accessdomain-policy-cluster` |

   **Cluster Definition**:

   | Parameter | definition | default |
   | --- | --- | --- |
   | `metadata.name` | oam and policy cluster name `<domainUID>-oam-cluster` or `<domainUID>-policy-cluster`. | for oam cluster - `accessdomain-oam-cluster` and for policy-cluster `accessdomain-policy-cluster` |
   | `metadata.namespace` | cluster namespace. This should be same as of domain namespace. | `oamns` |

   For more details about these configuration parameters please see [Domain Resources](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-resource/). 
   
   
   {{%expand "Click here to see an example domain.yaml:" %}}
   ```
   # Copyright (c) 2023, Oracle and/or its affiliates.
   # Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
   # This is an example of how to define a Domain resource.
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
     image: "container-registry.oracle.com/middleware/oam_cpu:12.2.1.4-jdk8-ol7-<October`23>"

     # imagePullPolicy defaults to "Always" if image version is :latest
     imagePullPolicy: IfNotPresent

     # Identify which Secret contains the credentials for pulling an image
     imagePullSecrets:
     - name: orclcred
 
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
           image: "container-registry.oracle.com/middleware/oam_cpu:12.2.1.4-jdk8-ol7-<October`23>"
         #OAM Product image, same as spec.image mentioned above
           imagePullPolicy: IfNotPresent
           command: [ "/bin/bash", "-c", "mkdir -p  /u01/oracle/user_projects/domains/wdt-logs"]
           volumeMounts:
             - mountPath: /u01/oracle/user_projects/
               name: weblogic-domain-storage-volume

       # a list of environment variable to be set on the servers
       env:
       - name: JAVA_OPTIONS
         value: "-Dweblogic.StdoutDebugEnabled=false"
       - name: WLSDEPLOY_LOG_DIRECTORY
         value: "/u01/oracle/user_projects/domains/wdt-logs"
       - name: USER_MEM_ARGS
         value: "-Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx1024m "
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
              # The valid values are: 'Retain', 'Delete', and 'Recycle'
               persistentVolumeReclaimPolicy: Retain
              # Persistent volume type for the persistent storage.
              # The value must be 'hostPath' or 'nfs'.
              # If using 'nfs', server must be specified.
               nfs:
                 server: <IPADDRESS>
                 path: "/<NFS_PATH>/accessdomainpv"
               #hostPath:
                 #path: "/scratch/k8s_dir"
           persistentVolumeClaim:
             metadata:
               name: accessdomain-domain-pvc
               namespace: oamns
             spec:
               storageClassName: accessdomain-domain-storage-class
               resources:
                 requests:
                   storage: 10Gi
               volumeName: accessdomain-domain-pv
           domain:
               # Domain | DomainAndRCU
               createIfNotExists: Domain
               domainCreationImages:
                   - image: 'container-registry.example.com/oam-aux:v1'
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
     serverPod:
       env:
       - name: USER_MEM_ARGS
         value: "-XX:+UseContainerSupport -Djava.security.egd=file:/dev/./urandom -Xms8192m -Xmx8192m"
     replicas: 1

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
	
	
   **Note**: In circumstances where you may be pulling the OAM product container image from Oracle Container Registry, and then the domain image from a private registry, you must first create a secret (`privatecred`) for the private registry. For example:
	
	```
	kubectl create secret docker-registry "privatecred" --docker-server=container-registry.example.com \
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
	  image: "container-registry.oracle.com/middleware/oam_cpu:12.2.1.4-jdk8-ol7-<October'23>"

	  # imagePullPolicy defaults to "Always" if image version is :latest
	  imagePullPolicy: IfNotPresent

	  imagePullSecrets:
	  - name: orclcred
	  - name: privatecred
	  # Identify which Secret contains the WebLogic Admin credentials
	...
	```

#### Deploy the OAM domain

In this section you deploy the OAM domain using the `domain.yam1'.

1. Run the following command to create OAM domain resources,

   ```bash
	$ cd $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/domain-resources
   $ kubectl create -f domain.yaml
   ```

   The following steps will be performed by WebLogic Kubernetes Operator:
   
   + Run the introspector job.
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
   accessdomain-oam-policy-mgr1   1/1     Running   1 (3m50s ago)   3m53s
   accessdomain-oam-server1       1/1     Running   0               3m53s
   helper                         1/1     Running   0               21h
   ```


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
   pod/accessdomain-oam-policy-mgr1   1/1     Running   1 (4m16s ago)   4m19s
   pod/accessdomain-oam-server1       1/1     Running   0               4m19s
   pod/helper                         1/1     Running   0               21h

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
			  Image:      container-registry.example.com/oam-aux:v1
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
	  Image:                           container-registry.oracle.com/middleware/oam_cpu:12.2.1.4-jdk8-ol7-<October`23>
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
		  Image:              container-registry.oracle.com/middleware/oam_cpu:12.2.1.4-jdk8-ol7-<October`23>
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
	helper                         1/1     Running   0             21h   10.244.1.20   worker-node1   <none>           <none>
   ```


You are now ready to configure an Ingress to direct traffic for your OAM domain as per [Configure an ingress For an OAM Domain](../configure-ingress).
