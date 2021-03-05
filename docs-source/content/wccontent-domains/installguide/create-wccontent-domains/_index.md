+++
title = "Create Oracle WebCenter Content domain"
date =  2021-02-14T16:43:45-05:00
weight = 3
pre = "<b>  </b>"
description = "Create Oracle WebCenter Content domain home on an existing PV or PVC and create the domain resource YAML file for deploying the generated Oracle WebCenter Content domain."
+++

The  WebCenter Content deployment scripts demonstrate the creation of Oracle WebCenter Content domain home on an existing Kubernetes persistent volume (PV) and persistent volume claim (PVC). The scripts also generate the domain YAML file, which can then be used to start the Kubernetes artifacts of the corresponding domain.

#### Prerequisites

Before you begin, complete the following steps:

1. Review the [Domain resource](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/domain-resource) documentation.
1. Review the [requirements and limitations]({{< relref "/wccontent-domains/installguide/prerequisites" >}}).
1. Ensure that you have executed all the preliminary steps in [Prepare your environment]({{< relref "/wccontent-domains/installguide/prepare-your-environment" >}}).
1. Ensure that the database schemas were created and the WebLogic Kubernetes operator are running.


#### Prepare to use the create domain script

The sample scripts for Oracle WebCenter Content domain deployment are available at `${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-wcc-domain`.

You must edit `create-domain-inputs.yaml` (or a copy of it) to provide the details for your domain.
Refer to the configuration parameters below to understand the information that you must
provide in this file.

#### Configuration parameters
The following parameters can be provided in the inputs file.

| Parameter | Definition | Default |
| --- | --- | --- |
| `sslEnabled` | Boolean indicating whether to enable SSL for each WebLogic Server instance. | `false` |
| `adminPort` | Port number for the Administration Server inside the Kubernetes cluster. | `7001` |
| `adminServerSSLPort` | SSL port number of the Administration Server inside the Kubernetes cluster. | `7002` |
| `adminNodePort` | Port number of the Administration Server outside the Kubernetes cluster. | `30701` |
| `adminServerName` | Name of the Administration Server. | `AdminServer` |
| `clusterName` | Name of the WebLogic cluster instance to generate for the domain. By default the cluster name is ucm_cluster & ibr_cluster for the WebCenter Content domain.| `ucm_cluster` |
| `configuredManagedServerCount` | Number of Managed Server instances to generate for the domain. | `5` |
| `createDomainFilesDir` | Directory on the host machine to locate all the files to create a WebLogic domain, including the script that is specified in the `createDomainScriptName` property. By default, this directory is set to the relative path `wlst`, and the create script will use the built-in WLST offline scripts in the `wlst` directory to create the WebLogic domain. An absolute path is also supported to point to an arbitrary directory in the file system. The built-in scripts can be replaced by the user-provided scripts as long as those files are in the specified directory. Files in this directory are put into a Kubernetes config map, which in turn is mounted to the `createDomainScriptsMountPath`, so that the Kubernetes pod can use the scripts and supporting files to create a domain home. | `wlst` |
| `createDomainScriptsMountPath` | Mount path where the create domain scripts are located inside a pod. The `create-domain.sh` script creates a Kubernetes job to run the script (specified in the `createDomainScriptName` property) in a Kubernetes pod to create a domain home. Files in the `createDomainFilesDir` directory are mounted to this location in the pod, so that the Kubernetes pod can use the scripts and supporting files to create a domain home. | `/u01/weblogic` |
| `createDomainScriptName` | Script that the create domain script uses to create a WebLogic domain. The `create-domain.sh` script creates a Kubernetes job to run this script to create a domain home. The script is located in the in-pod directory that is specified in the `createDomainScriptsMountPath` property. If you need to provide your own scripts to create the domain home, instead of using the built-it scripts, you must use this property to set the name of the script that you want the create domain job to run. | `create-domain-job.sh` |
| `domainHome` | Home directory of the WebCenter Content domain. If not specified, the value is derived from the `domainUID` as `/shared/domains/<domainUID>`. | `/u01/oracle/user_projects/domains/wccinfra` |
| `domainPVMountPath` | Mount path of the domain persistent volume. | `/u01/oracle/user_projects` |
| `domainUID` | Unique ID that will be used to identify this particular domain. Used as the name of the generated WebLogic domain as well as the name of the Kubernetes domain resource. This ID must be unique across all domains in a Kubernetes cluster. This ID cannot contain any character that is not valid in a Kubernetes service name. | `wccinfra` |
| `exposeAdminNodePort` | Boolean indicating if the Administration Server is exposed outside of the Kubernetes cluster. | `false` |
| `exposeAdminT3Channel` | Boolean indicating if the T3 administrative channel is exposed outside the Kubernetes cluster. | `false` |
| `image` | WebCenter Content Docker image. The operator requires Oracle WebCenter Content 12.2.1.4.0 Refer to [Obtain the Oracle WebCenter Content Docker image]({{< relref "/wccontent-domains/installguide/prepare-your-environment#obtain-the-oracle-webcenter-content-docker-image" >}}) for details on how to obtain or create the image. | `oracle/wccontent:12.2.1.4.0` |
| `imagePullPolicy` | WebLogic Docker image pull policy. Legal values are `IfNotPresent`, `Always`, or `Never`. | `IfNotPresent` |
| `imagePullSecretName` | Name of the Kubernetes secret to access the Docker Store to pull the WebLogic Server Docker image. The presence of the secret will be validated when this parameter is specified. |  |
| `includeServerOutInPodLog` | Boolean indicating whether to include the server .out to the pod's stdout. | `true` |
| `initialManagedServerReplicas` | Number of Managed Servers to initially start for the domain. | `3` |
| `javaOptions` | Java options for starting the Administration Server and Managed Servers. A Java option can have references to one or more of the following pre-defined variables to obtain WebLogic domain information: `$(DOMAIN_NAME)`, `$(DOMAIN_HOME)`, `$(ADMIN_NAME)`, `$(ADMIN_PORT)`, and `$(SERVER_NAME)`. If `sslEnabled` is set to `true` and the WebLogic demo certificate is used, add `-Dweblogic.security.SSL.ignoreHostnameVerification=true` to allow the Managed Servers to connect to the Administration Server while booting up.  The WebLogic generated demo certificate in this environment typically contains a host name that is different from the runtime container's host name.  | `-Dweblogic.StdoutDebugEnabled=false` |
| `logHome` | The in-pod location for the domain log, server logs, server out, and Node Manager log files. If not specified, the value is derived from the `domainUID` as `/shared/logs/<domainUID>`. | `/u01/oracle/user_projects/domains/logs/wccinfra` |
| `managedServerNameBase` | Base string used to generate Managed Server names. | `ucm_server` |
| `managedServerPort` | Port number for each Managed Server. By default the `managedServerPort` is `16200` for the ucm_server & `managedServerPort` is `16250 for the ibr_server`.| `16200` |
| `managedServerSSLPort` | SSL port number for each Managed Server. By default the `managedServerSSLPort` is `16201` for the ucm_server & `managedServerSSLPort` is `16251 for the ibr_server`.| `16201` |
| `namespace` | Kubernetes namespace in which to create the domain. | `wccns` |
| `persistentVolumeClaimName` | Name of the persistent volume claim created to host the domain home. If not specified, the value is derived from the `domainUID` as `<domainUID>-weblogic-sample-pvc`. | `wccinfra-domain-pvc` |
| `productionModeEnabled` | Boolean indicating if production mode is enabled for the domain. | `true` |
| `serverStartPolicy` | Determines which WebLogic Server instances will be started. Legal values are `NEVER`, `IF_NEEDED`, `ADMIN_ONLY`. | `IF_NEEDED` |
| `t3ChannelPort` | Port for the t3 channel of the NetworkAccessPoint. | `30012` |
| `t3PublicAddress` | Public address for the T3 channel.  This should be set to the public address of the Kubernetes cluster.  This would typically be a load balancer address. <p/>For development environments only: In a single server (all-in-one) Kubernetes deployment, this may be set to the address of the master, or at the very least, it must be set to the address of one of the worker nodes. | If not provided, the script will attempt to set it to the IP address of the Kubernetes cluster |
| `weblogicCredentialsSecretName` | Name of the Kubernetes secret for the Administration Server's user name and password. If not specified, then the value is derived from the `domainUID` as `<domainUID>-weblogic-credentials`. | `wccinfra-domain-credentials` |
| `weblogicImagePullSecretName` | Name of the Kubernetes secret for the Docker Store, used to pull the WebLogic Server image. |   |
| `serverPodCpuRequest`, `serverPodMemoryRequest`, `serverPodCpuCLimit`, `serverPodMemoryLimit` |  The maximum amount of compute resources allowed, and minimum amount of compute resources required, for each server pod. Please refer to the Kubernetes documentation on `Managing Compute Resources for Containers` for details. | Resource requests and resource limits are not specified. |
| `rcuSchemaPrefix` | The schema prefix to use in the database, for example `WCC1`.  You may wish to make this the same as the domainUID in order to simplify matching domains to their RCU schemas. | `WCC1` |
| `rcuDatabaseURL` | The database URL. | `<YOUR DATABASE CONNECTION DETAILS>` |
| `rcuCredentialsSecret` | The Kubernetes secret containing the database credentials. | `wccinfra-rcu-credentials` |

Note that the names of the Kubernetes resources in the generated YAML files may be formed with the
value of some of the properties specified in the `create-inputs.yaml` file. Those properties include
the `adminServerName`, `clusterName` and `managedServerNameBase`. If those values contain any
characters that are invalid in a Kubernetes service name, those characters are converted to
valid values in the generated YAML files. For example, an uppercase letter is converted to a
lowercase letter and an underscore `("_")` is converted to a hyphen `("-")`.

The sample demonstrates how to create the Oracle WebCenter Content domain home and associated Kubernetes resources for that domain.
In addition, the sample provides the capability for users to supply their own scripts
to create the domain home for other use cases. The generated domain YAML file could also be modified to cover more use cases.

#### Run the create domain script

Run the create domain script, specifying your inputs file and an output directory to store the
generated artifacts:

```
$ ./create-domain.sh \
  -i create-domain-inputs.yaml \
  -o <path to output-directory>
```

The script will perform the following steps:

* Create a directory for the generated Kubernetes YAML files for this domain if it does not
  already exist.  The path name is `<path to output-directory>/weblogic-domains/<domainUID>`.
  If the directory already exists, its contents must be removed before using this script.
* Create a Kubernetes job that will start up a utility Oracle WebCenter Content container and run
  offline WLST scripts to create the domain on the shared storage.
* Run and wait for the job to finish.
* Create a Kubernetes domain YAML file, `domain.yaml`, in the "output" directory that was created above.
  This YAML file can be used to create the Kubernetes resource using the `kubectl create -f`
  or `kubectl apply -f` command. 
* Run `managed-server-wrapper` script, which intrenally applies the domain YAML. This script also applies initial 
  configurations for Managed Server containers and readies Managed Servers for future inter-container communications.

    ```
    $ cd ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-wcc-domain/domain-home-on-pv/
    $ ./start-managed-servers-wrapper.sh -p <load_balancer_port>
    ```

* Create a convenient utility script, `delete-domain-job.yaml`, to clean up the domain home
  created by the create script.



The default domain created by the script has the following characteristics:

* An Administration Server named `AdminServer` listening on port `7001`.
* A configured cluster named `ucm_cluster` of size 3.
* A configured cluster named `ibr_cluster` of size 1.
* Managed Servers, named `ucm_cluster` listening on port `16200`.
* Managed Servers, named `ibr_cluster` listening on port `16250`.
* Log files that are located in `/shared/logs/<domainUID>`.

#### Verify the results

The create domain script will verify that the domain was created, and will report failure if there was any error.
However, it may be desirable to manually verify the domain, even if just to gain familiarity with the
various Kubernetes objects that were created by the script.


##### Generated YAML files with the default inputs

{{%expand "Click here to see sample content of the generated `domain.yaml`." %}}

```
$ cat output/weblogic-domains/wccinfra/domain.yaml
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of how to define a Domain resource.
#
apiVersion: "weblogic.oracle/v8"
kind: Domain
metadata:
  name: wccinfra
  namespace: wccns
  labels:
    weblogic.domainUID: wccinfra
spec:
  # The WebLogic Domain Home
  domainHome: /u01/oracle/user_projects/domains/wccinfra
  maxClusterConcurrentStartup: 1

  # The domain home source type
  # Set to PersistentVolume for domain-in-pv, Image for domain-in-image, or FromModel for model-in-image
  domainHomeSourceType: PersistentVolume

  # The WebLogic Server Docker image that the Operator uses to start the domain
  image: "oracle/wccontent:12.2.1.4.0"

  # imagePullPolicy defaults to "Always" if image version is :latest
  imagePullPolicy: "IfNotPresent"

  # Identify which Secret contains the credentials for pulling an image
  #imagePullSecrets:
  #- name: 

  # Identify which Secret contains the WebLogic Admin credentials (note that there is an example of
  # how to create that Secret at the end of this file)
  webLogicCredentialsSecret: 
    name: wccinfra-domain-credentials

  # Whether to include the server out file into the pod's stdout, default is true
  includeServerOutInPodLog: true

  # Whether to enable log home
  logHomeEnabled: true

  # Whether to write HTTP access log file to log home
  httpAccessLogInLogHome: true

  # The in-pod location for domain log, server logs, server out, and Node Manager log files
  logHome: /u01/oracle/user_projects/domains/logs/wccinfra
  # An (optional) in-pod location for data storage of default and custom file stores.
  # If not specified or the value is either not set or empty (e.g. dataHome: "") then the
  # data storage directories are determined from the WebLogic domain home configuration.
  dataHome: ""


  # serverStartPolicy legal values are "NEVER", "IF_NEEDED", or "ADMIN_ONLY"
  # This determines which WebLogic Servers the Operator will start up when it discovers this Domain
  # - "NEVER" will not start any server in the domain
  # - "ADMIN_ONLY" will start up only the administration server (no managed servers will be started)
  # - "IF_NEEDED" will start all non-clustered servers, including the administration server and clustered servers up to the replica count
  serverStartPolicy: "IF_NEEDED"

  serverPod:
    # an (optional) list of environment variable to be set on the servers
    env:
    - name: JAVA_OPTIONS
      value: "-Dweblogic.StdoutDebugEnabled=false"
    - name: USER_MEM_ARGS
      value: "-Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx512m "
    volumes:
    - name: weblogic-domain-storage-volume
      persistentVolumeClaim:
        claimName: wccinfra-domain-pvc
    volumeMounts:
    - mountPath: /u01/oracle/user_projects/domains
      name: weblogic-domain-storage-volume

  # adminServer is used to configure the desired behavior for starting the administration server.
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
    #    - channelName: T3Channel

  # clusters is used to configure the desired behavior for starting member servers of a cluster.  
  # If you use this entry, then the rules will be applied to ALL servers that are members of the named clusters.
  clusters:
  - clusterName: ibr_cluster
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
    replicas: 1
    serverStartPolicy: "IF_NEEDED"
  # The number of managed servers to start for unlisted clusters
  # replicas: 1

  # Istio
  # configuration:
  #   istio:
  #     enabled: 
  #     readinessPort: 

  - clusterName: ucm_cluster
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
    replicas: 3
    serverStartPolicy: "IF_NEEDED"
  # The number of managed servers to start for unlisted clusters
  # replicas: 1

```
{{% /expand %}}

#### Verify the domain

To confirm that the domain was created, enter the following command:

```
$ kubectl describe domain DOMAINUID -n NAMESPACE
```

Replace `DOMAINUID` with the `domainUID` and `NAMESPACE` with the actual namespace.

{{%expand "Click here to see a sample domain description." %}}

```
$ kubectl describe domain wccinfra -n wccns
Name:         wccinfra
Namespace:    wccns
Labels:       weblogic.domainUID=wccinfra
Annotations:  API Version:  weblogic.oracle/v8
Kind:         Domain
Metadata:
  Creation Timestamp:  2020-11-23T12:48:13Z
  Generation:          7
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
    Time:         2020-11-23T13:50:28Z
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
    Time:            2020-12-03T10:20:52Z
  Resource Version:  18267402
  Self Link:         /apis/weblogic.oracle/v8/namespaces/wccns/domains/wccinfra
  UID:               1a866c30-9b29-4281-bd2b-df80914efdff
Spec:
  Admin Server:
    Admin Service:
      Channels:
        Channel Name:    default
        Node Port:       30701
    Server Start State:  RUNNING
  Clusters:
    Cluster Name:  ibr_cluster
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
    Server Start Policy:  IF_NEEDED
    Server Start State:   RUNNING
    Cluster Name:         ucm_cluster
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
    Server Service:
      Precreate Service:           true
    Server Start Policy:           IF_NEEDED
    Server Start State:            RUNNING
  Data Home:
  Domain Home:                     /u01/oracle/user_projects/domains/wccinfra
  Domain Home Source Type:         PersistentVolume
  Http Access Log In Log Home:     true
  Image:                           oracle/wccontent_ora_final_it:12.2.1.4.0
  Image Pull Policy:               IfNotPresent
  Include Server Out In Pod Log:   true
  Log Home:                        /u01/oracle/user_projects/domains/logs/wccinfra
  Log Home Enabled:                true
  Max Cluster Concurrent Startup:  1
  Server Pod:
    Env:
      Name:   JAVA_OPTIONS
      Value:  -Dweblogic.StdoutDebugEnabled=false
      Name:   USER_MEM_ARGS
      Value:  -Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx512m
    Volume Mounts:
      Mount Path:  /u01/oracle/user_projects/domains
      Name:        weblogic-domain-storage-volume
    Volumes:
      Name:  weblogic-domain-storage-volume
      Persistent Volume Claim:
        Claim Name:     wccinfra-domain-pvc
  Server Start Policy:  IF_NEEDED
  Web Logic Credentials Secret:
    Name:  wccinfra-domain-credentials
Status:
  Clusters:
    Cluster Name:      ibr_cluster
    Maximum Replicas:  5
    Minimum Replicas:  0
    Ready Replicas:    1
    Replicas:          1
    Replicas Goal:     1
    Cluster Name:      ucm_cluster
    Maximum Replicas:  5
    Minimum Replicas:  0
    Ready Replicas:    2
    Replicas:          2
    Replicas Goal:     2
  Conditions:
    Last Transition Time:  2020-11-23T13:58:41.070Z
    Reason:                ServersReady
    Status:                True
    Type:                  Available
  Servers:
    Desired State:  RUNNING
    Health:
      Activation Time:  2020-11-25T16:55:24.930Z
      Overall Health:   ok
      Subsystems:
        Subsystem Name:  ServerRuntime
        Symptoms:
    Node Name:      pjadam
    Server Name:    AdminServer
    State:          RUNNING
    Cluster Name:   ibr_cluster
    Desired State:  RUNNING
    Health:
      Activation Time:  2020-11-30T12:23:27.603Z
      Overall Health:   ok
      Subsystems:
        Subsystem Name:  ServerRuntime
        Symptoms:
    Node Name:      pjadam
    Server Name:    ibr_server1
    State:          RUNNING
    Cluster Name:   ibr_cluster
    Desired State:  SHUTDOWN
    Server Name:    ibr_server2
    Cluster Name:   ibr_cluster
    Desired State:  SHUTDOWN
    Server Name:    ibr_server3
    Cluster Name:   ibr_cluster
    Desired State:  SHUTDOWN
    Server Name:    ibr_server4
    Cluster Name:   ibr_cluster
    Desired State:  SHUTDOWN
    Server Name:    ibr_server5
    Cluster Name:   ucm_cluster
    Desired State:  RUNNING
    Health:
      Activation Time:  2020-12-02T14:10:37.992Z
      Overall Health:   ok
      Subsystems:
        Subsystem Name:  ServerRuntime
        Symptoms:
    Node Name:      pjadam
    Server Name:    ucm_server1
    State:          RUNNING
    Cluster Name:   ucm_cluster
    Desired State:  RUNNING
    Health:
      Activation Time:  2020-12-01T04:51:19.886Z
      Overall Health:   ok
      Subsystems:
        Subsystem Name:  ServerRuntime
        Symptoms:
    Node Name:      pjadam
    Server Name:    ucm_server2
    State:          RUNNING
    Cluster Name:   ucm_cluster
    Desired State:  SHUTDOWN
    Server Name:    ucm_server3
    Cluster Name:   ucm_cluster
    Desired State:  SHUTDOWN
    Server Name:    ucm_server4
    Cluster Name:   ucm_cluster
    Desired State:  SHUTDOWN
    Server Name:    ucm_server5
  Start Time:       2020-11-23T12:48:13.756Z
Events:             <none>
```
{{% /expand %}}

In the `Status` section of the output, the available servers and clusters are listed.
Note that if this command is issued soon after the script finishes, there may be
no servers available yet, or perhaps only the Administration Server but no Managed Servers.
The operator will start up the Administration Server first and wait for it to become ready
before starting the Managed Servers.

#### Verify the pods

Enter the following command to see the pods running the servers:

```
$ kubectl get pods -n NAMESPACE
```

Here is an example of the output of this command. You can verify that an Administration Server and Managed Servers for ucm & ibr cluster are running.

```
$ kubectl get pod -n wccns
NAME                                                READY   STATUS      RESTARTS   AGE
rcu                                                 1/1     Running     0          78d
wccinfra-adminserver                                1/1     Running     0          9d
wccinfra-create-fmw-infra-sample-domain-job-l8r9d   0/1     Completed   0          9d
wccinfra-ibr-server1                                1/1     Running     0          9d
wccinfra-ucm-server1                                1/1     Running     0          9d
wccinfra-ucm-server2                                1/1     Running     0          9d

```

#### Verify the services

Enter the following command to see the services for the domain:

```
$ kubectl get services -n NAMESPACE
```

Here is an example of the output of this command.

{{%expand "Click here to see a sample list of services." %}}
```
$ kubectl get services -n wccns
NAME                               TYPE        CLUSTER-IP       EXTERNAL-IP       PORT(S)          AGE
wccinfra-adminserver               ClusterIP   None             <none>            7001/TCP         9d
wccinfra-adminserver-external      NodePort    10.104.100.193   <none>            7001:30701/TCP   9d
wccinfra-cluster-ibr-cluster       ClusterIP   10.98.100.212    <none>            16250/TCP        114s
wccinfra-cluster-ucm-cluster       ClusterIP   10.108.47.178    <none>            16200/TCP        9d
wccinfra-ibr-server1               ClusterIP   None             <none>            16250/TCP        9d
wccinfra-ibr-server2               ClusterIP   10.97.253.44     <none>            16250/TCP        9d
wccinfra-ibr-server3               ClusterIP   10.110.183.48    <none>            16250/TCP        9d
wccinfra-ibr-server4               ClusterIP   10.108.228.158   <none>            16250/TCP        9d
wccinfra-ibr-server5               ClusterIP   10.101.29.140    <none>            16250/TCP        9d
wccinfra-ucm-server1               ClusterIP   None             <none>            16200/TCP        9d
wccinfra-ucm-server2               ClusterIP   None             <none>            16200/TCP        9d
wccinfra-ucm-server3               ClusterIP   10.107.61.128    <none>            16200/TCP        9d
wccinfra-ucm-server4               ClusterIP   10.109.25.242    <none>            16200/TCP        9d
wccinfra-ucm-server5               ClusterIP   10.109.193.26    <none>            16200/TCP        9d
```
{{% /expand %}}
