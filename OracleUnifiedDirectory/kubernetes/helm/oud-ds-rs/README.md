Helm Chart: oud-ds-rs: For deployment of replicated OUD (DS+RS) instances
=========================================================================

## Contents
1. [Introduction](#1-introduction)
2. [Deploy oud-ds-rs Helm Chart](#2-deploy-oud-ds-rs-helm-chart)
3. [Verify the Replication](#3-verify-the-replication)
4. [Ingress Controller Setup](#4-ingress-controller-setup)
5. [Access to Interfaces through Ingress](#5-access-to-interfaces-through-ingress)
6. [Logging and Monitoring](#6-logging-and-monitoring)
7. [Configuration Parameters](#7-configuration-parameters)
8. [Copyright](#copyright)

# 1. Introduction

A Helm chart for deployment of replicated OUD (DS+RS) instances on Kubernetes. 
This chart can be used to deploy an OUD instance as base with configured sample entries and multiple replicated OUD instances/pods/services based on the specified replicaCount.

Based on the configuration, this chart would be deploying following objects in specified namespace of Kubernetes cluster.

* Service Account
* Secret
* Persistent Volume and Persistent Volume Claim
* Pod(s)/Container(s) for OUD Instances
* Services for interfaces exposed through OUD Instances
* Ingress configuration

# 2. Deploy oud-ds-rs Helm Chart

Create/Deploy a group of replicated OUD instances along with Kubernetes objects in specified namespace using oud-ds-rs Helm Chart. 
The deployment can be initiated by running the following Helm command with reference to oud-ds-rs Helm Chart along with configuration parameters according to your environment. Before deploying the helm chart, namespace should be created. Object to be created with helm chart would be created inside specified namespace.

    # helm install --namespace <namespace> \
        <Configuration Parameters> \
        <deployment/release name> \
        <Helm Chart Path/Name>

Configuration Parameters (override values in chart) can be passed on with `--set` arguments on command line and/or with `-f / --values` arguments referring to files.

## 2.1 Examples

### 2.1.1 Example where configuration parameters are passed with `--set` argument:

    # helm install --namespace myhelmns \
        --set oudConfig.rootUserPassword=Oracle123,persistence.filesystem.hostPath.path=/scratch/shared/oud_user_projects \
        my-oud-ds-rs oud-ds-rs
> For more details about helm command and parameters, please execute `helm --help` and `helm install --help`.<br>
> In this example, it's assumed that the command is executed from directory containing 'oud-ds-rs' helm chart directory (OracleUnifiedDirectory/kubernetes/helm/).

### 2.1.2 Example where configuration parameters are passed with `--values` argument:

    # helm install --namespace myhelmns \
        --values oud-ds-rs-values-override.yaml \
        my-oud-ds-rs oud-ds-rs
> For more details about helm command and parameters, please execute `helm --help` and `helm install --help`.<br>
> In this example, it's assumed that the command is executed from directory containing 'oud-ds-rs' helm chart directory (OracleUnifiedDirectory/kubernetes/helm/).
> With `--values` argument, passed file path/name is to override values in chart. 

oud-rs-ds-values-override.yaml
```yaml
oudConfig:
  rootUserPassword: Oracle123
persistence:
  type: filesystem
  filesystem:
    hostPath: 
      path: /scratch/shared/oud_user_projects
```

### 2.1.3 Example to scale-up through Helm Chart based deployment:

> For more details about helm command and parameters, please execute `helm --help` and `helm upgrade --help`.<br>
> In this example, it's assumed that the command is executed from directory containing 'oud-ds-rs' helm chart directory (OracleUnifiedDirectory/kubernetes/helm/).<br>

In this example, we are setting replicaCount value to 3. If initially, the replicaCount value was 2, we will observe a new OUD pod with assosiated services brought up by kubernetes. So overall, 4 pods will be running now.

We have two ways to achieve our goal:

    # helm upgrade --namespace myhelmns \
        --set replicaCount=3 \
        my-oud-ds-rs oud-ds-rs

OR

	# helm upgrade --namespace myhelmns \
		--values oud-ds-rs-values-override.yaml \
		my-oud-ds-rs oud-ds-rs

oud-rs-ds-values-override.yaml
```yaml
replicaCount: 3
```

### 2.1.4 Example to apply new OUD patch through Helm Chart based deployment:

> For more details about helm command and parameters, please execute `helm --help` and `helm upgrade --help`.<br>
> In this example, it's assumed that the command is executed from directory containing 'oud-ds-rs' helm chart directory (OracleUnifiedDirectory/kubernetes/helm/).<br>

In this example, we will apply PSU2020July-20200730 patch on earlier running OUD version. If we `describe pod` we will observe that the container is up with new version.

We have two ways to achieve our goal:

    # helm upgrade --namespace myhelmns \
        --set image.repository=oracle/oud,image.tag=12.2.1.4.0-PSU2020July-20200730 \
        my-oud-ds-rs oud-ds-rs

OR

	# helm upgrade --namespace myhelmns \
		--values oud-ds-rs-values-override.yaml \
		my-oud-ds-rs oud-ds-rs

oud-rs-ds-values-override.yaml
```yaml
image:
  repository: oracle/oud
  tag: 12.2.1.4.0-PSU2020July-20200730
```


### 2.1.5 Example for using NFS as PV Storage:

    # helm install --namespace myhelmns \
        --values oud-ds-rs-values-override-nfs.yaml \
        my-oud-ds-rs oud-ds-rs
> For more details about helm command and parameters, please execute `helm --help` and `helm install --help`.<br>
> In this example, it's assumed that the command is executed from directory containing 'oud-ds-rs' helm chart directory (OracleUnifiedDirectory/kubernetes/helm/).
> With `--values` argument, passed file path/name is to override values in chart. 

oud-rs-ds-values-override-nfs.yaml
```yaml
oudConfig: 
  rootUserPassword: Oracle123
persistence:
  type: networkstorage
  networkstorage:
    nfs: 
      path: /scratch/shared/oud_user_projects
      server: <NFS Server IP address>
```

### 2.1.6 Example for using PV type of your choice:

    # helm install --namespace myhelmns \
        --values oud-ds-rs-values-override-pv-custom.yaml \
        my-oud-ds-rs oud-ds-rs
> For more details about helm command and parameters, please execute `helm --help` and `helm install --help`.<br>
> In this example, it's assumed that the command is executed from directory containing 'oud-ds-rs' helm chart directory (OracleUnifiedDirectory/kubernetes/helm/).
> With `--values` argument, passed file path/name is to override values in chart. 

oud-rs-ds-values-override-pv-custom.yaml
```yaml
oudConfig: 
  rootUserPassword: Oracle123
persistence:
  type: custom
  custom:
    nfs: 
      # Path of NFS Share location
      path: /scratch/shared/oud_user_projects
      # IP of NFS Server
      server: <NFS Server IP address>
```
> Under `custom:`, configuration of your choice can be specified. Such configuration would be used as-is for PersistentVolume object.

## 2.2 Check deployment 

### 2.2.1 Output for helm install/upgrade command

Following kind of output would be shown after successful execution of `helm install/upgrade` command.

    NAME: my-oud-ds-rs
    LAST DEPLOYED: Tue Mar 31 01:40:05 2020
    NAMESPACE: myhelmns
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None

### 2.2.2 Check for the status of objects created through oud-ds-rs helm chart

Command: 

    # kubectl --namespace myhelmns get nodes,pod,service,secret,pv,pvc,ingress -o wide

Output: 

    NAME                 READY   STATUS    RESTARTS   AGE     IP             NODE       NOMINATED NODE   READINESS GATES
    pod/my-oud-ds-rs-0   1/1     Running   0          8m44s   10.244.0.195   adc01kna   <none>           <none>
    pod/my-oud-ds-rs-1   1/1     Running   0          8m44s   10.244.0.194   adc01kna   <none>           <none>
    pod/my-oud-ds-rs-2   0/1     Running   0          8m44s   10.244.0.193   adc01kna   <none>           <none>
    
    NAME                             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE     SELECTOR
    service/my-oud-ds-rs-0           ClusterIP   10.99.232.83     <none>        1444/TCP,1888/TCP,1898/TCP   8m44s   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=my-oud-ds-rs-0
    service/my-oud-ds-rs-1           ClusterIP   10.100.186.42    <none>        1444/TCP,1888/TCP,1898/TCP   8m45s   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=my-oud-ds-rs-1
    service/my-oud-ds-rs-2           ClusterIP   10.104.55.53     <none>        1444/TCP,1888/TCP,1898/TCP   8m45s   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=my-oud-ds-rs-2
    service/my-oud-ds-rs-http-0      ClusterIP   10.102.116.145   <none>        1080/TCP,1081/TCP            8m45s   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=my-oud-ds-rs-0
    service/my-oud-ds-rs-http-1      ClusterIP   10.111.103.84    <none>        1080/TCP,1081/TCP            8m44s   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=my-oud-ds-rs-1
    service/my-oud-ds-rs-http-2      ClusterIP   10.105.53.24     <none>        1080/TCP,1081/TCP            8m45s   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=my-oud-ds-rs-2
    service/my-oud-ds-rs-lbr-admin   ClusterIP   10.98.39.206     <none>        1888/TCP,1444/TCP            8m45s   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
    service/my-oud-ds-rs-lbr-http    ClusterIP   10.110.77.132    <none>        1080/TCP,1081/TCP            8m45s   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
    service/my-oud-ds-rs-lbr-ldap    ClusterIP   10.111.55.122    <none>        1389/TCP,1636/TCP            8m45s   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
    service/my-oud-ds-rs-ldap-0      ClusterIP   10.108.155.81    <none>        1389/TCP,1636/TCP            8m44s   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=my-oud-ds-rs-0
    service/my-oud-ds-rs-ldap-1      ClusterIP   10.104.88.44     <none>        1389/TCP,1636/TCP            8m45s   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=my-oud-ds-rs-1
    service/my-oud-ds-rs-ldap-2      ClusterIP   10.105.253.120   <none>        1389/TCP,1636/TCP            8m45s   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=my-oud-ds-rs-2
    
    NAME                                        TYPE                                  DATA   AGE
    secret/default-token-tbjr5                  kubernetes.io/service-account-token   3      25d
    secret/my-oud-ds-rs-creds                   opaque                                8      8m48s
    secret/my-oud-ds-rs-token-cct26             kubernetes.io/service-account-token   3      8m50s
    secret/sh.helm.release.v1.my-oud-ds-rs.v1   helm.sh/release.v1                    1      8m51s
    
    NAME                               CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                       STORAGECLASS   REASON   AGE
    persistentvolume/my-oud-ds-rs-pv   20Gi       RWX            Retain           Bound    myhelmns/my-oud-ds-rs-pvc   manual                  8m47s
    
    NAME                                     STATUS   VOLUME            CAPACITY   ACCESS MODES   STORAGECLASS   AGE
    persistentvolumeclaim/my-oud-ds-rs-pvc   Bound    my-oud-ds-rs-pv   20Gi       RWX            manual         8m48s
    
    NAME                                                  HOSTS                                                                        ADDRESS         PORTS   AGE
    ingress.extensions/my-oud-ds-rs-admin-ingress-nginx   my-oud-ds-rs-admin-0,my-oud-ds-rs-admin-1,my-oud-ds-rs-admin-2 + 2 more...   10.229.141.78   80      8m45s
    ingress.extensions/my-oud-ds-rs-http-ingress-nginx    my-oud-ds-rs-http-0,my-oud-ds-rs-http-1,my-oud-ds-rs-http-2 + 3 more...      10.229.141.78   80      8m45s

## 2.3 Kubernetes Objects

| **Type** | **Name** | **Example Name** | **Purpose** | 
| ------ | ------ | ------ | ------ |
| Service Account | <deployment/release name> | my-oud-ds-rs | Kubernetes Service Account for the Helm Chart deployment |
| Secret | <deployment/release name>-creds |  my-oud-ds-rs-creds | Secret object for OUD related critical values like passwords |
| Persistent Volume | <deployment/release name>-pv | my-oud-ds-rs-pv | Persistent Volume for user_projects mount. | 
| Persistent Volume Claim | <deployment/release name>-pvc | my-oud-ds-rs-pvc | Persistent Volume Claim for user_projects mount. |
| Persistent Volume | <deployment/release name>-pv-config | my-oud-ds-rs-pv-config | Persistent Volume for mounting volume in containers for configuration files like ldif, schema, jks, java.security, etc. |
| Persistent Volume Claim | <deployment/release name>-pvc-config | my-oud-ds-rs-pvc-config | Persistent Volume Claim for mounting volume in containers for configuration files like ldif, schema, jks, java.security, etc. |
| Pod | <deployment/release name>-0 | my-oud-ds-rs-0 | Pod/Container for base OUD Instance which would be populated first with base configuration (like number of sample entries) |
| Pod | <deployment/release name>-N | my-oud-ds-rs-1, my-oud-ds-rs-2, ...  | Pod(s)/Container(s) for OUD Instances - each would have replication enabled against base OUD instance <deployment/release name>-0|
| Service | <deployment/release name>-0 | my-oud-ds-rs-0 | Service for LDAPS Admin, REST Admin and Replication interfaces from base OUD instance <deployment/release name>-0|
| Service | <deployment/release name>-http-0 | my-oud-ds-rs-http-0 | Service for HTTP and HTTPS interfaces from base OUD instance <deployment/release name>-0 |
| Service | <deployment/release name>-ldap-0 | my-oud-ds-rs-ldap-0 | Service for LDAP and LDAPS interfaces from base OUD instance <deployment/release name>-0 |
| Service | <deployment/release name>-N | my-oud-ds-rs-1, my-oud-ds-rs-2, ... | Service(s) for LDAPS Admin, REST Admin and Replication interfaces from base OUD instance <deployment/release name>-N |
| Service | <deployment/release name>-http-N | my-oud-ds-rs-http-1, my-oud-ds-rs-http-2, ... | Service(s) for HTTP and HTTPS interfaces from base OUD instance <deployment/release name>-N |
| Service | <deployment/release name>-ldap-N | my-oud-ds-rs-ldap-1, my-oud-ds-rs-ldap-2, ... | Service(s) for LDAP and LDAPS interfaces from base OUD instance <deployment/release name>-N |
| Service | <deployment/release name>-lbr-admin | my-oud-ds-rs-lbr-admin | Service for LDAPS Admin, REST Admin and Replication interfaces from all OUD instances |
| Service | <deployment/release name>-lbr-http | my-oud-ds-rs-lbr-http | Service for HTTP and HTTPS interfaces from all OUD instances |
| Service | <deployment/release name>-lbr-ldap | my-oud-ds-rs-lbr-ldap | Service for LDAP and LDAPS interfaces from all OUD instances |
| Ingress | <deployment/release name>-admin-ingress-nginx | my-oud-ds-rs-admin-ingress-nginx | Ingress Rules for HTTP Admin interfaces. |
| Ingress | <deployment/release name>-http-ingress-nginx | my-oud-ds-rs-http-ingress-nginx | Ingress Rules for HTTP (Data/REST) interfaces. |
> In table above, Example Name for each Object is based on value 'my-oud-ds-rs' as deployment/release name for helm chart installation.

# 3. Verify the Replication

Once all the PODs created are visible as READY (i.e. 1/1), you can verify your replication across multiple OUD instances.

To verify the replication group, connect to the container and issue an OUD admin command to show details. You can get the name of the container by issuing the following:

    # kubectl get pods -n <namespace> -o jsonpath={.items[*].spec.containers[*].name}

For example:

    # kubectl get pods -n myhelmns -o jsonpath={.items[*].spec.containers[*].name}
    oud-ds-rs
    
With the container name you can then connect to the container:

    # kubectl --namespace <namespace> exec -it -c <containername> <podname> /bin/bash

For example: 

    # kubectl --namespace myhelmns exec -it -c oud-ds-rs my-oud-ds-rs-0 /bin/bash
    
From the prompt, use the dsreplication command to check the status of your replication group:

    # cd /u01/oracle/user_projects/my-oud-ds-rs-0/OUD/bin
    # ./dsreplication status --trustAll \
        --hostname my-oud-ds-rs-0 --port 1444 --adminUID admin \
        --dataToDisplay compat-view --dataToDisplay rs-connections

Output will be similar to the following (enter credentials where prompted):

    >>>> Specify Oracle Unified Directory LDAP connection parameters
    
    Password for user 'admin':
    
    Establishing connections and reading configuration ..... Done.
    
    dc=example,dc=com - Replication Enabled
    =======================================
    
    Server               : Entries : M.C. [1] : A.O.M.C. [2] : Port [3] : Encryption [4] : Trust [5] : U.C. [6] : Status [7] : ChangeLog [8] : Group ID [9] : Connected To [10]
    ---------------------:---------:----------:--------------:----------:----------------:-----------:----------:------------:---------------:--------------:-------------------------------
    my-oud-ds-rs-0:1444  : 10002   : 0        : 0            : 1898     : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : my-oud-ds-rs-0:1898
                         :         :          :              :          :                :           :          :            :               :              : (GID=1)
    my-oud-ds-rs-1:1444  : 10002   : 0        : 0            : 1898     : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : my-oud-ds-rs-1:1898
                         :         :          :              :          :                :           :          :            :               :              : (GID=1)
    my-oud-ds-rs-2:1444  : 10002   : 0        : 0            : 1898     : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : my-oud-ds-rs-2:1898
                         :         :          :              :          :                :           :          :            :               :              : (GID=1)
    
    Replication Server [11]        : RS #1 : RS #2 : RS #3
    -------------------------------:-------:-------:------
    my-oud-ds-rs-0:1898            : --    : Yes   : Yes
    (#1)                           :       :       :
    my-oud-ds-rs-1:1898            : Yes   : --    : Yes
    (#2)                           :       :       :
    my-oud-ds-rs-2:1898            : Yes   : Yes   : --
    (#3)                           :       :       :
    
    [1] The number of changes that are still missing on this element (and that have been applied to at least one other server).
    [2] Age of oldest missing change: the age (in seconds) of the oldest change that has not yet arrived on this element.
    [3] The replication port used to communicate between the servers whose contents are being replicated.
    [4] Whether the replication communication initiated by this element is encrypted or not.
    [5] Whether the directory server is trusted or not. Updates coming from an untrusted server are discarded and not propagated.
    [6] The number of untrusted changes. These are changes generated on this server while it is untrusted.
        Those changes are not propagated to the rest of the topology but are effective on the untrusted server.
    [7] The status of the replication on this element.
    [8] Whether the external change log is enabled for the base DN on this server or not.
    [9] The ID of the replication group to which the server belongs.
    [10] The replication server this server is connected to with its group ID between brackets.
    [11] This table represents the connections between the replication servers.  The headers of the columns use a number as identifier for each replication server.  See the values of the first column to identify the corresponding replication server for each number.

Above mentioned `dsreplication status` command can be invoked in following way as well.

    # kubectl --namespace <namespace> exec -it -c <containername> <podname> -- \
        /u01/oracle/user_projects/<OUD Instance/Pod Name>/OUD/bin/dsreplication status \
        --trustAll --hostname <OUD Instance/Pod Name> --port 1444 --adminUID admin \
        --dataToDisplay compat-view --dataToDisplay rs-connections

For example: 

    # kubectl --namespace myhelmns exec -it -c oud-ds-rs my-oud-ds-rs-0 -- \
        /u01/oracle/user_projects/my-oud-ds-rs-0/OUD/bin/dsreplication status \
        --trustAll --hostname my-oud-ds-rs-0 --port 1444 --adminUID admin \
        --dataToDisplay compat-view --dataToDisplay rs-connections

# 4. Ingress Controller Setup

There are two types of ingress controllers supported through this helm chart. In the sub-sections below, configuration steps for each Controller are describved.

As, by default Ingress configuration only supports HTTP and HTTPS Ports/Communication, to allow LDAP and LDAPS communication over TCP, configuration would be required at Ingress Controller/Implementation level.

## 4.1 nginx-ingress

NGINX-ingress controller implementation can be deployed/installed in Kubernetes environment.

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
# Configuration for additional TCP ports to be exposed through Ingress
# Format for each port would be like:
# <PortNumber>: <Namespace>/<Service>
tcp: 
  # Map 1389 TCP port to LBR LDAP service to get requests handled through any available POD/Endpoint serving LDAP Port
  1389: myhelmns/my-oud-ds-rs-lbr-ldap:ldap
  # Map 1636 TCP port to LBR LDAP service to get requests handled through any available POD/Endpoint serving LDAPS Port
  1636: myhelmns/my-oud-ds-rs-lbr-ldap:ldaps
controller:
  admissionWebhooks:
    enabled: false
  extraArgs:
    # The secret referred to by this flag contains the default certificate to be used when accessing the catch-all server.
    # If this flag is not provided NGINX will use a self-signed certificate.
    # If the TLS Secret is in different namespace, name can be mentioned as <namespace>/<tlsSecretName>
    default-ssl-certificate: myhelmns/my-oud-ds-rs-tls-cert
  service:
    # controller service external IP addresses
    # externalIPs:
    #   - < External IP Address >
    # To configure Ingress Controller Service as LoadBalancer type of Service
    # Based on the Kubernetes configuration, External LoadBalancer would be linked to the Ingress Controller Service
    type: LoadBalancer
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
        # 1389: 31389
        # For LDAPS Interface
        # 1636: 31636
```
> Above mentioned configuration is according to assumption of having oud-ds-rs installed with value 'my-oud-ds-rs' as deployment/release name.
> Based on the deployment/release name in your env, TCP port mapping would be required to be changed/updated.

### Optional: Command `helm upgrade` to update nginx-ingress related objects like pod, service, deployment, etc.

If requried, NGINX-ingress deployment can be updated/upgraded with following command. In this example, nginx-ingress configuration will be updated with additional TCP port and Node Port for accessing LDAP/LDAPS Port of specific POD.

    # helm upgrade --namespace ingressns \
        --values nginx-ingress-values-override.yaml
        lbr-nginx ingress-nginx/nginx-ingress
> For more details about helm command and parameters, please execute `helm --help` and `helm install --help`.<br>
> With `--values` argument, passed file path/name is to override values in chart. 

nginx-ingress-values-override.yaml
```yaml
# Configuration for additional TCP ports to be exposed through Ingress
# Format for each port would be like:
# <PortNumber>: <Namespace>/<Service>
tcp: 
  # Map 1389 TCP port to LBR LDAP service to get requests handled through any available POD/Endpoint serving LDAP Port
  1389: myhelmns/my-oud-ds-rs-lbr-ldap:ldap
  # Map 1636 TCP port to LBR LDAP service to get requests handled through any available POD/Endpoint serving LDAPS Port
  1636: myhelmns/my-oud-ds-rs-lbr-ldap:ldaps
  # Map specific ports for LDAP and LDAPS communication from individual Services/Pods
  # To redirect requests on 3890 port to myhelmns/my-oud-ds-rs-ldap-0:ldap
  3890: myhelmns/my-oud-ds-rs-ldap-0:ldap
  # To redirect requests on 6360 port to myhelmns/my-oud-ds-rs-ldaps-0:ldap
  6360: myhelmns/my-oud-ds-rs-ldap-0:ldaps
  # To redirect requests on 3891 port to myhelmns/my-oud-ds-rs-ldap-1:ldap
  3891: myhelmns/my-oud-ds-rs-ldap-1:ldap
  # To redirect requests on 6361 port to myhelmns/my-oud-ds-rs-ldaps-1:ldap
  6361: myhelmns/my-oud-ds-rs-ldap-1:ldaps
  # To redirect requests on 3892 port to myhelmns/my-oud-ds-rs-ldap-2:ldap
  3892: myhelmns/my-oud-ds-rs-ldap-2:ldap
  # To redirect requests on 6362 port to myhelmns/my-oud-ds-rs-ldaps-2:ldap
  6362: myhelmns/my-oud-ds-rs-ldap-2:ldaps
  # To redirect requests on 4440 port to myhelmns/my-oud-ds-rs-0:adminldaps
  4440: myhelmns/my-oud-ds-rs-0:adminldaps
  # To redirect requests on 4441 port to myhelmns/my-oud-ds-rs-1:adminldaps
  4441: myhelmns/my-oud-ds-rs-1:adminldaps
  # To redirect requests on 4442 port to myhelmns/my-oud-ds-rs-2:adminldaps
  4442: myhelmns/my-oud-ds-rs-2:adminldaps
controller:
  admissionWebhooks:
    enabled: false
  extraArgs:
    # The secret referred to by this flag contains the default certificate to be used when accessing the catch-all server.
    # If this flag is not provided NGINX will use a self-signed certificate.
    # If the TLS Secret is in different namespace, name can be mentioned as <namespace>/<tlsSecretName>
    default-ssl-certificate: myhelmns/my-oud-ds-rs-tls-cert
  service:
    # controller service external IP addresses
    # externalIPs:
    #   - < External IP Address >
    # To configure Ingress Controller Service as LoadBalancer type of Service
    # Based on the Kubernetes configuration, External LoadBalancer would be linked to the Ingress Controller Service
    type: LoadBalancer
    # Configuration for NodePort to be used for Ports exposed through Ingress
    # If NodePorts are not defied/configured, Node Port would be assigend automatically by Kubernetes
    # These NodePorts are helpful while accessing services directly through Ingress and without having External Load Balancer.

```
> Above mentioned configuration is according to assumption of having oud-ds-rs installed with value 'my-oud-ds-rs' as deployment/release name.
> Based on the deployment/release name in your env, TCP port mapping would be required to be changed/updated.

> For more details about helm command and parameters, please execute `helm --help` and `helm install --help`.

# 5. Access to Interfaces through Ingress

With the helm chart, Ingress objects are also created according to configuration. Following are the rules configured in Ingress object(s) for access to OUD Interfaces through Ingress.

Note: Kubernetes will assign NodePorts in the range 3#### for http and https i.e. against 80 and 443 ports.

| **Port** | **Host** | **Example Hostname** | **Path** | **Backend Service:Port** | **Example Service Name:Port** | 
| ------ | ------ | ------ | ------ | ------ | ------ |  
| http/https | <deployment/release name>-admin-0 | my-oud-ds-rs-admin-0 | * | <deployment/release name>-0:adminhttps | my-oud-ds-rs-0:adminhttps | 
| http/https | <deployment/release name>-admin-N | my-oud-ds-rs-admin-N | * | <deployment/release name>-N:adminhttps | my-oud-ds-rs-1:adminhttps | 
| http/https | <deployment/release name>-admin | my-oud-ds-rs-admin | * | <deployment/release name>-lbr-admin:adminhttps | my-oud-ds-rs-lbr-admin:adminhttps | 
| http/https | * | * | /rest/v1/admin | <deployment/release name>-lbr-admin:adminhttps | my-oud-ds-rs-lbr-admin:adminhttps | 
| http/https | <deployment/release name>-http-0 | my-oud-ds-rs-http-0 | * | <deployment/release name>-http-0:http | my-oud-ds-rs-http-0:http | 
| http/https | <deployment/release name>-http-N | my-oud-ds-rs-http-N | * | <deployment/release name>-http-N:http | my-oud-ds-rs-http-N:http | 
| http/https | <deployment/release name>-http | my-oud-ds-rs-http | * | <deployment/release name>-lbr-http:http | my-oud-ds-rs-lbr-http:http | 
| http/https | * | * | /rest/v1/directory | <deployment/release name>-lbr-http:http | my-oud-ds-rs-lbr-http:http | 
| http/https | * | * | /iam/directory | <deployment/release name>-lbr-http:http | my-oud-ds-rs-lbr-http:http | 
> In table above, Example Values are based on value 'my-oud-ds-rs' as deployment/release name for helm chart installation.<br>
> NodePort mentioned in the table are according to Ingress configuration described in previous section. <br>
> When External LoadBalancer is not available/configured, Interfaces can be accessed through NodePort on Kubernetes Node.

For LDAP/LDAPS access (based on the updated/upgraded configuration mentioned in previous section)

Note: Kubernetes will assign NodePorts in the range 3#### against TCP ports.

| **Port** | **Backend Service:Port** | **Example Service Name:Port** | 
| ------ | ------ | ------ | 
| 1389 | <deployment/release name>-lbr-ldap:ldap | my-oud-ds-rs-lbr-ldap:ldap | 
| 1636 | <deployment/release name>-lbr-ldap:ldap | my-oud-ds-rs-lbr-ldap:ldaps |
| 1444 | <deployment/release name>-lbr-admin:adminldaps | my-oud-ds-rs-lbr-admin:adminldaps |
| 3890 | <deployment/release name>-ldap-0:ldap | my-oud-ds-rs-ldap-0:ldap | 
| 6360 | <deployment/release name>-ldap-0:ldaps | my-oud-ds-rs-ldap-0:ldaps | 
| 3891 | <deployment/release name>-ldap-1:ldap | my-oud-ds-rs-ldap-1:ldap | 
| 6361 | <deployment/release name>-ldap-1:ldaps | my-oud-ds-rs-ldap-1:ldaps | 
| 3892 | <deployment/release name>-ldap-2:ldap | my-oud-ds-rs-ldap-2:ldap | 
| 6362 | <deployment/release name>-ldap-2:ldaps | my-oud-ds-rs-ldap-2:ldaps |
| 4440 | <deployment/release name>-0:adminldaps | my-oud-ds-rs-ldap-0:adminldaps |
| 4441 | <deployment/release name>-1:adminldaps | my-oud-ds-rs-ldap-1:adminldaps |
| 4442 | <deployment/release name>-2:adminldaps | my-oud-ds-rs-ldap-2:adminldaps |
> In table above, Example Values are based on value 'my-oud-ds-rs' as deployment/release name for helm chart installation.<br>
> NodePort mentioned in the table are according to Ingress configuration described in previous section. <br>
> When External LoadBalancer is not available/configured, Interfaces can be accessed through NodePort on Kubernetes Node.

> Above Example Port to service mapping have to be specifically provided as a override config for Ingress nginx while installing as mentioned in the section ( **4.1 nginx-ingress** ).<br>

## 5.1 Changes in /etc/hosts to validate hostname based Ingress rules

In case, its not possible for you to have LoadBalancer configuration updated to have host names added for OUD Interfaces, following kind of entries can be added in /etc/hosts files on host from where OUD interfaces would be accessed. 

```text
<IP Address of External LBR or Kubernetes Node>	my-oud-ds-rs-http my-oud-ds-rs-http-0 my-oud-ds-rs-http-1 my-oud-ds-rs-http-2 my-oud-ds-rs-http-N
<IP Address of External LBR or Kubernetes Node>	my-oud-ds-rs-admin my-oud-ds-rs-admin-0 my-oud-ds-rs-admin-1 my-oud-ds-rs-admin-2 my-oud-ds-rs-admin-N
```
> In table above, host names are based on value 'my-oud-ds-rs' as deployment/release name for helm chart installation.<br>
> When External LoadBalancer is not available/configured, Interfaces can be accessed through NodePort on Kubernetes Node.

## 5.2 Validate access 

### 5.2.1 HTTP/REST API against External LBR Host

Command to invoke Data REST API: 

    # curl --noproxy "*" --location \
    --request GET 'http://<External LBR Host>/rest/v1/directory/uid=user.1,ou=People,dc=example,dc=com?scope=sub&attributes=*' \
    --header 'Authorization: Basic <Base64 of userDN:userPassword>' | json_pp
> `| json_pp` is used to format output in readable json format on client side. It can be ignored if you dont have json_pp library. <br>
> Base64 of userDN:userPassword can be generated using `echo -n "userDN:userPassword" | base64`

Output: 
```json
{
   "msgType" : "urn:ietf:params:rest:schemas:oracle:oud:1.0:SearchResponse",
   "totalResults" : 1,
   "searchResultEntries" : [
      {
         "dn" : "uid=user.1,ou=People,dc=example,dc=com",
         "attributes" : {
            "st" : "OH",
            "employeeNumber" : "1",
            "postalCode" : "93694",
            "description" : "This is the description for Aaren Atp.",
            "telephoneNumber" : "+1 390 103 6917",
            "homePhone" : "+1 280 375 4325",
            "initials" : "ALA",
            "objectClass" : [
               "top",
               "inetorgperson",
               "organizationalperson",
               "person"
            ],
            "uid" : "user.1",
            "sn" : "Atp",
            "street" : "70110 Fourth Street",
            "mobile" : "+1 680 734 6300",
            "givenName" : "Aaren",
            "mail" : "user.1@maildomain.net",
            "l" : "New Haven",
            "postalAddress" : "Aaren Atp$70110 Fourth Street$New Haven, OH  93694",
            "pager" : "+1 850 883 8888",
            "cn" : "Aaren Atp"
         }
      }
   ]
}
```

Command to invoke Data REST API against specific OUD Interface: 

    # curl --noproxy "*" --location \
    --request GET 'http://my-oud-ds-rs-http-0/rest/v1/directory/uid=user.1,ou=People,dc=example,dc=com?scope=sub&attributes=*' \
    --header 'Authorization: Basic <Base64 of userDN:userPassword>' | json_pp
> `| json_pp` is used to format output in readable json format on client side. It can be ignored if you dont have json_pp library. <br>
> Base64 of userDN:userPassword can be generated using `echo -n "userDN:userPassword" | base64`. <br>
> For this command example, it's assumed that value 'my-oud-ds-rs' is used as deployment/release name for helm chart installation. <br>
> It's assumed that 'my-oud-ds-rs-http-0' points to External LoadBalancer

### 5.2.2 HTTP/REST API against Kubernetes NodePort for Ingress Controller Service

Command to invoke Data SCIM API (this is a sample URL where K8s assigned port 30443 against https): 

    # curl --noproxy "*" --location -k \
    --request GET 'https://<Kubernetes Node>:30443/iam/directory/oud/scim/v1/Users' \
    --header 'Authorization: Basic <Base64 of userDN:userPassword>' | json_pp
> `| json_pp` is used to format output in readable json format on client side. It can be ignored if you dont have json_pp library. <br>
> Base64 of userDN:userPassword can be generated using `echo -n "userDN:userPassword" | base64` <br>

Output: 
```json
{
   "Resources" : [
      {
         "id" : "ad55a34a-763f-358f-93f9-da86f9ecd9e4",
         "userName" : [
            {
               "value" : "user.0"
            }
         ],
         "schemas" : [
            "urn:ietf:params:scim:schemas:core:2.0:User",
            "urn:ietf:params:scim:schemas:extension:oracle:2.0:OUD:User",
            "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User"
         ],
         "meta" : {
            "location" : "http://idm-oke-lbr/iam/directory/oud/scim/v1/Users/ad55a34a-763f-358f-93f9-da86f9ecd9e4",
            "resourceType" : "User"
         },
         "addresses" : [
            {
               "postalCode" : "50369",
               "formatted" : "Aaccf Amar$01251 Chestnut Street$Panama City, DE  50369",
               "streetAddress" : "01251 Chestnut Street",
               "locality" : "Panama City",
               "region" : "DE"
            }
         ],
         "urn:ietf:params:scim:schemas:extension:oracle:2.0:OUD:User" : {
            "description" : [
               {
                  "value" : "This is the description for Aaccf Amar."
               }
            ],
            "mobile" : [
               {
                  "value" : "+1 010 154 3228"
               }
            ],
            "pager" : [
               {
                  "value" : "+1 779 041 6341"
               }
            ],
            "objectClass" : [
               {
                  "value" : "top"
               },
               {
                  "value" : "organizationalperson"
               },
               {
                  "value" : "person"
               },
               {
                  "value" : "inetorgperson"
               }
            ],
            "initials" : [
               {
                  "value" : "ASA"
               }
            ],
            "homePhone" : [
               {
                  "value" : "+1 225 216 5900"
               }
            ]
         },
         "name" : [
            {
               "givenName" : "Aaccf",
               "familyName" : "Amar",
               "formatted" : "Aaccf Amar"
            }
         ],
         "emails" : [
            {
               "value" : "user.0@maildomain.net"
            }
         ],
         "phoneNumbers" : [
            {
               "value" : "+1 685 622 6202"
            }
         ],
         "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User" : {
            "employeeNumber" : [
               {
                  "value" : "0"
               }
            ]
         }
      }
      ,
 .
 .
 .
 }
```

Command to invoke Data SCIM API against specific OUD Interface (below is the sample URL with NodePort 30443): 

    # curl --noproxy "*" --location -k \
    --request GET 'https://my-oud-ds-rs-http-0:30443/iam/directory/oud/scim/v1/Users' \
    --header 'Authorization: Basic <Base64 of userDN:userPassword>' | json_pp
> `| json_pp` is used to format output in readable json format on client side. It can be ignored if you dont have json_pp library. <br>
> Base64 of userDN:userPassword can be generated using `echo -n "userDN:userPassword" | base64`. <br>
> For this command example, it's assumed that value 'my-oud-ds-rs' is used as deployment/release name for helm chart installation. <br>
> It's assumed that 'my-oud-ds-rs-http-0' points to Kubernetes Node serving Ingress Controller.

### 5.2.3 HTTPS/REST Admin API

Command to invoke Admin REST API against External LBR: 

    # curl --noproxy "*" --insecure --location \
    --request GET 'https://<External LBR Host>/rest/v1/admin/?scope=base&attributes=vendorName&attributes=vendorVersion&attributes=ds-private-naming-contexts&attributes=subschemaSubentry' \
    --header 'Content-Type: application/json' \
    --header 'Authorization: Basic <Base64 of userDN:userPassword>' | json_pp
> `| json_pp` is used to format output in readable json format on client side. It can be ignored if you dont have json_pp library. <br>
> Base64 of userDN:userPassword can be generated using `echo -n "userDN:userPassword" | base64`

Output:
```json
{
   "totalResults" : 1,
   "searchResultEntries" : [
      {
         "dn" : "",
         "attributes" : {
            "vendorVersion" : "Oracle Unified Directory 12.2.1.4.0",
            "ds-private-naming-contexts" : [
               "cn=admin data",
               "cn=ads-truststore",
               "cn=backups",
               "cn=config",
               "cn=monitor",
               "cn=schema",
               "cn=tasks",
               "cn=virtual acis",
               "dc=replicationchanges"
            ],
            "subschemaSubentry" : "cn=schema",
            "vendorName" : "Oracle Corporation"
         }
      }
   ],
   "msgType" : "urn:ietf:params:rest:schemas:oracle:oud:1.0:SearchResponse"
}

```

Command to invoke Admin REST API against specific OUD Admin Interface: 

    # curl --noproxy "*" --insecure --location \
    --request GET 'https://my-oud-ds-rs-admin-0/rest/v1/admin/?scope=base&attributes=vendorName&attributes=vendorVersion&attributes=ds-private-naming-contexts&attributes=subschemaSubentry' \
    --header 'Content-Type: application/json' \
    --header 'Authorization: Basic <Base64 of userDN:userPassword>' | json_pp
> `| json_pp` is used to format output in readable json format on client side. It can be ignored if you dont have json_pp library. <br>
> Base64 of userDN:userPassword can be generated using `echo -n "userDN:userPassword" | base64` <br>
> It's assumed that 'my-oud-ds-rs-admin-0' points to External LoadBalancer

Command to invoke Admin REST API against Kubernetes NodePort for Ingress Controller Service (sample URL where K8s assigned NodePort 30443)

    # curl --noproxy "*" --insecure --location \
    --request GET 'https://my-oud-ds-rs-admin-0:30443/rest/v1/admin/?scope=base&attributes=vendorName&attributes=vendorVersion&attributes=ds-private-naming-contexts&attributes=subschemaSubentry' \
    --header 'Content-Type: application/json' \
    --header 'Authorization: Basic <Base64 of userDN:userPassword>' | json_pp
> `| json_pp` is used to format output in readable json format on client side. It can be ignored if you dont have json_pp library. <br>
> Base64 of userDN:userPassword can be generated using `echo -n "userDN:userPassword" | base64` <br>
> It's assumed that 'my-oud-ds-rs-admin-0' points to Kubernetes Node serving Ingress Controller.

### 5.2.4 LDAP against External Load Balancer

Command to perform `ldapsearch` against External LBR and LDAP port

    # <OUD Home>/bin/ldapsearch --hostname <External LBR> --port 1389 
        -D "<Root User DN>" -w <Passwrod for Root User DN> \
        -b "" -s base "(objectClass=*)" "*" +

Output: 
```ldif
dn: 
objectClass: top
objectClass: ds-root-dse
lastChangeNumber: 0
firstChangeNumber: 0
changelog: cn=changelog
entryDN: 
pwdPolicySubentry: cn=Default Password Policy,cn=Password Policies,cn=config
subschemaSubentry: cn=schema
supportedAuthPasswordSchemes: SHA256
supportedAuthPasswordSchemes: SHA1
supportedAuthPasswordSchemes: SHA384
supportedAuthPasswordSchemes: SHA512
supportedAuthPasswordSchemes: MD5
numSubordinates: 1
supportedFeatures: 1.3.6.1.1.14
supportedFeatures: 1.3.6.1.4.1.4203.1.5.1
supportedFeatures: 1.3.6.1.4.1.4203.1.5.2
supportedFeatures: 1.3.6.1.4.1.4203.1.5.3
lastExternalChangelogCookie: 
vendorName: Oracle Corporation
vendorVersion: Oracle Unified Directory 12.2.1.4.0
componentVersion: 4
releaseVersion: 1
platformVersion: 0
supportedLDAPVersion: 2
supportedLDAPVersion: 3
supportedControl: 1.2.826.0.1.3344810.2.3
supportedControl: 1.2.840.113556.1.4.1413
supportedControl: 1.2.840.113556.1.4.319
supportedControl: 1.2.840.113556.1.4.473
supportedControl: 1.2.840.113556.1.4.805
supportedControl: 1.3.6.1.1.12
supportedControl: 1.3.6.1.1.13.1
supportedControl: 1.3.6.1.1.13.2
supportedControl: 1.3.6.1.4.1.26027.1.5.2
supportedControl: 1.3.6.1.4.1.26027.1.5.4
supportedControl: 1.3.6.1.4.1.26027.1.5.5
supportedControl: 1.3.6.1.4.1.26027.1.5.6
supportedControl: 1.3.6.1.4.1.26027.2.3.1
supportedControl: 1.3.6.1.4.1.26027.2.3.2
supportedControl: 1.3.6.1.4.1.26027.2.3.4
supportedControl: 1.3.6.1.4.1.42.2.27.8.5.1
supportedControl: 1.3.6.1.4.1.42.2.27.9.5.2
supportedControl: 1.3.6.1.4.1.42.2.27.9.5.8
supportedControl: 1.3.6.1.4.1.4203.1.10.1
supportedControl: 1.3.6.1.4.1.4203.1.10.2
supportedControl: 2.16.840.1.113730.3.4.12
supportedControl: 2.16.840.1.113730.3.4.16
supportedControl: 2.16.840.1.113730.3.4.17
supportedControl: 2.16.840.1.113730.3.4.18
supportedControl: 2.16.840.1.113730.3.4.19
supportedControl: 2.16.840.1.113730.3.4.2
supportedControl: 2.16.840.1.113730.3.4.3
supportedControl: 2.16.840.1.113730.3.4.4
supportedControl: 2.16.840.1.113730.3.4.5
supportedControl: 2.16.840.1.113730.3.4.9
supportedControl: 2.16.840.1.113894.1.8.21
supportedControl: 2.16.840.1.113894.1.8.31
supportedControl: 2.16.840.1.113894.1.8.36
maintenanceVersion: 2
supportedSASLMechanisms: PLAIN
supportedSASLMechanisms: EXTERNAL
supportedSASLMechanisms: CRAM-MD5
supportedSASLMechanisms: DIGEST-MD5
majorVersion: 12
orclGUID: D41D8CD98F003204A9800998ECF8427E
entryUUID: d41d8cd9-8f00-3204-a980-0998ecf8427e
ds-private-naming-contexts: cn=schema
hasSubordinates: true
nsUniqueId: d41d8cd9-8f003204-a9800998-ecf8427e
structuralObjectClass: ds-root-dse
supportedExtension: 1.3.6.1.4.1.4203.1.11.1
supportedExtension: 1.3.6.1.4.1.4203.1.11.3
supportedExtension: 1.3.6.1.1.8
supportedExtension: 1.3.6.1.4.1.26027.1.6.3
supportedExtension: 1.3.6.1.4.1.26027.1.6.2
supportedExtension: 1.3.6.1.4.1.26027.1.6.1
supportedExtension: 1.3.6.1.4.1.1466.20037
namingContexts: cn=changelog
namingContexts: dc=example,dc=com
```

Command to perform `ldapsearch` against External LBR and LDAP port for specific OUD Interface

    # <OUD Home>/bin/ldapsearch --hostname <External LBR> --port 3890 \
        -D "<Root User DN>" -w <Passwrod for Root User DN> \
        -b "" -s base "(objectClass=*)" "*" +

### 5.2.4 LDAPS against Kubernetes NodePort for Ingress Controller Service

Command to perform `ldapsearch` against External LBR and LDAP port

    # <OUD Home>/bin/ldapsearch --hostname <Kubernetes Node> --port 31636 
        --port 1636 --useSSL --trustAll
        -D "<Root User DN>" -w <Passwrod for Root User DN> \
        -b "" -s base "(objectClass=*)" "*" +

Output: 
```ldif
dn: 
objectClass: top
objectClass: ds-root-dse
lastChangeNumber: 0
firstChangeNumber: 0
changelog: cn=changelog
entryDN: 
pwdPolicySubentry: cn=Default Password Policy,cn=Password Policies,cn=config
subschemaSubentry: cn=schema
supportedAuthPasswordSchemes: SHA256
supportedAuthPasswordSchemes: SHA1
supportedAuthPasswordSchemes: SHA384
supportedAuthPasswordSchemes: SHA512
supportedAuthPasswordSchemes: MD5
numSubordinates: 1
supportedFeatures: 1.3.6.1.1.14
supportedFeatures: 1.3.6.1.4.1.4203.1.5.1
supportedFeatures: 1.3.6.1.4.1.4203.1.5.2
supportedFeatures: 1.3.6.1.4.1.4203.1.5.3
lastExternalChangelogCookie: 
vendorName: Oracle Corporation
vendorVersion: Oracle Unified Directory 12.2.1.4.0
componentVersion: 4
releaseVersion: 1
platformVersion: 0
supportedLDAPVersion: 2
supportedLDAPVersion: 3
supportedControl: 1.2.826.0.1.3344810.2.3
supportedControl: 1.2.840.113556.1.4.1413
supportedControl: 1.2.840.113556.1.4.319
supportedControl: 1.2.840.113556.1.4.473
supportedControl: 1.2.840.113556.1.4.805
supportedControl: 1.3.6.1.1.12
supportedControl: 1.3.6.1.1.13.1
supportedControl: 1.3.6.1.1.13.2
supportedControl: 1.3.6.1.4.1.26027.1.5.2
supportedControl: 1.3.6.1.4.1.26027.1.5.4
supportedControl: 1.3.6.1.4.1.26027.1.5.5
supportedControl: 1.3.6.1.4.1.26027.1.5.6
supportedControl: 1.3.6.1.4.1.26027.2.3.1
supportedControl: 1.3.6.1.4.1.26027.2.3.2
supportedControl: 1.3.6.1.4.1.26027.2.3.4
supportedControl: 1.3.6.1.4.1.42.2.27.8.5.1
supportedControl: 1.3.6.1.4.1.42.2.27.9.5.2
supportedControl: 1.3.6.1.4.1.42.2.27.9.5.8
supportedControl: 1.3.6.1.4.1.4203.1.10.1
supportedControl: 1.3.6.1.4.1.4203.1.10.2
supportedControl: 2.16.840.1.113730.3.4.12
supportedControl: 2.16.840.1.113730.3.4.16
supportedControl: 2.16.840.1.113730.3.4.17
supportedControl: 2.16.840.1.113730.3.4.18
supportedControl: 2.16.840.1.113730.3.4.19
supportedControl: 2.16.840.1.113730.3.4.2
supportedControl: 2.16.840.1.113730.3.4.3
supportedControl: 2.16.840.1.113730.3.4.4
supportedControl: 2.16.840.1.113730.3.4.5
supportedControl: 2.16.840.1.113730.3.4.9
supportedControl: 2.16.840.1.113894.1.8.21
supportedControl: 2.16.840.1.113894.1.8.31
supportedControl: 2.16.840.1.113894.1.8.36
maintenanceVersion: 2
supportedSASLMechanisms: PLAIN
supportedSASLMechanisms: EXTERNAL
supportedSASLMechanisms: CRAM-MD5
supportedSASLMechanisms: DIGEST-MD5
majorVersion: 12
orclGUID: D41D8CD98F003204A9800998ECF8427E
entryUUID: d41d8cd9-8f00-3204-a980-0998ecf8427e
ds-private-naming-contexts: cn=schema
hasSubordinates: true
nsUniqueId: d41d8cd9-8f003204-a9800998-ecf8427e
structuralObjectClass: ds-root-dse
supportedExtension: 1.3.6.1.4.1.4203.1.11.1
supportedExtension: 1.3.6.1.4.1.4203.1.11.3
supportedExtension: 1.3.6.1.1.8
supportedExtension: 1.3.6.1.4.1.26027.1.6.3
supportedExtension: 1.3.6.1.4.1.26027.1.6.2
supportedExtension: 1.3.6.1.4.1.26027.1.6.1
supportedExtension: 1.3.6.1.4.1.1466.20037
namingContexts: cn=changelog
namingContexts: dc=example,dc=com
```

Command to perform `ldapsearch` against External LBR and LDAP port for specific OUD Interface

    # <OUD Home>/bin/ldapsearch --hostname <Kubernetes Node> --port 30360 \
        --port 1636 --useSSL --trustAll
        -D "<Root User DN>" -w <Passwrod for Root User DN> \
        -b "" -s base "(objectClass=*)" "*" +

# 6. Logging and Monitoring

## 6.1. Logging

For Logging, OUD will be integrating ELK stack.The ELK stack consists of Elasticsearch, Logstash, and Kibana. Using ELK we can gain insights in real-time from the log data from your applications.


**Elasticsearch** is a distributed, RESTful search and analytics engine capable of solving a growing number of use cases. As the heart of the Elastic Stack, it centrally stores your data so you can discover the expected and uncover the unexpected.

**Logstash** is an open source, server-side data processing pipeline that ingests data from a multitude of sources simultaneously, transforms it, and then sends it to your favorite “stash.”

**Kibana** lets you visualize your Elasticsearch data and navigate the Elastic Stack. It gives you the freedom to select the way you give shape to your data. And you don’t always have to know what you're looking for.

### 6.1.1. Values.yaml Configurations to enable ELK stack 

    # elk:
          enabled: true
    
This configuration will enable the ELK stack integration with OUD.

### 6.1.2. Prepare a host directory to be used for Filesystem based PersistentVolume for Elastic Search

It's required to prepare directory on Host filesystem to store Elastic Search Instances and other configuration outside container filesystem. That directory from host filesystem would be associated with PersistentVolume.
In case of multi-node Kubernetes cluster, directory to be associated with PersistentVolume should be accessible on all the nodes at the same path.

To prepare a host directory (for example: /scratch/test/oud_elk ) for mounting as file system based PersistentVolume inside containers, execute the command below on host:

> The userid can be anything but it must belong to uid:guid as 1000:1000, which is same as 'oracle' user running in the container.
> This ensures 'oracle' user has access to shared volume/directory.

```
sudo su - root
mkdir -p /scratch/test/oud_elk
chown 1000:1000 /scratch/test/oud_elk
exit
```
All container operations are performed as **'oracle'** user.

**Note**: If a user already exist with **'-u 1000 -g 1000'** then use the same user. Or modify any existing user to have uid-gid as **'-u 1000 -g 1000'**


### 6.1.3. Deploy oud-ds-rs Helm Chart

Create/Deploy a group of replicated OUD instances along with ELK stack Kubernetes objects in specified namespace using oud-ds-rs Helm Chart. 
The deployment can be initiated by running the following Helm command with reference to oud-ds-rs Helm Chart along with configuration parameters according to your environment. Before deploying the helm chart, namespace should be created. Object to be created with helm chart would be created inside specified namespace.

    # helm install --namespace <namespace> \
        <Configuration Parameters> \
        <deployment/release name> \
        <Helm Chart Path/Name>
        

### 6.1.4 Output for helm install/upgrade command

Following kind of output would be shown after successful execution of `helm install/upgrade` command.
    
    NAME: oud-ds-rs
    LAST DEPLOYED: Fri Sep 18 18:09:31 2020
    NAMESPACE: oudns
    STATUS: deployed
    REVISION: 1
    NOTES:
    Since "nginx" has been chosen, follow the steps below to configure nginx ingress controller.
    Add Repo reference to helm for retriving/installing Chart for nginx-ingress implementation.
    command-# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

    Command helm install to install nginx-ingress related objects like pod, service, deployment, etc.
    # helm install --namespace <namespace for ingress> --values nginx-ingress-values-override.yaml lbr-nginx ingress-nginx/nginx-ingress

    For details of content of nginx-ingress-values-override.yaml refer README.md file of this chart.

    Run these commands to check port mapping and services: 
    # kubectl --namespace <namespace for ingress> get services -o wide -w lbr-nginx-ingress-controller
    # kubectl describe --namespace <namespace for oud-ds-rs chart> ingress.extensions/oud-ds-rs-http-ingress-nginx
    # kubectl describe --namespace <namespace for oud-ds-rs chart> ingress.extensions/oud-ds-rs-admin-ingress-nginx

    Accessible interfaces through ingress:
    (External IP Address for LoadBalancer NGINX Controller can be determined through details associated with lbr-nginx-ingress-controller)

    1. OUD Admin REST:
       Port: http/https 

    2. OUD Data REST:
       Port: http/https 

    3. OUD Data SCIM:
       Port: http/https 

    4. OUD LDAP/LDAPS:
       Port: ldap/ldaps

    5. OUD Admin LDAPS:
       Port: ldaps
 
    Please refer to README.md from Helm Chart to find more details about accessing interfaces and configuration parameters.

### 6.1.5 Check for the status of objects created through oud-ds-rs helm chart

```
NAME                                      READY   STATUS    RESTARTS   AGE     IP            NODE                     NOMINATED NODE   READINESS GATES
pod/oud-ds-rs-0                           1/1     Running   0          8m7s    10.244.0.78   adcaa712.us.oracle.com   <none>           <none>
pod/oud-ds-rs-1                           1/1     Running   0          8m7s    10.244.0.76   adcaa712.us.oracle.com   <none>           <none>
pod/oud-ds-rs-2                           1/1     Running   0          8m7s    10.244.0.77   adcaa712.us.oracle.com   <none>           <none>
pod/oud-ds-rs-es-cluster-0                1/1     Running   0          8m6s    10.244.0.81   adcaa712.us.oracle.com   <none>           <none>
pod/oud-ds-rs-es-cluster-1                1/1     Running   0          7m54s   10.244.0.82   adcaa712.us.oracle.com   <none>           <none>
pod/oud-ds-rs-es-cluster-2                1/1     Running   0          7m46s   10.244.0.83   adcaa712.us.oracle.com   <none>           <none>
pod/oud-ds-rs-kibana-5f85594555-dhxn7     1/1     Running   0          8m6s    10.244.0.79   adcaa712.us.oracle.com   <none>           <none>
pod/oud-ds-rs-logstash-6b879644b4-wg8xn   1/1     Running   0          8m6s    10.244.0.80   adcaa712.us.oracle.com   <none>           <none>

NAME                                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE    SELECTOR
service/oud-ds-rs-0                  ClusterIP   10.101.25.1      <none>        1444/TCP,1888/TCP,1898/TCP   8m8s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-0
service/oud-ds-rs-1                  ClusterIP   10.105.153.80    <none>        1444/TCP,1888/TCP,1898/TCP   8m8s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-1
service/oud-ds-rs-2                  ClusterIP   10.102.214.244   <none>        1444/TCP,1888/TCP,1898/TCP   8m8s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-2
service/oud-ds-rs-elasticsearch      ClusterIP   None             <none>        9200/TCP,9300/TCP            8m8s   app=oud-ds-rs-elasticsearch
service/oud-ds-rs-http-0             ClusterIP   10.98.180.254    <none>        1080/TCP,1081/TCP            8m8s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-0
service/oud-ds-rs-http-1             ClusterIP   10.96.202.130    <none>        1080/TCP,1081/TCP            8m8s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-1
service/oud-ds-rs-http-2             ClusterIP   10.101.200.124   <none>        1080/TCP,1081/TCP            8m8s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-2
service/oud-ds-rs-kibana             NodePort    10.105.137.82    <none>        5601:31199/TCP               8m8s   app=kibana
service/oud-ds-rs-lbr-admin          ClusterIP   10.108.187.3     <none>        1888/TCP,1444/TCP            8m8s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
service/oud-ds-rs-lbr-http           ClusterIP   10.102.156.39    <none>        1080/TCP,1081/TCP            8m8s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
service/oud-ds-rs-lbr-ldap           ClusterIP   10.100.62.213    <none>        1389/TCP,1636/TCP            8m8s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
service/oud-ds-rs-ldap-0             ClusterIP   10.111.170.205   <none>        1389/TCP,1636/TCP            8m8s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-0
service/oud-ds-rs-ldap-1             ClusterIP   10.104.31.4      <none>        1389/TCP,1636/TCP            8m8s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-1
service/oud-ds-rs-ldap-2             ClusterIP   10.99.214.59     <none>        1389/TCP,1636/TCP            8m8s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-2
service/oud-ds-rs-logstash-service   NodePort    10.108.107.249   <none>        9600:31547/TCP               8m8s   app=logstash

NAME                                 READY   UP-TO-DATE   AVAILABLE   AGE    CONTAINERS           IMAGES                                  SELECTOR
deployment.apps/oud-ds-rs-kibana     1/1     1            1           8m6s   kibana               docker.elastic.co/kibana/kibana:6.4.3   app=kibana
deployment.apps/oud-ds-rs-logstash   1/1     1            1           8m6s   oud-ds-rs-logstash   logstash:6.6.0                          app=logstash

NAME                                            DESIRED   CURRENT   READY   AGE    CONTAINERS           IMAGES                                  SELECTOR
replicaset.apps/oud-ds-rs-kibana-5f85594555     1         1         1       8m6s   kibana               docker.elastic.co/kibana/kibana:6.4.3   app=kibana,pod-template-hash=5f85594555
replicaset.apps/oud-ds-rs-logstash-6b879644b4   1         1         1       8m6s   oud-ds-rs-logstash   logstash:6.6.0                          app=logstash,pod-template-hash=6b879644b4

NAME                                    READY   AGE    CONTAINERS      IMAGES
statefulset.apps/oud-ds-rs-es-cluster   3/3     8m6s   elasticsearch   docker.elastic.co/elasticsearch/elasticsearch:6.4.3

NAME                                     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                               STORAGECLASS                       REASON   AGE     VOLUMEMODE
persistentvolume/myoud-oud-ds-rs-pv      20Gi       RWX            Retain           Bound    ouddemo/myoud-oud-ds-rs-pvc         manual                                      24h     Filesystem
persistentvolume/oam-cluster-domain-pv   10Gi       RWX            Retain           Bound    accessns/oam-cluster-domain-pvc     oam-cluster-domain-storage-class            2d1h    Filesystem
persistentvolume/oud-ds-rs-espv1         20Gi       RWX            Retain           Bound    oudns/data-oud-ds-rs-es-cluster-2   elk                                         8m12s   Filesystem
persistentvolume/oud-ds-rs-espv2         20Gi       RWX            Retain           Bound    oudns/data-oud-ds-rs-es-cluster-1   elk                                         8m12s   Filesystem
persistentvolume/oud-ds-rs-espv3         20Gi       RWX            Retain           Bound    oudns/data-oud-ds-rs-es-cluster-0   elk                                         8m12s   Filesystem
persistentvolume/oud-ds-rs-pv            20Gi       RWX            Retain           Bound    oudns/oud-ds-rs-pvc                 manual                                      8m12s   Filesystem

NAME                                                STATUS   VOLUME            CAPACITY   ACCESS MODES   STORAGECLASS   AGE     VOLUMEMODE
persistentvolumeclaim/data-oud-ds-rs-es-cluster-0   Bound    oud-ds-rs-espv3   20Gi       RWX            elk            8m6s    Filesystem
persistentvolumeclaim/data-oud-ds-rs-es-cluster-1   Bound    oud-ds-rs-espv2   20Gi       RWX            elk            7m54s   Filesystem
persistentvolumeclaim/data-oud-ds-rs-es-cluster-2   Bound    oud-ds-rs-espv1   20Gi       RWX            elk            7m46s   Filesystem
persistentvolumeclaim/oud-ds-rs-pvc                 Bound    oud-ds-rs-pv      20Gi       RWX            manual         8m10s   Filesystem

```

# 7. Configuration Parameters

The following table lists the configurable parameters of the OUD-DS-RS chart and their default values.

| **Parameter** | **Description** | **Default Value** |
| ------------- | --------------- | ----------------- |
| replicaCount  | Number of DS+RS instances/pods/services to be created with replication enabled against a base OUD instance/pod. | 3 |
| restartPolicyName | restartPolicy to be configured for each POD containing OUD instance | OnFailure |
| image.repository | OUD Image Registry/Repository and name. Based on this, image parameter would be configured for OUD pods/containers | oracle/oud |
| image.tag | OUD Image Tag. Based on this, image parameter would be configured for OUD pods/containers | 12.2.1.4.0 |
| image.pullPolicy | policy to pull the image | IfnotPresent |
| imagePullSecrets.name | name of Secret resource containing private registry credentials | regcred |
| nameOverride | override the fullname with this name | |
| fullnameOverride | Overrides the fullname with the provided string | |
| serviceAccount.create  | Specifies whether a service account should be created | true |
| serviceAccount.name | If not set and create is true, a name is generated using the fullname template | oud-ds-rs-< fullname >-token-< randomalphanum > |
| podSecurityContext | Security context policies to add to the controller pod | |
| securityContext | Security context policies to add by default | |
| service.type | type of controller service to create | ClusterIP |
| nodeSelector | node labels for pod assignment | |
| tolerations | node taints to tolerate  | |
| affinity | node/pod affinities  | |
| ingress.enabled | | true | 
| ingress.type | Supported value: nginx  | 
| ingress.nginx.http.host | Hostname to be used with Ingress Rules. <br>If not set, hostname would be configured according to fullname. <br> Hosts would be configured as < fullname >-http.< domain >, < fullname >-http-0.< domain >, < fullname >-http-1.< domain >, etc. | |
| ingress.nginx.http.domain | Domain name to be used with Ingress Rules. <br>In ingress rules, hosts would be configured as < host >.< domain >, < host >-0.< domain >, < host >-1.< domain >, etc. | |
| ingress.nginx.http.backendPort | | http |
| ingress.nginx.http.nginxAnnotations | | { <br>kubernetes.io/ingress.class: "nginx"<br> }|
| ingress.nginx.admin.host | Hostname to be used with Ingress Rules. <br>If not set, hostname would be configured according to fullname. <br> Hosts would be configured as < fullname >-admin.< domain >, < fullname >-admin-0.< domain >, < fullname >-admin-1.< domain >, etc. | |
| ingress.nginx.admin.domain | Domain name to be used with Ingress Rules. <br>In ingress rules, hosts would be configured as < host >.< domain >, < host >-0.< domain >, < host >-1.< domain >, etc. | |
| ingress.nginx.admin.nginxAnnotations | | { <br>kubernetes.io/ingress.class: "nginx" <br> nginx.ingress.kubernetes.io/backend-protocol: "https"<br>} |
| ingress.ingress.tlsSecret | Secret name to use an already created TLS Secret. If such secret is not provided, one would be created with name < fullname >-tls-cert. If the TLS Secret is in different namespace, name can be mentioned as < namespace >/< tlsSecretName > | |
| ingress.certCN | Subject's common name (cn) for SelfSigned Cert. | < fullname > |
| ingress.certValidityDays | Validity of Self-Signed Cert in days | 365 |
| secret.enabled | If enabled it will use the secret created with base64 encoding. if value is false, secret would not be used and input values (through --set, --values, etc.) would be used while creation of pods. | true|
| secret.name | secret name to use an already created Secret | oud-ds-rs-< fullname >-creds |
| secret.type | Specifies the type of the secret | Opaque |
| persistence.enabled | If enabled, it will use the persistent volume. if value is false, PV and PVC would not be used and pods would be using the default emptyDir mount volume. | true |
| persistence.pvname | pvname to use an already created Persistent Volume , If blank will use the default name | oud-ds-rs-< fullname >-pv |
| persistence.pvcname | pvcname to use an already created Persistent Volume Claim , If blank will use default name  |oud-ds-rs-< fullname >-pvc |
| persistence.type | supported values: either filesystem or networkstorage or custom | filesystem |
| persistence.filesystem.hostPath.path | The path location mentioned should be created and accessible from the local host provided with necessary privileges for the user. | /scratch/shared/oud_user_projects |
| persistence.networkstorage.nfs.path | Path of NFS Share location  | /scratch/shared/oud_user_projects |
| persistence.networkstorage.nfs.server | IP or hostname of NFS Server  | 0.0.0.0 |
| persistence.custom.* | Based on values/data, YAML content would be included in PersistenceVolume Object |  |
| persistence.accessMode | Specifies the access mode of the location provided | ReadWriteMany |
| persistence.size  | Specifies the size of the storage | 10Gi |
| persistence.storageClass | Specifies the storageclass of the persistence volume. | empty |
| persistence.annotations | specifies any annotations that will be used| { } |
| configVolume.enabled | If enabled, it will use the persistent volume. If value is false, PV and PVC would not be used and pods would be using the default emptyDir mount volume. | true |
| configVolume.mountPath | If enabled, it will use the persistent volume. If value is false, PV and PVC would not be used and there would not be any mount point available for config | false |
| configVolume.pvname | pvname to use an already created Persistent Volume , If blank will use the default name | oud-ds-rs-< fullname >-pv-config |
| configVolume.pvcname | pvcname to use an already created Persistent Volume Claim , If blank will use default name  |oud-ds-rs-< fullname >-pvc-config |
| configVolume.type | supported values: either filesystem or networkstorage or custom | filesystem |
| configVolume.filesystem.hostPath.path | The path location mentioned should be created and accessible from the local host provided with necessary privileges for the user. | /scratch/shared/oud_user_projects |
| configVolume.networkstorage.nfs.path | Path of NFS Share location  | /scratch/shared/oud_config |
| configVolume.networkstorage.nfs.server | IP or hostname of NFS Server  | 0.0.0.0 |
| configVolume.custom.* | Based on values/data, YAML content would be included in PersistenceVolume Object |  |
| configVolume.accessMode | Specifies the access mode of the location provided | ReadWriteMany |
| configVolume.size  | Specifies the size of the storage | 10Gi |
| configVolume.storageClass | Specifies the storageclass of the persistence volume. | empty |
| configVolume.annotations | specifies any annotations that will be used| { } |
| oudPorts.adminldaps | Port on which OUD Instance in the container should listen for Administration Communication over LDAPS Protocol | 1444 |
| oudPorts.adminhttps | Port on which OUD Instance in the container should listen for Administration Communication over HTTPS Protocol. | 1888 |
| oudPorts.ldap | Port on which OUD Instance in the container should listen for LDAP Communication. | 1389 |
| oudPorts.ldaps | Port on which OUD Instance in the container should listen for LDAPS Communication. | 1636 |
| oudPorts.http | Port on which OUD Instance in the container should listen for HTTP Communication. | 1080 |
| oudPorts.https | Port on which OUD Instance in the container should listen for HTTPS Communication. | 1081 |
| oudPorts.replication | Port value to be used while setting up replication server. | 1898 |
| oudConfig.baseDN | BaseDN for OUD Instances | dc=example,dc=com |
| oudConfig.rootUserDN | Root User DN for OUD Instances | dc=example,dc=com |
| oudConfig.rootUserPassword | Password for Root User DN | RandomAlphanum |
| oudConfig.sampleData | To specify that the database should be populated with the specified number of sample entries. | 0 |
| oudConfig.sleepBeforeConfig | Based on the value for this parameter, initialization/configuration of each OUD replica would be delayed. | 120 |
| oudConfig.adminUID | AdminUID to be configured with each replicated OUD instance | admin |
| oudConfig.adminPassword | Password for AdminUID. If the value is not passed, value of rootUserPassword would be used as password for AdminUID. | rootUserPassword |
| baseOUD.envVarsConfigMap | Reference to ConfigMap which can contain additional environment variables to be passed on to POD for Base OUD Instance. Following are the environment variables which would not be honored from the ConfigMap. <br> instanceType, sleepBeforeConfig, OUD_INSTANCE_NAME, hostname, baseDN, rootUserDN, rootUserDN, rootUserPassword, adminConnectorPort, httpAdminConnectorPort, ldapPort, ldapsPort, httpPort, httpsPort, replicationPort, sampleData. | - |
| baseOUD.envVars | Environment variables in Yaml Map format. This is helpful when its requried to pass environment variables through --values file. List of env variables which would not be honored from envVars map is same as list of env var names mentioned for envVarsConfigMap. | - |
| replOUD.envVarsConfigMap | Reference to ConfigMap which can contain additional environment variables to be passed on to PODs for Replicated OUD Instances. Following are the environment variables which would not be honored from the ConfigMap. <br> instanceType, sleepBeforeConfig, OUD_INSTANCE_NAME, hostname, baseDN, rootUserDN, rootUserDN, rootUserPassword, adminConnectorPort, httpAdminConnectorPort, ldapPort, ldapsPort, httpPort, httpsPort, replicationPort, sampleData, sourceHost, sourceServerPorts, sourceAdminConnectorPort, sourceReplicationPort, dsreplication_1, dsreplication_2, dsreplication_3, dsreplication_4, post_dsreplication_dsconfig_1, post_dsreplication_dsconfig_2 | - |
| replOUD.envVars | Environment variables in Yaml Map format. This is helpful when its requried to pass environment variables through --values file. List of env variables which would not be honored from envVars map is same as list of env var names mentioned for envVarsConfigMap. | - |
| replOUD.groupId | Group ID to be used/configured with each OUD instance in replicated topology. | 1 |
| elk.enabled | If enabled it will create the elk stack integrated with OUD | false |
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
