+++
title = "Create OAM domains"
weight = 5
pre = "<b>5. </b>"
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
1. Ensure that you have executed all the preliminary steps documented in [Prepare your environment](../prepare-your-environment).
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
   image: container-registry.oracle.com/middleware/oam_cpu:12.2.1.4-jdk8-ol7-<October`23>
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
| `domainHome` | Home directory of the OAM domain. If not specified, the value is derived from the `domainUID` as `/shared/domains/<domainUID>`. | `/u01/oracle/user_projects/domains/accessdomain` |
| `domainPVMountPath` | Mount path of the domain persistent volume. | `/u01/oracle/user_projects/domains` |
| `domainUID` | Unique ID that will be used to identify this particular domain. Used as the name of the generated WebLogic domain as well as the name of the Kubernetes domain resource. This ID must be unique across all domains in a Kubernetes cluster. This ID cannot contain any character that is not valid in a Kubernetes service name. | `accessdomain` |
| `domainType` | Type of the domain. Mandatory input for OAM domains. You must provide one of the supported domain type value: `oam` (deploys an OAM domain)| `oam`
| `exposeAdminNodePort` | Boolean indicating if the Administration Server is exposed outside of the Kubernetes cluster. | `false` |
| `exposeAdminT3Channel` | Boolean indicating if the T3 administrative channel is exposed outside the Kubernetes cluster. | `true` |
| `image` | OAM container image. The operator requires OAM 12.2.1.4. Refer to [Obtain the OAM container image](../prepare-your-environment#obtain-the-oam-container-image) for details on how to obtain or create the image. | `oracle/oam:12.2.1.4.0` |
| `imagePullPolicy` | WebLogic container image pull policy. Legal values are `IfNotPresent`, `Always`, or `Never` | `IfNotPresent` |
| `imagePullSecretName` | Name of the Kubernetes secret to access the container registry to pull the OAM container image. The presence of the secret will be validated when this parameter is specified. |  |
| `includeServerOutInPodLog` | Boolean indicating whether to include the server .out to the pod's stdout. | `true` |
| `initialManagedServerReplicas` | Number of Managed Servers to initially start for the domain. | `2` |
| `javaOptions` | Java options for starting the Administration Server and Managed Servers. A Java option can have references to one or more of the following pre-defined variables to obtain WebLogic domain information: `$(DOMAIN_NAME)`, `$(DOMAIN_HOME)`, `$(ADMIN_NAME)`, `$(ADMIN_PORT)`, and `$(SERVER_NAME)`. | `-Dweblogic.StdoutDebugEnabled=false` |
| `logHome` | The in-pod location for the domain log, server logs, server out, and Node Manager log files. If not specified, the value is derived from the `domainUID` as `/shared/logs/<domainUID>`. | `/u01/oracle/user_projects/domains/logs/accessdomain` |
| `managedServerNameBase` | Base string used to generate Managed Server names. | `oam_server` |
| `managedServerPort` | Port number for each Managed Server. | `8001` |
| `namespace` | Kubernetes namespace in which to create the domain. | `accessns` |
| `persistentVolumeClaimName` | Name of the persistent volume claim created to host the domain home. If not specified, the value is derived from the `domainUID` as `<domainUID>-weblogic-sample-pvc`. | `accessdomain-domain-pvc` |
| `productionModeEnabled` | Boolean indicating if production mode is enabled for the domain. | `true` |
| `serverStartPolicy` | Determines which WebLogic Server instances will be started. Legal values are `Never`, `IfNeeded`, `AdminOnly`. | `IfNeeded` |
| `t3ChannelPort` | Port for the T3 channel of the NetworkAccessPoint. | `30012` |
| `t3PublicAddress` | Public address for the T3 channel.  This should be set to the public address of the Kubernetes cluster.  This would typically be a load balancer address. <p/>For development environments only: In a single server (all-in-one) Kubernetes deployment, this may be set to the address of the master, or at the very least, it must be set to the address of one of the worker nodes. | If not provided, the script will attempt to set it to the IP address of the Kubernetes cluster |
| `weblogicCredentialsSecretName` | Name of the Kubernetes secret for the Administration Server's user name and password. If not specified, then the value is derived from the `domainUID` as `<domainUID>-weblogic-credentials`. | `accessdomain-domain-credentials` |
| `weblogicImagePullSecretName` | Name of the Kubernetes secret for the container registry, used to pull the WebLogic Server image. |   |
| `serverPodCpuRequest`, `serverPodMemoryRequest`, `serverPodCpuCLimit`, `serverPodMemoryLimit` |  The maximum amount of compute resources allowed, and minimum amount of compute resources required, for each server pod. Please refer to the Kubernetes documentation on `Managing Compute Resources for Containers` for details. | Resource requests and resource limits are not specified. |
| `rcuSchemaPrefix` | The schema prefix to use in the database, for example `OAM1`.  You may wish to make this the same as the domainUID in order to simplify matching domains to their RCU schemas. | `OAM1` |
| `rcuDatabaseURL` | The database URL. | `oracle-db.default.svc.cluster.local:1521/devpdb.k8s` |
| `rcuCredentialsSecret` | The Kubernetes secret containing the database credentials. | `accessdomain-rcu-credentials` |
| `datasourceType` | Type of JDBC datasource applicable for the OAM domain. Legal values are `agl` and `generic`. Choose `agl` for Active GridLink datasource and `generic` for Generic datasource. For enterprise deployments, Oracle recommends that you use GridLink data sources to connect to Oracle RAC databases. See the [Enterprise Deployment Guide](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/preparing-existing-database-enterprise-deployment.html#GUID-E3705EFF-AEF2-4F75-B5CE-1A829CDF0A1F) for further details. | `generic` |



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
   export serverStartPolicy="IfNeeded"
   export clusterName="oam_cluster"
   export configuredManagedServerCount="5"
   export initialManagedServerReplicas="2"
   export managedServerNameBase="oam_server"
   export managedServerPort="14100"
   export image="container-registry.oracle.com/middleware/oam_cpu:12.2.1.4-jdk8-ol7-<October`23>"
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
   export datasourceType="generic"

   validateWlsDomainName called with accessdomain
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
   
1. Edit the `domain.yaml` file and inside `name: accessdomain-oam-cluster`, add the memory setting as below: 
   
   ```
     serverPod:
       env:
       - name: USER_MEM_ARGS
         value: "-XX:+UseContainerSupport -Djava.security.egd=file:/dev/./urandom -Xms8192m -Xmx8192m"
       resources:
         limits:
           cpu: "2"
           memory: "8Gi"
         requests:
           cpu: "1000m"
           memory: "4Gi"
   ```
   
   
   For example:
      
   ```
   apiVersion: weblogic.oracle/v1
   kind: Cluster
   metadata:
     name: accessdomain-oam-cluster
     namespace: oamns
   spec:
     clusterName: oam_cluster
     serverService:
       precreateService: true
     serverPod:
       env:
       - name: USER_MEM_ARGS
         value: "-XX:+UseContainerSupport -Djava.security.egd=file:/dev/./urandom -Xms8192m -Xmx8192m"
       resources:
         limits:
           cpu: "2"
           memory: "8Gi"
       requests:
           cpu: "1000m"
           memory: "4Gi"
     replicas: 1

   ```
   
   
   **Note**: The above CPU and memory values are for development environments only. For Enterprise Deployments, please review the performance recommendations and sizing requirements in [Enterprise Deployment Guide for Oracle Identity and Access Management in a Kubernetes Cluster](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/procuring-resources-oracle-cloud-infrastructure-deployment.html#GUID-2E3C8D01-43EB-4691-B1D6-25B1DC2475AE).

   **Note**: Limits and requests for CPU resources are measured in CPU units. One CPU in Kubernetes is equivalent to 1 vCPU/Core for cloud providers, and 1 hyperthread on bare-metal Intel processors. An "`m`" suffix in a CPU attribute indicates ‘milli-CPU’, so 500m is 50% of a CPU. Memory can be expressed in various units, where one Mi is one IEC unit mega-byte (1024^2), and one Gi is one IEC unit giga-byte (1024^3). For more information, see [Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/), [Assign Memory Resources to Containers and Pods](https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/), and [Assign CPU Resources to Containers and Pods](https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/).
   
   **Note**: The parameters above are also utilized by the Kubernetes Horizontal Pod Autoscaler (HPA). For more details on HPA, see [Kubernetes Horizontal Pod Autoscaler](../manage-oam-domains/hpa).

   **Note**: If required you can also set the same resources and limits for the `accessdomain-policy-cluster`.


1. In the `domain.yaml` locate the section of the file starting with `adminServer:`. Under the `env:` tag add the following `CLASSPATH` entries. This is required for running the `idmconfigtool` from the Administration Server.

   ```
   - name: CLASSPATH
     value: "/u01/oracle/wlserver/server/lib/weblogic.jar"
   ```

   For example: 
  
   ```
   # adminServer is used to configure the desired behavior for starting the administration server.
   adminServer:
     # adminService:
     #   channels:
     # The Admin Server's NodePort
     #    - channelName: default
     #      nodePort: 30701
     # Uncomment to export the T3Channel as a service
     #    - channelName: T3Channel
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
   apiVersion: "weblogic.oracle/v9"
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
   cluster.weblogic.oracle/accessdomain-oam-cluster created
   cluster.weblogic.oracle/accessdomain-policy-cluster created
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
   pod/accessdomain-oam-server1                         1/1     Running     0          3m31s
   pod/helper                                           1/1     Running     0          33m

   NAME                                          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)     AGE
   service/accessdomain-adminserver              ClusterIP   None            <none>        7001/TCP    11m
   service/accessdomain-cluster-oam-cluster      ClusterIP   10.101.59.154   <none>        14100/TCP   3m31s
   service/accessdomain-cluster-policy-cluster   ClusterIP   10.98.236.51    <none>        15100/TCP   3m31s
   service/accessdomain-oam-policy-mgr1          ClusterIP   None            <none>        15100/TCP   3m31s
   service/accessdomain-oam-policy-mgr2          ClusterIP   10.104.92.12    <none>        15100/TCP   3m31s
   service/accessdomain-oam-policy-mgr3          ClusterIP   10.96.244.37    <none>        15100/TCP   3m31s
   service/accessdomain-oam-policy-mgr4          ClusterIP   10.105.201.23   <none>        15100/TCP   3m31s
   service/accessdomain-oam-policy-mgr5          ClusterIP   10.110.12.227   <none>        15100/TCP   3m31s
   service/accessdomain-oam-server1              ClusterIP   None            <none>        14100/TCP   3m31s
   service/accessdomain-oam-server2              ClusterIP   10.96.137.33    <none>        14100/TCP   3m31s
   service/accessdomain-oam-server3              ClusterIP   10.103.178.35   <none>        14100/TCP   3m31s
   service/accessdomain-oam-server4              ClusterIP   10.97.254.78    <none>        14100/TCP   3m31s
   service/accessdomain-oam-server5              ClusterIP   10.105.65.104   <none>        14100/TCP   3m31s

   NAME                                                 COMPLETIONS   DURATION   AGE
   job.batch/accessdomain-create-oam-infra-domain-job   1/1           2m6s       18m

   NAME                                  AGE
   domain.weblogic.oracle/accessdomain   12m
   
   NAME                                                  AGE
   cluster.weblogic.oracle/accessdomain-oam-cluster      11m
   cluster.weblogic.oracle/accessdomain-policy-cluster   11m
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
   * One started OAM Managed Server, named `oam_server1`, listening on port `14100`.
   * One started Policy Manager Managed Servers named `oam-policy-mgr1`, listening on port `15100`.
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
   API Version:  weblogic.oracle/v9
   Kind:         Domain
   Metadata:
     Creation Timestamp:  <DATE>
     Generation:          1
     Managed Fields:
       API Version:  weblogic.oracle/v9
       Fields Type:  FieldsV1
       fieldsV1:
         f:metadata:
           f:annotations:
             .:
             f:kubectl.kubernetes.io/last-applied-configuration:
           f:labels:
             .:
             f:weblogic.domainUID:
         f:spec:
           .:
           f:adminServer:
             .:
             f:adminChannelPortForwardingEnabled:
             f:serverPod:
               .:
               f:env:
             f:serverStartPolicy:
           f:clusters:
           f:dataHome:
           f:domainHome:
           f:domainHomeSourceType:
           f:failureRetryIntervalSeconds:
           f:failureRetryLimitMinutes:
           f:httpAccessLogInLogHome:
           f:image:
           f:imagePullPolicy:
           f:imagePullSecrets:
           f:includeServerOutInPodLog:
           f:logHome:
           f:logHomeEnabled:
           f:logHomeLayout:
           f:maxClusterConcurrentShutdown:
           f:maxClusterConcurrentStartup:
           f:maxClusterUnavailable:
           f:replicas:
           f:serverPod:
             .:
             f:env:
             f:volumeMounts:
             f:volumes:
           f:serverStartPolicy:
           f:webLogicCredentialsSecret:
             .:
             f:name:
       Manager:      kubectl-client-side-apply
       Operation:    Update
       Time:         <DATE>
       API Version:  weblogic.oracle/v9
       Fields Type:  FieldsV1
       fieldsV1:
         f:status:
           .:
           f:clusters:
           f:conditions:
           f:observedGeneration:
           f:servers:
           f:startTime:
       Manager:         Kubernetes Java Client
       Operation:       Update
       Subresource:     status
       Time:            <DATE>
     Resource Version:  2074089
     UID:               e194d483-7383-4359-adb9-bf97de36518b
   Spec:
     Admin Server:
       Admin Channel Port Forwarding Enabled:  true
       Server Pod:
         Env:
           Name:             USER_MEM_ARGS
           Value:            -Djava.security.egd=file:/dev/./urandom -Xms512m -Xmx1024m
           Name:             CLASSPATH
           Value:            /u01/oracle/wlserver/server/lib/weblogic.jar
       Server Start Policy:  IfNeeded
     Clusters:
       Name:                          accessdomain-oam-cluster
       Name:                          accessdomain-policy-cluster
     Data Home:
     Domain Home:                     /u01/oracle/user_projects/domains/accessdomain
     Domain Home Source Type:         PersistentVolume
     Failure Retry Interval Seconds:  120
     Failure Retry Limit Minutes:     1440
     Http Access Log In Log Home:     true
     Image:                           container-registry.oracle.com/middleware/oam_cpu:12.2.1.4-jdk8-ol7-<October'23>
     Image Pull Policy:               IfNotPresent
     Image Pull Secrets:
       Name:                           orclcred
     Include Server Out In Pod Log:    true
     Log Home:                         /u01/oracle/user_projects/domains/logs/accessdomain
     Log Home Enabled:                 true
     Log Home Layout:                  ByServers
     Max Cluster Concurrent Shutdown:  1
     Max Cluster Concurrent Startup:   0
     Max Cluster Unavailable:          1
     Replicas:                         1
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
     Server Start Policy:  IfNeeded
     Web Logic Credentials Secret:
       Name:  accessdomain-credentials
   Status:
     Clusters:
       Cluster Name:  oam_cluster
       Conditions:
         Last Transition Time:  <DATE>
         Status:                True
         Type:                  Available
         Last Transition Time:  <DATE>
         Status:                True
         Type:                  Completed
       Label Selector:          weblogic.domainUID=accessdomain,weblogic.clusterName=oam_cluster
       Maximum Replicas:        5
       Minimum Replicas:        0
       Observed Generation:     1
       Ready Replicas:          1
       Replicas:                1
       Replicas Goal:           1
       Cluster Name:            policy_cluster
       Conditions:
         Last Transition Time:  <DATE>
         Status:                True
         Type:                  Available
         Last Transition Time:  <DATE>
         Status:                True
         Type:                  Completed
       Label Selector:          weblogic.domainUID=accessdomain,weblogic.clusterName=policy_cluster
       Maximum Replicas:        5
       Minimum Replicas:        0
       Observed Generation:     1
       Ready Replicas:          1
       Replicas:                1
       Replicas Goal:           1
     Conditions:
       Last Transition Time:  <DATE>
       Status:                True
       Type:                  Available
       Last Transition Time:  <DATE>
       Status:                True
       Type:                  Completed
     Observed Generation:     1
     Servers:
       Health:
         Activation Time:  <DATE>
         Overall Health:   ok
         Subsystems:
           Subsystem Name:  ServerRuntime
           Symptoms:
       Node Name:     worker-node2
       Pod Phase:     Running
       Pod Ready:     True
       Server Name:   AdminServer
       State:         RUNNING
       State Goal:    RUNNING
       Cluster Name:  oam_cluster
       Health:
         Activation Time:  <DATE>
         Overall Health:   ok
         Subsystems:
           Subsystem Name:  ServerRuntime
          Symptoms:
       Node Name:     worker-node1
       Pod Phase:     Running
       Pod Ready:     True
       Server Name:   oam_server1
       State:         RUNNING
       State Goal:    RUNNING
       Cluster Name:  oam_cluster
       Server Name:   oam_server2
       State:         SHUTDOWN
       State Goal:    SHUTDOWN
       Cluster Name:  oam_cluster
       Server Name:   oam_server3
       State:         SHUTDOWN
       State Goal:    SHUTDOWN
       Cluster Name:  oam_cluster
       Server Name:   oam_server4
       State:         SHUTDOWN
       State Goal:    SHUTDOWN
       Cluster Name:  oam_cluster
       Server Name:   oam_server5
       State:         SHUTDOWN
       State Goal:    SHUTDOWN
       Cluster Name:  policy_cluster
       Health:
         Activation Time:  <DATE>
         Overall Health:   ok
         Subsystems:
           Subsystem Name:  ServerRuntime
           Symptoms:
       Node Name:     worker-node1
       Pod Phase:     Running
       Pod Ready:     True
       Server Name:   oam_policy_mgr1
       State:         RUNNING
       State Goal:    RUNNING
       Cluster Name:  policy_cluster
       Server Name:   oam_policy_mgr2
       State:         SHUTDOWN
       State Goal:    SHUTDOWN
       Cluster Name:  policy_cluster
       Server Name:   oam_policy_mgr3
       State:         SHUTDOWN
       State Goal:    SHUTDOWN
       Cluster Name:  policy_cluster
       Server Name:   oam_policy_mgr4
       State:         SHUTDOWN
       State Goal:    SHUTDOWN
       Cluster Name:  policy_cluster
       Server Name:   oam_policy_mgr5
       State:         SHUTDOWN
       State Goal:    SHUTDOWN
     Start Time:      <DATE>
   Events:
     Type    Reason     Age    From               Message
     ----    ------     ----   ----               -------
     Normal  Created    15m    weblogic.operator  Domain accessdomain was created.
     Normal  Available  2m56s  weblogic.operator  Domain accessdomain is available: a sufficient number of its servers have reached the ready state.
     Normal  Completed  2m56s  weblogic.operator  Domain accessdomain is complete because all of the following are true: there is no failure detected, there are no pending server shutdowns, and all servers expected to be running are ready and at their target image, auxiliary images, restart version, and introspect version.
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
   accessdomain-oam-server1                         1/1     Running     0          10m   10.244.5.12   10.250.42.255   <none>           <none>
   helper                                           1/1     Running     0          40m   10.244.6.60   10.250.42.252   <none>           <none>
   ```

   You are now ready to configure an Ingress to direct traffic for your OAM domain as per [Configure an Ingress for an OAM domain](../configure-ingress/).



