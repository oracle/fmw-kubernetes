+++
title=  "Prepare your environment"
date =  2021-02-14T16:43:45-05:00
weight = 2
pre = "<b>  </b>"
description = "Prepare for creating Oracle WebCenter Content domain, including required secrets creation, persistent volume and volume claim creation, database creation, and database schema creation."
+++

To prepare your Oracle WebCenter Content in Kubernetes environment, complete the following steps:

1. [Set up your Kubernetes cluster](#set-up-your-kubernetes-cluster)
1. [Install Helm](#install-helm)
1. [Pull dependent images](#pull-dependent-images)
1. [Set up the code repository to deploy Oracle WebCenter Content domain](#set-up-the-code-repository-to-deploy-oracle-webcenter-content-domain)
1. [Obtain the Oracle WebCenter Content Docker image](#obtain-the-oracle-webcenter-content-docker-image)
1. [Install the WebLogic Kubernetes operator](#install-the-weblogic-kubernetes-operator)
1. [Prepare the environment for Oracle WebCenter Content domain](#prepare-the-environment-for-oracle-webcenter-content-domain)

    a. [Create a namespace for the Oracle WebCenter Content domain](#create-a-namespace-for-the-oracle-webcenter-content-domain)

    b. [Create a persistent storage for the Oracle WebCenter Content domain](#create-a-persistent-storage-for-the-oracle-webcenter-content-domain)

    c. [Create a Kubernetes secret with domain credentials](#create-a-kubernetes-secret-with-domain-credentials)

    d. [Create a Kubernetes secret with the RCU credentials](#create-a-kubernetes-secret-with-the-rcu-credentials)

    e. [Configure access to your database](#configure-access-to-your-database)

    f. [Run the Repository Creation Utility to set up your database schemas](#run-the-repository-creation-utility-to-set-up-your-database-schemas)
1. [Create Oracle WebCenter Content domain](#create-oracle-webcenter-content-domain)


### Set up your Kubernetes cluster

If you need help setting up a Kubernetes environment, check the [cheat sheet](https://oracle.github.io/weblogic-kubernetes-operator/userguide/overview/k8s-setup/).

### Install Helm

The operator uses Helm to create and deploy the necessary resources and then run the operator in a Kubernetes cluster. For Helm installation and usage information, see [here](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-operators/#install-helm).

### Pull dependent images

Obtain dependent images and add them to your local registry.
Dependent images include WebLogic Kubernetes Operator, Traefik. Pull these images and add them to your local registry:

1. Pull these docker images and re-tag them as shown:

To pull an image from the Oracle Container Registry, in a web browser, navigate to ```https://container-registry.oracle.com``` and log in using the Oracle Single Sign-On authentication service. If you do not already have SSO credentials, at the top of the page, click the Sign In link to create them.

Use the web interface to accept the Oracle Standard Terms and Restrictions for the Oracle software images that you intend to deploy. Your acceptance of these terms are stored in a database that links the software images to your Oracle Single Sign-On login credentials.

Then, pull these docker images and re-tag them:

```
docker login https://container-registry.oracle.com (enter your Oracle email Id and password)
This step is required once at every node to get access to the Oracle Container Registry.
```

WebLogic Kubernetes Operator image:
```bash
$ docker pull container-registry.oracle.com/middleware/weblogic-kubernetes-operator:3.1.1
$ docker tag container-registry.oracle.com/middleware/weblogic-kubernetes-operator:3.1.1 oracle/weblogic-kubernetes-operator:3.1.1
```

Pull Traefik Image
```bash
$ docker pull traefik:2.2.8
```

### Set up the code repository to deploy Oracle WebCenter Content domain

Oracle WebCenter Content domain deployment on Kubernetes leverages the WebLogic Kubernetes operator infrastructure. To deploy an Oracle WebCenter Content domain, you must set up the deployment scripts.

1. Create a working directory to set up the source code:
   ```bash
   $ export WORKDIR=$HOME/wcc_3.1.1
   $ mkdir ${WORKDIR}
   ```

1. Download the supported version of the WebLogic Kubernetes operator source code from the operator github  project. Currently the supported operator version is [3.1.1](https://github.com/oracle/weblogic-kubernetes-operator/releases/tag/v3.1.1):

    ``` bash
    $ git clone https://github.com/oracle/weblogic-kubernetes-operator.git --branch release/3.1.1
    ```
1. Download the Oracle WebCenter Content Kubernetes deployment scripts from the WCC [repository](https://github.com/oracle/fmw-kubernetes.git) and copy them to the WebLogic Kubernetes operator samples location:

    ``` bash
    $ git clone https://github.com/oracle/fmw-kubernetes.git --branch release/21.2.3
    
    $ cp -rf ${WORKDIR}/fmw-kubernetes/OracleWebCenterContent/kubernetes/create-wcc-domain ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/	  
	
    $ cp -rf ${WORKDIR}/fmw-kubernetes/OracleWebCenterContent/kubernetes/ingress-per-domain  ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/
	
	$ cp -rf ${WORKDIR}/fmw-kubernetes/OracleWebCenterContent/kubernetes/charts  ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/
    
    $ cp -rf ${WORKDIR}/fmw-kubernetes/OracleWebCenterContent/kubernetes/imagetool-scripts  ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/
	```

### Obtain the Oracle WebCenter Content Docker image

The Oracle WebCenter Content image with latest bundle patch and required interim patches can be obtained from My Oracle Support (MOS). This is the only image supported for production deployments. Follow the below steps to download the Oracle WebCenter Content image from My Oracle Support.

1. Download patch [32822360](https://support.oracle.com/epmos/faces/ui/patch/PatchDetail.jspx?patchId=32822360) from My Oracle Support (MOS).
1. Unzip the downloaded patch zip file.

   For example:
   ```bash
   $ unzip p32822360_122140_Linux-x86-64.zip
   # sample output
   Archive:  p32822360_122140_Linux-x86-64.zip
   inflating: wccontent-12.2.1.4.0-8-ol7-210507.0906.tar
   inflating: README.html
   ```
1. Load the image archive using the `docker load` command.

   For example:
   ```bash
   $ docker load < wccontent-12.2.1.4.0-8-ol7-210507.0906.tar
   ```
   
   {{%expand "Click here to see sample output" %}}
   ```
   d0df970fe76a: Loading layer [==================================================>]  138.3MB/138.3MB
   3b64a4bdc552: Loading layer [==================================================>]  13.45MB/13.45MB
   ee5141cc5c13: Loading layer [==================================================>]  20.99kB/20.99kB
   51f637dc720f: Loading layer [==================================================>]    334MB/334MB
   ffc8b247ad07: Loading layer [==================================================>]   3.98GB/3.98GB
   cd87862f5c14: Loading layer [==================================================>]  4.608kB/4.608kB
   12661fb5186c: Loading layer [==================================================>]  137.2kB/137.2kB
   f84db83c8dfa: Loading layer [==================================================>]  69.12kB/69.12kB
   Loaded image: oracle/wccontent:12.2.1.4.0-8-ol7-210507.0906
   ```
   {{% /expand %}}

1. Run the `docker inspect` command to verify that the downloaded image is the latest released image. The value of label `com.oracle.weblogic.imagetool.buildid` must match to `29ff0886-a299-4860-9b13-fd6bb80ec354`.

   For example:
   ```bash
   $ docker inspect --format='{{ index .Config.Labels "com.oracle.weblogic.imagetool.buildid" }}'  oracle/wccontent:12.2.1.4.0-8-ol7-210507.0906
   29ff0886-a299-4860-9b13-fd6bb80ec354
   ```

Alternatively, if you want to build and use Oracle WebCenter Content Container image, using WebLogic Image Tool, with any additional bundle patch or interim patches, then follow these [steps]({{< relref "/wccontent-domains/create-or-update-image/#create-or-update-an-oracle-webcenter-content-docker-image-using-the-weblogic-image-tool" >}}) to create the image.

> Note: The default Oracle WebCenter Content image name used for Oracle WebCenter Content domain deployment is `oracle/wccontent:12.2.1.4.0`. The image created must be tagged as `oracle/wccontent:12.2.1.4.0` using the `docker tag` command. If you want to use a different name for the image, make sure to update the new image tag name in the `create-domain-inputs.yaml` file and also in other instances where the `oracle/wccontent:12.2.1.4.0` image name is used.


### Install the WebLogic Kubernetes operator

The WebLogic Kubernetes operator supports the deployment of Oracle WebCenter Content domain in the Kubernetes environment. Follow the steps in [this document](https://github.com/oracle/weblogic-kubernetes-operator/blob/release/3.1.1/docs-source/content/quickstart/install.md) to install the operator.
> Note: Optionally, you can execute these [steps](https://oracle.github.io/weblogic-kubernetes-operator/samples/simple/elastic-stack/operator/) to send the contents of the operator’s logs to Elasticsearch.

In the following example commands to install the WebLogic Kubernetes operator, `opns` is the namespace and `op-sa` is the service account created for the operator:

### Creating namespace and service account for operator
  
  ```
  $ kubectl create namespace opns
  $ kubectl create serviceaccount -n opns  op-sa
  
  ```
### Install operator  
  ```
  $ cd ${WORKDIR}/weblogic-kubernetes-operator
  
  $ helm install weblogic-kubernetes-operator kubernetes/charts/weblogic-operator  --namespace opns  --set image=oracle/weblogic-kubernetes-operator:3.1.1 --set serviceAccount=op-sa --set "domainNamespaces={}" --set "javaLoggingLevel=FINE" --wait
  ```

### Prepare the environment for Oracle WebCenter Content domain

#### Create a namespace for the Oracle WebCenter Content domain

   Create a Kubernetes namespace (for example, `wccns`) for the domain unless you intend to use the default namespace. Use the new namespace in the remaining steps in this section.
For details, see [Prepare to run a domain](https://oracle.github.io/weblogic-kubernetes-operator/quickstart/prepare/).

  ```
   $ kubectl create namespace wccns
   
   $ cd ${WORKDIR}/weblogic-kubernetes-operator
   $ helm upgrade --reuse-values --namespace opns --set "domainNamespaces={wccns}" --wait weblogic-kubernetes-operator kubernetes/charts/weblogic-operator
   
  ```

#### Create a persistent storage for the Oracle WebCenter Content domain

   In the Kubernetes namespace you created, create the PV and PVC for the domain by running the [create-pv-pvc.sh](https://oracle.github.io/weblogic-kubernetes-operator/samples/simple/storage/) script. Follow the instructions for using the script to create a dedicated PV and PVC for the Oracle WebCenter Content domain.

  * Review the configuration parameters for PV creation [here](https://oracle.github.io/weblogic-kubernetes-operator/samples/simple/storage/#configuration-parameters). Based on your requirements, update the values in the `create-pv-pvc-inputs.yaml` file located at `${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-weblogic-domain-pv-pvc/`. Sample configuration parameter values for the Oracle WebCenter Content domain are:
    * `baseName`: domain
    * `domainUID`: wccinfra
    * `namespace`: wccns
    * `weblogicDomainStorageType`: HOST_PATH
    * `weblogicDomainStoragePath`: /net/<your_host_name>/scratch/k8s_dir/wcc

  * Ensure that the path for the `weblogicDomainStoragePath` property exists (if not, please refer subsection 4 of [this](https://oracle.github.io/fmw-kubernetes/wccontent-domains/appendix/quickstart-deployment-guide/#61-prepare-for-an-oracle-webcenter-content-domain) document to create it first) and
    has full access permissions, and that the folder is empty.
  * Run the `create-pv-pvc.sh` script:
    ```bash
    $ cd ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-weblogic-domain-pv-pvc
    $ rm -rf output/
		
	$ ./create-pv-pvc.sh -i create-pv-pvc-inputs.yaml -o output
    
	```
  * The `create-pv-pvc.sh` script will create a subdirectory `pv-pvcs` under the given `/path/to/output-directory` directory and creates two YAML configuration files for PV and PVC. Apply these two YAML files to create the PV and PVC Kubernetes resources using the `kubectl create -f` command:
    ```bash
    $ kubectl create -f output/pv-pvcs/wccinfra-domain-pv.yaml -n wccns
	$ kubectl create -f output/pv-pvcs/wccinfra-domain-pvc.yaml -n wccns
    ```
  * Get the details of PV and PVC: 
    ```bash
    $ kubectl describe pv wccinfra-domain-pv
	
	$ kubectl describe pvc wccinfra-domain-pvc -n wccns
    ```

#### Create a Kubernetes secret with domain credentials

   Create the Kubernetes secrets `username` and `password` of the administrative account in the same Kubernetes namespace as the domain:

  ```
    $ cd ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-weblogic-domain-credentials
    
	$ ./create-weblogic-credentials.sh -u weblogic -p welcome1 -n wccns -d wccinfra -s wccinfra-domain-credentials
  ```

  For more details, see [this document](https://github.com/oracle/weblogic-kubernetes-operator/blob/v3.1.1/kubernetes/samples/scripts/create-weblogic-domain-credentials/README.md).

  You can check the secret with the `kubectl get secret` command.

  For example:

  {{%expand "Click here to see the sample secret description." %}}
  ```
$ kubectl get secret wccinfra-domain-credentials -o yaml -n wccns
apiVersion: v1
data:
  password: d2VsY29tZTE=
  username: d2VibG9naWM=
kind: Secret
metadata:
  creationTimestamp: "2020-09-16T08:22:50Z"
  labels:
    weblogic.domainName: wccinfra
    weblogic.domainUID: wccinfra
  managedFields:
  - apiVersion: v1
    fieldsType: FieldsV1
    fieldsV1:
      f:data:
        .: {}
        f:password: {}
        f:username: {}
      f:metadata:
        f:labels:
          .: {}
          f:weblogic.domainName: {}
          f:weblogic.domainUID: {}
      f:type: {}
    manager: kubectl
    operation: Update
    time: "2020-09-16T08:22:50Z"
  name: wccinfra-domain-credentials
  namespace: wccns
  resourceVersion: "3277100"
  selfLink: /api/v1/namespaces/wccns/secrets/wccinfra-domain-credentials
  uid: 35a8313f-1ec2-44b0-a2bf-fee381eed57f
type: Opaque

  ```
  {{% /expand %}}

#### Create a Kubernetes secret with the RCU credentials

   You also need to create a Kubernetes secret containing the credentials for the database schemas.
When you create your domain, it will obtain the RCU credentials
from this secret.

Use the provided sample script to create the secret:

```bash
$ cd ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-rcu-credentials

$ ./create-rcu-credentials.sh -u weblogic -p welcome1 -a sys -q welcome1 -d wccinfra -n wccns -s wccinfra-rcu-credentials 

```

The parameter values are:

  `-u` username for schema owner (regular user), required.  
  `-p` password for schema owner (regular user), required.  
  `-a` username for SYSDBA user, required.  
  `-q` password for SYSDBA user, required.  
  `-d` domainUID. Example: `wccinfra`  
  `-n` namespace. Example: `wccns`  
  `-s` secretName. Example: `wccinfra-rcu-credentials`  

You can confirm the secret was created as expected with the `kubectl get secret` command.

For example:

{{%expand "Click here to see the sample secret description." %}}
``` bash
$ kubectl get secret wccinfra-rcu-credentials -o yaml -n wccns
  apiVersion: v1
data:
  password: d2VsY29tZTE=
  sys_password: d2VsY29tZTE=
  sys_username: c3lz
  username: d2VibG9naWM=
kind: Secret
metadata:
  creationTimestamp: "2020-09-16T08:23:04Z"
  labels:
    weblogic.domainName: wccinfra
    weblogic.domainUID: wccinfra
  managedFields:
  - apiVersion: v1
    fieldsType: FieldsV1
    fieldsV1:
      f:data:
        .: {}
        f:password: {}
        f:sys_password: {}
        f:sys_username: {}
        f:username: {}
      f:metadata:
        f:labels:
          .: {}
          f:weblogic.domainName: {}
          f:weblogic.domainUID: {}
      f:type: {}
    manager: kubectl
    operation: Update
    time: "2020-09-16T08:23:04Z"
  name: wccinfra-rcu-credentials
  namespace: wccns
  resourceVersion: "3277132"
  selfLink: /api/v1/namespaces/wccns/secrets/wccinfra-rcu-credentials
  uid: b75f4e13-84e6-40f5-84ba-0213d85bdf30
type: Opaque

```
{{% /expand %}}

#### Configure access to your database
Run a container to create `rcu pod`

```bash
   kubectl run rcu --generator=run-pod/v1 --image oracle/wccontent:12.2.1.4 -n wccns  -- sleep infinity
   
   #check the status of rcu pod
   kubectl get pods -n wccns
```

#### Run the Repository Creation Utility to set up your database schemas

##### Create OR Drop schemas

To create the database schemas for Oracle WebCenter Content, run the `create-rcu-schema.sh` script.

For example:

```bash
   # make sure rcu pod status is running before executing this 
   kubectl exec -n wccns -ti rcu /bin/bash
   
   # DB details 
   export CONNECTION_STRING=your_db_host:1521/your_db_service
   export RCUPREFIX=your_schema_prefix
   echo -e welcome1"\n"welcome1> /tmp/pwd.txt
   
   # Create schemas
   /u01/oracle/oracle_common/bin/rcu -silent -createRepository -databaseType ORACLE -connectString $CONNECTION_STRING -dbUser sys -dbRole sysdba -useSamePasswordForAllSchemaUsers true -selectDependentsForComponents true -schemaPrefix $RCUPREFIX -component CONTENT -component MDS   -component STB -component OPSS  -component IAU -component IAU_APPEND -component IAU_VIEWER -component WLS  -tablespace USERS -tempTablespace TEMP -f < /tmp/pwd.txt
   
   # Drop schemas
   /u01/oracle/oracle_common/bin/rcu -silent -dropRepository -databaseType ORACLE -connectString $CONNECTION_STRING -dbUser sys -dbRole sysdba -selectDependentsForComponents true -schemaPrefix $RCUPREFIX -component CONTENT -component MDS  -component STB -component OPSS  -component IAU -component IAU_APPEND -component IAU_VIEWER -component WLS -f < /tmp/pwd.txt 
   
   #exit from the container
   exit
   
```

### Create Oracle WebCenter Content domain

Now that you have your Docker images and you have created your RCU schemas, you are ready to create your domain. To continue, follow the instructions in [Create Oracle WebCenter Content domains]({{< relref "/wccontent-domains/installguide/create-wccontent-domains" >}}).
