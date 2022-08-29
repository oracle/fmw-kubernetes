+++
title=  "Prepare your environment"
date = 2019-04-18T06:46:23-05:00
weight = 2
pre = "<b>  </b>"
description = "Prepare for creating Oracle SOA Suite domains, including required secrets creation, persistent volume and volume claim creation, database creation, and database schema creation."
+++

To prepare your Oracle SOA Suite in Kubernetes environment, complete the following steps.  

{{% notice note %}}
Refer to the [troubleshooting]({{< relref "/soa-domains/troubleshooting/" >}}) page to troubleshoot issues during the domain deployment process.
{{% /notice %}}

1. [Set up your Kubernetes cluster](#set-up-your-kubernetes-cluster)
1. [Install Helm](#install-helm)
1. [Get dependent images](#get-dependent-images)
1. [Set up the code repository to deploy Oracle SOA Suite domains](#set-up-the-code-repository-to-deploy-oracle-soa-suite-domains)
1. [Obtain the Oracle SOA Suite Docker image](#obtain-the-oracle-soa-suite-docker-image)
1. [Install the WebLogic Kubernetes Operator](#install-the-weblogic-kubernetes-operator)
1. [Prepare the environment for Oracle SOA Suite domains](#prepare-the-environment-for-oracle-soa-suite-domains)

    a. [Create a namespace for an Oracle SOA Suite domain](#create-a-namespace-for-an-oracle-soa-suite-domain)

    b. [Create a persistent storage for an Oracle SOA Suite domain](#create-a-persistent-storage-for-an-oracle-soa-suite-domain)

    c. [Create a Kubernetes secret with domain credentials](#create-a-kubernetes-secret-with-domain-credentials)

    d. [Create a Kubernetes secret with the RCU credentials](#create-a-kubernetes-secret-with-the-rcu-credentials)

    e. [Configure access to your database](#configure-access-to-your-database)

    f. [Run the Repository Creation Utility to set up your database schemas](#run-the-repository-creation-utility-to-set-up-your-database-schemas)
1. [Create an Oracle SOA Suite domain](#create-an-oracle-soa-suite-domain)


### Set up your Kubernetes cluster

Refer the official Kubernetes set up [documentation](https://kubernetes.io/docs/setup/#production-environment) to set up a production grade Kubernetes cluster.


### Install Helm

The operator uses Helm to create and deploy the necessary resources and then run the operator in a Kubernetes cluster. For Helm installation and usage information, see [here](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-operators/#install-helm).

### Get dependent images

Obtain dependent images and add them to your local registry.

1. For first time users, to pull an image from the Oracle Container Registry, navigate to https://container-registry.oracle.com and log in using the Oracle Single Sign-On (SSO) authentication service. If you do not already have an SSO account, you can create an Oracle Account [here](https://profile.oracle.com/myprofile/account/create-account.jspx).

   Use the web interface to accept the Oracle Standard Terms and Restrictions for the Oracle software images that you intend to deploy. Your acceptance of these terms are stored in a database that links the software images to your Oracle Single Sign-On login credentials.

   Log in to the Oracle Container Registry (`container-registry.oracle.com`) from your Docker client:

    ```shell
    $ docker login container-registry.oracle.com
    ```

1. Pull the operator image:

    ```bash
    $ docker pull ghcr.io/oracle/weblogic-kubernetes-operator:3.4.2
    $ docker tag ghcr.io/oracle/weblogic-kubernetes-operator:3.4.2  oracle/weblogic-kubernetes-operator:3.4.2
    ```

### Set up the code repository to deploy Oracle SOA Suite domains

Oracle SOA Suite domain deployment on Kubernetes leverages the WebLogic Kubernetes Operator infrastructure. To deploy an Oracle SOA Suite domain, you must set up the deployment scripts.

1. Create a working directory to set up the source code:
    ```bash
    $ mkdir $HOME/soa_22.3.2
    $ cd $HOME/soa_22.3.2
    ```
1. Download the WebLogic Kubernetes Operator source code and  Oracle SOA Suite Kubernetes deployment scripts from the SOA [repository](https://github.com/oracle/fmw-kubernetes.git). Required artifacts are available at `OracleSOASuite/kubernetes`.

    ``` bash
    $ git clone https://github.com/oracle/fmw-kubernetes.git
    $ export WORKDIR=$HOME/soa_22.3.2/fmw-kubernetes/OracleSOASuite/kubernetes
    ```

### Obtain the Oracle SOA Suite Docker image

The Oracle SOA Suite image with the latest bundle patch and required interim patches is prebuilt by Oracle and includes Oracle SOA Suite 12.2.1.4.0, the July Patch Set Update (PSU), and other fixes released with the Critical Patch Update (CPU) program. This is the only image supported for production deployments. Obtain the Oracle SOA Suite image using either of the following methods:

1. Download from Oracle Container Registry: 
    
    - Log in to `Oracle Container Registry`, navigate to **Middleware** > **soasuite_cpu** and accept the license agreement if not already done.

    - Log in to the Oracle Container Registry (container-registry.oracle.com) from your Docker client:

        ```bash
        $ docker login container-registry.oracle.com
        ```

    - Pull the image:

        For example:

        ```bash
        $ docker pull container-registry.oracle.com/middleware/soasuite_cpu:12.2.1.4-jdk8-ol7-220726
        ```

1. Download from My Oracle Support:
    - Download patch [34410491](https://support.oracle.com/epmos/faces/ui/patch/PatchDetail.jspx?patchId=34410491) from My Oracle Support (MOS).
    - Unzip the downloaded patch zip file.
    - Load the image archive using the `docker load` command.

        For example:
        ```bash
        $ docker load < soasuite-12.2.1.4-jdk8-ol7-220726.1801.tar
        Loaded image: oracle/soasuite:12.2.1.4-jdk8-ol7-220726.1801
        $
        ```
    - Run the `docker inspect` command to verify that the downloaded image is the latest released image. The value of label `com.oracle.weblogic.imagetool.buildid` must match to `c35d47e7-10a6-4fe6-908d-2d50aa23ed75`.

        For example:
        ```bash
        $ docker inspect --format='{{ index .Config.Labels "com.oracle.weblogic.imagetool.buildid" }}' oracle/soasuite:12.2.1.4-jdk8-ol7-220726.1801
            c35d47e7-10a6-4fe6-908d-2d50aa23ed75
        $
        ```

If you want to build and use an Oracle SOA Suite Docker image with any additional bundle patch or interim patches that are not part of the image obtained from My Oracle Support, then follow these [steps]({{< relref "/soa-domains/create-or-update-image/#create-or-update-an-oracle-soa-suite-docker-image-using-the-weblogic-image-tool" >}}) to create the image.

> Note: The default Oracle SOA Suite image name used for Oracle SOA Suite domains deployment is `soasuite:12.2.1.4`. The image obtained must be tagged as `soasuite:12.2.1.4` using the `docker tag` command. If you want to use a different name for the image, make sure to update the new image tag name in the `create-domain-inputs.yaml` file and also in other instances where the `soasuite:12.2.1.4` image name is used.


### Install the WebLogic Kubernetes Operator

The WebLogic Kubernetes Operator supports the deployment of Oracle SOA Suite domains in the Kubernetes environment. Follow the steps in [this document](https://github.com/oracle/weblogic-kubernetes-operator/blob/v3.4.2/documentation/3.4/content/quickstart/install.md#install-the-operator) to install the operator.
> Note: Optionally, you can execute these [steps](https://oracle.github.io/weblogic-kubernetes-operator/samples/elastic-stack/operator/) to send the contents of the operator's logs to Elasticsearch.

In the following example commands to install the WebLogic Kubernetes Operator, `opns` is the namespace and `op-sa` is the service account created for the operator:
  ```
  $ kubectl create namespace opns
  $ kubectl create serviceaccount -n opns  op-sa
  $ cd ${WORKDIR}
  $ helm install weblogic-kubernetes-operator charts/weblogic-operator  --namespace opns  --set image=oracle/weblogic-kubernetes-operator:3.4.2 --set serviceAccount=op-sa --set "domainNamespaces={}" --set "javaLoggingLevel=FINE" --wait
  ```

### Prepare the environment for Oracle SOA Suite domains

#### Create a namespace for an Oracle SOA Suite domain

   Create a Kubernetes namespace (for example, `soans`) for the domain unless you intend to use the default namespace. Use the new namespace in the remaining steps in this section.
For details, see [Prepare to run a domain](https://oracle.github.io/weblogic-kubernetes-operator/quickstart/prepare/).

  ```
  $ kubectl create namespace soans
  $ helm upgrade --reuse-values --namespace opns --set "domainNamespaces={soans}" --wait weblogic-kubernetes-operator charts/weblogic-operator         
  ```

#### Create a persistent storage for an Oracle SOA Suite domain

   In the Kubernetes namespace you created, create the PV and PVC for the domain by running the [create-pv-pvc.sh](https://oracle.github.io/weblogic-kubernetes-operator/samples/storage/) script. Follow the instructions for using the script to create a dedicated PV and PVC for the Oracle SOA Suite domain.

  * Review the configuration parameters for PV creation [here](https://oracle.github.io/weblogic-kubernetes-operator/samples/storage/#configuration-parameters). Based on your requirements, update the values in the `create-pv-pvc-inputs.yaml` file located at `${WORKDIR}/create-weblogic-domain-pv-pvc/`. Sample configuration parameter values for an Oracle SOA Suite domain are:
    * `baseName`: domain
    * `domainUID`: soainfra
    * `namespace`: soans
    * `weblogicDomainStorageType`: HOST_PATH
    * `weblogicDomainStoragePath`: /scratch/k8s_dir/SOA

  * Ensure that the path for the `weblogicDomainStoragePath` property exists and have the ownership for `1000:0`. If not, you need to create it as follows:
    ```
    $ sudo mkdir /scratch/k8s_dir/SOA
    $ sudo chown -R 1000:0 /scratch/k8s_dir/SOA
    ```
  * Run the `create-pv-pvc.sh` script:
    ```bash
    $ cd ${WORKDIR}/create-weblogic-domain-pv-pvc
    $ ./create-pv-pvc.sh -i create-pv-pvc-inputs.yaml -o output_soainfra
    ```
  * The `create-pv-pvc.sh` script will create a subdirectory `pv-pvcs` under the given `/path/to/output-directory` directory and creates two YAML configuration files for PV and PVC. Apply these two YAML files to create the PV and PVC Kubernetes resources using the `kubectl create -f` command:
    ```bash
    $ kubectl create -f output_soainfra/pv-pvcs/soainfra-domain-pv.yaml
    $ kubectl create -f output_soainfra/pv-pvcs/soainfra-domain-pvc.yaml
    ```

#### Create a Kubernetes secret with domain credentials

   Create the Kubernetes secrets `username` and `password` of the administrative account in the same Kubernetes namespace as the domain:

  ```
    $ cd ${WORKDIR}/create-weblogic-domain-credentials
    $ ./create-weblogic-credentials.sh -u weblogic -p Welcome1 -n soans -d soainfra -s soainfra-domain-credentials
  ```

  For more details, see [this document](https://github.com/oracle/weblogic-kubernetes-operator/blob/v3.4.2/kubernetes/samples/scripts/create-weblogic-domain-credentials/README.md).

  You can check the secret with the `kubectl get secret` command.

  For example:

  {{%expand "Click here to see the sample secret description." %}}
  ```
  $ kubectl get secret soainfra-domain-credentials -o yaml -n soans
    apiVersion: v1
    data:
      password: T3JhZG9jX2RiMQ==
      sys_password: T3JhZG9jX2RiMQ==
      sys_username: c3lz
      username: U09BMQ==
    kind: Secret
    metadata:
      creationTimestamp: "2020-06-25T14:08:16Z"
      labels:
        weblogic.domainName: soainfra
        weblogic.domainUID: soainfra
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
        time: "2020-06-25T14:08:16Z"
      name: soainfra-rcu-credentials
      namespace: soans
      resourceVersion: "265386"
      selfLink: /api/v1/namespaces/soans/secrets/soainfra-rcu-credentials
      uid: 2d93941c-656b-43a4-8af2-78ca8be0f293
    type: Opaque
  ```
  {{% /expand %}}

#### Create a Kubernetes secret with the RCU credentials

   You also need to create a Kubernetes secret containing the credentials for the database schemas.
When you create your domain, it will obtain the RCU credentials
from this secret.

Use the provided sample script to create the secret:

```bash
$ cd ${WORKDIR}/create-rcu-credentials
$ ./create-rcu-credentials.sh \
  -u SOA1 \
  -p Oradoc_db1 \
  -a sys \
  -q Oradoc_db1 \
  -d soainfra \
  -n soans \
  -s soainfra-rcu-credentials
```

The parameter values are:

  * `-u` username for schema owner (regular user), required.
  * `-p` password for schema owner (regular user), required.
  * `-a` username for SYSDBA user, required.
  * `-q` password for SYSDBA user, required.
  * `-d` domainUID. Example: `soainfra`
  * `-n` namespace. Example: `soans`
  * `-s` secretName. Example: `soainfra-rcu-credentials`

You can confirm the secret was created as expected with the `kubectl get secret` command.

For example:

{{%expand "Click here to see the sample secret description." %}}
``` bash
$ kubectl get secret soainfra-rcu-credentials -o yaml -n soans
  apiVersion: v1
  data:
    password: T3JhZG9jX2RiMQ==
    sys_password: T3JhZG9jX2RiMQ==
    sys_username: c3lz
    username: U09BMQ==
  kind: Secret
  metadata:
    creationTimestamp: "2020-06-25T14:08:16Z"
    labels:
      weblogic.domainName: soainfra
      weblogic.domainUID: soainfra
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
      time: "2020-06-25T14:08:16Z"
    name: soainfra-rcu-credentials
    namespace: soans
    resourceVersion: "265386"
    selfLink: /api/v1/namespaces/soans/secrets/soainfra-rcu-credentials
    uid: 2d93941c-656b-43a4-8af2-78ca8be0f293
  type: Opaque
```
{{% /expand %}}

#### Configure access to your database

Oracle SOA Suite domains require a database with the necessary schemas installed in them. The Repository Creation Utility (RCU) allows you to create
those schemas.  You must set up the database before you create your domain. There are no additional requirements added by running Oracle SOA Suite in Kubernetes; the same existing requirements apply.

For production deployments, you must set up and use the standalone (non-container) based database running outside of Kubernetes.

Before creating a domain, you will need to set up the necessary schemas in your database.

#### Run the Repository Creation Utility to set up your database schemas

##### Create schemas

To create the database schemas for Oracle SOA Suite, run the `create-rcu-schema.sh` script.

For example:

```bash
$ cd ${WORKDIR}/create-rcu-schema

$ ./create-rcu-schema.sh -h
 usage: ./create-rcu-schema.sh -s <schemaPrefix> -t <schemaType> -d <dburl> -i <image> -u <imagePullPolicy> -p <docker-store> -n <namespace> -q <sysPassword> -r <schemaPassword>  -o <rcuOutputDir> -c <customVariables> [-l] <timeoutLimit>  [-h]
  -s RCU Schema Prefix (required)
  -t RCU Schema Type (optional)
      (supported values: osb,soa,soaosb)
  -d RCU Oracle Database URL (optional)
      (default: oracle-db.default.svc.cluster.local:1521/devpdb.k8s)
  -p OracleSOASuite ImagePullSecret (optional)
      (default: none)
  -i OracleSOASuite Image (optional)
      (default: soasuite:12.2.1.4)
  -u OracleSOASuite ImagePullPolicy (optional)
      (default: IfNotPresent)
  -n Namespace for RCU pod (optional)
      (default: default)
  -q password for database SYSDBA user. (optional)
      (default: Oradoc_db1)
  -r password for all schema owner (regular user). (optional)
      (default: Oradoc_db1)
  -o Output directory for the generated YAML file. (optional)
      (default: rcuoutput)
  -c Comma-separated custom variables in the format variablename=value. (optional).
      (default: none)
  -l Timeout limit in seconds. (optional).
      (default: 300)
  -h Help

$ ./create-rcu-schema.sh \
  -s SOA1 \
  -t soaosb \
  -d oracle-db.default.svc.cluster.local:1521/devpdb.k8s \
  -i soasuite:12.2.1.4 \
  -n default \
  -q Oradoc_db1 \
  -r Oradoc_db1 \
  -c SOA_PROFILE_TYPE=SMALL,HEALTHCARE_INTEGRATION=NO
```

For Oracle SOA Suite domains, the `create-rcu-schema.sh` script supports:
* domain types: `soa`, `osb`, and `soaosb`.
You must specify one of these using the `-t` flag.
* For Oracle SOA Suite you must specify the Oracle SOA schema profile type using the `-c` flag. For example, `-c SOA_PROFILE_TYPE=SMALL`. Supported values for `SOA_PROFILE_TYPE` are `SMALL`, `MED`, and `LARGE`.

> Note: To use the `LARGE` schema profile type, make sure that the partitioning feature is enabled in the Oracle Database.

Make sure that you maintain the association between the database schemas and the
matching domain just like you did in a non-Kubernetes environment. There is no specific
functionality provided to help with this.

##### Drop schemas

If you want to drop a schema, you can use the `drop-rcu-schema.sh` script.

For example:

```bash
$ cd ${WORKDIR}/create-rcu-schema

$ ./drop-rcu-schema.sh -h
usage: ./drop-rcu-schema.sh  -s <schemaPrefix> -d <dburl> -n <namespace> -q <sysPassword> -r <schemaPassword> -c <customVariables> [-h]
  -s RCU Schema Prefix (required)
  -t RCU Schema Type (optional)
        (supported values: osb,soa,soaosb)
  -d Oracle Database URL (optional)
        (default: oracle-db.default.svc.cluster.local:1521/devpdb.k8s)
  -n Namespace where RCU pod is deployed (optional)
        (default: default)
  -q password for database SYSDBA user. (optional)
        (default: Oradoc_db1)
  -r password for all schema owner (regular user). (optional)
        (default: Oradoc_db1)
  -c Comma-separated custom variables in the format variablename=value. (optional).
        (default: none)
  -h Help

$ ./drop-rcu-schema.sh \
  -s SOA1 \
  -t soaosb \
  -d oracle-db.default.svc.cluster.local:1521/devpdb.k8s \
  -n default \
  -q Oradoc_db1 \
  -r Oradoc_db1 \
  -c SOA_PROFILE_TYPE=SMALL,HEALTHCARE_INTEGRATION=NO
```

For Oracle SOA Suite domains, the `drop-rcu-schema.sh` script supports:
* Domain types: `soa`, `osb`, and `soaosb`.
You must specify one of these using the `-t` flag.
* For Oracle SOA Suite, you must specify the Oracle SOA schema profile type using the `-c` flag. For example, `-c SOA_PROFILE_TYPE=SMALL`. Supported values for `SOA_PROFILE_TYPE` are `SMALL`, `MED`, and `LARGE`.

### Create an Oracle SOA Suite domain

Now that you have your Docker images and you have created your RCU schemas, you are ready to create your domain. To continue, follow the instructions in [Create Oracle SOA Suite domains]({{< relref "/soa-domains/installguide/create-soa-domains" >}}).
