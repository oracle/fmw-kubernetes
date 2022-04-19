+++
title = "Create Oracle Internet Directory Instances"
weight = 4 
pre = "<b>4. </b>"
description=  "This document provides details of the oid Helm chart."

+++

1. [Introduction](#introduction)
1. [Create a Kubernetes namespace](#create-a-kubernetes-namespace)
1. [Create a Kubernetes secret for the container registry](#create-a-kubernetes-secret-for-the-container-registry)
1. [Create a persistent volume directory](#create-a-persistent-volume-directory)
1. [The oid Helm chart](#the-oid-helm-chart)
1. [Create OID instances](#create-oid-instances)
1. [Helm command output](#helm-command-output)
1. [Verify the OID deployment](#verify-the-oid-deployment)
1. [Undeploy an OID deployment](#undeploy-an-oid-deployment)
1. [Appendix: Configuration parameters](#appendix-configuration-parameters)


### Introduction

This chapter demonstrates how to deploy Oracle Internet Directory (OID) 12c instance(s) using the Helm package manager for Kubernetes. 

Based on the configuration, this chart deploys the following objects in the specified namespace of a Kubernetes cluster.

* Service Account
* Secret
* Persistent Volume and Persistent Volume Claim
* Pod(s)/Container(s) for Oracle Internet Directory Instances
* Services for interfaces exposed through Oracle Internet Directory Instances
* Ingress configuration

### Create a Kubernetes namespace

Create a Kubernetes namespace for the OID deployment by running the following command:

```bash
$ kubectl create namespace <namespace>
```

For example:

```bash
$ kubectl create namespace oidns
```

The output will look similar to the following:

```
namespace/oidns created
```


### Create a Kubernetes secret for the container registry

In this section you create a secret that stores the credentials for the container registry where the OID image is stored. This step must be followed if using Oracle Container Registry or your own private registry. If you are not using a container registry and have loaded the images on each of the master and worker nodes, you can skip this step.

1. Run the following command to create the secret:

   ```bash
   kubectl create secret docker-registry "orclcred" --docker-server=<CONTAINER_REGISTRY> \
   --docker-username="<USER_NAME>" \
   --docker-password=<PASSWORD> --docker-email=<EMAIL_ID> \
   --namespace=<domain_namespace>
   ```
   
   For example, if using Oracle Container Registry:
   
   ```bash
   kubectl create secret docker-registry "orclcred" --docker-server=container-registry.oracle.com \
   --docker-username="user@example.com" \
   --docker-password=password --docker-email=user@example.com \
   --namespace=oudns
   ```
   
   
   Replace `<USER_NAME>` and `<PASSWORD>` with the credentials for the registry with the following caveats:

   -  If using Oracle Container Registry to pull the OID container image, this is the username and password used to login to [Oracle Container Registry](https://container-registry.oracle.com). Before you can use this image you must login to [Oracle Container Registry](https://container-registry.oracle.com), navigate to `Middleware` > `oid_cpu` and accept the license agreement.

   - If using your own container registry to store the OID container image, this is the username and password (or token) for your container registry.   

   The output will look similar to the following:
   
   ```bash
   secret/orclcred created
   ```

### Create a persistent volume directory

As referenced in [Prerequisites](../prerequisites) the nodes in the Kubernetes cluster must have access to a persistent volume such as a Network File System (NFS) mount or a shared file system. 

Make sure the persistent volume path has **full** access permissions, and that the folder is empty. In this example `/scratch/shared/` is a shared directory accessible from all nodes.
   
1. On the master node run the following command to create a `user_projects` directory:

   ```bash 
   $ cd <persistent_volume>
   $ mkdir oid_user_projects   
   $ chmod 777 oid_user_projects
   ```
   
   For example:
   
   ```bash 
   $ cd /scratch/shared
   $ mkdir oid_user_projects   
   $ chmod 777 oid_user_projects
   ```
   
1. On the master node run the following to ensure it is possible to read and write to the persistent volume:
   
   ```
   $ cd <persistent_volume>/oid_user_projects
   $ touch file.txt
   $ ls filemaster.txt
   ```
   
   For example:
   
   ```bash
   $ cd /scratch/shared/oid_user_projects
   $ touch filemaster.txt
   $ ls filemaster.txt
   ```
   
   On the first worker node run the following to ensure it is possible to read and write to the persistent volume:
   
   ```bash
   $ cd /scratch/shared/oid_user_projects
   $ ls filemaster.txt
   $ touch fileworker1.txt
   $ ls fileworker1.txt
   ```
   
   Repeat the above for any other worker nodes e.g fileworker2.txt etc. Once proven that it's possible to read and write from each node to the persistent volume, delete the files created.



### The oid Helm chart

The 'oid' Helm chart allows you to create Oracle Internet Directory instances along with Kubernetes objects in a specified namespace using the `oid` Helm Chart.

The deployment can be initiated by running the following Helm command with reference to the `oid` Helm chart, along with configuration parameters according to your environment. 

```bash
cd $WORKDIR/kubernetes/helm
$ helm install --namespace <namespace> \
<Configuration Parameters> \
<deployment/release name> \
<Helm Chart Path/Name>
```

Configuration Parameters (override values in chart) can be passed on with `--set` arguments on the command line and/or with `-f / --values` arguments when referring to files.

**Note**: The examples in [Create OID instances](#create-oid-instances) below provide values which allow the user to override the default values provided by the Helm chart. A full list of configuration parameters and their default values is shown in [Appendix: Configuration parameters](#appendix-configuration-parameters).

For more details about the `helm` command and parameters, please execute `helm --help` and `helm install --help`.

### Create OID instances

You can create OID instances using one of the following methods:

1. [Using a YAML file](#using-a-yaml-file)
1. [Using `--set` argument](#using---set-argument)

**Note**: It is not possible to install sample data or load an ldif file during the OID deployment. In order to load data in OID, create the OID deployment and then use ldapmodify post the ingress deployment. See [Using LDAP utilities](../configure-ingress/#using-ldap-utilities).

#### Using a YAML file

1. Navigate to the `$WORKDIR/kubernetes/helm` directory:

   ```bash
   $ cd $WORKDIR/kubernetes/helm
   ```

1. Create an `oid-values-override.yaml` as follows:

   ```yaml
   image:
     repository: <image>
     tag: <tag>
     pullPolicy: IfNotPresent
   imagePullSecrets:
     - name: orclcred
   oidConfig:
     realmDN: <baseDN>
     domainName: <domainName>
     orcladminPassword: <password>
     dbUser: sys
     dbPassword: <sys_password>
     dbschemaPassword: <password>
     rcuSchemaPrefix: <rcu_prefix>
     rcuDatabaseURL: <db_hostname>:<dp_port>/<db_service>
     sslwalletPassword: <password>
   persistence:
     type: filesystem
     filesystem:
       hostPath::
         path: <persistent_volume>/oid_user_projects
   odsm:
     adminUser: weblogic
     adminPassword: <password>
   ```

   For example:
   
   ```yaml
   image:
     repository: container-registry.oracle.com/middleware/oid_cpu
     tag: 12.2.1.4-jdk8-ol7-220223.1744
     pullPolicy: IfNotPresent
   imagePullSecrets:
     - name: orclcred
   oidConfig:
     realmDN: dc=oid,dc=example,dc=com
     domainName: oid_domain
     orcladminPassword: <password>
     dbUser: sys
     dbPassword: <password>
     dbschemaPassword: <password>
     rcuSchemaPrefix: OIDK8S
     rcuDatabaseURL: oiddb.example.com:1521/oiddb.example.com
     sslwalletPassword: <password>
   persistence:
     type: filesystem
     filesystem:
       hostPath:
         path: /scratch/shared/oid_user_projects
   odsm:
     adminUser: weblogic
     adminPassword: <password>
   ```

    The following caveats exist:
   
   * `<baseDN>` should be set to the value for the base DN to be created.
   * `<domainName>` should be set to the value for the domain name to be created.
   * `rcuDatabaseURL`, `dbUser` and `dbPassword` should be set to the relevant values for the database created as per [Prerequisites](../prerequisites).
   * `rcuSchemaPrefix` and `dbschemaPassword` should be set to a value of your choice. This creates the OID schema in the database.
   * Replace `<password>` with a the relevant passwords.
   * If you are not using Oracle Container Registry or your own container registry for your OID container image, then you can remove the following:
   
      ```
      imagePullSecrets:
        - name: orclcred
      ```
   
   * If using NFS for your persistent volume the change the `persistence` section as follows:

      ```yaml
      persistence:
        type: networkstorage
        networkstorage:
          nfs: 
            path: <persistent_volume>/oud_user_projects
            server: <NFS IP address>
      ```

1. Run the following to create the OID instances:

   ```bash
   helm install --namespace <namespace> --values oid-values-override.yaml release name> oid
   ```
	  
   For example:
	  
   ```bash
   helm install --namespace oidns --values  oid-values-override.yaml oid oid
   ```


1. Check the OID deployment as per [Verify the OID deployment](#verify-the-oid-deployment).

#### Using `--set` argument

1. Navigate to the `$WORKDIR/kubernetes/helm` directory:

   ```bash
   $ cd $WORKDIR/kubernetes/helm
   ```
  
   
1. Run the following command to create OUDSM instance:

   ```bash
   $ helm install --namespace <namespace> \
   --set oidConfig.realmDN="<baseDN>",oidConfig.domainName=<domainName>,oidConfig.orcladminPassword=<password> \
   --set oidConfig.dbUser=sys,oidConfig.dbPassword=<password>,oidConfig.dbschemaPassword=<password> \
   --set oidConfig.rcuSchemaPrefix="<rcu_prefix>",oidConfig.rcuDatabaseURL="<db_hostname>:<db_port>/<db_service>",oidConfig.sslwalletPassword=<password> \
   --set persistence.filesystem.hostPath.path=<persistent_volume>/oid_user_projects \
   --set image.repository=<image_location>,image.tag=<image_tag> \
   --set odsm.adminUser=weblogic,odsm.adminPassword=<password> \
   --set imagePullSecrets[0].name="orclcred" \
   <release name> oid
   ```
	 
	 
   For example:

   ```bash
   $ helm install --namespace oidns \
   --set oidConfig.realmDN="dc=oid,dc=example,dc=com",oidConfig.domainName=oid_domain,oidConfig.orcladminPassword=<password> \
   --set oidConfig.dbUser=sys,oidConfig.dbPassword=<password>,oidConfig.dbschemaPassword=<password> \
   --set oidConfig.rcuSchemaPrefix="OIDK8S",oidConfig.rcuDatabaseURL="oiddb.example.com:1521/oiddb.example.com",oidConfig.sslwalletPassword=<password> \
   --set persistence.filesystem.hostPath.path=/scratch/shared/oid_user_projects \ 
   --set image.repository=container-registry.oracle.com/middleware/oid_cpu,image.tag=12.2.1.4-jdk8-ol7-220223.1744 \
   --set odsm.adminUser=weblogic,odsm.adminPassword=<password> \
   --set imagePullSecrets[0].name="orclcred" \
   oid oid
   ```
   
   The following caveats exist:
   
   * `<baseDN>` should be set to the value for the base DN to be created.
   * `<domainName>` should be set to the value for the domain name to be created.
   * `rcuDatabaseURL`, `dbUser` and `dbPassword` should be set to the relevant values for the database created as per [Prerequisites](../prerequisites).
   * `rcuSchemaPrefix` and `dbschemaPassword` should be set to a value of your choice. This creates the OID schema in the database.
   * Replace `<password>` with a the relevant passwords.
   * If you are not using Oracle Container Registry or your own container registry for your OID container image, then you can remove the following: `--set imagePullSecrets[0].name="orclcred"`
   * If using using NFS for your persistent volume then use `persistence.networkstorage.nfs.path=<persistent_volume>/oid_user_projects,persistence.networkstorage.nfs.server:<NFS IP address>`


1. Check the OID deployment as per [Verify the OID deployment](#verify-the-oid-deployment).

### Helm command output

In all the examples above, the following output is shown following a successful execution of the `helm install` command.

```
NAME: oid
LAST DEPLOYED: Fri Mar 25 09:43:25 2022
NAMESPACE: oidns
STATUS: deployed
REVISION: 1
TEST SUITE: None
```
	
### Verify the OID deployment	

Run the following command to verify the OID deployment:

Command:

```bash
$ kubectl --namespace oidns get all
```

For example:

```bash
$ kubectl --namespace oidns get all
```

The output will look similar to the following:

```
NAME           READY   STATUS    RESTARTS   AGE
pod/oidhost1   1/1     Running   0          35m
pod/oidhost2   1/1     Running   0          35m

NAME                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                               AGE
service/oid-lbr-ldap   ClusterIP   10.110.118.113   <none>        3060/TCP,3131/TCP                     35m
service/oidhost1       ClusterIP   10.97.17.125     <none>        3060/TCP,3131/TCP,7001/TCP,7002/TCP   35m
service/oidhost2       ClusterIP   10.106.32.187    <none>        3060/TCP,3131/TCP                     35m

```

**Note**: If the OID deployment fails refer to [Troubleshooting](../troubleshooting) for instructions on how to view pod logs or describe the pod.
Once the problem is identified follow [Undeploy an OID deployment](#undeploy-an-oid-deployment) to clean down the deployment before deploying again.



#### Kubernetes Objects

Kubernetes objects created by the Helm chart are detailed in the table below:

| **Type** | **Name** | **Example Name** | **Purpose** |
| ------ | ------ | ------ | ------ |
| Secret | <deployment/release name>-creds |  oid-creds | Secret object for Oracle Internet Directory related critical values like passwords |
| Persistent Volume | <deployment/release name>-pv | oid-pv | Persistent Volume for user_projects mount. |
| Persistent Volume Claim | <deployment/release name>-pvc | oid-pvc | Persistent Volume Claim for user_projects mount. |
| Pod | <deployment/release name>1 | oidhost1 | Pod/Container for base Oracle Internet Directory Instance which would be populated first with base configuration (like number of sample entries) |
| Pod | <deployment/release name>N | oidhost2, oidhost3, ...  | Pod(s)/Container(s) for Oracle Internet Directory Instances |
| Service | <deployment/release name>lbr-ldap | oid-lbr-ldap | Service for LDAP/LDAPS access load balanced across the base Oracle Internet Directory instances |
| Service | <deployment/release name> | oidhost1, oidhost2, oidhost3, ... | Service for LDAP/LDAPS access for each base Oracle Internet Directory instance |
| Ingress | <deployment/release name>-ingress-nginx | oid-ingress-nginx | Ingress Rules for LDAP/LDAPS access. |

* In the table above the 'Example Name' for each Object is based on the value 'oid' as deployment/release name for the Helm chart installation.

### Ingress Configuration

With OID instance(s) now deployed you are now ready to configure an ingress controller to direct traffic to OID as per [Configure an ingress for an OID](../configure-ingress).


### Undeploy an OID deployment

#### Remove OID schemas from the database

**Note**: These steps must be performed if cleaning down a failed install. Failure to do so will cause any new OID deployment to fail.

To remove the OID schemas from the database:

1. Run the following to enter a bash session in an oid pod:

   ```bash
   $ kubectl exec -ti <pod> -n <namespace> -- bash
   ```
   
   For example:
   
   ```bash
   $ kubectl exec -ti oidhost2 -n oidns -- bash
   ```
   
   This will take you into a bash session in the pod:

   ```bash
   [oracle@oidhost2 oracle]$    
   ```
   
1. Inside the container drop the RCU schemas as follows:

   ```bash
   [oracle@oidhost2 oracle]$ export CONNECTION_STRING=<db_host.domain>:<db_port>/<service_name>
   [oracle@oidhost2 oracle]$ export RCUPREFIX=<rcu_schema_prefix>
   [oracle@oidhost2 oracle]$ export DB_USER=sys
   [oracle@oidhost2 oracle]$ echo -e <db_pwd>"\n"<rcu_schema_pwd> > /tmp/pwd.txt
   
   ${ORACLE_HOME}/oracle_common/bin/rcu -silent -dropRepository -databaseType ORACLE -connectString ${CONNECTION_STRING} \
   -dbUser ${DB_USER} -dbRole sysdba -selectDependentsForComponents true -schemaPrefix ${RCUPREFIX} \
   -component MDS -component OPSS -component STB -component OID -component IAU -component WLS -f < /tmp/pwd.txt
   ```
   
   where:

   * `<db_host.domain>:<db_port>/<service_name>` is your database connect string
   * `<rcu_schema_prefix>` is the RCU schema prefix
   * `<db_pwd>` is the SYS password for the database
   * `<rcu_schema_pwd>` is the password for the `<rcu_schema_prefix>`
   
   For example:
   
   ```bash
   [oracle@oidhost2 oracle]$ export CONNECTION_STRING=oiddb.example.com:1521/oiddb.example.com
   [oracle@oidhost2 oracle]$ export RCUPREFIX=OIDK8S
   [oracle@oidhost2 oracle]$ export DB_USER=sys
   [oracle@oidhost2 oracle]$ echo -e <password>"\n"<password> > /tmp/pwd.txt 
   
    ${ORACLE_HOME}/oracle_common/bin/rcu -silent -dropRepository -databaseType ORACLE -connectString ${CONNECTION_STRING} \
   -dbUser ${DB_USER} -dbRole sysdba -selectDependentsForComponents true -schemaPrefix ${RCUPREFIX} \
   -component MDS -component OPSS -component STB -component OID -component IAU -component WLS -f < /tmp/pwd.txt
   ```
   
   The output will look similar to the following:
   
   ```bash
   
        RCU Logfile: /tmp/RCU2022-03-28_10-08_535715154/logs/rcu.log

   Processing command line ....
   Repository Creation Utility - Checking Prerequisites
   Checking Global Prerequisites
   Repository Creation Utility - Checking Prerequisites
   Checking Component Prerequisites
   Repository Creation Utility - Drop
   Repository Drop in progress.
           Percent Complete: 2
           Percent Complete: 13
           Percent Complete: 15
   Dropping Audit Services(IAU)
           Percent Complete: 23
           Percent Complete: 29
           Percent Complete: 44
           Percent Complete: 45
   Dropping Oracle Internet Directory(OID)
           Percent Complete: 46
           etc..
		   etc..
		   
   Dropping Audit Services Viewer(IAU_VIEWER)
   Dropping Audit Services Append(IAU_APPEND)
   Dropping Common Infrastructure Services(STB)
   Dropping tablespaces in the repository database

   Repository Creation Utility: Drop - Completion Summary

   Database details:
   -----------------------------
   Host Name                                    : oiddb.example.com
   Port                                         : 1521
   Service Name                                 : oiddb.example.com
   Connected As                                 : sys
   Prefix for (prefixable) Schema Owners        : OIDK8S
   Prefix for (non-prefixable) Schema Owners    : DEFAULT_PREFIX
   RCU Logfile                                  : /tmp/RCU2022-03-28_10-08_535715154/logs/rcu.log

   Component schemas dropped:
   -----------------------------
   Component                                    Status         Logfile

   Common Infrastructure Services               Success        /tmp/RCU2022-03-28_10-08_535715154/logs/stb.log
   Oracle Platform Security Services            Success        /tmp/RCU2022-03-28_10-08_535715154/logs/opss.log
   Oracle Internet Directory                    Success        /tmp/RCU2022-03-28_10-08_535715154/logs/oid.log
   Audit Services                               Success        /tmp/RCU2022-03-28_10-08_535715154/logs/iau.log
   Audit Services Append                        Success        /tmp/RCU2022-03-28_10-08_535715154/logs/iau_append.log
   Audit Services Viewer                        Success        /tmp/RCU2022-03-28_10-08_535715154/logs/iau_viewer.log
   Metadata Services                            Success        /tmp/RCU2022-03-28_10-08_535715154/logs/mds.log
   WebLogic Services                            Success        /tmp/RCU2022-03-28_10-08_535715154/logs/wls.log

   Repository Creation Utility - Drop : Operation Completed
   ```
   
#### Delete the OID deployment

1. Find the deployment release name:

   ```bash
   $ helm --namespace <namespace> list
   ```
        
   For example:

   ```bash 
   $ helm --namespace oidns list
   ```
   
   The output will look similar to the following:
   
   ```
   NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
   oid     oidns          2               2022-03-21 16:46:34.05531056 +0000 UTC  deployed         oid-0.1        12.2.1.4.0
   ```
        
1. Delete the deployment using the following command:

   ```bash
   $ helm uninstall --namespace <namespace> <release>
   ```
        
   For example:

   ```bash
   $ helm uninstall --namespace oidns oid
   ```
   
   The output will look similar to the following:
   
   ```
   release "oid" uninstalled
   ```

#### Delete the persistent volume contents

1. Delete the contents of the `oid_user_projects` directory in the persistent volume:

   ```bash
   $ cd <persistent_volume>/oid_user_projects
   $ rm -rf *
   ```
   
   For example:
   
   ```bash
   $ cd /scratch/shared/oid_user_projects
   $ rm -rf *
   ```

### Appendix: Configuration Parameters


The following table lists the configurable parameters of the `oid` chart and their default values.

| **Parameter** | **Description** | **Default Value** |
| ------------- | --------------- | ----------------- |
| replicaCount  | Number of base Oracle Internet Directory instances/pods/services to be created. | 1 |
|restartPolicyName | restartPolicy to be configured for each POD containing Oracle Internet Directory instance | OnFailure |
| image.repository | Oracle Internet Directory Image Registry/Repository and name. Based on this, the image parameter will be configured for Oracle Internet Directory pods/containers | oracle/oid |
| image.tag | Oracle Internet Directory Image Tag. Based on this, the image parameter will be configured for Oracle Internet Directory pods/containers | 12.2.1.4.0 |
| image.pullPolicy | policy to pull the image | IfnotPresent |
| imagePullSecrets.name | name of Secret resource containing private registry credentials | regcred |
| nameOverride | override the fullname with this name |  |
| fullnameOverride | Overrides the fullname with the provided string |  |
| serviceAccount.create | Specifies whether a service account should be created | true |
| serviceAccount.name | If not set and create is true, a name is generated using the fullname template | oid-< fullname >-token-< randomalphanum > |
| podSecurityContext | Security context policies to add to the controller pod |  |
| securityContext |  Security context policies to add by default |  |
| service.type | Type of Service to be created for OID Interfaces (like LDAP, HTTP, Admin) | ClusterIP |
| service.lbrtype | Service Type for loadbalancer services exposing LDAP, HTTP interfaces from available/accessible OID pods | ClusterIP |
| ingress.enabled |  | true |
| ingress.nginx.http.host | Hostname to be used with Ingress Rules. If not set, hostname would be configured according to fullname. Hosts would be configured as < fullname >-http.< domain >, < fullname >-http-0.< domain >, < fullname >-http-1.< domain >, etc. |  |
| ingress.nginx.http.domain | Domain name to be used with Ingress Rules. In ingress rules, hosts would be configured as < host >.< domain >, < host >-0.< domain >, < host >-1.< domain >, etc. |  |
| ingress.nginx.http.backendPort |  | http |
| ingress.nginx.http.nginxAnnotations |  | { kubernetes.io/ingress.class: “nginx" } |
| ingress.nginx.admin.host | Hostname to be used with Ingress Rules. If not set, hostname would be configured according to fullname. Hosts would be configured as < fullname >-admin.< domain >, < fullname >-admin-0.< domain >, < fullname >-admin-1.< domain >, etc. |  |
| ingress.nginx.admin.domain | Domain name to be used with Ingress Rules. In ingress rules, hosts would be configured as < host >.< domain >, < host >-0.< domain >, < host >-1.< domain >, etc. |  |
| ingress.nginx.admin.nginxAnnotations |  | { kubernetes.io/ingress.class: “nginx” nginx.ingress.kubernetes.io/backend-protocol: “https"} |
| ingress.ingress.tlsSecret | Secret name to use an already created TLS Secret. If such secret is not provided, one would be created with name < fullname >-tls-cert. If the TLS Secret is in different namespace, name can be mentioned as < namespace >/< tlsSecretName > |  |
| ingress.certCN | Subject’s common name (cn) for SelfSigned Cert | < fullname > |
| ingress.certValidityDays | Validity of Self-Signed Cert in days |  365 |
| nodeSelector | node labels for pod assignment |  |
| tolerations | node taints to tolerate |  |
| affinity | node/pod affinities |  |
| persistence.enabled | If enabled, it will use the persistent volume. if value is false, PV and PVC would not be used and pods would be using the default emptyDir mount volume | true |
| persistence.pvname | pvname to use an already created Persistent Volume , If blank will use the default name | oid-< fullname >-pv |
| persistence.pvcname | pvcname to use an already created Persistent Volume Claim , If blank will use default name | oid-< fullname >-pvc |
| persistence.type | supported values: either filesystem or networkstorage or custom | filesystem |
| persistence.filesystem.hostPath.path | The path location mentioned should be created and accessible from the local host provided with necessary privileges for the user | /scratch/shared/oid_user_projects |
| persistence.networkstorage.nfs.path | Path of NFS Share location | /scratch/shared/oid_user_projects |
| persistence.networkstorage.nfs.server | IP or hostname of NFS Server |  	0.0.0.0 |
| persistence.custom.* | Based on values/data, YAML content would be included in PersistenceVolume Object |  |
| persistence.accessMode | Specifies the access mode of the location provided |  ReadWriteMany |
| persistence.size | Specifies the size of the storage | 20Gi |
| persistence.storageClass | Specifies the storageclass of the persistence volume. | manual |
| persistence.annotations | specifies any annotations that will be used | { } |
| secret.enabled |  	If enabled it will use the secret created with base64 encoding. if value is false, secret would not be used and input values (through –set, –values, etc.) would be used while creation of pods. | true |
| secret.name | secret name to use an already created Secret | oid-< fullname >-creds |
| secret.type | Specifies the type of the secret | opaque |
| oidPorts.ldap | Port on which Oracle Internet Directory Instance in the container should listen for LDAP Communication. | 3060 |
| oidPorts.ldaps | Port on which Oracle Internet Directory Instance in the container should listen for LDAPS Communication. |  |
| oidConfig.realmDN | BaseDN for OID Instances |  |
| oidConfig.domainName | WebLogic Domain Name | oid_domain |
| oidConfig.domainHome | WebLogic Domain Home | /u01/oracle/user_projects/domains/oid_domain |
| oidConfig.orcladminPassword | Password for orcladmin user. Value will be added to Secret and Pod(s) will use the Secret |  |
| oidConfig.dbUser | Value for login into db usually sys. Value would be added to Secret and Pod(s) would be using the Secret |  |
| oidConfig.dbPassword | dbPassword is the SYS password for the database. Value would be added to Secret and Pod(s) would be using the Secret |  |
| oidConfig.dbschemaPassword | Password for DB Schema(s) to be created by RCU. Value would be added to Secret and Pod(s) would be using the Secret |  |
| oidConfig.rcuSchemaPrefix | The schema prefix to use in the database, for example `OIDPD`. |  |
| oidConfig.rcuDatabaseURL | The database URL. Sample: <db_host.domain>:<db_port>/<service_name> |  |
| oidConfig.sleepBeforeConfig | Based on the value for this parameter, initialization/configuration of each OID additional server (oid)n would be delayed and readiness probes would be configured. This is to  make sure that OID additional servers (oid)n are initialized in sequence.  | 600 |
| oidConfig.sslwalletPassword | SSL enabled password to be used for ORAPKI |  |
| deploymentConfig.startupTime | Based on the value for this parameter, initialization/configuration of each OID additional servers (oid)n will be delayed and readiness probes would be configured. initialDelaySeconds would be configured as sleepBeforeConfig + startupTime | 480 |
| deploymentConfig.livenessProbeInitialDelay | Parameter to decide livenessProbe initialDelaySeconds | 900 |
| baseOID | Configuration for Base OID instance (oid1) |  |
| baseOID.envVarsConfigMap | Reference to ConfigMap which can contain additional environment variables to be passed on to POD for Base OID Instance |  |
| baseOID.envVars | Environment variables in Yaml Map format. This is helpful when its requried to pass environment variables through --values file. List of env variables which would not be honored from envVars map is same as list of env var names mentioned for envVarsConfigMap |  |
| additionalOID | Configuration for additional OID instances (oidN) |  |
| additionalOID.envVarsConfigMap | Reference to ConfigMap which can contain additional environment variables to be passed on to POD for additional OID Instance |  |
| additionalOID.envVars | List of env variables which would not be honored from envVars map is same as list of env var names mentioned for envVarsConfigMap |  |
| odsm | Parameters/Configurations for ODSM Deployment |  |
| odsm.adminUser | Oracle WebLogic Server Administration User |  |
| odsm.adminPassword | Password for Oracle WebLogic Server Administration User |  |
| odsm.startupTime | Expected startup time. After specified seconds readinessProbe will start | 900 |
| odsmPorts | Configuration for ODSM Ports |  |
| odsmPorts.http | ODSM HTTP Port | 7001 |
| odsmPorts.https | ODSM HTTPS Port | 7002 |
