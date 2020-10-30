+++
title = "Create Oracle Unified Directory Services Manager Instances Using Samples"
date = 2019-04-18T07:32:31-05:00
weight = 3
pre = "<b>3. </b>"
description = "Samples for deploying Oracle Unified Directory Services Manager instances to a Kubernetes POD."
+++

1. [Introduction](#introduction)
1. [Preparing the Environment for Container Creation](#preparing-the-environment-for-container-creation)
	1. [Create Kubernetes Namespace](#create-kubernetes-namespace)
	1. [Create Secrets for User IDs and Passwords](#create-secrets-for-user-ids-and-passwords)
	1. [Prepare a Host Directory to be used for Filesystem Based PersistentVolume](#prepare-a-host-directory-to-be-used-for-filesystem-based-persistentvolume)
	1. [Create PersistentVolume (PV) and PersistentVolumeClaim (PVC) for your Namespace](#create-persistentvolume-pv-and-persistentvolumeclaim-pvc-for-your-namespace)
1. [Oracle Unified Directory Services Manager POD](#oracle-unified-directory-services-manager-pod)
1. [Oracle Unified Directory Services Manager Deployment](#oracle-unified-directory-services-manager-deployment)

### Introduction

The Oracle Unified Directory Services Manager deployment scripts provided in the code repository demonstrate how to deploy Oracle Unified Directory Services Manager in containers within a Kubernetes environment.

**Note:** The sample files to assist you in creating and configuring your Oracle Unified Directory Services Manager Kubernetes environment can be found in the project at the following location:

`<work directory>/fmw-kubernetes/OracleUnifiedDirectorySM/kubernetes/samples`

### Preparing the Environment for Container Creation

In this section you prepare the environment for the Oracle Unified Directory Services Manager container creation. This involves the following steps:

1. Create Kubernetes Namespace
1. Create Secrets for User IDs and Passwords
1. Prepare a host directory to be used for Filesystem based PersistentVolume
1. Create PersistentVolume (PV) and PersistentVolumeClaim (PVC) for your Namespace

#### Create Kubernetes Namespace

You should create a Kubernetes namespace to provide a scope for other objects such as pods and services that you create in the environment.  To create your namespace you should refer to the `oudsmns.yaml` file.

Update the `oudsmns.yaml` file and replace `%NAMESPACE%` with the value of the namespace you would like to create.  In the example below the value 'myoudsmns' is used.

To create the namespace apply the file using `kubectl`:

```
$ kubectl apply -f oudsmns.yaml
namespace/myoudsmns created
```

Confirm that the namespace is created:

```
$ kubectl get namespaces
NAME          STATUS   AGE
default       Active   4d
kube-public   Active   4d
kube-system   Active   4d
myoudsmns     Active   53s
```

#### Create Secrets for User IDs and Passwords

To protect sensitive information, namely user IDs and passwords, you should create Kubernetes Secrets for the key-value pairs with following keys. The Secret with key-value pairs will be used to pass values to containers created through the OUD image:

* adminUser
* adminPass

There are two ways by which a Kubernetes secret object can be created with required key-value pairs.

##### Using samples/secrets.yaml file

In this method you update the `samples/secrets.yaml` file with the value for %SECRET_NAME% and %NAMESPACE%, together with the Base64 value for each secret.

* `%adminUser%` - With Base64 encoded value for adminUser parameter.
* `%adminPass%` - With Base64 encoded value for adminPass parameter.

Obtain the base64 value for your secrets, for example:

```
$ echo -n weblogic | base64
d2VibG9naWM=
$ echo -n Oracle123 | base64
T3JhY2xlMTIz
```

**Note:** Ensure that you use the `-n` parameter with the `echo` command. If the parameter is omitted Base64 values will be generated with a new-line character included.

Update the `secrets.yaml` file with your values.  It should look similar to the file shown below:

```
apiVersion: v1
kind: Secret
metadata:
  name: oudsmsecret
  namespace: myoudsmns
type: Opaque
data:
  adminUser: d2VibG9naWM=
  adminPass: T3JhY2xlMTIz
```
          
Apply the file:

```
$ kubectl apply -f secrets.yaml
secret/oudsmsecret created
```
       
Verify that the secret has been created:

```
$ kubectl --namespace myoudsmns get secret
NAME                  TYPE                                  DATA   AGE
default-token-fztcb   kubernetes.io/service-account-token   3      15m
oudsmsecret           Opaque                                8      99s
```

##### Using `kubectl create secret` command

The Kubernetes secret can be created using the command line with the following syntax:

```
$ kubectl --namespace %NAMESPACE% create secret generic %SECRET_NAME% \
      --from-literal=adminUser="%adminUser%" \
      --from-literal=adminPass="%adminPass%"
```

Update the following placeholders in the command with the relevant value:

*  `%NAMESPACE%` - With name of namespace in which secret is required to be created
*  `%SECRET_NAME%` - Name for the secret object
*  `%adminUser%` - With Base64 encoded value for adminUser parameter.
*  `%adminPass%`- With Base64 encoded value for adminPass parameter.

After executing the `kubectl create secret` command, verify that the secret has been created:

```
$ kubectl --namespace myoudsmns get secret
NAME                  TYPE                                  DATA   AGE
default-token-fztcb   kubernetes.io/service-account-token   3      15m
oudsmsecret           Opaque                                8      99s
```

#### Prepare a Host Directory to be used for Filesystem Based PersistentVolume

It is required to prepare a directory on the Host filesystem to store Oracle Unified Directory Services Manager Instances and other configuration outside the container filesystem. That directory from the Host filesystem will be associated with a PersistentVolume.

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

| Param          | Value                       | Example                         |
| -------------- | --------------------------- | ------------------------------- |
| `%PV_NAME%`      | PV name                     | oudsmpv                           |
| `%PV_HOST_PATH%` | Valid path on localhost     | /scratch/user_projects |
| `%PVC_NAME%`     | PVC name                    | oudsmpvc                          |
| `%NAMESPACE%`    | Namespace                   | myoudsmns                         |

Apply the file:

```
$ kubectl apply -f persistent-volume.yaml
persistentvolume/oudsmpv created
persistentvolumeclaim/oudsmpvc created
```

Verify the PersistentVolume:

```
$ kubectl describe persistentvolume oudsmpv
Name:            oudsmpv
Labels:          type=oud-pv
Annotations:     pv.kubernetes.io/bound-by-controller: yes
Finalizers:      [kubernetes.io/pv-protection]
StorageClass:    manual
Status:          Bound
Claim:           myoudsmns/oudsmpvc
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
$ kubectl --namespace myoudsmns describe pvc oudsmpvc
Name:          oudsmpvc
Namespace:     myoudsmns
StorageClass:  manual
Status:        Bound
Volume:        oudsmpv
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

### Oracle Unified Directory Services Manager POD

In this example you create a POD (oudsmpod) which holds a single container based on an Oracle Unified Directory Services Manager 12c PS4 (12.2.1.4.0) image. This container is configured to run Oracle Unified Directory Services Manager. You also create a service (oudsm) through which you can access the Oracle Unified Directory Services Manager GUI.

To create the POD update the `samples/oudsm-pod.yaml` file.

Update the following parameters to values specific to your environment:

| Param         | Value                       | Example                 |
| ----------- | ------------------------- | --------------------- |
| %NAMESPACE%   | Namespace                   | myoudsmns                 |
| %IMAGE%       | Oracle image tag            | oracle/oudsm:12.2.1.4.0 |
| %SECRET_NAME% | Secret name                 | oudsmsecret             |
| %PV_NAME%     | PV name                     | oudsmpv                 |
| %PVC_NAME%    | PVC name                    | oudsmpvc                |

Apply the file:

```
$ kubectl apply -f samples/oudsm-pod.yaml
service/oudsm-svc created
pod/oudsmpod created
```
        
To check the status of the created pod:

```
$ kubectl get pods -n myoudsmns
NAME       READY   STATUS    RESTARTS   AGE
oudsmpod   1/1     Running   0          22m
```

If you see any errors then use the following commands to debug the pod/container.

To review issues with the pod e.g. CreateContainerConfigError:

```
$ kubectl --namespace <namespace> describe pod <pod>
```

For example:

```
$ kubectl --namespace myoudsmns describe pod oudsmpod
```
        
To tail the container logs while it is initialising use the following command:

```
$ kubectl --namespace <namespace> logs -f -c <container> <pod>
```

For example:

```
$ kubectl --namespace myoudsmns logs -f -c oudsm oudsmpod
```
        
To view the full container logs:

```
$ kubectl --namespace <namespace> logs -c <container> <pod>
```
        
To validate that the POD is running:

```
$ kubectl --namespace <namespace> get all,pv,pvc,secret
```
        
For example:

```
$ kubectl --namespace myoudsmns get all,pv,pvc,secret
NAME           READY   STATUS    RESTARTS   AGE
pod/oudsmpod   1/1     Running   0          24m

NAME                TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)                         AGE
service/oudsm-svc   NodePort   10.109.142.163   <none>        7001:31674/TCP,7002:31490/TCP   24m

NAME                                    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                     STORAGECLASS                   REASON   AGE
persistentvolume/oudsmpv                10Gi       RWX            Delete           Bound    myoudsmns/oudsmpvc                        manual                                  45m

NAME                             STATUS   VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/oudsmpvc   Bound    oudsmpv   10Gi       RWX            manual         45m

NAME                         TYPE                                  DATA   AGE
secret/default-token-5kbxk   kubernetes.io/service-account-token   3      84m
secret/oudsmsecret           Opaque                                2      80m
```
    
Once the container is running (READY shows as '1/1') check the value of the service port (PORT/s value : here 7001:31674/TCP,7002:31490/TCP)  for the Oracle Unified Directory Services Manager service and use this to access Oracle Unified Directory Services Manager in a browser:

    http://<hostname>:<svcport>/oudsm

In the case here:

    http://<myhost>:31674/oudsm
	
If you need to release the resources created in this example (POD, service) then issue the following command:

```
$ kubectl delete -f samples/oudsm-pod.yaml
service "oudsm-svc" deleted
pod "oudsmpod" deleted
```

This will avoid conflicts when running the following example for Deployments.

### Oracle Unified Directory Services Manager Deployment

In this example you create multiple Oracle Unified Directory Services Manager PODs/Services using Kubernetes deployments.

To create the deployment update the `samples/oudsm-deployment.yaml` file.

Update the following to values specific to your environment:

| Param         | Value                       | Example                 |
| ----------- | ------------------------- | --------------------- |
| %NAMESPACE%   | Namespace                   | myoudsmns                 |
| %IMAGE%       | Oracle image tag            | oracle/oudsm:12.2.1.4.0 |
| %SECRET_NAME% | Secret name                 | oudsmsecret               |

Apply the file:

```
$ kubectl apply -f samples/oudsm-deployment.yaml
service/oudsm created
deployment.apps/oudsmdeploypod created
```
        
To validate that the POD is running:

```
$ kubectl --namespace <namespace> get all,pv,pvc,secret
```

For example:

```
$ kubectl --namespace myoudsmns get all,pv,pvc,secret
```

        
For example:

```
$ kubectl --namespace myoudsmns get all,pv,pvc,secret
NAME                                 READY   STATUS    RESTARTS   AGE
pod/oudsmdeploypod-7c6bb5476-6zcmc   1/1     Running   0          13m
pod/oudsmdeploypod-7c6bb5476-nldd8   1/1     Running   0          13m

NAME            TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)                         AGE
service/oudsm   NodePort   10.97.245.58   <none>        7001:31342/TCP,7002:31222/TCP   13m

NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/oudsmdeploypod   2/2     2            2           13m

NAME                                       DESIRED   CURRENT   READY   AGE
replicaset.apps/oudsmdeploypod-7c6bb5476   2         2         2       13m

NAME                                    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                     STORAGECLASS                   REASON   AGE
persistentvolume/oudsmpv                10Gi       RWX            Delete           Bound    myoudsmns/oudsmpvc                        manual                                  16h

NAME                             STATUS   VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/oudsmpvc   Bound    oudsmpv   10Gi       RWX            manual         16h

NAME                         TYPE                                  DATA   AGE
secret/default-token-5kbxk   kubernetes.io/service-account-token   3      16h
secret/oudsmsecret           Opaque                                2      16h

```

Once the container is running (READY shows as '1/1') check the value of the service port (PORT/s value : here 7001:31421/TCP,7002:31737/TCP) for the Oracle Unified Directory Services Manager service and use this to access Oracle Unified Directory Services Manager in a browser:

        http://<hostname>:<svcport>/oudsm
        
In the case here:

        http://<myhost>:31342/oudsm

Notice that in the output above we have created 2 Oracle Unified Directory Services Manager PODs (pod/oudsmdeploypod-7bb67b685c-78sq5, pod/oudsmdeploypod-7bb67b685c-xssbq) which are accessed via a service (service/oudsm).

The number of PODs is governed by the `replicas` parameter in the `samples/oudsm-deployment.yaml` file:

```
...
    kind: Deployment
    metadata:
      name: oudsmdeploypod
      namespace: myoudsmns
      labels:
        app: oudsmdeploypod
    spec:
    replicas: 2
    selector:
        matchLabels:
        app: oudsmdeploypod
...
```

If you have a requirement to add additional PODs to your cluster you can update the `samples/oudsm-deployment.yaml` file with the new value for `replicas` and apply the file.  For example, setting `replicas` to '3' would start an additional POD as shown below:

```
...
    kind: Deployment
    metadata:
      name: oudsmdeploypod
      namespace: myoudsmns
      labels:
        app: oudsmdeploypod
    spec:
    replicas: 3
    selector:
        matchLabels:
        app: oudsmdeploypod
...
```

```
$ kubectl apply -f samples/oudsm-deployment.yaml.tmp
service/oudsm unchanged
deployment.apps/oudsmdeploypod configured
```
Check the number of PODs have increased to 3.

```
$ kubectl --namespace myoudsmns get all,pv,pvc,secret
NAME                                 READY   STATUS    RESTARTS   AGE
pod/oudsmdeploypod-7c6bb5476-6zcmc   1/1     Running   0          17m
pod/oudsmdeploypod-7c6bb5476-nldd8   1/1     Running   0          17m
pod/oudsmdeploypod-7c6bb5476-vqmz7   0/1     Running   0          26s

NAME            TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)                         AGE
service/oudsm   NodePort   10.97.245.58   <none>        7001:31342/TCP,7002:31222/TCP   17m

NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/oudsmdeploypod   2/3     3            2           17m

NAME                                       DESIRED   CURRENT   READY   AGE
replicaset.apps/oudsmdeploypod-7c6bb5476   3         3         2       17m

NAME                                    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                     STORAGECLASS                   REASON   AGE
persistentvolume/mike-oud-ds-rs-espv1   20Gi       RWX            Retain           Bound    mikens/data-mike-oud-ds-rs-es-cluster-0   elk                                     4d18h
persistentvolume/mike-oud-ds-rs-pv      30Gi       RWX            Retain           Bound    mikens/mike-oud-ds-rs-pvc                 manual                                  4d18h
persistentvolume/oimcluster-oim-pv      10Gi       RWX            Retain           Bound    oimcluster/oimcluster-oim-pvc             oimcluster-oim-storage-class            69d
persistentvolume/oudsmpv                10Gi       RWX            Delete           Bound    myoudsmns/oudsmpvc                        manual                                  16h

NAME                             STATUS   VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/oudsmpvc   Bound    oudsmpv   10Gi       RWX            manual         16h

NAME                         TYPE                                  DATA   AGE
secret/default-token-5kbxk   kubernetes.io/service-account-token   3      16h
secret/oudsmsecret           Opaque                                2      16h
bash-4.2$
```

In this example, the POD `pod/oudsmdeploypod-7c6bb5476-vqmz7` has been added.

### Appendix A : Reference

1. **samples/oudsm-pod.yaml** : This yaml file is use to create the pod and bring up the Oracle Unified Directory Services Manager services
2. **samples/oudsm-deployment.yaml** : This yaml file is used to create replicas of Oracle Unified Directory Services Manager and bring up the Oracle Unified Directory Services Manager services based on the deployment
