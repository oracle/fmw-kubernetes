+++
title = "Create OAM domains"
weight = 4
pre = "<b>4. </b>"
description = "Sample for creating an OAM domain home on an existing PV or PVC, and the domain resource YAML file for deploying the generated OAM domain."
+++

1. [Introduction](#introduction)
1. [Prerequisites](#prerequisites)
1. [Prepare the create domain script](#prepare-the-create-domain-script)
1. [Run the create domain script](#run-the-create-domain-script)
1. [Set the OAM server memory parameters](#set-the-oam-server-memory-parameters)
1. [Initializing the domain](#initializing-the-domain)
1. [Verify the results](#verify-the-results)
    
	a. [Verify the domain, pods and services](#verify-the-domain-pods-and-services)
	
	b. [Verify the domain](#verify-the-domain)
	
	c. [Verify the pods](#verify-the-pods)
	
	
### Introduction

The OAM deployment scripts demonstrate the creation of an OAM domain home on an existing Kubernetes persistent volume (PV) and persistent volume claim (PVC). The scripts also generate the domain YAML file, which can then be used to start the Kubernetes artifacts of the corresponding domain.

### Prerequisites

Before you begin, perform the following steps:

1. Review the [Domain resource](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/domain-resource) documentation.
1. Ensure that you have executed all the preliminary steps documented in [Prepare your environment]({{< relref "/oam/prepare-your-environment" >}}).
1. Ensure that the database is up and running.


### Prepare the create domain script

The sample scripts for Oracle Access Management domain deployment are available at `$WORKDIR/kubernetes/create-access-domain`.

1. Make a copy of the `create-domain-inputs.yaml` file:

   ```bash
   $ cd $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv
   $ cp create-domain-inputs.yaml create-domain-inputs.yaml.orig   
   ```

1. Edit the `create-domain-inputs.yaml` and modify the following parameters. Save the file when complete:   

   ```bash
   domainUID: <domain_uid>
   domainHome: /u01/oracle/user_projects/domains/<domain_uid>
   image: <image_name>:<tag>
   imagePullSecretName: <container_registry_secret>
   weblogicCredentialsSecretName: <kubernetes_domain_secret>
   logHome: /u01/oracle/user_projects/domains/logs/<domain_uid>
   namespace: <domain_namespace>
   persistentVolumeClaimName: <pvc_name>
   rcuSchemaPrefix: <rcu_prefix>
   rcuDatabaseURL: <rcu_db_host>:<rcu_db_port>/<rcu_db_service_name>
   rcuCredentialsSecret: <kubernetes_rcu_secret>   
   ```
   
   For example:
   
   
   ```bash   
   domainUID: accessdomain
   domainHome: /u01/oracle/user_projects/domains/accessdomain
   image: container-registry.oracle.com/middleware/oam_cpu:12.2.1.4-jdk8-ol7-<july'22>
   imagePullSecretName: orclcred
   weblogicCredentialsSecretName: accessdomain-credentials
   logHome: /u01/oracle/user_projects/domains/logs/accessdomain
   namespace: oamns
   persistentVolumeClaimName: accessdomain-domain-pvc
   rcuSchemaPrefix: OAMK8S
   rcuDatabaseURL: mydatabasehost.example.com:1521/orcl.example.com
   rcuCredentialsSecret: accessdomain-rcu-credentials
   ```
   
   
A full list of parameters in the `create-domain-inputs.yaml` file are shown below:

| Parameter | Definition | Default |
| --- | --- | --- |
| `adminPort` | Port number for the Administration Server inside the Kubernetes cluster. | `7001` |
| `adminNodePort` | Port number of the Administration Server outside the Kubernetes cluster. | `30701` |
| `adminServerName` | Name of the Administration Server. | `AdminServer` |
| `clusterName` | Name of the WebLogic cluster instance to generate for the domain. By default the cluster name is `oam_cluster` for the OAM domain. | `oam_cluster` |
| `configuredManagedServerCount` | Number of Managed Server instances to generate for the domain. | `5` |
| `createDomainFilesDir` | Directory on the host machine to locate all the files to create a WebLogic domain, including the script that is specified in the `createDomainScriptName` property. By default, this directory is set to the relative path `wlst`, and the create script will use the built-in WLST offline scripts in the `wlst` directory to create the WebLogic domain. It can also be set to the relative path `wdt`, and then the built-in WDT scripts will be used instead. An absolute path is also supported to point to an arbitrary directory in the file system. The built-in scripts can be replaced by the user-provided scripts or model files as long as those files are in the specified directory. Files in this directory are put into a Kubernetes config map, which in turn is mounted to the `createDomainScriptsMountPath`, so that the Kubernetes pod can use the scripts and supporting files to create a domain home. | `wlst` |
| `createDomainScriptsMountPath` | Mount path where the create domain scripts are located inside a pod. The `create-domain.sh` script creates a Kubernetes job to run the script (specified in the `createDomainScriptName` property) in a Kubernetes pod to create a domain home. Files in the `createDomainFilesDir` directory are mounted to this location in the pod, so that the Kubernetes pod can use the scripts and supporting files to create a domain home. | `/u01/weblogic` |
| `createDomainScriptName` | Script that the create domain script uses to create a WebLogic domain. The `create-domain.sh` script creates a Kubernetes job to run this script to create a domain home. The script is located in the in-pod directory that is specified in the `createDomainScriptsMountPath` property. If you need to provide your own scripts to create the domain home, instead of using the built-it scripts, you must use this property to set the name of the script that you want the create domain job to run. | `create-domain-job.sh` |
| `domainHome` | Home directory of the OAM domain. If not specified, the value is derived from the `domainUID` as `/shared/domains/<domainUID>`. | `/u01/oracle/user_projects/domains/accessinfra` |
| `domainPVMountPath` | Mount path of the domain persistent volume. | `/u01/oracle/user_projects` |
| `domainUID` | Unique ID that will be used to identify this particular domain. Used as the name of the generated WebLogic domain as well as the name of the Kubernetes domain resource. This ID must be unique across all domains in a Kubernetes cluster. This ID cannot contain any character that is not valid in a Kubernetes service name. | `accessinfra` |
| `domainType` | Type of the domain. Mandatory input for OAM domains. You must provide one of the supported domain type value: `oam` (deploys an OAM domain)| `oam`
| `exposeAdminNodePort` | Boolean indicating if the Administration Server is exposed outside of the Kubernetes cluster. | `false` |
| `exposeAdminT3Channel` | Boolean indicating if the T3 administrative channel is exposed outside the Kubernetes cluster. | `true` |
| `image` | OAM container image. The operator requires OAM 12.2.1.4. Refer to [Obtain the OAM container image]({{< relref "/oam/prepare-your-environment#obtain-the-oam-container-image" >}}) for details on how to obtain or create the image. | `oracle/oam:12.2.1.4.0` |
| `imagePullPolicy` | WebLogic container image pull policy. Legal values are `IfNotPresent`, `Always`, or `Never` | `IfNotPresent` |
| `imagePullSecretName` | Name of the Kubernetes secret to access the container registry to pull the OAM container image. The presence of the secret will be validated when this parameter is specified. |  |
| `includeServerOutInPodLog` | Boolean indicating whether to include the server .out to the pod's stdout. | `true` |
| `initialManagedServerReplicas` | Number of Managed Servers to initially start for the domain. | `2` |
| `javaOptions` | Java options for starting the Administration Server and Managed Servers. A Java option can have references to one or more of the following pre-defined variables to obtain WebLogic domain information: `$(DOMAIN_NAME)`, `$(DOMAIN_HOME)`, `$(ADMIN_NAME)`, `$(ADMIN_PORT)`, and `$(SERVER_NAME)`. | `-Dweblogic.StdoutDebugEnabled=false` |
| `logHome` | The in-pod location for the domain log, server logs, server out, and Node Manager log files. If not specified, the value is derived from the `domainUID` as `/shared/logs/<domainUID>`. | `/u01/oracle/user_projects/domains/logs/accessinfra` |
| `managedServerNameBase` | Base string used to generate Managed Server names. | `oam_server` |
| `managedServerPort` | Port number for each Managed Server. | `8001` |
| `namespace` | Kubernetes namespace in which to create the domain. | `accessns` |
| `persistentVolumeClaimName` | Name of the persistent volume claim created to host the domain home. If not specified, the value is derived from the `domainUID` as `<domainUID>-weblogic-sample-pvc`. | `accessinfra-domain-pvc` |
| `productionModeEnabled` | Boolean indicating if production mode is enabled for the domain. | `true` |
| `serverStartPolicy` | Determines which WebLogic Server instances will be started. Legal values are `NEVER`, `IF_NEEDED`, `ADMIN_ONLY`. | `IF_NEEDED` |
| `t3ChannelPort` | Port for the T3 channel of the NetworkAccessPoint. | `30012` |
| `t3PublicAddress` | Public address for the T3 channel.  This should be set to the public address of the Kubernetes cluster.  This would typically be a load balancer address. <p/>For development environments only: In a single server (all-in-one) Kubernetes deployment, this may be set to the address of the master, or at the very least, it must be set to the address of one of the worker nodes. | If not provided, the script will attempt to set it to the IP address of the Kubernetes cluster |
| `weblogicCredentialsSecretName` | Name of the Kubernetes secret for the Administration Server's user name and password. If not specified, then the value is derived from the `domainUID` as `<domainUID>-weblogic-credentials`. | `accessinfra-domain-credentials` |
| `weblogicImagePullSecretName` | Name of the Kubernetes secret for the container registry, used to pull the WebLogic Server image. |   |
| `serverPodCpuRequest`, `serverPodMemoryRequest`, `serverPodCpuCLimit`, `serverPodMemoryLimit` |  The maximum amount of compute resources allowed, and minimum amount of compute resources required, for each server pod. Please refer to the Kubernetes documentation on `Managing Compute Resources for Containers` for details. | Resource requests and resource limits are not specified. |
| `rcuSchemaPrefix` | The schema prefix to use in the database, for example `OAM1`.  You may wish to make this the same as the domainUID in order to simplify matching domains to their RCU schemas. | `OAM1` |
| `rcuDatabaseURL` | The database URL. | `oracle-db.default.svc.cluster.local:1521/devpdb.k8s` |
| `rcuCredentialsSecret` | The Kubernetes secret containing the database credentials. | `accessinfra-rcu-credentials` |

Note that the names of the Kubernetes resources in the generated YAML files may be formed with the
value of some of the properties specified in the `create-inputs.yaml` file. Those properties include
the `adminServerName`, `clusterName` and `managedServerNameBase`. If those values contain any
characters that are invalid in a Kubernetes service name, those characters are converted to
valid values in the generated YAML files. For example, an uppercase letter is converted to a
lowercase letter and an underscore `("_")` is converted to a hyphen `("-")`.

The sample demonstrates how to create an OAM domain home and associated Kubernetes resources for a domain
that has one cluster only. In addition, the sample provides the capability for users to supply their own scripts
to create the domain home for other use cases. The generated domain YAML file could also be modified to cover more use cases.

### Run the create domain script

1. Run the create domain script, specifying your inputs file and an output directory to store the
generated artifacts:

   ```bash
   $ cd $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv
   $ ./create-domain.sh -i create-domain-inputs.yaml -o /<path to output-directory>
   ```

   For example:
   
   ```bash
   $ cd $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv
   $ ./create-domain.sh -i create-domain-inputs.yaml -o output
   ```
   
   The output will look similar to the following:
   
   ```
   Input parameters being used
   export version="create-weblogic-sample-domain-inputs-v1"
   export adminPort="7001"
   export adminServerName="AdminServer"
   export domainUID="accessdomain"
   export domainType="oam"
   export domainHome="/u01/oracle/user_projects/domains/accessdomain"
   export serverStartPolicy="IF_NEEDED"
   export clusterName="oam_cluster"
   export configuredManagedServerCount="5"
   export initialManagedServerReplicas="2"
   export managedServerNameBase="oam_server"
   export managedServerPort="14100"
   export image="container-registry.oracle.com/middleware/oam_cpu:12.2.1.4-jdk8-ol7-<july'22>"
   export imagePullPolicy="IfNotPresent"
   export imagePullSecretName="orclcred"
   export productionModeEnabled="true"
   export weblogicCredentialsSecretName="accessdomain-credentials"
   export includeServerOutInPodLog="true"
   export logHome="/u01/oracle/user_projects/domains/logs/accessdomain"
   export httpAccessLogInLogHome="true"
   export t3ChannelPort="30012"
   export exposeAdminT3Channel="false"
   export adminNodePort="30701"
   export exposeAdminNodePort="false"
   export namespace="oamns"
   javaOptions=-Dweblogic.StdoutDebugEnabled=false
   export persistentVolumeClaimName="accessdomain-domain-pvc"
   export domainPVMountPath="/u01/oracle/user_projects/domains"
   export createDomainScriptsMountPath="/u01/weblogic"
   export createDomainScriptName="create-domain-job.sh"
   export createDomainFilesDir="wlst"
   export rcuSchemaPrefix="OAMK8S"
   export rcuDatabaseURL="mydatabasehost.example.com:1521/orcl.example.com"
   export rcuCredentialsSecret="accessdomain-rcu-credentials"

   createFiles - valuesInputFile is create-domain-inputs.yaml
   createDomainScriptName is create-domain-job.sh
   Generating output/weblogic-domains/accessdomain/create-domain-job.yaml
   Generating output/weblogic-domains/accessdomain/delete-domain-job.yaml
   Generating output/weblogic-domains/accessdomain/domain.yaml
   Checking to see if the secret accessdomain-credentials exists in namespace oamns
   configmap/accessdomain-create-oam-infra-domain-job-cm created
   Checking the configmap accessdomain-create-oam-infra-domain-job-cm was created
   configmap/accessdomain-create-oam-infra-domain-job-cm labeled
   Checking if object type job with name accessdomain-create-oam-infra-domain-job exists
   No resources found in oamns namespace.
   Creating the domain by creating the job output/weblogic-domains/accessdomain/create-domain-job.yaml
   job.batch/accessdomain-create-oam-infra-domain-job created
   Waiting for the job to complete...
   status on iteration 1 of 20
   pod accessdomain-create-oam-infra-domain-job-6tgw4 status is Running
   status on iteration 2 of 20
   pod accessdomain-create-oam-infra-domain-job-6tgw4 status is Running
   status on iteration 3 of 20
   pod accessdomain-create-oam-infra-domain-job-6tgw4 status is Running
   status on iteration 4 of 20
   pod accessdomain-create-oam-infra-domain-job-6tgw4 status is Running
   status on iteration 5 of 20
   pod accessdomain-create-oam-infra-domain-job-6tgw4 status is Running
   status on iteration 6 of 20
   pod accessdomain-create-oam-infra-domain-job-6tgw4 status is Completed

   Domain accessdomain was created and will be started by the WebLogic Kubernetes Operator

   The following files were generated:
     output/weblogic-domains/accessdomain/create-domain-inputs.yaml
     output/weblogic-domains/accessdomain/create-domain-job.yaml
     output/weblogic-domains/accessdomain/domain.yaml
   ```

   **Note**: If the domain creation fails, refer to the [Troubleshooting](../troubleshooting) section.
   
   The command creates a `domain.yaml` file required for domain creation. 

### Set the OAM server memory parameters

By default, the java memory parameters assigned to the oam_server cluster are very small. The minimum recommended values are `-Xms4096m -Xmx8192m`. However, Oracle recommends you to set these to `-Xms8192m -Xmx8192m` in a production environment.

1. Navigate to the `/output/weblogic-domains/<domain_uid>` directory:

   ```bash
   $ cd $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/output/weblogic-domains/<domain_uid>
   ```
   
   For example:
   
   ```bash
   $ cd $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/output/weblogic-domains/accessdomain
   ```
   
1. Edit the `domain.yaml` file and locate the section of the file starting with: `- clusterName: oam_cluster`. Immediately after the line: `topologyKey: "kubernetes.io/hostname"`, add the following lines:
   
   ```
   env:
   - name: USER_MEM_ARGS
     value: "-XX:+UseContainerSupport -Djava.security.egd=file:/dev/./urandom -Xms8192m -Xmx8192m"
   ```
   
   For example:
   
   ```
     - clusterName: oam_cluster
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
        value: "-XX:+UseContainerSupport -Djava.security.egd=file:/dev/./urandom -Xms8192m -Xmx8192m"
    replicas: 2
   ```
   

1. In the `domain.yaml` locate the section of the file starting with `adminServer:`. Under the `env:` tag add the following `CLASSPATH` entries. This is required for running the `idmconfigtool` from the Administration Server.

   ```
   - name: CLASSPATH
     value: "/u01/oracle/wlserver/server/lib/weblogic.jar"
   ```

   For example: 
  
   ```
     adminServer:
     # serverStartState legal values are "RUNNING" or "ADMIN"
     # "RUNNING" means the listed server will be started up to "RUNNING" mode
     # "ADMIN" means the listed server will be start up to "ADMIN" mode
     serverStartState: "RUNNING"
     adminService:
       channels:
     # The Admin Server's NodePort
        - channelName: default
          nodePort: 30701
     # Uncomment to export the T3Channel as a service
        - channelName: T3Channel
     serverPod:
       # an (optional) list of environment variable to be set on the admin servers
       env:
       - name: USER_MEM_ARGS
         value: "-Djava.security.egd=file:/dev/./urandom -Xms512m -Xmx1024m "
       - name: CLASSPATH
         value: "/u01/oracle/wlserver/server/lib/weblogic.jar"
   ``` 
   
1. If required, you can add the optional parameter `maxClusterConcurrentStartup` to the `spec` section of the `domain.yaml`. This parameter specifies the number of managed servers to be started in sequence per cluster. For example if you updated the `initialManagedServerReplicas` to `4` in `create-domain-inputs.yaml` and only had 2 nodes, then setting `maxClusterConcurrentStartup: 1` will start one managed server at a time on each node, rather than starting them all at once. This can be useful to take the strain off individual nodes at startup. Below is an example with the parameter added:
   
   ```
   apiVersion: "weblogic.oracle/v8"
   kind: Domain
   metadata:
     name: accessdomain
     namespace: oamns
     labels:
       weblogic.domainUID: accessdomain
   spec:
     # The WebLogic Domain Home
     domainHome: /u01/oracle/user_projects/domains/accessdomain
	 maxClusterConcurrentStartup: 1

     # The domain home source type
     # Set to PersistentVolume for domain-in-pv, Image for domain-in-image, or FromModel for model-in-image
     domainHomeSourceType: PersistentVolume

     # The WebLogic Server container image that the Operator uses to start the domain
     image: "oracle/oam:12.2.1.4.0"
     ....
   ```	 
1. Save the changes to `domain.yaml`


### Initializing the domain

1. Create the Kubernetes resource using the following command:
   
   ```bash
   $ kubectl apply -f $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/output/weblogic-domains/<domain_uid>/domain.yaml
   ```
   
   For example:
   
   ```bash
   $ kubectl apply -f $WORKDIR/kubernetes/create-access-domain/domain-home-on-pv/output/weblogic-domains/accessdomain/domain.yaml
   ```
   
   The output will look similar to the following:
   
   ```
   domain.weblogic.oracle/accessdomain created
   ```

### Verify the results

#### Verify the domain, pods and services

1. Verify the domain, servers pods and services are created and in the `READY` state with a status of `1/1`, by running the following command:

   ```bash
   $ kubectl get all,domains -n <domain_namespace>
   ```
   
   For example:
   
    ```bash
   $ kubectl get all,domains -n oamns
   ```
   
   The output will look similar to the following:

   ```
   NAME                                                 READY   STATUS      RESTARTS   AGE
   pod/accessdomain-adminserver                         1/1     Running     0          11m
   pod/accessdomain-create-oam-infra-domain-job-7c9r9   0/1     Completed   0          18m
   pod/accessdomain-oam-policy-mgr1                     1/1     Running     0          3m31s
   pod/accessdomain-oam-policy-mgr2                     1/1     Running     0          3m31s
   pod/accessdomain-oam-server1                         1/1     Running     0          3m31s
   pod/accessdomain-oam-server2                         1/1     Running     0          3m31s
   pod/helper                                           1/1     Running     0          33m

   NAME                                          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)     AGE
   service/accessdomain-adminserver              ClusterIP   None            <none>        7001/TCP    11m
   service/accessdomain-cluster-oam-cluster      ClusterIP   10.101.59.154   <none>        14100/TCP   3m31s
   service/accessdomain-cluster-policy-cluster   ClusterIP   10.98.236.51    <none>        15100/TCP   3m31s
   service/accessdomain-oam-policy-mgr1          ClusterIP   None            <none>        15100/TCP   3m31s
   service/accessdomain-oam-policy-mgr2          ClusterIP   None            <none>        15100/TCP   3m31s
   service/accessdomain-oam-policy-mgr3          ClusterIP   10.96.244.37    <none>        15100/TCP   3m31s
   service/accessdomain-oam-policy-mgr4          ClusterIP   10.105.201.23   <none>        15100/TCP   3m31s
   service/accessdomain-oam-policy-mgr5          ClusterIP   10.110.12.227   <none>        15100/TCP   3m31s
   service/accessdomain-oam-server1              ClusterIP   None            <none>        14100/TCP   3m31s
   service/accessdomain-oam-server2              ClusterIP   None            <none>        14100/TCP   3m31s
   service/accessdomain-oam-server3              ClusterIP   10.103.178.35   <none>        14100/TCP   3m31s
   service/accessdomain-oam-server4              ClusterIP   10.97.254.78    <none>        14100/TCP   3m31s
   service/accessdomain-oam-server5              ClusterIP   10.105.65.104   <none>        14100/TCP   3m31s

   NAME                                                 COMPLETIONS   DURATION   AGE
   job.batch/accessdomain-create-oam-infra-domain-job   1/1           2m6s       18m

   NAME                                  AGE
   domain.weblogic.oracle/accessdomain   12m
   ```
   
   **Note**: It will take several minutes before all the services listed above show. When a pod has a `STATUS` of `0/1` the pod is started but the OAM server associated with it is currently starting. While the pods are starting you can check the startup status in the pod logs, by running the following command:
   
   ```bash
   $ kubectl logs accessdomain-adminserver -n oamns
   $ kubectl logs accessdomain-oam-policy-mgr1 -n oamns
   $ kubectl logs accessdomain-oam-server1 -n oamns
   etc..
   ```
   
   
   The default domain created by the script has the following characteristics:

   * An Administration Server named `AdminServer` listening on port `7001`.
   * A configured OAM cluster named `oam_cluster` of size 5.
   * A configured Policy Manager cluster named `policy_cluster` of size 5.
   * Two started OAM managed Servers, named `oam_server1` and `oam_server2`, listening on port `14100`.
   * Two started Policy Manager managed servers named `oam-policy-mgr1` and `oam-policy-mgr2`, listening on port `15100`.
   * Log files that are located in `<persistent_volume>/logs/<domainUID>`.
  
#### Verify the domain

1. Run the following command to describe the domain: 

   ```bash
   $ kubectl describe domain <domain_uid> -n <domain_namespace>
   ```

   For example:
   ```bash
   $ kubectl describe domain accessdomain -n oamns
   ```

   The output will look similar to the following:

   ```
   Name:         accessdomain
   Namespace:    oamns
   Labels:       weblogic.domainUID=accessdomain
   Annotations:  <none>
   API Version:  weblogic.oracle/v8
   Kind:         Domain
   Metadata:
     Creation Timestamp:  2022-07-07T11:59:51Z
     Generation:          1
     Managed Fields:
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
       Manager:      Kubernetes Java Client
       Operation:    Update
       Time:         2022-07-07T11:59:51Z
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
       Manager:         kubectl-client-side-apply
       Operation:       Update
       Time:            2022-07-07T11:59:51Z
     Resource Version:  1495179
     UID:               a90107d5-dbaf-4d86-9439-d5369faabd35
   Spec:
     Admin Server:
       Server Pod:
         Env:
           Name:            USER_MEM_ARGS
           Value:           -Djava.security.egd=file:/dev/./urandom -Xms512m -Xmx1024m
           Name:            CLASSPATH
           Value:           /u01/oracle/wlserver/server/lib/weblogic.jar
       Server Start State:  RUNNING
     Clusters:
       Cluster Name:  policy_cluster
       Replicas:      2
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
       Cluster Name:         oam_cluster
       Replicas:             2
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
           Value:  -XX:+UseContainerSupport -Djava.security.egd=file:/dev/./urandom -Xms8192m -Xmx8192m
       Server Service:
         Precreate Service:          true
       Server Start State:           RUNNING
     Data Home:
     Domain Home:                    /u01/oracle/user_projects/domains/accessdomain
     Domain Home Source Type:        PersistentVolume
     Http Access Log In Log Home:    true
     Image:                          container-registry.oracle.com/middleware/oam_cpu:12.2.1.4-jdk8-ol7-<july'22>
     Image Pull Policy:              IfNotPresent
	 Image Pull Secrets:
       Name:                         orclcred
     Include Server Out In Pod Log:  true
     Log Home:                       /u01/oracle/user_projects/domains/logs/accessdomain
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
           Claim Name:     accessdomain-domain-pvc
     Server Start Policy:  IF_NEEDED
     Web Logic Credentials Secret:
       Name:  accessdomain-credentials
   Status:
     Clusters:
       Cluster Name:      oam_cluster
       Maximum Replicas:  5
       Minimum Replicas:  0
       Ready Replicas:    2
       Replicas:          2
       Replicas Goal:     2
       Cluster Name:      policy_cluster
       Maximum Replicas:  5
       Minimum Replicas:  0
       Ready Replicas:    2
       Replicas:          2
       Replicas Goal:     2
     Conditions:
       Last Transition Time:        2022-07-07T12:11:52.623959Z
       Reason:                      ServersReady
       Status:                      True
       Type:                        Available
     Introspect Job Failure Count:  0
     Servers:
       Desired State:  RUNNING
       Health:
         Activation Time:  2022-07-07T12:08:29.271000Z
         Overall Health:   ok
         Subsystems:
           Subsystem Name:  ServerRuntime
           Symptoms:
        Node Name:      10.250.42.252
       Server Name:    AdminServer
       State:          RUNNING
       Cluster Name:   oam_cluster
       Desired State:  RUNNING
       Health:
         Activation Time:  2022-07-07T12:11:02.696000Z
         Overall Health:   ok
         Subsystems:
           Subsystem Name:  ServerRuntime
           Symptoms:
       Node Name:      10.250.42.255
       Server Name:    oam_server1
       State:          RUNNING
       Cluster Name:   oam_cluster
       Desired State:  RUNNING
       Health:
         Activation Time:  2022-07-07T12:11:46.175000Z
         Overall Health:   ok
         Subsystems:
           Subsystem Name:  ServerRuntime
           Symptoms:
        Node Name:      10.250.42.252
       Server Name:    oam_server2
       State:          RUNNING
       Cluster Name:   oam_cluster
       Desired State:  SHUTDOWN
       Server Name:    oam_server3
       Cluster Name:   oam_cluster
       Desired State:  SHUTDOWN
       Server Name:    oam_server4
       Cluster Name:   oam_cluster
       Desired State:  SHUTDOWN
       Server Name:    oam_server5
       Cluster Name:   policy_cluster
       Desired State:  RUNNING
       Health:
         Activation Time:  2022-07-07T12:11:20.404000Z
         Overall Health:   ok
         Subsystems:
           Subsystem Name:  ServerRuntime
           Symptoms:
       Node Name:      10.250.42.255
       Server Name:    oam_policy_mgr1
       State:          RUNNING
       Cluster Name:   policy_cluster
       Desired State:  RUNNING
       Health:
         Activation Time:  2022-07-07T12:11:09.719000Z
         Overall Health:   ok
         Subsystems:
           Subsystem Name:  ServerRuntime
           Symptoms:
       Node Name:      10.250.42.252
       Server Name:    oam_policy_mgr2
       State:          RUNNING
       Cluster Name:   policy_cluster
       Desired State:  SHUTDOWN
       Server Name:    oam_policy_mgr3
       Cluster Name:   policy_cluster
       Desired State:  SHUTDOWN
       Server Name:    oam_policy_mgr4
       Cluster Name:   policy_cluster
       Desired State:  SHUTDOWN
       Server Name:    oam_policy_mgr5
     Start Time:       2022-07-07T11:59:51.682687Z
   Events:
     Type    Reason                     Age                 From               Message
     ----    ------                     ----                ----               -------
     Normal  DomainCreated              13m                 weblogic.operator  Domain resource accessdomain was created
     Normal  DomainProcessingStarting   5m9s (x2 over 13m)  weblogic.operator  Creating or updating Kubernetes presence for WebLogic Domain with UID accessdomain
     Normal  DomainProcessingCompleted  114s                weblogic.operator  Successfully completed processing domain resource accessdomain
   ```

   In the `Status` section of the output, the available servers and clusters are listed.

#### Verify the pods

1. Run the following command to see the pods running the servers and which nodes they are running on:

   ```bash
   $ kubectl get pods -n <domain_namespace> -o wide
   ```

   For example:
   
   ```bash
   $ kubectl get pods -n oamns -o wide
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                                            READY   STATUS      RESTARTS   AGE     IP            NODE             NOMINATED NODE   READINESS GATES
   accessdomain-adminserver                         1/1     Running     0          18m   10.244.6.63   10.250.42.252   <none>           <none>
   accessdomain-create-oam-infra-domain-job-7c9r9   0/1     Completed   0          25m   10.244.6.61   10.250.42.252   <none>           <none>
   accessdomain-oam-policy-mgr1                     1/1     Running     0          10m   10.244.5.13   10.250.42.255   <none>           <none>
   accessdomain-oam-policy-mgr2                     1/1     Running     0          10m   10.244.6.65   10.250.42.252   <none>           <none>
   accessdomain-oam-server1                         1/1     Running     0          10m   10.244.5.12   10.250.42.255   <none>           <none>
   accessdomain-oam-server2                         1/1     Running     0          10m   10.244.6.64   10.250.42.252   <none>           <none>
   helper                                           1/1     Running     0          40m   10.244.6.60   10.250.42.252   <none>           <none>
   ```

   You are now ready to configure an Ingress to direct traffic for your OAM domain as per [Configure an Ingress for an OAM domain](../configure-ingress/).



