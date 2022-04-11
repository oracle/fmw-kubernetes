---
title: "Prepare your environment"
weight: 3
pre : "<b>3. </b>"
description: "Sample for creating an OAM domain home on an existing PV or
PVC, and the domain resource YAML file for deploying the generated OAM domain."
---
To prepare for Oracle Access Management deployment in a Kubernetes environment, complete the following steps:

1. [Set up your Kubernetes cluster](#set-up-your-kubernetes-cluster)
1. [Install Helm](#install-helm)
1. [Check the Kubernetes cluster is ready](#check-the-kubernetes-cluster-is-ready)
1. [Install the OAM Docker image](#install-the-oam-docker-image)
1. [Install the WebLogic Kubernetes Operator docker image](#install-the-weblogic-kubernetes-operator-docker-image)
1. [Set up the code repository to deploy OAM domains](#set-up-the-code-repository-to-deploy-oam-domains)
1. [Install the WebLogic Kubernetes Operator](#install-the-weblogic-kubernetes-operator)
1. [Create a namespace for Oracle Access Management](#create-a-namespace-for-oracle-access-management)
1. [RCU schema creation](#rcu-schema-creation)
1. [Preparing the environment for domain creation](#preparing-the-environment-for-domain-creation)
    
    a. [Creating Kubernetes secrets for the domain and RCU](#creating-kubernetes-secrets-for-the-domain-and-rcu)
    
	b. [Create a Kubernetes persistent volume and persistent volume claim](#create-a-kubernetes-persistent-volume-and-persistent-volume-claim)

### Set up your Kubernetes cluster

If you need help setting up a Kubernetes environment, refer to the official Kubernetes [documentation](https://kubernetes.io/docs/setup/#production-environment) to set up a production grade Kubernetes cluster.

It is recommended you have a master node and one or more worker nodes. The examples in this documentation assume one master and two worker nodes.

Verify that the system clocks on each host computer are synchronized. You can do this by running the date command simultaneously on all the hosts in each cluster.

After creating Kubernetes clusters, you can optionally:

* Configure an Ingress to direct traffic to backend domains.
* Configure Kibana and Elasticsearch for your operator logs.

### Install Helm

As per the [prerequisites](../prerequisites) an installation of Helm is required to create and deploy the necessary resources and then run the operator in a Kubernetes cluster. For Helm installation and usage information, refer to the [README](https://github.com/helm/helm).

### Check the Kubernetes cluster is ready

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
	
### Install the OAM Docker image

You can deploy OAM Docker images in the following ways:

1. Download the latest prebuilt OAM Docker image from [My Oracle Support](https://support.oracle.com) by referring to the document ID 2723908.1. This image is prebuilt by Oracle and includes Oracle Access Management 12.2.1.4.0 and the latest PSU.

1. Build your own OAM image using the WebLogic Image Tool or by using the dockerfile, scripts and base images from Oracle Container Registry (OCR). You can also build your own image by using only the dockerfile and scripts. For more information about the various ways in which you can build your own container image, see [Building the OAM Image](https://github.com/oracle/docker-images/tree/master/OracleAccessManagement/#building-the-oam-image).

Choose one of these options based on your requirements.

{{% notice note %}}
The OAM Docker image must be installed on the master node and each of the worker nodes in your Kubernetes cluster. Alternatively you can place the image in a Docker registry that your cluster can access.
{{% /notice %}}

After installing the OAM Docker image run the following command to make sure the image is installed correctly on the master and worker nodes:
 
```bash
$ docker images
```
The output will look similar to the following:

   ```
   REPOSITORY                                       TAG                            IMAGE ID            CREATED             SIZE
   oracle/oam                                       12.2.1.4.0-8-ol7-210721.0755   720a172374e6        2 weeks ago         3.38GB
   quay.io/coreos/flannel                           v0.15.0                        09b38f011a29        6 days ago          69.5MB
   rancher/mirrored-flannelcni-flannel-cni-plugin   v1.2                           98660e6e4c3a        13 days ago         8.98MB
   k8s.gcr.io/kube-proxy                            v1.20.10                       945c9bce487a        2 months ago        99.7MB
   k8s.gcr.io/kube-controller-manager               v1.20.10                       2f450864515d        2 months ago        116MB
   k8s.gcr.io/kube-apiserver                        v1.20.10                       644cadd07add        2 months ago        122MB
   k8s.gcr.io/kube-scheduler                        v1.20.10                       4c9be8dc650b        2 months ago        47.3MB
   k8s.gcr.io/etcd                                  3.4.13-0                       0369cf4303ff        14 months ago       253MB
   k8s.gcr.io/coredns                               1.7.0                          bfe3a36ebd25        16 months ago       45.2MB
   k8s.gcr.io/pause                                 3.2                            80d28bedfe5d        20 months ago       683kB
   ```



### Install the WebLogic Kubernetes Operator Docker image

{{% notice note %}}
The WebLogic Kubernetes Operator Docker image must be installed on the master node and each of the worker nodes in your Kubernetes cluster. Alternatively you can place the image in a Docker registry that your cluster can access.
{{% /notice %}}

1. Pull the WebLogic Kubernetes Operator image by running the following command on the master node:
   ```bash
   $ docker pull ghcr.io/oracle/weblogic-kubernetes-operator:3.3.0
   ```
  
   The output will look similar to the following:


   ```
   Trying to pull repository ghcr.io/oracle/weblogic-kubernetes-operator ...
   3.3.0: Pulling from ghcr.io/oracle/weblogic-kubernetes-operator
   c828c776e142: Pull complete
   175676c54fa1: Pull complete
   b3231f480c32: Pull complete
   ea4423fa8daa: Pull complete
   f3ca38f7f95f: Pull complete
   effd851583ec: Pull complete
   4f4fb700ef54: Pull complete
   Digest: sha256:3e93848ad2f5b272c88680e7b37a4ee428dd12e4c4c91af6977fd2fa9ec1f9dc
   Status: Downloaded newer image for ghcr.io/oracle/weblogic-kubernetes-operator:3.3.0
   ghcr.io/oracle/weblogic-kubernetes-operator:3.3.0
   ```

1. Run the docker tag command as follows:

   ```bash
   $ docker tag ghcr.io/oracle/weblogic-kubernetes-operator:3.3.0 weblogic-kubernetes-operator:3.3.0
   ```

   After installing the WebLogic Kubernetes Operator image, repeat the above on the worker nodes.


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
   $ git clone https://github.com/oracle/fmw-kubernetes.git --branch release/21.4.2
   ```
   
   For example:
   
   ```bash
   $ cd /scratch/OAMK8S
   $ git clone https://github.com/oracle/fmw-kubernetes.git --branch release/21.4.2
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

1. If you want to to setup logging and visualisation with Elasticsearch and Kibana (post domain creation) edit the `$WORKDIR/kubernetes/charts/weblogic-operator/values.yaml` and set the parameter `elkIntegrationEnabled` to `true` and make sure the following parameters are set:

   ```
   # elkIntegrationEnabled specifies whether or not ELK integration is enabled.
   elkIntegrationEnabled: true
   
   # logStashImage specifies the docker image containing logstash.
   # This parameter is ignored if 'elkIntegrationEnabled' is false.
   logStashImage: "logstash:6.6.0"
 
   # elasticSearchHost specifies the hostname of where elasticsearch is running.
   # This parameter is ignored if 'elkIntegrationEnabled' is false.
   elasticSearchHost: "elasticsearch.default.svc.cluster.local"
 
   # elasticSearchPort specifies the port number of where elasticsearch is running.
   # This parameter is ignored if 'elkIntegrationEnabled' is false.
   elasticSearchPort: 9200
   ```
   
   After the domain creation see [Logging and Visualization](../manage-oam-domains/logging-and-visualization) in order to complete the setup of Elasticsearch and Kibana.
   

1. Run the following helm command to install and start the operator:   
  
   ```bash
   $ cd $WORKDIR
   $ helm install weblogic-kubernetes-operator kubernetes/charts/weblogic-operator \
   --namespace <sample-kubernetes-operator-ns> \
   --set image=weblogic-kubernetes-operator:3.3.0 \
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
   --set image=weblogic-kubernetes-operator:3.3.0 \
   --set serviceAccount=op-sa \
   --set "enableClusterRoleBinding=true" \
   --set "domainNamespaceSelectionStrategy=LabelSelector" \
   --set "domainNamespaceLabelSelector=weblogic-operator\=enabled" \
   --set "javaLoggingLevel=FINE" --wait
   ```


   The output will look similar to the following:
   
   ```
   NAME: weblogic-kubernetes-operator
   LAST DEPLOYED: Fri Oct 29 03:10:39 2021
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
   pod/weblogic-operator-676d5cc6f4-wct7b   2/2     Running   0          40s

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
   {"timestamp":"2021-11-01T10:26:10.917829423Z","thread":13,"fiber":"","namespace":"","domainUID":"","level":"CONFIG","class":"oracle.kubernetes.operator.TuningParametersImpl","method":"update","timeInMillis":1635762370917,"message":"Reloading tuning parameters from Operator's config map","exception":"","code":"","headers":{},"body":""}
   {"timestamp":"2021-11-01T10:26:20.920145876Z","thread":13,"fiber":"","namespace":"","domainUID":"","level":"CONFIG","class":"oracle.kubernetes.operator.TuningParametersImpl","method":"update","timeInMillis":1635762380920,"message":"Reloading tuning parameters from Operator's config map","exception":"","code":"","headers":{},"body":""}
   {"timestamp":"2021-11-01T10:26:30.922360564Z","thread":19,"fiber":"","namespace":"","domainUID":"","level":"CONFIG","class":"oracle.kubernetes.operator.TuningParametersImpl","method":"update","timeInMillis":1635762390922,"message":"Reloading tuning parameters from Operator's config map","exception":"","code":"","headers":{},"body":""}
   {"timestamp":"2021-11-01T10:26:40.924847211Z","thread":29,"fiber":"","namespace":"","domainUID":"","level":"CONFIG","class":"oracle.kubernetes.operator.TuningParametersImpl","method":"update","timeInMillis":1635762400924,"message":"Reloading tuning parameters from Operator's config map","exception":"","code":"","headers":{},"body":""}
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
   Labels:       weblogic-operator=enabled
   Annotations:  <none>
   Status:       Active

   No resource quota.

   No LimitRange resource.
   ``` 

   

### RCU schema creation
	
In this section you create the RCU schemas in the Oracle Database.
	
Before following the steps in this section, make sure that the database and listener are up and running and you can connect to the database via SQL*Plus or other client tool.

1. Run the following command to create a helper pod to run RCU:

   ```bash
   $ kubectl run helper --image <image_name> -n <domain_namespace> -- sleep infinity
   ```
	
   For example:
	
   ```bash
   $ kubectl run helper --image oracle/oam:12.2.1.4.0-8-ol7-210721.0755 -n oamns -- sleep infinity
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
   helper   1/1     Running   0          8s
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
   RCU Logfile: /tmp/RCU2021-11-01_10-29_561898106/logs/rcu.log
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
   RCU Logfile :  /tmp/RCU2021-11-01_10-29_561898106/logs/rcu.log
   Component schemas created:
   -----------------------------
   Component Status Logfile
   Common Infrastructure Services Success /tmp/RCU2021-11-01_10-29_561898106/logs/stb.log
   Oracle Platform Security Services Success /tmp/RCU2021-11-01_10-29_561898106/logs/opss.log
   Oracle Access Manager Success /tmp/RCU2021-11-01_10-29_561898106/logs/oam.log
   Audit Services Success /tmp/RCU2021-11-01_10-29_561898106/logs/iau.log
   Audit Services Append Success /tmp/RCU2021-11-01_10-29_561898106/logs/iau_append.log
   Audit Services Viewer Success /tmp/RCU2021-11-01_10-29_561898106/logs/iau_viewer.log
   Metadata Services Success /tmp/RCU2021-11-01_10-29_561898106/logs/mds.log
   WebLogic Services Success /tmp/RCU2021-11-01_10-29_561898106/logs/wls.log
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
     creationTimestamp: "2021-11-01T10:32:35Z"
     labels:
       weblogic.domainName: accessdomain
       weblogic.domainUID: accessdomain
     managedFields:
     - apiVersion: v1
       fieldsType: FieldsV1
       fieldsV1:
         f:data:
           .: {}
           f:password: {}
           f:username: {}
         f:type: {}
       manager: kubectl-create
       operation: Update
       time: "2021-11-01T10:32:35Z"
      - apiVersion: v1
       fieldsType: FieldsV1
       fieldsV1:
         f:metadata:
           f:labels:
             .: {}
             f:weblogic.domainName: {}
             f:weblogic.domainUID: {}
       manager: kubectl-label
       operation: Update
       time: "2021-11-01T10:32:35Z"
     name: accessdomain-credentials
     namespace: oamns
     resourceVersion: "990770"
     uid: b2ffcd87-8c61-4fb1-805e-3768295982e2
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
     password: V2VsY29tZTE=
     sys_password: V2VsY29tZTE=
     sys_username: c3lz
     username: T0FNSzhT
   kind: Secret
   metadata:
     creationTimestamp: "2021-11-01T10:33:37Z"
     labels:
       weblogic.domainName: accessdomain
       weblogic.domainUID: accessdomain
     managedFields:
     - apiVersion: v1
       fieldsType: FieldsV1
       fieldsV1:
         f:data:
           .: {}
           f:password: {}
           f:sys_password: {}
           f:sys_username: {}
           f:username: {}
         f:type: {}
       manager: kubectl-create
       operation: Update
       time: "2021-11-01T10:33:37Z"
     - apiVersion: v1
       fieldsType: FieldsV1
       fieldsV1:
         f:metadata:
           f:labels:
             .: {}
             f:weblogic.domainName: {}
             f:weblogic.domainUID: {}
       manager: kubectl-label
       operation: Update
       time: "2021-11-01T10:33:37Z"
     name: accessdomain-rcu-credentials
     namespace: oamns
     resourceVersion: "992205"
     uid: ee283fbd-6211-4172-9c28-a65c84ecd794
   type: Opaque
   ```

	
### Create a Kubernetes persistent volume and persistent volume claim
  
   A persistent volume is the same as a disk mount but is inside a container. A Kubernetes persistent volume is an arbitrary name (determined in this case, by Oracle) that is mapped to a physical volume on a disk.

   When a container is started, it needs to mount that volume. The physical volume should be on a shared disk accessible by all the Kubernetes worker nodes because it is not known on which worker node the container will be started. In the case of Identity and Access Management, the persistent volume does not get erased when a container stops. This enables persistent configurations.
   
   The example below uses an NFS mounted volume (<workdir>/accessdomainpv). Other volume types can also be used. See the official [Kubernetes documentation for Volumes](https://kubernetes.io/docs/concepts/storage/volumes/).
   
   To create a Kubernetes persistent volume, perform the following steps:

1. Make a backup copy of the `create-pv-pvc-inputs.yaml` file and create required directories:

   ```bash
   $ cd $WORKDIR/kubernetes/create-weblogic-domain-pv-pvc
   $ cp create-pv-pvc-inputs.yaml create-pv-pvc-inputs.yaml.orig
   $ mkdir output
   $ mkdir -p /<workdir>/accessdomainpv
   $ chmod -R 777 /<workdir>/accessdomainpv
   ```

	For example:
	
   ```bash
   $ cd $WORKDIR/kubernetes/create-weblogic-domain-pv-pvc
   $ cp create-pv-pvc-inputs.yaml create-pv-pvc-inputs.yaml.orig
   $ mkdir output
   $ mkdir -p /scratch/OAMK8S/accessdomainpv
   $ chmod -R 777 /scratch/OAMK8S/accessdomainpv
   ```
	
	**Note**: The persistent volume directory needs to be accessible to both the master and worker node(s) via NFS. Make sure this path has full access permissions, and that the folder is empty. In this example `/scratch/OAMK8S/accessdomainpv` is accessible from all nodes via NFS. 

1. On the master node run the following command to ensure it is possible to read and write to the persistent volume:

   ```bash 
   cd <workdir>/accessdomainpv
   touch filemaster.txt
   ls filemaster.txt
   ```
   
   For example:
   
   ```bash
   cd /scratch/OAMK8S/accessdomainpv
   touch filemaster.txt
   ls filemaster.txt
   ```
   
   On the first worker node run the following to ensure it is possible to read and write to the persistent volume:
   
   ```bash
   cd /scratch/OAMK8S/accessdomainpv
   ls filemaster.txt
   touch fileworker1.txt
   ls fileworker1.txt
   ```
   
   Repeat the above for any other worker nodes e.g fileworker2.txt etc. Once proven that it's possible to read and write from each node to the persistent volume, delete the files created.

1. Edit the `create-pv-pvc-inputs.yaml` file and update the following parameters to reflect your settings. Save the file when complete:

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
   weblogicDomainStoragePath: /scratch/OAMK8S/accessdomainpv
   
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
   export weblogicDomainStoragePath="/scratch/OAMK8S/accessdomainpv"
   export weblogicDomainStorageReclaimPolicy="Retain"
   export weblogicDomainStorageSize="10Gi"

   Generating output/pv-pvcs/accessdomain-weblogic-sample-pv.yaml
   Generating output/pv-pvcs/accessdomain-weblogic-sample-pvc.yaml
   The following files were generated:
     output/pv-pvcs/accessdomain-weblogic-sample-pv.yaml
     output/pv-pvcs/accessdomain-weblogic-sample-pvc.yaml
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

   ```
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
       Path:      /scratch/OAMK8S/accessdomainpv
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
   
   
   You are now ready to create the OAM domain as per [Create OAM Domains](../create-oam-domains/)
