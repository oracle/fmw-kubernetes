+++
title = "Create Oracle SOA Suite domains"
date = 2019-04-18T07:32:31-05:00
weight = 3
pre = "<b>  </b>"
description = "Create an Oracle SOA Suite domain home on an existing PV or PVC, and create the domain resource YAML file for deploying the generated Oracle SOA Suite domain."
+++

The SOA deployment scripts demonstrate the creation of an Oracle SOA Suite domain home on an existing Kubernetes persistent volume (PV) and persistent volume claim (PVC). The scripts also generate the domain YAML file, which can then be used to start the Kubernetes artifacts of the corresponding domain.

#### Prerequisites

Before you begin, complete the following steps:

1. Review the [Domain resource](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/domain-resource) documentation.
1. Review the [requirements and limitations]({{< relref "/soa-domains/installguide/prerequisites" >}}).
1. Ensure that you have executed all the preliminary steps in [Prepare your environment]({{< relref "/soa-domains/installguide/prepare-your-environment" >}}).
1. Ensure that the database and the WebLogic Server Kubernetes Operator are running.


#### Prepare to use the create domain script

The sample scripts for Oracle SOA Suite domain deployment are available at `${WORKDIR}/create-soa-domain`.

You must edit `create-domain-inputs.yaml` (or a copy of it) to provide the details for your domain.
Refer to the configuration parameters below to understand the information that you must
provide in this file.

#### Configuration parameters
The following parameters can be provided in the inputs file.

| Parameter | Definition | Default |
| --- | --- | --- |
| `sslEnabled` | Boolean value indicating whether to enable SSL for each WebLogic Server instance. | `false` |
| `adminPort` | Port number for the Administration Server inside the Kubernetes cluster. | `7001` |
| `adminServerSSLPort` | SSL port number of the Administration Server inside the Kubernetes cluster. | `7002` |
| `adminNodePort` | Port number of the Administration Server outside the Kubernetes cluster. | `30701` |
| `adminServerName` | Name of the Administration Server. | `AdminServer` |
| `configuredManagedServerCount` | Number of Managed Server instances to generate for the domain. | `5` |
| `soaClusterName` | Name of the SOA WebLogic Server cluster instance to generate for the domain. By default, the cluster name is `soa_cluster`. This configuration parameter is applicable only for `soa` and `soaosb` domain types.| `soa_cluster` |
| `osbClusterName` | Name of the Oracle Service Bus WebLogic Server cluster instance to generate for the domain. By default, the cluster name is `osb_cluster`. This configuration parameter is applicable only for `osb` and `soaosb` domain types.| `osb_cluster` |
| `createDomainFilesDir` | Directory on the host machine to locate all the files to create a WebLogic Server domain, including the script that is specified in the `createDomainScriptName` parameter. By default, this directory is set to the relative path `wlst`, and the create script will use the built-in WLST offline scripts in the `wlst` directory to create the WebLogic Server domain. An absolute path is also supported to point to an arbitrary directory in the file system. The built-in scripts can be replaced by the user-provided scripts as long as those files are in the specified directory. Files in this directory are put into a Kubernetes config map, which in turn is mounted to the `createDomainScriptsMountPath`, so that the Kubernetes pod can use the scripts and supporting files to create a domain home. | `wlst` |
| `createDomainScriptsMountPath` | Mount path where the create domain scripts are located inside a pod. The `create-domain.sh` script creates a Kubernetes job to run the script (specified by the `createDomainScriptName` parameter) in a Kubernetes pod to create a domain home. Files in the `createDomainFilesDir` directory are mounted to this location in the pod, so that the Kubernetes pod can use the scripts and supporting files to create a domain home. | `/u01/weblogic` |
| `createDomainScriptName` | Script that the create domain script uses to create a WebLogic Server domain. The `create-domain.sh` script creates a Kubernetes job to run this script to create a domain home. The script is located in the in-pod directory that is specified by the `createDomainScriptsMountPath` parameter. If you need to provide your own scripts to create the domain home, instead of using the built-in scripts, you must use this property to set the name of the script that you want the create domain job to run. | `create-domain-job.sh` |
| `domainHome` | Home directory of the SOA domain. If not specified, the value is derived from the `domainUID` as `/shared/domains/<domainUID>`. | `/u01/oracle/user_projects/domains/soainfra` |
| `domainPVMountPath` | Mount path of the domain persistent volume. | `/u01/oracle/user_projects` |
| `domainUID` | Unique ID that will be used to identify this particular domain. Used as the name of the generated WebLogic Server domain as well as the name of the Kubernetes domain resource. This ID must be unique across all domains in a Kubernetes cluster. This ID cannot contain any character that is not valid in a Kubernetes service name. | `soainfra` |
| `domainType` | Type of the domain. Mandatory input for Oracle SOA Suite domains. You must provide one of the supported domain type values: `soa` (deploys a SOA domain with Enterprise Scheduler (ESS)), `osb` (deploys an Oracle Service Bus domain), and `soaosb` (deploys a domain with SOA, Oracle Service Bus, and Enterprise Scheduler (ESS)). | `soa`
| `exposeAdminNodePort` | Boolean value indicating if the Administration Server is exposed outside of the Kubernetes cluster. | `false` |
| `exposeAdminT3Channel` | Boolean value indicating if the T3 administrative channel is exposed outside the Kubernetes cluster. | `false` |
| `httpAccessLogInLogHome` | Boolean value indicating if server HTTP access log files should be written to the same directory as `logHome`. If `false`, server HTTP access log files will be written to the directory specified in the WebLogic Server domain home configuration. | `true` |
| `image` | SOA Suite Docker image. The operator requires Oracle SOA Suite 12.2.1.4. Refer to [Obtain the Oracle SOA Suite Docker image]({{< relref "/soa-domains/installguide/prepare-your-environment#obtain-the-oracle-soa-suite-docker-image" >}}) for details on how to obtain or create the image. | `soasuite:12.2.1.4` |
| `imagePullPolicy` | Oracle SOA Suite Docker image pull policy. Valid values are `IfNotPresent`, `Always`, `Never`. | `IfNotPresent` |
| `imagePullSecretName` | Name of the Kubernetes secret to access the Docker Store to pull the WebLogic Server Docker image. The presence of the secret will be validated when this parameter is specified. |  |
| `includeServerOutInPodLog` | Boolean value indicating whether to include the server .out to the pod's stdout. | `true` |
| `initialManagedServerReplicas` | Number of Managed Servers to initially start for the domain. | `2` |
| `javaOptions` | Java options for starting the Administration Server and Managed Servers. A Java option can have references to one or more of the following predefined variables to obtain WebLogic Server domain information: `$(DOMAIN_NAME)`, `$(DOMAIN_HOME)`, `$(ADMIN_NAME)`, `$(ADMIN_PORT)`, and `$(SERVER_NAME)`. If `sslEnabled` is set to `true` and the WebLogic Server demo certificate is used, add `-Dweblogic.security.SSL.ignoreHostnameVerification=true` to allow the Managed Servers to connect to the Administration Server while booting up. The WebLogic Server generated demo certificate in this environment typically contains a host name that is different from the runtime container's host name. | `-Dweblogic.StdoutDebugEnabled=false` |
| `logHome` | The in-pod location for the domain log, server logs, server out, and Node Manager log files. If not specified, the value is derived from the `domainUID` as `/shared/logs/<domainUID>`. | `/u01/oracle/user_projects/domains/logs/soainfra` |
| `soaManagedServerNameBase` | Base string used to generate Managed Server names in the SOA cluster. The default value is `soa_server`. This configuration parameter is applicable only for `soa` and `soaosb` domain types.| `soa_server` |
| `osbManagedServerNameBase` | Base string used to generate Managed Server names in the Oracle Service Bus cluster. The default value is `osb_server`. This configuration parameter is applicable only for `osb` and `soaosb` domain types.| `osb_server` |
| `soaManagedServerPort` | Port number for each Managed Server in the SOA cluster. This configuration parameter is applicable only for `soa` and `soaosb` domain types.| `8001` |
| `osbManagedServerPort` | Port number for each Managed Server in the Oracle Service Bus cluster. This configuration parameter is applicable only for `osb` and `soaosb` domain types.| `9001` |
| `soaManagedServerSSLPort` | SSL port number for each Managed Server in the SOA cluster. This configuration parameter is applicable only for `soa` and `soaosb` domain types.| `8002` |
| `osbManagedServerSSLPort` | SSL port number for each Managed Server in the Oracle Service Bus cluster. This configuration parameter is applicable only for `osb` and `soaosb` domain types.| `9002` |
| `namespace` | Kubernetes namespace in which to create the domain. | `soans` |
| `persistentVolumeClaimName` | Name of the persistent volume claim created to host the domain home. If not specified, the value is derived from the `domainUID` as `<domainUID>-weblogic-sample-pvc`. | `soainfra-domain-pvc` |
| `productionModeEnabled` | Boolean value indicating if production mode is enabled for the domain. | `true` |
| `serverStartPolicy` | Determines which WebLogic Server instances will be started. Valid values are `NEVER`, `IF_NEEDED`, `ADMIN_ONLY`. | `IF_NEEDED` |
| `t3ChannelPort` | Port for the T3 channel of the NetworkAccessPoint. | `30012` |
| `t3PublicAddress` | Public address for the T3 channel. This should be set to the public address of the Kubernetes cluster. This would typically be a load balancer address. <p/>For development environments only: In a single server (all-in-one) Kubernetes deployment, this may be set to the address of the master, or at the very least, it must be set to the address of one of the worker nodes. | If not provided, the script will attempt to set it to the IP address of the Kubernetes cluster. |
| `weblogicCredentialsSecretName` | Name of the Kubernetes secret for the Administration Server's user name and password. If not specified, then the value is derived from the `domainUID` as `<domainUID>-weblogic-credentials`. | `soainfra-domain-credentials` |
| `weblogicImagePullSecretName` | Name of the Kubernetes secret for the Docker Store, used to pull the WebLogic Server image. |   |
| `serverPodCpuRequest`, `serverPodMemoryRequest`, `serverPodCpuCLimit`, `serverPodMemoryLimit` |  The maximum amount of compute resources allowed, and minimum amount of compute resources required, for each server pod. Refer to the Kubernetes documentation on `Managing Compute Resources for Containers` for details. | Resource requests and resource limits are not specified. |
| `rcuSchemaPrefix` | The schema prefix to use in the database. For example `SOA1`. You may wish to make this the same as the domainUID in order to simplify matching domains to their RCU schemas. | `SOA1` |
| `rcuDatabaseURL` | The database URL. | `oracle-db.default.svc.cluster.local:1521/devpdb.k8s` |
| `rcuCredentialsSecret` | The Kubernetes secret containing the database credentials. | `soainfra-rcu-credentials` |
| `persistentStore` | The persistent store for 'JMS servers' and 'Transaction log store' in the domain. Valid values are `jdbc`,  `file`. | `jdbc` |

Note that the names of the Kubernetes resources in the generated YAML files may be formed with the
value of some of the properties specified in the `create-inputs.yaml` file. Those properties include
the `adminServerName`, `clusterName`, and `managedServerNameBase`. If those values contain any
characters that are invalid in a Kubernetes service name, those characters are converted to
valid values in the generated YAML files. For example, an uppercase letter is converted to a
lowercase letter and an underscore `("_")` is converted to a hyphen `("-")`.

The sample demonstrates how to create an Oracle SOA Suite domain home and associated Kubernetes resources for a domain
that has one cluster only. In addition, the sample provides the capability for users to supply their own scripts
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
  already exist. The path name is `<path to output-directory>/weblogic-domains/<domainUID>`.
  If the directory already exists, its contents must be removed before using this script.
* Create a Kubernetes job that will start up a utility Oracle SOA Suite container and run
  offline WLST scripts to create the domain on the shared storage.
* Run and wait for the job to finish.
* Create a Kubernetes domain YAML file, `domain.yaml`, in the "output" directory that was created above.
  This YAML file can be used to create the Kubernetes resource using the `kubectl create -f`
  or `kubectl apply -f` command:

    ```
    $ kubectl apply -f <path to output-directory>/weblogic-domains/<domainUID>/domain.yaml
    ```

* Create a convenient utility script, `delete-domain-job.yaml`, to clean up the domain home
  created by the create script.



The default domain created by the script has the following characteristics:

* An Administration Server named `AdminServer` listening on port `7001`.
* A configured cluster named `soa_cluster` of size 5.
* Two Managed Servers, named `soa_server1` and `soa_server2`, listening on port `8001`.
* Log files that are located in `/shared/logs/<domainUID>`.
* SOA Infra, SOA composer and WorklistApp applications deployed.

#### Verify the results

The create domain script will verify that the domain was created, and will report failure if there was any error.
However, it may be desirable to manually verify the domain, even if just to gain familiarity with the
various Kubernetes objects that were created by the script.


##### Generated YAML files with the default inputs

{{%expand "Click here to see sample content of the generated `domain.yaml` for `soaosb` domainType that creates SOA and Oracle Service Bus clusters." %}}

```
$ cat output/weblogic-domains/soainfra/domain.yaml
# Copyright (c) 2020, 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of how to define a Domain resource.
#
apiVersion: "weblogic.oracle/v8"
kind: Domain
metadata:
  name: soainfra
  namespace: soans
  labels:
    weblogic.domainUID: soainfra
spec:
  # The WebLogic Domain Home
  domainHome: /u01/oracle/user_projects/domains/soainfra

  # The domain home source type
  # Set to PersistentVolume for domain-in-pv, Image for domain-in-image, or FromModel for model-in-image
  domainHomeSourceType: PersistentVolume

  # The WebLogic Server image that the Operator uses to start the domain
  image: "soasuite:12.2.1.4"

  # imagePullPolicy defaults to "Always" if image version is :latest
  imagePullPolicy: "IfNotPresent"

  # Identify which Secret contains the credentials for pulling an image
  #imagePullSecrets:
  #- name:

  # Identify which Secret contains the WebLogic Admin credentials (note that there is an example of
  # how to create that Secret at the end of this file)
  webLogicCredentialsSecret:
    name: soainfra-domain-credentials

  # Whether to include the server out file into the pod's stdout, default is true
  includeServerOutInPodLog: true

  # Whether to enable log home
  logHomeEnabled: true

  # Whether to write HTTP access log file to log home
  httpAccessLogInLogHome: true

  # The in-pod location for domain log, server logs, server out, introspector out, and Node Manager log files
  logHome: /u01/oracle/user_projects/domains/logs/soainfra
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
      value: "-Dweblogic.StdoutDebugEnabled=false -Dweblogic.ssl.Enabled=true -Dweblogic.security.SSL.ignoreHostnameVerification=true"
    - name: USER_MEM_ARGS
      value: "-Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx1024m "
    volumes:
    - name: weblogic-domain-storage-volume
      persistentVolumeClaim:
        claimName: soainfra-domain-pvc
    volumeMounts:
    - mountPath: /u01/oracle/user_projects
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
    #    - channelName: default
    #      nodePort: 30701
    # Uncomment to export the T3Channel as a service
       - channelName: T3Channel
    serverPod:
      # an (optional) list of environment variable to be set on the admin servers
      env:
      - name: USER_MEM_ARGS
        value: "-Djava.security.egd=file:/dev/./urandom -Xms512m -Xmx1024m "

  # clusters is used to configure the desired behavior for starting member servers of a cluster.
  # If you use this entry, then the rules will be applied to ALL servers that are members of the named clusters.
  clusters:
  - clusterName: osb_cluster
    serverService:
      precreateService: true
    serverStartState: "RUNNING"
    serverPod:
      env:
      # This parameter can be used to pass in new system properties, use the space delimiter to append multiple values.
      # Do not change the below value, only append new values to it.
      - name: K8S_REFCONF_OVERRIDES
        value: "-Doracle.sb.tracking.resiliency.MemoryMetricEnabled=false "
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
    replicas: 2
  # The number of managed servers to start for unlisted clusters
  # replicas: 1

  # Istio
  # configuration:
  #   istio:
  #     enabled:
  #     readinessPort:

  - clusterName: soa_cluster
    serverService:
      precreateService: true
    serverStartState: "RUNNING"
    serverPod:
      env:
      # This parameter can be used to pass in new system properties, use the space delimiter to append multiple values.
      # Do not change the below value, only append new values to it.
      - name: K8S_REFCONF_OVERRIDES
        value: "-Doracle.soa.tracking.resiliency.MemoryMetricEnabled=false "
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
    replicas: 2
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
$ kubectl describe domain soainfra -n soans
Name:         soainfra
Namespace:    soans
Labels:       weblogic.domainUID=soainfra
Annotations:  <none>
API Version:  weblogic.oracle/v8
Kind:         Domain
Metadata:
  Creation Timestamp:  2021-03-01T05:27:38Z
  Generation:          1
  Managed Fields:
    API Version:  weblogic.oracle/v8
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:labels:
          .:
          f:weblogic.domainUID:
    Manager:      kubectl
    Operation:    Update
    Time:         2021-03-01T05:27:38Z
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
    Time:            2021-03-02T10:26:59Z
  Resource Version:  13351862
  Self Link:         /apis/weblogic.oracle/v8/namespaces/soans/domains/soainfra
  UID:               295dfc48-999e-45e3-b275-9d752587b8d9
Spec:
  Admin Server:
    Admin Service:
      Channels:
        Channel Name:  T3Channel
    Server Pod:
      Env:
        Name:            USER_MEM_ARGS
        Value:           -Djava.security.egd=file:/dev/./urandom -Xms512m -Xmx1024m
    Server Start State:  RUNNING
  Clusters:
    Cluster Name:  osb_cluster
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
      Env:
        Name:   K8S_REFCONF_OVERRIDES
        Value:  -Doracle.sb.tracking.resiliency.MemoryMetricEnabled=false
    Server Service:
      Precreate Service:  true
    Server Start State:   RUNNING
    Cluster Name:         soa_cluster
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
        Name:   K8S_REFCONF_OVERRIDES
        Value:  -Doracle.soa.tracking.resiliency.MemoryMetricEnabled=false
    Server Service:
      Precreate Service:          true
    Server Start State:           RUNNING
  Data Home:
  Domain Home:                    /u01/oracle/user_projects/domains/soainfra
  Domain Home Source Type:        PersistentVolume
  Http Access Log In Log Home:    true
  Image:                          soasuite:12.2.1.4
  Image Pull Policy:              IfNotPresent
  Include Server Out In Pod Log:  true
  Log Home:                       /u01/oracle/user_projects/domains/logs/soainfra
  Log Home Enabled:               true
  Server Pod:
    Env:
      Name:   JAVA_OPTIONS
      Value:  -Dweblogic.StdoutDebugEnabled=false -Dweblogic.ssl.Enabled=true -Dweblogic.security.SSL.ignoreHostnameVerification=true
      Name:   USER_MEM_ARGS
      Value:  -Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx1024m
    Volume Mounts:
      Mount Path:  /u01/oracle/user_projects
      Name:        weblogic-domain-storage-volume
    Volumes:
      Name:  weblogic-domain-storage-volume
      Persistent Volume Claim:
        Claim Name:     soainfra-domain-pvc
  Server Start Policy:  IF_NEEDED
  Web Logic Credentials Secret:
    Name:  soainfra-domain-credentials
Status:
  Clusters:
    Cluster Name:      osb_cluster
    Maximum Replicas:  5
    Minimum Replicas:  0
    Ready Replicas:    2
    Replicas:          2
    Replicas Goal:     2
    Cluster Name:      soa_cluster
    Maximum Replicas:  5
    Minimum Replicas:  0
    Ready Replicas:    2
    Replicas:          2
    Replicas Goal:     2
  Conditions:
    Last Transition Time:        2021-03-02T10:26:59.683Z
    Reason:                      ManagedServersStarting
    Status:                      True
    Type:                        Progressing
  Introspect Job Failure Count:  0
  Servers:
    Desired State:  RUNNING
    Node Name:      k8sdev
    Server Name:    AdminServer
    State:          UNKNOWN
    Cluster Name:   osb_cluster
    Desired State:  RUNNING
    Node Name:      k8sdev
    Server Name:    osb_server1
    State:          UNKNOWN
    Cluster Name:   osb_cluster
    Desired State:  RUNNING
    Node Name:      k8sdev
    Server Name:    osb_server2
    State:          UNKNOWN
    Cluster Name:   osb_cluster
    Desired State:  SHUTDOWN
    Server Name:    osb_server3
    Cluster Name:   osb_cluster
    Desired State:  SHUTDOWN
    Server Name:    osb_server4
    Cluster Name:   osb_cluster
    Desired State:  SHUTDOWN
    Server Name:    osb_server5
    Cluster Name:   soa_cluster
    Desired State:  RUNNING
    Node Name:      k8sdev
    Server Name:    soa_server1
    State:          UNKNOWN
    Cluster Name:   soa_cluster
    Desired State:  RUNNING
    Node Name:      k8sdev
    Server Name:    soa_server2
    State:          UNKNOWN
    Cluster Name:   soa_cluster
    Desired State:  SHUTDOWN
    Server Name:    soa_server3
    Cluster Name:   soa_cluster
    Desired State:  SHUTDOWN
    Server Name:    soa_server4
    Cluster Name:   soa_cluster
    Desired State:  SHUTDOWN
    Server Name:    soa_server5
  Start Time:       2021-03-01T05:27:38.844Z
Events:             <none>
```
{{% /expand %}}

In the `Status` section of the output, the available servers and clusters are listed.
Note that if this command is issued very soon after the script finishes, there may be
no servers available yet, or perhaps only the Administration Server but no Managed Servers.
The operator will start up the Administration Server first and wait for it to become ready
before starting the Managed Servers.

#### Verify the pods

Enter the following command to see the pods running the servers:

```
$ kubectl get pods -n NAMESPACE
```

Here is an example of the output of this command. You can verify that an Administration Server and two Managed Servers for each cluster (SOA and Oracle Service Bus) are running for `soaosb` domain type.

```
$ kubectl get pods -n soans
NAME                                                READY   STATUS      RESTARTS   AGE
soainfra-adminserver                         1/1     Running     0          53m
soainfra-osb-server1                         1/1     Running     0          50m
soainfra-osb-server2                         1/1     Running     0          50m
soainfra-soa-server1                         1/1     Running     0          50m
soainfra-soa-server2                         1/1     Running     0          50m

```

#### Verify the services

Enter the following command to see the services for the domain:

```
$ kubectl get services -n NAMESPACE
```

Here is an example of the output of this command. You can verify that services for Administration Server and Managed Servers (for SOA and Oracle Service Bus clusters) are created for `soaosb` domain type.

{{%expand "Click here to see a sample list of services." %}}
```
$ kubectl get services -n soans
NAME                            TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                       AGE
soainfra-adminserver            ClusterIP      None             <none>        30012/TCP,7001/TCP,7002/TCP   54m
soainfra-cluster-osb-cluster    ClusterIP      10.100.138.57    <none>        9001/TCP,9002/TCP             51m
soainfra-cluster-soa-cluster    ClusterIP      10.99.117.240    <none>        8001/TCP,8002/TCP             51m
soainfra-osb-server1            ClusterIP      None             <none>        9001/TCP,9002/TCP             51m
soainfra-osb-server2            ClusterIP      None             <none>        9001/TCP,9002/TCP             51m
soainfra-osb-server3            ClusterIP      10.108.71.8      <none>        9001/TCP,9002/TCP             51m
soainfra-osb-server4            ClusterIP      10.100.1.144     <none>        9001/TCP,9002/TCP             51m
soainfra-osb-server5            ClusterIP      10.108.57.147    <none>        9001/TCP,9002/TCP             51m
soainfra-soa-server1            ClusterIP      None             <none>        8001/TCP,8002/TCP             51m
soainfra-soa-server2            ClusterIP      None             <none>        8001/TCP,8002/TCP             51m
soainfra-soa-server3            ClusterIP      10.98.160.126    <none>        8001/TCP,8002/TCP             51m
soainfra-soa-server4            ClusterIP      10.105.164.133   <none>        8001/TCP,8002/TCP             51m
soainfra-soa-server5            ClusterIP      10.109.168.179   <none>        8001/TCP,8002/TCP             51m
```
{{% /expand %}}
