+++
title = "Prepare environment for WCC domain"
date =  2021-02-14T16:43:45-05:00
weight = 2
pre = "<b>2.  </b>"
description = "Prepare environment for WCC domain on Oracle Kubernetes Engine (OKE)."
+++

To create your Oracle WebCenter Content domain in Kubernetes OKE environment, complete the following steps:

### Contents
1. [Set up the code repository to deploy Oracle WebCenter Content domain](#set-up-the-code-repository-to-deploy-oracle-webcenter-content-domain)
1. [Create a namespace for the Oracle WebCenter Content domain](#create-a-namespace-for-the-oracle-webcenter-content-domain)
1. [Create the imagePullSecrets](#create-the-imagepullsecrets)
1. [Install the WebLogic Kubernetes Operator](#install-the-weblogic-kubernetes-operator)
1. [Prepare the environment for Oracle WebCenter Content domain](#prepare-the-environment-for-oracle-webcenter-content-domain)

    a. [Upgrade the WebLogic Kubernetes Operator with the Oracle WebCenter Content domain-namespace](#upgrade-the-weblogic-kubernetes-operator-with-the-oracle-webcenter-content-domain-namespace)
	
	b. [Create a persistent storage for the Oracle WebCenter Content domain](#create-a-persistent-storage-for-the-oracle-webcenter-content-domain)

    c. [Create a Kubernetes secret with domain credentials](#create-a-kubernetes-secret-with-domain-credentials)
	
	d. [Create a Kubernetes secret with the RCU credentials](#create-a-kubernetes-secret-with-the-rcu-credentials)
	
	e. [Install and start the Database](#install-and-start-the-database)
	
	f. [Configure access to your database](#configure-access-to-your-database)
	
	g. [Run the Repository Creation Utility to set up your database schemas](#run-the-repository-creation-utility-to-set-up-your-database-schemas)
1. [Create Oracle WebCenter Content domain](#create-oracle-webcenter-content-domain)

### Set up the code repository to deploy Oracle WebCenter Content domain

Oracle WebCenter Content domain deployment on Kubernetes leverages the WebLogic Kubernetes Operator infrastructure. To deploy an Oracle WebCenter Content domain, you must set up the deployment scripts.

1. Create a working directory to set up the source code:
   ```bash  
   $ mkdir $HOME/wcc_3.4.2
   $ cd $HOME/wcc_3.4.2
   ```

1. Download the WebLogic Kubernetes Operator source code and  Oracle WebCenter Content Suite Kubernetes deployment scripts from the WCContent [repository](https://github.com/oracle/fmw-kubernetes.git). Required artifacts are available at `OracleWebCenterContent/kubernetes`.

    ``` bash
	$ git clone https://github.com/oracle/fmw-kubernetes.git
	$ export WORKDIR=$HOME/wcc_3.4.2/fmw-kubernetes/OracleWebCenterContent/kubernetes
    ```

### Create a namespace for the Oracle WebCenter Content domain

   Create a Kubernetes namespace (for example, `wccns`) for the domain unless you intend to use the default namespace. Use the new namespace in the remaining steps in this section.
For details, see [Prepare to run a domain](https://oracle.github.io/weblogic-kubernetes-operator/quickstart/prepare/).

  ```
   $ kubectl create namespace wccns   
  ```
### Create the imagePullSecrets

Create the imagePullSecrets (in wccns namespace) so that Kubernetes Deployment can pull the image automatically from OCIR.

> Note: Create the imagePullSecret as per your environement using a sample command like this -
  ```
  $ kubectl create secret docker-registry image-secret -n wccns --docker-server=phx.ocir.io  --docker-username=axxxxxxxxxxx/oracleidentitycloudservice/<your_user_name> --docker-password='vUv+xxxxxxxxxxx<KN7z'  --docker-email=me@oracle.com  
  ```

The parameter values are:

  `OCI Region is phoenix`       phx.ocir.io
  `OCI Tenancy Name`            axxxxxxxxxxx
  `ImagePullSecret Name`        image-secret
  `Username and email address`  me@oracle.com 
  `Auth Token Password`         vUv+xxxxxxxxxxx<KN7z
  
### Install the WebLogic Kubernetes Operator

The WebLogic Kubernetes Operator supports the deployment of Oracle WebCenter Content domain in the Kubernetes environment. 

In the following example commands to install the WebLogic Kubernetes Operator, `opns` is the namespace and `op-sa` is the service account created for the WebLogic Kubernetes Operator:

#### Creating namespace and service account for WebLogic Kubernetes Operator
  
  ```
  $ kubectl create namespace opns
  $ kubectl create serviceaccount -n opns  op-sa  
  ```
#### Install WebLogic Kubernetes Operator  
  ```
  $ cd ${WORKDIR} 
    
  $ helm install weblogic-kubernetes-operator charts/weblogic-operator --namespace opns  --set image=phx.ocir.io/xxxxxxxxxxx/oracle/weblogic-kubernetes-operator:3.4.2 --set imagePullSecret=image-secret --set serviceAccount=op-sa --set "domainNamespaces={}" --set "javaLoggingLevel=FINE" --wait
  ```
#### Verify the WebLogic Kubernetes Operator pod
  
  ```
  $ kubectl get pods -n opns
 
  NAME                                 READY   STATUS    RESTARTS   AGE
  weblogic-operator-779965b66c-d8265   1/1     Running   0          11d
  
  # Verify the Operator helm Charts
  $ helm list -n opns
 
  NAME                            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                          APP VERSION
  weblogic-kubernetes-operator    opns            3               2022-02-24 06:50:29.810106777 +0000 UTC deployed        weblogic-operator-3.4.2        3.4.2
  ```
### Prepare the environment for Oracle WebCenter Content domain

#### Upgrade the WebLogic Kubernetes Operator with the Oracle WebCenter Content domain-namespace

  ```
   $ cd ${WORKDIR}
   $ helm upgrade --reuse-values --namespace opns --set "domainNamespaces={wccns}" --wait weblogic-kubernetes-operator charts/weblogic-operator    
  ```
#### Create a persistent storage for the Oracle WebCenter Content domain

   In the Kubernetes namespace you created, create the PV and PVC for the domain by running the [create-pv-pvc.sh](https://oracle.github.io/weblogic-kubernetes-operator/samples/storage/) script. Follow the instructions for using the script to create a dedicated PV and PVC for the Oracle WebCenter Content domain.
   
   Here we will use the NFS Server and mount path, created on [this page]({{< relref "/wccontent-domains/oracle-cloud/filesystem" >}}).

  * Review the configuration parameters for PV creation [here](https://oracle.github.io/weblogic-kubernetes-operator/samples/storage/#configuration-parameters). Based on your requirements, update the values in the `create-pv-pvc-inputs.yaml` file located at `${WORKDIR}/create-weblogic-domain-pv-pvc/`. Sample configuration parameter values for the Oracle WebCenter Content domain are:
    * `baseName`: domain
    * `domainUID`: wccinfra
    * `namespace`: wccns    
	* `weblogicDomainStorageType:`: NFS
	* `weblogicDomainStorageNFSServer:`: <your_nfs_server_ip>
    * `weblogicDomainStoragePath`: /<your_dir_name>
    > Note: Make sure to update the "weblogicDomainStorageNFSServer:" with the NFS Server IP as per your Environment	

  * Ensure that the path for the `weblogicDomainStoragePath` property exists (if not, please refer subsection 4 of [this](https://oracle.github.io/fmw-kubernetes/wccontent-domains/appendix/quickstart-deployment-guide/#61-prepare-for-an-oracle-webcenter-content-domain) document to create it first) and
    has correct access permissions, and that the folder is empty.
  
  * Run the `create-pv-pvc.sh` script:
    ```bash
    $ cd ${WORKDIR}/create-weblogic-domain-pv-pvc
    
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
   $ cd ${WORKDIR}/create-weblogic-domain-credentials
    
   $ ./create-weblogic-credentials.sh -u weblogic -p welcome1 -n wccns -d wccinfra -s wccinfra-domain-credentials
   ```

  For more details, see [this document](https://github.com/oracle/weblogic-kubernetes-operator/blob/v3.4.2/kubernetes/samples/scripts/create-weblogic-domain-credentials/README.md).

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
  creationTimestamp: "2021-07-30T06:04:33Z"
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
    time: "2021-07-30T06:04:36Z"
  name: wccinfra-domain-credentials
  namespace: wccns
  resourceVersion: "90770768"
  selfLink: /api/v1/namespaces/wccns/secrets/wccinfra-domain-credentials
  uid: 9c5dab09-15f3-4e1f-a40d-457904ddf96b
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

#### Install and start the Database
This step is required only when standalone database was not already setup and the user wanted to use the database in a container.
The Oracle Database Docker images are supported only for non-production use. For more details, see My Oracle Support note: Oracle Support for Database Running on Docker (Doc ID 2216342.1). For production usecase it is suggested to use a standalone db.
Sample provides steps to create the database in a container.

The database in a container can be created with a PV attached for persisting the data or without attaching the PV.
In this setup we will be creating database in a container without PV attached.
```bash
$ cd ${WORKDIR}/create-oracle-db-service

$ ./start-db-service.sh -i phx.ocir.io/xxxxxxxxxxxx/oracle/database/enterprise:x.x.x.x -s image-secret -n wccns
```
{{%expand "Click here to see the Sample Output" %}}
```
$ ./start-db-service.sh -i phx.ocir.io/xxxxxxxxxxxx/oracle/database/enterprise:x.x.x.x -s image-secret -n wccns
Checking Status for NameSpace [wccns]
Skipping the NameSpace[wccns] Creation ...
NodePort[30011] ImagePullSecret[docker-store] Image[phx.ocir.io/xxxxxxxxxxxx/oracle/database/enterprise:x.x.x.x] NameSpace[wccns]
service/oracle-db created
deployment.apps/oracle-db created
[oracle-db-8598b475c5-cx5nk] already initialized ..
Checking Pod READY column for State [1/1]
NAME                         READY   STATUS    RESTARTS   AGE
oracle-db-8598b475c5-cx5nk   1/1     Running   0          20s
Service [oracle-db] found
NAME                         READY   STATUS    RESTARTS   AGE
oracle-db-8598b475c5-cx5nk   1/1     Running   0          25s
NAME        TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
oracle-db   LoadBalancer   10.96.74.187   <pending>     1521:30011/TCP   28s
[1/30] Retrying for Oracle Database Availability...
[2/30] Retrying for Oracle Database Availability...
[3/30] Retrying for Oracle Database Availability...
[4/30] Retrying for Oracle Database Availability...
[5/30] Retrying for Oracle Database Availability...
[6/30] Retrying for Oracle Database Availability...
[7/30] Retrying for Oracle Database Availability...
[8/30] Retrying for Oracle Database Availability...
[9/30] Retrying for Oracle Database Availability...
[10/30] Retrying for Oracle Database Availability...
[11/30] Retrying for Oracle Database Availability...
[12/30] Retrying for Oracle Database Availability...
[13/30] Retrying for Oracle Database Availability...
Done ! The database is ready for use .
Oracle DB Service is RUNNING with NodePort [30011]
Oracle DB Service URL [oracle-db.wccns.svc.cluster.local:1521/devpdb.k8s]
```
{{% /expand %}}

Once database is created successfully, you can use the database connection string, as an `rcuDatabaseURL` parameter in the create-domain-inputs.yaml file.

#### Configure access to your database
Run a container to create `rcu pod`

```bash
kubectl run rcu --generator=run-pod/v1 \
  --image phx.ocir.io/xxxxxxxxxxx/oracle/wccontent:x.x.x.x \
  --namespace wccns \
  --overrides='{ "apiVersion": "v1", "spec": { "imagePullSecrets": [{"name": "image-secret"}] } }'  \
  -- sleep infinity
   
# Check the status of rcu pod
kubectl get pods -n wccns
```

#### Run the Repository Creation Utility to set up your database schemas

##### Create or Drop schemas

To create the database schemas for Oracle WebCenter Content, run the `create-rcu-schema.sh` script.

For example:

```bash
# Make sure rcu pod status is running before executing this 
kubectl exec -n wccns -ti rcu /bin/bash

# DB details 
export CONNECTION_STRING=your_db_host:1521/your_db_service
export RCUPREFIX=your_schema_prefix
echo -e welcome1"\n"welcome1> /tmp/pwd.txt
   
# Create schemas
/u01/oracle/oracle_common/bin/rcu -silent -createRepository -databaseType ORACLE -connectString $CONNECTION_STRING -dbUser sys -dbRole sysdba -useSamePasswordForAllSchemaUsers true -selectDependentsForComponents true -schemaPrefix $RCUPREFIX -component CONTENT -component MDS   -component STB -component OPSS  -component IAU -component IAU_APPEND -component IAU_VIEWER -component WLS  -tablespace USERS -tempTablespace TEMP -f < /tmp/pwd.txt

# Drop schemas
/u01/oracle/oracle_common/bin/rcu -silent -dropRepository -databaseType ORACLE -connectString $CONNECTION_STRING -dbUser sys -dbRole sysdba -selectDependentsForComponents true -schemaPrefix $RCUPREFIX -component CONTENT -component MDS  -component STB -component OPSS  -component IAU -component IAU_APPEND -component IAU_VIEWER -component WLS -f < /tmp/pwd.txt 

# Exit from the container
exit
```
> Note: In the create and drop schema commands above, pass additional components ( -component IPM -component CAPTURE ) if IPM and CAPTURE applications are enabled resepectively.

### Create Oracle WebCenter Content domain

Now that you have your Docker images and you have created your RCU schemas, you are ready to create your domain. To continue, follow the Step-3 and Step-4.

  
   
   
	
