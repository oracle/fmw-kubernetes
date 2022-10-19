+++
title = "Create OIG domains"
weight = 4
pre = "<b>4. </b>"
description = "Sample for creating an OIG domain home on an existing PV or PVC, and the domain resource YAML file for deploying the generated OIG domain."
+++


1. [Introduction](#introduction)
1. [Prerequisites](#prerequisites)
1. [Prepare the create domain script](#prepare-the-create-domain-script)
1. [Run the create domain script](#run-the-create-domain-script)

    a. [Generate the create domain script](#generate-the-create-domain-script)
	
	b. [Setting the OIM server memory parameters](#setting-the-oim-server-memory-parameters)
	
	c. [Run the create domain scripts](#run-the-create-domain-scripts)
	
1. [Verify the results](#verify-the-results)

    a. [Verify the domain, pods and services](#verify-the-domain-pods-and-services)
	
	b. [Verify the domain](#verify-the-domain)
	
	c. [Verify the pods](#verify-the-pods)
	
### Introduction

The OIG deployment scripts demonstrate the creation of an OIG domain home on an existing Kubernetes persistent volume (PV) and persistent volume claim (PVC). The scripts also generate the domain YAML file, which can then be used to start the Kubernetes artifacts of the corresponding domain.

### Prerequisites

Before you begin, perform the following steps:

1. Review the [Domain resource](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/domain-resource) documentation.
1. Ensure that you have executed all the preliminary steps documented in [Prepare your environment]({{< relref "/oig/prepare-your-environment" >}}).
1. Ensure that the database is up and running.

### Prepare the create domain script

The sample scripts for Oracle Identity Governance domain deployment are available at `$WORKDIR/kubernetes/create-oim-domain`.

1. Make a copy of the `create-domain-inputs.yaml` file:

   ```bash
   $ cd $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv
   $ cp create-domain-inputs.yaml create-domain-inputs.yaml.orig   
   ```

1. Edit the `create-domain-inputs.yaml` and modify the following parameters. Save the file when complete:   

   ```
   domainUID: <domain_uid>
   domainHome: /u01/oracle/user_projects/domains/<domain_uid>
   image: <image_name>
   imagePullSecretName: <container_registry_secret>
   weblogicCredentialsSecretName: <kubernetes_domain_secret>
   logHome: /u01/oracle/user_projects/domains/logs/<domain_id>
   namespace: <domain_namespace>
   persistentVolumeClaimName: <pvc_name>
   rcuSchemaPrefix: <rcu_prefix>
   rcuDatabaseURL: <rcu_db_host>:<rcu_db_port>/<rcu_db_service_name>
   rcuCredentialsSecret: <kubernetes_rcu_secret>
   frontEndHost: <front_end_hostname>
   frontEndPort: <front_end_port>
   ```

   For example:

   ```
   domainUID: governancedomain
   domainHome: /u01/oracle/user_projects/domains/governancedomain
   image: container-registry.oracle.com/middleware/oig_cpu:12.2.1.4-jdk8-ol7-<October'22>
   imagePullSecretName: orclcred
   weblogicCredentialsSecretName: oig-domain-credentials
   logHome: /u01/oracle/user_projects/domains/logs/governancedomain
   namespace: oigns
   persistentVolumeClaimName: governancedomain-domain-pvc
   rcuSchemaPrefix: OIGK8S
   rcuDatabaseURL: mydatabasehost.example.com:1521/orcl.example.com
   rcuCredentialsSecret: oig-rcu-credentials
   frontEndHost: example.com
   frontEndPort: 14100
   ```
   
   **Note**: For now `frontEndHost` and `front_end_port` should be set to `example.com` and `14100` respectively. These values will be changed to the correct values in post installation tasks in [Set OIMFrontendURL using MBeans](../post-install-config).

A full list of parameters in the `create-domain-inputs.yaml` file are shown below:

| Parameter | Definition | Default |
| --- | --- | --- |
| `adminPort` | Port number for the Administration Server inside the Kubernetes cluster. | `7001` |
| `adminNodePort` | Port number of the Administration Server outside the Kubernetes cluster. | `30701` |
| `adminServerName` | Name of the Administration Server. | `AdminServer` |
| `clusterName` | Name of the WebLogic cluster instance to generate for the domain. By default the cluster name is `oimcluster` for the OIG domain. | `oimcluster` |
| `configuredManagedServerCount` | Number of Managed Server instances to generate for the domain. | `5` |
| `createDomainFilesDir` | Directory on the host machine to locate all the files to create a WebLogic domain, including the script that is specified in the `createDomainScriptName` property. By default, this directory is set to the relative path `wlst`, and the create script will use the built-in WLST offline scripts in the `wlst` directory to create the WebLogic domain. It can also be set to the relative path `wdt`, and then the built-in WDT scripts will be used instead. An absolute path is also supported to point to an arbitrary directory in the file system. The built-in scripts can be replaced by the user-provided scripts or model files as long as those files are in the specified directory. Files in this directory are put into a Kubernetes config map, which in turn is mounted to the `createDomainScriptsMountPath`, so that the Kubernetes pod can use the scripts and supporting files to create a domain home. | `wlst` |
| `createDomainScriptsMountPath` | Mount path where the create domain scripts are located inside a pod. The `create-domain.sh` script creates a Kubernetes job to run the script (specified in the `createDomainScriptName` property) in a Kubernetes pod to create a domain home. Files in the `createDomainFilesDir` directory are mounted to this location in the pod, so that the Kubernetes pod can use the scripts and supporting files to create a domain home. | `/u01/weblogic` |
| `createDomainScriptName` | Script that the create domain script uses to create a WebLogic domain. The `create-domain.sh` script creates a Kubernetes job to run this script to create a domain home. The script is located in the in-pod directory that is specified in the `createDomainScriptsMountPath` property. If you need to provide your own scripts to create the domain home, instead of using the built-it scripts, you must use this property to set the name of the script that you want the create domain job to run. | `create-domain-job.sh` |
| `domainHome` | Home directory of the OIG domain. If not specified, the value is derived from the `domainUID` as `/shared/domains/<domainUID>`. | `/u01/oracle/user_projects/domains/oimcluster` |
| `domainPVMountPath` | Mount path of the domain persistent volume. | `/u01/oracle/user_projects/domains` |
| `domainUID` | Unique ID that will be used to identify this particular domain. Used as the name of the generated WebLogic domain as well as the name of the Kubernetes domain resource. This ID must be unique across all domains in a Kubernetes cluster. This ID cannot contain any character that is not valid in a Kubernetes service name. | `oimcluster` |
| `exposeAdminNodePort` | Boolean indicating if the Administration Server is exposed outside of the Kubernetes cluster. | `false` |
| `exposeAdminT3Channel` | Boolean indicating if the T3 administrative channel is exposed outside the Kubernetes cluster. | `true` |
| `image` | OIG container image. The operator requires OIG 12.2.1.4. Refer to [OIG domains]({{< relref "/oig/prepare-your-environment#obtain-the-container-image" >}}) for details on how to obtain or create the image. | `oracle/oig:12.2.1.4.0` |
| `imagePullPolicy` | WebLogic container image pull policy. Legal values are `IfNotPresent`, `Always`, or `Never` | `IfNotPresent` |
| `imagePullSecretName` | Name of the Kubernetes secret to access the container registry to pull the OIG container image. The presence of the secret will be validated when this parameter is specified. |  |
| `includeServerOutInPodLog` | Boolean indicating whether to include the server .out to the pod's stdout. | `true` |
| `initialManagedServerReplicas` | Number of Managed Servers to initially start for the domain. | `2` |
| `javaOptions` | Java options for starting the Administration Server and Managed Servers. A Java option can have references to one or more of the following pre-defined variables to obtain WebLogic domain information: `$(DOMAIN_NAME)`, `$(DOMAIN_HOME)`, `$(ADMIN_NAME)`, `$(ADMIN_PORT)`, and `$(SERVER_NAME)`. | `-Dweblogic.StdoutDebugEnabled=false` |
| `logHome` | The in-pod location for the domain log, server logs, server out, and Node Manager log files. If not specified, the value is derived from the `domainUID` as `/shared/logs/<domainUID>`. | `/u01/oracle/user_projects/domains/logs/oimcluster` |
| `managedServerNameBase` | Base string used to generate Managed Server names. | `oim_server` |
| `managedServerPort` | Port number for each Managed Server. | `8001` |
| `namespace` | Kubernetes namespace in which to create the domain. | `oimcluster` |
| `persistentVolumeClaimName` | Name of the persistent volume claim created to host the domain home. If not specified, the value is derived from the `domainUID` as `<domainUID>-weblogic-sample-pvc`. | `oimcluster-domain-pvc` |
| `productionModeEnabled` | Boolean indicating if production mode is enabled for the domain. | `true` |
| `serverStartPolicy` | Determines which WebLogic Server instances will be started. Legal values are `NEVER`, `IF_NEEDED`, `ADMIN_ONLY`. | `IF_NEEDED` |
| `t3ChannelPort` | Port for the T3 channel of the NetworkAccessPoint. | `30012` |
| `t3PublicAddress` | Public address for the T3 channel.  This should be set to the public address of the Kubernetes cluster.  This would typically be a load balancer address. <p/>For development environments only: In a single server (all-in-one) Kubernetes deployment, this may be set to the address of the master, or at the very least, it must be set to the address of one of the worker nodes. | If not provided, the script will attempt to set it to the IP address of the Kubernetes cluster |
| `weblogicCredentialsSecretName` | Name of the Kubernetes secret for the Administration Server's user name and password. If not specified, then the value is derived from the `domainUID` as `<domainUID>-weblogic-credentials`. | `oimcluster-domain-credentials` |
| `weblogicImagePullSecretName` | Name of the Kubernetes secret for the container registry, used to pull the WebLogic Server image. |   |
| `serverPodCpuRequest`, `serverPodMemoryRequest`, `serverPodCpuCLimit`, `serverPodMemoryLimit` |  The maximum amount of compute resources allowed, and minimum amount of compute resources required, for each server pod. Please refer to the Kubernetes documentation on `Managing Compute Resources for Containers` for details. | Resource requests and resource limits are not specified. |
| `rcuSchemaPrefix` | The schema prefix to use in the database, for example `OIGK8S`.  You may wish to make this the same as the domainUID in order to simplify matching domains to their RCU schemas. | `OIGK8S` |
| `rcuDatabaseURL` | The database URL. | `oracle-db.default.svc.cluster.local:1521/devpdb.k8s` |
| `rcuCredentialsSecret` | The Kubernetes secret containing the database credentials. | `oimcluster-rcu-credentials` |
| `frontEndHost` | The entry point URL for the OIM. | Not set |
| `frontEndPort` | The entry point port for the OIM. | Not set |

Note that the names of the Kubernetes resources in the generated YAML files may be formed with the
value of some of the properties specified in the `create-inputs.yaml` file. Those properties include
the `adminServerName`, `clusterName` and `managedServerNameBase`. If those values contain any
characters that are invalid in a Kubernetes service name, those characters are converted to
valid values in the generated YAML files. For example, an uppercase letter is converted to a
lowercase letter and an underscore `("_")` is converted to a hyphen `("-")`.

The sample demonstrates how to create an OIG domain home and associated Kubernetes resources for a domain
that has one cluster only. In addition, the sample provides the capability for users to supply their own scripts
to create the domain home for other use cases. The generated domain YAML file could also be modified to cover more use cases.

### Run the create domain script

#### Generate the create domain script

1. Run the create domain script, specifying your inputs file and an output directory to store the
generated artifacts:

   ```bash
   $ cd $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv
   $ mkdir output
   $ ./create-domain.sh -i create-domain-inputs.yaml -o /<path to output-directory>
   ```

   For example:
   
   ```bash
   $ cd $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv
   $ mkdir output
   $ ./create-domain.sh -i create-domain-inputs.yaml -o output
   ```
   
   The output will look similar to the following:
   
   ```
   Input parameters being used
   export version="create-weblogic-sample-domain-inputs-v1"
   export adminPort="7001"
   export adminServerName="AdminServer"
   export domainUID="governancedomain"
   export domainHome="/u01/oracle/user_projects/domains/governancedomain"
   export serverStartPolicy="IF_NEEDED"
   export clusterName="oim_cluster"
   export configuredManagedServerCount="5"
   export initialManagedServerReplicas="1"
   export managedServerNameBase="oim_server"
   export managedServerPort="14000"
   export image="container-registry.oracle.com/middleware/oig_cpu:12.2.1.4-jdk8-ol7-<October'22>"
   export imagePullPolicy="IfNotPresent"
   export imagePullSecretName="orclcred"
   export productionModeEnabled="true"
   export weblogicCredentialsSecretName="oig-domain-credentials"
   export includeServerOutInPodLog="true"
   export logHome="/u01/oracle/user_projects/domains/logs/governancedomain"
   export t3ChannelPort="30012"
   export exposeAdminT3Channel="false"
   export adminNodePort="30701"
   export exposeAdminNodePort="false"
   export namespace="oigns"
   javaOptions=-Dweblogic.StdoutDebugEnabled=false
   export persistentVolumeClaimName="governancedomain-domain-pvc"
   export domainPVMountPath="/u01/oracle/user_projects/domains"
   export createDomainScriptsMountPath="/u01/weblogic"
   export createDomainScriptName="create-domain-job.sh"
   export createDomainFilesDir="wlst"
   export rcuSchemaPrefix="OIGK8S"
   export rcuDatabaseURL="mydatabasehost.example.com:1521/orcl.example.com"
   export rcuCredentialsSecret="oig-rcu-credentials"
   export frontEndHost="example.com"
   export frontEndPort="14100"


   Generating output/weblogic-domains/governancedomain/create-domain-job.yaml
   Generating output/weblogic-domains/governancedomain/delete-domain-job.yaml
   Generating output/weblogic-domains/governancedomain/domain.yaml
   Checking to see if the secret governancedomain-domain-credentials exists in namespace oigns
   configmap/governancedomain-create-fmw-infra-sample-domain-job-cm created
   Checking the configmap governancedomain-create-fmw-infra-sample-domain-job-cm was created
   configmap/governancedomain-create-fmw-infra-sample-domain-job-cm labeled
   Checking if object type job with name governancedomain-create-fmw-infra-sample-domain-job exists
   No resources found in oigns namespace.
   Creating the domain by creating the job output/weblogic-domains/governancedomain/create-domain-job.yaml
   job.batch/governancedomain-create-fmw-infra-sample-domain-job created
   Waiting for the job to complete...
   status on iteration 1 of 40
   pod governancedomain-create-fmw-infra-sample-domain-job-8cww8 status is Running
   status on iteration 2 of 40
   pod governancedomain-create-fmw-infra-sample-domain-job-8cww8 status is Running
   status on iteration 3 of 40
   pod governancedomain-create-fmw-infra-sample-domain-job-8cww8 status is Running
   status on iteration 4 of 40
   pod governancedomain-create-fmw-infra-sample-domain-job-8cww8 status is Running
   status on iteration 5 of 40
   pod governancedomain-create-fmw-infra-sample-domain-job-8cww8 status is Running
   status on iteration 6 of 40
   pod governancedomain-create-fmw-infra-sample-domain-job-8cww8 status is Running
   status on iteration 7 of 40
   pod governancedomain-create-fmw-infra-sample-domain-job-8cww8 status is Running
   status on iteration 8 of 40
   pod governancedomain-create-fmw-infra-sample-domain-job-8cww8 status is Running
   status on iteration 9 of 40
   pod governancedomain-create-fmw-infra-sample-domain-job-8cww8 status is Running
   status on iteration 10 of 40
   pod governancedomain-create-fmw-infra-sample-domain-job-8cww8 status is Running
   status on iteration 11 of 40
   pod governancedomain-create-fmw-infra-sample-domain-job-8cww8 status is Completed

   Domain governancedomain was created and will be started by the WebLogic Kubernetes Operator

   The following files were generated:
     output/weblogic-domains/governancedomain/create-domain-inputs.yaml
     output/weblogic-domains/governancedomain/create-domain-job.yaml
     output/weblogic-domains/governancedomain/domain.yaml
   sed

   Completed
   $
   ```

   **Note**: If the create domain script creation fails, refer to the [Troubleshooting](../troubleshooting) section.

#### Setting the OIM server memory parameters

1. Navigate to the `/output/weblogic-domains/<domain_uid>` directory:

   ```bash
   $ cd $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/output/weblogic-domains/<domain_uid>
   ```
   
   For example:

   ```bash
   $ cd $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/output/weblogic-domains/governancedomain
   ```
   
1. Edit the `domain_oim_soa.yaml` and locate the section of the file starting with: `- clusterName: oim_cluster`. Immediately after the line: `topologyKey: "kubernetes.io/hostname"`, add the following lines:

   ```
   env:
   - name: USER_MEM_ARGS
     value: "-Djava.security.egd=file:/dev/./urandom -Xms2408m -Xmx8192m"
   ```
   
   The file should looks as follows:
   
   ```
   - clusterName: oim_cluster
     serverService:
       precreateService: true
     serverStartState: "RUNNING"
     serverPod:
       # Instructs Kubernetes scheduler to prefer nodes for new cluster members where there are not
       # already members of the same cluster.
       affinity:
         podAntiAffinity:
           preferredDuringSchedulingIgnoredDuringExecution:
             - weight: 100
               podAffinityTerm:
                 labelSelector:
                   matchExpressions:
                     - key: "weblogic.clusterName"
                       operator: In
                       values:
                         - $(CLUSTER_NAME)
                 topologyKey: "kubernetes.io/hostname"
       env:
       - name: USER_MEM_ARGS
         value: "-Djava.security.egd=file:/dev/./urandom -Xms2408m -Xmx8192m"
     replicas: 1
   ...
   ```


#### Run the create domain scripts

1. Create the Kubernetes resource using the following command:

   ```bash
   $ cd $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/output/weblogic-domains/<domain_uid>
   $ kubectl apply -f domain.yaml
   ```

   For example:

   ```bash
   $ cd $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/output/weblogic-domains/governancedomain
   $ kubectl apply -f domain.yaml
   ```

   The output will look similar to the following:
   
   ```
   domain.weblogic.oracle/governancedomain created
   ```

1. Run the following command to view the status of the OIG pods:

   ```bash
   $ kubectl get pods -n oigns
   ```
   
   The output will initially look similar to the following:
   
   ```
   NAME                                                        READY   STATUS      RESTARTS   AGE
   helper                                                      1/1     Running     0          3h30m
   governancedomain-create-fmw-infra-sample-domain-job-8cww8   0/1     Completed   0          27m
   governancedomain-introspect-domain-job-p4brt                1/1     Running     0          6s
   ```
   
   The `introspect-domain-job` pod will be displayed first. Run the command again after several minutes and check to see that the Administration Server and SOA Server are both started. When started they should have `STATUS` = `Running` and `READY` = `1/1`.
   
   ```
   NAME                                                        READY   STATUS      RESTARTS   AGE
   helper                                                      1/1     Running     0          3h38m
   governancedomain-adminserver                                1/1     Running     0          7m30s
   governancedomain-create-fmw-infra-sample-domain-job-8cww8   0/1     Completed   0          35m
   governancedomain-soa-server1                                1/1     Running     0          4m
   ```

   **Note**: It will take several minutes before all the pods listed above show. When a pod has a `STATUS` of `0/1` the pod is started but the OIG server associated with it is currently starting. While the pods are starting you can check the startup status in the pod logs, by running the following command:
   
   ```bash
   $ kubectl logs governancedomain-adminserver -n oigns
   $ kubectl logs governancedomain-soa-server1 -n oigns
   ```
   
   
1. Once both pods are running, start the OIM Server using the following command:

   ```bash
   $ cd $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/output/weblogic-domains/governancedomain/
   $ kubectl apply -f domain_oim_soa.yaml
   ```

   For example:

   ```bash
   $ cd $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/output/weblogic-domains/governancedomain/
   $ kubectl apply -f domain_oim_soa.yaml
   ```

   The output will look similar to the following:

   ```
   domain.weblogic.oracle/governancedomain configured
   ```

### Verify the results

#### Verify the domain, pods and services

1. Verify the domain, servers pods and services are created and in the `READY` state with a `STATUS` of `1/1`, by running the following command:

   ```bash
   $ kubectl get all,domains -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl get all,domains -n oigns
   ```
   
   The output will look similar to the following:

   ```
   NAME                                                            READY   STATUS      RESTARTS   AGE
   pod/governancedomain-adminserver                                1/1     Running     0          16m
   pod/governancedomain-create-fmw-infra-sample-domain-job-8cww8   0/1     Completed   0          36m
   pod/governancedomain-oim-server1                                1/1     Running     0          5m57s
   pod/governancedomain-soa-server1                                1/1     Running     0          13m
   pod/helper                                                      1/1     Running     0          3h40m

   NAME                                           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)     AGE
   service/governancedomain-adminserver           ClusterIP   None             <none>        7001/TCP    16m
   service/governancedomain-cluster-oim-cluster   ClusterIP   10.97.121.159    <none>        14000/TCP   13m
   service/governancedomain-cluster-soa-cluster   ClusterIP   10.111.231.242   <none>        8001/TCP    13m
   service/governancedomain-oim-server1           ClusterIP   None             <none>        14000/TCP   5m57s
   service/governancedomain-oim-server2           ClusterIP   10.108.139.30    <none>        14000/TCP   5m57s
   service/governancedomain-oim-server3           ClusterIP   10.97.170.104    <none>        14000/TCP   5m57s
   service/governancedomain-oim-server4           ClusterIP   10.99.82.214     <none>        14000/TCP   5m57s
   service/governancedomain-oim-server5           ClusterIP   10.98.75.228     <none>        14000/TCP   5m57s
   service/governancedomain-soa-server1           ClusterIP   None             <none>        8001/TCP    13m
   service/governancedomain-soa-server2           ClusterIP   10.107.232.220   <none>        8001/TCP    13m
   service/governancedomain-soa-server3           ClusterIP   10.108.203.6     <none>        8001/TCP    13m
   service/governancedomain-soa-server4           ClusterIP   10.96.178.0      <none>        8001/TCP    13m
   service/governancedomain-soa-server5           ClusterIP   10.107.83.62     <none>        8001/TCP    13m

   NAME                                                            COMPLETIONS   DURATION   AGE
   job.batch/governancedomain-create-fmw-infra-sample-domain-job   1/1           5m30s      36m

   NAME                                AGE
   domain.weblogic.oracle/governancedomain   17m
   ```
   
   **Note**: It will take several minutes before all the services listed above show. While the `governancedomain-oim-server1` pod has a `STATUS` of `0/1` the pod is started but the OIG server associated with it is currently starting. While the pod is starting you can check the startup status in the pod logs, by running the following command:
   
   ```
   $ kubectl logs governancedomain-oim-server1 -n oigns
   ```

The default domain created by the script has the following characteristics:

  * An Administration Server named `AdminServer` listening on port `7001`.
  * A configured OIG cluster named `oig_cluster` of size 5.
  * A configured SOA cluster named `soa_cluster` of size 5.
  * One started OIG managed Server, named `oim_server1`, listening on port `14000`.
  * One started SOA managed Server, named `soa_server1`, listening on port `8001`.
  * Log files that are located in `<persistent_volume>/logs/<domainUID>`


#### Verify the domain

1. Run the following command to describe the domain: 

   ```bash
   $ kubectl describe domain <domain_uid> -n <namespace>
   ```

   For example:
   
   ```bash
   $ kubectl describe domain governancedomain -n oigns
   ```

   The output will look similar to the following:

   ```
   Name:         governancedomain
   Namespace:    oigns
   Labels:       weblogic.domainUID=governancedomain
   Annotations:  <none>
   API Version:  weblogic.oracle/v8
   Kind:         Domain
   Metadata:
     Creation Timestamp:  <DATE>
     Generation:          2
     Managed Fields:
       API Version:  weblogic.oracle/v8
       Fields Type:  FieldsV1
       fieldsV1:
         f:metadata:
           f:annotations:
             .:
             f:kubectl.kubernetes.io/last-applied-configuration:
           f:labels:
             .:
             f:weblogic.domainUID:
       Manager:      kubectl-client-side-apply
       Operation:    Update
       Time:         <DATE>
       API Version:  weblogic.oracle/v8
       Fields Type:  FieldsV1
       fieldsV1:
         f:status:
           .:
           f:clusters:
           f:conditions:
           f:introspectJobFailureCount:
           f:servers:
           f:startTime:
       Manager:         Kubernetes Java Client
       Operation:       Update
       Time:            <DATE>
     Resource Version:  383381
     UID:               ea95c549-c414-42a6-8de4-beaf1204872e
   Spec:
     Admin Server:
       Server Pod:
         Env:
           Name:            USER_MEM_ARGS
           Value:           -Djava.security.egd=file:/dev/./urandom -Xms512m -Xmx1024m
       Server Start State:  RUNNING
     Clusters:
       Cluster Name:  soa_cluster
       Replicas:      1
       Server Pod:
         Affinity:
           Pod Anti Affinity:
             Preferred During Scheduling Ignored During Execution:
               Pod Affinity Term:
                 Label Selector:
                   Match Expressions:
                     Key:       weblogic.clusterName
                     Operator:  In
                     Values:
                       $(CLUSTER_NAME)
                 Topology Key:  kubernetes.io/hostname
               Weight:          100
       Server Service:
         Precreate Service:  true
       Server Start State:   RUNNING
       Cluster Name:         oim_cluster
       Replicas:             1
       Server Pod:
         Affinity:
           Pod Anti Affinity:
             Preferred During Scheduling Ignored During Execution:
               Pod Affinity Term:
                 Label Selector:
                   Match Expressions:
                     Key:       weblogic.clusterName
                     Operator:  In
                     Values:
                       $(CLUSTER_NAME)
                 Topology Key:  kubernetes.io/hostname
               Weight:          100
         Env:
           Name:   USER_MEM_ARGS
           Value:  -Djava.security.egd=file:/dev/./urandom -Xms2408m -Xmx8192m
       Server Service:
         Precreate Service:          true
       Server Start State:           RUNNING
     Data Home:
     Domain Home:                    /u01/oracle/user_projects/domains/governancedomain
     Domain Home Source Type:        PersistentVolume
     Http Access Log In Log Home:    true
     Image:                          container-registry.oracle.com/middleware/oig_cpu:12.2.1.4-jdk8-ol7-<October'22>
     Image Pull Policy:              IfNotPresent
	 Image Pull Secrets:
       Name:                         orclcred
     Include Server Out In Pod Log:  true
     Log Home:                       /u01/oracle/user_projects/domains/logs/governancedomain
     Log Home Enabled:               true
     Server Pod:
       Env:
         Name:   JAVA_OPTIONS
         Value:  -Dweblogic.StdoutDebugEnabled=false
         Name:   USER_MEM_ARGS
         Value:  -Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx1024m
       Volume Mounts:
         Mount Path:  /u01/oracle/user_projects/domains
         Name:        weblogic-domain-storage-volume
       Volumes:
         Name:  weblogic-domain-storage-volume
         Persistent Volume Claim:
           Claim Name:     governancedomain-domain-pvc
     Server Start Policy:  IF_NEEDED
     Web Logic Credentials Secret:
       Name:  oig-domain-credentials
   Status:
     Clusters:
       Cluster Name:      oim_cluster
       Maximum Replicas:  5
       Minimum Replicas:  0
       Ready Replicas:    1
       Replicas:          1
       Replicas Goal:     1
       Cluster Name:      soa_cluster
       Maximum Replicas:  5
       Minimum Replicas:  0
       Ready Replicas:    1
       Replicas:          1
       Replicas Goal:     1
     Conditions:
       Last Transition Time:        <DATE>
       Reason:                      ServersReady
       Status:                      True
       Type:                        Available
     Introspect Job Failure Count:  0
     Servers:
       Desired State:  RUNNING
       Health:
         Activation Time:  <DATE>
         Overall Health:   ok
         Subsystems:
           Subsystem Name:  ServerRuntime
           Symptoms:
       Node Name:      10.250.40.59
       Server Name:    AdminServer
       State:          RUNNING
       Cluster Name:   oim_cluster
       Desired State:  RUNNING
       Health:
         Activation Time:  <DATE>
         Overall Health:   ok
         Subsystems:
           Subsystem Name:  ServerRuntime
           Symptoms:
       Node Name:      10.250.40.59
       Server Name:    oim_server1
       State:          RUNNING
       Cluster Name:   oim_cluster
       Desired State:  SHUTDOWN
       Server Name:    oim_server2
       Cluster Name:   oim_cluster
       Desired State:  SHUTDOWN
       Server Name:    oim_server3
       Cluster Name:   oim_cluster
       Desired State:  SHUTDOWN
       Server Name:    oim_server4
       Cluster Name:   oim_cluster
       Desired State:  SHUTDOWN
       Server Name:    oim_server5
       Cluster Name:   soa_cluster
       Desired State:  RUNNING
       Health:
         Activation Time:  <DATE>
         Overall Health:   ok
         Subsystems:
           Subsystem Name:  ServerRuntime
           Symptoms:
       Node Name:      10.250.40.59
       Server Name:    soa_server1
       State:          RUNNING
       Cluster Name:   soa_cluster
       Desired State:  SHUTDOWN
       Server Name:    soa_server2
       Cluster Name:   soa_cluster
       Desired State:  SHUTDOWN
       Server Name:    soa_server3
       Cluster Name:   soa_cluster
       Desired State:  SHUTDOWN
       Server Name:    soa_server4
       Cluster Name:   soa_cluster
       Desired State:  SHUTDOWN
       Server Name:    soa_server5
     Start Time:       <DATE>
   Events:
     Type    Reason                     Age                From               Message
     ----    ------                     ----               ----               -------
     Normal  DomainCreated              19m                weblogic.operator  Domain resource governancedomain was created
     Normal  DomainProcessingCompleted  12m                weblogic.operator  Successfully completed processing domain resource governancedomain
     Normal  DomainChanged              10m                weblogic.operator  Domain resource governancedomain was changed
     Normal  DomainProcessingStarting   10m (x2 over 19m)  weblogic.operator  Creating or updating Kubernetes presence for WebLogic Domain with UID governancedomai
   ```
  
    In the `Status` section of the output, the available servers and clusters are listed.

#### Verify the pods

1. Run the following command to see the pods running the servers and which nodes they are running on:

   ```bash
   $ kubectl get pods -n <namespace> -o wide
   ```

   For example:

   ```bash
   $ kubectl get pods -n oigns -o wide
   ```

   The output will look similar to the following:

   ```
   NAME                                                        READY   STATUS      RESTARTS   AGE   IP              NODE           NOMINATED NODE   READINESS GATES
   helper                                                      1/1     Running     0          3h50m   10.244.1.39   worker-node2   <none>           <none>
   governancedomain-adminserver                                1/1     Running     0          27m     10.244.1.42   worker-node2   <none>           <none>
   governancedomain-create-fmw-infra-sample-domain-job-8cww8   0/1     Completed   0          47m     10.244.1.40   worker-node2   <none>           <none>
   governancedomain-oim-server1                                1/1     Running     0          16m     10.244.1.44   worker-node2   <none>           <none>
   governancedomain-soa-server1                                1/1     Running     0          24m     10.244.1.43   worker-node2   <none>           <none>
   ```

   You are now ready to configure an Ingress to direct traffic for your OIG domain as per [Configure an ingress for an OIG domain](../configure-ingress).




