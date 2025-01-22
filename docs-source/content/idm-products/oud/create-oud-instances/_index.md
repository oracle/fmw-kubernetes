+++
title = "Create Oracle Unified Directory Instances"
weight = 5 
pre = "<b>5. </b>"
description=  "This document provides details of the oud-ds-rs Helm chart."
+++

1. [Introduction](#introduction)
1. [Create a Kubernetes namespace](#create-a-kubernetes-namespace)
1. [Create a Kubernetes secret for the container registry](#create-a-kubernetes-secret-for-the-container-registry)
1. [Create a Kubernetes secret for cronjob images](#create-a-kubernetes-secret-for-cronjob-images)
1. [The oud-ds-rs Helm chart](#the-oud-ds-rs-helm-chart)
1. [Create OUD instances](#create-oud-instances)
1. [Enabling Assured Replication (Optional)](#enabling-assured-replication-optional)
1. [Helm command output](#helm-command-output)
1. [Verify the OUD deployment](#verify-the-oud-deployment)
1. [Verify the OUD replication](#verify-the-oud-replication)
1. [Verify the cronjob](#verify-the-cronjob)
1. [Undeploy an OUD deployment](#undeploy-an-oud-deployment)
1. [Appendix A: Configuration parameters](#appendix-a-configuration-parameters)
1. [Appendix B: Environment Variables](#appendix-b-environment-variables)


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

**Note**: From July 22 ([22.3.1](https://github.com/oracle/fmw-kubernetes/releases)) onwards OUD deployment is performed using [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/).

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

Once OUD is deployed, if the Kubernetes node where the OUD pod(s) is/are running goes down after the pod eviction time-out, the pod(s) don't get evicted but move to a `Terminating` state. The pod(s) will then remain in that state forever. To avoid this problem a cron-job is created during OUD deployment that checks for any pods in `Terminating` state. If there are any pods in `Terminating` state, the cron job will delete them. The pods will then start again automatically. This cron job requires access to images on [hub.docker.com](https://hub.docker.com). A Kubernetes secret must therefore be created to enable access to these images.

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
of configuration parameters and their default values is shown in [Appendix A: Configuration parameters]((#appendix-a-configuration-parameters)).

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
    # memory, cpu parameters for both requests and limits for oud instances
     resources:
       limits:
         cpu: "1"
         memory: "4Gi"
       requests:
         cpu: "500m" 
         memory: "4Gi"
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
 
     imagePullSecrets:
       - name: dockercred
   ```
   
   For example:
   
   ```yaml
   image:
     repository: container-registry.oracle.com/middleware/oud_cpu
     tag: 12.2.1.4-jdk8-ol8-<January'25>
     pullPolicy: IfNotPresent
   imagePullSecrets:
     - name: orclcred
   oudConfig:
    # memory, cpu parameters for both requests and limits for oud instances
     resources:
       limits:
         cpu: "1"
         memory: "8Gi"
       requests:
         cpu: "500m" 
         memory: "4Gi"
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
       tag: 1.28.3
       pullPolicy: IfNotPresent
 
     imagePullSecrets:
       - name: dockercred
   ```   
   
  

  
   The following caveats exist:
   
   * Replace `<password>` with the relevant password.
   * `sampleData: "200"` will load 200 sample users into the default baseDN `dc=example,dc=com`. If you do not want sample data, remove this entry. If `sampleData` is set to `1,000,000` users or greater, then you must add the following entries to the yaml file to prevent inconsistencies in dsreplication:
      
      ```yaml
      deploymentConfig:
        startupTime: 720
        period: 120
        timeout: 60
      ```
  
   
   * The `<version>` in *kubectlImage* `tag:` should be set to the same version as your Kubernetes version (`kubectl version`). For example if your Kubernetes version is `1.28.3` set to `1.28.3`.
   * If you are not using Oracle Container Registry or your own container registry for your OUD container image, then you can remove the following:
   
      ```
      imagePullSecrets:
        - name: orclcred
      ```
	  
   *  If your cluster does not have access to the internet to pull external images, such as bitnami/kubectl or busybox, you must load the images in a local container registry. You must then set the following:
   
      ```
	  cronJob:
	    kubectlImage:
          repository: container-registry.example.com/bitnami/kubectl
          tag: 1.28.3
	      pullPolicy: IfNotPresent
	   
	  busybox:
        image: container-registry.example.com/busybox 
      ```	   
  
   * If using NFS for your persistent volume then change the `persistence` section as follows:
   
      **Note**: If you want to use NFS you should ensure that you have a default Kubernetes storage class defined for your environment that allows network storage.
	  
	  For more information on storage classes, see [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/). 
  
      ```yaml
      persistence:
        type: networkstorage
        networkstorage:
          nfs: 
            path: <persistent_volume>/oud_user_projects
            server: <NFS IP address>
		# if true, it will create the storageclass. if value is false, please provide existing storage class (storageClass) to be used.
        storageClassCreate: true
        storageClass: oud-sc
        # if storageClassCreate is true, please provide the custom provisioner if any to use. If you do not have a custom provisioner, delete this line, and it will use the default class kubernetes.io/is-default-class.
        provisioner:  kubernetes.io/is-default-class
      ```
	  
	  The following caveats exist:
   
      * If you want to create your own storage class, set `storageClassCreate: true`. If `storageClassCreate: true` it is recommended to set `storageClass` to a value of your choice, and `provisioner` to the provisioner supported by your cloud vendor.
	  * If you have an existing storageClass that supports network storage, set `storageClassCreate: false` and `storageClass` to the NAME value returned in "`kubectl  get storageclass`". The `provisioner` can be ignored.
	  
	  
   * If using Block Device storage for your persistent volume then change the `persistence` section as follows:
   
      **Note**: If you want to use block devices you should ensure that you have a default Kubernetes storage class defined for your environment that allows dynamic storage. Each vendor has its own storage provider but it may not be configured to provide dynamic storage allocation.
	  
      For more information on storage classes, see [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/).
  
      ```yaml
      persistence:
        type: blockstorage
        # Specify Accessmode ReadWriteMany for NFS and for block ReadWriteOnce
        accessMode: ReadWriteOnce
        # if true, it will create the storageclass. if value is false, please provide existing storage class (storageClass) to be used.
        storageClassCreate: true
        storageClass: oud-sc
        # if storageClassCreate is true, please provide the custom provisioner if any to use or else it will use default.
        provisioner:  oracle.com/oci
      ```  
     
	  The following caveats exist:
   
      * If you want to create your own storage class, set `storageClassCreate: true`. If `storageClassCreate: true` it is recommended to set `storageClass` to a value of your choice, and `provisioner` to the provisioner supported by your cloud vendor.
	  * If you have an existing storageClass that supports dynamic storage, set `storageClassCreate: false` and `storageClass` to the NAME value returned in "`kubectl get storageclass`". The `provisioner` can be ignored.
	  
   * For `resources`, `limits` and `requests`, the example CPU and memory values shown are for development environments only. For Enterprise Deployments, please review the performance recommendations and sizing requirements in [Enterprise Deployment Guide for Oracle Identity and Access Management in a Kubernetes Cluster](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/procuring-resources-oracle-cloud-infrastructure-deployment.html#GUID-2E3C8D01-43EB-4691-B1D6-25B1DC2475AE).

      **Note**: Limits and requests for CPU resources are measured in CPU units. One CPU in Kubernetes is equivalent to 1 vCPU/Core for cloud providers, and 1 hyperthread on bare-metal Intel processors. An "`m`" suffix in a CPU attribute indicates ‘milli-CPU’, so 500m is 50% of a CPU. Memory can be expressed in various units, where one Mi is one IEC unit mega-byte (1024^2), and one Gi is one IEC unit giga-byte (1024^3). For more information, see [Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/), [Assign Memory Resources to Containers and Pods](https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/), and [Assign CPU Resources to Containers and Pods](https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/).
   
      **Note**: The parameters above are also utilized by the Kubernetes Horizontal Pod Autoscaler (HPA). For more details on HPA, see [Kubernetes Horizontal Pod Autoscaler](../manage-oud-containers/hpa).

   * If you plan on integrating OUD with other Oracle components then you must specify the following under the `oudConfig:` section:
   
        ```
          integration: <Integration option>
		```
		
		For example:
		```
		oudConfig:
		  etc...
          integration: <Integration option>
		```

        It is recommended to choose the option covering your minimal requirements. Allowed values include: `no-integration` (no integration), `basic` (Directory Integration Platform), `generic` (Directory Integration Platform, Database Net Services and E-Business Suite integration), `eus` (Directory Integration  Platform, Database Net Services, E-Business Suite and Enterprise User Security integration). The default value is `no-integration`
        
		
		**Note**: This will enable the integration type only. To integrate OUD with the Oracle component referenced, refer to the relevant product component documentation.
   
   * If you want to enable Assured Replication, see [Enabling Assured Replication (Optional)](#enabling-assured-replication-optional).
   
   
   
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
   --set oudConfig.rootUserPassword=<password> \
   --set persistence.filesystem.hostPath.path=<persistent_volume>/oud_user_projects \
   --set image.repository=<image_location>,image.tag=<image_tag> \
   --set oudConfig.sampleData="200" \
   --set oudConfig.resources.limits.cpu="1",oudConfig.resources.limits.memory="8Gi",oudConfig.resources.requests.cpu="500m",oudConfig.resources.requests.memory="4Gi" \
   --set cronJob.kubectlImage.repository=bitnami/kubectl,cronJob.kubectlImage.tag=<version> \
   --set cronJob.imagePullSecrets[0].name="dockercred" \
   --set imagePullSecrets[0].name="orclcred" \
   <release_name> oud-ds-rs
   ```

   For example:

   ```bash
   $ helm install --namespace oudns \
   --set oudConfig.rootUserPassword=<password> \
   --set persistence.filesystem.hostPath.path=/scratch/shared/oud_user_projects \
   --set image.repository=container-registry.oracle.com/middleware/oud_cpu,image.tag=12.2.1.4-jdk8-ol8-<January'25> \
   --set oudConfig.sampleData="200" \
   --set oudConfig.resources.limits.cpu="1",oudConfig.resources.limits.memory="8Gi",oudConfig.resources.requests.cpu="500m",oudConfig.resources.requests.memory="4Gi" \
   --set cronJob.kubectlImage.repository=bitnami/kubectl,cronJob.kubectlImage.tag=1.28.3 \
   --set cronJob.imagePullSecrets[0].name="dockercred" \
   --set imagePullSecrets[0].name="orclcred" \
   oud-ds-rs oud-ds-rs
   ```

   The following caveats exist:

   * Replace `<password>` with a the relevant password.
   * `sampleData: "200"` will load 200 sample users into the default baseDN `dc=example,dc=com`. If you do not want sample data, remove this entry. If `sampleData` is set to `1,000,000` users or greater, then you must add the following entries to the yaml file to prevent inconsistencies in dsreplication: `--set deploymentConfig.startupTime=720,deploymentConfig.period=120,deploymentConfig.timeout=60`.
   * The `<version>` in *kubectlImage* `tag:` should be set to the same version as your Kubernetes version (`kubectl version`). For example if your Kubernetes version is `1.28.3` set to `1.28.3`.
   * If using using NFS for your persistent volume then use:
   
        ```
		--set persistence.networkstorage.nfs.path=<persistent_volume>/oud_user_projects,persistence.networkstorage.nfs.server:<NFS IP address>` \
		--set persistence.storageClassCreate="true",persistence.storageClass="oud-sc",persistence.provisioner="kubernetes.io/is-default-class" \
		```
      * If you want to create your own storage class, set `storageClassCreate: true`. If `storageClassCreate: true` it is recommended to set `storageClass` to a value of your choice, and `provisioner` to the provisioner supported by your cloud vendor.
	  * If you have an existing storageClass that supports dynamic storage, set `storageClassCreate: false` and `storageClass` to the NAME value returned in "`kubectl get storageclass`". The `provisioner` can be ignored. 
	  
   * If using using block storage for your persistent volume then use:
   
        ```
		--set persistence.type="blockstorage",persistence.accessMode="ReadWriteOnce" \
		--set persistence.storageClassCreate="true",persistence.storageClass="oud-sc",persistence.provisioner="oracle.com/oci" \
		```
      * If you want to create your own storage class, set `storageClassCreate: true`. If `storageClassCreate: true` it is recommended to set `storageClass` to a value of your choice, and `provisioner` to the provisioner supported by your cloud vendor.
	  * If you have an existing storageClass that supports dynamic storage, set `storageClassCreate: false` and `storageClass` to the NAME value returned in "`kubectl get storageclass`". The `provisioner` can be ignored. 	  
	  
   * If you are not using Oracle Container Registry or your own container registry for your OUD container image, then you can remove the following: `--set imagePullSecrets[0].name="orclcred"`.
   * For `resources`, `limits` and `requests1, the example CPU and memory values shown are for development environments only. For Enterprise Deployments, please review the performance recommendations and sizing requirements in [Enterprise Deployment Guide for Oracle Identity and Access Management in a Kubernetes Cluster](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/procuring-resources-oracle-cloud-infrastructure-deployment.html#GUID-2E3C8D01-43EB-4691-B1D6-25B1DC2475AE).

      **Note**: Limits and requests for CPU resources are measured in CPU units. One CPU in Kubernetes is equivalent to 1 vCPU/Core for cloud providers, and 1 hyperthread on bare-metal Intel processors. An "`m`" suffix in a CPU attribute indicates ‘milli-CPU’, so 500m is 50% of a CPU. Memory can be expressed in various units, where one Mi is one IEC unit mega-byte (1024^2), and one Gi is one IEC unit giga-byte (1024^3). For more information, see [Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/), [Assign Memory Resources to Containers and Pods](https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/), and [Assign CPU Resources to Containers and Pods](https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/).
   
      **Note**: The parameters above are also utilized by the Kubernetes Horizontal Pod Autoscaler (HPA). For more details on HPA, see [Kubernetes Horizontal Pod Autoscaler](../manage-oud-domains/hpa).
	  
   * If you plan on integrating OUD with other Oracle components then you must specify the following:
   
        ```
		--set oudConfig.integration=<Integration option>
		```

        It is recommended to choose the option covering your minimal requirements. Allowed values include: `no-integration` (no integration), `basic` (Directory Integration Platform), `generic` (Directory Integration Platform, Database Net Services and E-Business Suite integration), `eus` (Directory Integration  Platform, Database Net Services, E-Business Suite and Enterprise User Security integration). The default value is `no-integration`
        
		**Note**: This will enable the integration type only. To integrate OUD with the Oracle component referenced, refer to the relevant product component documentation.
   
   * If you want to enable Assured Replication, see [Enabling Assured Replication (Optional)](#enabling-assured-replication-optional).

1. Check the OUD deployment as per [Verify the OUD deployment](#verify-the-oud-deployment) and [Verify the OUD replication](#verify-the-oud-replication).


### Enabling Assured Replication (Optional)

If you want to enable assured replication, perform the following steps:

1. Create a directory on the persistent volume as follows:

   ```
   $ cd <persistent_volume>
   $ mkdir oud-repl-config  
   $ sudo chown -R 1000:0 oud-repl-config
   ```
   
   For example:
   
   ```
   $ cd /scratch/shared
   $ mkdir oud-repl-config   
   $ sudo chown -R 1000:0 oud-repl-config
   ```
 
   
1. Add the following section in the `oud-ds-rs-values-override.yaml`:

   ```
   replOUD:
     envVars:
       - name: post_dsreplication_dsconfig_3
         value: set-replication-domain-prop --domain-name ${baseDN} --advanced --set assured-type:safe-data --set assured-sd-level:2 --set assured-timeout:5s
       - name: execCmd_1
         value: /u01/oracle/user_projects/${OUD_INSTANCE_NAME}/OUD/bin/dsconfig --no-prompt --hostname ${sourceHost} --port ${adminConnectorPort} --bindDN "${rootUserDN}" --bindPasswordFile /u01/oracle/user_projects/${OUD_INSTANCE_NAME}/admin/rootPwdFile.txt  --trustAll set-replication-domain-prop --domain-name ${baseDN} --advanced --set assured-type:safe-data --set assured-sd-level:2 --set assured-timeout:5s --provider-name "Multimaster Synchronization"
   configVolume:
     enabled: true
     type: networkstorage
     storageClassCreate: true
     storageClass: oud-config
     provisioner: kubernetes.io/is-default-class
     networkstorage:
       nfs:
         server: <IP_address>
         path: <persistent_volume>/oud-repl-config
     mountPath: /u01/oracle/config-input
   ```
   
	The above will enable assured replication with assured type `safe-data` and `assured-sd-level: 2`.
	
	**Note**: If you prefer `assured-type` to be  set to `safe-read`, then change to `--set assured-type:safe-read` and remove `--set assured-sd-level:2`.
	
   For more information on OUD Assured Replication, and other options and levels, see, [Understanding the Oracle Unified Directory Replication Model](https://docs.oracle.com/en/middleware/idm/unified-directory/12.2.1.4/oudag/understanding-oracle-unified-directory-replication-model.html#GUID-A2438E61-D4DB-4B3B-8E2D-AE5921C3CF8C).

   The following caveats exist:

      * `post_dsreplication_dsconfig_N` and `execCmd_N` should be a unique key - change the suffix accordingly. For more information on the environment variable and respective keys, see, [Appendix B: Environment Variables](#appendix-b-environment-variables).

      * For configVolume the storage can be networkstorage(nfs) or filesystem(hostPath) as the config volume path has to be accessible from all the Kuberenetes nodes. Please note that block storage is not supported for configVolume.
   
      * If you want to create your own storage class, set `storageClassCreate: true`. If `storageClassCreate: true` it is recommended to set `storageClass` to a value of your choice, and `provisioner` to the provisioner supported by your cloud vendor.
	  
	   * If you have an existing storageClass that supports network storage, set `storageClassCreate: false` and `storageClass` to the NAME value returned in "`kubectl  get storageclass`". Please note that the storage-class should not be the one you used for the persistent volume earlier. The `provisioner` can be ignored.


### Helm command output

In all the examples above, the following output is shown following a successful execution of the `helm install` command.

   ```bash
   NAME: oud-ds-rs
   LAST DEPLOYED:  <DATE>
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
NAME                                  READY   STATUS      RESTARTS   AGE     IP             NODE            NOMINATED NODE   READINESS GATES
pod/oud-ds-rs-0                       1/1     Running     0          14m     10.244.1.180   <Worker Node>   <none>           <none>
pod/oud-ds-rs-1                       1/1     Running     0          8m26s   10.244.1.181   <Worker Node>   <none>           <none>
pod/oud-ds-rs-2                       0/1     Running     0          2m24s   10.244.1.182   <Worker Node>   <none>           <none>
pod/oud-pod-cron-job-27586680-p5d8q   0/1     Completed   0          50s     10.244.1.183   <Worker Node>   <none>           <none>

NAME                          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                          AGE   SELECTOR
service/oud-ds-rs             ClusterIP   None             <none>        1444/TCP,1888/TCP,1389/TCP,1636/TCP,1080/TCP,1081/TCP,1898/TCP   14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
service/oud-ds-rs-0           ClusterIP   None             <none>        1444/TCP,1888/TCP,1898/TCP                                       14m app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-0
service/oud-ds-rs-1           ClusterIP   None             <none>        1444/TCP,1888/TCP,1898/TCP                                       14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-1
service/oud-ds-rs-2           ClusterIP   None             <none>        1444/TCP,1888/TCP,1898/TCP                                       14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-2
service/oud-ds-rs-http-0      ClusterIP   10.104.112.93    <none>        1080/TCP,1081/TCP                                                14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-0
service/oud-ds-rs-http-1      ClusterIP   10.103.105.70    <none>        1080/TCP,1081/TCP                                                14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-1
service/oud-ds-rs-http-2      ClusterIP   10.110.160.107   <none>        1080/TCP,1081/TCP                                                14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-2
service/oud-ds-rs-lbr-admin   ClusterIP   10.99.238.222    <none>        1888/TCP,1444/TCP                                                14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
service/oud-ds-rs-lbr-http    ClusterIP   10.101.250.196   <none>        1080/TCP,1081/TCP                                                14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
service/oud-ds-rs-lbr-ldap    ClusterIP   10.104.149.90    <none>        1389/TCP,1636/TCP                                                14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
service/oud-ds-rs-ldap-0      ClusterIP   10.109.255.221   <none>        1389/TCP,1636/TCP                                                14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-0
service/oud-ds-rs-ldap-1      ClusterIP   10.111.135.142   <none>        1389/TCP,1636/TCP                                                14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-1
service/oud-ds-rs-ldap-2      ClusterIP   10.100.8.145     <none>        1389/TCP,1636/TCP                                                14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-2

NAME                                     TYPE                             DATA   AGE
secret/dockercred                        kubernetes.io/dockerconfigjson   1      4h24m
secret/orclcred                          kubernetes.io/dockerconfigjson   1      14m
secret/oud-ds-rs-creds                   opaque                           8      14m
secret/oud-ds-rs-tls-cert                kubernetes.io/tls                2      14m
secret/sh.helm.release.v1.oud-ds-rs.v1   helm.sh/release.v1               1      14m


NAME                                 CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                       STORAGECLASS        REASON   AGE    VOLUMEMODE
persistentvolume/oud-ds-rs-pv        20Gi       RWX            Delete           Bound    oudns/oud-ds-rs-pvc         manual                       14m    Filesystem

NAME                                  STATUS   VOLUME         CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE
persistentvolumeclaim/oud-ds-rs-pvc   Bound    oud-ds-rs-pv   20Gi       RWX            manual         14m   Filesystem

NAME                                                      CLASS    HOSTS                                                               ADDRESS   PORTS     AGE
ingress.networking.k8s.io/oud-ds-rs-admin-ingress-nginx   <none>   oud-ds-rs-admin-0,oud-ds-rs-admin-0,oud-ds-rs-admin-1 + 3 more...             80, 443   14m
ingress.networking.k8s.io/oud-ds-rs-http-ingress-nginx    <none>   oud-ds-rs-http-0,oud-ds-rs-http-1,oud-ds-rs-http-2 + 3 more...                80, 443   14m

```

**Note**: If you are using block storage you will see slightly different entries for PV and PVC, for example:

```
NAME                                                  CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS        CLAIM                            STORAGECLASS                        REASON   AGE   VOLUMEMODE
persistentvolume/ocid1.volume.oc1.iad.<unique_ID>     50Gi       RWO            Delete           Bound         oudns/oud-ds-rs-pv-oud-ds-rs-2   oud-sc                                       60m   Filesystem
persistentvolume/ocid1.volume.oc1.iad.<unique_ID>     50Gi       RWO            Delete           Bound         oudns/oud-ds-rs-pv-oud-ds-rs-1   oud-sc                                       67m   Filesystem
persistentvolume/ocid1.volume.oc1.iad.<unique_ID>     50Gi       RWO            Delete           Bound         oudns/oud-ds-rs-pv-oud-ds-rs-3   oud-sc                                       45m   Filesystem

NAME                                             STATUS   VOLUME                             CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE
persistentvolumeclaim/oud-ds-rs-pv-oud-ds-rs-1   Bound    ocid1.volume.oc1.iad.<unique_ID>   50Gi       RWO            oud-sc         67m   Filesystem
persistentvolumeclaim/oud-ds-rs-pv-oud-ds-rs-2   Bound    ocid1.volume.oc1.iad.<unique_ID>   50Gi       RWO            oud-sc         60m   Filesystem
persistentvolumeclaim/oud-ds-rs-pv-oud-ds-rs-3   Bound    ocid1.volume.oc1.iad.<unique_ID>   50Gi       RWO            oud-sc         45m   Filesystem
```

**Note**: Initially `pod/oud-ds-rs-0` will appear with a `STATUS` of `0/1` and it will take approximately 5 minutes before OUD is started (`1/1`). Once `pod/oud-ds-rs-0` has a `STATUS` of `1/1`, `pod/oud-ds-rs-1` will appear with a `STATUS` of `0/1`. Once `pod/oud-ds-rs-1` is started (`1/1`),  `pod/oud-ds-rs-2` will appear. It will take around 15 minutes for all the pods to fully started.

While the oud-ds-rs pods have a `STATUS` of `0/1` the pod is running but OUD server associated with it is currently starting. While the pod is starting you can check the startup status in the pod logs, by running the following command:

```bash
$ kubectl logs <pod> -n oudns
```

For example:

```
$ kubectl logs oud-ds-rs-0 -n oudns
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
   oud-ds-rs-0:1444     : 202     : 0        : 0            : 1898     : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : oud-ds-rs-0:1898
                        :         :          :              :          :                :           :          :            :               :              : (GID=1)
   oud-ds-rs-1:1444     : 202     : 0        : 0            : 1898     : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : oud-ds-rs-1:1898
                        :         :          :              :          :                :           :          :            :               :              : (GID=1)
   oud-ds-rs-2:1444     : 202     : 0        : 0            : 1898     : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : oud-ds-rs-2:1898
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

#### Verify OUD assured replication status

**Note**: This section only needs to be followed if you enabled assured replication as per [Enabling Assured Replication (Optional)](#enabling-assured-replication-optional).

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
   
1. At the prompt, enter the following commands:

   ```bash
   $ echo $bindPassword1 > /tmp/pwd.txt
   $ /u01/oracle/user_projects/${OUD_INSTANCE_NAME}/OUD/bin/dsconfig --no-prompt --hostname ${OUD_INSTANCE_NAME} --port ${adminConnectorPort} --bindDN "${rootUserDN}" --bindPasswordFile /tmp/pwd.txt  --trustAll get-replication-domain-prop --domain-name ${baseDN} --advanced --property assured-type --property assured-sd-level --property assured-timeout --provider-name "Multimaster Synchronization"
   ```

   The output will look similar to the following:
   
   ```
   Property         : Value(s)
   -----------------:----------
   assured-sd-level : 2
   assured-timeout  : 5 s
   assured-type     : safe-data
   ```

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
   oud-pod-cron-job   */30 * * * *   False     0        5m18s           19m
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
   NAME                        COMPLETIONS   DURATION   AGE     CONTAINERS        IMAGES                   SELECTOR
   oud-pod-cron-job-27586680   1/1           1s         5m36s   cron-kubectl      bitnami/kubectl:1.28.3   controller-uid=700ab9f7-6094-488a-854d-f1b914de5f61
   ```
   

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
   NAME               SCHEDULE       SUSPEND   ACTIVE   LAST SCHEDULE   AGE
   oud-pod-cron-job   */30 * * * *   True      0        7m47s           21m
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
   NAME            NAMESPACE       REVISION        UPDATED   STATUS          CHART           APP VERSION
   oud-ds-rs       oudns           1               <DATE>    deployed        oud-ds-rs-0.2   12.2.1.4.0
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
   
1. Run the following command to view the status:

   ```bash
   $ kubectl --namespace oudns get pod,service,secret,pv,pvc,ingress -o wide
   ```
   
   Initially the pods and persistent volume (PV) and persistent volume claim (PVC) will move to a `Terminating` status:
   
   ```
   NAME              READY   STATUS        RESTARTS   AGE   IP             NODE            NOMINATED NODE   READINESS GATES

   pod/oud-ds-rs-0   1/1     Terminating   0          24m   10.244.1.180   <Worker Node>   <none>           <none>
   pod/oud-ds-rs-1   1/1     Terminating   0          18m   10.244.1.181   <Worker Node>   <none>           <none>
   pod/oud-ds-rs-2   1/1     Terminating   0          12m   10.244.1.182   <Worker Node>   <none>           <none>

   NAME                         TYPE                                  DATA   AGE
   secret/default-token-msmmd   kubernetes.io/service-account-token   3      3d20h
   secret/dockercred            kubernetes.io/dockerconfigjson        1      3d20h
   secret/orclcred              kubernetes.io/dockerconfigjson        1      3d20h

   NAME                                 CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS        CLAIM                       STORAGECLASS        REASON   AGE    VOLUMEMODE
   persistentvolume/oud-ds-rs-pv        20Gi       RWX            Delete           Terminating   oudns/oud-ds-rs-pvc         manual                       24m    Filesystem

   NAME                                  STATUS        VOLUME         CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE
   persistentvolumeclaim/oud-ds-rs-pvc   Terminating   oud-ds-rs-pv   20Gi       RWX            manual         24m   Filesystem
   ```
   
   Run the command again until the pods, PV and PVC disappear.
   
1. If the PV or PVC's don't delete, remove them manually:

   ```
   $ kubectl delete pvc oud-ds-rs-pvc -n oudns
   $ kubectl delete pv oud-ds-rs-pv -n oudns
   ```
   
   **Note**: If using blockstorage, you will see a PV and PVC for each pod. Delete all of the PVC's and PV's using the above commands. 
   
   
   
#### Delete the persistent volume contents

**Note**: The steps below are not relevant for block storage.

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

### Appendix A: Configuration Parameters

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
| ingress.nginx.http.nginxAnnotations | | { <br>ingressClassName: "nginx"<br> }|
| ingress.nginx.admin.host | Hostname to be used with Ingress Rules. <br>If not set, hostname would be configured according to fullname. <br> Hosts would be configured as < fullname >-admin.< domain >, < fullname >-admin-0.< domain >, < fullname >-admin-1.< domain >, etc. | |
| ingress.nginx.admin.domain | Domain name to be used with Ingress Rules. <br>In ingress rules, hosts would be configured as < host >.< domain >, < host >-0.< domain >, < host >-1.< domain >, etc. | |
| ingress.nginx.admin.nginxAnnotations | | { <br>ingressClassName: "nginx" <br> nginx.ingress.kubernetes.io/backend-protocol: "https"<br>} |
| ingress.ingress.tlsSecret | Secret name to use an already created TLS Secret. If such secret is not provided, one would be created with name < fullname >-tls-cert. If the TLS Secret is in different namespace, name can be mentioned as < namespace >/< tlsSecretName > | |
| ingress.certCN | Subject's common name (cn) for SelfSigned Cert. | < fullname > |
| ingress.certValidityDays | Validity of Self-Signed Cert in days | 365 |
| secret.enabled | If enabled it will use the secret created with base64 encoding. if value is false, secret would not be used and input values (through --set, --values, etc.) would be used while creation of pods. | true|
| secret.name | secret name to use an already created Secret | oud-ds-rs-< fullname >-creds |
| secret.type | Specifies the type of the secret | Opaque |
| persistence.enabled | If enabled, it will use the persistent volume. if value is false, PV and PVC would not be used and pods would be using the default emptyDir mount volume. | true |
| persistence.pvname | pvname to use an already created Persistent Volume , If blank will use the default name | oud-ds-rs-< fullname >-pv |
| persistence.pvcname | pvcname to use an already created Persistent Volume Claim , If blank will use default name  |oud-ds-rs-< fullname >-pvc |
| persistence.type | supported values: either filesystem or networkstorage or blockstorage or custom | filesystem |
| persistence.filesystem.hostPath.path | The path location mentioned should be created and accessible from the local host provided with necessary privileges for the user. | /scratch/shared/oud_user_projects |
| persistence.networkstorage.nfs.path | Path of NFS Share location  | /scratch/shared/oud_user_projects |
| persistence.networkstorage.nfs.server | IP or hostname of NFS Server  | 0.0.0.0 |
| persistence.custom.* | Based on values/data, YAML content would be included in PersistenceVolume Object |  |
| persistence.accessMode | Specifies the access mode of the location provided. ReadWriteMany for Filesystem/NFS, ReadWriteOnce for block storage. | ReadWriteMany |
| persistence.size  | Specifies the size of the storage | 10Gi |
| persistence.storageClassCreate | if true, it will create the storageclass. if value is false, please provide existing storage class (storageClass) to be used. | empty |
| persistence.storageClass | Specifies the storageclass of the persistence volume. | empty |
| persistence.provisioner | If storageClassCreate is true, provide the custom provisioner if any . | kubernetes.io/is-default-class |
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
| configVolume.annotations | Specifies any annotations that will be used| { } |
| configVolume.storageClassCreate |  If true, it will create the storageclass. if value is false, provide existing storage class (storageClass) to be used. | true |
| configVolume.provisioner |  If configVolume.storageClassCreate is true, please provide the custom provisioner if any. | kubernetes.io/is-default-class |
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
| baseOUD.envVars | Environment variables in Yaml Map format. This is helpful when its requried to pass environment variables through --values file. List of env variables which would not be honored from envVars map is same as list of env var names mentioned for envVarsConfigMap. For a full list of environment variables, see [Appendix B: Environment Variables](#appendix-b-environment-variables).| - |
| replOUD.envVarsConfigMap | Reference to ConfigMap which can contain additional environment variables to be passed on to PODs for Replicated Oracle Unified Directory Instances. Following are the environment variables which would not be honored from the ConfigMap. <br> instanceType, sleepBeforeConfig, OUD_INSTANCE_NAME, hostname, baseDN, rootUserDN, rootUserPassword, adminConnectorPort, httpAdminConnectorPort, ldapPort, ldapsPort, httpPort, httpsPort, replicationPort, sampleData, sourceHost, sourceServerPorts, sourceAdminConnectorPort, sourceReplicationPort, dsreplication_1, dsreplication_2, dsreplication_3, dsreplication_4, post_dsreplication_dsconfig_1, post_dsreplication_dsconfig_2 | - |
| replOUD.envVars | Environment variables in Yaml Map format. This is helpful when its required to pass environment variables through --values file. List of env variables which would not be honored from envVars map is same as list of env var names mentioned for envVarsConfigMap. For a full list of environment variables, see [Appendix B: Environment Variables](#appendix-b-environment-variables).| - |
| podManagementPolicy | Defines the policy for pod management within the statefulset. Typical values are  OrderedReady/Parallel | OrderedReady |
| updateStrategy |  Allows you to configure and disable automated rolling updates for containers, labels, resource request/limits, and annotations for the Pods in a StatefulSet. Typical values are OnDelete/RollingUpdate | RollingUpdate |
| busybox.image | busy box image name. Used for initcontainers | busybox |
| oudConfig.cleanupbeforeStart |  Used to remove the individual pod directories during restart. Recommended value is false. **Note**: Do not change the default value (false) as it will delete the existing data and clone it from base pod again.| false |
| oudConfig.disablereplicationbeforeStop | This parameter is used to disable replication when a pod is restarted. Recommended value is false. **Note** Do not change the default value (false), as changing the value will result in an issue where the pod won't join the replication topology after a restart. | false |
| oudConfig.resources.requests.memory | This parameter is used to set the memory request for the OUD pod | 4Gi |
| oudConfig.resources.requests.cpu | This parameter is used to set the cpu request for the OUD  pod | 0.5 |
| oudConfig.resources.limits.memory | This parameter is used to set the memory limit for the OUD pod | 4Gi |
| oudConfig.resources.limits.cpu | This parameter is used to set the cpu limit for the OUD pod | 1 |
| replOUD.groupId | Group ID to be used/configured with each Oracle Unified Directory instance in replicated topology. | 1 |
| service.lbrtype | Type of load balancer Service to be created for admin, http,ldap services. Values allowed: ClusterIP/NodePort | ClusterIP |
| oudPorts.nodePorts.adminldaps | Public port on which the OUD instance in the container should listen for administration communication over LDAPS Protocol. The port number should be between 30000-32767. No duplicate values are  allowed. **Note**: Set only if service.lbrtype is set as NodePort. If left blank then k8s will assign random ports in between 30000 and 32767. | |
| oudPorts.nodePorts.adminhttps | Public port on which the OUD instance in the container should listen for administration communication over HTTPS Protocol. The port number should be between 30000-32767. No duplicate values are  allowed. **Note**: Set only if service.lbrtype is set as NodePort. If left blank then k8s will assign random ports in between 30000 and 32767. | |
| oudPorts.nodePorts.ldap | Public port on which the OUD instance in the container should listen for LDAP communication. The port number should be between 30000-32767. No duplicate values are  allowed. **Note**: Set only if service.lbrtype is set as NodePort. If left blank then k8s will assign random ports in between 30000 and 32767. | |
| oudPorts.nodePorts.ldaps | Public port on which the OUD instance in the container should listen for LDAPS communication. The port number should be between 30000-32767. No duplicate values are  allowed. **Note**: Set only if service.lbrtype is set as NodePort. If left blank then k8s will assign random ports in between 30000 and 32767. | |
| oudPorts.nodePorts.http | Public port on which the OUD instance in the container should listen for HTTP communication. The port number should be between 30000-32767. No duplicate values are  allowed. **Note**: Set only if service.lbrtype is set as NodePort. If left blank then k8s will assign random ports in between 30000 and 32767. | |
| oudPorts.nodePorts.https | Public port on which the OUD instance in the container should listen for HTTPS communication. The port number should be between 30000-32767. No duplicate values are  allowed. **Note**: Set only if service.lbrtype is set as NodePort. If left blank then k8s will assign random ports in between 30000 and 32767. | |
| oudConfig.integration | Specifies which Oracle components the server can be integrated with. It is recommended to choose the option covering your minimal requirements. Allowed values: no-integration (no integration), basic (Directory Integration Platform), generic (Directory Integration Platform, Database Net Services and E-Business Suite integration), eus (Directory Integration  Platform, Database Net Services, E-Business Suite and Enterprise User Security integration)| no-integration |
| elk.logStashImage | The version of logstash you want to install |	logstash:8.3.1 |
| elk.sslenabled | If SSL is enabled for ELK set the value to true, or if NON-SSL set to false. This value must be lowercase | TRUE |
| elk.eshosts |	The URL for sending logs to Elasticsearch. HTTP if NON-SSL is used | https://elasticsearch.example.com:9200 |
| elk.esuser | The name of the user for logstash to access Elasticsearch | logstash_internal |
| elk.espassword | The password for ELK_USER | password |
| elk.esapikey | The API key details | apikey |
| elk.esindex |	The log name  | oudlogs-00001 |
| elk.imagePullSecrets | secret to be used for pulling logstash image |	dockercred |


### Appendix B: Environment Variables

| **Environment Variable** | **Description** | **Default Value** |
| ------ | ------ | ------ |
| ldapPort | Port on which the Oracle Unified Directory instance in the container should listen for LDAP communication. Use 'disabled' if you do not want to enable it. | 1389 |
| ldapsPort | Port on which the Oracle Unified Directory instance in the container should listen for LDAPS communication. Use 'disabled' if you do not want to enable it. | 1636 |
| rootUserDN | DN for the Oracle Unified Directory instance root user. | ------ |
| rootUserPassword | Password for the Oracle Unified Directory instance root user. | ------ |
| adminConnectorPort | Port on which the Oracle Unified Directory instance in the container should listen for administration communication over LDAPS. Use 'disabled' if you do not want to enable it. Note that at least one of the LDAP or the HTTP administration ports must be enabled. | 1444 |
| httpAdminConnectorPort | Port on which the Oracle Unified Directory Instance in the container should listen for Administration Communication over HTTPS Protocol. Use 'disabled' if you do not want to enable it. Note that at least one of the LDAP or the HTTP administration ports must be enabled. | 1888 |
| httpPort | Port on which the Oracle Unified Directory Instance in the container should listen for HTTP Communication. Use 'disabled' if you do not want to enable it. | 1080 |
| httpsPort | Port on which the Oracle Unified Directory Instance in the container should listen for HTTPS Communication. Use 'disabled' if you do not want to enable it. | 1081 |
| sampleData | Specifies the number of sample entries to populate the Oracle Unified Directory instance with on creation. If this parameter has a non-numeric value, the parameter addBaseEntry is added to the command instead of sampleData.  Similarly, when the ldifFile_n parameter is specified sampleData will not be considered and ldifFile entries will be populated.| 0 |
| adminUID | User ID of the Global Administrator to use to bind to the server. This parameter is primarily used with the dsreplication command. | ------ |
| adminPassword | Password for adminUID | ------ |
| bindDN1 | BindDN to be used while setting up replication using `dsreplication` to connect to First Directory/Replication Instance. | ------ |
| bindPassword1 | Password for bindDN1 | ------ |
| bindDN2 | BindDN to be used while setting up replication using `dsreplication` to connect to Second Directory/Replication Instance. | ------ |
| bindPassword2 | Password for bindDN2 | ------ |
| replicationPort | Port value to be used while setting up a replication server. This variable is used to substitute values in `dsreplication` parameters. | 1898 |
| sourceHost | Value for the hostname to be used while setting up a replication server. This variable is used to substitute values in `dsreplication` parameters. | ------ |
| initializeFromHost | Value for the hostname to be used while initializing data on a new Oracle Unified Directory instance replicated  from an existing instance. This variable is used to substitute values in `dsreplication` parameters. It is possible to have a different value for sourceHost and initializeFromHost while setting up replication with Replication Server, sourceHost can be used for the Replication Server and initializeFromHost can be used for an existing Directory instance from which data will be initialized.| $sourceHost |
| serverTuning | Values to be used to tune JVM settings. The default value is jvm-default.  If specific tuning parameters are required, they can be added using this variable.  | jvm-default |
| offlineToolsTuning | Values to be used to specify the tuning for offline tools. This variable if not specified will consider jvm-default as the default or specify the complete set of values with options if wanted to set to specific tuning | jvm-default|
| generateSelfSignedCertificate | Set to "true" if the requirement is to generate a self signed certificate when creating an Oracle Unified Directory instance. If no value is provided this value takes the default, "true". If using a certificate generated separately this value should be set to "false". | true |
| usePkcs11Keystore | Use a certificate in a PKCS#11 token that the replication gateway will use as servercertificate when accepting encrypted connections from the Oracle Directory Server Enterprise Edition server. Set to "true" if the requirement is to use the usePkcs11Keystore parameter when creating an Oracle Unified Directory instance. By default this parameter is not set. To use this option generateSelfSignedCertificate should be set to "false".| ------ |
| enableStartTLS | Enable StartTLS to allow secure communication with the directory server by using the LDAP port. By default this parameter is not set. To use this option generateSelfSignedCertificate should be set to "false". | ------ |
| useJCEKS | Specifies the path of a JCEKS that contains a certificate that the replication gateway will use as server certificate when accepting encrypted connections from the Oracle Directory Server Enterprise Edition server.  If required this should specify the keyStorePath, for example, `/u01/oracle/config/keystore`. | ------ |
| useJavaKeystore | Specify the path to the Java Keystore (JKS) that contains the server certificate. If required this should specify the path to the JKS, for example, `/u01/oracle/config/keystore`. By default this parameter is not set. To use this option generateSelfSignedCertificate should be set to "false". | ------ |
| usePkcs12keyStore | Specify the path to the PKCS#12 keystore that contains the server certificate. If required this should specify the path, for example, `/u01/oracle/config/keystore.p12`. By default this parameter is not set. | ------ |
| keyStorePasswordFile | Use the password in the specified file to access the certificate keystore. A password is required when you specify an existing certificate (JKS, JCEKS, PKCS#11, orPKCS#12) as a server certificate. If required this should specify the path of the password file, for example, `/u01/oracle/config/keystorepassword.txt`. By default this parameter is not set. | ------ |
| eusPasswordScheme | Set password storage scheme, if configuring Oracle Unified Directory for Enterprise User Security.  Set this to a value of either "sha1" or "sha2". By default this parameter is not set. | ------ |
| jmxPort | Port on which the Directory Server should listen for JMX communication.  Use 'disabled' if you do not want to enable it. | disabled |
| javaSecurityFile | Specify the path to the Java security file. If required this should specify the path, for example, `/u01/oracle/config/new_security_file`. By default this parameter is not set. | ------ |
| schemaConfigFile_n | 'n' in the variable name represents a numeric value between 1 and 50. This variable is used to set the full path of LDIF files that need to be passed to the Oracle Unified Directory instance for schema configuration/extension. If required this should specify the path, for example, `schemaConfigFile_1=/u01/oracle/config/00_test.ldif`. | ------ |
| ldifFile_n | 'n' in the variable name represents a numeric value between 1 and 50. This variable is used to set the full path of LDIF files that need to be passed to the Oracle Unified Directory instance for initial data population. If required this should specify the path, for example, `ldifFile_1=/u01/oracle/config/test1.ldif`. | ------ |
| dsconfigBatchFile_n | 'n' in the variable name represents a numeric value between 1 and 50. This variable is used to set the full path of LDIF files that need to be passed to the Oracle Unified Directory instance for batch processing by the `dsconfig` command. If required this should specify the path, for example, `dsconfigBatchFile_1=/u01/oracle/config/dsconfig_1.txt`.  When executing the `dsconfig` command the following values are added implicitly to the arguments contained in the batch file : ${hostname}, ${adminConnectorPort}, ${bindDN} and ${bindPasswordFile} | ------ |
| dstune_n | 'n' in the variable name represents a numeric value between 1 and 50. Allows commands and options to be passed to the `dstune` utility as a full command. | ------ |
| dsconfig_n | 'n' in the variable name represents a numeric value between 1 and 300. Each file represents a set of execution parameters for the `dsconfig` command.  For each `dsconfig` execution, the following variables are added implicitly : ${hostname}, ${adminConnectorPort}, ${bindDN}, ${bindPasswordFile}. | ------ |
| dsreplication_n | 'n' in the variable name represents a numeric value between 1 and 50. Each file represents a set of execution parameters for the `dsreplication` command.  For each `dsreplication` execution, the following variables are added implicitly : ${hostname}, ${ldapPort}, ${ldapsPort}, ${adminConnectorPort}, ${replicationPort}, ${sourceHost}, ${initializeFromHost}, and ${baseDN}.  Depending on the dsreplication sub-command, the following variables are added implicitly : ${bindDN1}, ${bindPasswordFile1}, ${bindDN2}, ${bindPasswordFile2}, ${adminUID}, and ${adminPasswordFile}. | ------ |
| post_dsreplication_dsconfig_n | 'n' in the variable name represents a numeric value between 1 and 300. Each file represents a set of execution parameters for the `dsconfig` command to be run following execution of the `dsreplication` command. For each `dsconfig` execution, the following variables/values are added implicitly : --provider-name "Multimaster Synchronization", ${hostname}, ${adminConnectorPort}, ${bindDN}, ${bindPasswordFile}. | ------ |
| rebuildIndex_n | 'n' in the variable name represents a numeric value between 1 and 50. Each file represents a set of execution parameters for the `rebuild-index` command. For each `rebuild-index` execution, the following variables are added implicitly : ${hostname}, ${adminConnectorPort}, ${bindDN}, ${bindPasswordFile}, and ${baseDN}. | ------ |
| manageSuffix_n | 'n' in the variable name represents a numeric value between 1 and 50. Each file represents a set of execution parameters for the `manage-suffix` command. For each `manage-suffix` execution, the following variables are added implicitly : ${hostname}, ${adminConnectorPort}, ${bindDN}, ${bindPasswordFile}. | ------ |
| importLdif_n | 'n' in the variable name represents a numeric value between 1 and 50. Each file represents a set of execution parameters for the `import-ldif` command. For each `import-ldif` execution, the following variables are added implicitly : ${hostname}, ${adminConnectorPort}, ${bindDN}, ${bindPasswordFile}. | ------ |
| execCmd_n | 'n' in the variable name represents a numeric value between 1 and 300. Each file represents a command to be executed in the container. For each command execution, the following variables are replaced, if present in the command : ${hostname}, ${ldapPort}, ${ldapsPort}, ${adminConnectorPort}. | ------ |
| restartAfterRebuildIndex | Specifies whether to restart the server after building the index. | false |
| restartAfterSchemaConfig | Specifies whether to restart the server after configuring the schema. | false |

**Note** For the following parameters above, the following statement applies:

* dsconfig_n
* dsreplication_n
* post_dsreplication_dsconfig_n
* rebuildIndex_n
* manageSuffix_n
* importLdif_n
* execCmd_n

If values are provided the following variables will be substituted with their values: ${hostname},${ldapPort},${ldapsPort},${adminConnectorPort},${replicationPort},${sourceHost},${initializeFromHost},${sourceAdminConnectorPort},${sourceReplicationPort},${baseDN},${rootUserDN},${adminUID},${rootPwdFile},${bindPasswordFile},${adminPwdFile},${bindPwdFile1},${bindPwdFile2}