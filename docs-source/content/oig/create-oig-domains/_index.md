+++
title = "Create OIG domains"
weight = 4
pre = "<b>4. </b>"
description = "Sample for creating an OIG domain home on an existing PV or PVC, and the domain resource YAML file for deploying the generated OIG domain."
+++


1. [Introduction](#introduction)
1. [Prerequisites](#prerequisites)
1. [Prepare the Create Domain Script](#prepare-the-create-domain-script)
    1. [Edit Configuration Parameters](#edit-configuration-parameters)
1. [Run the Create Domain Script](#run-the-create-domain-script)
    1. [Generate the Create Domain Script](#generate-the-create-domain-script)
	1. [Create Docker Registry Secret](#create-docker-registry-secret)
	1. [Setting the OIM Server Memory Parameters](#setting-the-oim-server-memory-parameters)
	1. [Run the Create Domain Scripts](#run-the-create-domain-scripts)
1. [Verify the Results](#verify-the-results)
    1. [Verify the Domain, Pods and Services](#verify-the-domain-pods-and-services)
	1. [Verify the Domain](#verify-the-domain)
	1. [Verify the Pods](#verify-the-pods)
	
### Introduction

The OIG deployment scripts demonstrate the creation of an OIG domain home on an existing Kubernetes persistent volume (PV) and persistent volume claim (PVC). The scripts also generate the domain YAML file, which can then be used to start the Kubernetes artifacts of the corresponding domain.

### Prerequisites

Before you begin, perform the following steps:

1. Review the [Domain resource](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/domain-resource) documentation.
1. Ensure that you have executed all the preliminary steps documented in [Prepare your environment]({{< relref "/oig/prepare-your-environment" >}}).
1. Ensure that the database is up and running.

#### Create Docker Registry Secret

This section should only be followed if you are using a registry to store your container images and have not downloaded the container image to the master and worker nodes. 

1. Create a Docker Registry Secret with name `oig-docker`. The operator validates the presence of this secret.  The OIG image has been manually loaded in [Install the OIG Docker Image]({{< relref "/oig/prepare-your-environment#install-the-oig-docker-image" >}}) so you can run this command as is. The presence of the secret is sufficient for creating the Kubernetes resource in the next step.


   ```bash
   $ kubectl create secret docker-registry oig-docker -n <domain_namespace> --docker-username='<user_name>' --docker-password='<password>' --docker-server='<docker_registry_url>' --docker-email='<email_address>'
   ```
   
   For example:
   
   ```bash
   $ kubectl create secret docker-registry oig-docker -n oigns --docker-username='<user_name>' --docker-password='<password>' --docker-server='<docker_registry_url>' --docker-email='<email_address>'
   ```
   
   **Note**: The above command should be run as described. Do not change anything other than the `<domain_namespace>`.
   
   
   
   The output will look similar to the following:
   
   ```bash
   secret/oig-docker created
   ```

### Prepare the Create Domain Script

The sample scripts for Oracle Identity Governance domain deployment are available at `<weblogic-kubernetes-operator-project>/kubernetes/samples/scripts/create-oim-domain`.

1. Make a copy of the `create-domain-inputs.yaml` file:

   ```bash
   $ cd <work directory>/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-oim-domain/domain-home-on-pv
   $ cp create-domain-inputs.yaml create-domain-inputs.yaml.orig   
   ```
   
   For example:
   
   ```bash
   $ cd /scratch/OIGDockerK8S/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-oim-domain/domain-home-on-pv
   $ cp create-domain-inputs.yaml create-domain-inputs.yaml.orig
   ```
    
   You must edit `create-domain-inputs.yaml` (or a copy of it) to provide the details for your domain. Please refer to the configuration parameters below to understand the information that you must
   provide in this file.

#### Edit Configuration Parameters

1. Edit the `create-domain-inputs.yaml` and modify the following parameters. Save the file when complete:   

   ```bash
   domainUID: <domain_uid>
   domainHome: /u01/oracle/user_projects/domains/<domain_uid>
   image: <image_name>
   namespace: <domain_namespace>
   weblogicCredentialsSecretName: <kubernetes_domain_secret>
   persistentVolumeClaimName: <pvc_name>
   logHome: /u01/oracle/user_projects/domains/logs/<domain_id>
   rcuSchemaPrefix: <rcu_prefix>
   rcuDatabaseURL: <rcu_db_host>:<rcu_db_port>/<rcu_db_service_name>
   rcuCredentialsSecret: <kubernetes_rcu_secret>
   frontEndHost: <front_end_hostname>
   frontEndPort: <front_end_port>
   ```

   For example:

   ```bash
   domainUID: governancedomain
   domainHome: /u01/oracle/user_projects/domains/governancedomain
   image: oracle/oig:12.2.1.4.0
   namespace: oigns
   weblogicCredentialsSecretName: oig-domain-credentials
   persistentVolumeClaimName: governancedomain-domain-pvc
   logHome: /u01/oracle/user_projects/domains/logs/governancedomain
   rcuSchemaPrefix: OIGK8S
   rcuDatabaseURL: mydatabasehost.example.com:1521/orcl.example.com
   rcuCredentialsSecret: oig-rcu-credentials
   frontEndHost: masternode.example.com
   frontEndPort: 14100
   ```
   
   **Note**: `frontEndHost` and <front_end_port> should be set to the entry point host and port for OIM. This can be changed later in [Set OIMFrontendURL using MBeans](../post-install-config).
   
   **Note**: If using a container registry for your container images then you need to set `image` to the repository image name and `imagePullSecretName` to the name of the secret created earlier e.g: `oig-docker`.

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
| `domainPVMountPath` | Mount path of the domain persistent volume. | `/u01/oracle/user_projects` |
| `domainUID` | Unique ID that will be used to identify this particular domain. Used as the name of the generated WebLogic domain as well as the name of the Kubernetes domain resource. This ID must be unique across all domains in a Kubernetes cluster. This ID cannot contain any character that is not valid in a Kubernetes service name. | `oimcluster` |
| `exposeAdminNodePort` | Boolean indicating if the Administration Server is exposed outside of the Kubernetes cluster. | `false` |
| `exposeAdminT3Channel` | Boolean indicating if the T3 administrative channel is exposed outside the Kubernetes cluster. | `true` |
| `image` | OIG Docker image. The operator requires OIG 12.2.1.4. Refer to [OIG domains]({{< relref "/oig/prepare-your-environment#install-the-oig-docker-image" >}}) for details on how to obtain or create the image. | `oracle/oig:12.2.1.4.0` |
| `imagePullPolicy` | WebLogic Docker image pull policy. Legal values are `IfNotPresent`, `Always`, or `Never` | `IfNotPresent` |
| `imagePullSecretName` | Name of the Kubernetes secret to access the Docker Store to pull the WebLogic Server Docker image. The presence of the secret will be validated when this parameter is specified. |  |
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
| `weblogicImagePullSecretName` | Name of the Kubernetes secret for the Docker Store, used to pull the WebLogic Server image. |   |
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

### Run the Create Domain Script

#### Generate the Create Domain Script

1. Run the create domain script, specifying your inputs file and an output directory to store the
generated artifacts:

   ```bash
   $ cd <work directory>/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-oim-domain/domain-home-on-pv
   $ mkdir output
   $ ./create-domain.sh -i create-domain-inputs.yaml -o /<path to output-directory>
   ```

   For example:
   
   ```bash
   $ cd /scratch/OIGDockerK8S/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-oim-domain/domain-home-on-pv
   $ mkdir output
   $ ./create-domain.sh -i create-domain-inputs.yaml -o output
   ```
   
   The output will look similar to the following:
   
   ```bash
   $ ./create-domain.sh -i create-domain-inputs.yaml -o output
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
   export image="oracle/oig:12.2.1.4.0"
   export imagePullPolicy="IfNotPresent"
   export imagePullSecretName="oig-docker"
   export productionModeEnabled="true"
   export weblogicCredentialsSecretName="oig-domain-credentials"
   export includeServerOutInPodLog="true"
   export logHome="/u01/oracle/user_projects/domains/logs/governancedomain"
   export t3ChannelPort="30012"
   export exposeAdminT3Channel="false"
   export adminNodePort="30701"
   export exposeAdminNodePort="false"
   export namespace="governancedomain"
   javaOptions=-Dweblogic.StdoutDebugEnabled=false
   export persistentVolumeClaimName="governancedomain-domain-pvc"
   export domainPVMountPath="/u01/oracle/user_projects/domains"
   export createDomainScriptsMountPath="/u01/weblogic"
   export createDomainScriptName="create-domain-job.sh"
   export createDomainFilesDir="wlst"
   export rcuSchemaPrefix="OIGK8S"
   export rcuDatabaseURL="mydatabasehost.example.com:1521/orcl.example.com"
   export rcuCredentialsSecret="oig-rcu-credentials"
   export frontEndHost="100.102.48.49"
   export frontEndPort="80"

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
   pod governancedomain-create-fmw-infra-sample-domain-job-dktkk status is Running
   status on iteration 2 of 40
   pod governancedomain-create-fmw-infra-sample-domain-job-dktkk status is Running
   status on iteration 3 of 40
   pod governancedomain-create-fmw-infra-sample-domain-job-dktkk status is Running
   status on iteration 4 of 40
   pod governancedomain-create-fmw-infra-sample-domain-job-dktkk status is Running
   status on iteration 5 of 40
   pod governancedomain-create-fmw-infra-sample-domain-job-dktkk status is Running
   status on iteration 6 of 40
   pod governancedomain-create-fmw-infra-sample-domain-job-dktkk status is Running
   status on iteration 7 of 40
   pod governancedomain-create-fmw-infra-sample-domain-job-dktkk status is Running
   status on iteration 8 of 40
   pod governancedomain-create-fmw-infra-sample-domain-job-dktkk status is Running
   status on iteration 9 of 40
   pod governancedomain-create-fmw-infra-sample-domain-job-dktkk status is Running
   status on iteration 10 of 40
   pod governancedomain-create-fmw-infra-sample-domain-job-dktkk status is Running
   status on iteration 11 of 40
   pod governancedomain-create-fmw-infra-sample-domain-job-dktkk status is Completed

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

#### Setting the OIM Server Memory Parameters

1. Navigate to the `output` directory:

   ```bash
   $ cd <work directory>/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-oim-domain/domain-home-on-pv/output/weblogic-domains/governancedomain
   ```
   
   For example:
   
   ```bash
   $ cd /scratch/OIGDockerK8S/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-oim-domain/domain-home-on-pv/output/weblogic-domains/governancedomain
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


#### Run the Create Domain Scripts

1. Create the Kubernetes resource using the following command:

   ```bash
   $ cd <work directory>/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-oim-domain/domain-home-on-pv/output/weblogic-domains/governancedomain
   $ kubectl apply -f domain.yaml
   ```

   For example:

   ```bash
   $ cd /scratch/OIGDockerK8S/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-oim-domain/domain-home-on-pv/output/weblogic-domains/governancedomain
   $ kubectl apply -f domain.yaml
   ```

   The output will look similar to the following:
   
   ```bash
   domain.weblogic.oracle/governancedomain created
   ```

1. Run the following command to view the status of the OIG pods:

   ```bash
   $ kubectl get pods -n oigns
   ```
   
   The output will initially look similar to the following:
   
   ```bash
   NAME                                                        READY   STATUS      RESTARTS   AGE
   helper                                                      1/1     Running     0          3h30m
   governancedomain-create-fmw-infra-sample-domain-job-dktkk   0/1     Completed   0          27m
   governancedomain-introspect-domain-job-p4brt                1/1     Running     0          6s
   ```
   
   The `introspect-domain-job` pod will be displayed first. Run the command again after several minutes and check to see that the AdminServer and SOA Server are both started. When started they should have `STATUS` = `Running` and `READY` = `1/1`.
   
   ```bash
   NAME                                                  READY   STATUS      RESTARTS   AGE
   helper                                                1/1     Running     0          3h38m
   governancedomain-adminserver                                1/1     Running     0          7m30s
   governancedomain-create-fmw-infra-sample-domain-job-dktkk   0/1     Completed   0          35m
   governancedomain-soa-server1                                1/1     Running     0          4m
   ```

   **Note**: It will take several minutes before all the pods listed above show. When a pod has a `STATUS` of `0/1` the pod is started but the OIG server associated with it is currently starting. While the pods are starting you can check the startup status in the pod logs, by running the following command:
   
   ```bash
   $ kubectl logs governancedomain-adminserver -n oigns
   $ kubectl logs governancedomain-soa-server1 -n oigns
   ```
   
   
1. Once both pods are running, start the OIM Server using the following command:

   ```bash
   $ cd <work directory>/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-oim-domain/domain-home-on-pv/output/weblogic-domains/governancedomain
   $ kubectl apply -f domain_oim_soa.yaml
   ```

   For example:

   ```bash
   $ cd /scratch/OIGDockerK8S/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-oim-domain/domain-home-on-pv/output/weblogic-domains/governancedomain
   $ kubectl apply -f domain_oim_soa.yaml
   ```

   The output will look similar to the following:

   ```bash
   domain.weblogic.oracle/governancedomain configured
   ```

### Verify the Results

#### Verify the Domain, Pods and Services

1. Verify the domain, servers pods and services are created and in the `READY` state with a `STATUS` of `1/1`, by running the following command:

   ```bash
   $ kubectl get all,domains -n oigns
   ```
   
   The output will look similar to the following:

   ```bash
   NAME                                                      READY   STATUS      RESTARTS   AGE
   pod/helper                                                1/1     Running     0          3h40m
   pod/governancedomain-adminserver                                1/1     Running     0          16m
   pod/governancedomain-create-fmw-infra-sample-domain-job-dktkk   0/1     Completed   0          36m
   pod/governancedomain-oim-server1                                1/1     Running     0          5m57s
   pod/governancedomain-soa-server1                                1/1     Running     0          13m

   NAME                                     TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)     AGE
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

   NAME                                                      COMPLETIONS   DURATION   AGE
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
  



#### Verify the Domain

To confirm that the domain was created, use this command:

```
$ kubectl describe domain <domain_uid> -n <namespace>
```

For example:
```
$ kubectl describe domain governancedomain -n oigns
```

Here is an example of the output of this command:

```
Name:         governancedomain
Namespace:    oigns
Labels:       weblogic.domainUID=governancedomain
Annotations:  API Version:  weblogic.oracle/v8
Kind:         Domain
Metadata:
  Creation Timestamp:  2020-09-29T14:08:09Z
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
    Manager:      kubectl
    Operation:    Update
    Time:         2020-09-29T14:19:58Z
    API Version:  weblogic.oracle/v8
    Fields Type:  FieldsV1
    fieldsV1:
      f:status:
        .:
        f:clusters:
        f:conditions:
        f:servers:
        f:startTime:
    Manager:         OpenAPI-Generator
    Operation:       Update
    Time:            2020-09-29T14:27:30Z
  Resource Version:  1278400
  Self Link:         /apis/weblogic.oracle/v8/namespaces/oigns/domains/governancedomain
  UID:               94604c47-6995-43c5-8848-5c5975ba5ace
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
    Server Service:
      Precreate Service:        true
    Server Start State:         RUNNING
  Data Home:
  Domain Home:                  /u01/oracle/user_projects/domains/governancedomain
  Domain Home Source Type:      PersistentVolume
  Http Access Log In Log Home:  true
  Image:                        oracle/oig:12.2.1.4.0
  Image Pull Policy:            IfNotPresent
  Image Pull Secrets:
    Name:                         oig-docker
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
    Name:  governancedomain-domain-credentials
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
    Last Transition Time:  2020-09-29T14:25:51.338Z
    Reason:                ServersReady
    Status:                True
    Type:                  Available
  Servers:
    Desired State:  RUNNING
    Health:
      Activation Time:  2020-09-29T14:12:23.439Z
      Overall Health:   ok
      Subsystems:
        Subsystem Name:  ServerRuntime
        Symptoms:
    Node Name:      10.250.111.112
    Server Name:    AdminServer
    State:          RUNNING
    Cluster Name:   oim_cluster
    Desired State:  RUNNING
    Health:
      Activation Time:  2020-09-29T14:25:46.339Z
      Overall Health:   ok
      Subsystems:
        Subsystem Name:  ServerRuntime
        Symptoms:
    Node Name:      10.250.111.112
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
      Activation Time:  2020-09-29T14:15:11.288Z
      Overall Health:   ok
      Subsystems:
        Subsystem Name:  ServerRuntime
        Symptoms:
    Node Name:      10.250.111.112
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
  Start Time:       2020-09-29T14:08:10.085Z
Events:             <none>
```

In the `Status` section of the output, the available servers and clusters are listed.

#### Verify the Pods

Use the following command to see the pods running the servers and which nodes they are running on:

```bash
$ kubectl get pods -n <namespace> -o wide
```

For example:

```bash
$ kubectl get pods -n oigns -o wide
```

The output will look similar to the following:

```bash
NAME                                                        READY   STATUS      RESTARTS   AGE   IP            NODE           NOMINATED NODE   READINESS GATES
helper                                                      1/1     Running     0          3h50m   10.244.1.39   10.250.111.112   <none>           <none>
governancedomain-adminserver                                1/1     Running     0          27m     10.244.1.42   10.250.111.112   <none>           <none>
governancedomain-create-fmw-infra-sample-domain-job-dktkk   0/1     Completed   0          47m     10.244.1.40   10.250.111.112   <none>           <none>
governancedomain-oim-server1                                1/1     Running     0          16m     10.244.1.44   10.250.111.112   <none>           <none>
governancedomain-soa-server1                                1/1     Running     0          24m     10.244.1.43   10.250.111.112   <none>           <none>
```

You are now ready to configure an Ingress to direct traffic for your OIG domain as per [Configure an Ingress for an OIG domain](../configure-ingress).




