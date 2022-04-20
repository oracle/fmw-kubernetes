+++
title = "Create Oracle Unified Directory Services Manager Instances"
weight = 4 
pre = "<b>4. </b>"
description=  "This document provides details of the oudsm Helm chart."
+++

1. [Introduction](#introduction)
1. [Create a Kubernetes namespace](#create-a-kubernetes-namespace)
1. [Create a Kubernetes secret for the container registry](#create-a-kubernetes-secret-for-the-container-registry)
1. [Create a persistent volume directory](#create-a-persistent-volume-directory)
1. [The oudsm Helm chart](#the-oudsm-helm-chart)
1. [Create OUDSM instances](#create-oudsm-instances)
1. [Helm command output](#helm-command-output)
1. [Verify the OUDSM deployment](#verify-the-oudsm-deployment)
1. [Undeploy an OUDSM deployment](#undeploy-an-oudsm-deployment)
1. [Appendix: Configuration parameters](#appendix-configuration-parameters)

### Introduction

This chapter demonstrates how to deploy Oracle Unified Directory Services Manager (OUDSM) 12c instance(s) using the Helm package manager for Kubernetes. 

Based on the configuration, this chart deploys the following objects in the specified namespace of a Kubernetes cluster.

* Service Account
* Secret
* Persistent Volume and Persistent Volume Claim
* Pod(s)/Container(s) for Oracle Unified Directory Services Manager Instances
* Services for interfaces exposed through Oracle Unified Directory Services Manager Instances
* Ingress configuration

### Create a Kubernetes namespace

Create a Kubernetes namespace for the OUDSM deployment by running the following command:

```bash
$ kubectl create namespace <namespace>
```

For example:

```bash
$ kubectl create namespace oudsmns
```

The output will look similar to the following:

```
namespace/oudsmns created
```


### Create a Kubernetes secret for the container registry

Create a Kubernetes secret that stores the credentials for the container registry where the OUDSM image is stored. This step must be followed if using Oracle Container Registry or your own private container registry. If you are not using a container registry and have loaded the images on each of the master and worker nodes, you can skip this step.

1. Run the following command to create the secret:

   ```bash
   kubectl create secret docker-registry "orclcred" --docker-server=<CONTAINER_REGISTRY> \
   --docker-username="<USER_NAME>" \
   --docker-password=<PASSWORD> --docker-email=<EMAIL_ID> \
   --namespace=<domain_namespace>
   ```
   
   For example, if using Oracle Container Registry:
   
   ```bash
   kubectl create secret docker-registry "orclcred" --docker-server=container-registry.oracle.com \
   --docker-username="user@example.com" \
   --docker-password=password --docker-email=user@example.com \
   --namespace=oudsmns
   ```
   
   
   Replace `<USER_NAME>` and `<PASSWORD>` with the credentials for the registry with the following caveats:

   -  If using Oracle Container Registry to pull the OUDSM container image, this is the username and password used to login to [Oracle Container Registry](https://container-registry.oracle.com). Before you can use this image you must login to [Oracle Container Registry](https://container-registry.oracle.com), navigate to `Middleware` > `oudsm_cpu` and accept the license agreement.

   - If using your own container registry to store the OUDSM container image, this is the username and password (or token) for your container registry.   

   The output will look similar to the following:
   
   ```bash
   secret/orclcred created
   ```

### Create a persistent volume directory

As referenced in [Prerequisites](../prerequisites) the nodes in the Kubernetes cluster must have access to a persistent volume such as a Network File System (NFS) mount or a shared file system. 

Make sure the persistent volume path has **full** access permissions, and that the folder is empty. In this example `/scratch/shared/` is a shared directory accessible from all nodes.
   
1. On the master node run the following command to create a `user_projects` directory:

   ```bash 
   $ cd <persistent_volume>
   $ mkdir oudsm_user_projects   
   $ chmod 777 oudsm_user_projects
   ```
   
   For example:
   
   ```bash 
   $ cd /scratch/shared
   $ mkdir oudsm_user_projects   
   $ chmod 777 oudsm_user_projects
   ```
   
1. On the master node run the following to ensure it is possible to read and write to the persistent volume:
   
   ```
   $ cd <persistent_volume>/oudsm_user_projects
   $ touch file.txt
   $ ls filemaster.txt
   ```
   
   For example:
   
   ```bash
   $ cd /scratch/shared/oudsm_user_projects
   $ touch filemaster.txt
   $ ls filemaster.txt
   ```
   
   On the first worker node run the following to ensure it is possible to read and write to the persistent volume:
   
   ```bash
   $ cd /scratch/shared/oudsm_user_projects
   $ ls filemaster.txt
   $ touch fileworker1.txt
   $ ls fileworker1.txt
   ```
   
   Repeat the above for any other worker nodes e.g fileworker2.txt etc. Once proven that it's possible to read and write from each node to the persistent volume, delete the files created.



   
### The oudsm Helm chart

The `oudsm` Helm chart allows you to create or deploy Oracle Unified Directory Services Manager instances along with Kubernetes objects in a specified namespace.

The deployment can be initiated by running the following Helm command with reference to the `oudsm` Helm chart, along with configuration parameters according to your environment. 

```
cd $WORKDIR/kubernetes/helm
$ helm install --namespace <namespace> \
<Configuration Parameters> \
<deployment/release name> \
<Helm Chart Path/Name>
```

Configuration Parameters (override values in chart) can be passed on with `--set` arguments on the command line and/or with `-f / --values` arguments when referring to files.

**Note**: The examples in [Create OUDSM instances](#create-oudsm-instances) below provide values which allow the user to override the default values provided by the Helm chart. A full list of configuration parameters and their default values is shown in [Appendix: Configuration parameters](#appendix-configuration-parameters).

For more details about the `helm` command and parameters, please execute `helm --help` and `helm install --help`.


### Create OUDSM instances

You can create OUDSM instances using one of the following methods:

1. [Using a YAML file](#using-a-yaml-file)
1. [Using `--set` argument](#using---set-argument)


#### Using a YAML file

1. Navigate to the `$WORKDIR/kubernetes/helm` directory:

   ```bash
   $ cd $WORKDIR/kubernetes/helm
   ```

1. Create an `oudsm-values-override.yaml` as follows:

   ```yaml
   image:
     repository: <image_location>
     tag: <image_tag>
     pullPolicy: IfNotPresent
   imagePullSecrets:
     - name: orclcred
   oudsm:
     adminUser: weblogic
     adminPass: <password>
   persistence:
     type: filesystem
     filesystem:
       hostPath: 
         path: <persistent_volume>/oudsm_user_projects
   ```

   For example:

   ```yaml
   image:
     repository: container-registry.oracle.com/middleware/oudsm_cpu
     tag: 12.2.1.4-jdk8-ol7-220223.2053
     pullPolicy: IfNotPresent
   imagePullSecrets:
     - name: orclcred
   oudsm:
     adminUser: weblogic
     adminPass: <password>
   persistence:
     type: filesystem
     filesystem:
       hostPath: 
         path: /scratch/shared/oudsm_user_projects
   ```

   The following caveats exist:
   
   * Replace `<password>` with a the relevant passwords.
   * If you are not using Oracle Container Registry or your own container registry for your OUD container image, then you can remove the following:
   
      ```
      imagePullSecrets:
        - name: orclcred
      ```
  
   * If using NFS for your persistent volume the change the `persistence` section as follows:
  
   ```yaml
   persistence:
     type: networkstorage
     networkstorage:
       nfs: 
         path: <persistent_volume>/oudsm_user_projects
         server: <NFS IP address>
   ```


1. Run the following command to deploy OUDSM:

   ```bash
   $ helm install --namespace <namespace> \
   --values oudsm-values-override.yaml \
   <release_name> oudsm
   ```

   ```bash
   $ helm install --namespace oudsmns \
   --values oudsm-values-override.yaml \
   oudsm oudsm
   ```

1. Check the OUDSM deployment as per [Verify the OUDSM deployment](#verify-the-oudsm-deployment)


#### Using `--set` argument

1. Navigate to the `$WORKDIR/kubernetes/helm` directory:

   ```bash
   $ cd $WORKDIR/kubernetes/helm
   ```
   
1. Run the following command to create OUDSM instance:

   ```bash
   $ helm install --namespace oudsmns \
   --set oudsm.adminUser=weblogic,oudsm.adminPass=<password>,persistence.filesystem.hostPath.path=<persistent_volume>/oudsm_user_projects,image.repository=<image_location>,image.tag=<image_tag> \
   --set imagePullSecrets[0].name="orclcred" \
   <release_name> oudsm
   ```

   For example:

   ```bash
   $ helm install --namespace oudsmns \
   --set oudsm.adminUser=weblogic,oudsm.adminPass=<password>,persistence.filesystem.hostPath.path=/scratch/shared/oudsm_user_projects,image.repository=container-registry.oracle.com/middleware/oudsm_cpu,image.tag=12.2.1.4-jdk8-ol7-220223.2053 \
   --set imagePullSecrets[0].name="orclcred" \
   oudsm oudsm
   ```

   The following caveats exist:

   * Replace `<password>` with a the relevant password.
   * If you are not using Oracle Container Registry or your own container registry for your OUDSM container image, then you can remove the following: `--set imagePullSecrets[0].name="orclcred"`
   * If using using NFS for your persistent volume then use `persistence.networkstorage.nfs.path=<persistent_volume>/oudsm_user_projects,persistence.networkstorage.nfs.server:<NFS IP address>`.

1. Check the OUDSM deployment as per [Verify the OUDSM deployment](#verify-the-oudsm-deployment)

### Helm command output

In all the examples above, the following output is shown following a successful execution of the `helm install` command.

   ```bash
   NAME: oudsm
   LAST DEPLOYED: Mon Mar 21 12:21:06 2022
   NAMESPACE: oudsmns
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   ```

### Verify the OUDSM deployment

Run the following command to verify the OUDSM deployment: 

```bash
$ kubectl --namespace <namespace> get pod,service,secret,pv,pvc,ingress -o wide
```

For example:

```bash
$ kubectl --namespace oudsmns get pod,service,secret,pv,pvc,ingress -o wide
```

The output will look similar to the following:

```
NAME          READY   STATUS    RESTARTS   AGE   IP            NODE             NOMINATED NODE   READINESS GATES
pod/oudsm-1   1/1     Running   0          73m   10.244.0.19   <worker-node>   <none>           <none>
	
NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE   SELECTOR
service/oudsm-1     ClusterIP   10.96.108.200   <none>        7001/TCP,7002/TCP   73m   app.kubernetes.io/instance=oudsm,app.kubernetes.io/name=oudsm,oudsm/instance=oudsm-1
service/oudsm-lbr   ClusterIP   10.96.41.201    <none>        7001/TCP,7002/TCP   73m   app.kubernetes.io/instance=oudsm,app.kubernetes.io/name=oudsm
	
NAME                                 TYPE                                  DATA   AGE
secret/default-token-w4jft           kubernetes.io/service-account-token   3      3h15m
secret/orclcred                      kubernetes.io/dockerconfigjson        1      3h13m
secret/oudsm-creds                   opaque                                2      73m
secret/oudsm-token-ksr4g             kubernetes.io/service-account-token   3      73m
secret/sh.helm.release.v1.oudsm.v1   helm.sh/release.v1                    1      73m
	
NAME                            CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                   STORAGECLASS   REASON   AGE   VOLUMEMODE
persistentvolume/oudsm-pv       30Gi       RWX            Retain           Bound    myoudsmns/oudsm-pvc     manual                  73m   Filesystem

NAME                              STATUS   VOLUME     CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE
persistentvolumeclaim/oudsm-pvc   Bound    oudsm-pv   30Gi       RWX            manual         73m   Filesystem

NAME                                     HOSTS                               ADDRESS          PORTS   AGE
ingress.extensions/oudsm-ingress-nginx   oudsm-1,oudsm-2,oudsm + 1 more...   100.102.51.230   80      73m
```

**Note**: It will take several minutes before all the services listed above show. While the oudsm pods have a `STATUS` of `0/1` the pod is started but the OUDSM server associated with it is currently starting. While the pod is starting you can check the startup status in the pod logs, by running the following command:

```bash
$ kubectl logs oudsm-1 -n oudsmns
```

**Note** : If the OUD deployment fails additionally refer to [Troubleshooting](../troubleshooting) for instructions on how describe the failing pod(s).
Once the problem is identified follow [Undeploy an OUDSM deployment](#undeploy-an-oudsm-deployment) to clean down the deployment before deploying again.


#### Kubernetes Objects

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

### Ingress Configuration

With an OUDSM instance now deployed you are now ready to configure an ingress controller to direct traffic to OUDSM as per [Configure an ingress for an OUDSM](../configure-ingress).

### Undeploy an OUDSM deployment

#### Delete the OUDSM deployment

1. Find the deployment release name:

   ```bash
   $ helm --namespace <namespace> list
   ```
        
   For example:
   
   ```bash
   $ helm --namespace oudsmns list
   ```
   
   The output will look similar to the following:
   
   ```
   NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
   oudsm   oudsmns         2               2022-03-21 16:46:34.05531056 +0000 UTC  deployed        oudsm-0.1       12.2.1.4.0
   ```
        
1. Delete the deployment using the following command:

   ```bash
   $ helm uninstall --namespace <namespace> <release>
   ```
        
   For example:

   ```bash
   $ helm uninstall --namespace oudsmns oudsm
   release "oudsm" uninstalled
   ```
   
#### Delete the persistent volume contents

1. Delete the contents of the `oudsm_user_projects` directory in the persistent volume:

   ```bash
   $ cd <persistent_volume>/oudsm_user_projects
   $ rm -rf *
   ```
   
   For example:
   
   ```bash
   $ cd /scratch/shared/oudsm_user_projects
   $ rm -rf *
   ```


### Appendix: Configuration Parameters

The following table lists the configurable parameters of the 'oudsm' chart and their default values.

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
| elk.elkVolume.networkstorage.nfs.path | Path of NFS Share location  | /scratch/shared/oudsm_elk/data |
| elk.elkVolume.networkstorage.nfs.server | IP or hostname of NFS Server  | 0.0.0.0 |
| elk.elkVolume.custom.* | Based on values/data, YAML content would be included in PersistenceVolume Object |  |
| elk.elkVolume.accessMode | Specifies the access mode of the location provided | ReadWriteMany |
| elk.elkVolume.size  | Specifies the size of the storage | 20Gi |
| elk.elkVolume.storageClass | Specifies the storageclass of the persistence volume. | elk |
| elk.elkVolume.annotations | specifies any annotations that will be used| { } |
