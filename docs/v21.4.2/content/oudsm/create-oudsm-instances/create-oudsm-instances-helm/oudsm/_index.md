+++
title = "Helm Chart: oudsm: For deployment of Oracle Unified Directory Services Manager instances on Kubernetes"
date = 2019-04-18T06:46:23-05:00
description=  "This document provides details of the oudsm Helm chart."
+++

1. [Introduction](#introduction)
1. [Create Kubernetes Namespace](#create-kubernetes-namespace)
1. [Deploy oudsm Helm Chart](#deploy-oudsm-helm-chart)
1. [Verify the Installation](#verify-the-installation)
1. [Ingress Controller Setup](#ingress-controller-setup)
	1. [Ingress with NGINX](#ingress-with-nginx)
1. [Access to Interfaces through Ingress](#access-to-interfaces-through-ingress)
1. [Configuration Parameters](#configuration-parameters)

### Introduction

This Helm chart provides for the deployment of replicated Oracle Unified Directory Services Manager instances on Kubernetes.

Based on the configuration, this chart deploys the following objects in the specified namespace of a Kubernetes cluster.

* Service Account
* Secret
* Persistent Volume and Persistent Volume Claim
* Pod(s)/Container(s) for Oracle Unified Directory Services Manager Instances
* Services for interfaces exposed through Oracle Unified Directory Services Manager Instances
* Ingress configuration

### Create Kubernetes Namespace

Create a Kubernetes namespace to provide a scope for other objects such as pods and services that you create in the environment. To create your namespace issue the following command:

```
$ kubectl create ns oudns
namespace/oudns created
```


### Deploy oudsm Helm Chart

Create/Deploy Oracle Unified Directory Services Manager instances along with Kubernetes objects in a specified namespace using the `oudsm` Helm Chart.

The deployment can be initiated by running the following Helm command with reference to the `oudsm` Helm Chart, along with configuration parameters according to your environment. Before deploying the Helm chart, the namespace should be created. Objects to be created by the Helm chart will be created inside the specified namespace.

```
cd <work directory>/fmw-kubernetes/OracleUnifiedDirectorySM/kubernetes/helm
$ helm install --namespace <namespace> \
<Configuration Parameters> \
<deployment/release name> \
<Helm Chart Path/Name>
```

Configuration Parameters (override values in chart) can be passed on with `--set` arguments on the command line and/or with `-f / --values` arguments when referring to files.

#### Examples

##### Example where configuration parameters are passed with `--set` argument:

```
$ helm install --namespace oudns \
--set oudsm.adminUser=weblogic,oudsm.adminPass=Oracle123,persistence.filesystem.hostPath.path=/scratch/shared/oudsm_user_projects,image.repository=oracle/oudsm,image.tag=12.2.1.4.0-PSU2020July-20200730 \
oudsm oudsm
```

* For more details about the `helm` command and parameters, please execute `helm --help` and `helm install --help`.
* In this example, it is assumed that the command is executed from the directory containing the 'oudsm' helm chart directory (`OracleUnifiedDirectorySM/kubernetes/helm/`).

##### Example where configuration parameters are passed with `--values` argument:

```
$ helm install --namespace oudns \
--values oudsm-values-override.yaml \
oudsm oudsm
```

* For more details about the `helm` command and parameters, please execute `helm --help` and `helm install --help`.
* In this example, it is assumed that the command is executed from the directory containing the 'oudsm' helm chart directory (`OracleUnifiedDirectorySM/kubernetes/helm/`).
* The `--values` argument passes a file path/name which overrides default values in the chart. 

`oudsm-values-override.yaml`
```
oudsm:
  adminUser: weblogic
  adminPass: Oracle123
persistence:
  type: filesystem
  filesystem:
    hostPath: 
      path: /scratch/shared/oudsm_user_projects
```

##### Example to update/upgrade Helm Chart based deployment:

```
$ helm upgrade --namespace oudns \
--set oudsm.adminUser=weblogic,oudsm.adminPass=Oracle123,persistence.filesystem.hostPath.path=/scratch/shared/oudsm_user_projects,replicaCount=2 \
oudsm oudsm
```
* For more details about the `helm` command and parameters, please execute `helm --help` and `helm install --help`.
* In this example, it is assumed that the command is executed from the directory containing the 'oudsm' helm chart directory (`OracleUnifiedDirectorySM/kubernetes/helm/`).

##### Example to apply new Oracle Unified Directory Services Manager patch through Helm Chart based deployment:

In this example, we will apply PSU2020July-20200730 patch on earlier running Oracle Unified Directory Services Manager version. If we `describe pod` we will observe that the container is up with new version.

We have two ways to achieve our goal:

```
$ helm upgrade --namespace oudns \
--set image.repository=oracle/oudsm,image.tag=12.2.1.4.0-PSU2020July-20200730 \
oudsm oudsm
```

OR

```
$ helm upgrade --namespace oudns \
--values oudsm-values-override.yaml \
oudsm oudsm
```
		
* For more details about the `helm` command and parameters, please execute `helm --help` and `helm install --help`.<br>
* In this example, it is assumed that the command is executed from the directory containing the 'oudsm' helm chart directory (`OracleUnifiedDirectorySM/kubernetes/helm/`).

`oudsm-values-override.yaml`

```yaml
image:
  repository: oracle/oudsm
  tag: 12.2.1.4.0-PSU2020July-20200730
```

##### Example for using NFS as PV Storage:

```
$ helm install --namespace oudns \
--values oudsm-values-override-nfs.yaml \
oudsm oudsm
```

* For more details about the `helm` command and parameters, please execute `helm --help` and `helm install --help`.
* In this example, it is assumed that the command is executed from the directory containing the 'oudsm' helm chart directory (`OracleUnifiedDirectorySM/kubernetes/helm/`).
* The `--values` argument passes a file path/name which overrides values in the chart. 

`oudsm-values-override-nfs.yaml`

```
oudsm:
  adminUser: weblogic
  adminPass: Oracle123
persistence:
  type: networkstorage
  networkstorage:
    nfs: 
      path: /scratch/shared/oud_user_projects
      server: <NFS IP address>
```

##### Example for using PV type of your choice:

```
$ helm install --namespace oudns \
--values oudsm-values-override-pv-custom.yaml \
oudsm oudsm
```

* For more details about the `helm` command and parameters, please execute `helm --help` and `helm install --help`.
* In this example, it is assumed that the command is executed from the directory containing the 'oudsm' helm chart directory (`OracleUnifiedDirectorySM/kubernetes/helm/`).
* The `--values` argument passes a file path/name which overrides values in the chart.

`oudsm-values-override-pv-custom.yaml`

```
oudsm:
  adminUser: weblogic
  adminPass: Oracle123
persistence:
  type: custom
  custom:
    nfs: 
      # Path of NFS Share location
      path: /scratch/shared/oudsm_user_projects
      # IP of NFS Server
      server: <NFS IP address>
```

> Under `custom:`, the configuration of your choice can be specified. This configuration will be used 'as-is' for the PersistentVolume object.

#### Check Deployment 

##### Output for the `helm install/upgrade` command

Ouput similar to the following is observed following successful execution of `helm install/upgrade` command.

```
NAME: oudsm
LAST DEPLOYED: Wed Oct 14 06:22:10 2020
NAMESPACE: oudns
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

##### Check for the status of objects created through oudsm helm chart

Command: 

```
$ kubectl --namespace oudns get nodes,pod,service,secret,pv,pvc,ingress -o wide
```

Output is similar to the following: 

```
NAME          READY   STATUS    RESTARTS   AGE   IP            NODE             NOMINATED NODE   READINESS GATES
pod/oudsm-1   1/1     Running   0          22h   10.244.0.19   100.102.51.238   <none>           <none>
pod/oudsm-2   1/1     Running   0          22h   10.244.0.20   100.102.51.238   <none>           <none>
	
NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE   SELECTOR
service/oudsm-1     ClusterIP   10.96.108.200   <none>        7001/TCP,7002/TCP   22h   app.kubernetes.io/instance=oudsm,app.kubernetes.io/name=oudsm,oudsm/instance=oudsm-1
service/oudsm-2     ClusterIP   10.96.96.12     <none>        7001/TCP,7002/TCP   22h   app.kubernetes.io/instance=oudsm,app.kubernetes.io/name=oudsm,oudsm/instance=oudsm-2
service/oudsm-lbr   ClusterIP   10.96.41.201    <none>        7001/TCP,7002/TCP   22h   app.kubernetes.io/instance=oudsm,app.kubernetes.io/name=oudsm
	
NAME                                 TYPE                                  DATA   AGE
secret/default-token-w4jft           kubernetes.io/service-account-token   3      32d
secret/oudsm-creds                   opaque                                2      22h
secret/oudsm-token-ksr4g             kubernetes.io/service-account-token   3      22h
secret/sh.helm.release.v1.oudsm.v1   helm.sh/release.v1                    1      22h
secret/sh.helm.release.v1.oudsm.v2   helm.sh/release.v1                    1      21h
secret/sh.helm.release.v1.oudsm.v3   helm.sh/release.v1                    1      19h
	
NAME                            CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                   STORAGECLASS   REASON   AGE   VOLUMEMODE
persistentvolume/oudsm-pv       30Gi       RWX            Retain           Bound    myoudns/oudsm-pvc     manual                  22h   Filesystem

NAME                              STATUS   VOLUME     CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE
persistentvolumeclaim/oudsm-pvc   Bound    oudsm-pv   30Gi       RWX            manual         22h   Filesystem

NAME                                     HOSTS                               ADDRESS          PORTS   AGE
ingress.extensions/oudsm-ingress-nginx   oudsm-1,oudsm-2,oudsm + 1 more...   100.102.51.230   80      19h
```

##### Kubernetes Objects

Kubernetes objects created by the Helm chart are detailed in the table below:

| **Type** | **Name** | **Example Name** | **Purpose** | 
| ------ | ------ | ------ | ------ |
| Service Account | <deployment/release name> | oudsm | Kubernetes Service Account for the Helm Chart deployment |
| Secret | <deployment/release name>-creds |  oudsm-creds | Secret object for Oracle Unified Directory Services Manager related critical values like passwords |
| Persistent Volume | <deployment/release name>-pv | oudsm-pv | Persistent Volume for user_projects mount. | 
| Persistent Volume Claim | <deployment/release name>-pvc | oudsm-pvc | Persistent Volume Claim for user_projects mount. |
| Pod | <deployment/release name>-N | oudsm-1, oudsm-2, ...  | Pod(s)/Container(s) for Oracle Unified Directory Services Manager Instances |
| Service | <deployment/release name>-N | oudsm-1, oudsm-2, ... | Service(s) for HTTP and HTTPS interfaces from Oracle Unified Directory Services Manager instance <deployment/release name>-N |
| Ingress | <deployment/release name>-ingress-nginx | oudsm-ingress-nginx | Ingress Rules for HTTP and HTTPS interfaces. |

* In the table above, the Example Name for each Object is based on the value 'oudsm' as the deployment/release name for the Helm chart installation.

### Verify the Installation

### Ingress Controller Setup

There are two types of Ingress controllers supported by this Helm chart. In the sub-sections below, configuration steps for each Controller are described.

By default Ingress configuration only supports HTTP and HTTPS Ports/Communication. To allow LDAP and LDAPS communication over TCP, configuration is required at Ingress Controller/Implementation level.

#### Ingress with NGINX

Nginx-ingress controller implementation can be deployed/installed in Kubernetes environment.

##### Create a Kubernetes Namespace

Create a Kubernetes namespace to provide a scope for NGINX objects such as pods and services that you create in the environment. To create your namespace issue the following command:

```
$ kubectl create ns mynginx
namespace/mynginx created
```

##### Add Repo reference to helm for retriving/installing Chart for nginx-ingress implementation.

```
$ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
```

Confirm the charts available by issuing the following command:

```
$ helm search repo | grep nginx
ingress-nginx/ingress-nginx     4.0.1           1.0.0          Ingress controller for Kubernetes using NGINX a...
stable/ingress-nginx            4.0.1           1.0.0          Ingress controller for Kubernetes using NGINX a...
```

##### Command `helm install` to install nginx-ingress related objects like pod, service, deployment, etc.


```
$ helm install --namespace default \
--values nginx-ingress-values-override.yaml \
lbr-nginx ingress-nginx/ingress-nginx --version=3.34.0
```

* For more details about the `helm` command and parameters, please execute `helm --help` and `helm install --help`.
* The `--values` argument passes a file path/name which overrides values in the chart.

`nginx-ingress-values-override.yaml`

```
controller:
  admissionWebhooks:
    enabled: false
  extraArgs:
    # The secret referred to by this flag contains the default certificate to be used when accessing the catch-all server.
    # If this flag is not provided NGINX will use a self-signed certificate.
    # If the TLS Secret is in different namespace, name can be mentioned as <namespace>/<tlsSecretName>
    default-ssl-certificate=oudns/oudsm-tls-cert
  service:
    # controller service external IP addresses
    externalIPs:
      - < External IP Address >
    # To configure Ingress Controller Service as LoadBalancer type of Service
    # Based on the Kubernetes configuration, External LoadBalancer would be linked to the Ingress Controller Service
    type: LoadBalancer
    # Configuration for NodePort to be used for Ports exposed through Ingress
    # If NodePorts are not defined/configured, Node Port would be assigned automatically by Kubernetes
    # These NodePorts are helpful while accessing services directly through Ingress and without having External Load Balancer.
    nodePorts:
      # For HTTP Interface exposed through LoadBalancer/Ingress
      http: 30080
      # For HTTPS Interface exposed through LoadBalancer/Ingress
      https: 30443
```

### Access to Interfaces through Ingress

With the helm chart, Ingress objects are also created according to configuration. Following are the rules configured in Ingress object(s) for access to Oracle Unified Directory Services Manager Interfaces through Ingress.

| **Port** | **NodePort** | **Host** | **Example Hostname** | **Path** | **Backend Service:Port** | **Example Service Name:Port** | 
| ------ | ------ | ------ | ------ | ------ | ------ | ------ |  
| http/https | 30080/30443 | <deployment/release name>-N | oudsm-N | * | <deployment/release name>-N:http | oudsm-1:http | 
| http/https | 30080/30443 | * | * | /oudsm<br> /console| <deployment/release name>-lbr:http | oudsm-lbr:http | 

* In the table above, the Example Name for each Object is based on the value 'oudsm' as the deployment/release name for the Helm chart installation.
* NodePort mentioned in the table are according to Ingress configuration described in previous section.
* When an External LoadBalancer is not available/configured, Interfaces can be accessed through NodePort on the Kubernetes Node.

#### Changes in /etc/hosts to validate hostname based Ingress rules

In case, its not possible for you to have LoadBalancer configuration updated to have host names added for Oracle Unified Directory Services Manager Interfaces, following kind of entries can be added in /etc/hosts files on host from where Oracle Unified Directory Services Manager interfaces would be accessed. 

```
<IP Address of External LBR or Kubernetes Node>	oudsm oudsm-1 oudsm-2 oudsm-N
```

* In the table above, the Example Name for each Object is based on the value 'oudsm' as the deployment/release name for the Helm chart installation.
* When an External LoadBalancer is not available/configured, Interfaces can be accessed through NodePort on the Kubernetes Node.

### Configuration Parameters

The following table lists the configurable parameters of the Oracle Unified Directory Services Manager chart and their default values.

| **Parameter** | **Description** | **Default Value** |
| ------------- | --------------- | ----------------- |
| replicaCount  | Number of Oracle Unified Directory Services Manager instances/pods/services to be created | 1 |
| restartPolicyName | restartPolicy to be configured for each POD containing Oracle Unified Directory Services Manager instance | OnFailure |
| image.repository | Oracle Unified Directory Services Manager Image Registry/Repository and name. Based on this, image parameter would be configured for Oracle Unified Directory Services Manager pods/containers | oracle/oudsm |
| image.tag | Oracle Unified Directory Services Manager Image Tag. Based on this, image parameter would be configured for Oracle Unified Directory Services Manager pods/containers | 12.2.1.4.0 |
| image.pullPolicy | policy to pull the image | IfnotPresent |
| imagePullSecrets.name | name of Secret resource containing private registry credentials | regcred |
| nameOverride | override the fullname with this name | |
| fullnameOverride | Overrides the fullname with the provided string | |
| serviceAccount.create  | Specifies whether a service account should be created | true |
| serviceAccount.name | If not set and create is true, a name is generated using the fullname template | oudsm-< fullname >-token-< randomalphanum > |
| podSecurityContext | Security context policies to add to the controller pod | |
| securityContext | Security context policies to add by default | |
| service.type | type of controller service to create | ClusterIP |
| nodeSelector | node labels for pod assignment | |
| tolerations | node taints to tolerate  | |
| affinity | node/pod affinities  | |
| ingress.enabled | | true | 
| ingress.type | Supported value: nginx | nginx | 
| ingress.host | Hostname to be used with Ingress Rules. <br>If not set, hostname would be configured according to fullname. <br> Hosts would be configured as < fullname >-http.< domain >, < fullname >-http-0.< domain >, < fullname >-http-1.< domain >, etc. | |
| ingress.domain | Domain name to be used with Ingress Rules. <br>In ingress rules, hosts would be configured as < host >.< domain >, < host >-0.< domain >, < host >-1.< domain >, etc. | |
| ingress.backendPort | | http |
| ingress.nginxAnnotations | | { <br>kubernetes.io/ingress.class: "nginx"<br> nginx.ingress.kubernetes.io/affinity-mode: "persistent" <br> nginx.ingress.kubernetes.io/affinity: "cookie" <br>}|
| ingress.ingress.tlsSecret | Secret name to use an already created TLS Secret. If such secret is not provided, one would be created with name < fullname >-tls-cert. If the TLS Secret is in different namespace, name can be mentioned as < namespace >/< tlsSecretName > | |
| ingress.certCN | Subject's common name (cn) for SelfSigned Cert. | < fullname > |
| ingress.certValidityDays | Validity of Self-Signed Cert in days | 365 |
| secret.enabled | If enabled it will use the secret created with base64 encoding. if value is false, secret would not be used and input values (through --set, --values, etc.) would be used while creation of pods. | true|
| secret.name | secret name to use an already created Secret | oudsm-< fullname >-creds |
| secret.type | Specifies the type of the secret | Opaque |
| persistence.enabled | If enabled, it will use the persistent volume. if value is false, PV and PVC would not be used and pods would be using the default emptyDir mount volume. | true |
| persistence.pvname | pvname to use an already created Persistent Volume , If blank will use the default name | oudsm-< fullname >-pv |
| persistence.pvcname | pvcname to use an already created Persistent Volume Claim , If blank will use default name  |oudsm-< fullname >-pvc |
| persistence.type | supported values: either filesystem or networkstorage or custom | filesystem |
| persistence.filesystem.hostPath.path | The path location mentioned should be created and accessible from the local host provided with necessary privileges for the user. | /scratch/shared/oudsm_user_projects |
| persistence.networkstorage.nfs.path | Path of NFS Share location  | /scratch/shared/oudsm_user_projects |
| persistence.networkstorage.nfs.server | IP or hostname of NFS Server  | 0.0.0.0 |
| persistence.custom.* | Based on values/data, YAML content would be included in PersistenceVolume Object |  |
| persistence.accessMode | Specifies the access mode of the location provided | ReadWriteMany |
| persistence.size  | Specifies the size of the storage | 10Gi |
| persistence.storageClass | Specifies the storageclass of the persistence volume. | empty |
| persistence.annotations | specifies any annotations that will be used | { } |
| oudsm.adminUser | Weblogic Administration User | weblogic |
| oudsm.adminPass | Password for Weblogic Administration User |  |
| oudsm.startupTime | Expected startup time. After specified seconds readinessProbe would start | 900 |
| oudsm.livenessProbeInitialDelay | Paramter to decide livenessProbe initialDelaySeconds | 1200
| elk.elasticsearch.enabled | If enabled it will create the elastic search statefulset deployment | false |
| elk.elasticsearch.image.repository | Elastic Search Image name/Registry/Repository . Based on this elastic search instances will be created | docker.elastic.co/elasticsearch/elasticsearch |
| elk.elasticsearch.image.tag | Elastic Search Image tag .Based on this, image parameter would be configured for Elastic Search pods/instances | 6.4.3 |
| elk.elasticsearch.image.pullPolicy | policy to pull the image | IfnotPresent |
| elk.elasticsearch.esreplicas | Number of Elastic search Instances will be created | 3 |
| elk.elasticsearch.minimumMasterNodes | The value for discovery.zen.minimum_master_nodes. Should be set to (esreplicas / 2) + 1. | 2 |
| elk.elasticsearch.esJAVAOpts | Java options for Elasticsearch. This is where you should configure the jvm heap size | -Xms512m -Xmx512m |
| elk.elasticsearch.sysctlVmMaxMapCount | Sets the sysctl vm.max_map_count needed for Elasticsearch | 262144 |
| elk.elasticsearch.resources.requests.cpu | cpu resources requested for the elastic search | 100m |
| elk.elasticsearch.resources.limits.cpu | total cpu limits that are configures for the elastic search | 1000m |
| elk.elasticsearch.esService.type | Type of Service to be created for elastic search | ClusterIP |
| elk.elasticsearch.esService.lbrtype | Type of load balancer Service to be created for elastic search | ClusterIP |
| elk.kibana.enabled | If enabled it will create a kibana deployment | false |
| elk.kibana.image.repository | Kibana Image Registry/Repository and name. Based on this Kibana instance will be created  | docker.elastic.co/kibana/kibana |
| elk.kibana.image.tag | Kibana Image tag. Based on this, Image parameter would be configured. | 6.4.3 |
| elk.kibana.image.pullPolicy | policy to pull the image | IfnotPresent |
| elk.kibana.kibanaReplicas | Number of Kibana instances will be created | 1 |
| elk.kibana.service.tye | Type of service to be created | NodePort |
| elk.kibana.service.targetPort | Port on which the kibana will be accessed | 5601 |
| elk.kibana.service.nodePort | nodePort is the port on which kibana service will be accessed from outside | 31119 |
| elk.logstash.enabled | If enabled it will create a logstash deployment | false |
| elk.logstash.image.repository | logstash Image Registry/Repository and name. Based on this logstash instance will be created  | logstash |
| elk.logstash.image.tag | logstash Image tag. Based on this, Image parameter would be configured. | 6.6.0 |
| elk.logstash.image.pullPolicy | policy to pull the image | IfnotPresent |
| elk.logstash.containerPort | Port on which the logstash container will be running  | 5044 |
| elk.logstash.service.tye | Type of service to be created | NodePort |
| elk.logstash.service.targetPort | Port on which the logstash will be accessed | 9600 |
| elk.logstash.service.nodePort | nodePort is the port on which logstash service will be accessed from outside | 32222 |
| elk.logstash.logstashConfigMap | Provide the configmap name which is already created with the logstash conf. if empty default logstash configmap will be created and used | |
| elk.elkPorts.rest | Port for REST | 9200 |
| elk.elkPorts.internode | port used for communication between the nodes | 9300 |
| elk.busybox.image | busy box image name. Used for initcontianers | busybox |
| elk.elkVolume.enabled | If enabled, it will use the persistent volume. if value is false, PV and pods would be using the default emptyDir mount volume. | true |
| elk.elkVolume.pvname | pvname to use an already created Persistent Volume , If blank will use the default name | oudsm-< fullname >-espv |
| elk.elkVolume.type | supported values: either filesystem or networkstorage or custom | filesystem |
| elk.elkVolume.filesystem.hostPath.path | The path location mentioned should be created and accessible from the local host provided with necessary privileges for the user. | /scratch/shared/oud_elk/data |
| elk.elkVolume.networkstorage.nfs.path | Path of NFS Share location  | /scratch/shared/oud_elk/data |
| elk.elkVolume.networkstorage.nfs.server | IP or hostname of NFS Server  | 0.0.0.0 |
| elk.elkVolume.custom.* | Based on values/data, YAML content would be included in PersistenceVolume Object |  |
| elk.elkVolume.accessMode | Specifies the access mode of the location provided | ReadWriteMany |
| elk.elkVolume.size  | Specifies the size of the storage | 20Gi |
| elk.elkVolume.storageClass | Specifies the storageclass of the persistence volume. | elk |
| elk.elkVolume.annotations | specifies any annotations that will be used| { } |
