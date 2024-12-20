# Deploying Oracle SOA Suite on Kubernetes

> **Note**: The page is applicable for Oracle SOA Suite 14.1.2.0.0

This page walks you through the steps required to deploy Oracle SOA Suite on a Kubernetes cluster along with the dependent charts using [Helmfile](https://github.com/helmfile/helmfile). At a high level, the Helmfile will perform the following tasks using the Helm charts from local or remote charts:
- Installs the Oracle Database required for the domain:
    - Installs the [certificate manager](https://cert-manager.io/docs/installation/helm/#installing-with-helm) required for Oracle Database Operator.
    - Installs the [Oracle Database Operator](https://github.com/oracle/oracle-database-operator).
    - Creates the [Oracle Single Instance Database](https://github.com/oracle/oracle-database-operator/blob/main/docs/sidb/README.md).
- Installs the [WebLogic Kubernetes Operator](https://oracle.github.io/weblogic-kubernetes-operator/managing-operators/installation/#install-the-operator).
- Deploys the Oracle SOA Suite Domain.
- Installs the ingress-based load balancers such as Traefik or NGINX.
- Sets up the path-based routing [ingresses](https://github.com/oracle/fmw-kubernetes/blob/master/OracleSOASuite/kubernetes/charts/ingress-per-domain/README.md#configuration) for application URL access.
- Triggers various events during deployment using [Helmfile Hooks](https://helmfile.readthedocs.io/en/latest/#hooks):
  - Labeling for using default domain [namespace management](https://oracle.github.io/weblogic-kubernetes-operator/managing-operators/namespace-management/) of WebLogic Kubernetes Operator.
  - Wait for the domain to be up and running.
  - Collect domain pod logs after successful domain deployment.
  - Back-up domain home during deleting the domain deployment.

## Prepare for installation
### System and software requirements

The same resource [sizing](https://docs.oracle.com/en/middleware/soa-suite/soa/14.1.2/soakn/domain-resource-sizing.html) and [prerequistes](https://docs.oracle.com/en/middleware/soa-suite/soa/14.1.2/soakn/requirements-and-pricing.html#GUID-EDFD7254-AE5B-4984-BCF6-771DFCF2FE83__GUID-595FBF13-A588-45E2-ACFB-3D3FCF09A931) needed for an Oracle SOA Suite domains can be used here.

- These are the versions of the tools required for deploying Oracle SOA Suite domain:
    - **kubectl** (>= 1.24) : See [here](https://kubernetes.io/docs/tasks/tools/#kubectl) for the installation instructions.
    - **Helm** (>= 3.10.2): Helm is a Kubernetes deployment package manager. See [here](https://helm.sh/docs/intro/install) to install helm locally.
    - **Helmfile** (>= 0.156.0): Helmfile is a declarative spec for managing multiple Helm charts. See [here](https://helmfile.readthedocs.io/en/latest/#installation) to install the helmfile.
- If your environment doesn’t already have a Kubernetes setup, then see [set up Kubernetes](https://docs.oracle.com/en/middleware/soa-suite/soa/14.1.2/soakn/set-your-kubernetes-cluster.html#GUID-9BA68049-C94D-4ED4-A8D4-416BDE35E683).
- To deploy SOA review the [system requirements](https://docs.oracle.com/en/middleware/soa-suite/soa/14.1.2/soakn/requirements-and-pricing.html#GUID-EDFD7254-AE5B-4984-BCF6-771DFCF2FE83__GUID-595FBF13-A588-45E2-ACFB-3D3FCF09A931) to ensure that your Kubernetes cluster supports the deploy of Oracle SOA Suite domains.

### Software prerequistes

To deploy this chart, you will need:
- Oracle SOA Suite container image and details to pull the image.
- Shared path or Network File Server (NFS) and mount point accessible from within your cluster for Domain home which will be shared accross the servers.
- Oracle Database details:
    - Container image and pull access details, in case you intend to create the Database for this set up. This charts creates the [Oracle Single Instance Database](https://github.com/oracle/oracle-database-operator/blob/main/docs/sidb/README.md).
    - In case you are already having the required Database set up, then have the connection string details and credentials for performing Repository Creation Utility (RCU) schema creation.
    - In case you are creating the Oracle Single Instance Database on Kubernetes, a Kubernetes [storage classes](https://kubernetes.io/docs/concepts/storage/storage-classes/) or [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) details. For example, to use NFS for Database persistence storage, you need to use an [external provisioner](https://kubernetes.io/docs/concepts/storage/storage-classes/#nfs) to create a StorageClass for NFS and Kubernetes doesn't include an internal NFS provisioner.

### Get access to Oracle SOA Suite and Database Image
If you are using the Oracle SOA Suite image from the Oracle Container Registry, then you must accept the terms of use for this image before using the chart, or it will fail to pull the image from registry.

- At https://container-registry.oracle.com, search for *SOA*.
- Click **soasuite**.
- Click to accept the License terms and condition on the right.
- Fill in your information (if you haven't already).
- Accept the License.

If you intend on deploying the Database within the Kubernetes cluster, you must agree to the terms of the Oracle database Docker image:

- At https://container-registry.oracle.com, search for *Database*.
- Click **Enterprise**.
- Click to accept the License terms and condition on the right.
- Fill in your information (if you haven't already).
Accept the License.

### Create a Secret with your Oracle Container Registry Credentials
If the Oracle SOA Suite and/or Oracle Database images requires credentials to be pulled during deploying, create the secrets in Domain namespace and Database namespace as below:

By default we will be deploying SOA Domain in `soans` and Database on `dbns` namespace. Change the name according to your needs.

We're creating a docker registry login credential secret named `image-secret` in `soans`. Pass this name to `domain.imagePullSecrets` in `values.yaml`:

```
$ kubectl create namespace soans
$ kubectl -n soans create secret docker-registry image-secret \
  --docker-server=container-registry.oracle.com \
  --docker-username=<Oracle Container Registry login email> \
  --docker-password=<Oracle Container Registry login password> \
  --docker-email=<Oracle Container Registry login email>
```

Next, we are creating a docker registry login credential secret named `image-secret` in `dbns`. Pass this name to `oracledb.imagePullSecrets` in `values.yaml`:

```
$ kubectl create namespace dbns
$ kubectl -n dbns create secret docker-registry image-secret \
  --docker-server=container-registry.oracle.com \
  --docker-username=<Oracle Container Registry login email> \
  --docker-password=<Oracle Container Registry login password> \
  --docker-email=<Oracle Container Registry login email>
```

### Create Secret's for Oracle Single Instance Database
1. Create the secret for the SYS, SYSTEM and PDBADMIN users of the Single Instance Database. Pass this secret name to `oracledb.credentials.secretName` in `values.yaml`. By default Database namespace is `dbns`, change the name according to your needs.

    ```
    $ kubectl -n dbns create secret generic db-admin-secret \
      --from-literal=username=SYS \
      --from-literal=password=<specify password here>
    ```
2. Create the same secret in Domain namespace. Note to use the **same** secret name as the same will be used by Domain from `oracledb.credentials.secretName` in `values.yaml`. By default Domain namespace is `soans`, change the name according to your needs.

    ```
    $ kubectl -n soans create secret generic db-admin-secret \
      --from-literal=username=SYS \
      --from-literal=password=<specify password here>
    ```

### Create a Secret for WebLogic Administration credentails
Create the secret for the `weblogic` user. Pass this secret name to `domain.credentials.secretName` in `values.yaml`:

The default Domain namespace is `soans`, change the name according to your needs.

```
$ kubectl -n soans create secret generic wls-admin-secret \
        --from-literal=username=weblogic \
        --from-literal=password=<specify password here>
```

### Create a Secret for Repository Creation Utility (RCU) credentails for Schemas
Create the secret for the schema prefix. Pass this secret name to `domain.rcuSchema.credentials.secretName` in `values.yaml`:

The default Domain namespace is `soans` and schema prefix is `SOA`, change the name according to your needs.

```
$ kubectl -n soans create secret generic rcu-secret \
        --from-literal=username=SOA \
        --from-literal=password=<specify password here>
```

## Installation
### Get helmfile charts
1. Create a working directory for the helm charts:
    ```
    $ mkdir $HOME/soa_X.X.X
    $ cd $HOME/soa_X.X.X
    ```
1. Clone the [fmw-kubernetes](https://github.com/oracle/fmw-kubernetes) repository.

> **Note** - We will refer the internal repository here. Finally when release steps will be updated to refer to external GitHub.
```
$ git clone https://github.com/oracle/fmw-kubernetes.git
$ export WORKDIR_HELM=$HOME/fmw-kubernetes/OracleSOASuite/helm-charts
```

### Update the chart values
The default values for Oracle SOA Suite domain deployment are available at `$WORKDIR_HELM/values.yaml`.

Update the values of Helm charts required for deploying Oracle SOA Suite on Kubernetes:

#### values.yaml
| Key | Type | Default | Description |
| :-----| :-----: | :----- | :----- |
|`timeout` | integer | `3600` |The wait time in seconds for complete operation.|
|`domain` | [Domain values](#domain-values)| |The values for Oracle SOA Suite domain creation |
|`oracledb` | [Oracle Single Instance Database values](#oracle-single-instance-database-values) | |The values for Oracle Single Instance Database |
|`dboperator` | [Oracle Database Operator Values](#oracle-database-operator-values) | | The values for Oracle Database Operator|
|`certmanager`| [Certificate Manager Values](#certificate-manager-values)| |The values for certification manager |
|`wlsoperator` |[WebLogic Kubernetes Operator values](#weblogic-kubernetes-operator-values) | | The values for WebLogic Kubernetes Operator |
|`loadbalancer` |[Loadbalancer Values](#load-balancer-values) | |The values for Load balancer set up |
|`nginx` | [NGINX ingress controller values](#nginx-controller-helm-chart-default-values)| | The values for NGINX controller. This will be used when `loadbalancer.type` is set to `NGINX` |
|`traefik` | [TRAEFIK ingress controller values](#traefik-controller-helm-chart-default-values) | |The values for TRAEFIK ingress controller. This will be used when `loadbalancer.type` is set to `TRAEFIK` |
|||||

#### Domain values

| Key | Type | Default | Description |
| :-----| :-----: | :----- | :----- |
|`provision` | Boolean | `true` |Set `false` to uninstall soa domain release on sync|
|`namespace`|String|`soans`||
|`release_name` | String | `soadomain` | |
|`type`|String|`soaosb`|Type of the domain. Mandatory input for Oracle SOA Suite domains. You must provide one of the supported domain type values: soa (deploys a SOA domain with Enterprise Scheduler (ESS)), osb (deploys an Oracle Service Bus domain), and soaosb (deploys a domain with SOA, Oracle Service Bus, and Enterprise Scheduler (ESS)).|
|`domainName`|String|`soainfra`|Unique ID that will be used to identify this particular domain. Used as the name of the generated WebLogic Server domain as well as the name of the Kubernetes domain resource. This ID must be unique across all domains in a Kubernetes cluster. This ID cannot contain any character that is not valid in a Kubernetes service name.|
|`productionMode`|Boolean|`true`||
|`secureEnabled`|Boolean|`true`||
|`credentials.secretName`|String|||
|`credentials.username`|String|`weblogic`| WebLogic Administration username|
|`credentials.password`|String|`Welcome1`|WebLogic Administration password|
|`sslEnabled`|Boolean| `true` |Boolean value that indicates whether SSL must be enabled for each WebLogic Server instance. To enable end-to-end SSL access during load balancer setup, set sslEnabled to true and also, set appropriate value for the javaOptions property as detailed in this table.|
|`javaOptions`|String|`"-Dweblogic.StdoutDebugEnabled=false -Dweblogic.ssl.Enabled=true -Dweblogic.security.SSL.ignoreHostnameVerification=true -Dweblogic.security.TrustKeyStore=DemoTrust"`|Java options for initiating the Administration Server and Managed Servers. A Java option can have references to one or more of the following predefined variables to obtain WebLogic Server domain information: $(DOMAIN_NAME), $(DOMAIN_HOME), $(ADMIN_NAME), $(ADMIN_PORT), and $(SERVER_NAME). If sslEnabled is set to true, add -Dweblogic.ssl.Enabled=true -Dweblogic.security.SSL.ignoreHostnameVerification=true to allow the Managed Servers to connect to the Administration Server while booting up. In this environment, the demo certificate generated by the WebLogic Server contains a host name that is different from the runtime container’s host name.|
|`persistenceStore`|String| `jdbc`|The persistent store for ‘JMS servers’ and ‘Transaction log store’ in the domain. Valid values are jdbc, file.|
|`image.repository`|String|`container-registry.oracle.com/middleware/soasuite`||
|`image.pullPolicy`|String|`IfNotPresent`||
|`image.tag`|String|`UPDATE-ME`||
|`imagePullSecrets`||`[]`|Name of the Kubernetes secret to access the Container Registry to pull the SOA Suite Container image.|
|`rcuSchema.prefix`|| `SOA`|The schema prefix to use in the database. For example SOA. You may wish to make this the same as the domainUID in order to simplify matching domains to their RCU schemas|
|`rcuSchema.profileType`|String| `SMALL`|Oracle SOA schema profile type. Supported values for SOA_PROFILE_TYPE are SMALL, MED, and LARGE. |
|`rcuSchema.databaseType`|String| `EBR`|Type of database to which you are connecting. Supported values are ORACLE and EBR. |
|`rcuSchema.edition`|String| `'ORA$BASE'`|The edition name. This parameter is only valid if you specify type of databaseType as EBR."|
|`rcuSchema.credentials.secretName`|String|""|Name of the Kubernetes secret for the Administration Server’s user name and password.|
|`rcuSchema.credentials.username`|String|`SOA`|The schema prefix|
|`rcuSchema.credentials.password`|String|`"OraDB1_#OraDB1_#"`|The schema password|
|`storage.capacity`|String| `10Gi`|The storage capacity required for Domain Home|
|`storage.reclaimPolicy`|String| `Retain`| The reclaim policy of a PersistentVolume|
|`storage.type`|String|`hostpath`| The storage type. Can be hostpath or nfs|
|`storage.path`|String|`/scratch/k8s_dir`|Shared mount point path. Ensure that this path exists and have the ownership for 1000:0|
|`storage.nfs.server`|String|`X.X.X.X`|NFS Server IP address|
|`maxManagedServerCount`|Interger|`5`|Number of Managed Server instances to generate for the domain.|
|`admin.name`|String|`AdminServer`|Name of the Administration Server.|
|`admin.listenPort`|Integer|`7001`|Port number for the Administration Server inside the Kubernetes cluster.|
|`admin.sslListenPort`|Integer|`7002`|SSL port number of the Administration Server inside the Kubernetes cluster.|
|`admin.administrationPort`|Integer|`9002`|Administration port number of the Administration Server inside the Kubernetes cluster.|
|`admin.exposeNodePort`|Integer|`false`|Boolean value indicating if the Administration Server is exposed outside of the Kubernetes cluster.|
|`admin.nodePort`|Interger|`30701`|Port number of the Administration Server outside the Kubernetes cluster.|
|`soaCluster.name`|String|`soa_cluster`|Name of the SOA WebLogic Server cluster instance to generate for the domain. By default, the cluster name is soa_cluster. This configuration parameter is applicable only for soa and soaosb domain types.|
|`soaCluster.managedServers.count`|Integer|`1`|Number of Managed Servers to initially start for the domain.|
|`soaCluster.managedServers.name`|String|`soa_server`|Base string used to generate Managed Server names in the SOA cluster. The default value is soa_server. This configuration parameter is applicable only for soa and soaosb domain types.|
|`soaCluster.managedServers.listenPort`|Integer|`7003`|Port number for each Managed Server in the SOA cluster. This configuration parameter is applicable only for soa and soaosb domain types.|
|`soaCluster.managedServers.sslListenPort`|Integer|`7004`|SSL port number for each Managed Server in the SOA cluster. This configuration parameter is applicable only for soa and soaosb domain types.|
|`soaCluster.managedServers.administrationPort`|Integer|`9004`|Administration port number for each Managed Server in the SOA cluster. This configuration parameter is applicable only for soa and soaosb domain types.|
|`osbCluster.name`|String|`osb_cluster`|Name of the Oracle Service Bus WebLogic Server cluster instance to generate for the domain. By default, the cluster name is osb_cluster. This configuration parameter is applicable only for osb and soaosb domain types.|
|`osbCluster.managedServers.count`|Integer|`1`|Number of Managed Servers to initially start for the domain.|
|`osbCluster.managedServers.name`|String|`osb_server`|Base string used to generate Managed Server names in the Oracle Service Bus cluster. The default value is osb_server. This configuration parameter is applicable only for osb and soaosb domain types.|
|`osbCluster.managedServers.listenPort`|Integer|`8002`|SSL port number for each Managed Server in the Oracle Service Bus cluster. This configuration parameter is applicable only for osb and soaosb domain types.|
|`osbCluster.managedServers.sslListenPort`|Integer|`8003`|SSL port number for each Managed Server in the SOA cluster. This configuration parameter is applicable only for soa and soaosb domain types.|
|`osbCluster.managedServers.administrationPort`|Integer|`9007`|SSL port number for each Managed Server in the SOA cluster. This configuration parameter is applicable only for soa and soaosb domain types.|
|`rootDir`|String|`/u01/oracle/user_projects`|Path of the domain persistent volume.|
|`scriptDir`|String|`/u01/weblogic`|Mount path where the create domain scripts are located inside a pod.|
|`logHomeEnabled`|Boolean|`true`||
|`logHome`|String|`/u01/oracle/user_projects/domains/logs`|The in-pod location for the domain log, server logs, server out, and Node Manager log files. If not specified, the value is derived from the domainUID as /shared/logs/<domainUID>.|
|`includeServerOutInPodLog`|Boolean|`true`||
|`httpAccessLogInLogHome`|Boolean|`true`|Boolean value indicating if server HTTP access log files should be written to the same directory as logHome. If false, server HTTP access log files will be written to the directory specified in the WebLogic Server domain home configuration.|
|`serverStartPolicy`|String|`IfNeeded`|Determines which WebLogic Server instances will be started. Valid values are Never, IfNeeded, or AdminOnly.|
|`serviceAccount.create`|Boolean|`true`|Kubernetes Serviceaccount to be created or not|
|`serviceAccount.annotations`|object|`{}`|Kubernetes Serviceaccount annotations|
|`serviceAccount.name`|String|`""`|Kubernetes Serviceaccount name|
|||||

#### Oracle Single instance Database values

| Key | Type | Default | Description |
| -----| ----- | ----- | ----- |
|`provision` | Boolean | `true` |Set `false` to uninstall Oracle DB and is a subchart of Domain release|
|`namespaceOverride`|String|`dbns`|Namespace for Database|
|`image` |String | `container-registry.oracle.com/database/enterprise:19.3.0.0` | Database image. Supports Oracle Database Enterprise Edition (19.3.0), and later releases.|
|`imagePullSecrets`| String|`""`|Image pull secret name required for pulling Database image|
|`oracle_sid`|String|`ORCLCDB`|SID of the database|
|`oracle_pdb`|String|`ORCLPDB1`|PDB of the database|
|`oracle_characterset`|String|`AL32UTF8`|The character set to use when creating the database.|
|`oracle_edition`|String|`enterprise`|The database edition|
|`url`|String||External Database connection string. If this value is present, the Database is not provisioned|
|`credentials.secretName`|String|`""`|Secret containing Single instance Database password mapped to secretKey password|
|`credentials.username`|String|`SYS`|Single instance Database username|
|`credentials.password`|String|`"Oradoc_db1"`|Single instance Database password|
|`persistence.storageClass`|String|`nfs-client`|Provide appropriate Storage Class name|
|`persistence.size`|String|`10Gi`||
|`persistence.accessMode`|String|`"ReadWriteOnce"`||
|`persistence.volumeName`|String|`""`|The persistent volume name. The storageClass field is not required in this case, and can be left empty.|
|||||

#### Oracle Database Operator values

| Key | Type | Default | Description |
| :-----| :-----: | :----- | :----- |
|`provision` | Boolean | `true` |Set `false` to uninstall Oracle Database Operator release on sync|
|`namespace`|String|oracle-database-operator-system||
|`release_name` |String| `oracledb-operator` | |
|`version`|String|`latest`||
|||||

#### Certificate Manager values

Refer [here](https://github.com/cert-manager/cert-manager/blob/master/deploy/charts/cert-manager/values.yaml) for more configuration details.
| Key | Type | Default | Description |
| :-----| :-----: | :----- | :----- |
|`provision` | Boolean | `true` |Set `false` to uninstall Oracle Database Operator release on sync|
|`namespace`|String|`oracle-database-operator-system`||
|`release_name` |String| `oracledb-operator` | |
|`version`|String|v1.13.0||
|||||

#### WebLogic Kubernetes Operator values

Refer [here](https://github.com/oracle/weblogic-kubernetes-operator/blob/main/kubernetes/charts/weblogic-operator/values.yaml) for more configuration details.
| Key | Type | Default | Description |
| :-----| :-----: | :----- | :----- |
|`provision` | Boolean | `true` |Set `false` to uninstall WebLogic Kubernetes Operator release on sync|
|`namespace`|String|`opns`||
|`release_name` |String| `weblogic-operator` |WebLogic Kubernetes Operator release name |
|`version`|String|`4.2.9`| Refer [here](https://docs.oracle.com/en/middleware/soa-suite/soa/14.1.2/soakn/requirements-and-pricing.html#GUID-EDFD7254-AE5B-4984-BCF6-771DFCF2FE83__GUID-595FBF13-A588-45E2-ACFB-3D3FCF09A931) for supported WebLogic Kubernetes Operator version|
|`javaLoggingLevel`| String| "WARNING"| Similarly, other WebLogic Kubernetes Operator chart values can be added|
|||||

#### Load Balancer values
| Key | Type | Default | Description |
| :-----| :-----: | :----- | :----- |
|`provision` | Boolean | `true` |Set `false` to uninstall NGINIX or TRAEFIK ingress controller release on sync|
|`type` | String | `TRAEFIK` |Supported values are TRAEFIK or NGINX|
|`namespace`|String|`soalbns`| Namespace for Ingress controllers |
|`release_name` |String| soalb | Load Balancer release name |
|`sslType` |String| `SSL` | Supported values are NONSSL, SSL or E2ESSL |
|`hostname` |String| `soasuite.domain.org` | Hostname required for accessing the application URLs |
|`certCommonName` |String| `*.domain.org` | Certificate Common name for TLS secret to be used by Load Balancer |
|`e2ehostName.admin` |String| `admin.domain.org` | Hostname required for accessing the administration URLs |
|`e2ehostName.soa` |String| `soa.domain.org` | Hostname required for accessing the applications URLs on SOA cluster |
|`e2ehostName.osb` |String| `osb.domain.org` | Hostname required for accessing the application URLs on OSB cluster |
|||||

#### NGINX controller helm chart default values

Refer [here](https://github.com/kubernetes/ingress-nginx/blob/main/charts/ingress-nginx/values.yaml) for more configuration details.
| Key | Type | Default | Description |
| :-----| :-----: | :----- | :----- |
|`controller.service.type` | String | `NodePort` | NGNIX ingress controller will be provisioned with Node Port access|
|`controller.admissionWebhooks.enabled` | Boolean| `false` ||
|`conroller.allowSnippetAnnotations`|Boolean|`true`| This is required if the Snipper annotations are being used|
|||||

#### TRAEFIK controller helm chart default values

Refer [here](https://github.com/traefik/traefik-helm-chart/blob/master/traefik/values.yaml) for more configuration details.

| Key | Type | Default | Description |
| :-----| :-----: | :----- | :----- |
|`image.registry` | String | `docker.io` | Note: Added this as default for internal reference. Will be updated when published externally|
|`image.repository` | String| `traefik` | Traefik image repository details|
|`image.tag`|String|`""`| Image tag|
|`service.type`|String|`NodePort`| TRAEFIK ingress controller will be provisioned with Node Port access|
|||||

### Running Helmfile

Verify the `helmfile` version before starting the deployment:
```
$ helmfile version
```

Sample output:
```
$ helmfile version

▓▓▓ helmfile

  Version              0.157.0
  Git Commit           e7560af
  Build Date           12 Sep 23 02:12 UTC (1 month ago)
  Commit Date          09 Sep 23 14:06 UTC (1 month ago)
  Dirty Build          no
  Go version           1.21.0
  Compiler             gc
  Platform             linux/amd64
```

Run the `helmfile` interactivety to start SOA Suite deployment:
```
$ cd $WORKDIR_HELM
$ helmfile -i sync
```

Sample output:
```
$ cd $WORKDIR_HELM
$ helmfile -i sync
Adding repo weblogic-operator https://oracle.github.io/weblogic-kubernetes-operator/charts
"weblogic-operator" has been added to your repositories

Adding repo traefik https://helm.traefik.io/traefik
"traefik" has been added to your repositories

Adding repo jetstack https://charts.jetstack.io
"jetstack" has been added to your repositories


hook[prepare] logs | Missing Namespace soans creating now
hook[prepare] logs | namespace/soans created
hook[prepare] logs | namespace/soans labeled
hook[prepare] logs | Missing Namespace dbns creating now
hook[prepare] logs | namespace/dbns created
hook[prepare] logs |
Building dependency release=oracledb-operator, chart=charts/oracledb-operator
Building dependency release=soalb-ingress-per-domain, chart=charts/ingress-per-domain
Building dependency release=soadomain, chart=charts/soa-suite
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "weblogic-operator" chart repository
...Successfully got an update from the "nfs-subdir-external-provisioner" chart repository
...Successfully got an update from the "ingress-nginx" chart repository
...Successfully got an update from the "jetstack" chart repository
...Successfully got an update from the "traefik" chart repository
...Successfully got an update from the "prometheus-community" chart repository
Update Complete. ⎈Happy Helming!⎈
Saving 1 charts
Dependency oracledb did not declare a repository. Assuming it exists in the charts directory
Deleting outdated charts

Affected releases are:
  cert-manager (jetstack/cert-manager) UPDATED
  oracledb-operator (./charts/oracledb-operator) UPDATED
  soadomain (./charts/soa-suite) UPDATED
  soalb (traefik/traefik) UPDATED
  soalb-ingress-per-domain (./charts/ingress-per-domain) UPDATED
  weblogic-operator (weblogic-operator/weblogic-operator) UPDATED

Do you really want to sync?
  Helmfile will sync all your releases, as shown above.

 [y/n]: y
Upgrading release=soalb-ingress-per-domain, chart=charts/ingress-per-domain
Upgrading release=oracledb-operator, chart=charts/oracledb-operator
Upgrading release=soalb, chart=traefik/traefik
Upgrading release=weblogic-operator, chart=weblogic-operator/weblogic-operator
Release "oracledb-operator" does not exist. Installing it now.

Release "weblogic-operator" does not exist. Installing it now.
NAME: weblogic-operator
LAST DEPLOYED: Thu Oct 12 12:36:20 2023
NAMESPACE: opns
STATUS: deployed
REVISION: 1
TEST SUITE: None

Listing releases matching ^weblogic-operator$
weblogic-operator       opns            1               2023-10-12 12:36:20.669852336 +0000 UTC deployed        weblogic-operator-4.1.2 4.1.2


hook[presync] logs | customresourcedefinition.apiextensions.k8s.io/certificaterequests.cert-manager.io created
hook[presync] logs | customresourcedefinition.apiextensions.k8s.io/certificates.cert-manager.io created
hook[presync] logs | customresourcedefinition.apiextensions.k8s.io/challenges.acme.cert-manager.io created
hook[presync] logs | customresourcedefinition.apiextensions.k8s.io/clusterissuers.cert-manager.io created
hook[presync] logs | customresourcedefinition.apiextensions.k8s.io/issuers.cert-manager.io created
hook[presync] logs | customresourcedefinition.apiextensions.k8s.io/orders.acme.cert-manager.io created
hook[presync] logs |
Upgrading release=cert-manager, chart=jetstack/cert-manager
Release "soalb-ingress-per-domain" does not exist. Installing it now.
NAME: soalb-ingress-per-domain
LAST DEPLOYED: Thu Oct 12 12:36:20 2023
NAMESPACE: soans
STATUS: deployed
REVISION: 1
TEST SUITE: None

Listing releases matching ^soalb-ingress-per-domain$
soalb-ingress-per-domain        soans           1               2023-10-12 12:36:20.445804311 +0000 UTC deployed        ingress-per-domain-0.1.0        1.0

Release "soalb" does not exist. Installing it now.
NAME: soalb
LAST DEPLOYED: Thu Oct 12 12:36:21 2023
NAMESPACE: soalbns
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Traefik Proxy v2.10.4 has been deployed successfully on soalbns namespace !

Listing releases matching ^soalb$
soalb   soalbns         1               2023-10-12 12:36:21.003742334 +0000 UTC deployed        traefik-24.0.0  v2.10.4
.
.
```

### Get the status

The `helmfile status` will give the status of all the releases installed as part of `helmfile sync`.

### Managing individual release

Helmfile will add labels to each releases and one of them is the name of a release can be used as a label for mananging each releases. For example, to sync the changes for the helm release name, `soadomain`, you can execute below command:
```
$ cd $WORKDIR_HELM
$ helmfile sync --selector name=soadomain
```

## Uninstallation

To uninstall the Oracle SOA Suite domain along with all the dependent charts, execute:
```
$ cd $WORKDIR_HELM
$ helmfile destroy
```

Sample output:
```
Adding repo weblogic-operator https://oracle.github.io/weblogic-kubernetes-operator/charts
"weblogic-operator" has been added to your repositories

Adding repo traefik https://helm.traefik.io/traefik
"traefik" has been added to your repositories

Adding repo jetstack https://charts.jetstack.io
"jetstack" has been added to your repositories


hook[prepare] logs | NAME    STATUS   AGE
hook[prepare] logs | soans   Active   36m
hook[prepare] logs | Namespace soans Already exists
hook[prepare] logs | namespace/soans not labeled
hook[prepare] logs | NAME   STATUS   AGE
hook[prepare] logs | dbns   Active   36m
hook[prepare] logs | Namespace dbns Already exists
hook[prepare] logs |
Building dependency release=soalb-ingress-per-domain, chart=charts/ingress-per-domain
Building dependency release=oracledb-operator, chart=charts/oracledb-operator
Building dependency release=soadomain, chart=charts/soa-suite
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "weblogic-operator" chart repository
...Successfully got an update from the "nfs-subdir-external-provisioner" chart repository
...Successfully got an update from the "jetstack" chart repository
...Successfully got an update from the "traefik" chart repository
...Successfully got an update from the "ingress-nginx" chart repository
...Successfully got an update from the "prometheus-community" chart repository
Update Complete. ⎈Happy Helming!⎈
Saving 1 charts
Dependency oracledb did not declare a repository. Assuming it exists in the charts directory
Deleting outdated charts

Listing releases matching ^soalb-ingress-per-domain$
soalb-ingress-per-domain        soans           3               2023-10-12 13:02:41.995649789 +0000 UTC deployed        ingress-per-domain-0.1.0        1.0

Listing releases matching ^soalb$
soalb   soalbns         3               2023-10-12 13:02:42.025494299 +0000 UTC deployed        traefik-24.0.0  v2.10.4

Listing releases matching ^soadomain$
soadomain       soans           2               2023-10-12 13:02:58.385330552 +0000 UTC deployed        soa-suite-14.1.2        14.1.2

Listing releases matching ^weblogic-operator$
weblogic-operator       opns            3               2023-10-12 13:02:41.981513412 +0000 UTC deployed        weblogic-operator-4.1.2 4.1.2

Listing releases matching ^oracledb-operator$
oracledb-operator       oracle-database-operator-system 2               2023-10-12 13:02:41.702027202 +0000 UTC deployed        oracledb-operator-0.1.0 0.1.0

Listing releases matching ^cert-manager$
cert-manager    cert-manager    3               2023-10-12 13:02:42.901878501 +0000 UTC deployed        cert-manager-v1.13.0    v1.13.0


hook[preuninstall] logs | [2023-10-12T13:12:45.604742789Z][INFO] Patching domain 'soainfra' in namespace 'soans' from serverStartPolicy='IfNeeded' to 'Never'.
hook[preuninstall] logs | domain.weblogic.oracle/soainfra patched
hook[preuninstall] logs | [2023-10-12T13:12:45.712030338Z][INFO] Successfully patched domain 'soainfra' in namespace 'soans' with 'Never' start policy!
hook[preuninstall] logs |

hook[preuninstall] logs |
hook[preuninstall] logs | @@ [2023-10-12T13:12:46][seconds=1] Info: Waiting up to 1000 seconds for there to be no (0) WebLogic Server pods that match the following criteria:
hook[preuninstall] logs | @@ [2023-10-12T13:12:46][seconds=1] Info:   namespace='soans' domainUID='soainfra'
hook[preuninstall] logs | @@ [2023-10-12T13:12:46][seconds=1] Info: Failure conditions (if any): ''.
hook[preuninstall] logs |
hook[preuninstall] logs |
hook[preuninstall] logs | @@ [2023-10-12T13:12:46][seconds=1] Info: '3' WebLogic Server pods currently match all criteria.
hook[preuninstall] logs | @@ [2023-10-12T13:12:46][seconds=1] Info: Introspector and WebLogic Server pods with same namespace and domain-uid:
hook[preuninstall] logs |
hook[preuninstall] logs | NAME                    RVER  IVER  IMAGE                                                                                                     AIIMAGES  READY   PHASE
hook[preuninstall] logs | ----                    ----  ----  -----                                                                                                     --------  -----   -----
hook[preuninstall] logs | 'soainfra-adminserver'  ''    ''    'container-registry.oracle.com/middleware/soasuite:UPDATE-ME'  ''        'true'  'Running'
hook[preuninstall] logs | 'soainfra-osb-server1'  ''    ''    'container-registry.oracle.com/middleware/soasuite:UPDATE-ME'  ''        'true'  'Running'
hook[preuninstall] logs | 'soainfra-soa-server1'  ''    ''    'container-registry.oracle.com/middleware/soasuite:UPDATE-ME'  ''        'true'  'Running'
hook[preuninstall] logs |
hook[preuninstall] logs | @@ [2023-10-12T13:14:37][seconds=112] Info: '3' WebLogic Server pods currently match all criteria.
hook[preuninstall] logs | @@ [2023-10-12T13:14:37][seconds=112] Info: Introspector and WebLogic Server pods with same namespace and domain-uid:
hook[preuninstall] logs |
hook[preuninstall] logs | NAME                    RVER  IVER  IMAGE                                                                                                     AIIMAGES  READY    PHASE
hook[preuninstall] logs | ----                    ----  ----  -----                                                                                                     --------  -----    -----
hook[preuninstall] logs | 'soainfra-adminserver'  ''    ''    'container-registry.oracle.com/middleware/soasuite:UPDATE-ME'  ''        'false'  'Running'
hook[preuninstall] logs | 'soainfra-osb-server1'  ''    ''    'container-registry.oracle.com/middleware/soasuite:UPDATE-ME'  ''        'false'  'Running'
hook[preuninstall] logs | 'soainfra-soa-server1'  ''    ''    'container-registry.oracle.com/middleware/soasuite:UPDATE-ME'  ''        'true'   'Running'
hook[preuninstall] logs |
hook[preuninstall] logs | @@ [2023-10-12T13:14:39][seconds=114] Info: '3' WebLogic Server pods currently match all criteria.
hook[preuninstall] logs | @@ [2023-10-12T13:14:39][seconds=114] Info: Introspector and WebLogic Server pods with same namespace and domain-uid:
hook[preuninstall] logs |
hook[preuninstall] logs | NAME                    RVER  IVER  IMAGE                                                                                                     AIIMAGES  READY    PHASE
hook[preuninstall] logs | ----                    ----  ----  -----                                                                                                     --------  -----    -----
hook[preuninstall] logs | 'soainfra-adminserver'  ''    ''    'container-registry.oracle.com/middleware/soasuite:UPDATE-ME'  ''        'false'  'Running'
hook[preuninstall] logs | 'soainfra-osb-server1'  ''    ''    'container-registry.oracle.com/middleware/soasuite:UPDATE-ME'  ''        'false'  'Running'
hook[preuninstall] logs | 'soainfra-soa-server1'  ''    ''    'container-registry.oracle.com/middleware/soasuite:UPDATE-ME'  ''        'false'  'Running'
hook[preuninstall] logs |
hook[preuninstall] logs | @@ [2023-10-12T13:15:16][seconds=151] Info: '0' WebLogic Server pods currently match all criteria.
hook[preuninstall] logs | @@ [2023-10-12T13:15:16][seconds=151] Info: Introspector and WebLogic Server pods with same namespace and domain-uid:
hook[preuninstall] logs |
hook[preuninstall] logs | NAME  RVER  IVER  IMAGE  AIIMAGES  READY  PHASE
hook[preuninstall] logs | ----  ----  ----  -----  --------  -----  -----
hook[preuninstall] logs |
hook[preuninstall] logs |
hook[preuninstall] logs | @@ [2023-10-12T13:15:16][seconds=151] Info: Success!
hook[preuninstall] logs |

hook[preuninstall] logs | job.batch "soainfra-create-soa-infra-domain-job" deleted
hook[preuninstall] logs | job.batch "soainfra-rcu-create" deleted
hook[preuninstall] logs |
Deleting soadomain
release "soadomain" uninstalled

Deleting oracledb-operator
Deleting weblogic-operator
Deleting soalb-ingress-per-domain
Deleting cert-manager
Deleting soalb
release "soalb-ingress-per-domain" uninstalled

release "weblogic-operator" uninstalled

release "oracledb-operator" uninstalled

release "soalb" uninstalled

release "cert-manager" uninstalled


DELETED RELEASES:
NAME                       DURATION
soadomain                     4m23s
soalb-ingress-per-domain         0s
weblogic-operator                0s
oracledb-operator                0s
soalb                            1s
cert-manager                     1s

```

> **Note**: Do not use the `helmfile list` command as it does not behave as `helm list` and just lists the releases defined in the state file (helmfile.yaml).
