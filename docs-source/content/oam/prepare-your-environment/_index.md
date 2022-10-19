---
title: "Prepare your environment"
weight: 3
pre : "<b>3. </b>"
description: "Sample for creating an OAM domain home on an existing PV or
PVC, and the domain resource YAML file for deploying the generated OAM domain."
---
To prepare for Oracle Access Management deployment in a Kubernetes environment, complete the following steps:

1. [Check the Kubernetes cluster is ready](#check-the-kubernetes-cluster-is-ready)
1. [Obtain the OAM container image](#obtain-the-oam-container-image)
1. [Set up the code repository to deploy OAM domains](#set-up-the-code-repository-to-deploy-oam-domains)
1. [Install the WebLogic Kubernetes Operator](#install-the-weblogic-kubernetes-operator)
1. [Create a namespace for Oracle Access Management](#create-a-namespace-for-oracle-access-management)
1. [Create a Kubernetes secret for the container registry](#create-a-kubernetes-secret-for-the-container-registry)
1. [RCU schema creation](#rcu-schema-creation)
1. [Preparing the environment for domain creation](#preparing-the-environment-for-domain-creation)
    
    a. [Creating Kubernetes secrets for the domain and RCU](#creating-kubernetes-secrets-for-the-domain-and-rcu)
    
	b. [Create a Kubernetes persistent volume and persistent volume claim](#create-a-kubernetes-persistent-volume-and-persistent-volume-claim)



### Check the Kubernetes cluster is ready

As per the [Prerequisites](../prerequisites/#system-requirements-for-oam-domains) a Kubernetes cluster should have already been configured.

Check that all the nodes in the Kubernetes cluster are running.

1. Run the following command on the master node to check the cluster and worker nodes are running:
    
	```bash
    $ kubectl get nodes,pods -n kube-system
    ```
	
    The output will look similar to the following:

	```
    NAME                  STATUS   ROLES                  AGE   VERSION
    node/worker-node1     Ready    <none>                 17h   v1.20.10
    node/worker-node2     Ready    <none>                 17h   v1.20.10
    node/master-node      Ready    control-plane,master   23h   v1.20.10

    NAME                                     READY   STATUS    RESTARTS   AGE
    pod/coredns-66bff467f8-fnhbq             1/1     Running   0          23h
    pod/coredns-66bff467f8-xtc8k             1/1     Running   0          23h
    pod/etcd-master                          1/1     Running   0          21h
    pod/kube-apiserver-master-node           1/1     Running   0          21h
    pod/kube-controller-manager-master-node  1/1     Running   0          21h
    pod/kube-flannel-ds-amd64-lxsfw          1/1     Running   0          17h
    pod/kube-flannel-ds-amd64-pqrqr          1/1     Running   0          17h
    pod/kube-flannel-ds-amd64-wj5nh          1/1     Running   0          17h
    pod/kube-proxy-2kxv2                     1/1     Running   0          17h
    pod/kube-proxy-82vvj                     1/1     Running   0          17h
    pod/kube-proxy-nrgw9                     1/1     Running   0          23h
    pod/kube-scheduler-master                1/1     Running   0          21
    ```
	
### Obtain the OAM container image

The OAM Kubernetes deployment requires access to an OAM container image. The image can be obtained in the following ways:

- Prebuilt OAM container image
- Build your own OAM container image using WebLogic Image Tool

#### Prebuilt OAM container image


The prebuilt OAM October 2022 container image can be downloaded from [Oracle Container Registry](https://container-registry.oracle.com). This image is prebuilt by Oracle and includes Oracle Access Management 12.2.1.4.0, the October Patch Set Update (PSU) and other fixes released with the Critical Patch Update (CPU) program.

**Note**: Before using this image you must login to [Oracle Container Registry](https://container-registry.oracle.com), navigate to `Middleware` > `oam_cpu` and accept the license agreement.

You can use this image in the following ways:

- Pull the container image from the Oracle Container Registry automatically during the OAM Kubernetes deployment.
- Manually pull the container image from the Oracle Container Registry and then upload it to your own container registry.
- Manually pull the container image from the Oracle Container Registry and manually stage it on the master node and each worker node. 

#### Build your own OAM container image using WebLogic Image Tool


You can build your own OAM container image using the WebLogic Image Tool. This is recommended if you need to apply one off patches to a [Prebuilt OAM container image](#prebuilt-oam-container-image). For more information about building your own container image with WebLogic Image Tool, see [Create or update image](../create-or-update-image/).

You can use an image built with WebLogic Image Tool in the following ways:

- Manually upload them to your own container registry. 
- Manually stage them on the master node and each worker node. 


**Note**: This documentation does not tell you how to pull or push the above images into a private container registry, or stage them on the master and worker nodes. Details of this can be found in the [Enterprise Deployment Guide](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/procuring-software-enterprise-deployment.html).



### Set up the code repository to deploy OAM domains

OAM domain deployment on Kubernetes leverages the WebLogic Kubernetes Operator infrastructure. For deploying the OAM domains, you need to set up the deployment scripts on the **master** node as below:

1. Create a working directory to setup the source code.
   ```bash
   $ mkdir <workdir>
   ```
   
   For example:
   ```bash
   $ mkdir /scratch/OAMK8S
   ```
   
1. Download the latest OAM deployment scripts from the OAM repository.

   ```bash
   $ cd <workdir>
   $ git clone https://github.com/oracle/fmw-kubernetes.git
   ```
   
   For example:
   
   ```bash
   $ cd /scratch/OAMK8S
   $ git clone https://github.com/oracle/fmw-kubernetes.git
   ```

1. Set the `$WORKDIR` environment variable as follows:

   ```bash
   $ export WORKDIR=<workdir>/fmw-kubernetes/OracleAccessManagement
   ```

   For example:
   
   ```bash
   $ export WORKDIR=/scratch/OAMK8S/fmw-kubernetes/OracleAccessManagement
   ```
   
	
1. Run the following command and see if the WebLogic custom resource definition name already exists:

   ```bash
   $ kubectl get crd
   ```
   
   In the output you should see:
	
   ```
   No resources found
   ```
   
   If you see the following:
	
   ```
   NAME                    AGE
   domains.weblogic.oracle 5d
   ```
   then run the following command to delete the existing crd:
	
   ```bash
   $ kubectl delete crd domains.weblogic.oracle
   customresourcedefinition.apiextensions.k8s.io "domains.weblogic.oracle" deleted
   ```
   
   
### Install the WebLogic Kubernetes Operator

1. On the **master** node run the following command to create a namespace for the operator:

   ```bash
   $ kubectl create namespace <sample-kubernetes-operator-ns>
   ```
  
   For example:
  
   ```bash
   $ kubectl create namespace opns
   ```
  
   The output will look similar to the following:
  
   ```
   namespace/opns created
   ```

1. Create a service account for the operator in the operator's namespace by running the following command:
  
   ```bash
   $ kubectl create serviceaccount -n <sample-kubernetes-operator-ns> <sample-kubernetes-operator-sa>
   ```
   
   For example:
   
   ```bash
   $ kubectl create serviceaccount -n opns op-sa
   ```
   
   The output will look similar to the following:
   
   ```
   serviceaccount/op-sa created
   ```

1. Run the following helm command to install and start the operator:   
  
   ```bash
   $ cd $WORKDIR
   $ helm install weblogic-kubernetes-operator kubernetes/charts/weblogic-operator \
   --namespace <sample-kubernetes-operator-ns> \
   --set image=ghcr.io/oracle/weblogic-kubernetes-operator:3.4.2 \
   --set serviceAccount=<sample-kubernetes-operator-sa> \
   --set “enableClusterRoleBinding=true” \
   --set "domainNamespaceSelectionStrategy=LabelSelector" \
   --set "domainNamespaceLabelSelector=weblogic-operator\=enabled" \
   --set "javaLoggingLevel=FINE" --wait
   ```
  
   For example:
  
   ```bash
   $ cd $WORKDIR
   $ helm install weblogic-kubernetes-operator kubernetes/charts/weblogic-operator \
   --namespace opns \
   --set image=ghcr.io/oracle/weblogic-kubernetes-operator:3.4.2 \
   --set serviceAccount=op-sa \
   --set "enableClusterRoleBinding=true" \
   --set "domainNamespaceSelectionStrategy=LabelSelector" \
   --set "domainNamespaceLabelSelector=weblogic-operator\=enabled" \
   --set "javaLoggingLevel=FINE" --wait
   ```


   The output will look similar to the following:
   
   ```
   NAME: weblogic-kubernetes-operator
   LAST DEPLOYED: <DATE>
   NAMESPACE: opns
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   ```
   
1. Verify that the operator's pod and services are running by executing the following command:

   ```bash
   $ kubectl get all -n <sample-kubernetes-operator-ns>
   ```

   For example:

   ```bash
   $ kubectl get all -n opns
   ```
	
   The output will look similar to the following:
	
   ```
   NAME                                     READY   STATUS    RESTARTS   AGE
   pod/weblogic-operator-676d5cc6f4-wct7b   1/1     Running   0          40s

   NAME                                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
   service/internal-weblogic-operator-svc   ClusterIP   10.101.1.198   <none>        8082/TCP   40s

   NAME                                READY   UP-TO-DATE   AVAILABLE   AGE
   deployment.apps/weblogic-operator   1/1     1            1           40s

   NAME                                           DESIRED   CURRENT   READY   AGE
   replicaset.apps/weblogic-operator-676d5cc6f4   1         1         1       40s
   ```

1. Verify the operator pod's log:
	
   ```bash
   $ kubectl logs -n <sample-kubernetes-operator-ns> -c weblogic-operator deployments/weblogic-operator
   ```
	
   For example:
	
   ```bash
   $ kubectl logs -n opns -c weblogic-operator deployments/weblogic-operator
   ```
	
   The output will look similar to the following:
	
   ```
   ...
   {"timestamp":"<DATE>","thread":26,"fiber":"","namespace":"","domainUID":"","level":"CONFIG","class":"oracle.kubernetes.operator.TuningParametersImpl","method":"update","timeInMillis":1664440408119,"message":"Reloading tuning parameters from Operator's config map","exception":"","code":"","headers":{},"body":""}
   {"timestamp":"<DATE>","thread":19,"fiber":"","namespace":"","domainUID":"","level":"CONFIG","class":"oracle.kubernetes.operator.TuningParametersImpl","method":"update","timeInMillis":1664440418120,"message":"Reloading tuning parameters from Operator's config map","exception":"","code":"","headers":{},"body":""}
   {"timestamp":"<DATE>","thread":29,"fiber":"","namespace":"","domainUID":"","level":"CONFIG","class":"oracle.kubernetes.operator.TuningParametersImpl","method":"update","timeInMillis":1664440428123,"message":"Reloading tuning parameters from Operator's config map","exception":"","code":"","headers":{},"body":""}
   {"timestamp":"<DATE>","thread":29,"fiber":"","namespace":"","domainUID":"","level":"CONFIG","class":"oracle.kubernetes.operator.TuningParametersImpl","method":"update","timeInMillis":1664440438124,"message":"Reloading tuning parameters from Operator's config map","exception":"","code":"","headers":{},"body":""
   ```

### Create a namespace for Oracle Access Management

1. Run the following command to create a namespace for the domain:
	
   ```bash
   $ kubectl create namespace <domain_namespace>
   ```
	
   For example:
	
   ```bash
   $ kubectl create namespace oamns
   ```
	
   The output will look similar to the following:
	
   ```
   namespace/oamns created
   ```

1. Run the following command to tag the namespace so the WebLogic Kubernetes Operator can manage it:

   ```bash
   $ kubectl label namespaces <domain_namespace> weblogic-operator=enabled
   ```
   
   For example:
   
   ```bash
   $ kubectl label namespaces oamns weblogic-operator=enabled
   ```
   
   The output will look similar to the following:
	
   ```
   namespace/oamns labeled
   ```

1. Run the following command to check the label was created:

   ```bash
   $ kubectl describe namespace <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl describe namespace oamns
   ```
   
   
   The output will look similar to the following:
	
   ```
   Name:         oamns
   Labels:       kubernetes.io/metadata.name=oamns
                 weblogic-operator=enabled
   Annotations:  <none>
   Status:       Active

   No resource quota.

   No LimitRange resource.
   ``` 

### Create a Kubernetes secret for the container registry

In this section you create a secret that stores the credentials for the container registry where the OAM image is stored. 

If you are not using a container registry and have loaded the images on each of the master and worker nodes, you still need to create the registry secret. However, the user name and password need not contain meaningful data.

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
   --namespace=oamns
   ```
   
   
   Replace `<USER_NAME>` and `<PASSWORD>` with the credentials for the registry with the following caveats:

   -  If using Oracle Container Registry to pull the OAM container image, this is the username and password used to login to [Oracle Container Registry](https://container-registry.oracle.com). Before you can use this image you must login to [Oracle Container Registry](https://container-registry.oracle.com), navigate to `Middleware` > `oam_cpu` and accept the license agreement.

   - If using your own container registry to store the OAM container image, this is the username and password (or token) for your container registry.   

   The output will look similar to the following:
   
   ```bash
   secret/orclcred created
   ```

### RCU schema creation
	
In this section you create the RCU schemas in the Oracle Database.
	
Before following the steps in this section, make sure that the database and listener are up and running and you can connect to the database via SQL*Plus or other client tool.


1. If using Oracle Container Registry or your own container registry for your OAM container image, run the following command to create a helper pod to run RCU:

   ```bash
   $ kubectl run --image=<image_name-from-registry>:<tag> --image-pull-policy="IfNotPresent" --overrides='{"apiVersion": "v1", "spec":{"imagePullSecrets": [{"name": "orclcred"}]}}' helper -n <domain_namespace> -- sleep infinity
   ```
	
   For example:
	
   ```bash
   $ kubectl run --image=container-registry.oracle.com/middleware/oam_cpu:12.2.1.4-jdk8-ol7-<October`22> --image-pull-policy="IfNotPresent" --overrides='{"apiVersion": "v1","spec":{"imagePullSecrets": [{"name": "orclcred"}]}}' helper -n oamns -- sleep infinity
   ```
   
   If you are not using a container registry and have loaded the image on each of the master and worker nodes, run the following command:
   
   ```bash
   $ kubectl run helper --image <image>:<tag> -n oamns -- sleep infinity
   ```
   
   For example:
   
   ```bash
   $ kubectl run helper --image oracle/oam:12.2.1.4-jdk8-ol7-<October`22> -n oamns -- sleep infinity
   ```
   
   The output will look similar to the following:
	
   ```
   pod/helper created
   ```

1. Run the following command to check the pod is running:

   ```bash
   $ kubectl get pods -n <domain_namespace>
   ```
	
   For example:
	
   ```bash
   $ kubectl get pods -n oamns
   ```
	
   The output will look similar to the following:
	
   ```
   NAME     READY   STATUS    RESTARTS   AGE
   helper   1/1     Running   0          3m
   ```
   
   **Note**: If you are pulling the image from a container registry it may take several minutes before the pod has a `STATUS` of `1\1`. While the pod is starting you can check the status of the pod, by running the following command:
   
   ```bash
   $ kubectl describe pod helper -n oamns
   ```
	
1. Run the following command to start a bash shell in the helper pod:

   ```bash
   $ kubectl exec -it helper -n <domain_namespace> -- /bin/bash
   ```
	
   For example:
	
   ```bash
   $ kubectl exec -it helper -n oamns -- /bin/bash
   ```
	
   This will take you into a bash shell in the running helper pod:
	
   ```bash
   [oracle@helper ~]$
   ```
	
1. In the helper bash shell run the following commands to set the environment:

   ```bash
   [oracle@helper ~]$ export CONNECTION_STRING=<db_host.domain>:<db_port>/<service_name>
   [oracle@helper ~]$ export RCUPREFIX=<rcu_schema_prefix>
   [oracle@helper ~]$ echo -e <db_pwd>"\n"<rcu_schema_pwd> > /tmp/pwd.txt
   [oracle@helper ~]$ cat /tmp/pwd.txt
   ```
   
   where: 
	
   `<db_host.domain>:<db_port>/<service_name>`	is your database connect string
	
   `<rcu_schema_prefix>` is the RCU schema prefix you want to set
	
   `<db_pwd>` is the SYS password for the database
	
   `<rcu_schema_pwd>` is the password you want to set for the `<rcu_schema_prefix>`
	
   For example:
	
   ```bash
   [oracle@helper ~]$ export CONNECTION_STRING=mydatabasehost.example.com:1521/orcl.example.com
   [oracle@helper ~]$ export RCUPREFIX=OAMK8S
   [oracle@helper ~]$ echo -e <password>"\n"<password> > /tmp/pwd.txt
   [oracle@helper ~]$ cat /tmp/pwd.txt
   <password>
   <password>
   ```

1. In the helper bash shell run the following command to create the RCU schemas in the database:

   ```bash
   $ [oracle@helper ~]$ /u01/oracle/oracle_common/bin/rcu -silent -createRepository -databaseType ORACLE -connectString \
   $CONNECTION_STRING -dbUser sys -dbRole sysdba -useSamePasswordForAllSchemaUsers true \
   -selectDependentsForComponents true -schemaPrefix $RCUPREFIX -component MDS -component IAU \
   -component IAU_APPEND -component IAU_VIEWER -component OPSS -component WLS -component STB -component OAM -f < /tmp/pwd.txt
   ```
	
	The output will look similar to the following:
	
   ```
   RCU Logfile: /tmp/RCU<DATE>/logs/rcu.log
   Processing command line ....
   Repository Creation Utility - Checking Prerequisites
   Checking Global Prerequisites
   Repository Creation Utility - Checking Prerequisites
   Checking Component Prerequisites
   Repository Creation Utility - Creating Tablespaces
   Validating and Creating Tablespaces
   Create tablespaces in the repository database
   Repository Creation Utility - Create
   Repository Create in progress.
   Executing pre create operations
   Percent Complete: 18
   Percent Complete: 18
   Percent Complete: 19
   Percent Complete: 20
   Percent Complete: 21
   Percent Complete: 21
   Percent Complete: 22
   Percent Complete: 22
   Creating Common Infrastructure Services(STB)
   Percent Complete: 30
   Percent Complete: 30
   Percent Complete: 39
   Percent Complete: 39
   Percent Complete: 39
   Creating Audit Services Append(IAU_APPEND)
   Percent Complete: 46
   Percent Complete: 46
   Percent Complete: 55
   Percent Complete: 55
   Percent Complete: 55
   Creating Audit Services Viewer(IAU_VIEWER)
   Percent Complete: 62
   Percent Complete: 62
   Percent Complete: 63
   Percent Complete: 63
   Percent Complete: 64
   Percent Complete: 64
   Creating Metadata Services(MDS)
   Percent Complete: 73
   Percent Complete: 73
   Percent Complete: 73
   Percent Complete: 74
   Percent Complete: 74
   Percent Complete: 75
   Percent Complete: 75
   Percent Complete: 75
   Creating Weblogic Services(WLS)
   Percent Complete: 80
   Percent Complete: 80
   Percent Complete: 83
   Percent Complete: 83
   Percent Complete: 91
   Percent Complete: 98
   Percent Complete: 98
   Creating Audit Services(IAU)
   Percent Complete: 100
   Creating Oracle Platform Security Services(OPSS)
   Creating Oracle Access Manager(OAM)
   Executing post create operations
   Repository Creation Utility: Create - Completion Summary
   Database details:
   -----------------------------
   Host Name : mydatabasehost.example.com
   Port : 1521
   Service Name : ORCL.EXAMPLE.COM
   Connected As : sys
   Prefix for (prefixable) Schema Owners : OAMK8S
   RCU Logfile                                  : /tmp/RCU<DATE>/logs/rcu.log

   Component schemas created:
   -----------------------------
   Component                                    Status         Logfile

   Common Infrastructure Services               Success        /tmp/RCU<DATE>/logs/stb.log
   Oracle Platform Security Services            Success        /tmp/RCU<DATE>/logs/opss.log
   Oracle Access Manager                        Success        /tmp/RCU<DATE>/logs/oam.log
   Audit Services                               Success        /tmp/RCU<DATE>/logs/iau.log
   Audit Services Append                        Success        /tmp/RCU<DATE>/logs/iau_append.log
   Audit Services Viewer                        Success        /tmp/RCU<DATE>/logs/iau_viewer.log
   Metadata Services                            Success        /tmp/RCU<DATE>/logs/mds.log
   WebLogic Services                            Success        /tmp/RCU<DATE>/logs/wls.log

   Repository Creation Utility - Create : Operation Completed
   [oracle@helper ~]$
   ```
	
1. 	Exit the helper bash shell by issuing the command `exit`.
	

	
### Preparing the environment for domain creation

In this section you prepare the environment for the OAM domain creation. This involves the following steps:

   a. [Creating Kubernetes secrets for the domain and RCU](#creating-kubernetes-secrets-for-the-domain-and-rcu)
    
   b. [Create a Kubernetes persistent volume and persistent volume claim](#create-a-kubernetes-persistent-volume-and-persistent-volume-claim)

#### Creating Kubernetes secrets for the domain and RCU


1. Create a Kubernetes secret for the domain using the create-weblogic-credentials script in the same Kubernetes namespace as the domain:


   ```bash
   $ cd $WORKDIR/kubernetes/create-weblogic-domain-credentials
   $ ./create-weblogic-credentials.sh -u weblogic -p <pwd> -n <domain_namespace> -d <domain_uid> -s <kubernetes_domain_secret>
   ```
   
   where: 
	
   `-u weblogic` is the WebLogic username
	
   `-p <pwd>` is the password for the weblogic user
	
   `-n <domain_namespace>` is the domain namespace
	
   `-d <domain_uid>` is the domain UID to be created. The default is domain1 if not specified
	
   `-s <kubernetes_domain_secret>` is the name you want to create for the secret for this namespace. The default is to use the domainUID if not specified
	
   For example:
	
   ```bash
   $ cd $WORKDIR/kubernetes/create-weblogic-domain-credentials
   $ ./create-weblogic-credentials.sh -u weblogic -p <password> -n oamns -d accessdomain -s accessdomain-credentials
   ```

   The output will look similar to the following:
	
   ```
   secret/accessdomain-credentials created
   secret/accessdomain-credentials labeled
   The secret accessdomain-credentials has been successfully created in the oamns namespace.
   ```

1. Verify the secret is created using the following command:

   ```bash
   $ kubectl get secret <kubernetes_domain_secret> -o yaml -n <domain_namespace>
   ```
	
   For example:
	
   ```bash
   $ kubectl get secret accessdomain-credentials -o yaml -n oamns
   ```
	
   The output will look similar to the following:
	
   ```
   apiVersion: v1
   data:
     password: V2VsY29tZTE=
     username: d2VibG9naWM=
   kind: Secret
   metadata:
     creationTimestamp: "<DATE>"
     labels:
       weblogic.domainName: accessdomain
       weblogic.domainUID: accessdomain
     name: accessdomain-credentials
     namespace: oamns
     resourceVersion: "29428101"
     uid: 6dac0561-d157-4144-9ed7-c475a080eb3a
   type: Opaque
   ```

1. Create a Kubernetes secret for RCU using the create-weblogic-credentials script in the same Kubernetes namespace as the domain:

   ```bash
   $ cd $WORKDIR/kubernetes/create-rcu-credentials
   $ ./create-rcu-credentials.sh -u <rcu_prefix> -p <rcu_schema_pwd> -a sys -q <sys_db_pwd> -d <domain_uid> -n <domain_namespace> -s <kubernetes_rcu_secret>
   ```
   
   where: 
	
   `-u <rcu_prefix>` is the name of the RCU schema prefix created previously
	
   `-p <rcu_schema_pwd>` is the password for the RCU schema prefix
	
   `-q <sys_db_pwd>` is the sys database password
	
   `-d <domain_uid>` is the domain_uid that you created earlier
	
   `-n <domain_namespace>` is the domain namespace
	
   `-s <kubernetes_rcu_secret>` is the name of the rcu secret to create
	
   For example:
	
   ```bash
   $ cd $WORKDIR/kubernetes/create-rcu-credentials
   $ ./create-rcu-credentials.sh -u OAMK8S -p <password> -a sys -q <password> -d accessdomain -n oamns -s accessdomain-rcu-credentials
   ```

   The output will look similar to the following:
	
   ```
   secret/accessdomain-rcu-credentials created
   secret/accessdomain-rcu-credentials labeled
   The secret accessdomain-rcu-credentials has been successfully created in the oamns namespace.
   ```
	
1. Verify the secret is created using the following command:

   ```bash
   $ kubectl get secret <kubernetes_rcu_secret> -o yaml -n <domain_namespace>
   ```
	
   For example:
	
   ```bash
   $ kubectl get secret accessdomain-rcu-credentials -o yaml -n oamns
   ```
	
   The output will look similar to the following:
	
   ```
   apiVersion: v1
   data:
     password: T3JhY2xlXzEyMw==
     sys_password: T3JhY2xlXzEyMw==
     sys_username: c3lz
     username: T0FNSzhT
   kind: Secret
   metadata:
     creationTimestamp: "<DATE>"
     labels:
       weblogic.domainName: accessdomain
       weblogic.domainUID: accessdomain
     name: accessdomain-rcu-credentials
     namespace: oamns
     resourceVersion: "29428242"
     uid: 1b81b6e0-fd7d-40b8-a060-454c8d23f4dc
   type: Opaque
   ```

	
### Create a Kubernetes persistent volume and persistent volume claim

   As referenced in [Prerequisites](../prerequisites) the nodes in the Kubernetes cluster must have access to a persistent volume such as a Network File System (NFS) mount or a shared file system. 
  
   A persistent volume is the same as a disk mount but is inside a container. A Kubernetes persistent volume is an arbitrary name (determined in this case, by Oracle) that is mapped to a physical volume on a disk.

   When a container is started, it needs to mount that volume. The physical volume should be on a shared disk accessible by all the Kubernetes worker nodes because it is not known on which worker node the container will be started. In the case of Identity and Access Management, the persistent volume does not get erased when a container stops. This enables persistent configurations.
   
   The example below uses an NFS mounted volume (<persistent_volume>/accessdomainpv). Other volume types can also be used. See the official [Kubernetes documentation for Volumes](https://kubernetes.io/docs/concepts/storage/volumes/).
   
   **Note**: The persistent volume directory needs to be accessible to both the master and worker node(s). In this example `/scratch/shared/accessdomainpv` is accessible from all nodes via NFS. 

   
   
   To create a Kubernetes persistent volume, perform the following steps:

1. Make a backup copy of the `create-pv-pvc-inputs.yaml` file and create required directories:

   ```bash
   $ cd $WORKDIR/kubernetes/create-weblogic-domain-pv-pvc
   $ cp create-pv-pvc-inputs.yaml create-pv-pvc-inputs.yaml.orig
   $ mkdir output
   $ mkdir -p <persistent_volume>/accessdomainpv
   $ sudo chown -R 1000:0 <persistent_volume>/accessdomainpv
   ```

	For example:
	
   ```bash
   $ cd $WORKDIR/kubernetes/create-weblogic-domain-pv-pvc
   $ cp create-pv-pvc-inputs.yaml create-pv-pvc-inputs.yaml.orig
   $ mkdir output
   $ mkdir -p /scratch/shared/accessdomainpv
   $ sudo chown -R 1000:0 /scratch/shared/accessdomainpv
   ```

1. On the master node run the following command to ensure it is possible to read and write to the persistent volume:

   ```bash 
   cd <persistent_volume>/accessdomainpv
   touch filemaster.txt
   ls filemaster.txt
   ```
   
   For example:
   
   ```bash
   cd /scratch/shared/accessdomainpv
   touch filemaster.txt
   ls filemaster.txt
   ```
   
   On the first worker node run the following to ensure it is possible to read and write to the persistent volume:
   
   ```bash
   cd /scratch/shared/accessdomainpv
   ls filemaster.txt
   touch fileworker1.txt
   ls fileworker1.txt
   ```
   
   Repeat the above for any other worker nodes e.g fileworker2.txt etc. Once proven that it's possible to read and write from each node to the persistent volume, delete the files created.

1. Navigate to `$WORKDIR/kubernetes/create-weblogic-domain-pv-pvc`:

   ```bash
   $ cd $WORKDIR/kubernetes/create-weblogic-domain-pv-pvc
   ```
   
   and edit the `create-pv-pvc-inputs.yaml` file and update the following parameters to reflect your settings. Save the file when complete:

   ```
   baseName: <domain>
   domainUID: <domain_uid>
   namespace: <domain_namespace>
   weblogicDomainStorageType: NFS
   weblogicDomainStorageNFSServer: <nfs_server>
   weblogicDomainStoragePath: <physical_path_of_persistent_storage>
   weblogicDomainStorageSize: 10Gi
   ```
    
   For example:
	
   ```
	
   # The base name of the pv and pvc
   baseName: domain

   # Unique ID identifying a domain.
   # If left empty, the generated pv can be shared by multiple domains
   # This ID must not contain an underscope ("_"), and must be lowercase and unique across all domains in a Kubernetes cluster.
   domainUID: accessdomain
	
   # Name of the namespace for the persistent volume claim
   namespace: oamns
   ...
   # Persistent volume type for the persistent storage.
   # The value must be 'HOST_PATH' or 'NFS'.
   # If using 'NFS', weblogicDomainStorageNFSServer must be specified.
   weblogicDomainStorageType: NFS

   # The server name or ip address of the NFS server to use for the persistent storage.
   # The following line must be uncomment and customized if weblogicDomainStorateType is NFS:
   weblogicDomainStorageNFSServer: mynfsserver

   # Physical path of the persistent storage.
   # When weblogicDomainStorageType is set to HOST_PATH, this value should be set the to path to the
   # domain storage on the Kubernetes host.
   # When weblogicDomainStorageType is set to NFS, then weblogicDomainStorageNFSServer should be set
   # to the IP address or name of the DNS server, and this value should be set to the exported path
   # on that server.
   # Note that the path where the domain is mounted in the WebLogic containers is not affected by this
   # setting, that is determined when you create your domain.
   # The following line must be uncomment and customized:
   weblogicDomainStoragePath: /scratch/shared/accessdomainpv
   
   # Reclaim policy of the persistent storage
   # The valid values are: 'Retain', 'Delete', and 'Recycle'
   weblogicDomainStorageReclaimPolicy: Retain

   # Total storage allocated to the persistent storage.
   weblogicDomainStorageSize: 10Gi
   ```

1. Execute the `create-pv-pvc.sh` script to create the PV and PVC configuration files:

   ```bash
   $ ./create-pv-pvc.sh -i create-pv-pvc-inputs.yaml -o output
   ```
	
   The output will be similar to the following:
	
   ```
   Input parameters being used
   export version="create-weblogic-sample-domain-pv-pvc-inputs-v1"
   export baseName="domain"
   export domainUID="accessdomain"
   export namespace="oamns"
   export weblogicDomainStorageType="NFS"
   export weblogicDomainStorageNFSServer="mynfsserver"
   export weblogicDomainStoragePath="/scratch/shared/accessdomainpv"
   export weblogicDomainStorageReclaimPolicy="Retain"
   export weblogicDomainStorageSize="10Gi"

   Generating output/pv-pvcs/accessdomain-domain-pv.yaml
   Generating output/pv-pvcs/accessdomain-domain-pvc.yaml
   The following files were generated:
     output/pv-pvcs/accessdomain-domain-pv.yaml.yaml
     output/pv-pvcs/accessdomain-domain-pvc.yaml
   ```

1. Run the following to show the files are created:

   ```bash
   $ ls output/pv-pvcs
   accessdomain-domain-pv.yaml  accessdomain-domain-pvc.yaml  create-pv-pvc-inputs.yaml
   ```
   
1. Run the following `kubectl` command to create the PV and PVC in the domain namespace:

   ```bash
   $ kubectl create -f output/pv-pvcs/accessdomain-domain-pv.yaml -n <domain_namespace>
   $ kubectl create -f output/pv-pvcs/accessdomain-domain-pvc.yaml -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl create -f output/pv-pvcs/accessdomain-domain-pv.yaml -n oamns
   $ kubectl create -f output/pv-pvcs/accessdomain-domain-pvc.yaml -n oamns
   ```

   The output will look similar to the following:
   
   ```
   persistentvolume/accessdomain-domain-pv created
   persistentvolumeclaim/accessdomain-domain-pvc created
   ```
   
1. Run the following commands to verify the PV and PVC were created successfully:

   ```bash
   $ kubectl describe pv <pv_name>
   $ kubectl describe pvc <pvc_name> -n <domain_namespace>
   ```
	
   For example:
   
   ```bash
   $ kubectl describe pv accessdomain-domain-pv
   $ kubectl describe pvc accessdomain-domain-pvc -n oamns
   ```
   
   The output will look similar to the following:

   ```bash
   $ kubectl describe pv accessdomain-domain-pv
   
   Name:           accessdomain-domain-pv
   Labels:         weblogic.domainUID=accessdomain
   Annotations:    pv.kubernetes.io/bound-by-controller: yes
   Finalizers:     [kubernetes.io/pv-protection]
   StorageClass:   accessdomain-domain-storage-class
   Status:         Bound
   Claim:          oamns/accessdomain-domain-pvc
   Reclaim Policy: Retain
   Access Modes:   RWX
   VolumeMode:     Filesystem
   Capacity:       10Gi
   Node Affinity:  <none>
   Message:
   Source:
       Type:      NFS (an NFS mount that lasts the lifetime of a pod)
	   Server:    mynfsserver
       Path:      /scratch/shared/accessdomainpv
       ReadOnly:  false
   Events: <none>
   ```
   
   ```bash
   $ kubectl describe pvc accessdomain-domain-pvc -n oamns
   
   Name:            accessdomain-domain-pvc
   Namespace:       oamns
   StorageClass:    accessdomain-domain-storage-class
   Status:          Bound
   Volume:          accessdomain-domain-pv
   Labels:          weblogic.domainUID=accessdomain
   Annotations:     pv.kubernetes.io/bind-completed: yes
                    pv.kubernetes.io/bound-by-controller: yes
   Finalizers:     [kubernetes.io/pvc-protection]
   Capacity:       10Gi
   Access Modes:   RWX
   VolumeMode:     Filesystem
   Events:         <none>
   Mounted By:     <none>
   ```
   
   
   You are now ready to create the OAM domain as per [Create OAM Domains](../create-oam-domains/).
