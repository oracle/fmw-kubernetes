+++
title = "Create Oracle WebCenter Sites domains"
date = 2019-04-18T07:32:31-05:00
weight = 3
pre = "<b>  </b>"
description = "Create an Oracle WebCenter Sites domain home on an existing PV or PVC, and create the domain resource YAML file for deploying the generated Oracle WebCenter Sites domain."
+++


#### Contents

* [Introduction](#introduction)
* [Prerequisites](#prerequisites)
* [Prepare the WebCenter Sites Domain Creation Input File](#prepare-the-webcenter-sites-domain-creation-input-file)
* [Create the WebCenter Sites Domain](#create-the-webcenter-sites-domain)
* [Initialize the WebCenter Sites Domain](#initialize-the-webcenter-sites-domain)
* [Verify the WebCenter Sites Domain](#verify-the-webcenter-sites-domain)
* [Expose WebCenter Sites Services](#expose-webcenter-sites-services)
* [Load Balance With an Ingress Controller or A Web Server](#load-balance-with-an-ingress-controller-or-a-web-server)
* [Configure WebCenter Sites](#configure-webcenter-sites)
* [Settings in WebCenter Sites Property Management](#settings-in-webcenter-sites-property-management)
* [For Publishing Setting in WebCenter Sites](#for-publishing-setting-in-webcenter-sites)


#### Introduction

This document details on how to use sample scripts to demonstrate the creation of a WebCenter Sites domain home on an
existing Kubernetes persistent volume (PV) and persistent volume claim (PVC). The scripts
also generate the domain YAML file, which can then be used to start the Kubernetes
artifacts of the corresponding domain.

#### Prerequisites

* Ensure that you have completed all of the steps under [prepare-your-environment]({{< relref "/wcsites-domains/installguide/prepare-your-environment">}}). 
* Ensure that the database and the WebLogic Kubernetes Operator is up.

#### Prepare the WebCenter Sites Domain Creation Input File

If required, domain creation inputs can be customized by editing `create-domain-inputs.yaml` as described below:  

Please note that the sample scripts for the WebCenter Sites domain deployment are available from the previously downloaded repository at  `kubernetes/samples/scripts/create-wcsites-domain/domain-home-on-pv/`.
  
Make a copy of the `create-domain-inputs.yaml` file before updating the default values.

The default domain created by the script has the following characteristics:

* An Administration Server named `AdminServer` listening on port `7001`.
* A configured cluster named `wcsites_cluster` of size `5`.
* Managed Server, named `wcsites_server1`, listening on port `8001`.
* Log files that are located in `/shared/logs/<domainUID>`.

##### Configuration parameters
The following parameters can be provided in the inputs file:

| Parameter | Definition | Default |
| --- | --- | --- |
| `adminPort` | Port number for the Administration Server inside the Kubernetes cluster. | `7001` |
| `adminServerName` | Name of the Administration Server. | `AdminServer` |
| `clusterName` | Name of the WebLogic cluster instance to generate for the domain. By default the cluster name is `wcsites_cluster` for the WebCenter Sites domain. | `wcsites_cluster` |
| `configuredManagedServerCount` | Number of Managed Server instances for the domain. | `3` |
| `createDomainFilesDir` | Directory on the host machine to locate all the files that you need to create a WebLogic domain, including the script that is specified in the `createDomainScriptName` property. By default, this directory is set to the relative path `wlst`, and the create script will use the built-in WLST offline scripts in the `wlst` directory to create the WebLogic domain. An absolute path is also supported to point to an arbitrary directory in the file system. The built-in scripts can be replaced by the user-provided scripts or model files as long as those files are in the specified directory. Files in this directory are put into a Kubernetes config map, which in turn is mounted to the `createDomainScriptsMountPath`, so that the Kubernetes pod can use the scripts and supporting files to create a domain home. | `wlst` |
| `createDomainScriptsMountPath` | Mount path where the create domain scripts are located inside a pod. The `create-domain.sh` script creates a Kubernetes job to run the script (specified in the `createDomainScriptName` property) in a Kubernetes pod to create a domain home. Files in the `createDomainFilesDir` directory are mounted to this location in the pod, so that the Kubernetes pod can use the scripts and supporting files to create a domain home. | `/u01/weblogic` |
| `createDomainScriptName` | Script that the create domain script uses to create a WebLogic domain. The `create-domain.sh` script creates a Kubernetes job to run this script to create a domain home. The script is located in the in-pod directory that is specified in the `createDomainScriptsMountPath` property. If you need to provide your own scripts to create the domain home, instead of using the built-it scripts, you must use this property to set the name of the script that you want the create domain job to run. | `create-domain-job.sh` |
| `domainHome` | Home directory of the WebCenter Sites domain. `This field cannot be modified.` | `/u01/oracle/user_projects/domains/wcsitesinfra` |
| `domainPVMountPath` | Mount path of the domain persistent volume. `This field cannot be modified.` | `/u01/oracle/user_projects/domains` |
| `domainUID` | Unique ID that will be used to identify this particular domain. Used as the name of the generated WebLogic domain as well as the name of the Kubernetes domain resource. This ID must be unique across all domains in a Kubernetes cluster. This ID cannot contain any character that is not valid in a Kubernetes service name. | `wcsitesinfra` |
| `exposeAdminNodePort` | Boolean indicating if the Administration Server is exposed outside of the Kubernetes cluster. | `false` |
| `exposeAdminT3Channel` | Boolean indicating if the T3 administrative channel is exposed outside the Kubernetes cluster. | `false` |
| `image` | WebCenter Sites Docker image. The Operator requires WebCenter Sites release 12.2.1.4.0. Refer to [WebCenter Sites Docker image](https://github.com/oracle/docker-images/tree/master/OracleWebCenterSites/dockerfiles/12.2.1.4) for details on how to obtain or create the image. | `oracle/wcsites:12.2.1.4-21.1.1` |
| `imagePullPolicy` | WebLogic Docker image pull policy. Legal values are `IfNotPresent`, `Always`, or `Never` | `IfNotPresent` |
| `imagePullSecretName` | Name of the Kubernetes secret to access the Docker Store to pull the WebLogic Server Docker image. The presence of the secret will be validated when this parameter is specified. |  |
| `includeServerOutInPodLog` | Boolean indicating whether to include the server.out to the pod's stdout. | `true` |
| `initialManagedServerReplicas` | Number of Managed Server to initially start for the domain. | `1` |
| `javaOptions` | Java options for starting the Administration Server and Managed Servers. A Java option can include references to one or more of the following pre-defined variables to obtain WebLogic domain information: `$(DOMAIN_NAME)`, `$(DOMAIN_HOME)`, `$(ADMIN_NAME)`, `$(ADMIN_PORT)`, and `$(SERVER_NAME)`. | `-Dweblogic.StdoutDebugEnabled=false` |
| `logHome` | The in-pod location for the domain log, server logs, server out, and Node Manager log files. `This field cannot be modified.` | `/u01/oracle/user_projects/logs/wcsitesinfra` |
| `managedServerNameBase` | Base string used to generate Managed Server names. | `wcsites_server` |
| `managedServerPort` | Port number for each Managed Server. | `8001` |
| `namespace` | Kubernetes namespace in which to create the domain. | `wcsites-ns` |
| `persistentVolumeClaimName` | Name of the persistent volume claim created to host the domain home. If not specified, the value is derived from the `domainUID` as `<domainUID>-weblogic-sample-pvc`. | `wcsitesinfra-domain-pvc` |
| `productionModeEnabled` | Boolean indicating if production mode is enabled for the domain. | `true` |
| `serverStartPolicy` | Determines which WebLogic Server instances will be started. Legal values are `NEVER`, `IF_NEEDED`, `ADMIN_ONLY`. | `IF_NEEDED` |
| `t3ChannelPort` | Port for the T3 channel of the NetworkAccessPoint. | `30012` |
| `t3PublicAddress` | Public address for the T3 channel.  This should be set to the public address of the Kubernetes cluster.  This would typically be a load balancer address. <p/>For development environments only: In a single server (all-in-one) Kubernetes deployment, this may be set to the address of the master, or at the very least, it must be set to the address of one of the worker nodes. | If not provided, the script will attempt to set it to the IP address of the Kubernetes cluster. |
| `weblogicCredentialsSecretName` | Name of the Kubernetes secret for the Administration Server's user name and password. If not specified, then the value is derived from the `domainUID` as `<domainUID>-weblogic-credentials`. | `wcsites-domain-credentials` |
| `weblogicImagePullSecretName` | Name of the Kubernetes secret for the Docker Store, used to pull the WebLogic Server image. |   |
| `serverPodCpuRequest`, `serverPodMemoryRequest`, `serverPodCpuCLimit`, `serverPodMemoryLimit` |  The maximum amount of compute resources allowed and minimum amount of compute resources required for each server pod. Please refer to the Kubernetes documentation on `Managing Compute Resources for Containers` for details. | Resource requests and resource limits are not specified. Refer to [WebCenter Sites Cluster Sizing Recommendations](../pre-requisites/#webcenter-sites-cluster-sizing-recommendations) for more details. |
| `rcuSchemaPrefix` | The schema prefix to use in the database, for example `WCS1`.  You may wish to make this the same as the domainUID in order to simplify matching domains to their RCU schemas. | `WCS1` |
| `rcuDatabaseURL` | The database URL. | `oracle-db.wcsitesdb-ns.svc.cluster.local:1521/devpdb.k8s` |
| `rcuCredentialsSecret` | The loadbalancer hostname to be provided. | `wcsites-rcu-credentials` |
| `loadBalancerHostName` | Hostname for the final url accessible outside K8S environment. | `abc.def.com` |
| `loadBalancerPortNumber` | Port for the final url accessible outside K8S environment. | `30305` |
| `loadBalancerProtocol` | Protocol for the final url accessible outside K8S environment. | `http` |
| `loadBalancerType` | Loadbalancer name that will be used. Example: Traefik or "" | `traefik` |
| `unicastPort` | Starting range of uniciast port that application will use. | `50000` |
| `sitesSamples` | Sites to be installed without samples sites by default, else true. | `false` |

You can form the names of the Kubernetes resources in the generated YAML files with the value of these properties
specified in the `create-domain-inputs.yaml` file: `adminServerName` , `clusterName` and `managedServerNameBase` . Characters that are invalid in a Kubernetes service name are converted to valid values in the
generated YAML files. For example, an uppercase letter is converted to a lowercase letter and an underscore ("_") is converted to a
hyphen ("-") .

The sample demonstrates how to create a WebCenter Sites domain home and associated Kubernetes resources for a domain
that has one cluster only. In addition, the sample provides the capability for users to supply their own scripts
to create the domain home for other use cases. You can modify the generated domain YAML file to include more use cases.

#### Create the WebCenter Sites Domain

1. Understanding the syntax of the create-domain.sh  script:
   
    ```
    $ ./create-domain.sh \
     -i create-domain-inputs.yaml \
     -o /<path to output-directory>
    ```
    
    The script performs the following functions:
    
    * Creates a directory for the generated Kubernetes YAML files for this domain if it does not
      already exist.  The path name is `/<path to output-directory>/weblogic-domains/<domainUID>`.
      If the directory already exists, remove its content before using this script.
    * Creates a Kubernetes job that will start up a utility WebCenter Sites container and run
      offline WLST scripts to create the domain on the shared storage.
    * Runs and waits for the job to finish.
    * Creates a Kubernetes domain YAML file, `domain.yaml`, in the directory that is created above.
      This YAML file can be used to create the Kubernetes resource using the `kubectl create -f`
      or `kubectl apply -f` command:
    
       ```
       $ kubectl apply -f ../<path to output-directory>/weblogic-domains/<domainUID>/domain.yaml
       ```   
    
    * Creates a convenient utility script, `delete-domain-job.yaml`, to clean up the domain home
      created by the create script.

1. Now, run the `create-domain.sh` sample script below, pointing it at the create-domain-inputs inputs file and an output directory like below:

    ```bash
    bash-4.2$ rm -rf kubernetes/samples/scripts/create-wcsites-domain/output/weblogic-domains
     
    bash-4.2$ sh kubernetes/samples/scripts/create-wcsites-domain/domain-home-on-pv/create-domain.sh \
        -i kubernetes/samples/scripts/create-wcsites-domain/domain-home-on-pv/create-domain-inputs.yaml \
        -o kubernetes/samples/scripts/create-wcsites-domain/output
     
	Input parameters being used
	export version="create-weblogic-sample-domain-inputs-v1"
	export adminPort="7001"
	export adminServerName="adminserver"
	export domainUID="wcsitesinfra"
	export domainHome="/u01/oracle/user_projects/domains/$domainUID"
	export serverStartPolicy="IF_NEEDED"
	export clusterName="wcsites_cluster"
	export configuredManagedServerCount="3"
	export initialManagedServerReplicas="1"
	export managedServerNameBase="wcsites_server"
	export managedServerPort="8001"
	export image="oracle/wcsites:12.2.1.4-21.1.1"
	export imagePullPolicy="IfNotPresent"
	export productionModeEnabled="true"
	export weblogicCredentialsSecretName="wcsitesinfra-domain-credentials"
	export includeServerOutInPodLog="true"
	export logHome="/u01/oracle/user_projects/domains/logs/$domainUID"
	export t3ChannelPort="30012"
	export exposeAdminT3Channel="false"
	export adminNodePort="30701"
	export exposeAdminNodePort="false"
	export namespace="wcsites-ns"
	javaOptions=-Dweblogic.StdoutDebugEnabled=false -Xms2g
	export persistentVolumeClaimName="wcsitesinfra-domain-pvc"
	export domainPVMountPath="/u01/oracle/user_projects/domains"
	export createDomainScriptsMountPath="/u01/weblogic"
	export createDomainScriptName="create-domain-job.sh"
	export createDomainFilesDir="wlst"
	export rcuSchemaPrefix="WCS1"
	export rcuDatabaseURL="oracle-db.wcsitesdb-ns.svc.cluster.local:1521/devpdb.k8s"
	export rcuCredentialsSecret="wcsitesinfra-rcu-credentials"
	export loadBalancerHostName="abc.def.com"
	export loadBalancerPortNumber="30305"
	export loadBalancerProtocol="http"
	export loadBalancerType="traefik"
	export unicastPort="50000"
	export sitesSamples="true"
	
	Generating kubernetes/samples/scripts/create-wcsites-domain/output/weblogic-domains/wcsitesinfra/create-domain-job.yaml
	Generating kubernetes/samples/scripts/create-wcsites-domain/output/weblogic-domains/wcsitesinfra/delete-domain-job.yaml
	Generating kubernetes/samples/scripts/create-wcsites-domain/output/weblogic-domains/wcsitesinfra/domain.yaml
	Checking to see if the secret wcsitesinfra-domain-credentials exists in namespace wcsites-ns
	configmap/wcsitesinfra-create-fmw-infra-sample-domain-job-cm created
	Checking the configmap wcsitesinfra-create-fmw-infra-sample-domain-job-cm was created
	configmap/wcsitesinfra-create-fmw-infra-sample-domain-job-cm labeled
	Checking if object type job with name wcsitesinfra-create-fmw-infra-sample-domain-job exists
	No resources found.
	$loadBalancerType is NOT empty
	Creating the domain by creating the job kubernetes/samples/scripts/create-wcsites-domain/output/weblogic-domains/wcsitesinfra/create-domain-job.yaml
	job.batch/wcsitesinfra-create-fmw-infra-sample-domain-job created
	Waiting for the job to complete...
	status on iteration 1 of 20
	pod wcsitesinfra-create-fmw-infra-sample-domain-job-6l7zh status is Running
	status on iteration 2 of 20
	pod wcsitesinfra-create-fmw-infra-sample-domain-job-6l7zh status is Running
	status on iteration 3 of 20
	pod wcsitesinfra-create-fmw-infra-sample-domain-job-6l7zh status is Running
	status on iteration 4 of 20
	pod wcsitesinfra-create-fmw-infra-sample-domain-job-6l7zh status is Running
	status on iteration 5 of 20
	pod wcsitesinfra-create-fmw-infra-sample-domain-job-6l7zh status is Running
	status on iteration 6 of 20
	pod wcsitesinfra-create-fmw-infra-sample-domain-job-6l7zh status is Running
	status on iteration 7 of 20
	pod wcsitesinfra-create-fmw-infra-sample-domain-job-6l7zh status is Running
	status on iteration 8 of 20
	pod wcsitesinfra-create-fmw-infra-sample-domain-job-6l7zh status is Running
	status on iteration 9 of 20
	pod wcsitesinfra-create-fmw-infra-sample-domain-job-6l7zh status is Running
	status on iteration 10 of 20
	pod wcsitesinfra-create-fmw-infra-sample-domain-job-6l7zh status is Running
	status on iteration 11 of 20
	pod wcsitesinfra-create-fmw-infra-sample-domain-job-6l7zh status is Running
	status on iteration 12 of 20
	pod wcsitesinfra-create-fmw-infra-sample-domain-job-6l7zh status is Running
	status on iteration 13 of 20
	pod wcsitesinfra-create-fmw-infra-sample-domain-job-6l7zh status is Running
	status on iteration 14 of 20
	pod wcsitesinfra-create-fmw-infra-sample-domain-job-6l7zh status is Running
	status on iteration 15 of 20
	pod wcsitesinfra-create-fmw-infra-sample-domain-job-6l7zh status is Running
	status on iteration 16 of 20
	pod wcsitesinfra-create-fmw-infra-sample-domain-job-6l7zh status is Completed
	
	Domain wcsitesinfra was created and will be started by the WebLogic Kubernetes Operator
	
	The following files were generated:
	kubernetes/samples/scripts/create-wcsites-domain/output/weblogic-domains/wcsitesinfra/create-domain-inputs.yaml
	kubernetes/samples/scripts/create-wcsites-domain/output/weblogic-domains/wcsitesinfra/create-domain-job.yaml
	kubernetes/samples/scripts/create-wcsites-domain/output/weblogic-domains/wcsitesinfra/domain.yaml
	
	Completed	
    ```

1. To monitor the above domain creation logs:

    ```bash
    $ kubectl get pods -n wcsites-ns |grep wcsitesinfra-create
     
    wcsitesinfra-create-fmw-infra-sample-domain-job-6l7zh   1/1     Running   0          6s
    ```
    
    ```bash
    $ kubectl get pods -n wcsites-ns | grep wcsitesinfra-create | awk '{print $1}' | xargs kubectl -n wcsites-ns logs -f 
    ```
      
    SAMPLE OUTPUT:
    ```
	The domain will be created using the script /u01/weblogic/createSitesDomain.sh
	Install Automation -> Starting automation script
		[mkdir] Created dir: /u01/wcs-wls-docker-install/work
		[echo] [3/14/20 7:54 AM] Work Directory=/u01/wcs-wls-docker-install/work
		[echo] [3/14/20 7:54 AM] DB URL: jdbc:oracle:thin:@
		[echo] [3/14/20 7:54 AM] Info -> The script.db.connectstring has been set.
		[echo] [3/14/20 7:54 AM] Info.setDBConnectStringPropertey -> setting oracle-db.wcsitesdb-ns.svc.cluster.local:1521/devpdb.k8s
		[echo] [3/14/20 7:54 AM] Validation -> Checking if full path to JAVA executable is correctly specified
		[exec] java version "1.8.0_241"
		[exec] Java(TM) SE Runtime Environment (build 1.8.0_241-b07)
		[exec] Java HotSpot(TM) 64-Bit Server VM (build 25.241-b07, mixed mode)
		[echo] [3/14/20 7:54 AM] Validation -> Checking database connection
		[echo] [3/14/20 7:54 AM] dbUrl-----------------: jdbc:oracle:thin:@oracle-db.wcsitesdb-ns.svc.cluster.local:1521/devpdb.k8s
		[echo] [3/14/20 7:54 AM] Database Connection --> Success!
		[echo] [3/14/20 7:54 AM] 1st phase: WebCenter Sites installation started...
		[copy] Copying 1 file to /u01/wcs-wls-docker-install/work
		[copy] Copying /u01/wcs-wls-docker-install/rcu.rsp to /u01/wcs-wls-docker-install/work/rcu.rsp
		[echo] [3/14/20 7:54 AM] 1st phase: WebCenter Sites installation completed
		[echo] [3/14/20 7:54 AM] 2nd phase: WebCenter Sites RCU configuration started...
		[echo] [3/14/20 7:54 AM] Installation -> Repository Creation Utility - creates schema
		[echo] [3/14/20 7:54 AM] connectString-----------------: oracle-db.wcsitesdb-ns.svc.cluster.local:1521/devpdb.k8s
	[replace] Replaced 1 occurrences in 1 files.
	[replace] Replaced 1 occurrences in 1 files.
	[replace] Replaced 1 occurrences in 1 files.
	[replace] Replaced 1 occurrences in 1 files.
	[replace] Replaced 1 occurrences in 1 files.
		[echo] [3/14/20 7:54 AM] Create schema using command: /u01/oracle/oracle_common/bin/rcu -silent -responseFile /u01/wcs-wls-docker-install/work/rcu.rsp -f < /u01/wcs-wls-docker-install/work/rcuPasswords8852085298596415722.txt >/u01/wcs-wls-docker-install/work/rcu_output.log
		[echo] [3/14/20 7:54 AM] RCU Create Schema -> Please wait ... may take several minutes
		[echo] [3/14/20 8:00 AM]
		[echo]     RCU Logfile: /u01/wcs-wls-docker-install/work/rcu/RCU2020-03-14_07-54_2112542638/logs/rcu.log
		[echo] Processing command line ....
		[echo] Repository Creation Utility - Checking Prerequisites
		[echo] Checking Global Prerequisites
		[echo] Repository Creation Utility - Checking Prerequisites
		[echo] Checking Component Prerequisites
		[echo] Repository Creation Utility - Creating Tablespaces
		[echo] Validating and Creating Tablespaces
		[echo] Create tablespaces in the repository database
		[echo] Repository Creation Utility - Create
		[echo] Repository Create in progress.
		[echo] Executing pre create operations
		[echo]         Percent Complete: 20
		[echo]         Percent Complete: 20
		[echo]         Percent Complete: 22
		[echo]         Percent Complete: 24
		[echo]         Percent Complete: 26
		[echo]         Percent Complete: 26
		[echo]         Percent Complete: 28
		[echo]         Percent Complete: 28
		[echo] Creating Common Infrastructure Services(STB)
		[echo]         Percent Complete: 36
		[echo]         Percent Complete: 36
		[echo]         Percent Complete: 46
		[echo]         Percent Complete: 46
		[echo]         Percent Complete: 46
		[echo] Creating Audit Services Append(IAU_APPEND)
		[echo]         Percent Complete: 54
		[echo]         Percent Complete: 54
		[echo]         Percent Complete: 64
		[echo]         Percent Complete: 64
		[echo]         Percent Complete: 64
		[echo] Creating Audit Services Viewer(IAU_VIEWER)
		[echo]         Percent Complete: 72
		[echo]         Percent Complete: 72
		[echo]         Percent Complete: 72
		[echo]         Percent Complete: 73
		[echo]         Percent Complete: 73
		[echo]         Percent Complete: 74
		[echo]         Percent Complete: 74
		[echo]         Percent Complete: 74
		[echo] Creating WebLogic Services(WLS)
		[echo]         Percent Complete: 79
		[echo]         Percent Complete: 79
		[echo]         Percent Complete: 83
		[echo]         Percent Complete: 83
		[echo]         Percent Complete: 92
		[echo]         Percent Complete: 99
		[echo]         Percent Complete: 99
		[echo] Creating Audit Services(IAU)
		[echo]         Percent Complete: 100
		[echo] Creating Oracle Platform Security Services(OPSS)
		[echo] Creating WebCenter Sites(WCSITES)
		[echo] Executing post create operations
		[echo] Repository Creation Utility: Create - Completion Summary
		[echo] Database details:
		[echo] -----------------------------
		[echo] Host Name                                    : oracle-db.wcsitesdb-ns.svc.cluster.local:1521/devpdb.k8s
		[echo] Port                                         : 1521
		[echo] Service Name                                 : devpdb.k8s
		[echo] Connected As                                 : sys
		[echo] Prefix for (prefixable) Schema Owners        : WCS1
		[echo] RCU Logfile                                  : /u01/wcs-wls-docker-install/work/rcu/RCU2020-03-14_07-54_2112542638/logs/rcu.log
		[echo] Component schemas created:
		[echo] -----------------------------
		[echo] Component                                    Status         Logfile
		[echo] Common Infrastructure Services               Success        /u01/wcs-wls-docker-install/work/rcu/RCU2020-03-14_07-54_2112542638/logs/stb.log
		[echo] Oracle Platform Security Services            Success        /u01/wcs-wls-docker-install/work/rcu/RCU2020-03-14_07-54_2112542638/logs/opss.log
		[echo] WebCenter Sites                              Success        /u01/wcs-wls-docker-install/work/rcu/RCU2020-03-14_07-54_2112542638/logs/wcsites.log
		[echo] Audit Services                               Success        /u01/wcs-wls-docker-install/work/rcu/RCU2020-03-14_07-54_2112542638/logs/iau.log
		[echo] Audit Services Append                        Success        /u01/wcs-wls-docker-install/work/rcu/RCU2020-03-14_07-54_2112542638/logs/iau_append.log
		[echo] Audit Services Viewer                        Success        /u01/wcs-wls-docker-install/work/rcu/RCU2020-03-14_07-54_2112542638/logs/iau_viewer.log
		[echo] WebLogic Services                            Success        /u01/wcs-wls-docker-install/work/rcu/RCU2020-03-14_07-54_2112542638/logs/wls.log
		[echo] Repository Creation Utility - Create : Operation Completed
		[echo] [3/14/20 8:00 AM] Successfully created schemas
		[echo] [3/14/20 8:00 AM] 2nd phase: WebCenter Sites RCU configuration completed successfully.
		[echo] [3/14/20 8:00 AM] Oracle WebCenter Sites Installation complete. You can connect to the WebCenter Sites instance at http://10.244.0.252:7002/sites/
	
	Sites RCU Phase completed successfull!!!
	
	
	
	Sites Installation completed in 366 seconds.
	---------------------------------------------------------
	
	The domain will be created using the script /u01/weblogic/create-domain-script.sh
	wlst.sh -skipWLSModuleScanning /u01/weblogic/createSitesDomain.py -oh /u01/oracle -jh /u01/jdk -parent /u01/oracle/user_projects/domains/wcsitesinfra/.. -name wcsitesinfra -user weblogic -password Welcome1 -rcuDb oracle-db.wcsitesdb-ns.svc.cluster.local:1521/devpdb.k8s -rcuPrefix WCS1 -rcuSchemaPwd Welcome1 -adminListenPort 7001 -adminName adminserver -managedNameBase wcsites_server -managedServerPort 8001 -prodMode true -managedServerCount 3 -clusterName wcsites_cluster -exposeAdminT3Channel false -t3ChannelPublicAddress 10.123.152.96 -t3ChannelPort 30012 -domainType wcsites -machineName wcsites_machine
	
	Initializing WebLogic Scripting Tool (WLST) ...
	
	Welcome to WebLogic Server Administration Scripting Shell
	
	Type help() for help on available commands
	
	Creating Admin Server...
	Creating cluster...
	Creating Node Managers...
	managed server name is wcsites_server1
	managed server name is wcsites_server2
	managed server name is wcsites_server3
	['wcsites_server1', 'wcsites_server2', 'wcsites_server3']
	Will create Base domain at /u01/oracle/user_projects/domains/wcsitesinfra
	Writing base domain...
	Base domain created at /u01/oracle/user_projects/domains/wcsitesinfra
	Extending domain at /u01/oracle/user_projects/domains/wcsitesinfra
	Database  oracle-db.wcsitesdb-ns.svc.cluster.local:1521/devpdb.k8s
	ExposeAdminT3Channel false with 10.123.152.96:30012
	Applying JRF templates...
	Extension Templates added
	Applying Oracle WebCenter Sites templates...
	Extension Templates added
	Configuring the Service Table DataSource...
	fmwDb...jdbc:oracle:thin:@oracle-db.wcsitesdb-ns.svc.cluster.local:1521/devpdb.k8s
	Set user...WCS140_OPSS
	Set user...WCS140_IAU_APPEND
	Set user...WCS140_IAU_VIEWER
	Set user...WCS140_STB
	Set user...WCS140_WCSITES
	Getting Database Defaults...
	Targeting Server Groups...
	Targeting Server Groups...
	Set CoherenceClusterSystemResource to defaultCoherenceCluster for server:wcsites_server1
	Set CoherenceClusterSystemResource to defaultCoherenceCluster for server:wcsites_server2
	Set CoherenceClusterSystemResource to defaultCoherenceCluster for server:wcsites_server3
	Targeting Cluster ...
	Set CoherenceClusterSystemResource to defaultCoherenceCluster for cluster:wcsites_cluster
	Set WLS clusters as target of defaultCoherenceCluster:[wcsites_cluster]
	Preparing to update domain...
	Mar 14, 2020 8:01:52 AM oracle.security.jps.az.internal.runtime.policy.AbstractPolicyImpl initializeReadStore
	INFO: Property for read store in parallel: oracle.security.jps.az.runtime.readstore.threads = null
	Domain updated successfully
	Copying /u01/weblogic/server-config-update.sh to PV /u01/oracle/user_projects/domains/wcsitesinfra
	Copying /u01/weblogic/unicast.py to PV /u01/oracle/user_projects/domains/wcsitesinfra
	replacing tokens in /u01/oracle/user_projects/domains/wcsitesinfra/server-config-update.sh
	Successfully Completed
    ```

#### Initialize the WebCenter Sites Domain

To start the domain, apply the above `domain.yaml`:

	```bash
	$ kubectl apply -f kubernetes/samples/scripts/create-wcsites-domain/output/weblogic-domains/wcsitesinfra/domain.yaml
	domain.weblogic.oracle/wcsitesinfra created
	```

#### Verify the WebCenter Sites Domain        
Verify that the domain and servers pods and services are created and in the READY state:

Sample run below:
```bash
-bash-4.2$ kubectl get pods -n wcsites-ns -w
NAME                                                    READY   STATUS      	RESTARTS	AGE
wcsitesinfra-create-fmw-infra-sample-domain-job-6l7zh   0/1     Completed   	0          	15m
wcsitesinfra-introspect-domain-job-7tvdt                1/1     Running     	0          	15s
wcsitesinfra-introspect-domain-job-7tvdt   				0/1   	Completed   	0     	   	25s
wcsitesinfra-introspect-domain-job-7tvdt   				0/1   	Terminating 	0     		5s
wcsitesinfra-adminserver  								0/1   	Pending   		0     		0s
wcsitesinfra-adminserver  								0/1   	Init:0/1  		0     		0s
wcsitesinfra-adminserver  								0/1   	PodInitializing 0     		12s
wcsitesinfra-adminserver  								0/1   	Running   		0     		13s
wcsitesinfra-adminserver  								1/1   	Running   		0     		108s
wcsitesinfra-wcsites-server1   							0/1   	Pending   		0     		0s
wcsitesinfra-wcsites-server1   							0/1   	Init:0/1  		0     		1s
wcsitesinfra-wcsites-server1   							0/1   	PodInitializing 0     		13s
wcsitesinfra-wcsites-server1   							0/1   	Running   		0     		14s
wcsitesinfra-wcsites-server1   							1/1   	Running   		0     		96s
```

```bash
-bash-4.2$ kubectl get all -n wcsites-ns
NAME                                                        READY   STATUS      RESTARTS   AGE
pod/wcsitesinfra-adminserver                                1/1     Running     0          7m5s
pod/wcsitesinfra-create-fmw-infra-sample-domain-job-6l7zh   0/1     Completed   0          22m
pod/wcsitesinfra-wcsites-server1                            1/1     Running     0          5m17s

NAME                                           TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/wcsitesinfra-adminserver               ClusterIP   None           <none>        7001/TCP   7m5s
service/wcsitesinfra-cluster-wcsites-cluster   ClusterIP   10.109.210.3   <none>        8001/TCP   5m17s
service/wcsitesinfra-wcsites-server1           ClusterIP   None           <none>        8001/TCP   5m17s

NAME                                                        COMPLETIONS   DURATION   AGE
job.batch/wcsitesinfra-create-fmw-infra-sample-domain-job   1/1           7m40s      22m
```

To see the Admin and Managed Servers logs, you can check the pod logs:

```bash
$ kubectl logs -f wcsitesinfra-adminserver -n wcsites-ns
```
```bash
$ kubectl exec -it wcsitesinfra-adminserver  -n wcsites-ns -- /bin/bash
```
```bash
$ kubectl logs -f wcsitesinfra-wcsites-server1 -n wcsites-ns
```
```bash
$ kubectl exec -it wcsitesinfra-wcsites-server1  -n wcsites-ns -- /bin/bash
```

##### Verify the Pods

Use the following command to see the pods running the servers:

```
$ kubectl get pods -n NAMESPACE
```

Here is an example of the output of this command:

```
-bash-4.2$ kubectl get pods -n wcsites-ns
NAME                                                    READY   STATUS      RESTARTS   AGE
wcsitesinfra-adminserver                                1/1     Running     0          56m
wcsitesinfra-create-fmw-infra-sample-domain-job-rq4xv   0/1     Completed   0          65m
wcsitesinfra-wcsites-server1                            1/1     Running     0          41m
wcsitesinfra-wcsites-server2                            1/1     Running     0          41m
```

##### Verify the Services

Use the following command to see the services for the domain:

```
$ kubectl get services -n NAMESPACE
```

Here is an example of the output of this command:
```
-bash-4.2$ kubectl get services -n wcsites-ns
NAME                                                    READY   STATUS      RESTARTS   AGE
wcsitesinfra-adminserver                                1/1     Running     0          7m38s
wcsitesinfra-create-fmw-infra-sample-domain-job-6l7zh   0/1     Completed   0          23m
wcsitesinfra-wcsites-server1                            1/1     Running     0          5m50s
```

#### Expose WebCenter Sites Services

Below are the default values for exposing services required for all the WebCenter Sites Managed Servers. 
Reset them if any values are modified.

Details on `kubernetes/samples/scripts/create-wcsites-domain/utils/wcs-services.yaml`:

* name: wcsitesinfra-wcsites-server1-np
* namespace: wcsites-ns
* weblogic.domainUID: wcsitesinfra
* weblogic.serverName: wcsites_server1

Execute the below command for exposing the services: (If domain is configured for more than 3 Managed Servers then add the service yaml for additional servers.)

```bash
$ kubectl apply -f kubernetes/samples/scripts/create-wcsites-domain/utils/wcs-services.yaml
service/wcsitesinfra-wcsites-server1-np created
service/wcsitesinfra-wcsites-server1-svc created
service/wcsitesinfra-wcsites-server2-svc created
service/wcsitesinfra-wcsites-server3-svc created
```

To verify the services created, here is an example of the output of this command:

```
-bash-4.2$ kubectl get services -n wcsites-ns
NAME                                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                                                               AGE
wcsitesinfra-adminserver               ClusterIP   None             <none>        7001/TCP                                                                                              11m
wcsitesinfra-cluster-wcsites-cluster   ClusterIP   10.109.210.3     <none>        8001/TCP                                                                                              9m14s
wcsitesinfra-wcsites-server1           ClusterIP   None             <none>        8001/TCP                                                                                              9m14s
wcsitesinfra-wcsites-server1-np        NodePort    10.105.167.205   <none>        8001:30155/TCP                                                                                        2m47s
wcsitesinfra-wcsites-server1-svc       ClusterIP   None             <none>        50000/TCP,50001/TCP,50002/TCP,50003/TCP,50004/TCP,50005/TCP,50006/TCP,50007/TCP,50008/TCP,50009/TCP   2m47s
wcsitesinfra-wcsites-server2-svc       ClusterIP   None             <none>        50000/TCP,50001/TCP,50002/TCP,50003/TCP,50004/TCP,50005/TCP,50006/TCP,50007/TCP,50008/TCP,50009/TCP   2m47s
wcsitesinfra-wcsites-server3-svc       ClusterIP   None             <none>        50000/TCP,50001/TCP,50002/TCP,50003/TCP,50004/TCP,50005/TCP,50006/TCP,50007/TCP,50008/TCP,50009/TCP   2m47s
```

#### Load Balance With an Ingress Controller or A Web Server

You can choose a load balancer provider for your WebLogic domains running in a Kubernetes cluster. 
Please refer to the [WebLogic Kubernetes Operator Load Balancer Samples](https://github.com/oracle/weblogic-kubernetes-operator/blob/master/kubernetes/samples/charts/README.md) for information about the current capabilities and setup instructions for each of the supported load balancers.

For information on how to set up Loadbalancer for setting up WebCenter Sites domain on K8S:

For Traefik, see [Setting Up Loadbalancer Traefik for the WebCenter Sites Domain on K8S]({{< relref "/wcsites-domains/adminguide/configure-load-balancer/traefik.md">}})

For Voyager, see [Setting Up Loadbalancer Voyager for the WebCenter Sites Domain on K8S]({{< relref "/wcsites-domains/adminguide/configure-load-balancer/voyager.md">}})

#### Configure WebCenter Sites 

1. Configure WebCenter Sites by hitting url `http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}/sites/sitesconfigsetup`

    When installing, select sample sites to be installed and enter the required passwords. Do not change the sites-config location. If you change the location, installation will fail.

2. After the configuration is complete, edit the domain, and restart the Managed Server.

To stop Managed Servers:

```bash
$ kubectl patch domain wcsitesinfra -n wcsites-ns --type='json' -p='[{"op": "replace", "path": "/spec/clusters/0/replicas", "value": 0 }]'
```

To start all configured Managed Servers:

```bash
$ kubectl patch domain wcsitesinfra -n wcsites-ns --type='json' -p='[{"op": "replace", "path": "/spec/clusters/0/replicas", "value": 3 }]' 
```

3. Wait till the Managed Server pod is killed and then restart it. Monitor with below command:
    ```bash
	-bash-4.2$ kubectl get pods -n wcsites-ns -w
	NAME                                                    READY   STATUS      RESTARTS   AGE
	wcsitesinfra-adminserver                                1/1     Running     0          111m
	wcsitesinfra-create-fmw-infra-sample-domain-job-6l7zh   0/1     Completed   0          126m
	wcsitesinfra-wcsites-server1                            1/1     Running     0          3m7s
	wcsitesinfra-wcsites-server2                            1/1     Running     0          3m7s
	wcsitesinfra-wcsites-server3                            1/1     Running     0          3m7s
    ```
	
#### Settings in WebCenter Sites Property Management

Incase of Voyager Load Balancer: Use Property Management Tool and update `cookieserver.validnames` property with value `JSESSIONID,SERVERID`.

Incase of Traefik Load Balancer: Use Property Management Tool and update `cookieserver.validnames` property with value `JSESSIONID,sticky`.

Incase of Nginx Load Balancer: Use Property Management Tool and update `cookieserver.validnames` property with value `JSESSIONID,stickyid`.

#### For Publishing Setting in WebCenter Sites

While configuring publishing destination use NodePort `port` of target cluster which can be found by executing below command: 

(In this example for publishihng the port `30155` has to be used.)

```bash
-bash-4.2$ kubectl get service/wcsitesinfra-wcsites-server1-np -n wcsites-ns
NAME                              TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
wcsitesinfra-wcsites-server1-np   NodePort   10.105.167.205   <none>        8001:30155/TCP   32h
```

#### Customization

A customer specific customizations (extend.sites.webapp-lib.war) has to be placed in sites-home directory inside your domain mount path. 