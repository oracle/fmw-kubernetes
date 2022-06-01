Helm Chart: oudsm: For deployment of Oracle Unified Directory Services Manager instance(s)
==========================================================================================

## Contents
1. [Introduction](#1-introduction)
2. [Deploy oudsm Helm Chart](#2-deploy-oudsm-helm-chart)
3. [Ingress Controller Setup](#3-ingress-controller-setup)
4. [Access to Interfaces through Ingress](#4-access-to-interfaces-through-ingress)
5. [Logging and Monitoring](#5-logging-and-monitoring)
6. [Configuration Parameters](#6-configuration-parameters)
7. [Copyright](#copyright)

# 1. Introduction

A Helm chart for deployment of OUDSM instances on Kubernetes. 

Based on the configuration, this chart would be deploying following objects in specified namespace of Kubernetes cluster.

* Service Account
* Secret
* Persistent Volume and Persistent Volume Claim
* Pod(s)/Container(s) for OUDSM Instances
* Services for interfaces exposed through OUDSM Instances
* Ingress configuration

# 2. Deploy oudsm Helm Chart

Create/Deploy OUDSM instances along with Kubernetes objects in specified namespace using oudsm Helm Chart. 
The deployment can be initiated by running the following Helm command with reference to oudsm Helm Chart along with configuration parameters according to your environment. Before deploying the helm chart, namespace should be created. Object to be created with helm chart would be created inside specified namespace.

    # helm install --namespace <namespace> \
        <Configuration Parameters> \
        <deployment/release name> \
        <Helm Chart Path/Name>

Configuration Parameters (override values in chart) can be passed on with `--set` arguments on command line and/or with `-f / --values` arguments referring to files.

## 2.1 Examples

### 2.1.1 Example where configuration parameters are passed with `--set` argument:

    # helm install --namespace myhelmns \
        --set oudsm.adminUser=weblogic,oudsm.adminPass=Oracle123,persistence.filesystem.hostPath.path=/scratch/shared/oudsm_user_projects \
        my-oudsm oudsm
> For more details about helm command and parameters, please execute `helm --help` and `helm install --help`.<br>
> In this example, it's assumed that the command is executed from directory containing 'oudsm' helm chart directory (OracleUnifiedDirectorySM/kubernetes/helm/).

### 2.1.2 Example where configuration parameters are passed with `--values` argument:

    # helm install --namespace myhelmns \
        --values oudsm-values-override.yaml \
        my-oudsm oudsm
> For more details about helm command and parameters, please execute `helm --help` and `helm install --help`.<br>
> In this example, it's assumed that the command is executed from directory containing 'oudsm' helm chart directory (OracleUnifiedDirectorySM/kubernetes/helm/).
> With `--values` argument, passed file path/name is to override values in chart. 

oud-rs-ds-values-override.yaml
```yaml
oudsm:
  adminUser: weblogic
  adminPass: Oracle123
persistence:
  type: filesystem
  filesystem:
    hostPath: 
      path: /scratch/shared/oudsm_user_projects
```

### 2.1.3 Example to scale-up through Helm Chart based deployment:

> For more details about helm command and parameters, please execute `helm --help` and `helm upgrade --help`.<br>
> In this example, it's assumed that the command is executed from directory containing 'oudsm' helm chart directory (OracleUnifiedDirectorySM/kubernetes/helm/).<br>

In this example, we are setting replicaCount value to 2. If initially, the replicaCount value was 1, we will observe a new OUDSM pod with assosiated services brought up by kubernetes. So overall, 2 pods will be running now.

We have two ways to achieve our goal:

    # helm upgrade --namespace myhelmns \
        --set replicaCount=2 \
        my-oudsm oudsm

OR

	# helm upgrade --namespace myhelmns \
		--values oudsm-values-override.yaml \
		my-oudsm oudsm

oud-rs-ds-values-override.yaml
```yaml
replicaCount: 2
```

### 2.1.4 Example to apply new OUD patch through Helm Chart based deployment:

> For more details about helm command and parameters, please execute `helm --help` and `helm upgrade --help`.<br>
> In this example, it's assumed that the command is executed from directory containing 'oudsm' helm chart directory (OracleUnifiedDirectorySM/kubernetes/helm/).<br>

In this example, we will apply PSU2020July-20200805 patch on earlier running OUDSM version. If we `describe pod` we will observe that the container is up with new version.

We have two ways to achieve our goal:

    # helm upgrade --namespace myhelmns \
        --set image.repository=oracle/oudsm,image.tag=12.2.1.4.0-PSU2020July-20200805 \
        my-oudsm oudsm

OR

	# helm upgrade --namespace myhelmns \
		--values oudsm-values-override.yaml \
		my-oudsm oudsm

oud-rs-ds-values-override.yaml
```yaml
image:
  repository: oracle/oudsm
  tag: 12.2.1.4.0-PSU2020July-20200805
```


### 2.1.5 Example for using NFS as PV Storage:

    # helm install --namespace myhelmns \
        --values oudsm-values-override-nfs.yaml \
        my-oudsm oudsm
> For more details about helm command and parameters, please execute `helm --help` and `helm install --help`.<br>
> In this example, it's assumed that the command is executed from directory containing 'oudsm' helm chart directory (OracleUnifiedDirectorySM/kubernetes/helm/).
> With `--values` argument, passed file path/name is to override values in chart. 

oud-rs-ds-values-override-nfs.yaml
```yaml
oudsm:
  adminUser: weblogic
  adminPass: Oracle123
persistence:
  type: networkstorage
  networkstorage:
    nfs: 
      path: /scratch/shared/oudsm_user_projects
      server: 10.10.10.12
```

### 2.1.6 Example for using PV type of your choice:

    # helm install --namespace myhelmns \
        --values oudsm-values-override-pv-custom.yaml \
        my-oudsm oudsm
> For more details about helm command and parameters, please execute `helm --help` and `helm install --help`.<br>
> In this example, it's assumed that the command is executed from directory containing 'oudsm' helm chart directory (OracleUnifiedDirectorySM/kubernetes/helm/).
> With `--values` argument, passed file path/name is to override values in chart. 

oud-rs-ds-values-override-pv-custom.yaml
```yaml
oudsm.adminUser: weblogic
adminPass: Oracle123
persistence:
  type: custom
  custom:
    nfs: 
      # Path of NFS Share location
      path: /scratch/shared/oudsm_user_projects
      # IP of NFS Server
      server: 10.10.10.12
```
> Under `custom:`, configuration of your choice can be specified. Such configuration would be used as-is for PersistentVolume object.

## 2.2 Check deployment 

### 2.2.1 Output for helm install/upgrade command

Following kind of output would be shown after successful execution of `helm install/upgrade` command.

    NAME: oudsm
    LAST DEPLOYED: Thu Oct 29 13:09:31 2020
    NAMESPACE: oudns
    STATUS: deployed
    REVISION: 1

### 2.2.2 Check for the status of objects created through oudsm helm chart

Command: 

    # kubectl --namespace myhelmns get nodes,pod,service,secret,pv,pvc,ingress -o wide

Output: 

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
	persistentvolume/oudsm-pv       30Gi       RWX            Retain           Bound    myoudsmns/oudsm-pvc     manual                  22h   Filesystem
	
	NAME                              STATUS   VOLUME     CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE
	persistentvolumeclaim/oudsm-pvc   Bound    oudsm-pv   30Gi       RWX            manual         22h   Filesystem
	
	NAME                                     HOSTS                               ADDRESS          PORTS   AGE
	ingress.extensions/oudsm-ingress-nginx   oudsm-1,oudsm-2,oudsm + 1 more...   100.102.51.230   80      19h

## 2.3 Kubernetes Objects

| **Type** | **Name** | **Example Name** | **Purpose** | 
| ------ | ------ | ------ | ------ |
| Service Account | <deployment/release name> | my-oudsm | Kubernetes Service Account for the Helm Chart deployment |
| Secret | <deployment/release name>-creds |  my-oudsm-creds | Secret object for OUD related critical values like passwords |
| Persistent Volume | <deployment/release name>-pv | my-oudsm-pv | Persistent Volume for user_projects mount. | 
| Persistent Volume Claim | <deployment/release name>-pvc | my-oudsm-pvc | Persistent Volume Claim for user_projects mount. |
| Pod | <deployment/release name>-N | my-oudsm-1, my-oudsm-2, ...  | Pod(s)/Container(s) for OUDSM Instances |
| Service | <deployment/release name>-N | my-oudsm-1, my-oudsm-2, ... | Service(s) for HTTP and HTTPS interfaces from OUDSM instance <deployment/release name>-N |
| Ingress | <deployment/release name>-ingress-nginx | my-oudsm-ingress-nginx | Ingress Rules for HTTP and HTTPS interfaces. |
> In table above, Example Name for each Object is based on value 'my-oudsm' as deployment/release name for helm chart installation.

# 3. Ingress Controller Setup

There are two types of ingress controllers supported through this helm chart. In the sub-sections below, configuration steps for each Controller are described.

## 3.1 nginx-ingress

Nginx-ingress controller implementation can be deployed/installed in Kubernetes environment.

### Add Repo reference to helm for retriving/installing Chart for nginx-ingress implementation.

    # helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

### Command `helm install` to install nginx-ingress related objects like pod, service, deployment, etc.

    # helm install --namespace ingressns \
        --values nginx-ingress-values-override.yaml
        lbr-nginx ingress-nginx/ingress-nginx
> For more details about helm command and parameters, please execute `helm --help` and `helm install --help`.<br>
> With `--values` argument, passed file path/name is to override values in chart. 

nginx-ingress-values-override.yaml
```yaml
controller:
  admissionWebhooks:
    enabled: false
  extraArgs:
    # The secret referred to by this flag contains the default certificate to be used when accessing the catch-all server.
    # If this flag is not provided NGINX will use a self-signed certificate.
    # If the TLS Secret is in different namespace, name can be mentioned as <namespace>/<tlsSecretName>
    default-ssl-certificate=myhelmns/my-oud-ds-rs-tls-cert
  service:
    # controller service external IP addresses
    externalIPs:
      - < External IP Address >
    # To configure Ingress Controller Service as LoadBalancer type of Service
    # Based on the Kubernetes configuration, External LoadBalancer would be linked to the Ingress Controller Service
    type: LoadBalancer
    # Configuration for NodePort to be used for Ports exposed through Ingress
    # If NodePorts are not defied/configured, Node Port would be assigend automatically by Kubernetes
    # These NodePorts are helpful while accessing services directly through Ingress and without having External Load Balancer.
    nodePorts:
      # For HTTP Interface exposed through LoadBalancer/Ingress
      http: 30080
      # For HTTPS Interface exposed through LoadBalancer/Ingress
      https: 30443
```

> For more details about helm command and parameters, please execute `helm --help` and `helm install --help`.

# 4. Access to Interfaces through Ingress

With the helm chart, Ingress objects are also created according to configuration. Following are the rules configured in Ingress object(s) for access to OUD Interfaces through Ingress.

| **Port** | **NodePort** | **Host** | **Example Hostname** | **Path** | **Backend Service:Port** | **Example Service Name:Port** | 
| ------ | ------ | ------ | ------ | ------ | ------ | ------ |  
| http/https | 30080/30443 | <deployment/release name>-N | my-oudsm-N | * | <deployment/release name>-N:http | my-oudsm-1:http | 
| http/https | 30080/30443 | * | * | /oudsm<br> /console| <deployment/release name>-lbr:http | my-oudsm-lbr:http | 
> In table above, Example Values are based on value 'my-oudsm' as deployment/release name for helm chart installation.<br>
> NodePort mentioned in the table are according to Ingress configuration described in previous section. <br>
> When External LoadBalancer is not available/configured, Interfaces can be accessed through NodePort on Kubernetes Node.

## 4.1 Changes in /etc/hosts to validate hostname based Ingress rules

In case, its not possible for you to have LoadBalancer configuration updated to have host names added for OUD Interfaces, following kind of entries can be added in /etc/hosts files on host from where OUD interfaces would be accessed. 

```text
<IP Address of External LBR or Kubernetes Node>	my-oudsm my-oudsm-1 my-oudsm-2 my-oudsm-N
```
> In table above, host names are based on value 'my-oudsm' as deployment/release name for helm chart installation.<br>
> When External LoadBalancer is not available/configured, Interfaces can be accessed through NodePort on Kubernetes Node.

# 5. Logging and Monitoring

## 5.1. Logging

For Logging, OUD will be integrating ELK stack.The ELK stack consists of Elasticsearch, Logstash, and Kibana. Using ELK we can gain insights in real-time from the log data from your applications.


**Elasticsearch** is a distributed, RESTful search and analytics engine capable of solving a growing number of use cases. As the heart of the Elastic Stack, it centrally stores your data so you can discover the expected and uncover the unexpected.

**Logstash** is an open source, server-side data processing pipeline that ingests data from a multitude of sources simultaneously, transforms it, and then sends it to your favorite “stash.”

**Kibana** lets you visualize your Elasticsearch data and navigate the Elastic Stack. It gives you the freedom to select the way you give shape to your data. And you don’t always have to know what you're looking for.

### 5.1.1. Values.yaml Configurations to enable ELK stack 

    # elk:
        enabled: true
    
This configuration will enable the ELK stack integration with OUDSM.

### 5.1.2. Prepare a host directory to be used for Filesystem based PersistentVolume for Elastic Search

It's required to prepare directory on Host filesystem to store Elastic Search Instances and other configuration outside container filesystem. That directory from host filesystem would be associated with PersistentVolume.
In case of multi-node Kubernetes cluster, directory to be associated with PersistentVolume should be accessible on all the nodes at the same path.

To prepare a host directory (for example: /scratch/test/oudsm_elk/data ) for mounting as file system based PersistentVolume inside containers, execute the command below on host:

> The userid can be anything but it must belong to uid:guid as 1000:1000, which is same as 'oracle' user running in the container.
> This ensures 'oracle' user has access to shared volume/directory.

```
sudo su - root
mkdir -p /scratch/test/oudsm_elk/data
chown 1000:1000 /scratch/test/oudsm_elk/data
exit
```
All container operations are performed as **'oracle'** user.

**Note**: If a user already exist with **'-u 1000 -g 1000'** then use the same user. Or modify any existing user to have uid-gid as **'-u 1000 -g 1000'**

### 5.1.3. Deploy oudsm Helm Chart

Create/Deploy a group of replicated OUDSM instances along with ELK stack Kubernetes objects in specified namespace using oudsm Helm Chart. 
The deployment can be initiated by running the following Helm command with reference to oudsm Helm Chart along with configuration parameters according to your environment. Before deploying the helm chart, namespace should be created. Object to be created with helm chart would be created inside specified namespace.

    # helm install --namespace <namespace> \
        <Configuration Parameters> \
        <deployment/release name> \
        <Helm Chart Path/Name>
        

### 5.1.4 Output for helm install/upgrade command

Following kind of output would be shown after successful execution of `helm install/upgrade` command.

	#NAME: myoudsm
	 LAST DEPLOYED: Fri Sep 18 18:34:01 2020
	 NAMESPACE: oudns
	 STATUS: deployed
	 REVISION: 1
	 TEST SUITE: None

### 5.1.5 Check for the status of objects created through oudsm helm chart

```
NAME                                    READY   STATUS    RESTARTS   AGE     IP            NODE                     NOMINATED NODE   READINESS GATES
pod/myoudsm-1                           1/1     Running   0          7m57s   10.244.0.85   adcaa712.us.oracle.com   <none>           <none>
pod/myoudsm-es-cluster-0                1/1     Running   0          7m54s   10.244.0.88   adcaa712.us.oracle.com   <none>           <none>
pod/myoudsm-es-cluster-1                1/1     Running   0          7m44s   10.244.0.89   adcaa712.us.oracle.com   <none>           <none>
pod/myoudsm-es-cluster-2                1/1     Running   0          7m35s   10.244.0.90   adcaa712.us.oracle.com   <none>           <none>
pod/myoudsm-kibana-768855db67-nsg7k     1/1     Running   0          7m56s   10.244.0.87   adcaa712.us.oracle.com   <none>           <none>
pod/myoudsm-logstash-588cdc686d-p74qk   1/1     Running   0          7m56s   10.244.0.86   adcaa712.us.oracle.com   <none>           <none>

NAME                               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE     SELECTOR
service/myoudsm-1                  ClusterIP   10.101.54.79     <none>        7001/TCP,7002/TCP   7m58s   app.kubernetes.io/instance=myoudsm,app.kubernetes.io/name=oudsm,oudsm/instance=myoudsm-1
service/myoudsm-elasticsearch      ClusterIP   None             <none>        9200/TCP,9300/TCP   7m58s   app=myoudsm-elasticsearch
service/myoudsm-kibana             NodePort    10.108.206.150   <none>        5601:31199/TCP      7m58s   app=kibana
service/myoudsm-lbr                ClusterIP   10.110.199.78    <none>        7001/TCP,7002/TCP   7m58s   app.kubernetes.io/instance=myoudsm,app.kubernetes.io/name=oudsm
service/myoudsm-logstash-service   NodePort    10.101.88.161    <none>        9600:30360/TCP      7m58s   app=logstash

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS         IMAGES                                  SELECTOR
deployment.apps/myoudsm-kibana     1/1     1            1           7m56s   kibana             docker.elastic.co/kibana/kibana:6.4.3   app=kibana
deployment.apps/myoudsm-logstash   1/1     1            1           7m56s   myoudsm-logstash   logstash:6.6.0                          app=logstash

NAME                                          DESIRED   CURRENT   READY   AGE     CONTAINERS         IMAGES                                  SELECTOR
replicaset.apps/myoudsm-kibana-768855db67     1         1         1       7m56s   kibana             docker.elastic.co/kibana/kibana:6.4.3   app=kibana,pod-template-hash=768855db67
replicaset.apps/myoudsm-logstash-588cdc686d   1         1         1       7m56s   myoudsm-logstash   logstash:6.6.0                          app=logstash,pod-template-hash=588cdc686d

NAME                                  READY   AGE     CONTAINERS      IMAGES
statefulset.apps/myoudsm-es-cluster   3/3     7m54s   elasticsearch   docker.elastic.co/elasticsearch/elasticsearch:6.4.3

NAME                                     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                             STORAGECLASS                       REASON   AGE    VOLUMEMODE
persistentvolume/myoud-oud-ds-rs-pv      20Gi       RWX            Retain           Bound    ouddemo/myoud-oud-ds-rs-pvc       manual                                      25h    Filesystem
persistentvolume/myoudsm-espv1           20Gi       RWX            Retain           Bound    oudns/data-myoudsm-es-cluster-0   elk                                         8m2s   Filesystem
persistentvolume/myoudsm-espv2           20Gi       RWX            Retain           Bound    oudns/data-myoudsm-es-cluster-2   elk                                         8m2s   Filesystem
persistentvolume/myoudsm-espv3           20Gi       RWX            Retain           Bound    oudns/data-myoudsm-es-cluster-1   elk                                         8m2s   Filesystem
persistentvolume/myoudsm-pv              20Gi       RWX            Retain           Bound    oudns/myoudsm-pvc                 manual                                      8m2s   Filesystem
persistentvolume/oam-cluster-domain-pv   10Gi       RWX            Retain           Bound    accessns/oam-cluster-domain-pvc   oam-cluster-domain-storage-class            2d2h   Filesystem

NAME                                              STATUS   VOLUME          CAPACITY   ACCESS MODES   STORAGECLASS   AGE     VOLUMEMODE
persistentvolumeclaim/data-myoudsm-es-cluster-0   Bound    myoudsm-espv1   20Gi       RWX            elk            7m54s   Filesystem
persistentvolumeclaim/data-myoudsm-es-cluster-1   Bound    myoudsm-espv3   20Gi       RWX            elk            7m44s   Filesystem
persistentvolumeclaim/data-myoudsm-es-cluster-2   Bound    myoudsm-espv2   20Gi       RWX            elk            7m35s   Filesystem
persistentvolumeclaim/myoudsm-pvc                 Bound    myoudsm-pv      20Gi       RWX            manual         8m      Filesystem

```
    
# 6. Configuration Parameters

The following table lists the configurable parameters of the OUDSM chart and their default values.

| **Parameter** | **Description** | **Default Value** |
| ------------- | --------------- | ----------------- |
| replicaCount  | Number of OUDSM instances/pods/services to be created | 1 |
| restartPolicyName | restartPolicy to be configured for each POD containing OUDSM instance | OnFailure |
| image.repository | OUDSM Image Registry/Repository and name. Based on this, image parameter would be configured for OUDSM pods/containers | oracle/oud |
| image.tag | OUDSM Image Tag. Based on this, image parameter would be configured for OUDSM pods/containers | 12.2.1.4.0 |
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
| ingress.type | Supported value: nginx  | 
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
| elk.enabled | If enabled it will create the elk stack integrated with OUDSM | false |
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
| elk.kibana.image.repository | Kibana Image Registry/Repository and name. Based on this Kibana instance will be created  | docker.elastic.co/kibana/kibana |
| elk.kibana.image.tag | Kibana Image tag. Based on this, Image parameter would be configured. | 6.4.3 |
| elk.kibana.image.pullPolicy | policy to pull the image | IfnotPresent |
| elk.kibana.kibanaReplicas | Number of Kibana instances will be created | 1 |
| elk.kibana.service.tye | Type of service to be created | NodePort |
| elk.kibana.service.targetPort | Port on which the kibana will be accessed | 5601 |
| elk.kibana.service.nodePort | nodePort is the port on which kibana service will be accessed from outside | 31119 |
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
| elk.elkVolume.pvname | pvname to use an already created Persistent Volume , If blank will use the default name | oud-ds-rs-< fullname >-espv |
| elk.elkVolume.type | supported values: either filesystem or networkstorage or custom | filesystem |
| elk.elkVolume.filesystem.hostPath.path | The path location mentioned should be created and accessible from the local host provided with necessary privileges for the user. | /scratch/shared/oud_elk/data |
| elk.elkVolume.networkstorage.nfs.path | Path of NFS Share location  | /scratch/shared/oud_elk/data |
| elk.elkVolume.networkstorage.nfs.server | IP or hostname of NFS Server  | 0.0.0.0 |
| elk.elkVolume.custom.* | Based on values/data, YAML content would be included in PersistenceVolume Object |  |
| elk.elkVolume.accessMode | Specifies the access mode of the location provided | ReadWriteMany |
| elk.elkVolume.size  | Specifies the size of the storage | 20Gi |
| elk.elkVolume.storageClass | Specifies the storageclass of the persistence volume. | elk |
| elk.elkVolume.annotations | specifies any annotations that will be used| { } |

# Copyright
Copyright (c) 2020, 2022, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
