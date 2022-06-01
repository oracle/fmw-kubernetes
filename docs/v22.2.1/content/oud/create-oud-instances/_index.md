+++
title = "Create Oracle Unified Directory Instances"
weight = 4 
pre = "<b>4. </b>"
description=  "This document provides details of the oud-ds-rs Helm chart."
+++

1. [Introduction](#introduction)
1. [Create a Kubernetes namespace](#create-a-kubernetes-namespace)
1. [Create a Kubernetes secret for the container registry](#create-a-kubernetes-secret-for-the-container-registry)
1. [Create a Kubernetes secret for cronjob images](#create-a-kubernetes-secret-for-cronjob-images)
1. [The oud-ds-rs Helm chart](#the-oud-ds-rs-helm-chart)
1. [Create OUD instances](#create-oud-instances)
1. [Helm command output](#helm-command-output)
1. [Verify the OUD deployment](#verify-the-oud-deployment)
1. [Verify the OUD replication](#verify-the-oud-replication)
1. [Verify the cronjob](#verify-the-cronjob)
1. [Undeploy an OUD deployment](#undeploy-an-oud-deployment)
1. [Appendix: Configuration parameters](#appendix-configuration-parameters)


### Introduction

This chapter demonstrates how to deploy Oracle Unified Directory (OUD) 12c instance(s) and replicated instances using the Helm package manager for Kubernetes. 

The helm chart can be used to deploy an Oracle Unified Directory instance as a base, with configured sample entries, and multiple replicated Oracle Unified Directory instances/pods/services based on the specified `replicaCount`.

Based on the configuration, this chart deploys the following objects in the specified namespace of a Kubernetes cluster.

* Service Account
* Secret
* Persistent Volume and Persistent Volume Claim
* Pod(s)/Container(s) for Oracle Unified Directory Instances
* Services for interfaces exposed through Oracle Unified Directory Instances
* Ingress configuration


### Create a Kubernetes namespace

Create a Kubernetes namespace for the OUD deployment by running the following command:

```bash
$ kubectl create namespace <namespace>
```

For example:

```bash
$ kubectl create namespace oudns
```

The output will look similar to the following:

```
namespace/oudns created
```

### Create a Kubernetes secret for the container registry

Create a Kubernetes secret to stores the credentials for the container registry where the OUD image is stored. This step must be followed if using Oracle Container Registry or your own private container registry. If you are not using a container registry and have loaded the images on each of the master and worker nodes, you can skip this step.

1. Run the following command to create the secret:

   ```bash
   kubectl create secret docker-registry "orclcred" --docker-server=<CONTAINER_REGISTRY> \
   --docker-username="<USER_NAME>" \
   --docker-password=<PASSWORD> --docker-email=<EMAIL_ID> \
   --namespace=<domain_namespace>
   ```
   
   For example, if using Oracle Container Registry:
   
   ```bash
   $ kubectl create secret docker-registry "orclcred" --docker-server=container-registry.oracle.com \
   --docker-username="user@example.com" \
   --docker-password=password --docker-email=user@example.com \
   --namespace=oudns
   ```
   
   
   Replace `<USER_NAME>` and `<PASSWORD>` with the credentials for the registry with the following caveats:

   -  If using Oracle Container Registry to pull the OUD container image, this is the username and password used to login to [Oracle Container Registry](https://container-registry.oracle.com). Before you can use this image you must login to [Oracle Container Registry](https://container-registry.oracle.com), navigate to `Middleware` > `oud_cpu` and accept the license agreement.

   - If using your own container registry to store the OUD container image, this is the username and password (or token) for your container registry.   

   The output will look similar to the following:
   
   ```bash
   secret/orclcred created
   ```

### Create a Kubernetes secret for cronjob images

Once OUD is deployed, if the Kubernetes node where the OUD pod(s) is/are running goes down after the pod eviction time-out, the pod(s) don't get evicted but move to a `Terminating` state. The pod(s) will then remain in that state forever. To avoid this problem a cron-job is created during OUD deployment that checks for any pods in `Terminating` state, deletes them, and then starts the pod again. This cron job requires access to images on [hub.docker.com](https://hub.docker.com). A Kubernetes secret must therefore be created to enable access to these images.

1. Create a Kubernetes secret to access the required images on [hub.docker.com](https://hub.docker.com): 

   **Note:** You must first have a user account on [hub.docker.com](https://hub.docker.com):

   ```bash
   $ kubectl create secret docker-registry "dockercred" --docker-server="https://index.docker.io/v1/" --docker-username="<docker_username>" --docker-password=<password> --docker-email=<docker_email_credentials> --namespace=<domain_namespace>
   ```   
   
   For example:
   
   ```
   $ kubectl create secret docker-registry "dockercred" --docker-server="https://index.docker.io/v1/" --docker-username="username" --docker-password=<password> --docker-email=user@example.com --namespace=oudns
   ```
   
   The output will look similar to the following:
   
   ```bash
   secret/dockercred created
   ```  


### The oud-ds-rs Helm chart


The `oud-ds-rs` Helm chart allows you to create or deploy a group of replicated Oracle Unified Directory instances along with Kubernetes objects in a specified namespace.

The deployment can be initiated by running the following Helm command with reference to the `oud-ds-rs` Helm chart, along with configuration parameters according to your environment. 

```bash
$ cd $WORKDIR/kubernetes/helm
$ helm install --namespace <namespace> \
<Configuration Parameters> \
<deployment/release name> \
<Helm Chart Path/Name>
```

Configuration Parameters (override values in chart) can be passed on with `--set` arguments on the command line and/or with `-f / --values` arguments when referring to files. 

**Note**: The examples in [Create OUD instances](#create-oud-instances) below provide values which allow the user to override the default values provided by the Helm chart. A full list 
of configuration parameters and their default values is shown in [Appendix: Configuration parameters]((#appendix-configuration-parameters)).

For more details about the `helm` command and parameters, please execute `helm --help` and `helm install --help`.


### Create OUD instances

You can create OUD instances using one of the following methods:

1. [Using a YAML file](#using-a-yaml-file)
1. [Using `--set` argument](#using---set-argument)

**Note**: While it is possible to install sample data during the OID deployment is it not possible to load your own data via an ldif file . In order to load data in OUD, create the OUD deployment and then use ldapmodify post the ingress deployment. See [Using LDAP utilities](../configure-ingress/#using-ldap-utilities).


#### Using a YAML file

1. Navigate to the `$WORKDIR/kubernetes/helm` directory:

   ```bash
   $ cd $WORKDIR/kubernetes/helm
   ```

1. Create an `oud-ds-rs-values-override.yaml` as follows:

   ```yaml
   image:
     repository: <image_location>
     tag: <image_tag>
     pullPolicy: IfNotPresent
   imagePullSecrets:
     - name: orclcred
   oudConfig:
     rootUserPassword: <password>
	 sampleData: "200"
   persistence:
     type: filesystem
     filesystem:
       hostPath: 
         path: <persistent_volume>/oud_user_projects
   cronJob:
     kubectlImage:
       repository: bitnami/kubectl
       tag: <version>
       pullPolicy: IfNotPresent
     helmImage:
       repository: alpine/helm
       tag: <version>
       pullPolicy: IfNotPresent

     cronPersistence:
       enabled: true
       type: filesystem
       filesystem:
         hostPath:
           path: <$WORKDIR>/kubernetes/helm

       imagePullSecrets:
       - name: dockercred  
   ```
   
   For example:

   ```yaml
   image:
     repository: container-registry.oracle.com/middleware/oud_cpu
     tag: 12.2.1.4-jdk8-ol7-220119.2051
     pullPolicy: IfNotPresent
   imagePullSecrets:
     - name: orclcred
   oudConfig:
     rootUserPassword: <password>
	 sampleData: "200"
   persistence:
     type: filesystem
     filesystem:
       hostPath: 
         path: /scratch/shared/oud_user_projects
   cronJob:
     kubectlImage:
       repository: bitnami/kubectl
       tag: 1.21.0
       pullPolicy: IfNotPresent
     helmImage:
       repository: alpine/helm
       tag: 3.2.0
       pullPolicy: IfNotPresent

     cronPersistence:
       enabled: true
       type: filesystem
       filesystem:
         hostPath:
           path: /scratch/shared/OUDContainer/fmw-kubernetes/OracleUnifiedDirectory/kubernetes/helm

       imagePullSecrets:
       - name: dockercred
   ```

  
   The following caveats exist:
   
   * Replace `<password>` with the relevant password.
   * `sampleData: "200"` will load 200 sample users into the default baseDN `dc=example,dc=com`. If you do not want sample data, remove this entry.
   * The `<version>` in *kubectlImage* `tag:` should be set to the same version as your Kubernetes version (`kubectl version`). For example if your Kubernetes version is `1.21.6` set to `1.21.0`.
   * The `<version>` in *helmimage* `tag:` should be set to the same version as your Helm version (`helm version`). For example if your helm version is `3.2.4` set to `3.2.0`.
   * The *cronPersistence* `path` must point to the helm charts directory on the persistent volume.
   * If you are not using Oracle Container Registry or your own container registry for your OUD container image, then you can remove the following:
   
      ```
      imagePullSecrets:
        - name: orclcred
      ```
  
   * If using NFS for your persistent volume then change the `persistence` and `cronPersistence section as follows:
  
      ```yaml
      persistence:
        type: networkstorage
        networkstorage:
          nfs: 
            path: <persistent_volume>/oud_user_projects
            server: <NFS IP address>
		 
      cronPersistence:
	    enabled: true
        type: networkstorage
        networkstorage:
          nfs:
            path: <$WORKDIR>/kubernetes/helm
		    server: <NFS_IP_Address> 
      ```


1. Run the following command to deploy OUD:

   ```bash
   $ helm install --namespace <namespace> \
   --values oud-ds-rs-values-override.yaml \
   <release_name> oud-ds-rs
   ```

   For example:

   ```bash
   $ helm install --namespace oudns \
   --values oud-ds-rs-values-override.yaml \
   oud-ds-rs oud-ds-rs
   ```

1. Check the OUD deployment as per [Verify the OUD deployment](#verify-the-oud-deployment) and [Verify the OUD replication](#verify-the-oud-replication).

#### Using `--set` argument

1. Navigate to the `$WORKDIR/kubernetes/helm` directory:

   ```bash
   $ cd $WORKDIR/kubernetes/helm
   ```

1. Run the following command to create OUD instances:

   ```bash
   $ helm install --namespace <namespace> \
   --set oudConfig.rootUserPassword=<password>,persistence.filesystem.hostPath.path=<persistent_volume>/oud_user_projects,image.repository=<image_location>,image.tag=<image_tag> \ 
   --set imagePullSecrets[0].name="orclcred" \
   --set sampleData="200" \
   --set cronJob.kubectlImage.repository=bitnami/kubectl,cronJob.kubectlImage.tag=<version> \
   --set cronJob.helmImage.repository=alpine/helm,cronJob.helmImage.tag=<version> \
   --set cronJob.cronPersistence.filesystem.hostPath.path=<$WORKDIR>/kubernetes/helm \
   --set cronJob.imagePullSecrets[0].name="dockercred" \
   <release_name> oud-ds-rs
   ```

   For example:

   ```bash
   $ helm install --namespace oudns \
   --set oudConfig.rootUserPassword=<password>,persistence.filesystem.hostPath.path=/scratch/shared/oud_user_projects,image.repository=container-registry.oracle.com/middleware/oud_cpu,image.tag=12.2.1.4-jdk8-ol7-220119.2051 \
   --set sampleData="200" \
   --set cronJob.kubectlImage.repository=bitnami/kubectl,cronJob.kubectlImage.tag=1.21.0 \
   --set cronJob.helmImage.repository=alpine/helm,cronJob.helmImage.tag=3.2.0 \
   --set cronJob.cronPersistence.filesystem.hostPath.path=/scratch/shared/OUDContainer/fmw-kubernetes/OracleUnifiedDirectory/kubernetes/helm/ \
   --set cronJob.imagePullSecrets[0].name="dockercred" \
   --set imagePullSecrets[0].name="orclcred" \
   oud-ds-rs oud-ds-rs
   ```

   The following caveats exist:

   * Replace `<password>` with a the relevant password.
   * `sampleData: "200"` will load 200 sample users into the default baseDN `dc=example,dc=com`. If you do not want sample data, remove this entry.
   * The `<version>` in *kubectlImage* `tag:` should be set to the same version as your Kubernetes version (`kubectl version`). For example if your Kubernetes version is `1.21.6` set to `1.21.0`.
   * The `<version>` in *helmimage* `tag:` should be set to the same version as your Helm version (`helm version`). For example if your helm version is `3.2.4` set to `3.2.0`.
   * The *cronPersistence* `path` must point to the helm charts directory on the persistent volume.
   * If using using NFS for your persistent volume then use `persistence.networkstorage.nfs.path=<persistent_volume>/oud_user_projects,persistence.networkstorage.nfs.server:<NFS IP address>`.
   * If you are not using Oracle Container Registry or your own container registry for your OUD container image, then you can remove the following: `--set imagePullSecrets[0].name="orclcred"`.

1. Check the OUD deployment as per [Verify the OUD deployment](#verify-the-oud-deployment) and [Verify the OUD replication](#verify-the-oud-replication).

### Helm command output

In all the examples above, the following output is shown following a successful execution of the `helm install` command.

   ```bash
   NAME: oud-ds-rs
   LAST DEPLOYED:  Wed Mar 16 12:02:40 2022
   NAMESPACE: oudns
   STATUS: deployed
   REVISION: 4
   NOTES:
   #
   # Copyright (c) 2020, Oracle and/or its affiliates.
   #
   #  Licensed under the Universal Permissive License v 1.0 as shown at
   # https://oss.oracle.com/licenses/upl
   #
   #
   Since "nginx" has been chosen, follow the steps below to configure nginx ingress controller.
   Add Repo reference to helm for retriving/installing Chart for nginx-ingress implementation.
   command-# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

   Command helm install to install nginx-ingress related objects like pod, service, deployment, etc.
   # helm install --namespace <namespace for ingress> --values nginx-ingress-values-override.yaml lbr-nginx ingress-nginx/ingress-nginx

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
   ```

### Verify the OUD deployment 

Run the following command to verify the OUD deployment: 

```bash
$ kubectl --namespace <namespace> get pod,service,secret,pv,pvc,ingress -o wide
```

For example:

```bash
$ kubectl --namespace oudns get pod,service,secret,pv,pvc,ingress -o wide
```

The output will look similar to the following: 

```
NAME              READY   STATUS    RESTARTS   AGE     IP             NODE          NOMINATED NODE   READINESS GATES
pod/oud-ds-rs-0   1/1     Running   0          17m   10.244.0.195   <Worker Node>   <none>           <none>
pod/oud-ds-rs-1   1/1     Running   0          17m   10.244.0.194   <Worker Node>   <none>           <none>
pod/oud-ds-rs-2   1/1     Running   0          17m   10.244.0.193   <Worker Node>   <none>           <none>
    
NAME                          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE     SELECTOR
service/oud-ds-rs-0           ClusterIP   10.99.232.83     <none>        1444/TCP,1888/TCP,1898/TCP   8m44s   kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-0
service/oud-ds-rs-1           ClusterIP   10.100.186.42    <none>        1444/TCP,1888/TCP,1898/TCP   8m45s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-1
service/oud-ds-rs-2           ClusterIP   10.104.55.53     <none>        1444/TCP,1888/TCP,1898/TCP   8m45s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-2
service/oud-ds-rs-http-0      ClusterIP   10.102.116.145   <none>        1080/TCP,1081/TCP            8m45s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-0
service/oud-ds-rs-http-1      ClusterIP   10.111.103.84    <none>        1080/TCP,1081/TCP            8m44s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-1
service/oud-ds-rs-http-2      ClusterIP   10.105.53.24     <none>        1080/TCP,1081/TCP            8m45s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-2
service/oud-ds-rs-lbr-admin   ClusterIP   10.98.39.206     <none>        1888/TCP,1444/TCP            8m45s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
service/oud-ds-rs-lbr-http    ClusterIP   10.110.77.132    <none>        1080/TCP,1081/TCP            8m45s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
service/oud-ds-rs-lbr-ldap    ClusterIP   10.111.55.122    <none>        1389/TCP,1636/TCP            8m45s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
service/oud-ds-rs-ldap-0      ClusterIP   10.108.155.81    <none>        1389/TCP,1636/TCP            8m44s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-0
service/oud-ds-rs-ldap-1      ClusterIP   10.104.88.44     <none>        1389/TCP,1636/TCP            8m45s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-1
service/oud-ds-rs-ldap-2      ClusterIP   10.105.253.120   <none>        1389/TCP,1636/TCP            8m45s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-2
    
NAME                                        TYPE                                  DATA   AGE
secret/default-token-tbjr5                  kubernetes.io/service-account-token   3      25d
secret/orclcred                             kubernetes.io/dockerconfigjson        1      3d
secret/oud-ds-rs-creds                      opaque                                8      8m48s
secret/oud-ds-rs-token-cct26                kubernetes.io/service-account-token   3      8m50s
secret/sh.helm.release.v1.oud-ds-rs.v1      helm.sh/release.v1                    1      8m51s
    
NAME                               CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                    STORAGECLASS   REASON   AGE
persistentvolume/oud-ds-rs-pv      20Gi       RWX            Retain           Bound    oudns/oud-ds-rs-pvc      manual                  8m47s
 
NAME                                  STATUS   VOLUME         CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/oud-ds-rs-pvc   Bound    oud-ds-rs-pv   20Gi       RWX            manual         8m48s
   
NAME                                               HOSTS                                                               ADDRESS         PORTS   AGE
ingress.extensions/oud-ds-rs-admin-ingress-nginx   oud-ds-rs-admin-0,oud-ds-rs-admin-1,oud-ds-rs-admin-2 + 2 more...   10.229.141.78   80      8m45s
ingress.extensions/oud-ds-rs-http-ingress-nginx    oud-ds-rs-http-0,oud-ds-rs-http-1,oud-ds-rs-http-2 + 3 more...      10.229.141.78   80      8m45s
```

**Note**: It will take several minutes before all the services listed above show. While the oud-ds-rs pods have a `STATUS` of `0/1` the pod is started but the OUD server associated with it is currently starting. While the pod is starting you can check the startup status in the pod logs, by running the following command:

```bash
$ kubectl logs oud-ds-rs-0 -n oudns
$ kubectl logs oud-ds-rs-1 -n oudns
$ kubectl logs oud-ds-rs-2 -n oudns
```

**Note** : If the OUD deployment fails additionally refer to [Troubleshooting](../troubleshooting) for instructions on how describe the failing pod(s).
Once the problem is identified follow [Undeploy an OUD deployment](#undeploy-an-oud-deployment) to clean down the deployment before deploying again.

#### Kubernetes Objects

Kubernetes objects created by the Helm chart are detailed in the table below:

| **Type** | **Name** | **Example Name** | **Purpose** | 
| ------ | ------ | ------ | ------ |
| Service Account | <deployment/release name> | oud-ds-rs | Kubernetes Service Account for the Helm Chart deployment |
| Secret | <deployment/release name>-creds |  oud-ds-rs-creds | Secret object for Oracle Unified Directory related critical values like passwords |
| Persistent Volume | <deployment/release name>-pv | oud-ds-rs-pv | Persistent Volume for user_projects mount. | 
| Persistent Volume Claim | <deployment/release name>-pvc | oud-ds-rs-pvc | Persistent Volume Claim for user_projects mount. |
| Persistent Volume | <deployment/release name>-pv-config | oud-ds-rs-pv-config | Persistent Volume for mounting volume in containers for configuration files like ldif, schema, jks, java.security, etc. |
| Persistent Volume Claim | <deployment/release name>-pvc-config | oud-ds-rs-pvc-config | Persistent Volume Claim for mounting volume in containers for configuration files like ldif, schema, jks, java.security, etc. |
| Pod | <deployment/release name>-0 | oud-ds-rs-0 | Pod/Container for base Oracle Unified Directory Instance which would be populated first with base configuration (like number of sample entries) |
| Pod | <deployment/release name>-N | oud-ds-rs-1, oud-ds-rs-2, ...  | Pod(s)/Container(s) for Oracle Unified Directory Instances - each would have replication enabled against base Oracle Unified Directory instance <deployment/release name>-0|
| Service | <deployment/release name>-0 | oud-ds-rs-0 | Service for LDAPS Admin, REST Admin and Replication interfaces from base Oracle Unified Directory instance <deployment/release name>-0|
| Service | <deployment/release name>-http-0 | oud-ds-rs-http-0 | Service for HTTP and HTTPS interfaces from base Oracle Unified Directory instance <deployment/release name>-0 |
| Service | <deployment/release name>-ldap-0 | oud-ds-rs-ldap-0 | Service for LDAP and LDAPS interfaces from base Oracle Unified Directory instance <deployment/release name>-0 |
| Service | <deployment/release name>-N | oud-ds-rs-1, oud-ds-rs-2, ... | Service(s) for LDAPS Admin, REST Admin and Replication interfaces from base Oracle Unified Directory instance <deployment/release name>-N |
| Service | <deployment/release name>-http-N | oud-ds-rs-http-1, oud-ds-rs-http-2, ... | Service(s) for HTTP and HTTPS interfaces from base Oracle Unified Directory instance <deployment/release name>-N |
| Service | <deployment/release name>-ldap-N | oud-ds-rs-ldap-1, oud-ds-rs-ldap-2, ... | Service(s) for LDAP and LDAPS interfaces from base Oracle Unified Directory instance <deployment/release name>-N |
| Service | <deployment/release name>-lbr-admin | oud-ds-rs-lbr-admin | Service for LDAPS Admin, REST Admin and Replication interfaces from all Oracle Unified Directory instances |
| Service | <deployment/release name>-lbr-http | oud-ds-rs-lbr-http | Service for HTTP and HTTPS interfaces from all Oracle Unified Directory instances |
| Service | <deployment/release name>-lbr-ldap | oud-ds-rs-lbr-ldap | Service for LDAP and LDAPS interfaces from all Oracle Unified Directory instances |
| Ingress | <deployment/release name>-admin-ingress-nginx | oud-ds-rs-admin-ingress-nginx | Ingress Rules for HTTP Admin interfaces. |
| Ingress | <deployment/release name>-http-ingress-nginx | oud-ds-rs-http-ingress-nginx | Ingress Rules for HTTP (Data/REST) interfaces. |

* In the table above the 'Example Name' for each Object is based on the value 'oud-ds-rs' as deployment/release name for the Helm chart installation.

### Verify the OUD replication

Once all the PODs created are visible as `READY` (i.e. `1/1`), you can verify your replication across multiple Oracle Unified Directory instances.

1. To verify the replication group, connect to the container and issue an OUD administration command to show the details. The name of the container can be found by issuing the following:

   ```bash
   $ kubectl get pods -n <namespace> -o jsonpath='{.items[*].spec.containers[*].name}'
   ```

   For example:

   ```bash
   $ kubectl get pods -n oudns -o jsonpath='{.items[*].spec.containers[*].name}'
   ```

   The output will look similar to the following:

   ```bash
   oud-ds-rs oud-ds-rs oud-ds-rs
   ```

   Once you have the container name you can verify the replication status in the following ways:

   * Run dresplication inside the pod
   * Using kubectl commands

#### Run dresplication inside the pod

    
1. Run the following command to create a bash shell in the pod:

   ```bash
   $ kubectl --namespace <namespace> exec -it -c <containername> <podname> -- bash
   ```

   For example: 

   ```bash
   $ kubectl --namespace oudns exec -it -c oud-ds-rs oud-ds-rs-0 -- bash
   ```
   
   This will take you into the pod:
   
   ```bash
   [oracle@oud-ds-rs-0 oracle]$
   ```
   
    
1. From the prompt, use the `dsreplication` command to check the status of your replication group:

   ```bash
   $ cd /u01/oracle/user_projects/oud-ds-rs-0/OUD/bin

   $ ./dsreplication status --trustAll \
   --hostname oud-ds-rs-0 --port 1444 --adminUID admin \
   --dataToDisplay compat-view --dataToDisplay rs-connections
   ```

   The output will look similar to the following. Enter credentials where prompted:

   ```bash
   >>>> Specify Oracle Unified Directory LDAP connection parameters
    
   Password for user 'admin':
    
   Establishing connections and reading configuration ..... Done.
    
   dc=example,dc=com - Replication Enabled
   =======================================
    
   Server               : Entries : M.C. [1] : A.O.M.C. [2] : Port [3] : Encryption [4] : Trust [5] : U.C. [6] : Status [7] : ChangeLog [8] : Group ID [9] : Connected To [10]
   ---------------------:---------:----------:--------------:----------:----------------:-----------:----------:------------:---------------:--------------:-------------------------------
   oud-ds-rs-0:1444     : 1       : 0        : 0            : 1898     : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : oud-ds-rs-0:1898
                        :         :          :              :          :                :           :          :            :               :              : (GID=1)
   oud-ds-rs-1:1444     : 1       : 0        : 0            : 1898     : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : oud-ds-rs-1:1898
                        :         :          :              :          :                :           :          :            :               :              : (GID=1)
   oud-ds-rs-2:1444     : 1       : 0        : 0            : 1898     : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : oud-ds-rs-2:1898
                        :         :          :              :          :                :           :          :            :               :              : (GID=1)
    
   Replication Server [11]        : RS #1 : RS #2 : RS #3
   -------------------------------:-------:-------:------
   oud-ds-rs-0:1898               : --    : Yes   : Yes
   (#1)                           :       :       :
   oud-ds-rs-1:1898               : Yes   : --    : Yes
   (#2)                           :       :       :
   oud-ds-rs-2:1898               : Yes   : Yes   : --
   (#3)                           :       :       :
    
   [1] The number of changes that are still missing on this element (and that have been applied to at least one other server).
   [2] Age of oldest missing change: the age (in seconds) of the oldest change that has not yet arrived on this element.
   [3] The replication port used to communicate between the servers whose contents are being replicated.
   [4] Whether the replication communication initiated by this element is encrypted or not.
   [5] Whether the directory server is trusted or not. Updates coming from an untrusted server are discarded and not propagated.
   [6] The number of untrusted changes. These are changes generated on this server while it is untrusted. Those changes are not propagated to the rest of the topology but are effective on the untrusted server.
   [7] The status of the replication on this element.
   [8] Whether the external change log is enabled for the base DN on this server or not.
   [9] The ID of the replication group to which the server belongs.
   [10] The replication server this server is connected to with its group ID between brackets.
   [11] This table represents the connections between the replication servers.  The headers of the columns use a number as identifier for each replication server.  See the values of the first column to identify the corresponding replication server for each number.
   ```

1. Type `exit` to exit the pod.

#### Using kubectl commands

1. The `dsreplication status` command can be invoked using the following kubectl command:

   ```bash
   $ kubectl --namespace <namespace> exec -it -c <containername> <podname> -- \
   /u01/oracle/user_projects/<OUD Instance/Pod Name>/OUD/bin/dsreplication status \
   --trustAll --hostname <OUD Instance/Pod Name> --port 1444 --adminUID admin \
   --dataToDisplay compat-view --dataToDisplay rs-connections
   ```

   For example: 

   ```bash
   $ kubectl --namespace oudns exec -it -c oud-ds-rs oud-ds-rs-0 -- \
   /u01/oracle/user_projects/oud-ds-rs-0/OUD/bin/dsreplication status \
   --trustAll --hostname oud-ds-rs-0 --port 1444 --adminUID admin \
   --dataToDisplay compat-view --dataToDisplay rs-connections
   ```
   
   The output will be the same as per [Run dresplication inside the pod](#run-dresplication-inside-the-pod).


### Verify the cronjob

1. Run the following command to make sure the cronjob is created:

   ```bash
   $ kubectl get cronjob -n <namespace>
   ```   
   
   For example:
   
   ```bash
   $ kubectl get cronjob -n oudns
   ```
   
   The output will look similar to the following:
   
   ```bash
   NAME               SCHEDULE       SUSPEND   ACTIVE   LAST SCHEDULE   AGE
   oud-pod-cron-job   */30 * * * *   False     0        <none>          15s
   ```
   
1. Run the following command to make sure the job(s) is created:

   ```bash
   $ kubectl get job -n <namespace> -o wide
   ```
   
   For example:
   
   ```bash
   $ kubectl get job -n oudns -o wide
   ```
   
   The output will look similar to the following:
   
   ```bash
   NAME                        COMPLETIONS   DURATION   AGE     CONTAINERS               IMAGES                                     SELECTOR
   oud-pod-cron-job-27467340   1/1           17s        6m48s   cron-kubectl,cron-helm   bitnami/kubectl:1.21.0,alpine/helm:3.2.0    controller-uid=e8e7dfe2-d197-4b84-a5a4-d203d54caaac
   ```
   
     
   **Note**: The jobs(s) will only be displayed after the time schedule originally set has elapsed. The default is `30` minutes).
   
   

#### Disabling the cronjob

If you need to disable the job, for example if maintenance needs to be performed on the node, you can disable the job as follows:

1. Run the following command to edit the cronjob:

   ```bash
   $ kubectl edit cronjob pod-cron-job -n <namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl edit cronjob oud-pod-cron-job -n oudns
   ```
   
   **Note**: This opens an edit session for the cronjob where parameters can be changed using standard `vi` commands.
   
1. In the edit session search for `suspend` and change the vaule from `false` to `true`:
   
   ```
   ...
             - name: oud-ds-rs-job-pv
               persistentVolumeClaim:
                 claimName: oud-ds-rs-job-pvc
     schedule: '*/30 * * * *'
     successfulJobsHistoryLimit: 3
     suspend: true
   ...
   ```

1. Save the file and exit `(wq!)`.

1. Run the following to make sure the cronjob is suspended:

   ```bash
   $ kubectl get cronjob -n <namespace>
   ```   
   
   For example:
   
   ```bash
   $ kubectl get cronjob -n oudns
   ```
   
   The output will look similar to the following:
   
   ```bash
   NAME               SCHEDULE       SUSPEND  ACTIVE   LAST SCHEDULE   AGE
   oud-pod-cron-job   */30 * * * *   True     0        11m             33m
   ```

1. To enable the cronjob again, repeat the above steps and set `suspend` to `false`.
   
   
### Ingress Configuration

With an OUD instance now deployed you are now ready to configure an ingress controller to direct traffic to OUD as per [Configure an ingress for an OUD](../configure-ingress).

### Undeploy an OUD deployment

#### Delete the OUD deployment


1. Find the deployment release name:

   ```bash
   $ helm --namespace <namespace> list
   ```
        
   For example:
        
   ```bash
   $ helm --namespace oudns list
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
   oud-ds-rs               oudns           1               2021-03-16 12:02:40.616927678 -0700     PDT deployed    oud-ds-rs-12.2.1.4.0    12.2.1.4.0
   ```
        
1. Delete the deployment using the following command:

   ```bash
   $ helm uninstall --namespace <namespace> <release>
   ```
        
   For example:

   ```bash
   $ helm uninstall --namespace oudns oud-ds-rs
   release "oud-ds-rs" uninstalled
   ```
   
#### Delete the persistent volume contents

1. Delete the contents of the `oud_user_projects` directory in the persistent volume:

   ```bash
   $ cd <persistent_volume>/oud_user_projects
   $ rm -rf *
   ```
   
   For example:
   
   ```bash
   $ cd /scratch/shared/oud_user_projects
   $ rm -rf *
   ```

### Appendix: Configuration Parameters

The following table lists the configurable parameters of the `oud-ds-rs` chart and their default values.

| **Parameter** | **Description** | **Default Value** |
| ------------- | --------------- | ----------------- |
| replicaCount  | Number of DS+RS instances/pods/services to be created with replication enabled against a base Oracle Unified Directory instance/pod. | 3 |
| restartPolicyName | restartPolicy to be configured for each POD containing Oracle Unified Directory instance | OnFailure |
| image.repository | Oracle Unified Directory Image Registry/Repository and name. Based on this, image parameter would be configured for Oracle Unified Directory pods/containers | oracle/oud |
| image.tag | Oracle Unified Directory Image Tag. Based on this, image parameter would be configured for Oracle Unified Directory pods/containers | 12.2.1.4.0 |
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
| ingress.type | Supported value: nginx | nginx | 
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
| oudPorts.adminldaps | Port on which Oracle Unified Directory Instance in the container should listen for Administration Communication over LDAPS Protocol | 1444 |
| oudPorts.adminhttps | Port on which Oracle Unified Directory Instance in the container should listen for Administration Communication over HTTPS Protocol. | 1888 |
| oudPorts.ldap | Port on which Oracle Unified Directory Instance in the container should listen for LDAP Communication. | 1389 |
| oudPorts.ldaps | Port on which Oracle Unified Directory Instance in the container should listen for LDAPS Communication. | 1636 |
| oudPorts.http | Port on which Oracle Unified Directory Instance in the container should listen for HTTP Communication. | 1080 |
| oudPorts.https | Port on which Oracle Unified Directory Instance in the container should listen for HTTPS Communication. | 1081 |
| oudPorts.replication | Port value to be used while setting up replication server. | 1898 |
| oudConfig.baseDN | BaseDN for Oracle Unified Directory Instances | dc=example,dc=com |
| oudConfig.rootUserDN | Root User DN for Oracle Unified Directory Instances | cn=Directory Manager |
| oudConfig.rootUserPassword | Password for Root User DN | RandomAlphanum |
| oudConfig.sampleData | To specify that the database should be populated with the specified number of sample entries. | 0 |
| oudConfig.sleepBeforeConfig | Based on the value for this parameter, initialization/configuration of each Oracle Unified Directory replica would be delayed. | 120 |
| oudConfig.adminUID | AdminUID to be configured with each replicated Oracle Unified Directory instance | admin |
| oudConfig.adminPassword | Password for AdminUID. If the value is not passed, value of rootUserPassword would be used as password for AdminUID. | rootUserPassword |
| baseOUD.envVarsConfigMap | Reference to ConfigMap which can contain additional environment variables to be passed on to POD for Base Oracle Unified Directory Instance. Following are the environment variables which would not be honored from the ConfigMap. <br> instanceType, sleepBeforeConfig, OUD_INSTANCE_NAME, hostname, baseDN, rootUserDN, rootUserPassword, adminConnectorPort, httpAdminConnectorPort, ldapPort, ldapsPort, httpPort, httpsPort, replicationPort, sampleData. | - |
| baseOUD.envVars | Environment variables in Yaml Map format. This is helpful when its requried to pass environment variables through --values file. List of env variables which would not be honored from envVars map is same as list of env var names mentioned for envVarsConfigMap. | - |
| replOUD.envVarsConfigMap | Reference to ConfigMap which can contain additional environment variables to be passed on to PODs for Replicated Oracle Unified Directory Instances. Following are the environment variables which would not be honored from the ConfigMap. <br> instanceType, sleepBeforeConfig, OUD_INSTANCE_NAME, hostname, baseDN, rootUserDN, rootUserPassword, adminConnectorPort, httpAdminConnectorPort, ldapPort, ldapsPort, httpPort, httpsPort, replicationPort, sampleData, sourceHost, sourceServerPorts, sourceAdminConnectorPort, sourceReplicationPort, dsreplication_1, dsreplication_2, dsreplication_3, dsreplication_4, post_dsreplication_dsconfig_1, post_dsreplication_dsconfig_2 | - |
| replOUD.envVars | Environment variables in Yaml Map format. This is helpful when its required to pass environment variables through --values file. List of env variables which would not be honored from envVars map is same as list of env var names mentioned for envVarsConfigMap. | - |
| replOUD.groupId | Group ID to be used/configured with each Oracle Unified Directory instance in replicated topology. | 1 |
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


