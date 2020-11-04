Oracle Unified Directory (OUD) on Kubernetes
============================================

## Contents
1. [Introduction](#introduction)
1. [Hardware and Software Requirements](#hardware-and-software-requirements)
1. [Prerequisites](#prerequisites)
1. [Example 1 Directory Server](#example-1-directory-server-instancetypedirectory)
1. [Example 2 Directory Server as a Kubernetes Service](#example-2-directory-server-instancetypedirectory-as-a-kubernetes-service)
1. [Example 3 Proxy Server as a Kubernetes Service](#example-3-proxy-server-instancetypeproxy-as-a-kubernetes-service)
1. [Example 4 Replication Server (instanceType=Replication) as a Kubernetes Service](#example-4-replication-server-instancetypereplication-as-a-kubernetes-service)
1. [Example 5 Directory Server/Service added to existing Replication Server/Service (instanceType=AddDS2RS)](#example-5-directory-serverservice-added-to-existing-replication-serverservice-instancetypeaddds2rs)
1. [Appendix Reference](#appendix-reference)

# Introduction
This project offers Sample YAML files and scripts to deploy Oracle Unified Directory Docker images based on 12cPS4 (12.2.1.4.0) release within a Kubernetes environment. Use these YAML files to facilitate installation, configuration, and environment setup for DevOps users. 

The Docker Image refers to binaries for OUD Release 12.2.1.4.0 and it has the capability to create different types of OUD Instances (Directory Service, Proxy, Replication) on containers targeted for development and testing.

***Image***: oracle/oud:12.2.1.4.0

# Hardware and Software Requirements
Oracle Unified Directory Docker Image has been tested and is known to run on following hardware and software:

## Hardware Requirements

| Hardware  | Size  |
| :-------: | :---: |
| RAM       | 16GB  |
| Disk Space| 200GB+|

## Software Requirements

|       | Version                        | Command to verify version |
| :---: | :----------------------------: | :-----------------------: |
| OS    | Oracle Linux 7.3 or higher     | more /etc/oracle-release  |
| Docker| Docker version 18.03 or higher | docker version            |
| K8s   | Kubernetes version 1.16.0+     | kubectl version

# Prerequisites

## Verify OS Version
OS version should be Oracle Linux 7.3 or higher.  To check this, issue the following command:

        # more /etc/oracle-release
        Oracle Linux Server release 7.5

## Verify Docker Version and OUD Image
Docker version should be 18.03 or higher.  To check this, issue the following command:

         # docker version
         Client: Docker Engine - Community
         Version:           18.09.8-ol
         ...

The Oracle Unified Directory Image for 12cPS4 (12.2.1.4.0) should be loaded into Docker.  Verify this by running the following:

        # docker images
        REPOSITORY                                     TAG                 IMAGE ID            CREATED             SIZE
        oracle/oud                                     12.2.1.4.0          1855f331f5ef        10 days ago         945MB
        ...

## Verify Kubernetes Version
Kubernetes version should be 1.16.0 or higher.  Verify by running the following:

        # kubectl version
	Client Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.4", GitCommit:"c96aede7b5205121079932896c4ad89bb93260af", GitTreeState:"clean", BuildDate:"2020-06-17T11:41:22Z", GoVersion:"go1.13.9", Compiler:"gc", Platform:"linux/amd64"}
	Server Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.4", GitCommit:"c96aede7b5205121079932896c4ad89bb93260af", GitTreeState:"clean", BuildDate:"2020-06-17T11:33:59Z", GoVersion:"go1.13.9", Compiler:"gc", Platform:"linux/amd64"}

## Create Kubernetes Namespace
You should create a Kubernetes namespace to provide a scope for other objects such as pods and services that you create in the environment.  To create your namespace you should refer to the samples/oudns.yaml file.

Update the samples/oudns.yaml file and replace %NAMESPACE% with the value of the namespace you would like to create.  In the example below the value 'myoudns' is used.

To create the namespace apply the file using kubectl:

        # kubectl apply -f samples/oudns.yaml
        namespace/myoudns created

Confirm that the namespace is created:

<pre>   # kubectl get namespaces
    NAME          STATUS   AGE
    default       Active   4d
    kube-public   Active   4d
    kube-system   Active   4d
    <strong>myoudns       Active   53s</strong></pre>

## Create Secrets for User IDs and Passwords

To protect sensitive information, namely user IDs and passwords, you should create Kubernetes Secrets for the key-value pairs with following keys. The Secret with key-value pairs will be used to pass values to containers created through OUD image:

*  rootUserDN
*  rootUserPassword
*  adminUID
*  adminPassword
*  bindDN1
*  bindPassword1
*  bindDN2
*  bindPassword2

There are two ways by which Secret object can be created with required key-value pairs.

### Using samples/secrets.yaml file

To do this you should update the samples/secrets.yaml file with the value for %SECRET_NAME% and %NAMESPACE%, together with the Base64 value for each secret.

*  %rootUserDN% - With Base64 encoded value for rootUserDN parameter.
*  %rootUserPassword% - With Base64 encoded value for rootUserPassword parameter.
*  %adminUID% - With Base64 encoded value for adminUID parameter.
*  %adminPassword% - With Base64 encoded value for adminPassword parameter.
*  %bindDN1% - With Base64 encoded value for bindDN1 parameter.
*  %bindPassword1% - With Base64 encoded value for bindPassword1 parameter.
*  %bindDN2% - With Base64 encoded value for bindDN2 parameter.
*  %bindPassword2% - With Base64 encoded value for bindPassword2 parameter.

Obtain the base64 value for your secrets:

<pre>   # echo -n cn=Directory Manager | base64
    Y249RGlyZWN0b3J5IE1hbmFnZXI=
    # echo -n Oracle123 | base64
    <b>T3JhY2xlMTIz</b>
    # echo -n admin | base64
    <strong>YWRtaW4=</strong></pre>

**Note**: Please make sure to use -n with echo command. Without that, Base64 values would be generated with new-line character included. 

Update the samples/secrets.yaml file with your values.  It should look similar to the file shown below:

        apiVersion: v1
        kind: Secret
        metadata:
          name: oudsecret
          namespace: myoudns
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
          
Apply the file:

        # kubectl apply -f samples/secrets.yaml
        secret/oudsecret created
        
Verify that the secret has been created:

<pre>   # kubectl --namespace myoudns get secret
    NAME                  TYPE                                  DATA   AGE
    default-token-fztcb   kubernetes.io/service-account-token   3      15m
    <strong>oudsecret             Opaque                                8      99s</strong></pre>

### Using `kubectl create secret` command

Kubernetes Secret can be created using following command:

        # kubectl --namespace %NAMESPACE% create secret generic %SECRET_NAME% \
          --from-literal=rootUserDN="%rootUserDN%" \
          --from-literal=rootUserPassword="%rootUserPassword%" \
          --from-literal=adminUID="%adminUID%" \
          --from-literal=adminPassword="%adminPassword%" \
          --from-literal=bindDN1="%bindDN1%" \
          --from-literal=bindPassword1="%bindPassword1%" \
          --from-literal=bindDN2="%bindDN2%" \
          --from-literal=bindPassword2="%bindPassword2%" 

In the command mentioned above, following placeholders are required to be updated:

*  %NAMESPACE% - With name of namespace in which secret is required to be created
*  %SECRET_NAME% - Name for the secret object
*  %rootUserDN% - With Base64 encoded value for rootUserDN parameter.
*  %rootUserPassword% - With Base64 encoded value for rootUserPassword parameter.
*  %adminUID% - With Base64 encoded value for adminUID parameter.
*  %adminPassword% - With Base64 encoded value for adminPassword parameter.
*  %bindDN1% - With Base64 encoded value for bindDN1 parameter.
*  %bindPassword1% - With Base64 encoded value for bindPassword1 parameter.
*  %bindDN2% - With Base64 encoded value for bindDN2 parameter.
*  %bindPassword2% - With Base64 encoded value for bindPassword2 parameter.

After executing `kubectl create secret ...` command, verify that the secret has been created:

<pre>   # kubectl --namespace myoudns get secret
    NAME                  TYPE                                  DATA   AGE
    default-token-fztcb   kubernetes.io/service-account-token   3      15m
    <strong>oudsecret             Opaque                                8      99s</strong></pre>

## Prepare a host directory to be used for Filesystem based PersistentVolume

It's required to prepare directory on Host filesystem to store OUD Instances and other configuration outside container filesystem. That directory from host filesystem would be associated with PersistentVolume.
**In case of multi-node Kubernetes cluster, directory to be associated with PersistentVolume should be accessible on all the nodes at the same path.**

To prepare a host directory (for example: /scratch/test/oud_user_projects) for mounting as file system based PersistentVolume inside containers, execute the command below on host:

> The userid can be anything but it must belong to uid:guid as 1000:1000, which is same as 'oracle' user running in the container.
> This ensures 'oracle' user has access to shared volume/directory.

```
sudo su - root
mkdir -p /scratch/test/oud_user_projects
chown 1000:1000 /scratch/test/oud_user_projects
exit
```

All container operations are performed as **'oracle'** user.

**Note**: If a user already exist with **'-u 1000 -g 1000'** then use the same user. Or modify any existing user to have uid-gid as **'-u 1000 -g 1000'**

## Create PersistentVolume (PV) and PersistentVolumeClaim (PVC) for your Namespace
A PV is storage resource, while PVC is a request for that resource.  To provide storage for your namespace, update the samples/persistent-volume.yaml file.

Update the following to values specific to your environment:

| Param         | Value                       | Example               |
| :-----------: | :-------------------------: | :-------------------: |
| %PV_NAME%     | PV name                     | oudpv                 |
| %PV_HOST_PATH% | Valid path on localhost    | /scratch/test/oud_user_projects |
| %PVC_NAME%    | PVC name                    | oudpvc                |
| %NAMESPACE%   | Namespace                   | myoudns               |

Apply the file:

        # kubectl apply -f samples/persistent-volume.yaml
        persistentvolume/oudpv created
        persistentvolumeclaim/oudpvc created

Verify the PersistentVolume:

        # kubectl --namespace myoudns describe persistentvolume oudpv
        Name:            oudpv
        Labels:          type=local
        Annotations:     kubectl.kubernetes.io/last-applied-configuration:
            {"apiVersion":"v1","kind":"PersistentVolume","metadata":{"annotations":{},"labels":{"type":"local"},"name":"oudpv"},"spec":{"accessModes":...
            pv.kubernetes.io/bound-by-controller: yes
        Finalizers:      [kubernetes.io/pv-protection]
        StorageClass:    oud-storage
        Status:          Bound
        Claim:           myoudns/oudpvc
        Reclaim Policy:  Retain
        Access Modes:    RWX
        VolumeMode:      Filesystem
        Capacity:        10Gi
        Node Affinity:   <none>
        Message:
        Source:
            Type:          HostPath (bare host directory volume)
            Path:          /scratch/test/oud_user_projects
            HostPathType:
        Events:            <none>

Verify the PersistentVolumeClaim:

        # kubectl --namespace myoudns describe pvc oudpvc
        Name:          oudpvc
        Namespace:     myoudns
        StorageClass:  oud-storage
        Status:        Bound
        Volume:        oudpv
        Labels:        <none>
        Annotations:   kubectl.kubernetes.io/last-applied-configuration:
            {"apiVersion":"v1","kind":"PersistentVolumeClaim","metadata":{"annotations":{},"name":"oudpvc","namespace":"myoudns"},"spec":{"accessModes...
            pv.kubernetes.io/bind-completed: yes
            pv.kubernetes.io/bound-by-controller: yes
        Finalizers:    [kubernetes.io/pvc-protection]
        Capacity:      10Gi
        Access Modes:  RWX
        VolumeMode:    Filesystem
        Events:        <none>
        Mounted By:    <none>

# Example 1 Directory Server (instanceType=Directory)

In this example you create a POD (oudpod1) which holds a single container based on an Oracle Unified Directory 12c PS4 (12.2.1.4.0) image.

To create the POD update the samples/oud-dir-pod.yaml file.

Update the following to values specific to your environment:

| Param         | Value                       | Example               |
| :-----------: | :-------------------------: | :-------------------: |
| %NAMESPACE%   | Namespace                   | myoudns               |
| %IMAGE%       | Oracle image tag            | oracle/oud:12.2.1.4.0 |
| %SECRET_NAME% | Secret name                 | oudsecret             |
| %PV_NAME%     | PV name                     | oudpv                 |
| %PVC_NAME%    | PVC name                    | oudpvc                |

Apply the file:

        # kubectl apply -f samples/oud-dir-pod.yaml
        pod/oudpod1 created
        
To check the status of the created pod:

<pre>   #  kubectl get pods -n myoudns
    NAME      READY   STATUS    RESTARTS   AGE
    <strong>oudpod1   1/1     Running   0          14m</strong></pre>

If you see any errors then use the following commands to debug the pod/container.

To review issues with the pod e.g. CreateContainerConfigError:

        # kubectl --namespace <namespace> describe pod <pod>

For example:

        # kubectl --namespace myoudns describe pod oudpod1
        
To tail the container logs while it is initialising use the following command:

        # kubectl --namespace <namespace> logs -f -c <container> <pod>

For example:

        # kubectl --namespace myoudns logs -c oudds1 oudpod1
        
To view the full container logs:

        # kubectl --namespace <namespace> logs -c <container> <pod>
        
To validate that the OUD directory server instance is running, connect to the container:

        # kubectl --namespace myoudns exec -it -c oudds1 oudpod1 /bin/bash
        
In the container, run ldapsearch to return entries from the directory server:

        # cd /u01/oracle/user_projects/oudpod1/OUD/bin
        # ./ldapsearch -h localhost -p 1389 -D "cn=Directory Manager" -w Oracle123 -b "" -s sub "(objectclass=*)" dn
        dn: dc=example1,dc=com
        dn: ou=People,dc=example1,dc=com
        dn: uid=user.0,ou=People,dc=example1,dc=com
        ...
        dn: uid=user.99,ou=People,dc=example1,dc=com

# Example 2 Directory Server (instanceType=Directory) as a Kubernetes Service

In this example you will create two pods and 2 associated containers, both running OUD 12s directory server instances.  This demonstrates how you can expose OUD 12c as a network service.  This provides a way of abstracting access to the backend service independent of the pod details.

To create the POD update the samples/oud-dir-svc.yaml file.

Update the following to values specific to your environment:

| Param         | Value                       | Example               |
| :-----------: | :-------------------------: | :-------------------: |
| %NAMESPACE%   | Namespace                   | myoudns               |
| %IMAGE%       | Oracle image tag            | oracle/oud:12.2.1.4.0 |
| %SECRET_NAME% | Secret name                 | oudsecret             |
| %PV_NAME%     | PV name                     | oudpv                 |
| %PVC_NAME%    | PVC name                    | oudpvc                |

Apply the file:

        # kubectl apply -f samples/oud-dir-svc.yaml
        service/oud-dir-svc-1 created
        pod/oud-dir1 created
        service/oud-dir-svc-2 created
        pod/oud-dir2 created

To check the status of the created pods (oud-dir1 and oud-dir2) and services (oud-dir-svc-1 and oud-dir-svc-2):

<pre>#  kubectl --namespace myoudns get all
    NAME           READY   STATUS    RESTARTS   AGE
    <strong>pod/oud-dir1</strong>   1/1     Running   0          28m
    <strong>pod/oud-dir2</strong>   1/1     Running   0          28m
    pod/oudpod1    1/1     Running   0          22h
        
    NAME                    TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                                                                    AGE
    <strong>service/oud-dir-svc-1</strong>   NodePort   10.107.171.235   <none>        1444:30616/TCP,1888:32605/TCP,1389:31405/TCP,1636:32544/TCP,1080:31509/TCP,1081:32395/TCP,1898:31116/TCP   28m
    <strong>service/oud-dir-svc-2</strong>   NodePort   10.106.206.229   <none>        1444:30882/TCP,1888:30427/TCP,1389:31299/TCP,1636:31529/TCP,1080:30056/TCP,1081:30458/TCP,1898:31796/TCP   28m</pre>
    
From this example you can see that the following service port mappings are available to access the container:

<pre>   service/oud-dir-svc-1 : 10.107.171.235 : <strong>1389:31405</strong>
    service/oud-dir-svc-2 : 10.106.206.229 : <strong>1389:31299</strong></pre>
        
To access the OUD directory server running in pod/oud-dir1 via the LDAP port 1389 you would use the service port : $HOSTNAME:31405.

To access the OUD directory server running in pod/oud-dir2 via the LDAP port 1389 you would use the service port : $HOSTNAME:31299.

For example:

        ldapsearch -h $HOSTNAME -p 31405 -D "cn=Directory Manager" -w Oracle123 -b "" -s sub "(objectclass=*)" dn
        dn: dc=example1,dc=com
        dn: ou=People,dc=example1,dc=com
        dn: uid=user.0,ou=People,dc=example1,dc=com
        ...
        dn: uid=user.98,ou=People,dc=example1,dc=com
        dn: uid=user.99,ou=People,dc=example1,dc=com
        
        ldapsearch -h $HOSTNAME -p 31299 -D "cn=Directory Manager" -w Oracle123 -b "" -s sub "(objectclass=*)" dn
        dn: dc=example2,dc=com
        dn: ou=People,dc=example2,dc=com
        dn: uid=user.0,ou=People,dc=example2,dc=com
        ...
        dn: uid=user.98,ou=People,dc=example2,dc=com
        dn: uid=user.99,ou=People,dc=example2,dc=com

## Validation

From outside the cluster, you can invoke curl commands like following for accessing interfaces exposed through NodePort. In this example, there are two services (service/oud-dir-svc-1 and service/oud-dir-svc-2) exposing set of ports. Following curl commands can be executed against ports exposed through each service.

### Curl command example for OUD Admin REST:

	curl --noproxy "*" --insecure --location --request GET \
	'https://<HOSTNAME>:<AdminHttps NodePort mapped to 1888>/rest/v1/admin/?scope=base&attributes=%2b' \
	--header 'Content-Type: application/json' \
	--header 'Authorization: Basic Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz' | json_pp

### Curl command example for OUD Data REST :

	curl --noproxy "*" --insecure --location --request GET \
	'https://<HOSTNAME>:<Https NodePort mapped to 1081>/rest/v1/directory/?scope=base&attributes=%2b' \
	--header 'Authorization: Basic Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz' | json_pp

### Curl command example for OUD Data SCIM:

	curl --noproxy "*" --insecure --location --request GET \
	'https://<HOSTNAME>:<Https NodePort mapped to 1081>/iam/directory/oud/scim/v1/Schemas/urn:ietf:params:scim:schemas:core:2.0:Schema' \
	--header 'Authorization: Basic Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz' | json_pp

# Example 3 Proxy Server (instanceType=Proxy) as a Kubernetes Service

In this example you will create a service, pod and associated container, in which an OUD 12c Proxy Server instance is deployed.  This acts as a proxy to the 2 services you created in the previous example.

To create the POD update the samples/oud-ds_proxy-svc.yaml file.

Update the following to values specific to your environment:

| Param         | Value                       | Example               |
| :-----------: | :-------------------------: | :-------------------: |
| %NAMESPACE%   | Namespace                   | myoudns               |
| %IMAGE%       | Oracle image tag            | oracle/oud:12.2.1.4.0 |
| %SECRET_NAME% | Secret name                 | oudsecret             |
| %PV_NAME%     | PV name                     | oudpv                 |
| %PVC_NAME%    | PVC name                    | oudpvc                |

Apply the file:

        # kubectl apply -f samples/oud-ds_proxy-svc.yaml
        service/oud-ds-proxy-svc created
        pod/oudp1 created

Check the status of the new pod/service:

<pre># kubectl --namespace myoudns get all
    NAME           READY   STATUS    RESTARTS   AGE
    pod/oud-dir1   1/1     Running   0          166m
    pod/oud-dir2   1/1     Running   0          166m
    <strong>pod/oudp1</strong>      1/1     Running   0          20m
    pod/oudpod1    1/1     Running   0          25h
    
    NAME                       TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                                                                    AGE
    service/oud-dir-svc-1      NodePort   10.107.171.235   <none>        1444:30616/TCP,1888:32605/TCP,1389:31405/TCP,1636:32544/TCP,1080:31509/TCP,1081:32395/TCP,1898:31116/TCP   166m
    service/oud-dir-svc-2      NodePort   10.106.206.229   <none>        1444:30882/TCP,1888:30427/TCP,1389:31299/TCP,1636:31529/TCP,1080:30056/TCP,1081:30458/TCP,1898:31796/TCP   166m
    <strong>service/oud-ds-proxy-svc</strong>   NodePort   10.103.41.171    <none>        1444:30878/TCP,1888:30847/TCP,1389:31810/TCP,1636:30873/TCP,1080:32076/TCP,1081:30762/TCP,1898:31269/TCP   20m</pre>

Verify operation of the proxy server, accessing through the external service port:

        # ldapsearch -h $HOSTNAME -p 31810 -D "cn=Directory Manager" -w Oracle123 -b "" -s sub "(objectclass=*)" dn
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

**Note**: Entries are returned from both backend directory servers (dc=example1,dc=com and dc=example2,dc=com) via the proxy server.

## Validation

From outside the cluster, you can invoke curl commands like following for accessing interfaces exposed through NodePort. In this example, there is a service (service/oud-ds-proxy-svc) exposing set of ports. 

### Curl command example for OUD Admin REST:

	curl --noproxy "*" --insecure --location --request GET \
	'https://<HOSTNAME>:<AdminHttps NodePort mapped to 1888>/rest/v1/admin/?scope=base&attributes=%2b' \
	--header 'Content-Type: application/json' \
	--header 'Authorization: Basic Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz' | json_pp

### Curl command example for OUD Data REST :

	curl --noproxy "*" --insecure --location --request GET \
	'https://<HOSTNAME>:<Https NodePort mapped to 1081>/rest/v1/directory/?scope=base&attributes=%2b' \
	--header 'Authorization: Basic Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz' | json_pp

### Curl command example for OUD Data SCIM:

	curl --noproxy "*" --insecure --location --request GET \
	'https://<HOSTNAME>:<Https NodePort mapped to 1081>/iam/directory/oud/scim/v1/Schemas/urn:ietf:params:scim:schemas:core:2.0:Schema' \
	--header 'Authorization: Basic Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz' | json_pp

# Example 4 Replication Server (instanceType=Replication) as a Kubernetes Service

In this example you will create a service, pod and associated container, in which an OUD 12 Replication Server instance is deployed.  This creates a single Replication Server which has 2 Directory Servers as its replication group.

To create the POD update the samples/oud-ds_rs_ds-svc.yaml file.

Update the following to values specific to your environment:

| Param         | Value                       | Example               |
| :-----------: | :-------------------------: | :-------------------: |
| %NAMESPACE%   | Namespace                   | myoudns               |
| %IMAGE%       | Oracle image tag            | oracle/oud:12.2.1.4.0 |
| %SECRET_NAME% | Secret name                 | oudsecret             |
| %PV_NAME%     | PV name                     | oudpv                 |
| %PVC_NAME%    | PVC name                    | oudpvc                |

Apply the file:

        # kubectl apply -f samples/oud-ds_rs_ds-svc.yaml
        service/oud-rs-svc-1 created
        pod/oudpodrs1 created
        service/oud-ds-svc-1a created
        pod/oudpodds1a created
        service/oud-ds-svc-1b created
        pod/oudpodds1b created

Check the status of the new services:

<pre># kubectl --namespace myoudns get all
    NAME             READY   STATUS    RESTARTS   AGE
    pod/oud-dir1     1/1     Running   0          2d20h
    pod/oud-dir2     1/1     Running   0          2d20h
    pod/oudp1        1/1     Running   0          2d18h
    pod/oudpod1      1/1     Running   0          3d18h
    <strong>pod/oudpodds1a</strong>   0/1     Running   0          2m44s
    <strong>pod/oudpodds1b</strong>   0/1     Running   0          2m44s
    <strong>pod/oudpodrs1</strong>    0/1     Running   0          2m45s
    
    NAME                       TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                                                                    AGE
    service/oud-dir-svc-1      NodePort   10.107.171.235   <none>        1444:30616/TCP,1888:32605/TCP,1389:31405/TCP,1636:32544/TCP,1080:31509/TCP,1081:32395/TCP,1898:31116/TCP   2d20h
    service/oud-dir-svc-2      NodePort   10.106.206.229   <none>        1444:30882/TCP,1888:30427/TCP,1389:31299/TCP,1636:31529/TCP,1080:30056/TCP,1081:30458/TCP,1898:31796/TCP   2d20h
    service/oud-ds-proxy-svc   NodePort   10.103.41.171    <none>        1444:30878/TCP,1888:30847/TCP,1389:31810/TCP,1636:30873/TCP,1080:32076/TCP,1081:30762/TCP,1898:31269/TCP   2d18h
    <strong>service/oud-ds-svc-1a</strong>      NodePort   10.102.218.25    <none>        1444:30347/TCP,1888:30392/TCP,1389:32482/TCP,1636:31161/TCP,1080:31241/TCP,1081:32597/TCP                  2m45s
    <strong>service/oud-ds-svc-1b</strong>      NodePort   10.104.6.215     <none>        1444:32031/TCP,1888:31621/TCP,1389:32511/TCP,1636:31698/TCP,1080:30737/TCP,1081:30748/TCP                  2m44s
    <strong>service/oud-rs-svc-1</strong>       NodePort   10.110.237.193   <none>        1444:32685/TCP,1888:30176/TCP,1898:30543/TCP                                                               2m45s</pre>

To validate that the OUD replication group is running, connect to the replication server container (oudrs1):

        # kubectl --namespace myoudns exec -it -c oudrs1 oudpodrs1 /bin/bash
        cd /u01/oracle/user_projects/oudpodrs1/OUD/bin
        
In the container, run dsreplication to return details of the replication group:

        # ./dsreplication status --trustAll --hostname localhost --port 1444 --adminUID admin --dataToDisplay compat-view --dataToDisplay rs-connections

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

You can see that the Replication Server is running as the oud-rs-svc-1:1444, while you have Directory Server services running on oud-ds-svc-1a:1444 and oud-ds-svc-1b:1444.

## Validation

From outside the cluster, you can invoke curl commands like following for accessing interfaces exposed through NodePort. In this example, there are two Directory services (service/oud-ds-svc-1a and service/oud-ds-svc-1b) exposing set of ports. Following curl commands can be executed against ports exposed through each service.

### Curl command example for OUD Admin REST:

	curl --noproxy "*" --insecure --location --request GET \
	'https://<HOSTNAME>:<AdminHttps NodePort mapped to 1888>/rest/v1/admin/?scope=base&attributes=%2b' \
	--header 'Content-Type: application/json' \
	--header 'Authorization: Basic Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz' | json_pp
> This can be executed against replication service (oud-rs-svc-1) as well.

### Curl command example for OUD Data REST :

	curl --noproxy "*" --insecure --location --request GET \
	'https://<HOSTNAME>:<Https NodePort mapped to 1081>/rest/v1/directory/?scope=base&attributes=%2b' \
	--header 'Authorization: Basic Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz' | json_pp

### Curl command example for OUD Data SCIM:

	curl --noproxy "*" --insecure --location --request GET \
	'https://<HOSTNAME>:<Https NodePort mapped to 1081>/iam/directory/oud/scim/v1/Schemas/urn:ietf:params:scim:schemas:core:2.0:Schema' \
	--header 'Authorization: Basic Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz' | json_pp

# Example 5 Directory Server/Service added to existing Replication Server/Service (instanceType=AddDS2RS)

In this example you will create services, pods and containers, in which OUD 12 Replication Server instances are deployed.  In this case, 2 Replication/Directory Server Services are added, in addition the Directory Server created in Example 2 (oud-dir-svc-2) is added to the replication group.

To create the POD update the samples/oud-ds-plus-rs-svc.yaml file.

Update the following to values specific to your environment:

| Param         | Value                       | Example               |
| :-----------: | :-------------------------: | :-------------------: |
| %NAMESPACE%   | Namespace                   | myoudns               |
| %IMAGE%       | Oracle image tag            | oracle/oud:12.2.1.4.0 |
| %SECRET_NAME% | Secret name                 | oudsecret             |
| %PV_NAME%     | PV name                     | oudpv                 |
| %PVC_NAME%    | PVC name                    | oudpvc                |

Apply the file:

        # kubectl apply -f samples/oud-ds-plus-rs-svc.yaml
        service/oud-dsrs-svc-1 created
        pod/ouddsrs1 created
        service/oud-dsrs-svc-2 created
        pod/ouddsrs2 created

Check the status of the new services:

<pre>   # kubectl --namespace myoudns get all
    NAME             READY   STATUS    RESTARTS   AGE
    pod/oud-dir1     1/1     Running   0          3d
    pod/oud-dir2     1/1     Running   0          3d
    <strong>pod/ouddsrs1</strong>     0/1     Running   0          75s
    <strong>pod/ouddsrs2</strong>     0/1     Running   0          75s
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
    <strong>service/oud-dsrs-svc-1</strong>     NodePort   10.102.118.29    <none>        1444:30738/TCP,1888:30935/TCP,1389:32438/TCP,1636:32109/TCP,1080:31776/TCP,1081:31897/TCP,1898:30874/TCP   75s
    <strong>service/oud-dsrs-svc-2</strong>     NodePort   10.98.139.53     <none>        1444:32312/TCP,1888:30595/TCP,1389:31376/TCP,1636:30090/TCP,1080:31238/TCP,1081:31174/TCP,1898:31863/TCP   75s
    service/oud-rs-svc-1       NodePort   10.110.237.193   <none>        1444:32685/TCP,1888:30176/TCP,1898:30543/TCP   3h33m</pre>

To validate that the OUD replication group is running, connect to the replication server container (oudrs1):

        # kubectl --namespace myoudns exec -it -c ouddsrs ouddsrs1 /bin/bash
        cd /u01/oracle/user_projects/ouddsrs1/OUD/bin
        
In the container, run dsreplication to return details of the replication group:

        # ./dsreplication status --trustAll --hostname localhost --port 1444 --adminUID admin --dataToDisplay compat-view --dataToDisplay rs-connections

        >>>> Specify Oracle Unified Directory LDAP connection parameters

        Password for user 'admin':

        Establishing connections and reading configuration ..... Done.

        dc=example2,dc=com - Replication Enabled
        ========================================

        Server               : Entries : M.C. [1] : A.O.M.C. [2] : Port [3] : Encryption [4] : Trust [5] : U.C. [6] : Status [7] : ChangeLog [8] : Group ID [9] : Connected To [10]
        ---------------------:---------:----------:--------------:----------:----------------:-----------:----------:------------:---------------:--------------:-----------------------------
        oud-dir-svc-2:1444   : 102     : 0        : 0            : 1898     : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : oud-dir-svc-2:1898 (GID=1)
        oud-dsrs-svc-1:1444  : 102     : 0        : 0            : 1898     : Disabled       : Trusted   : --       : Normal     : Enabled       : 2            : oud-dsrs-svc-1:1898 (GID=2)
        oud-dsrs-svc-2:1444  : 102     : 0        : 0            : 1898     : Disabled       : Trusted   : --       : Normal     : Enabled       : 2            : oud-dsrs-svc-2:1898 (GID=2)

        Replication Server [11]   : RS #1 : RS #2 : RS #3 
        --------------------------:-------:-------:-------
        oud-dir-svc-2:1898 (#1)   : --    : Yes   : Yes   
        oud-dsrs-svc-1:1898 (#2)  : Yes   : --    : Yes   
        oud-dsrs-svc-2:1898 (#3)  : Yes   : Yes   : --    


## Validation

From outside the cluster, you can invoke curl commands like following for accessing interfaces exposed through NodePort. In this example, there are two services (service/oud-dsrs-svc-1 and service/oud-dsrs-svc-2) exposing set of ports. Following curl commands can be executed against ports exposed through each service.

### Curl command example for OUD Admin REST:

	curl --noproxy "*" --insecure --location --request GET \
	'https://<HOSTNAME>:<AdminHttps NodePort mapped to 1888>/rest/v1/admin/?scope=base&attributes=%2b' \
	--header 'Content-Type: application/json' \
	--header 'Authorization: Basic Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz' | json_pp

### Curl command example for OUD Data REST :

	curl --noproxy "*" --insecure --location --request GET \
	'https://<HOSTNAME>:<Https NodePort mapped to 1081>/rest/v1/directory/?scope=base&attributes=%2b' \
	--header 'Authorization: Basic Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz' | json_pp

### Curl command example for OUD Data SCIM:

	curl --noproxy "*" --insecure --location --request GET \
	'https://<HOSTNAME>:<Https NodePort mapped to 1081>/iam/directory/oud/scim/v1/Schemas/urn:ietf:params:scim:schemas:core:2.0:Schema' \
	--header 'Authorization: Basic Y249RGlyZWN0b3J5IE1hbmFnZXI6T3JhY2xlMTIz' | json_pp


# Appendix Reference

Before using these sample yaml files, following variables are requried to be updated
*  %NAMESPACE% - with value for Kubernetes namespace of your choice
*  %IMAGE% - with exact docker image for oracle/oud:12.2.1.x.x
*  %PV_NAME% - with value of the persistent volume name of your choice
*  %PV_HOST_PATH% - with value of the persistent volume Host Path (Directory Path which would be used as storage path for volume)
*  %PVC_NAME% - with value of the persistent volume claim name of your choice
*  %SECRET_NAME% - with value of the secret name which can be created using samples/secrets.yaml file.
*  %rootUserDN% - With Base64 encoded value for  rootUserDN parameter.
*  %rootUserPassword% - With Base64 encoded value for rootUserPassword parameter.
*  %adminUID% - With Base64 encoded value for adminUID parameter.
*  %adminPassword% - With Base64 encoded value for adminPassword parameter.
*  %bindDN1% - With Base64 encoded value for bindDN1 parameter.
*  %bindPassword1% - With Base64 encoded value for bindPassword1 parameter.
*  %bindDN2% - With Base64 encoded value for bindDN2 parameter.
*  %bindPassword2% - With Base64 encoded value for bindPassword2 parameter.


## samples/oudns.yaml

This is a sample file to create Kubernetes namespace.

## samples/persistent-volume.yaml

This is a sample file to create Persistent volume and persistent volume claim

## samples/secrets.yaml

This is a sample file to create the secrets which can be used to create secrets for the pods.

Below keys will be honoured by different OUD yaml files
* rootUserDN
* rootUserPassword
* adminUID
* adminPassword
* bindDN1
* bindPassword1
* bindDN2
* bindPassword2

All the values of the keys should be encoded using the below command and provide the value in samples/secrets.yaml file.

example: To generate value for keys in Base64 format, following kind of command can be executed.
echo -n 'MyPassword' | base64
TXlQYXNzd29yZA==

**Note**: Please make sure to use -n with echo command. Without that, Base64 values would be generated with new-line character included. 

## samples/oud-dir-svc.yaml

This is a sample file to create 2 set of PODs and Services for OUD Instances

## samples/oud-dir-pod.yaml

This is a sample file to create POD (oudpod1) with container for OUD Directory Instance.

## samples/oud-ds_proxy-svc.yaml

This is a sample file to create:
* POD (oudds1) with container for OUD Directory Instance (dc=example1,dc=com)
* POD (oudds2) with container for OUD Directory Instance (dc=example2,dc=com)
* POD (oudp1) with container for OUD Directory Proxy referring to OUD Directory Instances (oudds1 and oudds2) for dc=example1,dc=com and dc=example2,dc=com
* Service (oud-ds-proxy-svc) referring to POD with OUD Directory Proxy (oudp1) 

## samples/oud-ds_rs_ds-svc.yaml

This is a sample file to create:
* POD (oudpodrs1) with container for OUD Replication Server Instance connected to OUD Directory Instance (oudpodds1)
* POD (oudpodds1a) with container for OUD Directory Instance having replication enabled through Replication Server Instance (oudpodrs1)
* POD (oudpodds1b) with container for OUD Directory Instance having replication enabled through Replication Server Instance (oudpodrs1)
* Service (oud-rs-svc-1) referring to Ports from POD (oudpodrs1)
* Service (oud-ds-svc-1a) referring to Ports from POD (oudpodds1a)
* Service (oud-ds-svc-1b) referring to Ports from POD (oudpodds1b)

With execution of following kind of command in container, status can be checked for replicated instances: 

    $ /u01/oracle/user_projects/oudpodrs1/OUD/bin/dsreplication status \
    --trustAll --hostname oudpodrs1.oud-ds-rs-ds-svc.myoudns.svc.cluster.local --port 1444 \
    --dataToDisplay compat-view

## samples/oud-ds-plus-rs-svc.yaml

This is a sample file to create 3 replicated DS+RS Instances:
* POD (ouddsrs1) with container for OUD Directory Server (dc=example1,dc=com) and Replication Server
* POD (ouddsrs2) with container for OUD Directory Server (dc=example1,dc=com) and Replication Server
* Service (oud-dsrs-svc-1) referring to Ports from POD (ouddsrs1)
* Service (oud-dsrs-svc-2) referring to Ports from POD (ouddsrs2)

With execution of following kind of command in container, status can be checked for replicated instances:

    $ /u01/oracle/user_projects/ouddsrs2/OUD/bin/dsreplication status \
    --trustAll --hostname ouddsrs2.oud-dsrs-svc.myoudns.svc.cluster.local --port 1444 \
    --dataToDisplay compat-view

# Licensing & Copyright

## License<br>
To download and run Oracle Fusion Middleware products, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.<br><br>

All scripts and files hosted in this project and GitHub [fmw-kubernetes/OracleUnifiedDirectory](./) repository required to build the Docker images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.<br><br>

## Copyright<br>
Copyright (c) 2020, Oracle and/or its affiliates.<br>
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl<br><br>
