+++
title = "Helm Chart: oid"
date = 2019-04-18T06:46:23-05:00
description=  "This document provides details of the oid Helm chart."
+++

1. [Introduction](#introduction)
1. [Deploy oid Helm Chart](#deploy-oid-helm-chart)
1. [Ingress Controller Setup](#ingress-controller-setup)
	1. [Ingress with NGINX](#ingress-with-nginx)
1. [Configuration Parameters](#configuration-parameters)

### Introduction

This Helm chart is provided for the deployment of Oracle Internet Directory instances on Kubernetes.

Based on the configuration, this chart deploys the following objects in the specified namespace of a Kubernetes cluster.

* Service Account
* Secret
* Persistent Volume and Persistent Volume Claim
* Pod(s)/Container(s) for Oracle Internet Directory Instances
* Services for interfaces exposed through Oracle Internet Directory Instances
* Ingress configuration

### Create Kubernetes Namespace

Create a Kubernetes namespace to provide a scope for other objects such as pods and services that you create in the environment. To create your namespace, issue the following command:

```
$ kubectl create ns oidns
namespace/oidns created
```

### Deploy OID Helm Chart

Create Oracle Internet Directory instances along with Kubernetes objects in a specified namespace using the `oid` Helm Chart.

The deployment can be initiated by running the following Helm command with reference to the `oid` Helm Chart, along with configuration parameters according to your environment. Before deploying the Helm chart, the namespace should be created. Objects to be created by the Helm chart will be created inside the specified namespace.

```
$ helm install --namespace <namespace> \
<Configuration Parameters> \
<deployment/release name> \
<Helm Chart Path/Name>
```

Configuration Parameters (override values in chart) can be passed on with `--set` arguments on the command line and/or with `-f / --values` arguments when referring to files.

**Note**: Example files in the sections below provide values which allow the user to override the default values provided by the Helm chart.

1. Navigate to the helm directory for OID under the working directory where the code was cloned.

2. Create a file `oidoverride.yaml` file with the following contents:

```
image:
  repository: oracle/oid
  tag: 12.2.1.4.0
  pullPolicy: IfNotPresent
oidConfig:
  realmDN: dc=oid,dc=example,dc=com
  domainName: oid_domain
  orcladminPassword: <password>
  dbUser: sys
  dbPassword: <password>
  dbschemaPassword: <password>
  rcuSchemaPrefix: OIDK8S
  rcuDatabaseURL: oiddb.example.com:1521/oiddb.example.com
  sslwalletPassword: welcome2
persistence:
  type: networkstorage
  networkstorage:
    nfs:
      path: /scratch/shared/oid_user_projects
      server: <NFS IP address >
odsm:
  adminUser: weblogic
  adminPassword: welcome3
  ```

where: `/scratch/shared/oid_user_projects` is the hostpath where the pv and pvc will be created.

3. Create the OID instances

To setup a single pod:

   ```
   helm install --namespace oidns --values oidoverride.yaml oid oid --set replicaCount=0
   ```

To setup multiple pods increase `replicaCount`:

   ```
   helm install --namespace oidns --values oidoverride.yaml oid oid --set replicaCount=2
   ```

4. Confirm that the pods and services are running:

To setup a single pod:

   ```
   kubectl get all --namespace oidns
   ```

Output should be similar to the following:

   ```
	 NAME                READY   STATUS    RESTARTS   AGE     IP             NODE         NOMINATED NODE   READINESS GATES
	 pod/oidhost1        1/1     Running   0          3h34m   10.244.0.137   myoidhost    <none>           <none>
	 pod/oidhost2        1/1     Running   0          3h34m   10.244.0.138   myoidhost    <none>           <none>
	 pod/oidhost3        1/1     Running   0          3h34m   10.244.0.136   myoidhost    <none>           <none>

	 NAME                        TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                               AGE     SELECTOR
	 service/oid-lbr-ldap        ClusterIP   10.103.103.151   <none>        3060/TCP,3131/TCP                     3h34m   app.kubernetes.io/instance=oid,app.kubernetes.io/name=oid
	 service/oidhost1            ClusterIP   10.108.25.249    <none>        3060/TCP,3131/TCP,7001/TCP,7002/TCP   3h34m   app.kubernetes.io/instance=oid,app.kubernetes.io/name=oid,oid/instance=oidhost1
	 service/oidhost2            ClusterIP   10.99.99.62      <none>        3060/TCP,3131/TCP                     3h34m   app.kubernetes.io/instance=oid,app.kubernetes.io/name=oid,oid/instance=oidhost2
	 service/oidhost3            ClusterIP   10.107.13.174    <none>        3060/TCP,3131/TCP                     3h34m   app.kubernetes.io/instance=oid,app.kubernetes.io/name=oid,oid/instance=oidhost3
   ```

#### Examples

##### Example where configuration parameters are passed with `--set` argument:

```
$ helm install --namespace oidns \
--set oidConfig.rootUserPassword=Oracle123,persistence.filesystem.hostPath.path=/scratch/shared/oid_user_projects \
oid oid
```

* For more details about the `helm` command and parameters, please execute `helm --help` and `helm install --help`.<br>
* In this example, it is assumed that the command is executed from the directory containing the 'oid' helm chart directory (`OracleInternetDirectory/kubernetes/helm/`).

##### Example where configuration parameters are passed with `--values` argument:

```
$ helm install --namespace oidns \
--values oid-values-override.yaml \
oid oid
```

* For more details about the `helm` command and parameters, please execute `helm --help` and `helm install --help`.<br>
* In this example, it is assumed that the command is executed from the directory containing the 'oid' helm chart directory (`OracleInternetDirectory/kubernetes/helm/`).
* The `--values` argument passes a file path/name which overrides values in the chart.

`oid-values-override.yaml`
```
image:
  repository: oracle/oid
  tag: 12.2.1.4.0
  pullPolicy: IfNotPresent
oidConfig:
  realmDN: dc=oid,dc=example,dc=com
  domainName: oid_domain
  orcladminPassword: <password>
  dbUser: sys
  dbPassword: <password>
  dbschemaPassword: <password>
  rcuSchemaPrefix: OIDK8S
  rcuDatabaseURL: oiddb.example.com:1521/oiddb.example.com
  sslwalletPassword: welcome2
persistence:
  type: filesystem
  filesystem:
    hostPath:
      path: /scratch/shared/oid_user_projects
odsm:
  adminUser: weblogic
  adminPassword: welcome3
```

#### Example to scale-up through Helm Chart based deployment:

In this example, we are setting replicaCount value to 3. If initially, the replicaCount value was 2, we will observe a new Oracle Internet Directory pod with assosiated services brought up by Kubernetes. So overall, 4 pods will be running now.

We have two ways to achieve our goal:

```
$ helm upgrade --namespace oidns \
--set replicaCount=3 \
oid oid
```

OR

```
$ helm upgrade --namespace oidns \
--values oid-values-override.yaml \
oid oid
```

oid-values-override.yaml
```yaml
replicaCount: 3
```

* For more details about the `helm` command and parameters, please execute `helm --help` and `helm install --help`.<br>
* In this example, it is assumed that the command is executed from the directory containing the 'oid' helm chart directory (`OracleInternetDirectory/kubernetes/helm/`).

#### Example to apply new Oracle Internet Directory patch through Helm Chart based deployment:

In this example, we will apply PSU2020July-20200730 patch on earlier running Oracle Internet Directory version. If we `describe pod` we will observe that the container is up with new version.

We have two ways to achieve our goal:

```
$ helm upgrade --namespace oidns \
--set image.repository=oracle/oid,image.tag=12.2.1.4.0-PSU2020July-20200730 \
oid oid --reuse-values
```

OR

```
$ helm upgrade --namespace oidns \
--values oid-values-override.yaml \
oid oid
```

* For more details about the `helm` command and parameters, please execute `helm --help` and `helm install --help`.<br>
* In this example, it is assumed that the command is executed from the directory containing the 'oid' helm chart directory (`OracleInternetDirectory/kubernetes/helm/`).

oid-values-override.yaml
```yaml
image:
  repository: oracle/oid
  tag: 12.2.1.4.0-PSU2020July-20200730
```

##### Example for using NFS as PV Storage:

```
$ helm install --namespace oidns \
--values oid-values-override-nfs.yaml \
oid oid
```

* For more details about the `helm` command and parameters, please execute `helm --help` and `helm install --help`.<br>
* In this example, it is assumed that the command is executed from the directory containing the 'oid' helm chart directory (`OracleInternetDirectory/kubernetes/helm/`).
* The `--values` argument passes a file path/name which overrides values in the chart.

`oid-values-override-nfs.yaml`

```
image:
  repository: oracle/oid
  tag: 12.2.1.4.0
  pullPolicy: IfNotPresent
oidConfig:
  realmDN: dc=oid,dc=example,dc=com
  domainName: oid_domain
  orcladminPassword: <password>
  dbUser: sys
  dbPassword: <password>
  dbschemaPassword: <password>
  rcuSchemaPrefix: OIDK8S
  rcuDatabaseURL: oiddb.example.com:1521/oiddb.example.com
  sslwalletPassword: welcome2
persistence:
  type: networkstorage
  networkstorage:
    nfs:
      path: /scratch/shared/oid_user_projects
      server: <NFS IP address >
odsm:
  adminUser: weblogic
  adminPassword: welcome3
```

##### Example for using PV type of your choice:

```
$ helm install --namespace oidns \
--values oid-values-override-pv-custom.yaml \
oid oid
```

* For more details about the `helm` command and parameters, please execute `helm --help` and `helm install --help`.<br>
* In this example, it is assumed that the command is executed from the directory containing the 'oid' helm chart directory (`OracleInternetDirectory/kubernetes/helm/`).
* The `--values` argument passes a file path/name which overrides values in the chart.

`oid-values-override-pv-custom.yaml`

```
oidConfig:
  rootUserPassword: Oracle123
persistence:
  type: custom
  custom:
    nfs:
      # Path of NFS Share location
      path: /scratch/shared/oid_user_projects
      # IP of NFS Server
      server: <NFS IP address >
```

* Under `custom:`, the configuration of your choice can be specified. This configuration will be used 'as-is' for the PersistentVolume object.

#### Check Deployment

##### Output for the `helm install/upgrade` command

Output similar to the following is observed following successful execution of `helm install/upgrade` command.

    NAME: oid
    LAST DEPLOYED: Tue Mar 31 01:40:05 2020
    NAMESPACE: oidns
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None

##### Check for the status of objects created through oid helm chart

Command:

```
$ kubectl --namespace oidns get all
```

Output is similar to the following:

```
NAME                READY   STATUS    RESTARTS   AGE     IP             NODE         NOMINATED NODE   READINESS GATES
pod/oidhost1   1/1     Running   0          3h34m   10.244.0.137   myoidhost    <none>           <none>
pod/oidhost2   1/1     Running   0          3h34m   10.244.0.138   myoidhost    <none>           <none>
pod/oidhost3   1/1     Running   0          3h34m   10.244.0.136   myoidhost    <none>           <none>

NAME                        TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                               AGE     SELECTOR
service/oid-lbr-ldap        ClusterIP   10.103.103.151   <none>        3060/TCP,3131/TCP                     3h34m   app.kubernetes.io/instance=oid,app.kubernetes.io/name=oid
service/oidhost1            ClusterIP   10.108.25.249    <none>        3060/TCP,3131/TCP,7001/TCP,7002/TCP   3h34m   app.kubernetes.io/instance=oid,app.kubernetes.io/name=oid,oid/instance=oidhost1
service/oidhost2            ClusterIP   10.99.99.62      <none>        3060/TCP,3131/TCP                     3h34m   app.kubernetes.io/instance=oid,app.kubernetes.io/name=oid,oid/instance=oidhost2
service/oidhost3            ClusterIP   10.107.13.174    <none>        3060/TCP,3131/TCP                     3h34m   app.kubernetes.io/instance=oid,app.kubernetes.io/name=oid,oid/instance=oidhost3
```

##### Kubernetes Objects

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

### Ingress Controller Setup

There are two types of Ingress controllers supported by this Helm chart. In the sub-sections below, configuration steps for each Controller are described.

By default Ingress configuration only supports HTTP and HTTPS Ports/Communication. To allow LDAP and LDAPS communication over TCP, additional configuration is required at Ingress Controller/Implementation level.

#### Ingress with NGINX

Nginx-ingress controller implementation can be deployed/installed in a Kubernetes environment.

##### Create a Kubernetes Namespace

Create a Kubernetes namespace to provide a scope for NGINX objects such as pods and services that you create in the environment. To create your namespace, issue the following command:

```
$ kubectl create ns mynginx
namespace/mynginx created
```

##### Command `helm install` to install nginx-ingress related objects like pod, service, deployment, etc.

Add repository reference to Helm for retrieving/installing Chart for nginx-ingress implementation.

```
$ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
```

To install and configure NGINX Ingress issue the following command:

```
$ helm install --namespace mynginx \
--values nginx-ingress-values-override.yaml \
lbr-nginx \
ingress-nginx/ingress-nginx \
--version=3.34.0 \
--set controller.admissionWebhooks.enabled=false
```
Where:
* `lbr-nginx` is your deployment name
* `ingress-nginx/ingress-nginx` is the chart reference

* For more details about the `helm` command and parameters, please execute `helm --help` and `helm install --help`.<br>
* The `--values` argument passes a file path/name which overrides values in the chart.

Output will be something like this:

```
NAME: lbr-nginx
LAST DEPLOYED: Thu Aug 26 20:05:41 2021
NAMESPACE: mynginx
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The ingress-nginx controller has been installed.
Get the application URL by running these commands:
  export HTTP_NODE_PORT=$(kubectl --namespace mynginx get services -o jsonpath="{.spec.ports[0].nodePort}" lbr-nginx-ingress-nginx-controller)
  export HTTPS_NODE_PORT=$(kubectl --namespace mynginx get services -o jsonpath="{.spec.ports[1].nodePort}" lbr-nginx-ingress-nginx-controller)
  export NODE_IP=$(kubectl --namespace mynginx get nodes -o jsonpath="{.items[0].status.addresses[1].address}")

  echo "Visit http://$NODE_IP:$HTTP_NODE_PORT to access your application via HTTP."
  echo "Visit https://$NODE_IP:$HTTPS_NODE_PORT to access your application via HTTPS."

An example Ingress that makes use of the controller:

  apiVersion: networking.k8s.io/v1beta1
  kind: Ingress
  metadata:
    annotations:
      kubernetes.io/ingress.class: nginx
    name: example
    namespace: foo
  spec:
    rules:
      - host: www.example.com
        http:
          paths:
            - backend:
                serviceName: exampleService
                servicePort: 80
              path: /
    # This section is only required if TLS is to be enabled for the Ingress
    tls:
```


nginx-ingress-values-override.yaml

```
# Configuration for additional TCP ports to be exposed through Ingress
# Format for each port would be like:
# <PortNumber>: <Namespace>/<Service>
tcp:
  # Map 1389 TCP port to LBR LDAP service to get requests handled through any available POD/Endpoint serving LDAP Port
  3060: oidns/oid-lbr-ldap:3060
  # Map 1636 TCP port to LBR LDAP service to get requests handled through any available POD/Endpoint serving LDAPS Port
  3131: oidns/oid-lbr-ldap:3131
  3061: oidns/oidhost1:3060
  3130: oidns/oidhost1:3131
  3062: oidns/oidhost2:3060
  3132: oidns/oidhost2:3131
  3063: oidns/oidhost3:3060
  3133: oidns/oidhost3:3131
  3064: oidns/oidhost4:3060
  3134: oidns/oidhost4:3131
  3065: oidns/oidhost5:3060
  3135: oidns/oidhost5:3131
controller:
  admissionWebhooks:
    enabled: false
  extraArgs:
    # The secret referred to by this flag contains the default certificate to be used when accessing the catch-all server.
    # If this flag is not provided NGINX will use a self-signed certificate.
    # If the TLS Secret is in different namespace, name can be mentioned as <namespace>/<tlsSecretName>
    default-ssl-certificate: oidns/oid-tls-cert
  service:
    # controller service external IP addresses
    # externalIPs:
    #   - < External IP Address >
    # To configure Ingress Controller Service as LoadBalancer type of Service
    # Based on the Kubernetes configuration, External LoadBalancer would be linked to the Ingress Controller Service
    type: NodePort
    # Configuration for NodePort to be used for Ports exposed through Ingress
    # If NodePorts are not defied/configured, Node Port would be assigend automatically by Kubernetes
    # These NodePorts are helpful while accessing services directly through Ingress and without having External Load Balancer.
    # nodePorts:
      # For HTTP Interface exposed through LoadBalancer/Ingress
      # http: 30080
      # For HTTPS Interface exposed through LoadBalancer/Ingress
      # https: 30443
      #tcp:
        # For LDAP Interface
        # 3060: 31389
        # For LDAPS Interface
        # 3131: 31636
```

* The configuration above assumes that you have `oid` installed with value `oid` as a deployment/release name.
* Based on the deployment/release name in your environment, TCP port mapping may be required to be changed/updated.

List the ports mapped using the following command:

```
$ kubectl get all -n mynginx
NAME                                                      READY   STATUS    RESTARTS   AGE
pod/lbr-nginx-ingress-nginx-controller-8644545f5b-8dgg9   0/1     Running   0          17s

NAME                                         TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                                                                                                                AGE
service/lbr-nginx-ingress-nginx-controller   NodePort   10.107.39.198   <none>        80:30450/TCP,443:32569/TCP,3060:30395/TCP,3061:30518/TCP,3062:32540/TCP,3130:32086/TCP,3131:31794/TCP,3132:31089/TCP   17s

NAME                                                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/lbr-nginx-ingress-nginx-controller   0/1     1            0           17s

NAME                                                            DESIRED   CURRENT   READY   AGE
replicaset.apps/lbr-nginx-ingress-nginx-controller-8644545f5b   1         1         0       17s
```

##### Validate Service

Use an LDAP client to connect to the Oracle Internet Directory service, the Oracle `ldapbind` client for example:

```
$ORACLE_HOME//bin/ldapbind -D cn=orcladmin -w welcome1 -h <hostname_ingress> -p 30395
```

where:

* -p 30395 : is the port mapping to the LDAP port 3060 (3060:30395)
* -h <hostname_ingress> : is the hostname where the ingress is running

Access Oracle Directory Services Manager (ODSM) via a browser using the service port which maps to HTTPS port 443, in this case 32569 (`443:32569` from the previous `kubectl` command). Access the following:

* Oracle WebLogic Server Administration Console    : https://oid.example.com:32569/console

  When prompted, enter the following credentials from your oidoverride.yaml file.

  * Username: [adminUser]
  * Password: [adminPassword]

* Oracle Directory Services Manager : https://oid.example.com:32569/odsm

  Select Create a New Connection and, when prompted, enter the following values.

  * Server: oid.example.com
  * Port: Ingress mapped port for LDAP or LDAPS, in the example above `3060:30395/TCP` or `3131:31794/TCP`, namely LDAP:30395, LDAPS:31794
  * SSL Enabled: select if accessing LDAPS.
  * User Name: cn=orcladmin
  * Password: value of `orcladminPassword` from your oidoverride.yaml file.

### Configuration Parameters


The following table lists the configurable parameters of the `oid` chart and its default values.

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
