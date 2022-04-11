+++
title=  "Prepare your environment"
weight = 3
pre = "<b>3. </b>"
description = "Preparation to deploy OIG on Kubernetes"
+++

1. [Set up your Kubernetes cluster](#set-up-your-kubernetes-cluster)
1. [Install Helm](#install-helm)
1. [Check the Kubernetes cluster is ready](#check-the-kubernetes-cluster-is-ready)
1. [Install the OIG Docker image](#install-the-oig-docker-image)
1. [Install the WebLogic Kubernetes Operator Docker Image](#install-the-weblogic-kubernetes-operator-docker-image)
1. [Setup the Code Repository to Deploy Oracle Identity Governance Domains](#setup-the-code-repository-to-deploy-oracle-identity-governance-domains)
1. [Install the WebLogic Kubernetes Operator](#install-the-weblogic-kubernetes-operator)
1. [RCU schema creation](#rcu-schema-creation)
1. [Preparing the environment for domain creation](#preparing-the-environment-for-domain-creation)
    1. [Configure the operator for the domain namespace](#configure-the-operator-for-the-domain-namespace)
	1. [Creating Kubernetes secrets for the domain and RCU](#creating-kubernetes-secrets-for-the-domain-and-rcu)
	1. [Create a Kubernetes persistent volume and persistent volume claim](#create-a-kubernetes-persistent-volume-and-persistent-volume-claim)

### Set up your Kubernetes cluster

If you need help setting up a Kubernetes environment, check our [cheat sheet](https://oracle.github.io/weblogic-kubernetes-operator/userguide/overview/k8s-setup/).

It is recommended you have a master node and one or more worker nodes. The examples in this documentation assume one master and two worker nodes.

Verify that the system clocks on each host computer are synchronized. You can do this by running the date command simultaneously on all the hosts in each cluster.

After creating Kubernetes clusters, you can optionally:

* Configure an Ingress to direct traffic to backend domains.
* Configure Kibana and Elasticsearch for your operator logs.

### Install Helm

As per the [prerequisites](../prerequisites) an installation of Helm is required to create and deploy the necessary resources and then run the operator in a Kubernetes cluster. For Helm installation and usage information, refer to the [README](https://github.com/helm/helm).

### Check the Kubernetes cluster is ready

Run the following command on the master node to check the cluster and worker nodes are running:
    
```
$ kubectl get nodes,pods -n kube-system
```

The output will look similar to the following:
	
```
$ kubectl get nodes,pods -n kube-system
NAME                STATUS   ROLES    AGE   VERSION
node/worker-node1   Ready    <none>   10d   v1.18.4
node/worker-node2   Ready    <none>   10d   v1.18.4
node/master-node    Ready    master   11d   v1.18.4

NAME                                      READY   STATUS    RESTARTS   AGE
pod/coredns-66bff467f8-slxdq              1/1     Running   0          11d
pod/coredns-66bff467f8-v77qt              1/1     Running   0          11d
pod/etcd-master-node                      1/1     Running   0          11d
pod/kube-apiserver-master-node            1/1     Running   0          11d
pod/kube-controller-manager-master-node   1/1     Running   0          11d
pod/kube-flannel-ds-amd64-dcqjn           1/1     Running   0          10d
pod/kube-flannel-ds-amd64-g4ztq           1/1     Running   0          11d
pod/kube-flannel-ds-amd64-vpcbj           1/1     Running   1          10d
pod/kube-proxy-jtcxm                      1/1     Running   0          11d
pod/kube-proxy-swfmm                      1/1     Running   0          10d
pod/kube-proxy-w6x6t                      1/1     Running   0          10d
pod/kube-scheduler-master-node            1/1     Running   0          11d
$
```

### Install the OIG Docker Image

You can deploy OIG Docker images in the following ways:

1. Download a prebuilt OIG Docker image from [My Oracle Support](https://support.oracle.com) by referring to the document ID 2723908.1. This image is prebuilt by Oracle and includes Oracle Identity Governance 12.2.1.4.0 and the latest PSU.

1. Build your own OIG image using the WebLogic Image Tool or by using the dockerfile, scripts and base images from Oracle Container Registry (OCR). You can also build your own image by using only the dockerfile and scripts. For more information about the various ways in which you can build your own container image, see [Building the OIG Docker Image](https://github.com/oracle/docker-images/tree/master/OracleIdentityGovernance/#building-the-oig-image).

Choose one of these options based on your requirements.

{{% notice note %}}
The OIG Docker image must be installed on the master node AND each of the worker nodes in your Kubernetes cluster. Alternatively you can place the image in a Docker registry that your cluster can access.
{{% /notice %}}

After installing the OIG Docker image run the following command to make sure the image is installed correctly on the master and worker nodes:
 
```
$ docker images
```

The output will look similar to the following:

```
REPOSITORY                            TAG                 IMAGE ID            CREATED             SIZE
oracle/oig                            12.2.1.4.0          59ffc14dddbb        3 days ago          4.96GB
k8s.gcr.io/kube-proxy                 v1.18.4             718fa77019f2        6 weeks ago         117MB
k8s.gcr.io/kube-scheduler             v1.18.4             c663567f869e        6 weeks ago         95.3MB
k8s.gcr.io/kube-controller-manager    v1.18.4             e8f1690127c4        6 weeks ago         162MB
k8s.gcr.io/kube-apiserver             v1.18.4             408913fc18eb        6 weeks ago         173MB
quay.io/coreos/flannel                v0.12.0-amd64       4e9f801d2217        4 months ago        52.8MB
k8s.gcr.io/pause                      3.2                 80d28bedfe5d        5 months ago        683kB
k8s.gcr.io/coredns                    1.6.7               67da37a9a360        6 months ago        43.8MB
k8s.gcr.io/etcd                       3.4.3-0             303ce5db0e90        9 months ago        288MB
```

### Install the WebLogic Kubernetes Operator Docker Image

In this release only Oracle WebLogic Server Kubernetes Operator 3.0.1 is supported.

{{% notice note %}}
The Oracle WebLogic Server Kubernetes Operator Docker image must be installed on the master node and each of the worker nodes in your Kubernetes cluster. Alternatively you can place the image in a Docker registry that your cluster can access.
{{% /notice %}}

1. Pull the Oracle WebLogic Server Kubernetes Operator 3.0.1 image by running the following command on the master node:

   ```bash
   $ docker pull ghcr.io/oracle/weblogic-kubernetes-operator:3.0.1
   ```
 
   The output will look similar to the following:

   ```bash
   Trying to pull repository ghcr.io/oracle/weblogic-kubernetes-operator:3.0.1 ...
   3.0.1: Pulling from ghcr.io/oracle/weblogic-kubernetes-operator:3.0.1
   bce8f778fef0: Already exists
   de14ddc50a70: Pull complete
   77401a861078: Pull complete
   9c5ac1423af4: Pull complete
   2b6f244f998f: Pull complete
   625e05083092: Pull complete
   Digest: sha256:27047d032ac5a9077b39bec512b99d8ca54bf9bf71227f5fd1b7b26ac80c20d3
   Status: Downloaded newer image for ghcr.io/oracle/weblogic-kubernetes-operator:3.0.1
   ghcr.io/oracle/weblogic-kubernetes-operator:3.0.1
   ```

1. Run the docker tag command as follows:

   ```bash
   $ docker tag ghcr.io/oracle/weblogic-kubernetes-operator:3.0.1 weblogic-kubernetes-operator:3.0.1
   ```

   After installing the Oracle WebLogic Server Kubernetes Operator 3.0.1 Docker image, repeat the above on the worker nodes.

### Setup the Code Repository to Deploy Oracle Identity Governance Domains

Oracle Identity Governance domain deployment on Kubernetes leverages the WebLogic Kubernetes Operator infrastructure. For deploying the Oracle Identity Governance domains, you need to set up the deployment scripts on the **master** node as below:

1. Create a working directory to setup the source code.

   ```bash
   $ mkdir <work directory>
   ```
   
   For example:
   ```bash
   $ mkdir /scratch/OIGDockerK8S
   ```

1. Download the supported version of the WebLogic Kubernetes Operator source code from the operator github project. Currently the supported operator version is [3.0.1](https://github.com/oracle/weblogic-kubernetes-operator/releases/tag/v3.0.1):

    ```bash
   $ cd <work directory>
   $ git clone https://github.com/oracle/weblogic-kubernetes-operator.git --branch release/3.0.1
   ```

   For example:

   ```bash
   $ cd /scratch/OIGDockerK8S
   $ git clone https://github.com/oracle/weblogic-kubernetes-operator.git --branch release/3.0.1
   ```

   This will create the directory `<work directory>/weblogic-kubernetes-operator`

1. Clone the Oracle Identity Governance deployment scripts from the OIG [repository](https://github.com/oracle/fmw-kubernetes.git) and copy them into the WebLogic operator samples location.

   ```bash
   $ git clone https://github.com/oracle/fmw-kubernetes.git --branch release/21.4.1
   $ cp -rf <work directory>/fmw-kubernetes/OracleIdentityGovernance/kubernetes/3.0.1/create-oim-domain  <work directory>/weblogic-kubernetes-operator/kubernetes/samples/scripts/
   $ mv -f <work directory>/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain  <work directory>/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain_backup
   $ cp -rf <work directory>/fmw-kubernetes/OracleIdentityGovernance/kubernetes/3.0.1/ingress-per-domain <work directory>/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain
   $ cp -rf <work directory>/fmw-kubernetes/OracleIdentityGovernance/kubernetes/3.0.1/design-console-ingress <work directory>/weblogic-kubernetes-operator/kubernetes/samples/charts/design-console-ingress
   ```

   For example:   
  
   ```bash
   $ git clone https://github.com/oracle/fmw-kubernetes.git --branch release/21.4.1
   $ cp -rf /scratch/OIGDockerK8S/fmw-kubernetes/OracleIdentityGovernance/kubernetes/3.0.1/create-oim-domain  /scratch/OIGDockerK8S/weblogic-kubernetes-operator/kubernetes/samples/scripts/
   $ mv -f /scratch/OIGDockerK8S/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain  /scratch/OIGDockerK8S/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain_backup
   $ cp -rf /scratch/OIGDockerK8S/fmw-kubernetes/OracleIdentityGovernance/kubernetes/3.0.1/ingress-per-domain /scratch/OIGDockerK8S/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain
   $ cp -rf /scratch/OIGDockerK8S/fmw-kubernetes/OracleIdentityGovernance/kubernetes/3.0.1/design-console-ingress /scratch/OIGDockerK8S/weblogic-kubernetes-operator/kubernetes/samples/charts/design-console-ingress
   ```
   
   You can now use the deployment scripts from `<work directory>/weblogic-kubernetes-operator/kubernetes/samples/scripts/` to set up the OIG domains as further described in this document.

1. Run the following command and see if the WebLogic custom resource definition name already exists:

   ```bash
   $ kubectl get crd
   ```
	
   In the output you should see:
	
   ```bash
   No resources found in default namespace.
   ```
   
   If you see the following:
	
   ```bash
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
   
   ```bash
   serviceaccount/op-sa created
   ```

1. If you want to setup logging and visualisation with Elasticsearch and Kibana (post domain creation) edit the `<work directory>/weblogic-kubernetes-operator/kubernetes/charts/weblogic-operator/values.yaml` and set the parameter `elkIntegrationEnabled` to `true` and make sure the following parameters are set:

   ```bash
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
   $ cd <work directory>/weblogic-kubernetes-operator
   $ helm install kubernetes/charts/weblogic-operator \
   --namespace <sample-kubernetes-operator-ns> \
   --set image=weblogic-kubernetes-operator:3.0.1 \
   --set serviceAccount=<sample-kubernetes-operator-sa> \
   --set "domainNamespaces={}"
   ```
  
   For example:
  
   ```bash
   $ cd /scratch/OIGDockerK8S/weblogic-kubernetes-operator
   $ helm install weblogic-kubernetes-operator kubernetes/charts/weblogic-operator \
   --namespace opns \
   --set image=weblogic-kubernetes-operator:3.0.1 \
   --set serviceAccount=op-sa \
   --set "domainNamespaces={}" 
   ```

   The output will look similar to the following:
   
   ```bash
   NAME: weblogic-kubernetes-operator
   LAST DEPLOYED: Tue Sep 29 02:33:06 2020
   NAMESPACE: opns
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   ```
   
1. Verify that the operator's pod is running by executing the following command to list the pods in the operator's namespace:

   ```bash
   $ kubectl get all -n <sample-kubernetes-operator-ns>
   ```

   For example:

   ```bash
   $ kubectl get all -n opns
   ```
	
   The output will look similar to the following:

   ```bash
   NAME                                     READY   STATUS    RESTARTS   AGE
   pod/weblogic-operator-5d5dfb74ff-t7ct5   2/2     Running   0          17m

   NAME                                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
   service/internal-weblogic-operator-svc   ClusterIP   10.101.11.127   <none>        8082/TCP   17m

   NAME                                READY   UP-TO-DATE   AVAILABLE   AGE
   deployment.apps/weblogic-operator   1/1     1            1           17m

   NAME                                           DESIRED   CURRENT   READY   AGE
   replicaset.apps/weblogic-operator-5d5dfb74ff   1         1         1       17m
   ```

1. Verify that the operator is up and running by viewing the operator pod's log:
	
   ```bash
   $ kubectl logs -n <sample-kubernetes-operator-ns> -c weblogic-operator deployments/weblogic-operator
   ```

   For example:
	
   ```bash
   $ kubectl logs -n opns -c weblogic-operator deployments/weblogic-operator
   ```
	
   The output will look similar to the following:
	
   ```bash
   {"timestamp":"09-29-2020T09:33:26.284+0000","thread":27,"fiber":"fiber-1","namespace":"operator","domainUID":"","level":"WARNING","class":"oracle.kubernetes.operator.utils.Certificates","method":"getCertificate","timeInMillis":1601372006284,"message":"No external certificate configured for REST endpoint. Endpoint will be disabled.","exception":"","code":"","headers":{},"body":""}
   {"timestamp":"09-29-2020T09:33:28.611+0000","thread":27,"fiber":"fiber-1","namespace":"operator","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.rest.RestServer","method":"start","timeInMillis":1601372008611,"message":"Started the internal ssl REST server on https://0.0.0.0:8082/operator","exception":"","code":"","headers":{},"body":""}
   {"timestamp":"09-29-2020T09:33:28.613+0000","thread":27,"fiber":"fiber-1","namespace":"operator","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.Main","method":"markReadyAndStartLivenessThread","timeInMillis":1601372008613,"message":"Starting Operator Liveness Thread","exception":"","code":"","headers":{},"body":""}
   ```

### RCU schema creation
	
In this section you create the RCU schemas in the Oracle Database.
	
Before following the steps in this section, make sure that the database and listener are up and running and you can connect to the database via SQL*Plus or other client tool.
	
1. Run the following command to create a namespace for the domain:
	
   ```bash
   $ kubectl create namespace <domain_namespace>
   ```
	
   For example:
	
   ```
   $ kubectl create namespace oigns
   ```
	
   The output will look similar to the following:
	
   ```
   namespace/oigns created
   ```

   Run the following command to create a helper pod:

   ```bash
   $ kubectl run helper --image <image_name> -n <domain_namespace> -- sleep infinity
   ```
	
   For example:
	
   ```bash
   $ kubectl run helper --image oracle/oig:12.2.1.4.0 -n oigns -- sleep infinity
   ```
	
   The output will look similar to the following:
	
   ```bash
   pod/helper created
   ```
	
1. Run the following command to start a bash shell in the helper pod:

   ```bash
   $ kubectl exec -it helper -n <domain_namespace> -- /bin/bash
   ```
	
   For example:
	
   ```bash
   $ kubectl exec -it helper -n oigns -- /bin/bash
   ```
	
   This will take you into a bash shell in the running rcu pod:
	
   ```bash
   [oracle@helper oracle]$
   ```
	
1. In the helper bash shell run the following commands to set the environment:

   ```bash
   [oracle@helper oracle]$ export DB_HOST=<db_host.domain>
   [oracle@helper oracle]$ export DB_PORT=<db_port>
   [oracle@helper oracle]$ export DB_SERVICE=<service_name>
   [oracle@helper oracle]$ export RCUPREFIX=<rcu_schema_prefix>
   [oracle@helper oracle]$ export RCU_SCHEMA_PWD=<rcu_schema_pwd>
   [oracle@helper oracle]$ echo -e <db_pwd>"\n"<rcu_schema_pwd> > /tmp/pwd.txt
   [oracle@helper oracle]$ cat /tmp/pwd.txt
   ```
   
   where: 
	
   `<db_host.domain>` is the database server hostname
   
   `<db_port>` is the database listener port
   
   `<service_name>` is the database service name
   
   `<rcu_schema_prefix>` is the RCU schema prefix you want to set
   
   `<rcu_schema_pwd>` is the password you want to set for the `<rcu_schema_prefix>`
	
   `<db_pwd>` is the SYS password for the database
	
   For example:
	
   ```bash
   [oracle@helper oracle]$ export DB_HOST=mydatabasehost.example.com
   [oracle@helper oracle]$ export DB_PORT=1521
   [oracle@helper oracle]$ export DB_SERVICE=orcl.example.com
   [oracle@helper oracle]$ export RCUPREFIX=OIGK8S
   [oracle@helper oracle]$ export RCU_SCHEMA_PWD=<password>
   [oracle@helper oracle]$ echo -e <password>"\n"<password> > /tmp/pwd.txt
   [oracle@helper oracle]$ cat /tmp/pwd.txt
   <password>
   <password>
   ```

1. In the helper bash shell run the following commands to create the RCU schemas in the database:

   ```bash
   [oracle@helper oracle]$ /u01/oracle/oracle_common/bin/rcu -silent -createRepository -databaseType ORACLE -connectString \
   $DB_HOST:$DB_PORT/$DB_SERVICE -dbUser sys -dbRole sysdba -useSamePasswordForAllSchemaUsers true \
   -selectDependentsForComponents true -schemaPrefix $RCUPREFIX -component OIM -component MDS -component SOAINFRA -component OPSS \
   -f < /tmp/pwd.txt
   ```
	
   The output will look similar to the following:
	
   ```bash
   RCU Logfile: /tmp/RCU2020-09-29_10-51_508080961/logs/rcu.log

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
           Percent Complete: 10
   Executing pre create operations
           Percent Complete: 25
           Percent Complete: 25
           Percent Complete: 26
           Percent Complete: 27
           Percent Complete: 28
           Percent Complete: 28
           Percent Complete: 29
           Percent Complete: 29
   Creating Common Infrastructure Services(STB)
           Percent Complete: 36
           Percent Complete: 36
           Percent Complete: 44
           Percent Complete: 44
           Percent Complete: 44
   Creating Audit Services Append(IAU_APPEND)
           Percent Complete: 51
           Percent Complete: 51
           Percent Complete: 59
           Percent Complete: 59
           Percent Complete: 59
   Creating Audit Services Viewer(IAU_VIEWER)
           Percent Complete: 66
           Percent Complete: 66
           Percent Complete: 67
           Percent Complete: 67
           Percent Complete: 68
           Percent Complete: 68
   Creating Metadata Services(MDS)
           Percent Complete: 76
           Percent Complete: 76
           Percent Complete: 76
           Percent Complete: 77
           Percent Complete: 77
           Percent Complete: 78
           Percent Complete: 78
           Percent Complete: 78
   Creating Weblogic Services(WLS)
           Percent Complete: 82
           Percent Complete: 82
           Percent Complete: 83
           Percent Complete: 84
           Percent Complete: 86
           Percent Complete: 88
           Percent Complete: 88
           Percent Complete: 88
   Creating User Messaging Service(UCSUMS)
           Percent Complete: 92
           Percent Complete: 92
           Percent Complete: 95
           Percent Complete: 95
           Percent Complete: 100
   Creating Audit Services(IAU)
   Creating Oracle Platform Security Services(OPSS)
   Creating SOA Infrastructure(SOAINFRA)
   Creating Oracle Identity Manager(OIM)
   Executing post create operations

   Repository Creation Utility: Create - Completion Summary

   Database details:
   -----------------------------
   Host Name                                    : mydatabasehost.example.com
   Port                                         : 1521
   Service Name                                 : ORCL.EXAMPLE.COM
   Connected As                                 : sys
   Prefix for (prefixable) Schema Owners        : OIGK8S
   RCU Logfile                                  : /tmp/RCU2020-09-29_10-51_508080961/logs/rcu.log

   Component schemas created:
   -----------------------------
   Component                                    Status         Logfile

   Common Infrastructure Services               Success        /tmp/RCU2020-09-29_10-51_508080961/logs/stb.log
   Oracle Platform Security Services            Success        /tmp/RCU2020-09-29_10-51_508080961/logs/opss.log
   SOA Infrastructure                           Success        /tmp/RCU2020-09-29_10-51_508080961/logs/soainfra.log
   Oracle Identity Manager                      Success        /tmp/RCU2020-09-29_10-51_508080961/logs/oim.log
   User Messaging Service                       Success        /tmp/RCU2020-09-29_10-51_508080961/logs/ucsums.log
   Audit Services                               Success        /tmp/RCU2020-09-29_10-51_508080961/logs/iau.log
   Audit Services Append                        Success        /tmp/RCU2020-09-29_10-51_508080961/logs/iau_append.log
   Audit Services Viewer                        Success        /tmp/RCU2020-09-29_10-51_508080961/logs/iau_viewer.log
   Metadata Services                            Success        /tmp/RCU2020-09-29_10-51_508080961/logs/mds.log
   WebLogic Services                            Success        /tmp/RCU2020-09-29_10-51_508080961/logs/wls.log

   Repository Creation Utility - Create : Operation Completed
   [oracle@helper oracle]$
   ```

1. Run the following command to patch schemas in the database:

   {{% notice note %}}
   This command should be run if you are using an OIG image that contains OIG bundle patches. If using an OIG image without OIG bundle patches, then you can skip this step.
   {{% /notice %}}
   

   ```bash
   [oracle@helper oracle]$ /u01/oracle/oracle_common/modules/thirdparty/org.apache.ant/1.10.5.0.0/apache-ant-1.10.5/bin/ant \
   -f /u01/oracle/idm/server/setup/deploy-files/automation.xml \
   run-patched-sql-files \
   -logger org.apache.tools.ant.NoBannerLogger \
   -logfile /u01/oracle/idm/server/bin/patch_oim_wls.log \
   -DoperationsDB.host=$DB_HOST \
   -DoperationsDB.port=$DB_PORT \
   -DoperationsDB.serviceName=$DB_SERVICE \
   -DoperationsDB.user=${RCUPREFIX}_OIM \
   -DOIM.DBPassword=$RCU_SCHEMA_PWD \
   -Dojdbc=/u01/oracle/oracle_common/modules/oracle.jdbc/ojdbc8.jar
   ```
   
   The output will look similar to the following:
   
   ```
   Buildfile: /u01/oracle/idm/server/setup/deploy-files/automation.xml
   ```
   
1. Verify the database was patched successfully by viewing the `patch_oim_wls.log`:

   ```bash
   [oracle@helper oracle]$ cat /u01/oracle/idm/server/bin/patch_oim_wls.log
   ```
   
   The output should look similar to below:
   
   ```
   run-patched-sql-files:
      [sql] Executing resource: /u01/oracle/idm/server/db/oim/oracle/StoredProcedures/API/oim_role_mgmt_pkg_body.sql
      [sql] Executing resource: /u01/oracle/idm/server/db/oim/oracle/Upgrade/oim12cps4/list/oim12cps4_dml_pty_insert_sysprop_ssointg_grprecon_matching_rolename.sql
      [sql] Executing resource: /u01/oracle/idm/server/db/oim/oracle/Upgrade/oim12cps4/list/oim12cps4_dml_pty_insert_sysprop_oimadpswdpolicy.sql
      [sql] 3 of 3 SQL statements executed successfully

   BUILD SUCCESSFUL
   Total time: 1 second
   ```
   
   
1. Exit the helper bash shell by issuing the command `exit`.

### Preparing the environment for domain creation

In this section you prepare the environment for the OIG domain creation. This involves the following steps:

   1. Configure the operator for the domain namespace
   2. Create Kubernetes secrets for the domain and RCU
   3. Create a Kubernetes PV and PVC (Persistent Volume and Persistent Volume Claim)

#### Configure the operator for the domain namespace

1. Configure the WebLogic Kubernetes Operator to manage the domain in the domain namespace by running the following command:

   ```bash
   $ cd <work directory>/weblogic-kubernetes-operator
   $ helm upgrade --reuse-values --namespace <operator_namespace> --set "domainNamespaces={oigns}" --wait weblogic-kubernetes-operator kubernetes/charts/weblogic-operator
   ```

   For example:

   ```bash
   $ cd /scratch/OIGDockerK8S/weblogic-kubernetes-operator
   $ helm upgrade --reuse-values --namespace opns --set "domainNamespaces={oigns}" --wait weblogic-kubernetes-operator kubernetes/charts/weblogic-operator
   ```
	
   The output will look similar to the following:
	
   ```bash
   Release "weblogic-kubernetes-operator" has been upgraded. Happy Helming!
   NAME: weblogic-kubernetes-operator
   LAST DEPLOYED: Tue Sep 29 04:01:43 2020
   NAMESPACE: opns
   STATUS: deployed
   REVISION: 2
   TEST SUITE: None
   ```	

#### Creating Kubernetes secrets for the domain and RCU

1. Create a Kubernetes secret for the domain using the create-weblogic-credentials script in the same Kubernetes namespace as the domain:

   ```bash
   $ cd <work directory>/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-weblogic-domain-credentials
   $ ./create-weblogic-credentials.sh -u weblogic -p <pwd> -n <domain_namespace> -d <domain_uid> -s <kubernetes_domain_secret>
   ```

   where: 
	
   `-u weblogic` is the WebLogic username
	
   `-p <pwd>` is the password for the WebLogic user
	
   `-n <domain_namespace>` is the domain namespace
	
   `-d <domain_uid>` is the domain UID to be created. The default is domain1 if not specified
	
   `-s <kubernetes_domain_secret>` is the name you want to create for the secret for this namespace. The default is to use the domainUID if not specified
	
   For example:
	
   ```bash
   $ cd /scratch/OIGDockerK8S/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-weblogic-domain-credentials
   $ ./create-weblogic-credentials.sh -u weblogic -p <password> -n oigns -d governancedomain -s oig-domain-credentials
   ```

   The output will look similar to the following:
	
   ```bash
   secret/oig-domain-credentials created
   secret/oig-domain-credentials labeled
   The secret oig-domain-credentials has been successfully created in the oigns namespace.
   ```

1. Verify the secret is created using the following command:

   ```bash
   $ kubectl get secret <kubernetes_domain_secret> -o yaml -n <domain_namespace>
   ```

   For example:
	
   ```bash
   $ kubectl get secret oig-domain-credentials -o yaml -n oigns
   ```

   The output will look similar to the following:
	
   ```bash
   $ kubectl get secret oig-domain-credentials -o yaml -n oigns
   apiVersion: v1
   data:
     password: V2VsY29tZTE=
     username: d2VibG9naWM=
   kind: Secret
   metadata:
     creationTimestamp: "2020-09-29T11:04:44Z"
     labels:
       weblogic.domainName: governancedomain
       weblogic.domainUID: governancedomain
     managedFields:
     - apiVersion: v1
       fieldsType: FieldsV1
       fieldsV1:
         f:data:
           .: {}
           f:password: {}
           f:username: {}
         f:metadata:
           f:labels:
             .: {}
             f:weblogic.domainName: {}
             f:weblogic.domainUID: {}
         f:type: {}
       manager: kubectl
       operation: Update
       time: "2020-09-29T11:04:44Z"
     name: oig-domain-credentials
     namespace: oigns
     resourceVersion: "1249007"
     selfLink: /api/v1/namespaces/oigns/secrets/oig-domain-credentials
     uid: 4ade08f3-7b11-4bb0-9340-7304a2ef9b64
   type: Opaque
   ```

1. Create a Kubernetes secret for RCU in the same Kubernetes namespace as the domain, using the `create-weblogic-credentials.sh` script:

   ```bash
   $ cd <work directory>/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-rcu-credentials
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
   $ cd /scratch/OIGDockerK8S/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-rcu-credentials
   $ ./create-rcu-credentials.sh -u OIGK8S -p <password> -a sys -q <password> -d governancedomain -n oigns -s oig-rcu-credentials
   ```

   The output will look similar to the following:
	
   ```bash
   secret/oig-rcu-credentials created
   secret/oig-rcu-credentials labeled
   The secret oig-rcu-credentials has been successfully created in the oigns namespace.
   ```
	
1. Verify the secret is created using the following command:

   ```bash
   $ kubectl get secret <kubernetes_rcu_secret> -o yaml -n <domain_namespace>
   ```
	
   For example:
	
   ```bash
   $ kubectl get secret oig-rcu-credentials -o yaml -n oigns
   ```
	
   The output will look similar to the following:
	
   ```bash
   apiVersion: v1
   data:
     password: V2VsY29tZTE=
     sys_password: V2VsY29tZTE=
     sys_username: c3lz
     username: T0lHSzhT
   kind: Secret
   metadata:
      creationTimestamp: "2020-09-29T11:18:45Z"
     labels:
       weblogic.domainName: governancedomain
       weblogic.domainUID: governancedomain
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
         f:metadata:
           f:labels:
             .: {}
             f:weblogic.domainName: {}
             f:weblogic.domainUID: {}
         f:type: {}
       manager: kubectl
       operation: Update
       time: "2020-09-29T11:18:45Z"
     name: oig-rcu-credentials
     namespace: oigns
     resourceVersion: "1251020"
     selfLink: /api/v1/namespaces/oigns/secrets/oig-rcu-credentials
     uid: aee4213e-ffe2-45a6-9b96-11c4e88d12f2
   type: Opaque
   ```

### Create a Kubernetes persistent volume and persistent volume claim
  
In the Kubernetes domain namespace created above, create the persistent volume (PV) and persistent volume claim (PVC)  by running the `create-pv-pvc.sh` script.

1. Make a backup copy of the `create-pv-pvc-inputs.yaml` file and create required directories:
   
   ```bash
   $ cd <work directory>/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-weblogic-domain-pv-pvc
   $ cp create-pv-pvc-inputs.yaml create-pv-pvc-inputs.yaml.orig
   $ mkdir output
   $ mkdir -p /<work directory>/governancedomainpv
   $ chmod -R 777 /<work directory>/governancedomainpv
   ```

   For example:
	
   ```bash
   $ cd /scratch/OIGDockerK8S/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-weblogic-domain-pv-pvc
   $ cp create-pv-pvc-inputs.yaml create-pv-pvc-inputs.yaml.orig
   $ mkdir output
   $ mkdir -p /scratch/OIGDockerK8S/governancedomainpv
   $ chmod -R 777 /scratch/OIGDockerK8S/governancedomainpv
   ```
   
   **Note**: The persistent volume directory needs to be accessible to both the master and worker node(s) via NFS. Make sure this path has **full** access permissions, and that the folder is empty. In this example `/scratch/OIGDockerK8S/governancedomainpv` is accessible from all nodes via NFS. 
   
1. On the master node run the following command to ensure it is possible to read and write to the persistent volume:

   ```bash 
   cd /<work directory>/governancedomainpv
   touch file.txt
   ls filemaster.txt
   ```
   
   For example:
   
   ```bash
   cd /scratch/OIGDockerK8S/governancedomainpv
   touch filemaster.txt
   ls filemaster.txt
   ```
   
   On the first worker node run the following to ensure it is possible to read and write to the persistent volume:
   
   ```bash
   cd /scratch/OIGDockerK8S/governancedomainpv
   ls filemaster.txt
   touch fileworker1.txt
   ls fileworker1.txt
   ```
   
   Repeat the above for any other worker nodes e.g fileworker2.txt etc. Once proven that it's possible to read and write from each node to the persistent volume, delete the files created.
   
1. Edit the `create-pv-pvc-inputs.yaml` file and update the following parameters to reflect your settings. Save the file when complete:

   ```bash
   baseName: <domain>
   domainUID: <domain_uid>
   namespace: <domain_namespace>
   weblogicDomainStorageType: NFS
   weblogicDomainStorageNFSServer: <nfs_server>
   weblogicDomainStoragePath: <physical_path_of_persistent_storage>
   weblogicDomainStorageSize: 10Gi
   ```
    
   For example:
	
   ```bash
   # The base name of the pv and pvc
   baseName: domain

   # Unique ID identifying a domain.
   # If left empty, the generated pv can be shared by multiple domains
   # This ID must not contain an underscope ("_"), and must be lowercase and unique across all domains in a Kubernetes cluster.
   domainUID: governancedomain

   # Name of the namespace for the persistent volume claim
   namespace: oigns

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
   weblogicDomainStoragePath: /scratch/OIGDockerK8S/governancedomainpv
     
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
	
   ```bash
   Input parameters being used
   export version="create-weblogic-sample-domain-pv-pvc-inputs-v1"
   export baseName="domain"
   export domainUID="governancedomain"
   export namespace="oigns"
   export weblogicDomainStorageType="NFS"
   export weblogicDomainStorageNFSServer="mynfsserver"
   export weblogicDomainStoragePath="/scratch/OIGDockerK8S/governancedomainpv"
   export weblogicDomainStorageReclaimPolicy="Retain"
   export weblogicDomainStorageSize="10Gi"

   Generating output/pv-pvcs/governancedomain-domain-pv.yaml
   Generating output/pv-pvcs/governancedomain-domain-pvc.yaml
   The following files were generated:
     output/pv-pvcs/governancedomain-domain-pv.yaml
     output/pv-pvcs/governancedomain-domain-pvc.yaml

   Completed
   ```

1. Run the following to show the files are created:

   ```bash
   $ ls output/pv-pvcs
   create-pv-pvc-inputs.yaml  governancedomain-domain-pvc.yaml  governancedomain-domain-pv.yaml
   ```
1. Run the following `kubectl` command to create the PV and PVC in the domain namespace:

   ```bash
   $ kubectl create -f output/pv-pvcs/governancedomain-domain-pv.yaml -n <domain_namespace>
   $ kubectl create -f output/pv-pvcs/governancedomain-domain-pvc.yaml -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl create -f output/pv-pvcs/governancedomain-domain-pv.yaml -n oigns
   $ kubectl create -f output/pv-pvcs/governancedomain-domain-pvc.yaml -n oigns
   ```

   The output will look similar to the following:
   
   ```bash
   persistentvolume/governancedomain-domain-pv created
   persistentvolumeclaim/governancedomain-domain-pvc created
   ```
   
1. Run the following commands to verify the PV and PVC were created successfully:

   ```bash
   $ kubectl describe pv <pv_name> 
   $ kubectl describe pvc <pvc_name> -n <domain_namespace>
   ```
	
   For example:
   
   ```bash
   $ kubectl describe pv governancedomain-domain-pv 
   $ kubectl describe pvc governancedomain-domain-pvc -n oigns
   ```
   
   The output will look similar to the following:

   ```bash
   $ kubectl describe pv governancedomain-domain-pv
   
   Name:            governancedomain-domain-pv
   Labels:          weblogic.domainUID=governancedomain
   Annotations:     pv.kubernetes.io/bound-by-controller: yes
   Finalizers:      [kubernetes.io/pv-protection]
   StorageClass:    governancedomain-domain-storage-class
   Status:          Bound
   Claim:           oigns/governancedomain-domain-pvc
   Reclaim Policy:  Retain
   Access Modes:    RWX
   VolumeMode:      Filesystem
   Capacity:        10Gi
   Node Affinity:   <none>
   Message:
   Source:
       Type:      NFS (an NFS mount that lasts the lifetime of a pod)
       Server:    mynfsserver
       Path:      /scratch/OIGDockerK8S/governancedomainpv
       ReadOnly:  false
   Events:        <none>
   ```
   
   ```bash
   $ kubectl describe pvc governancedomain-domain-pvc -n oigns

   Name:          governancedomain-domain-pvc
   Namespace:     oigns
   StorageClass:  governancedomain-domain-storage-class
   Status:        Bound
   Volume:        governancedomain-domain-pv
   Labels:        weblogic.domainUID=governancedomain
   Annotations:   pv.kubernetes.io/bind-completed: yes
                  pv.kubernetes.io/bound-by-controller: yes
   Finalizers:    [kubernetes.io/pvc-protection]
   Capacity:      10Gi
   Access Modes:  RWX
   VolumeMode:    Filesystem
   Mounted By:    <none>
   Events:        <none>
   ```
   
   You are now ready to create the OIG domain as per [Create OIG Domains](../create-oig-domains/)
