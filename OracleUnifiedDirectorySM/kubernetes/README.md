Oracle Unified Directory Oracle Unified Directory Services Manager (OUDSM) on Kubernetes
============================================================

## Contents
1. [Introduction](#introduction)
1. [Hardware and Software Requirements](#hardware-and-software-requirements)
1. [Prerequisites](#prerequisites)
1. [Example 1 OUDSM POD](#example-1-oudsm-pod)
1. [Example 2 OUDSM Deployment](#example-2-oudsm-deployment)
1. [Appendix Reference](#appendix-reference)

# Introduction
This project offers YAML files and scripts to build Oracle Unified Directory Services Manager (OUDSM) Docker images based on 12cPS4 (12.2.1.4.0) release within a Kubernetes environment. Use these YAML files to facilitate installation, configuration, and environment setup for DevOps users. 

The Docker Image refers to binaries for OUD Release 12.2.1.4.0.

***Image***: oracle/oudsm:12.2.1.4.0

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
        REPOSITORY                           TAG                 IMAGE ID            CREATED             SIZE
        oracle/oudsm                         12.2.1.4.0          4aefb2e19cd6        2 days ago          2.6GB
        ...

## Verify Kubernetes Version
Kubernetes version should be 1.16.0 or higher.  Verify by running the following:

        # kubectl version
	Client Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.4", GitCommit:"c96aede7b5205121079932896c4ad89bb93260af", GitTreeState:"clean", BuildDate:"2020-06-17T11:41:22Z", GoVersion:"go1.13.9", Compiler:"gc", Platform:"linux/amd64"}
	Server Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.4", GitCommit:"c96aede7b5205121079932896c4ad89bb93260af", GitTreeState:"clean", BuildDate:"2020-06-17T11:33:59Z", GoVersion:"go1.13.9", Compiler:"gc", Platform:"linux/amd64"}

## Create Kubernetes Namespace
You should create a Kubernetes namespace to provide a scope for other objects such as pods and services that you create in the environment.  To create your namespace you should refer to the samples/oudsmns.yaml file.

Update the samples/oudsmns.yaml file and replace %NAMESPACE% with the value of the namespace you would like to create.  In the example below the value 'oudsmns' is used.

To create the namespace apply the file using kubectl:

        #  kubectl apply -f samples/oudsmns.yaml
        namespace/oudsmns created

Confirm that the namespace is created:

<pre>   # kubectl get namespaces
    NAME          STATUS   AGE
    default       Active   8d
    kube-public   Active   8d
    kube-system   Active   8d
    <strong>oudsmns</strong>       Active   87s</pre>
        
## Create Secrets for User IDs and Passwords

To protect sensitive information, namely user IDs and passwords, you should create Kubernetes Secrets for the key-value pairs with following keys. The Secret with key-value pairs will be used to pass values to containers created through OUDSM image:

*  adminUser
*  adminPass

There are two ways by which Secret object can be created with required key-value pairs.

### Using samples/secrets.yaml file

To do this you should update the samples/secrets.yaml file with the value for %SECRET_NAME% and %NAMESPACE%, together with the Base64 value for each secret.

*  %adminUser% - With Base64 encoded value for adminUser parameter.
*  %adminPass% - With Base64 encoded value for adminPass parameter.

Obtain the base64 value for your secrets:

        # echo -n weblogic | base64
        d2VibG9naWM=
        # echo -n Oracle123 | base64
        T3JhY2xlMTIz

**Note**: Please make sure to use -n with echo command. Without that, Base64 values would be generated with new-line character included. 

Update the samples/secrets.yaml file with your values.  It should look similar to the file shown below:

        apiVersion: v1
        kind: Secret
        metadata:
          name: oudsecret
          namespace: oudsmns
        type: Opaque
        data:
          adminUser: d2VibG9naWM=
          adminPass: T3JhY2xlMTIz

Apply the file:

        # kubectl apply -f samples/secrets.yaml
        secret/oudsecret created
        
Verify that the secret has been created:

        # kubectl --namespace oudsmns get secret
        NAME                  TYPE                                  DATA   AGE
        default-token-l5nwd   kubernetes.io/service-account-token   3      7m10s
        oudsecret             Opaque                                2      27s

### Using `kubectl create secret` command

Kubernetes Secret can be created using following command:

        # kubectl --namespace %NAMESPACE% create secret generic %SECRET_NAME% \
          --from-literal=adminUser="%adminUser%" \
          --from-literal=adminPass="%adminPass%" 

In the command mentioned above, following placeholders are required to be updated:

*  %NAMESPACE% - With name of namespace in which secret is required to be created
*  %SECRET_NAME% - Name for the secret object
*  %adminUser% - With Base64 encoded value for adminUser parameter.
*  %adminPass% - With Base64 encoded value for adminPass parameter.

After executing `kubectl create secret ...` command, verify that the secret has been created:

        # kubectl --namespace oudsmns get secret
        NAME                  TYPE                                  DATA   AGE
        default-token-l5nwd   kubernetes.io/service-account-token   3      7m10s
        oudsecret             Opaque                                2      27s

## Create PersistentVolume (PV) and PersistentVolumeClaim (PVC) for your Namespace
A PV is storage resource, while PVC is a request for that resource.  To provide storage for your namespace, update the samples/persistent-volume.yaml file.

Update the following to values specific to your environment:

| Param          | Value                       | Example               |
| :------------: | :-------------------------: | :-------------------: |
| %PV_NAME%      | PV name                     | oudsmpv               |
| %PV_HOST_PATH% | Valid path on localhost     |/u01/app/oracle/mydir  |
| %PVC_NAME%     | PVC name                    | oudsmpvc              |
| %NAMESPACE%    | Namespace                   | oudsmns               |

Apply the file:

        # kubectl apply -f samples/persistent-volume.yaml
        persistentvolume/oudsmpv created
        persistentvolumeclaim/oudsmpvc created

Verify the PersistentVolume:

        # kubectl --namespace oudsmns describe persistentvolume oudsmpv
        Name:            oudsmpv
        Labels:          type=local
        Annotations:     kubectl.kubernetes.io/last-applied-configuration:
                        {"apiVersion":"v1","kind":"PersistentVolume","metadata":{"annotations":{},"labels":{"type":"local"},"name":"oudsmpv"},"spec":{"accessModes...
        Finalizers:      [kubernetes.io/pv-protection]
        StorageClass:
        Status:          Available
        Claim:
        Reclaim Policy:  Retain
        Access Modes:    RWX
        VolumeMode:      Filesystem
        Capacity:        10Gi
        Node Affinity:   <none>
        Message:
        Source:
        Type:          HostPath (bare host directory volume)
        Path:          /scratch/beta/user_projects
        HostPathType:
        Events:            <none>

Verify the PersistentVolumeClaim:

        # kubectl --namespace oudsmns describe pvc oudsmpvc
        Name:          oudsmpvc
        Namespace:     oudsmns
        StorageClass:
        Status:        Bound
        Volume:        oud-ds-rs-1585148421-pv
        Labels:        <none>
        Annotations:   kubectl.kubernetes.io/last-applied-configuration:
                        {"apiVersion":"v1","kind":"PersistentVolumeClaim","metadata":{"annotations":{},"name":"oudsmpvc","namespace":"oudsmns"},"spec":{"accessMod...
                        pv.kubernetes.io/bind-completed: yes
                        pv.kubernetes.io/bound-by-controller: yes
        Finalizers:    [kubernetes.io/pvc-protection]
        Capacity:      10Gi
        Access Modes:  RWX
        VolumeMode:    Filesystem
        Events:        <none>
        Mounted By:    <none>
        
# Example 1 OUDSM POD

In this example you create a POD (oudsmpod) which holds a single container based on an Oracle Unified Directory Services Manager 12c PS4 (12.2.1.4.0) image.  This container is configured to run Oracle Unified Directory Services Manager (OUDSM).  You also create a service (oudsm) through which you can access the OUDSM GUI.

To create the POD update the samples/oudsm-pod.yaml file.

Update the following to values specific to your environment:

| Param         | Value                       | Example                 |
| :-----------: | :-------------------------: | :---------------------: |
| %NAMESPACE%   | Namespace                   | oudsmns                 |
| %IMAGE%       | Oracle image tag            | oracle/oudsm:12.2.1.4.0 |
| %SECRET_NAME% | Secret name                 | oudsecret               |
| %PV_NAME%     | PV name                     | oudsmpv                 |
| %PVC_NAME%    | PVC name                    | oudsmpvc                |

Apply the file:

        # kubectl apply -f samples/oudsm-pod.yaml
        namespace/oudsmns unchanged
        service/oudsm created
        pod/oudsmpod created
        
To check the status of the created pod:

        #   kubectl get pods -n oudsmns
        NAME       READY   STATUS   RESTARTS   AGE
        oudsmpod   0/1     Error    0          20m


If you see any errors then use the following commands to debug the pod/container.

To review issues with the pod e.g. CreateContainerConfigError:

        # kubectl --namespace <namespace> describe pod <pod>

For example:

        # kubectl --namespace oudsmns describe pod oudsmpod
        
To tail the container logs while it is initialising use the following command:

        # kubectl --namespace <namespace> logs -f -c <container> <pod>

For example:

        # kubectl --namespace oudsmns logs -f -c oudsm oudsmpod
        
To view the full container logs:

        # kubectl --namespace <namespace> logs -c <container> <pod>
        
To validate that the POD is running:

        # kubectl --namespace <namespace> get all,pv,pvc,secret
        
For example:

<pre>   # kubectl --namespace oudsmns get all,pv,pvc,secret
    NAME           READY   STATUS    RESTARTS   AGE
    pod/oudsmpod   1/1     Running   0          15m
    
    NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                         AGE
    service/oudsm   NodePort   10.101.73.196   <none>        7001:<strong>31421</strong>/TCP,7002:31737/TCP   15m
    
    NAME                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM              STORAGECLASS   REASON   AGE
    persistentvolume/oudsmpv   10Gi       RWX            Retain           Bound    oudsmns/oudsmpvc                           18m
    
    NAME                             STATUS   VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS   AGE
    persistentvolumeclaim/oudsmpvc   Bound    oudsmpv   10Gi       RWX                           18m
    
    NAME                         TYPE                                  DATA   AGE
    secret/default-token-wp4gx   kubernetes.io/service-account-token   3      34m
    secret/oudsecret             Opaque                                2      19m</pre>
    
Once the container is running (READY shows as '1/1') check the value of the service port (PORT/s value : here 7001:31421/TCP,7002:31737/TCP)  for the OUDSM service and use this to access OUDSM in a browser:

    http://<hostname>:<svcport>/oudsm

In the case here:

    http://<myhost>:31421/oudsm

# Example 2 OUDSM Deployment

In this example you create multiple OUDSM PODs/Services using Kubernetes deployments.

To create the deployment update the samples/oudsm-deployment.yaml file.

Update the following to values specific to your environment:

| Param         | Value                       | Example                 |
| :-----------: | :-------------------------: | :---------------------: |
| %NAMESPACE%   | Namespace                   | oudsmns                 |
| %IMAGE%       | Oracle image tag            | oracle/oudsm:12.2.1.4.0 |
| %SECRET_NAME% | Secret name                 | oudsecret               |

Apply the file:

        # kubectl apply -f samples/oudsm-deployment.yaml
        namespace/oudsmns unchanged
        service/oudsm configured
        deployment.apps/oudsmdeploypod created
        
To validate that the POD is running:

        # kubectl --namespace <namespace> get all,pv,pvc,secret
        
For example:

        # kubectl --namespace oudsmns get all,pv,pvc,secret

        
For example:

        # kubectl --namespace oudsmns get all,pv,pvc,secret
        NAME                                  READY   STATUS    RESTARTS   AGE
        pod/oudsmdeploypod-7bb67b685c-78sq5   1/1     Running   0          12m
        pod/oudsmdeploypod-7bb67b685c-xssbq   1/1     Running   0          12m

        NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                         AGE
        service/oudsm   NodePort   10.102.47.146   <none>        7001:30489/TCP,7002:31588/TCP   12m

        NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
        deployment.apps/oudsmdeploypod   2/2     2            2           12m

        NAME                                        DESIRED   CURRENT   READY   AGE
        replicaset.apps/oudsmdeploypod-7bb67b685c   2         2         2       12m

        NAME                         TYPE                                  DATA   AGE
        secret/default-token-clzx7   kubernetes.io/service-account-token   3      68m
        secret/oudsecret             Opaque                                2      67m

Once the container is running (READY shows as '1/1') check the value of the service port (PORT/s value : here 7001:31421/TCP,7002:31737/TCP)  for the OUDSM service and use this to access OUDSM in a browser:

        http://<hostname>:<svcport>/oudsm
        
In the case here:

        http://<myhost>:30489/oudsm

Notice that in the output above we have created 2 OUDSM PODs (pod/oudsmdeploypod-7bb67b685c-78sq5, pod/oudsmdeploypod-7bb67b685c-xssbq) which are accessed via a service (service/oudsm).

The number of PODs is governed by the <code>replicas</code> parameter in the samples/oudsm-deployment.yaml file:

<pre>...
        kind: Deployment
        metadata:
          name: oudsmdeploypod
          namespace: oudsmns
          labels:
            app: oudsmdeploypod
        spec:
        <strong>replicas: 2</strong>
        selector:
            matchLabels:
            app: oudsmdeploypod
        ...</pre>

If you have a requirement to add additional PODs to your cluster you can update the samples/oudsm-deployment.yaml file with the new value for <code>replicas</code> and apply the file.  For example, setting <code>replicas</code> to '3' would start an additional POD as shown below:

        # kubectl apply -f samples/oudsm-deployment.yaml.tmp
        namespace/oudsmns unchanged
        service/oudsm unchanged
        deployment.apps/oudsmdeploypod configured

<pre>   # kubectl --namespace oudsmns get all,pv,pvc,secret
    NAME                                  READY   STATUS    RESTARTS   AGE
    pod/oudsmdeploypod-7bb67b685c-78sq5   1/1     Running   0          105m
    <strong>pod/oudsmdeploypod-7bb67b685c-sv9ms   1/1     Running   0          76m</strong>
    pod/oudsmdeploypod-7bb67b685c-xssbq   1/1     Running   0          105m
    
    NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                         AGE
    service/oudsm   NodePort   10.102.47.146   <none>        7001:30489/TCP,7002:31588/TCP   105m

    NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/oudsmdeploypod   3/3     3            3           105m

    NAME                                        DESIRED   CURRENT   READY   AGE
    replicaset.apps/oudsmdeploypod-7bb67b685c   3         3         3       105m

    NAME                         TYPE                                  DATA   AGE
    secret/default-token-clzx7   kubernetes.io/service-account-token   3      161m
    secret/oudsecret             Opaque                                2      160m</pre>

# Appendix Reference

1. **samples/oudsm-pod.yaml** : This yaml file is use to create the pod and bring up the OUDSM services
2. **samples/oudsm-deployment.yaml** : This yaml file is used to create replicas of OUDSM and bring up the OUDSM services based on the deployment

# Licensing & Copyright

## License<br>
To download and run Oracle Fusion Middleware products, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.<br><br>

All scripts and files hosted in this project and GitHub [fmw-kubernetes/OracleUnifiedDirectorySM](./) repository required to build the Docker images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.<br><br>

## Copyright<br>
Copyright (c) 2020, Oracle and/or its affiliates.<br>
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl<br><br>
