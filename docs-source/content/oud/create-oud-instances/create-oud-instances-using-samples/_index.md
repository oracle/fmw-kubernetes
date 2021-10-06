---
title: "a. Create Oracle Unified Directory Instances Using Samples"
weight: 1
description: "Samples for deploying Oracle Unified Directory instances to a Kubernetes POD."
---


1. [Introduction](#introduction)
1. [Preparing the Environment for Container Creation](#preparing-the-environment-for-container-creation)
	1. [Create Kubernetes Namespace](#create-kubernetes-namespace)
	1. [Create Secrets for User IDs and Passwords](#create-secrets-for-user-ids-and-passwords)
	1. [Prepare a Host Directory to be used for Filesystem Based PersistentVolume](#prepare-a-host-directory-to-be-used-for-filesystem-based-persistentvolume)
	1. [Create PersistentVolume (PV) and PersistentVolumeClaim (PVC) for your Namespace](#create-persistentvolume-pv-and-persistentvolumeclaim-pvc-for-your-namespace)
1. [Directory Server (instanceType=Directory)](#directory-server-instancetypedirectory)
1. [Directory Server (instanceType=Directory) as a Kubernetes Service](#directory-server-instancetypedirectory-as-a-kubernetes-service)
1. [Proxy Server (instanceType=Proxy) as a Kubernetes Service](#proxy-server-instancetypeproxy-as-a-kubernetes-service)
1. [Replication Server (instanceType=Replication) as a Kubernetes Service](#replication-server-instancetypereplication-as-a-kubernetes-service)
1. [Directory Server/Service added to existing Replication Server/Service (instanceType=AddDS2RS)](#directory-serverservice-added-to-existing-replication-serverservice-instancetypeaddds2rs)
1. [Appendix A : Reference](#appendix-a--reference)

### Introduction

The Oracle Unified Directory deployment scripts provided in the `samples` directory of this project demonstrate the creation of different types of Oracle Unified Directory Instances (Directory Service, Proxy, Replication) in containers within a Kubernetes environment.

**Note:** The sample files to assist you in creating and configuring your Oracle Unified Directory Kubernetes environment can be found in the project at the following location:

`https://github.com/oracle/fmw-kubernetes/tree/master/OracleUnifiedDirectory/kubernetes/samples`

### Preparing the Environment for Container Creation

In this section you prepare the environment for the Oracle Unified Directory container creation. This involves the following steps:

1. Create Kubernetes Namespace
1. Create Secrets for User IDs and Passwords
1. Prepare a host directory to be used for Filesystem based PersistentVolume
1. Create PersistentVolume (PV) and PersistentVolumeClaim (PVC) for your Namespace

**Note:** Sample files to assist you in creating and configuring your Oracle Unified Directory Kubernetes environment can be found in the project at the following location:

`https://github.com/oracle/fmw-kubernetes/tree/master/OracleUnifiedDirectory/kubernetes/samples`

#### Create Kubernetes Namespace

You should create a Kubernetes namespace to provide a scope for other objects such as pods and services that you create in the environment.  To create your namespace you should refer to the `oudns.yaml` file.

Update the `oudns.yaml` file and replace `%NAMESPACE%` with the value of the namespace you would like to create.  In the example below the value 'oudns' is used.

To create the namespace apply the file using `kubectl`:

```
$ cd <work directory>/fmw-kubernetes/OracleUnifiedDirectory/kubernetes/samples
$ kubectl apply -f oudns.yaml
```

For example:

```
$ cd /scratch/OUDContainer/fmw-kubernetes/OracleUnifiedDirectory/kubernetes/samples
$ kubectl apply -f oudns.yaml
```

The output will look similar to the following:

```
namespace/oudns created
```

Confirm that the namespace is created:

```
$ kubectl get namespaces
NAME          STATUS   AGE
default       Active   4d
kube-public   Active   4d
kube-system   Active   4d
oudns         Active   53s
```

#### Create Secrets for User IDs and Passwords

To protect sensitive information, namely user IDs and passwords, you should create Kubernetes Secrets for the key-value pairs with following keys. The Secret with key-value pairs will be used to pass values to containers created through the Oracle Unified Directory image:

* rootUserDN
* rootUserPassword
* adminUID
* adminPassword
* bindDN1
* bindPassword1
* bindDN2
* bindPassword2

There are two ways by which a Kubernetes secret object can be created with required key-value pairs.

##### Using secrets.yaml file

In this method you update the `secrets.yaml` file with the value for %SECRET_NAME% and %NAMESPACE%, together with the Base64 value for each secret.

*  `%rootUserDN%` - With Base64 encoded value for  rootUserDN parameter.
*  `%rootUserPassword%` - With Base64 encoded value for rootUserPassword parameter.
*  `%adminUID%` - With Base64 encoded value for adminUID parameter.
*  `%adminPassword%` - With Base64 encoded value for adminPassword parameter.
*  `%bindDN1%` - With Base64 encoded value for bindDN1 parameter.
*  `%bindPassword1%` - With Base64 encoded value for bindPassword1 parameter.
*  `%bindDN2%` - With Base64 encoded value for bindDN2 parameter.
*  `%bindPassword2%` - With Base64 encoded value for bindPassword2 parameter.

Obtain the base64 value for your secrets, for example:

```
$ echo -n cn=Directory Manager | base64
Y249RGlyZWN0b3J5IE1hbmFnZXI=
$ echo -n Oracle123 | base64
T3JhY2xlMTIz
$ echo -n admin | base64
YWRtaW4=
```

**Note:** Ensure that you use the `-n` parameter with the `echo` command. If the parameter is omitted Base64 values willbe generated with a new-line character included.

Update the `secrets.yaml` file with your values.  It should look similar to the file shown below:

```
apiVersion: v1
kind: Secret
metadata:
  name: oudsecret
  namespace: oudns
type: Opaque
data:
  rootUserDN: Y249RGlyZWN0b3J5IE1hbmFnZXI=
  rootUserPassword: T3JhY2xlMTIz
  adminUID: YWRtaW4=
  adminPassword: T3JhY2xlMTIz
  bindDN1: Y249RGlyZWN0b3J5IE1hbmFnZXI=
  bindPassword1: T3JhY2xlMTIz
  bindDN2: Y249RGlyZWN0b3J5IE1hbmFnZXI=
  bindPassword2: T3JhY2xlMTIz
```
          
Apply the file:

```
$ kubectl apply -f secrets.yaml
secret/oudsecret created
```
       
Verify that the secret has been created:

```
$ kubectl --namespace oudns get secret
NAME                  TYPE                                  DATA   AGE
default-token-fztcb   kubernetes.io/service-account-token   3      15m
oudsecret             Opaque                                8      99s
```

##### Using `kubectl create secret` command

The Kubernetes secret can be created using the command line with the following syntax:

```
$ kubectl --namespace %NAMESPACE% create secret generic %SECRET_NAME% \
      --from-literal=rootUserDN="%rootUserDN%" \
      --from-literal=rootUserPassword="%rootUserPassword%" \
      --from-literal=adminUID="%adminUID%" \
      --from-literal=adminPassword="%adminPassword%" \
      --from-literal=bindDN1="%bindDN1%" \
      --from-literal=bindPassword1="%bindPassword1%" \
      --from-literal=bindDN2="%bindDN2%" \
      --from-literal=bindPassword2="%bindPassword2%" 
```

Update the following placeholders in the command with the relevant value:

*  `%NAMESPACE%` - With name of namespace in which secret is required to be created
*  `%SECRET_NAME%` - Name for the secret object
*  `%rootUserDN%` - With Base64 encoded value for  rootUserDN parameter.
*  `%rootUserPassword%` - With Base64 encoded value for rootUserPassword parameter.
*  `%adminUID%` - With Base64 encoded value for adminUID parameter.
*  `%adminPassword%` - With Base64 encoded value for adminPassword parameter.
*  `%bindDN1%` - With Base64 encoded value for bindDN1 parameter.
*  `%bindPassword1%` - With Base64 encoded value for bindPassword1 parameter.
*  `%bindDN2%` - With Base64 encoded value for bindDN2 parameter.
*  `%bindPassword2%` - With Base64 encoded value for bindPassword2 parameter.

After executing the `kubectl create secret` command, verify that the secret has been created:

```
$ kubectl --namespace oudns get secret
NAME                  TYPE                                  DATA   AGE
default-token-fztcb   kubernetes.io/service-account-token   3      15m
oudsecret             Opaque                                8      99s
```

#### Prepare a Host Directory to be used for Filesystem Based PersistentVolume

It is required to prepare a directory on the Host filesystem to store Oracle Unified Directory Instances and other configuration outside the container filesystem. That directory from the Host filesystem will be associated with a PersistentVolume.

**In the case of a multi-node Kubernetes cluster, the Host directory to be associated with the PersistentVolume should be accessible on all the nodes at the same path.**

To prepare a Host directory (for example: /scratch/user_projects) for mounting as a file system based PersistentVolume inside your containers, execute the command below on your Host:

> The userid can be anything but it must have uid:guid as 1000:1000, which is the same as the 'oracle' user running in the container.
> This ensures the 'oracle' user has access to the shared volume/directory.

```
$ sudo su - root
$ mkdir -p /scratch/user_projects
$ chown 1000:1000 /scratch/user_projects
$ exit
```

All container operations are performed as the **oracle** user.

**Note**: If a user already exists with **-u 1000 -g 1000** then use the same user. Else modify the existing user to have uid-gid as **'-u 1000 -g 1000'**

#### Create PersistentVolume (PV) and PersistentVolumeClaim (PVC) for your Namespace

A PersistentVolume (PV) is a storage resource, while a PersistentVolumeClaim (PVC) is a request for that resource.  To provide storage for your namespace, update the `persistent-volume.yaml` file.

Update the following to values specific to your environment:

| Param            | Value                       | Example                         |
| ---------------- | --------------------------- | ------------------------------- |
| `%PV_NAME%`      | PV name                     | oudpv                           |
| `%PV_HOST_PATH%` | Valid path on localhost     | /scratch/user_projects          |
| `%PVC_NAME%`     | PVC name                    | oudpvc                          |
| `%NAMESPACE%`    | Namespace                   | oudns                           |

Apply the file:

```
$ kubectl apply -f persistent-volume.yaml
persistentvolume/oudpv created
persistentvolumeclaim/oudpvc created
```

Verify the PersistentVolume:

```
$ kubectl --namespace oudns describe persistentvolume oudpv
Name:            oudpv
Labels:          type=oud-pv
Annotations:     pv.kubernetes.io/bound-by-controller: yes
Finalizers:      [kubernetes.io/pv-protection]
StorageClass:    manual
Status:          Bound
Claim:           oudns/oudpvc
Reclaim Policy:  Retain
Access Modes:    RWX
VolumeMode:      Filesystem
Capacity:        10Gi
Node Affinity:   <none>
Message:
Source:
    Type:          HostPath (bare host directory volume)
    Path:          /scratch/user_projects
    HostPathType:
Events:            <none>
```

Verify the PersistentVolumeClaim:

```
$ kubectl --namespace oudns describe pvc oudpvc
Name:          oudpvc
Namespace:     oudns
StorageClass:  manual
Status:        Bound
Volume:        oudpv
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      10Gi
Access Modes:  RWX
VolumeMode:    Filesystem
Mounted By:    <none>
Events:        <none>
```

### Directory Server (instanceType=Directory)

In this example you create a POD (`oudpod1`) which comprises a single container based on an Oracle Unified Directory 12c PS4 (12.2.1.4.0) image.

To create the POD update the `oud-dir-pod.yaml` file.

Update the following to values specific to your environment:

| Param         | Value                       | Example               |
| ------------- | --------------------------- | --------------------- |
| `%NAMESPACE%`   | Namespace                   | oudns               |
| `%IMAGE%`       | Oracle image tag            | oracle/oud:12.2.1.4.0 |
| `%SECRET_NAME%` | Secret name                 | oudsecret             |
| `%PV_NAME%`     | PV name                     | oudpv                 |
| `%PVC_NAME%`    | PVC name                    | oudpvc                |

Apply the file:

```
$ kubectl apply -f oud-dir-pod.yaml
pod/oudpod1 created
```
        
To check the status of the created pod:

```
$  kubectl get pods -n oudns
NAME      READY   STATUS    RESTARTS   AGE
oudpod1   1/1     Running   0          14m
```

If you see any errors then use the following commands to debug the pod/container.

To review issues with the pod e.g. CreateContainerConfigError:

```
$ kubectl --namespace <namespace> describe pod <pod>
```

For example:

```
$ kubectl --namespace oudns describe pod oudpod1
```
        
To tail the container logs while it is initializing use the following command:

```
$ kubectl --namespace <namespace> logs -f -c <container> <pod>
```

For example:

```
$ kubectl --namespace oudns logs -f -c oudds1 oudpod1
```
        
To view the full container logs:

```
$ kubectl --namespace <namespace> logs -c <container> <pod>
```
        
To validate that the Oracle Unified Directory directory server instance is running, connect to the container:

```
$ kubectl --namespace oudns exec -it -c oudds1 oudpod1 /bin/bash
```
        
In the container, run ldapsearch to return entries from the directory server:

```
$ cd /u01/oracle/user_projects/oudpod1/OUD/bin
$ ./ldapsearch -h localhost -p 1389 -D "cn=Directory Manager" -w Oracle123 -b "" -s sub "(objectclass=*)" dn
dn: dc=example1,dc=com
dn: ou=People,dc=example1,dc=com
dn: uid=user.0,ou=People,dc=example1,dc=com
...
dn: uid=user.99,ou=People,dc=example1,dc=com
```

To exit the bash session type **exit**.

### Directory Server (instanceType=Directory) as a Kubernetes Service

In this example you will create two pods and 2 associated containers, both running Oracle Unified Directory 12c Directory Server instances.  This demonstrates how you can expose Oracle Unified Directory 12c as a network service.  This provides a way of abstracting access to the backend service independent of the pod details.

To create the POD update the `oud-dir-svc.yaml` file.

Update the following to values specific to your environment:

| Param         | Value                       | Example               |
| ------------- | --------------------------- | --------------------- |
| `%NAMESPACE%`   | Namespace                   | oudns               |
| `%IMAGE%`       | Oracle image tag            | oracle/oud:12.2.1.4.0 |
| `%SECRET_NAME%` | Secret name                 | oudsecret             |
| `%PV_NAME%`     | PV name                     | oudpv                 |
| `%PVC_NAME%`    | PVC name                    | oudpvc                |

Apply the file:

```
$ kubectl apply -f oud-dir-svc.yaml
service/oud-dir-svc-1 created
pod/oud-dir1 created
service/oud-dir-svc-2 created
pod/oud-dir2 created
```

To check the status of the created pods (oud-dir1 and oud-dir2) and services (oud-dir-svc-1 and oud-dir-svc-2):

```
$  kubectl --namespace oudns get all
NAME           READY   STATUS    RESTARTS   AGE
pod/oud-dir1   1/1     Running   0          28m
pod/oud-dir2   1/1     Running   0          28m
pod/oudpod1    1/1     Running   0          22h
        
NAME                    TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                                                                    AGE
service/oud-dir-svc-1   NodePort   10.107.171.235   <none>        1444:30616/TCP,1888:32605/TCP,1389:31405/TCP,1636:32544/TCP,1080:31509/TCP,1081:32395/TCP,1898:31116/TCP   28m
service/oud-dir-svc-2   NodePort   10.106.206.229   <none>        1444:30882/TCP,1888:30427/TCP,1389:31299/TCP,1636:31529/TCP,1080:30056/TCP,1081:30458/TCP,1898:31796/TCP   28m
```
    
From this example you can see that the following service port mappings are available to access the container:

		service/oud-dir-svc-1 : 10.107.171.235 : 1389:31405
		service/oud-dir-svc-2 : 10.106.206.229 : 1389:31299
        
To access the Oracle Unified Directory directory server running in pod/oud-dir1 via the LDAP port 1389 you would use the service port : 31405.

To access the Oracle Unified Directory directory server running in pod/oud-dir2 via the LDAP port 1389 you would use the service port : 31299.

For example:

**Note**: use the `ldapsearch` from the Oracle Unified Directory ORACLE_HOME when accessing the cluster externally.

```
$ ldapsearch -h $HOSTNAME -p 31405 -D "cn=Directory Manager" -w Oracle123 -b "" -s sub "(objectclass=*)" dn
dn: dc=example1,dc=com
dn: ou=People,dc=example1,dc=com
dn: uid=user.0,ou=People,dc=example1,dc=com
...
dn: uid=user.98,ou=People,dc=example1,dc=com
dn: uid=user.99,ou=People,dc=example1,dc=com
      
$ ldapsearch -h $HOSTNAME -p 31299 -D "cn=Directory Manager" -w Oracle123 -b "" -s sub "(objectclass=*)" dn
dn: dc=example2,dc=com
dn: ou=People,dc=example2,dc=com
dn: uid=user.0,ou=People,dc=example2,dc=com
...
dn: uid=user.98,ou=People,dc=example2,dc=com
dn: uid=user.99,ou=People,dc=example2,dc=com
```

#### Validation

It is possible to access the Oracle Unified Directory instances and the data within externally from the cluster, using commands like `curl`.  In this way you can access interfaces exposed through NodePort. In the example below, two services (`service/oud-dir-svc-1` and `service/oud-dir-svc-2`) expose a set of ports. The following `curl` commands can be executed against the ports exposed through each service.

##### Curl command example for Oracle Unified Directory Admin REST:

```
curl --noproxy "*" --insecure --location --request GET \
'https://<HOSTNAME>:<AdminHttps NodePort mapped to 1888>/rest/v1/admin/?scope=base&attributes=%2b' \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz'
```

where `Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz` is the base64 encoded version of : `cn=Directory Manager:Oracle123`

##### Curl command example for Oracle Unified Directory Data REST :

```
curl --noproxy "*" --insecure --location --request GET \
'https://<HOSTNAME>:<Https NodePort mapped to 1081>/rest/v1/directory/?scope=base&attributes=%2b' \
--header 'Authorization: Basic Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz'
```

##### Curl command example for Oracle Unified Directory Data SCIM:

```
curl --noproxy "*" --insecure --location --request GET \
'https://<HOSTNAME>:<Https NodePort mapped to 1081>/iam/directory/oud/scim/v1/Schemas/urn:ietf:params:scim:schemas:core:2.0:Schema' \
--header 'Authorization: Basic Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz'
```

### Proxy Server (instanceType=Proxy) as a Kubernetes Service

In this example you will create a service, pod and associated container, in which an Oracle Unified Directory 12c Proxy Server instance is deployed.  This acts as a proxy to the 2 services you created in the previous example.

To create the POD update the `oud-ds_proxy-svc.yaml` file.

Update the following to values specific to your environment:

| Param         | Value                       | Example               |
| ------------- | --------------------------- | --------------------- |
| `%NAMESPACE%`   | Namespace                   | oudns               |
| `%IMAGE%`       | Oracle image tag            | oracle/oud:12.2.1.4.0 |
| `%SECRET_NAME%` | Secret name                 | oudsecret             |
| `%PV_NAME%`     | PV name                     | oudpv                 |
| `%PVC_NAME%`    | PVC name                    | oudpvc                |

Apply the file:

```
$ kubectl apply -f oud-ds_proxy-svc.yaml
service/oud-ds-proxy-svc created
pod/oudp1 created
```

Check the status of the new pod/service:

```
$ kubectl --namespace oudns get all
NAME           READY   STATUS    RESTARTS   AGE
pod/oud-dir1   1/1     Running   0          166m
pod/oud-dir2   1/1     Running   0          166m
pod/oudp1      1/1     Running   0          20m
pod/oudpod1    1/1     Running   0          25h
    
NAME                       TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                                                                    AGE
service/oud-dir-svc-1      NodePort   10.107.171.235   <none>        1444:30616/TCP,1888:32605/TCP,1389:31405/TCP,1636:32544/TCP,1080:31509/TCP,1081:32395/TCP,1898:31116/TCP   166m
service/oud-dir-svc-2      NodePort   10.106.206.229   <none>        1444:30882/TCP,1888:30427/TCP,1389:31299/TCP,1636:31529/TCP,1080:30056/TCP,1081:30458/TCP,1898:31796/TCP   166m
service/oud-ds-proxy-svc   NodePort   10.103.41.171    <none>        1444:30878/TCP,1888:30847/TCP,1389:31810/TCP,1636:30873/TCP,1080:32076/TCP,1081:30762/TCP,1898:31269/TCP   20m
```

Verify operation of the proxy server, accessing through the external service port:

```
$ ldapsearch -h $HOSTNAME -p 31810 -D "cn=Directory Manager" -w Oracle123 -b "" -s sub "(objectclass=*)" dn
dn: dc=example1,dc=com
dn: ou=People,dc=example1,dc=com
dn: uid=user.0,ou=People,dc=example1,dc=com
...
dn: uid=user.99,ou=People,dc=example1,dc=com
dn: dc=example2,dc=com
dn: ou=People,dc=example2,dc=com
dn: uid=user.0,ou=People,dc=example2,dc=com
...
dn: uid=user.98,ou=People,dc=example2,dc=com
dn: uid=user.99,ou=People,dc=example2,dc=com
```

**Note**: Entries are returned from both backend directory servers (dc=example1,dc=com and dc=example2,dc=com) via the proxy server.

### Replication Server (instanceType=Replication) as a Kubernetes Service

In this example you will create a service, pod and associated container, in which an Oracle Unified Directory 12c Replication Server instance is deployed.  This creates a single Replication Server which has 2 Directory Servers as its replication group.  This example extends the Oracle Unified Directory instances created as part of [Directory Server (instanceType=Directory) as a Kubernetes Service](#directory-server-instancetypedirectory-as-a-kubernetes-service).

To create the POD update the `oud-ds_rs_ds-svc.yaml` file.

Update the following to values specific to your environment:

| Param         | Value                       | Example               |
| ------------- | --------------------------- | --------------------- |
| `%NAMESPACE%`   | Namespace                   | oudns               |
| `%IMAGE%`       | Oracle image tag            | oracle/oud:12.2.1.4.0 |
| `%SECRET_NAME%` | Secret name                 | oudsecret             |
| `%PV_NAME%`     | PV name                     | oudpv                 |
| `%PVC_NAME%`    | PVC name                    | oudpvc                |

Apply the file:

```
$ kubectl apply -f oud-ds_rs_ds-svc.yaml
service/oud-rs-svc-1 created
pod/oudpodrs1 created
service/oud-ds-svc-1a created
pod/oudpodds1a created
service/oud-ds-svc-1b created
pod/oudpodds1b created
```

Check the status of the new services:

```
$ kubectl --namespace oudns get all
NAME             READY   STATUS    RESTARTS   AGE
pod/oud-dir1     1/1     Running   0          2d20h
pod/oud-dir2     1/1     Running   0          2d20h
pod/oudp1        1/1     Running   0          2d18h
pod/oudpod1      1/1     Running   0          3d18h
pod/oudpodds1a   0/1     Running   0          2m44s
pod/oudpodds1b   0/1     Running   0          2m44s
pod/oudpodrs1    0/1     Running   0          2m45s
    
NAME                       TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                                                                    AGE
service/oud-dir-svc-1      NodePort   10.107.171.235   <none>        1444:30616/TCP,1888:32605/TCP,1389:31405/TCP,1636:32544/TCP,1080:31509/TCP,1081:32395/TCP,1898:31116/TCP   2d20h
service/oud-dir-svc-2      NodePort   10.106.206.229   <none>        1444:30882/TCP,1888:30427/TCP,1389:31299/TCP,1636:31529/TCP,1080:30056/TCP,1081:30458/TCP,1898:31796/TCP   2d20h
service/oud-ds-proxy-svc   NodePort   10.103.41.171    <none>        1444:30878/TCP,1888:30847/TCP,1389:31810/TCP,1636:30873/TCP,1080:32076/TCP,1081:30762/TCP,1898:31269/TCP   2d18h
service/oud-ds-svc-1a      NodePort   10.102.218.25    <none>        1444:30347/TCP,1888:30392/TCP,1389:32482/TCP,1636:31161/TCP,1080:31241/TCP,1081:32597/TCP                  2m45s
service/oud-ds-svc-1b      NodePort   10.104.6.215     <none>        1444:32031/TCP,1888:31621/TCP,1389:32511/TCP,1636:31698/TCP,1080:30737/TCP,1081:30748/TCP                  2m44s
service/oud-rs-svc-1       NodePort   10.110.237.193   <none>        1444:32685/TCP,1888:30176/TCP,1898:30543/TCP                                                               2m45s
```

#### Validation

To validate that the Oracle Unified Directory replication group is running, connect to the replication server container (oudrs1):

```
$ kubectl --namespace oudns exec -it -c oudrs1 oudpodrs1 /bin/bash
$ cd /u01/oracle/user_projects/oudpodrs1/OUD/bin
```
        
In the container, run dsreplication to return details of the replication group:

```
$ ./dsreplication status --trustAll --hostname localhost --port 1444 --adminUID admin --dataToDisplay compat-view --dataToDisplay rs-connections

>>>> Specify Oracle Unified Directory LDAP connection parameters

Password for user 'admin':

Establishing connections and reading configuration ..... Done.

dc=example1,dc=com - Replication Enabled
========================================

Server              : Entries  : M.C. [1] : A.O.M.C. [2] : Port [3] : Encryption [4] : Trust [5] : U.C. [6] : Status [7] : ChangeLog [8] : Group ID [9] : Connected To [10]
--------------------:----------:----------:--------------:----------:----------------:-----------:----------:------------:---------------:--------------:---------------------------
oud-rs-svc-1:1444   : -- [11]  : 0        : --           : 1898     : Disabled       : --        : --       : Up         : --            : 1            : --
oud-ds-svc-1a:1444  : 1        : 0        : 0            : -- [12]  : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : oud-rs-svc-1:1898 (GID=1)
oud-ds-svc-1b:1444  : 1        : 0        : 0            : -- [12]  : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : oud-rs-svc-1:1898 (GID=1)
```

You can see that the Replication Server is running as the oud-rs-svc-1:1444, while you have Directory Server services running on oud-ds-svc-1a:1444 and oud-ds-svc-1b:1444.

To exit the bash session type **exit**.

From outside the cluster, you can invoke `curl` commands, as shown in the following examples, to access interfaces exposed through NodePort. In this example, there are two Directory services (`service/oud-ds-svc-1a` and `service/oud-ds-svc-1b`) exposing a set of ports. The following `curl` commands can be executed against ports exposed through each service.

##### Curl command example for Oracle Unified Directory Admin REST:

```
curl --noproxy "*" --insecure --location --request GET \
'https://<HOSTNAME>:<AdminHttps NodePort mapped to 1888>/rest/v1/admin/?scope=base&attributes=%2b' \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz'
```

where `Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz` is the base64 encoded version of : `cn=Directory Manager:Oracle123`

**Note:** This can be executed against the replication service (`oud-rs-svc-1`) as well.

##### Curl command example for Oracle Unified Directory Data REST :

```
curl --noproxy "*" --insecure --location --request GET \
'https://<HOSTNAME>:<Https NodePort mapped to 1081>/rest/v1/directory/?scope=base&attributes=%2b' \
--header 'Authorization: Basic Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz'
```

##### Curl command example for Oracle Unified Directory Data SCIM:

```
curl --noproxy "*" --insecure --location --request GET \
'https://<HOSTNAME>:<Https NodePort mapped to 1081>/iam/directory/oud/scim/v1/Schemas/urn:ietf:params:scim:schemas:core:2.0:Schema' \
--header 'Authorization: Basic Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz'
```

### Directory Server/Service added to existing Replication Server/Service (instanceType=AddDS2RS)

In this example you will create services, pods and containers, in which Oracle Unified Directory 12c Replication Server instances are deployed.  In this case 2 Replication/Directory Server Services are added, in addition the Directory Server created in [Directory Server (instanceType=Directory) as a Kubernetes Service]({{< relref "#directory-server-instancetypedirectory-as-a-kubernetes-service">}}) (oud-dir-svc-2) is added to the replication group.

To create the POD update the `oud-ds-plus-rs-svc.yaml` file.

Update the following to values specific to your environment:

| Param         | Value                       | Example               |
| ------------- | --------------------------- | --------------------- |
| `%NAMESPACE%`   | Namespace                   | oudns               |
| `%IMAGE%`       | Oracle image tag            | oracle/oud:12.2.1.4.0 |
| `%SECRET_NAME%` | Secret name                 | oudsecret             |
| `%PV_NAME%`     | PV name                     | oudpv                 |
| `%PVC_NAME%`    | PVC name                    | oudpvc                |

Apply the file:

```
$ kubectl apply -f oud-ds-plus-rs-svc.yaml
service/oud-dsrs-svc-1 created
pod/ouddsrs1 created
service/oud-dsrs-svc-2 created
pod/ouddsrs2 created
```

Check the status of the new services:

```
$ kubectl --namespace oudns get all
NAME             READY   STATUS    RESTARTS   AGE
pod/oud-dir1     1/1     Running   0          3d
pod/oud-dir2     1/1     Running   0          3d
pod/ouddsrs1     0/1     Running   0          75s
pod/ouddsrs2     0/1     Running   0          75s
pod/oudp1        1/1     Running   0          2d21h
pod/oudpod1      1/1     Running   0          3d22h
pod/oudpodds1a   1/1     Running   0          3h33m
pod/oudpodds1b   1/1     Running   0          3h33m
pod/oudpodrs1    1/1     Running   0          3h33m
    
NAME                       TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                                                                    AGE
service/oud-dir-svc-1      NodePort   10.107.171.235   <none>        1444:30616/TCP,1888:32605/TCP,1389:31405/TCP,1636:32544/TCP,1080:31509/TCP,1081:32395/TCP,1898:31116/TCP   3d
service/oud-dir-svc-2      NodePort   10.106.206.229   <none>        1444:30882/TCP,1888:30427/TCP,1389:31299/TCP,1636:31529/TCP,1080:30056/TCP,1081:30458/TCP,1898:31796/TCP   3d
service/oud-ds-proxy-svc   NodePort   10.103.41.171    <none>        1444:30878/TCP,1888:30847/TCP,1389:31810/TCP,1636:30873/TCP,1080:32076/TCP,1081:30762/TCP,1898:31269/TCP   2d21h
service/oud-ds-svc-1a      NodePort   10.102.218.25    <none>        1444:30347/TCP,1888:30392/TCP,1389:32482/TCP,1636:31161/TCP,1080:31241/TCP,1081:32597/TCP                  3h33m
service/oud-ds-svc-1b      NodePort   10.104.6.215     <none>        1444:32031/TCP,1888:31621/TCP,1389:32511/TCP,1636:31698/TCP,1080:30737/TCP,1081:30748/TCP                  3h33m
service/oud-dsrs-svc-1     NodePort   10.102.118.29    <none>        1444:30738/TCP,1888:30935/TCP,1389:32438/TCP,1636:32109/TCP,1080:31776/TCP,1081:31897/TCP,1898:30874/TCP   75s
service/oud-dsrs-svc-2     NodePort   10.98.139.53     <none>        1444:32312/TCP,1888:30595/TCP,1389:31376/TCP,1636:30090/TCP,1080:31238/TCP,1081:31174/TCP,1898:31863/TCP   75s
service/oud-rs-svc-1       NodePort   10.110.237.193   <none>        1444:32685/TCP,1888:30176/TCP,1898:30543/TCP   3h33m
```

#### Validation

To validate that the Oracle Unified Directory replication group is running, connect to the replication server container (oudrs1):

```
$ kubectl --namespace oudns exec -it -c ouddsrs ouddsrs1 /bin/bash
$ cd /u01/oracle/user_projects/ouddsrs1/OUD/bin
```
        
In the container, run dsreplication to return details of the replication group:

```
$ ./dsreplication status --trustAll --hostname localhost --port 1444 --adminUID admin --dataToDisplay compat-view --dataToDisplay rs-connections

>>>> Specify Oracle Unified Directory LDAP connection parameters

Password for user 'admin':

Establishing connections and reading configuration ..... Done.

dc=example2,dc=com - Replication Enabled
========================================

Server               : Entries : M.C. [1] : A.O.M.C. [2] : Port [3] : Encryption [4] : Trust [5] : U.C. [6] : Status [7] : ChangeLog [8] : Group ID [9] : Connected To [10]
--------------------:---------:----------:--------------:----------:----------------:-----------:----------:------------:---------------:--------------:-----------------------------
oud-dir-svc-2:1444   : 102     : 0        : 0            : 1898     : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : oud-dir-svc-2:1898 (GID=1)
oud-dsrs-svc-1:1444  : 102     : 0        : 0            : 1898     : Disabled       : Trusted   : --       : Normal     : Enabled       : 2            : oud-dsrs-svc-1:1898 (GID=2)
oud-dsrs-svc-2:1444  : 102     : 0        : 0            : 1898     : Disabled       : Trusted   : --       : Normal     : Enabled       : 2            : oud-dsrs-svc-2:1898 (GID=2)

Replication Server [11]   : RS #1 : RS #2 : RS #3 
--------------------------:-------:-------:-------
oud-dir-svc-2:1898 (#1)   : --    : Yes   : Yes   
oud-dsrs-svc-1:1898 (#2)  : Yes   : --    : Yes   
oud-dsrs-svc-2:1898 (#3)  : Yes   : Yes   : --    
```

From outside the cluster, you can invoke curl commands like following for accessing interfaces exposed through NodePort. In this example, there are two services (service/oud-dsrs-svc-1 and service/oud-dsrs-svc-2) exposing set of ports. Following curl commands can be executed against ports exposed through each service.

To exit the bash session type **exit**.

##### Curl command example for Oracle Unified Directory Admin REST:

```
curl --noproxy "*" --insecure --location --request GET \
'https://<HOSTNAME>:<AdminHttps NodePort mapped to 1888>/rest/v1/admin/?scope=base&attributes=%2b' \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz'
```

where `Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz` is the base64 encoded version of : `cn=Directory Manager:Oracle123`

##### Curl command example for Oracle Unified Directory Data REST :

```
curl --noproxy "*" --insecure --location --request GET \
'https://<HOSTNAME>:<Https NodePort mapped to 1081>/rest/v1/directory/?scope=base&attributes=%2b' \
--header 'Authorization: Basic Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz'
```

##### Curl command example for Oracle Unified Directory Data SCIM:

```
curl --noproxy "*" --insecure --location --request GET \
'https://<HOSTNAME>:<Https NodePort mapped to 1081>/iam/directory/oud/scim/v1/Schemas/urn:ietf:params:scim:schemas:core:2.0:Schema' \
--header 'Authorization: Basic Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz'
```

### Appendix A : Reference

Before using these sample yaml files, the following variables must be updated:

*  %NAMESPACE% - with value for Kubernetes namespace of your choice
*  %IMAGE% - with exact docker image for oracle/oud:12.2.1.x.x
*  %PV_NAME% - with value of the persistent volume name of your choice
*  %PV_HOST_PATH% - with value of the persistent volume Host Path (Directory Path which would be used as storage path for volume)
*  %PVC_NAME% - with value of the persistent volume claim name of your choice
*  %SECRET_NAME% - with value of the secret name which can be created using secrets.yaml file.
*  %rootUserDN% - With Base64 encoded value for  rootUserDN parameter.
*  %rootUserPassword% - With Base64 encoded value for rootUserPassword parameter.
*  %adminUID% - With Base64 encoded value for adminUID parameter.
*  %adminPassword% - With Base64 encoded value for adminPassword parameter.
*  %bindDN1% - With Base64 encoded value for bindDN1 parameter.
*  %bindPassword1% - With Base64 encoded value for bindPassword1 parameter.
*  %bindDN2% - With Base64 encoded value for bindDN2 parameter.
*  %bindPassword2% - With Base64 encoded value for bindPassword2 parameter.


#### oudns.yaml

This is a sample file to create a Kubernetes namespace.

#### persistent-volume.yaml

This is a sample file to create Persistent Volume and Persistent Volume Claim

#### secrets.yaml

This is a sample file to create the Kubernetes secrets which can be used to substitute values during Pod creation.

The keys below will be honoured by the different Oracle Unified Directory yaml files

* rootUserDN
* rootUserPassword
* adminUID
* adminPassword
* bindDN1
* bindPassword1
* bindDN2
* bindPassword2

All the values of the keys should be encoded using the command below and the encoded value should be used in the `secrets.yaml` file.

To generate an encoded value for keys in Base64 format, execute the following command:

```
$ echo -n 'MyPassword' | base64
TXlQYXNzd29yZA==
```

#### oud-dir-pod.yaml

This is a sample file to create POD (`oudpod1`) and a container for an Oracle Unified Directory Directory Instance.

#### oud-ds_proxy-svc.yaml

This is a sample file to create:

* POD (`oudds1`) with container for Oracle Unified Directory Directory Instance (dc=example1,dc=com)
* POD (`oudds2`) with container for Oracle Unified Directory Directory Instance (dc=example2,dc=com)
* POD (`oudp1`) with container for Oracle Unified Directory Directory Proxy referring to Oracle Unified Directory Directory Instances (oudds1 and oudds2) for dc=example1,dc=com and dc=example2,dc=com
* Service (`oud-ds-proxy-svc`) referring to POD with Oracle Unified Directory Directory Proxy (oudp1) 

#### oud-ds_rs_ds-svc.yaml

This is a sample file to create:

* POD (`oudpodds1`) with container for Oracle Unified Directory Directory Instance (dc=example1,dc=com)
* POD (`oudpodrs1`) with container for Oracle Unified Directory Replication Server Instance connected to Oracle Unified Directory Directory Instance (oudpodds1)
* POD (`oudpodds1a`) with container for Oracle Unified Directory Directory Instance having replication enabled through Replication Server Instance (oudpodrs1)
* POD (`oudpodds1b`) with container for Oracle Unified Directory Directory Instance having replication enabled through Replication Server Instance (oudpodrs1)
* Service (oud-ds-rs-ds-svc) referring to all PODs

The following command can be executed in the container to check the status of the replicated instances: 

```
$ /u01/oracle/user_projects/oudpodrs1/OUD/bin/dsreplication status \
--trustAll --hostname oudpodrs1.oud-ds-rs-ds-svc.oudns.svc.cluster.local --port 1444 \
--dataToDisplay compat-view
```

#### oud-ds-plus-rs-svc.yaml

This is a sample file to create 3 replicated DS+RS Instances:
* POD (`ouddsrs1`) with container for Oracle Unified Directory Directory Server (dc=example1,dc=com) and Replication Server
* POD (`ouddsrs2`) with container for Oracle Unified Directory Directory Server (dc=example1,dc=com) and Replication Server
* Service (`oud-dsrs-svc`) referring to all PODs

The following command can be executed in the container to check the status of the replicated instances:

```
$ /u01/oracle/user_projects/ouddsrs1/OUD/bin/dsreplication status \
--trustAll --hostname ouddsrs1.oud-dsrs-svc.oudns.svc.cluster.local --port 1444 \
--dataToDisplay compat-view
```
