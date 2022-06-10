+++
title = "Create WebCenter Portal domain"
weight = 3
pre = "<b>  </b>"
description = "Create an Oracle WebCenter Portal domain home on an existing PV or PVC, and create the domain resource YAML file for deploying the generated Oracle WebCenter Portal domain."
+++

#### Contents

* [Introduction](#introduction)
* [Prerequisites](#prerequisites)
* [Prepare the WebCenter Portal Domain Creation Input File](#prepare-the-webcenter-portal-domain-creation-input-file)
* [Create the WebCenter Portal Domain](#create-the-webcenter-portal-domain)
* [Initialize the WebCenter Portal Domain](#initialize-the-webcenter-portal-domain)
* [Verify the WebCenter Portal Domain](#verify-the-webcenter-portal-domain)
* [Managing WebCenter Portal](#managing-webcenter-portal)


#### Introduction

You can use the sample scripts to create a WebCenter Portal domain home on an existing Kubernetes persistent volume (PV) and persistent volume claim (PVC).The scripts also generate the domain YAML file, which helps you start the Kubernetes artifacts of the corresponding domain.

#### Prerequisites

* Ensure that you have completed all of the steps under [prepare-your-environment]({{< relref "/wcportal-domains/prepare-your-environment/_index.md">}}). 
* Ensure that the database and the WebLogic Kubernetes operator is up.

#### Prepare the WebCenter Portal Domain Creation Input File

If required, you can customize the parameters used for creating a domain in the `create-domain-inputs.yaml` file.

Please note that the sample scripts for the WebCenter Portal domain deployment are available from the previously downloaded repository at  `${WORKDIR}/create-wcp-domain/domain-home-on-pv/`.
  
Make a copy of the `create-domain-inputs.yaml` file before updating the default values.

The default domain created by the script has the following characteristics:

* An Administration Server named `AdminServer` listening on port `7001`.
* A configured cluster named `wcp-cluster` of size `5`.
* Managed Server, named `wcpserver`, listening on port `8888`.
* If `configurePortletServer` is set to `true` . It configures a cluster named `wcportlet-cluster` of size `5` and Managed Server, named `wcportletserver`, listening on port `8889`.
* Log files that are located in `/shared/logs/<domainUID>`.

##### Configuration parameters
The following parameters can be provided in the inputs file:

| Parameter | Definition | Default |
| --- | --- | --- |
| `adminPort` | Port number for the Administration Server inside the Kubernetes cluster. | `7001` |
| `sslEnabled` | SSL mode enabling flag  | `false` |
| `configurePortletServer` |Configure portlet server cluster   | `false` |
| `adminServerSSLPort` | SSL Port number for the Administration Server inside the Kubernetes cluster. | `7002` |
| `adminServerName` | Name of the Administration Server. | `AdminServer` |
| `clusterName` | Name of the WebLogic cluster instance to generate for the domain. By default the cluster name is `wcp-cluster` for the WebCenter Portal domain. | `wcp-cluster` |
| `portletClusterName` | Name of the Portlet cluster instance to generate for the domain. By default the cluster name is `wcportlet-cluster` for the Portlet. | `wcportlet-cluster` |
| `configuredManagedServerCount` | Number of Managed Server instances for the domain. | `5` |
| `createDomainFilesDir` | Directory on the host machine to locate all the files that you need to create a WebLogic domain, including the script that is specified in the `createDomainScriptName` property. By default, this directory is set to the relative path `wlst`, and the *create script* uses the built-in WLST offline scripts in the `wlst` directory to create the WebLogic domain. An absolute path is also supported to point to an arbitrary directory in the file system. The built-in scripts can be replaced by the user-provided scripts or model files as long as those files are in the specified directory. Files in this directory are put into a Kubernetes config map, which in turn is mounted to `createDomainScriptsMountPath,` so that the Kubernetes pod can use the scripts and supporting files to create a domain home. | `wlst` |
| `createDomainScriptsMountPath` | Mount path where the *create domain* scripts are located inside a pod. The `create-domain.sh` script creates a Kubernetes job to run the script (specified in the `createDomainScriptName` property) in a Kubernetes pod that creates a domain home. Files in the `createDomainFilesDir` directory are mounted to this location in the pod, so that the Kubernetes pod can use the scripts and supporting files to create a domain home. | `/u01/weblogic` |
| `createDomainScriptName` | Script that the *create domain* script uses to create a WebLogic domain. The `create-domain.sh` script creates a Kubernetes job to run this script that creates a domain home. The script is located in the *in-pod* directory that is specified in the `createDomainScriptsMountPath` property. If you need to provide your own scripts to create the domain home, instead of using the built-in scripts, you must use this property to set the name of the script to that which you want the *create* domain job to run. | `create-domain-job.sh` |
| `domainHome` | Home directory of the WebCenter Portal domain. `This field cannot be modified.` | `/u01/oracle/user_projects/domains/wcp-domain` |
| `domainPVMountPath` | Mount path of the domain persistent volume. `This field cannot be modified.` | `/u01/oracle/user_projects/domains` |
| `domainUID` | Unique ID that identifies this particular domain. Used as the name of the generated WebLogic domain as well as the name of the Kubernetes domain resource. This ID must be unique across all domains in a Kubernetes cluster. This ID cannot contain any character that is not valid in a Kubernetes service name. | `wcp-domain` |
| `exposeAdminNodePort` | Boolean indicating if the Administration Server is exposed outside of the Kubernetes cluster. | `false` |
| `exposeAdminT3Channel` | Boolean indicating if the T3 administrative channel is exposed outside the Kubernetes cluster. | `false` |
| `image` | WebCenter Portal Docker image. The WebLogic Kubernetes Operator requires WebCenter Portal release 12.2.1.4. Refer to [WebCenter Portal Docker Image](https://github.com/oracle/docker-images/tree/main/OracleWebCenterPortal) for details on how to obtain or create the image. | `oracle/wcportal:12.2.1.4` |
| `imagePullPolicy` | WebLogic Docker image pull policy. Legal values are `IfNotPresent`, `Always`, or `Never` | `IfNotPresent` |
| `imagePullSecretName` | Name of the Kubernetes secret to access the Docker Store to pull the WebLogic Server Docker image. The presence of the secret is validated when this parameter is specified. |  |
| `includeServerOutInPodLog` | Boolean indicating whether to include *server.out* to the pod's stdout. | `true` |
| `initialManagedServerReplicas` | Number of Managed Server to initially start for the domain. | `2` |
| `javaOptions` | Java options for starting the Administration Server and Managed Servers. A Java option can include references to one or more of the following pre-defined variables to obtain WebLogic domain information: `$(DOMAIN_NAME)`, `$(DOMAIN_HOME)`, `$(ADMIN_NAME)`, `$(ADMIN_PORT)`, and `$(SERVER_NAME)`. | `-Dweblogic.StdoutDebugEnabled=false` |
| `logHome` | The in-pod location for the domain log, server logs, server out, and Node Manager log files. `This field cannot be modified.` | `/u01/oracle/user_projects/logs/wcp-domain` |
| `managedServerNameBase` | Base string used to generate Managed Server names. | `wcpserver` |
| `portletServerNameBase` | Base string used to generate Portlet Server names. | `wcportletserver` |
| `managedServerPort` | Port number for each Managed Server. By default the managedServerPort is `8888` for the `wcpserver` and managedServerPort is `8889` for the `wcportletserver`. | `8888` |
| `managedServerSSLPort` | SSL port number for each Managed Server. By default the managedServerPort is `8788` for the wcpserver and managedServerPort is `8789` for the `wcportletserver`. | `8788` |
| `portletServerPort` |Port number for each Portlet Server. By default the portletServerPort is `8889` for the `wcportletserver`. | `8888` |
| `portletServerSSLPort` |SSL port number for each Portlet Server. By default the portletServerSSLPort is `8789` for the `wcportletserver`. | `8789` |
| `namespace` | Kubernetes namespace in which to create the domain. | `wcpns` |
| `persistentVolumeClaimName` | Name of the persistent volume claim created to host the domain home. If not specified, the value is derived from the `domainUID` as `<domainUID>-weblogic-sample-pvc`. | `wcp-domain-domain-pvc` |
| `productionModeEnabled` | Boolean indicating if production mode is enabled for the domain. | `true` |
| `serverStartPolicy` | Determines which WebLogic Server instances are to be started. Legal values are `NEVER`, `IF_NEEDED`, `ADMIN_ONLY`. | `IF_NEEDED` |
| `t3ChannelPort` | Port for the T3 channel of the *NetworkAccessPoint*. | `30012` |
| `t3PublicAddress` | Public address for the T3 channel.  This should be set to the public address of the Kubernetes cluster.  This would typically be a load balancer address. <p/>For development environments only: In a single server (all-in-one) Kubernetes deployment, this may be set to the address of the master, or at the very least, it must be set to the address of one of the worker nodes. | If not provided, the script will attempt to set it to the IP address of the Kubernetes cluster. |
| `weblogicCredentialsSecretName` | Name of the Kubernetes secret for the Administration Server's user name and password. If not specified, then the value is derived from the `domainUID` as `<domainUID>-weblogic-credentials`. | wcp-domain-domain-credentials
| `weblogicImagePullSecretName` | Name of the Kubernetes secret for the Docker Store, used to pull the WebLogic Server image. |   |
| `serverPodCpuRequest`, `serverPodMemoryRequest`, `serverPodCpuCLimit`, `serverPodMemoryLimit` |  The maximum amount of compute resources allowed and minimum amount of compute resources required for each server pod. Please refer to the Kubernetes documentation on `Managing Compute Resources for Containers` for details. | Resource requests and resource limits are not specified. Refer to [WebCenter Portal Cluster Sizing Recommendations](../pre-requisites/#webcenter-portal-cluster-sizing-recommendations) for more details. |
| `rcuSchemaPrefix` | The schema prefix to use in the database, for example `WCP1`.  You may wish to make this the same as the domainUID in order to simplify matching domain to their RCU schemas. | `WCP1` |
| `rcuDatabaseURL` | The database URL. | `dbhostname:dbport/servicename` |
| `rcuCredentialsSecret` | The Kubernetes secret containing the database credentials. | `wcp-domain-rcu-credentials` |
| `loadBalancerHostName` | Host name for the final url accessible outside K8S environment. | `abc.def.com` |
| `loadBalancerPortNumber` | Port for the final url accessible outside K8S environment. | `30305` |
| `loadBalancerProtocol` | Protocol for the final url accessible outside K8S environment. | `http` |
| `loadBalancerType` | Loadbalancer name. Example: Traefik or "" | `traefik` |
| `unicastPort` | Starting range of unicast port that application will use. | `50000` |

You can form the names of the Kubernetes resources in the generated YAML files with the value of these properties
specified in the `create-domain-inputs.yaml` file: `adminServerName`, `clusterName` and `managedServerNameBase.` Characters that are invalid in a Kubernetes service name are converted to valid values in the
generated YAML files. For example, an uppercase letter is converted to a lowercase letter and an underscore ("_") is converted to a
hyphen ("-") .

The sample demonstrates how to create a WebCenter Portal domain home and associated Kubernetes resources for a domain that has one cluster only. In addition, the sample provides users with the capability to supply their own scripts to create the domain home for other use cases. You can modify the generated domain YAML file to include more use cases.

#### Create the WebCenter Portal Domain

The syntax of the `create-domain.sh` script is as follows:   
 ```
    $ ./create-domain.sh \
     -i create-domain-inputs.yaml \
     -o /<path to output-directory>
```
    
The script performs the following functions:
* Creates a directory for the generated Kubernetes YAML files for this domain if it does not already exist.  The path name is `/<path to output-directory>/weblogic-domains/<domainUID>`.If the directory already exists, remove its content before using this script.
* Creates a Kubernetes job to start the WebCenter Portal Container utility and run offline WLST scripts that create the domain on the shared storage.
* Runs and waits for the job to finish.
* Creates a Kubernetes domain YAML file, `domain.yaml`, in the directory that is created above.
  This YAML file can be used to create the Kubernetes resource using the `kubectl create -f`
or `kubectl apply -f` command:
    
 ```
 $ kubectl apply -f ../<path to output-directory>/weblogic-domains/<domainUID>/domain.yaml
 ```   
    
* Creates a convenient utility script, `delete-domain-job.yaml`, to clean up the domain home created by the *create* script.

1. Run the `create-domain.sh` sample script, pointing it at the `create-domain-inputs.yaml` inputs file and an output directory like below:

    ```bash
    $ cd ${WORKDIR}/create-wcp-domain/
    $ sh create-domain.sh  -i create-domain-inputs.yaml  -o output
      Input parameters being used
      export version="create-weblogic-sample-domain-inputs-v1"
      export sslEnabled="false"
      export adminPort="7001"
      export adminServerSSLPort="7002"
      export adminServerName="AdminServer"
      export domainUID="wcp-domain"
      export domainHome="/u01/oracle/user_projects/domains/$domainUID"
      export serverStartPolicy="IF_NEEDED"
      export clusterName="wcp-cluster"
      export configuredManagedServerCount="5"
      export initialManagedServerReplicas="2"
      export managedServerNameBase="wcpserver"
      export managedServerPort="8888"
      export managedServerSSLPort="8788"
      export portletServerPort="8889"
      export portletServerSSLPort="8789"
      export image="oracle/wcportal:12.2.1.4"
      export imagePullPolicy="IfNotPresent"
      export productionModeEnabled="true"
      export weblogicCredentialsSecretName="wcp-domain-domain-credentials"
      export includeServerOutInPodLog="true"
      export logHome="/u01/oracle/user_projects/domains/logs/$domainUID"
      export httpAccessLogInLogHome="true"
      export t3ChannelPort="30012"
      export exposeAdminT3Channel="false"
      export adminNodePort="30701"
      export exposeAdminNodePort="false"
      export namespace="wcpns"
      javaOptions=-Dweblogic.StdoutDebugEnabled=false
      export persistentVolumeClaimName="wcp-domain-domain-pvc"
      export domainPVMountPath="/u01/oracle/user_projects/domains"
      export createDomainScriptsMountPath="/u01/weblogic"
      export createDomainScriptName="create-domain-job.sh"
      export createDomainFilesDir="wlst"
      export rcuSchemaPrefix="WCP1"
      export rcuDatabaseURL="oracle-db.wcpns.svc.cluster.local:1521/devpdb.k8s"
      export rcuCredentialsSecret="wcp-domain-rcu-credentials"
      export loadBalancerHostName="abc.def.com"
      export loadBalancerPortNumber="30305"
      export loadBalancerProtocol="http"
      export loadBalancerType="traefik"
      export unicastPort="50000"
      
      Generating output/weblogic-domains/wcp-domain/create-domain-job.yaml
      Generating output/weblogic-domains/wcp-domain/delete-domain-job.yaml
      Generating output/weblogic-domains/wcp-domain/domain.yaml
      Checking to see if the secret wcp-domain-domain-credentials exists in namespace wcpns
      configmap/wcp-domain-create-wcp-infra-sample-domain-job-cm created
      Checking the configmap wcp-domain-create-wcp-infra-sample-domain-job-cm was created
      configmap/wcp-domain-create-wcp-infra-sample-domain-job-cm labeled
      Checking if object type job with name wcp-domain-create-wcp-infra-sample-domain-job exists
      Deleting wcp-domain-create-wcp-infra-sample-domain-job using output/weblogic-domains/wcp-domain/create-domain-job.yaml
      job.batch "wcp-domain-create-wcp-infra-sample-domain-job" deleted
      $loadBalancerType is NOT empty
      Creating the domain by creating the job output/weblogic-domains/wcp-domain/create-domain-job.yaml
      job.batch/wcp-domain-create-wcp-infra-sample-domain-job created
      Waiting for the job to complete...
      status on iteration 1 of 20
      pod wcp-domain-create-wcp-infra-sample-domain-job-b5l6c status is Running
      status on iteration 2 of 20
      pod wcp-domain-create-wcp-infra-sample-domain-job-b5l6c status is Running
      status on iteration 3 of 20
      pod wcp-domain-create-wcp-infra-sample-domain-job-b5l6c status is Running
      status on iteration 4 of 20
      pod wcp-domain-create-wcp-infra-sample-domain-job-b5l6c status is Running
      status on iteration 5 of 20
      pod wcp-domain-create-wcp-infra-sample-domain-job-b5l6c status is Running
      status on iteration 6 of 20
      pod wcp-domain-create-wcp-infra-sample-domain-job-b5l6c status is Running
      status on iteration 7 of 20
      pod wcp-domain-create-wcp-infra-sample-domain-job-b5l6c status is Completed
      
      Domain wcp-domain was created and will be started by the WebLogic Kubernetes Operator
      
      The following files were generated:
        output/weblogic-domains/wcp-domain/create-domain-inputs.yaml
        output/weblogic-domains/wcp-domain/create-domain-job.yaml
        output/weblogic-domains/wcp-domain/domain.yaml
      
      Completed
    ```

1. To monitor the above domain creation logs:

    ```bash
    $ kubectl get pods -n wcpns |grep wcp-domain-create
     
    wcp-domain-create-fmw-infra-sample-domain-job-8jr6k   1/1     Running   0          6s
    ```
    
    ```bash
    $ kubectl get pods -n wcpns | grep wcp-domain-create | awk '{print $1}' | xargs kubectl -n wcpns logs -f 
    ```
      
    SAMPLE OUTPUT:
    ```
   The domain will be created using the script /u01/weblogic/create-domain-script.sh
   
   Initializing WebLogic Scripting Tool (WLST) ...
     
     
   Welcome to WebLogic Server Administration Scripting Shell
     
   Type help() for help on available commands
     
   =================================================================
      WebCenter Portal Weblogic Operator Domain Creation Script
                           12.2.1.4.0
   =================================================================
   Creating Base Domain...
   Creating Admin Server...
   Creating cluster...
   managed server name is wcpserver1
   managed server name is wcpserver2
   managed server name is wcpserver3
   managed server name is wcpserver4
   managed server name is wcpserver5
   ['wcpserver1', 'wcpserver2', 'wcpserver3', 'wcpserver4', 'wcpserver5']
   Creating porlet cluster...
   managed server name is wcportletserver1
   managed server name is wcportletserver2
   managed server name is wcportletserver3
   ['wcportletserver1', 'wcportletserver2', 'wcportletserver3', 'wcportletserver4', 'wcportletserver5']
   Managed servers created...
   Creating Node Manager...
   Will create Base domain at /u01/oracle/user_projects/domains/wcp-domain
   Writing base domain...
   Base domain created at /u01/oracle/user_projects/domains/wcp-domain
   Extending Domain...
   Extending domain at /u01/oracle/user_projects/domains/wcp-domain
   Database  oracle-db.wcpns.svc.cluster.local:1521/devpdb.k8s
   ExposeAdminT3Channel false with 100.111.157.155:30012
   Applying JRF templates...
   Applying WCPortal templates...
   Extension Templates added...
   WC_Portal Managed server deleted...
   Configuring the Service Table DataSource...
   fmwDatabase  jdbc:oracle:thin:@oracle-db.wcpns.svc.cluster.local:1521/devpdb.k8s
   Getting Database Defaults...
   Targeting Server Groups...
   Set CoherenceClusterSystemResource to defaultCoherenceCluster for server:wcpserver1
   Set CoherenceClusterSystemResource to defaultCoherenceCluster for server:wcpserver2
   Set CoherenceClusterSystemResource to defaultCoherenceCluster for server:wcpserver3
   Set CoherenceClusterSystemResource to defaultCoherenceCluster for server:wcpserver4
   Set CoherenceClusterSystemResource to defaultCoherenceCluster for server:wcpserver5
   Set CoherenceClusterSystemResource to defaultCoherenceCluster for server:wcportletserver1
   Set CoherenceClusterSystemResource to defaultCoherenceCluster for server:wcportletserver2
   Set CoherenceClusterSystemResource to defaultCoherenceCluster for server:wcportletserver3
   Targeting Cluster ...
   Set CoherenceClusterSystemResource to defaultCoherenceCluster for cluster:wcp-cluster
   Set WLS clusters as target of defaultCoherenceCluster:wcp-cluster
   Set CoherenceClusterSystemResource to defaultCoherenceCluster for cluster:wcportlet-cluster
   Set WLS clusters as target of defaultCoherenceCluster:wcportlet-cluster
   Preparing to update domain...
   Jan 12, 2021 10:30:09 AM oracle.security.jps.az.internal.runtime.policy.AbstractPolicyImpl initializeReadStore
   INFO: Property for read store in parallel: oracle.security.jps.az.runtime.readstore.threads = null
   Domain updated successfully
   Domain Creation is done...
   Successfully Completed          
    ```

#### Initialize the WebCenter Portal Domain

To start the domain, apply the above `domain.yaml`:

```bash
$ kubectl apply -f output/weblogic-domains/wcp-domain/domain.yaml
domain.weblogic.oracle/wcp-domain created
```

#### Verify the WebCenter Portal Domain        
Verify that the domain and servers pods and services are created and in the READY state:

Sample run below:
```bash
-bash-4.2$ kubectl get pods -n wcpns -w
NAME                                                    READY   STATUS      	RESTARTS	AGE
wcp-domain-create-fmw-infra-sample-domain-job-8jr6k     0/1     Completed   	0          	15m
wcp-domain-adminserver                                  1/1     Running         0          8m9s
wcp-domain-create-fmw-infra-sample-domain-job-8jr6k     0/1     Completed       0          3h6m
wcp-domain-wcp-server1                                  0/1     Running         0          6m5s
wcp-domain-wcp-server2                                  0/1     Running         0          6m4s
wcp-domain-wcp-server2                                  1/1     Running         0          6m18s
wcp-domain-wcp-server1                                  1/1     Running         0          6m54s

```

```bash
-bash-4.2$ kubectl get all -n wcpns
NAME                                                      READY   STATUS      RESTARTS   AGE
pod/wcp-domain-adminserver                                1/1     Running     0          13m
pod/wcp-domain-create-fmw-infra-sample-domain-job-8jr6k   0/1     Completed   0          3h12m
pod/wcp-domain-wcp-server1                                1/1     Running     0          11m
pod/wcp-domain-wcp-server2                                1/1     Running     0          11m
pod/wcp-domain-wcportletserver1                           1/1     Running     1          21h


NAME                                             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/wcp-domain-adminserver                   ClusterIP   None            <none>        7001/TCP   13m
service/wcp-domain-cluster-wcp-cluster           ClusterIP   10.98.145.173   <none>        8888/TCP   11m
service/wcp-domain-wcp-server1                   ClusterIP   None            <none>        8888/TCP   11m
service/wcp-domain-wcp-server2                   ClusterIP   None            <none>        8888/TCP   11m
service/wcp-domain-cluster-wcportlet-cluster     ClusterIP   10.98.145.173   <none>        8889/TCP   11m
service/wcp-domain-wcportletserver1              ClusterIP   None            <none>        8889/TCP   11m


NAME                                                      COMPLETIONS   DURATION   AGE
job.batch/wcp-domain-create-fmw-infra-sample-domain-job   1/1           16m        3h12m
```

To see the Admin and Managed Servers logs, you can check the pod logs:

```bash
$ kubectl logs -f wcp-domain-adminserver -n wcpns
```

```bash
$ kubectl logs -f wcp-domain-wcp-server1  -n wcpns
```

#### Verify the Pods

Use the following command to see the pods running the servers:

```
$ kubectl get pods -n NAMESPACE
```

Here is an example of the output of this command:

```
-bash-4.2$ kubectl get pods -n wcpns
NAME                                                  READY   STATUS      RESTARTS   AGE
rcu                                                   1/1     Running     1          14d
wcp-domain-adminserver                                1/1     Running     0          16m
wcp-domain-create-fmw-infra-sample-domain-job-8jr6k   0/1     Completed   0          3h14m
wcp-domain-wcp-server1                                1/1     Running     0          14m
wcp-domain-wcp-server2                                1/1     Running     0          14m
wcp-domain-wcportletserver1                           1/1     Running     1          14m

```

#### Verify the Services

Use the following command to see the services for the domain:

```
$ kubectl get services -n NAMESPACE
```

Here is an example of the output of this command:
```
-bash-4.2$ kubectl get services -n wcpns
NAME                                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
wcp-domain-adminserver                  ClusterIP   None            <none>        7001/TCP   17m
wcp-domain-cluster-wcp-cluster          ClusterIP   10.98.145.173   <none>        8888/TCP   14m
wcp-domain-wcp-server1                  ClusterIP   None            <none>        8888/TCP   14m
wcp-domain-wcp-server2                  ClusterIP   None            <none>        8888/TCP   14m
wcp-domain-cluster-wcportlet-cluster    ClusterIP   10.98.145.173   <none>        8889/TCP   14m
wcp-domain-wcportletserver1             ClusterIP   None            <none>        8889/TCP   14m

```
#### Managing WebCenter Portal 

To stop Managed Servers:

```bash
$ kubectl patch domain wcp-domain -n wcpns --type='json' -p='[{"op": "replace", "path": "/spec/clusters/0/replicas", "value": 0 }]'
```

To start all configured Managed Servers:

```bash
$ kubectl patch domain wcp-domain -n wcpns --type='json' -p='[{"op": "replace", "path": "/spec/clusters/0/replicas", "value": 3 }]' 
```

```bash
	-bash-4.2$ kubectl get pods -n wcpns -w
      NAME                                                    READY   STATUS      	RESTARTS	AGE
      wcp-domain-create-fmw-infra-sample-domain-job-8jr6k     0/1     Completed   	0          	15m
      wcp-domain-adminserver                                  1/1     Running         0          8m9s
      wcp-domain-create-fmw-infra-sample-domain-job-8jr6k     0/1     Completed       0          3h6m
      wcp-domain-wcp-server1                                  0/1     Running         0          6m5s
      wcp-domain-wcp-server2                                  0/1     Running         0          6m4s
      wcp-domain-wcp-server2                                  1/1     Running         0          6m18s
      wcp-domain-wcp-server1                                  1/1     Running         0          6m54s
```
	
