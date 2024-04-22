+++
title = "Patch and Upgrade"
weight = 9 
pre = "<b>9. </b>"
description=  "This document provides steps to patch or upgrade an OUD image"
+++

In this section you learn how to upgrade OUD from a previous version. Follow the section relevant to the version you are upgrading from. 

1. [Upgrading to April 24 (24.2.1) from April 23 (23.2.1) or later](#upgrading-to-april-24-2421-from-april-23-2321-or-later)
1. [Upgrading to April 24 (24.2.1) from October 22 (22.4.1) or January 23 (23.1.1)](#upgrading-to-april-24-2421-from-october-22-2241-or-january-23-2311)
1. [Upgrading to April 24 (24.2.1) from July 22 (22.3.1)](#upgrading-to-april-24-2421-from-july-22-2231)
1. [Upgrading to April 24 (24.2.1) from releases prior to July 22 (22.3.1)](#upgrading-to-april-24-2421-from-releases-prior-to-july-22-2231)
1. [Upgrading Elasticsearch and Kibana](#upgrading-elasticsearch-and-kibana)

**Note**: If on July 22 (22.3.1) or later, and have [Kubernetes Horizontal Pod Autoscaler](../manage-oud-containers/hpa) (HPA) enabled, you must disable HPA before performing the steps in the relevant upgrade section. See [Delete the HPA](../manage-oud-containers/hpa#delete-the-hpa).


### Upgrading to April 24 (24.2.1) from April 23 (23.2.1) or later

The instructions below are for upgrading from April 23 ([23.2.1](https://github.com/oracle/fmw-kubernetes/releases)) or later to April 24 ([24.2.1](https://github.com/oracle/fmw-kubernetes/releases)).

**Note**: If you are not using Oracle Container Registry or your own container registry, then you must first load the new container image on all nodes in your Kubernetes cluster.

1. Navigate to the `$WORKDIR/kubernetes/helm` directory:

   ```bash
   $ cd $WORKDIR/kubernetes/helm
   ```

1. Create a `oud-patch-override.yaml` file that contains:

   ```yaml
   image:
     repository: <image_location>
     tag: <image_tag>
    imagePullSecrets:
      - name: orclcred
   ```

   For example:

   ```yaml
   image:
     repository: container-registry.oracle.com/middleware/oud_cpu
     tag: 12.2.1.4-jdk8-ol8-<April'24>
   imagePullSecrets:
     - name: orclcred
   ```
   
   The following caveats exist:
   
   * If you are not using Oracle Container Registry or your own container registry for your OUD container image, then you can remove the following:
   
      ```
      imagePullSecrets:
        - name: orclcred
      ```

1. Run the following command to upgrade the deployment:

   ```bash
   $ helm upgrade --namespace <namespace> \
   --values oud-patch-override.yaml \
   <release_name> oud-ds-rs --reuse-values
   ```
   
   For example:
   
   ```bash
   $ helm upgrade --namespace oudns \
   --values oud-patch-override.yaml \
   oud-ds-rs oud-ds-rs --reuse-values
   ```



### Upgrading to April 24 (24.2.1) from October 22 (22.4.1) or January 23 (23.1.1)

The instructions below are for upgrading from October 22 ([22.4.1](https://github.com/oracle/fmw-kubernetes/releases)) or January 23 ([23.1.1](https://github.com/oracle/fmw-kubernetes/releases)), to April ([24.2.1](https://github.com/oracle/fmw-kubernetes/releases)).

**Note**: If you are not using Oracle Container Registry or your own container registry, then you must first load the new container image on all nodes in your Kubernetes cluster.

#### Scale down OUD

1. Make sure the base pod (`oud-ds-rs-0`) is running and healthy (`READY 1/1`) by running the following command:

   ```
   $ kubectl get pods -n <namespace>
   ```
   
   For example:
   
   ```
   $ kubectl get pods -n oudns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                              READY   STATUS      RESTARTS   AGE
   oud-ds-rs-0                       1/1     Running     0          21h
   oud-ds-rs-1                       1/1     Running     0          20h
   oud-ds-rs-2                       1/1     Running     0          20h
   ```

1. Ensure dsreplication is healthy by running the following command:

   ```
   $ $ kubectl --namespace <namespace> exec -it -c <containername> <podname> -- \
   /u01/oracle/user_projects/<OUD Instance/Pod Name>/OUD/bin/dsreplication status \
   --trustAll --hostname <OUD Instance/Pod Name> --port 1444 --adminUID admin \
   --dataToDisplay compat-view --dataToDisplay rs-connections
   ```
   
   For example:
   
   ```
   $ kubectl --namespace oudns exec -it -c oud-ds-rs oud-ds-rs-0 -- \
   /u01/oracle/user_projects/oud-ds-rs-0/OUD/bin/dsreplication status \
   --trustAll --hostname oud-ds-rs-0 --port 1444 --adminUID admin \
   --dataToDisplay compat-view --dataToDisplay rs-connections
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                              READY   STATUS      RESTARTS   AGE
   
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
    
   etc...
   ```
   
1. Scale down OUD by reducing the replicas to `1`:

   ```
   $ cd $WORKDIR/kubernetes/helm
   $ helm upgrade -n oudns --set replicaCount=1 oud-ds-rs oud-ds-rs --reuse-values
   ```
   
   **Note**: The `$WORKDIR` is the directory for your existing release, not April 24.
   
   The output will be similar to the following:
   
   ```
   Release "oud-ds-rs" has been upgraded. Happy Helming!
   NAME: oud-ds-rs
   LAST DEPLOYED: <DATE>
   NAMESPACE: oudns
   STATUS: deployed
   REVISION: 2
   NOTES:
   
   etc..
   ```
   
   Make sure the replica pods are shutdown before proceeding:
   
   ```
   $ kubectl get pods -n oudns
   
   
   NAME                              READY   STATUS      RESTARTS   AGE
   oud-ds-rs-0                       1/1     Running     0          21h
   ```
   
   **Note**: It will take several minutes before the replica pods disappear.
   
#### Backup OUD data

1. Take a backup of the OUD data for every pod in the NFS shared volume:

   ```
   $ kubectl exec -it -n oudns oud-ds-rs-0 -- bash
   [oracle@oud-ds-rs-0 oracle]$ cd user_projects
   [oracle@oud-ds-rs-0 user_projects]$ mkdir OUD_backup_<DATE>
   [oracle@oud-ds-rs-0 user_projects]$ cp -r oud-ds-rs-* OUD_backup_<DATE>/
   ```

1. Make sure the backup created successfully:

   ```
   [oracle@oud-ds-rs-0 user_projects]$ ls -l OUD_backup_<date>
   total 2
   drwxr-x---. 5 oracle root 3 <DATE> oud-ds-rs-0
   drwxr-x---. 5 oracle root 3 <DATE> oud-ds-rs-1
   drwxr-x---. 5 oracle root 3 <DATE> oud-ds-rs-2
   ```

1. Remove the non-zero pod directories `oud-ds-rs-1` and `oud-ds-rs-2`:

   ```
   [oracle@oud-ds-rs-0 user_projects]$ rm -rf oud-ds-rs-1 oud-ds-rs-2
   ```
   
1. Exit the `oud-ds-rs-0` bash session:

   ```
   [oracle@oud-ds-rs-0 user_projects]$ exit
   ```
   
   

#### Setup the April 24 code repository to deploy OUD

1. Create a working directory on the persistent volume to setup the latest source code:

   ```bash
   $ mkdir <persistent_volume>/<workdir>
   ```

   For example:

   ```bash
   $ mkdir /scratch/shared/OUDK8SJan24
   ```

1. Download the latest OUD deployment scripts from the OUD repository:

   ```bash
   $ cd <persistent_volume>/<workdir>
   $ git clone https://github.com/oracle/fmw-kubernetes.git
   ```
   
   For example:
   
   ```bash
   $ mkdir /scratch/shared/OUDK8SJan24
   $ git clone https://github.com/oracle/fmw-kubernetes.git
   ```

1. Set the `$WORKDIR` environment variable as follows:

   ```bash
   $ export WORKDIR=<workdir>/fmw-kubernetes/OracleUnifiedDirectory
   ```
   
   For example:

   ```bash
   $ export WORKDIR=/scratch/shared/OUDK8SJan24/fmw-kubernetes/OracleUnifiedDirectory
   ```
  
#### Update the OUD container image   

 
1. Navigate to the `$WORKDIR/kubernetes/helm` directory:

   ```bash
   $ cd $WORKDIR/kubernetes/helm
   ```

1. Create a `oud-patch-override.yaml` file that contains:

   ```yaml
   image:
     repository: <image_location>
     tag:  <image_tag>
     pullPolicy: IfNotPresent
   imagePullSecrets:
     - name: orclcred
   oudConfig:
     cleanupbeforeStart: false
     disablereplicationbeforeStop: false
   replicaCount: 3
   ```

   For example:

   ```yaml
   image:
     repository: container-registry.oracle.com/middleware/oud_cpu
     tag:  12.2.1.4-jdk8-ol8-<April'24>
     pullPolicy: IfNotPresent
   imagePullSecrets:
     - name: orclcred
   oudConfig:
     cleanupbeforeStart: false
     disablereplicationbeforeStop: false
   replicaCount: 3
   ```

   The following caveats exist:
   
   * If you are not using Oracle Container Registry or your own container registry for your OUD container image, then you can remove the following:
   
      ```
      imagePullSecrets:
        - name: orclcred
      ```

1. Run the following command to upgrade the deployment:

   ```bash
   $ cd $WORKDIR/kubernetes/helm
   $ helm upgrade --namespace <namespace> \
   --values oud-patch-override.yaml \
   <release_name> oud-ds-rs --reuse-values
   ```
   
   For example:
   
   ```bash
   $ cd $WORKDIR/kubernetes/helm
   $ helm upgrade --namespace oudns \
   --values oud-patch-override.yaml \
   oud-ds-rs oud-ds-rs --reuse-values
   ```
   
   The output should look similar to the following:
   
   ```
   Release "oud-ds-rs" has been upgraded. Happy Helming!
   NAME: oud-ds-rs
   LAST DEPLOYED: <DATE>
   NAMESPACE: oudns
   STATUS: deployed
   REVISION: 3
   NOTES:
   etc..
   ```

#### Verify the pods

1. After updating with the new image the pods will restart. Verify the pods are running:

   ```bash
   $ kubectl --namespace <namespace> get pods
   ```

   For example:

   ```bash
   $ kubectl --namespace oudns get pods
   ```

   The output will look similar to the following:
   
   ```
   NAME                              READY   STATUS      RESTARTS   AGE
   oud-ds-rs-0                       1/1     Running     0          11m
   oud-ds-rs-1                       1/1     Running     0          28m
   oud-ds-rs-2                       1/1     Running     0          22m
   ...
   ```
   
   **Note**: It will take several minutes before the pods `oud-ds-rs-1` and `oud-ds-rs-2` start, and `oud-ds-rs-0` restarts. While the OUD pods have a `STATUS` of `0/1` the pods are started but the OUD server associated with it is currently starting.   
   
1. Verify the pods are using the new image by running the following command:

   ```bash
   $ kubectl describe pod <pod> -n <namespace>
   ```

   For example:

   ```bash
   $ kubectl describe pod oud-ds-rs-0 -n oudns | grep Image
   ```

   The output will look similar to the following:

   ```bash
   ...
   Image:          container-registry.oracle.com/middleware/oud_cpu:12.2.1.4-jdk8-ol8-<April'24>
   Image ID:       container-registry.oracle.com/middleware/oud_cpu@sha256:<sha256>
   ```

1. Ensure dsreplication is healthy by running the following command:

   ```
   $ $ kubectl --namespace <namespace> exec -it -c <containername> <podname> -- \
   /u01/oracle/user_projects/<OUD Instance/Pod Name>/OUD/bin/dsreplication status \
   --trustAll --hostname <OUD Instance/Pod Name> --port 1444 --adminUID admin \
   --dataToDisplay compat-view --dataToDisplay rs-connections
   ```
   
   For example:
   
   ```
   $ kubectl --namespace oudns exec -it -c oud-ds-rs oud-ds-rs-0 -- \
   /u01/oracle/user_projects/oud-ds-rs-0/OUD/bin/dsreplication status \
   --trustAll --hostname oud-ds-rs-0 --port 1444 --adminUID admin \
   --dataToDisplay compat-view --dataToDisplay rs-connections
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                              READY   STATUS      RESTARTS   AGE
   
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
    
   etc...
   ```

1. Once the validation steps are performed and you are confident OUD is working correctly, you can optionally delete the OUD backup data in the NFS shared volume:

   ```
   $ kubectl exec -it -n oudns oud-ds-rs-0 -- bash
   [oracle@oud-ds-rs-0 oracle]$ cd user_projects/OUD_backup_<DATE>/
   [oracle@oud-ds-rs-0 OUD_backup_<DATE>]$ rm -rf oud-ds-rs-0  oud-ds-rs-1  oud-ds-rs-2
   ```
   

### Upgrading to April 24 (24.2.1) from July 22 (22.3.1)

The instructions below are for upgrading from July 22 ([22.3.1](https://github.com/oracle/fmw-kubernetes/releases)) to April 24 ([24.2.1](https://github.com/oracle/fmw-kubernetes/releases)).

1. Follow [Upgrading to April 24 (24.2.1) from October 22 (22.4.1) or January 23 (23.1.1)](#upgrading-to-april-24-2421-from-october-22-2241-or-january-23-2311) to upgrade the image.
1. Once the image is upgraded, follow [Upgrading Elasticsearch and Kibana](#upgrading-elasticsearch-and-kibana).


### Upgrading to April 24 (24.2.1) from releases prior to July 22 (22.3.1)

In releases prior to July 22 ([22.3.1](https://github.com/oracle/fmw-kubernetes/releases)) OUD used pod based deployment. From July 22 ([22.3.1](https://github.com/oracle/fmw-kubernetes/releases)) onwards OUD is deployed using [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/).

If you are upgrading from a release prior to July 22 ([22.3.1](https://github.com/oracle/fmw-kubernetes/releases)) you must follow the steps below to deploy a new OUD instance to use your existing OUD data in `<persistent_volume>/oud_user_projects`.

**Note**: The steps below will incur a small outage.

#### Delete the existing deployment

1. Find the deployment release name as follows:

   ```bash
   $ helm --namespace <namespace> list
   ```
        
   For example:
        
   ```bash
   $ helm --namespace oudns list
   ```
   
   The output will look similar to the following:
   
   ```
   NAME            NAMESPACE       REVISION        UPDATED                                   STATUS          CHART           APP VERSION
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
   

#### Setup the code repository to deploy OUD

1. Create a working directory on the persistent volume to setup the latest source code:

   ```bash
   $ mkdir <persistent_volume>/<workdir>
   ```

   For example:

   ```bash
   $ mkdir /scratch/shared/OUDK8SJan24
   ```
   

1. Download the latest OUD deployment scripts from the OUD repository:

   ```bash
   $ cd <persistent_volume>/<workdir>
   $ git clone https://github.com/oracle/fmw-kubernetes.git
   ```
   
   For example:
   
   ```bash
   $ cd /scratch/shared/OUDK8SJan24
   $ git clone https://github.com/oracle/fmw-kubernetes.git
   ```

1. Set the `$WORKDIR` environment variable as follows:

   ```bash
   $ export WORKDIR=<workdir>/fmw-kubernetes/OracleUnifiedDirectory
   ```
   
   For example:

   ```bash
   $ export WORKDIR=/scratch/shared/OUDK8SJan24/fmw-kubernetes/OracleUnifiedDirectory
   ```


#### Create a new instance against your existing persistent volume


1. Navigate to the `$WORKDIR/kubernetes/helm` directory

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
 
     imagePullSecrets:
       - name: dockercred
   ```
   
   For example:
   
   ```yaml
   image:
     repository: container-registry.oracle.com/middleware/oud_cpu
     tag: 12.2.1.4-jdk8-ol8-<April'24>
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
       tag: 1.24.5
       pullPolicy: IfNotPresent
 
     imagePullSecrets:
       - name: dockercred
   ```   
   
  
   The following caveats exist:
   
   * The `<persistent_volume>/oud_user_projects` must point to the directory used in your previous deployment otherwise your existing OUD data will not be used. Make sure you take a backup of the `<persistent_volume>/oud_user_projects` directory before proceeding further.
   * Replace `<password>` with the password used in your previous deployment.
   * The `<version>` in *kubectlImage* `tag:` should be set to the same version as your Kubernetes version (`kubectl version`). For example if your Kubernetes version is `1.24.5` set to `1.24.5`.
   * If you are not using Oracle Container Registry or your own container registry for your OUD container image, then you can remove the following:
   
      ```
      imagePullSecrets:
        - name: orclcred
      ```
  
   * If using NFS for your persistent volume then change the `persistence` section as follows:
  
      ```yaml
      persistence:
        type: networkstorage
        networkstorage:
          nfs: 
            path: <persistent_volume>/oud_user_projects
            server: <NFS IP address>
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

1. Check the OUD deployment as per [Verify the OUD deployment](../create-oud-instances/#verify-the-oud-deployment) and [Verify the OUD replication](../create-oud-instances#verify-the-oud-replication).


1. Upgrade Elasticsearch and Kibana by following [Upgrading Elasticsearch and Kibana](#upgrading-elasticsearch-and-kibana).


### Upgrading Elasticsearch and Kibana

This section shows how to upgrade Elasticsearch and Kibana. From October 22 (22.4.1) onwards, OUD logs should be stored on a centralized Elasticsearch and Kibana stack.

***Note***: This section should only be followed if upgrading from July 22 (22.3.1) or earlier to April 24 (24.2.1). If you are upgrading from October 22 or later to April 24 do not follow this section.


#### Undeploy Elasticsearch and Kibana

From October 22 (22.4.1) onwards, OUD logs should be stored on a centralized Elasticsearch and Kibana (ELK) stack.

Deployments prior to October 22 (22.4.1) used local deployments of Elasticsearch and Kibana. 

If you are upgrading from July 22 (22.3.1) or earlier, to April 24 (24.2.1), you must first undeploy Elasticsearch and Kibana using the steps below:

1. Navigate to the `$WORKDIR/kubernetes/helm` directory and create a `logging-override-values-uninstall.yaml` with the following:

   ```
   elk:
     enabled: false
   ```

1. Run the following command to remove the existing ELK deployment:

   ```
   $ helm upgrade --namespace <domain_namespace> --values <valuesfile.yaml> <releasename> oud-ds-rs --reuse-values
   ```
   
   For example:

   ```
   $ helm upgrade --namespace oudns --values logging-override-values-uninstall.yaml oud-ds-rs oud-ds-rs --reuse-values
   ```
   
   
#### Deploy ElasticSearch and Kibana in centralized stack

1. Follow [Install Elasticsearch stack and Kibana](../manage-oud-containers/logging-and-visualization/#install-elasticsearch-stack-and-kibana) to deploy ElasticSearch and Kibana in a centralized stack.