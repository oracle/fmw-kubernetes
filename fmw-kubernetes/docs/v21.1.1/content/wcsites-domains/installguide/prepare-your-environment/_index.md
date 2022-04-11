+++
title=  "Prepare your environment"
date = 2019-04-18T06:46:23-05:00
weight = 2
pre = "<b>  </b>"
description = "Prepare for creating Oracle WebCenter Sites domains, including required secrets creation, persistent volume and volume claim creation, database creation, and database schema creation."
+++

#### Contents
This document describes the steps to set up the environment that includes setting up of a Kubernetes cluster and  setting up the WebLogic Operator including the database.

* [Introduction](#introduction)
* [Set Up your Kubernetes Cluster](#set-up-your-kubernetes-cluster)
* [Build Oracle WebCenter Sites Image](#build-oracle-webcenter-sites-image)
* [Pull Other Dependent Images](#pull-other-dependent-images)
* [Set Up the Code Repository to Deploy Oracle WebCenter Sites Domain](#set-up-the-code-repository-to-deploy-oracle-webcenter-sites-domain)
* [Grant Roles and Clear Stale Resources](#grant-roles-and-clear-stale-resources)
* [Install the WebLogic Kubernetes Operator](#install-the-weblogic-kubernetes-operator)
* [Configure NFS Server](#configure-nfs-server)
* [Prepare the Environment for the WebCenter Sites Domain](#prepare-the-environment-for-the-webcenter-sites-domain)
* [Configure access to your database](#Configure-access-to-your-database)

#### Introduction

#### Set Up your Kubernetes Cluster

If you need help in setting up a Kubernetes environment, check our [cheat sheet](https://oracle.github.io/weblogic-kubernetes-operator/userguide/overview/k8s-setup).

After creating Kubernetes clusters, you can optionally:

* Create load balancers to direct traffic to backend domains.
* Configure Kibana and Elasticsearch for your operator logs.

#### Build Oracle WebCenter Sites Image

Build Oracle WebCenter Sites 12.2.1.4 Image by following steps from this [document](https://oracle.github.io/fmw-kubernetes/wcsites-domains/create-or-update-image/#create-an-image).

#### Pull Other Dependent Images

Dependent images include WebLogic Kubernetes Operator, and Traefik. Pull these images and add them to your local registry:

1. Pull these Docker images and re-tag them as shown:

To pull an image from the Oracle Container Registry, in a web browser, navigate to ```https://container-registry.oracle.com``` and log in using the Oracle Single Sign-On authentication service. If you do not already have SSO credentials, at the top of the page, click the Sign In link to create them.

Use the web interface to accept the Oracle Standard Terms and Restrictions for the Oracle software images that you intend to deploy. Your acceptance of these terms are stored in a database that links the software images to your Oracle Single Sign-On login credentials.

Then, pull these Docker images and re-tag them:

```
docker login https://container-registry.oracle.com (enter your Oracle email Id and password)
This step is required once at every node to get access to the Oracle Container Registry.
```

WebLogic Kubernetes Operator image:
```bash
$ docker pull container-registry.oracle.com/middleware/weblogic-kubernetes-operator:3.0.1
$ docker tag container-registry.oracle.com/middleware/weblogic-kubernetes-operator:3.0.1 oracle/weblogic-kubernetes-operator:3.0.1
```

2. Copy all the above built and pulled images to all the nodes in your cluster or add to a Docker registry that your cluster can access.

NOTE: If you're not running Kubernetes on your development machine, you'll need to make the Docker image available to a registry visible to your Kubernetes cluster.
       Upload your image to a machine running Docker and Kubernetes as follows:
```bash
# on your build machine
$ docker save Image_Name:Tag > Image_Name-Tag.tar
$ scp Image_Name-Tag.tar YOUR_USER@YOUR_SERVER:/some/path/Image_Name-Tag.tar

# on the Kubernetes server
$ docker load < /some/path/Image_Name-Tag.tar
```

#### Set Up the Code Repository to Deploy Oracle WebCenter Sites Domain

Oracle WebCenter Sites domain deployment on Kubernetes leverages the Oracle WebLogic Kubernetes Operator infrastructure. For deploying the Oracle WebCenter Sites domain, you need to set up the deployment scripts as below:

1. Create a working directory to setup the source code.
   ```bash
   $ mkdir <work directory>
   $ cd <work directory>
   ```

1. Download the supported version of Oracle WebLogic Kubernetes Operator source code archieve file (`.zip`/`.tar.gz`) from the operator [relases page](https://github.com/oracle/weblogic-kubernetes-operator/releases). Currently the supported operator version can be downloaded from [3.0.1](https://github.com/oracle/weblogic-kubernetes-operator/archive/v3.0.1.zip).

1. Extract the source code archive file (`.zip`/`.tar.gz`) in to the work directory.

1. Download the WebCenter Sites kubernetes deployment scripts from this [repository](https://github.com/oracle/fmw-kubernetes.git) and copy them in to WebLogic operator samples location.

   ```bash
   $ git clone https://github.com/oracle/fmw-kubernetes.git
   $ cp -rf <work directory>/fmw-kubernetes/OracleWebCenterSites/kubernetes/3.0.1/create-wcsites-domain  <work directory>/weblogic-kubernetes-operator-3.0.1/kubernetes/samples/scripts/
   ```

You can now use the deployment scripts from `<work directory>/weblogic-kubernetes-operator-3.0.1` to set up the WebCenter Sites domain as further described in this document.

This will be your home directory for runnning all the required scripts.

```bash
$ cd <work directory>/weblogic-kubernetes-operator-3.0.1
```

#### Clear Stale Resources

1. To confirm if there is already a WebLogic custom resource definition, execute the following command:

    ```bash
    $ kubectl get crd
    NAME                      CREATED AT
    domains.weblogic.oracle   2020-03-14T12:10:21Z
    ```
2. If you find any WebLogic custom resource definition, then delete it by executing the following command:
    ```bash
    $ kubectl delete crd domains.weblogic.oracle
    customresourcedefinition.apiextensions.k8s.io "domains.weblogic.oracle" deleted
    ```
    
#### Install the WebLogic Kubernetes Operator

1. Create a namespace for the WebLogic Kubernetes Operator:

    ```bash
        $ kubectl create namespace operator-ns
        namespace/operator-ns created
    ```
    NOTE: For this exercise we are creating a namespace called "operator-ns" (can be any name).
             
    You can also use:
    * domainUID/domainname  as   `wcsitesinfra`
    * Domain namespace      as   `wcsites-ns`
    * Operator namespace    as   `operator-ns`
    * traefik namespace     as   `traefik`
    
1. Create a service account for the WebLogic Kubernetes Operator in the Operator's namespace:

    ```bash
    $ kubectl create serviceaccount -n operator-ns operator-sa
    serviceaccount/operator-sa created
    ```

1. To be able to set up the log-stash and Elasticsearch after creating the domain, set the value of the field `elkIntegrationEnabled` to `true` in the file `kubernetes/charts/weblogic-operator/values.yaml`.

1. Use helm to install and start the WebLogic Kubernetes Operator from the downloaded repository:

	> Helm install weblogic-operator

	```bash
	$ helm install weblogic-kubernetes-operator kubernetes/charts/weblogic-operator --namespace operator-ns --set serviceAccount=operator-sa --set "domainNamespaces={}" --wait
 
 
	NAME: weblogic-kubernetes-operator
	LAST DEPLOYED: Tue May 19 04:04:32 2020
	NAMESPACE: opns
	STATUS: deployed
	REVISION: 1
	TEST SUITE: None
	```

1. To verify that the Operator's pod is running, list the pods in the Operator's namespace. You should see one for the WebLogic Kubernetes Operator:

    ```bash
    $ kubectl get pods -n operator-ns
    NAME                                 READY   STATUS    RESTARTS   AGE
	weblogic-operator-67df5fddc5-tlc4b   2/2     Running   0          3m15s
    ```

2. Then, check by viewing the Operator pod's log as shown in the following sample log snippet:

    ```bash
    $ kubectl logs -n operator-ns -c weblogic-operator deployments/weblogic-operator
     
	Launching Oracle WebLogic Server Kubernetes Operator...
	Importing keystore /operator/internal-identity/temp/weblogic-operator.jks to /operator/internal-identity/temp/weblogic-operator.p12...
	Entry for alias weblogic-operator-alias successfully imported.
	Import command completed:  1 entries successfully imported, 0 entries failed or cancelled
	
	Warning:
	The -srcstorepass option is specified multiple times. All except the last one will be ignored.
	MAC verified OK
	% Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
									Dload  Upload   Total   Spent    Left  Speed
	100  4249    0  2394  100  1855   6884   5334 --:--:-- --:--:-- --:--:--  6899
	% Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
									Dload  Upload   Total   Spent    Left  Speed
	100  5558    0  3028  100  2530  22704  18970 --:--:-- --:--:-- --:--:-- 22766
	OpenJDK 64-Bit Server VM warning: Option MaxRAMFraction was deprecated in version 10.0 and will likely be removed in a future release.
	VM settings:
		Max. Heap Size (Estimated): 14.08G
		Using VM: OpenJDK 64-Bit Server VM
	
	{"timestamp":"03-14-2020T06:49:53.438+0000","thread":1,"fiber":"","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.TuningParametersImpl","method":"update","timeInMillis":1584168593438,"message":"Reloading tuning parameters from Operator's config map","exception":"","code":"","headers":{},"body":""}
	{"timestamp":"03-14-2020T06:49:53.944+0000","thread":1,"fiber":"","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.Main","method":"main","timeInMillis":1584168593944,"message":"Oracle WebLogic Server Kubernetes Operator, version: 3.0.1, implementation: master.4d4fe0a, build time: 2019-11-15T21:19:56-0500","exception":"","code":"","headers":{},"body":""}
	{"timestamp":"03-14-2020T06:49:53.972+0000","thread":11,"fiber":"","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.Main","method":"begin","timeInMillis":1584168593972,"message":"Operator namespace is: operator-ns","exception":"","code":"","headers":{},"body":""}
	{"timestamp":"03-14-2020T06:49:54.009+0000","thread":11,"fiber":"","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.Main","method":"begin","timeInMillis":1584168594009,"message":"Operator target namespaces are: operator-ns","exception":"","code":"","headers":{},"body":""}
	{"timestamp":"03-14-2020T06:49:54.013+0000","thread":11,"fiber":"","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.Main","method":"begin","timeInMillis":1584168594013,"message":"Operator service account is: operator-sa","exception":"","code":"","headers":{},"body":""}	{"timestamp":"03-14-2020T06:49:54.031+0000","thread":11,"fiber":"","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.helpers.HealthCheckHelper","method":"performK8sVersionCheck","timeInMillis":1584168594031,"message":"Verifying Kubernetes minimum version","exception":"","code":"","headers":{},"body":""}	{"timestamp":"03-14-2020T06:49:54.286+0000","thread":11,"fiber":"","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.helpers.ClientPool","method":"getApiClient","timeInMillis":1584168594286,"message":"The Kuberenetes Master URL is set to https://10.96.0.1:443","exception":"","code":"","headers":{},"body":""}	{"timestamp":"03-14-2020T06:49:54.673+0000","thread":11,"fiber":"","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.helpers.HealthCheckHelper","method":"createAndValidateKubernetesVersion","timeInMillis":1584168594673,"message":"Kubernetes version is: v1.13.7","exception":"","code":"","headers":{},"body":""}	{"timestamp":"03-14-2020T06:49:55.259+0000","thread":12,"fiber":"engine-operator-thread-2-fiber-1","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.helpers.CrdHelper$CrdContext$CreateResponseStep","method":"onSuccess","timeInMillis":1584168595259,"message":"Create Custom Resource Definition: oracle.kubernetes.operator.calls.CallResponse@470b40c","exception":"","code":"","headers":{},"body":""}	{"timestamp":"03-14-2020T06:49:55.356+0000","thread":16,"fiber":"fiber-1-child-2","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.helpers.HealthCheckHelper","method":"performSecurityChecks","timeInMillis":1584168595356,"message":"Verifying that operator service account can access required operations on required resources in namespace operator-ns","exception":"","code":"","headers":{},"body":""}	{"timestamp":"03-14-2020T06:49:55.598+0000","thread":18,"fiber":"fiber-1-child-2","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.helpers.ConfigMapHelper$ScriptConfigMapContext$CreateResponseStep","method":"onSuccess","timeInMillis":1584168595598,"message":"Creating domain config map, operator-ns, for namespace: {1}.","exception":"","code":"","headers":{},"body":""}	{"timestamp":"03-14-2020T06:49:55.937+0000","thread":21,"fiber":"fiber-1","domainUID":"","level":"WARNING","class":"oracle.kubernetes.operator.utils.Certificates","method":"getCertificate","timeInMillis":1584168595937,"message":"Can't read certificate at /operator/external-identity/externalOperatorCert","exception":"\njava.nio.file.NoSuchFileException: /operator/external-identity/externalOperatorCert\n\tat java.base/sun.nio.fs.UnixException.translateToIOException(UnixException.java:92)\n\tat java.base/sun.nio.fs.UnixException.rethrowAsIOException(UnixException.java:111)\n\tat java.base/sun.nio.fs.UnixException.rethrowAsIOException(UnixException.java:116)\n\tat java.base/sun.nio.fs.UnixFileSystemProvider.newByteChannel(UnixFileSystemProvider.java:215)\n\tat java.base/java.nio.file.Files.newByteChannel(Files.java:370)\n\tat java.base/java.nio.file.Files.newByteChannel(Files.java:421)\n\tat java.base/java.nio.file.Files.readAllBytes(Files.java:3205)\n\tat oracle.kubernetes.operator.utils.Certificates.getCertificate(Certificates.java:48)\n\tat oracle.kubernetes.operator.utils.Certificates.getOperatorExternalCertificateData(Certificates.java:39)\n\tat oracle.kubernetes.operator.rest.RestConfigImpl.getOperatorExternalCertificateData(RestConfigImpl.java:52)\n\tat oracle.kubernetes.operator.rest.RestServer.isExternalSslConfigured(RestServer.java:383)\n\tat oracle.kubernetes.operator.rest.RestServer.start(RestServer.java:199)\n\tat oracle.kubernetes.operator.Main.startRestServer(Main.java:353)\n\tat oracle.kubernetes.operator.Main.completeBegin(Main.java:198)\n\tat oracle.kubernetes.operator.Main$NullCompletionCallback.onCompletion(Main.java:701)\n\tat oracle.kubernetes.operator.work.Fiber.completionCheck(Fiber.java:475)\n\tat oracle.kubernetes.operator.work.Fiber.run(Fiber.java:448)\n\tat oracle.kubernetes.operator.work.ThreadLocalContainerResolver.lambda$wrapExecutor$0(ThreadLocalContainerResolver.java:87)\n\tat java.base/java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:515)\n\tat java.base/java.util.concurrent.FutureTask.run(FutureTask.java:264)\n\tat java.base/java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.run(ScheduledThreadPoolExecutor.java:304)\n\tat java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1128)\n\tat java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:628)\n\tat java.base/java.lang.Thread.run(Thread.java:834)\n","code":"","headers":{},"body":""}
	{"timestamp":"03-14-2020T06:49:55.967+0000","thread":21,"fiber":"fiber-1","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.rest.RestServer","method":"start","timeInMillis":1584168595967,"message":"Did not start the external ssl REST server because external ssl has not been configured.","exception":"","code":"","headers":{},"body":""}
	{"timestamp":"03-14-2020T06:49:57.910+0000","thread":21,"fiber":"fiber-1","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.rest.RestServer","method":"start","timeInMillis":1584168597910,"message":"Started the internal ssl REST server on https://0.0.0.0:8082/operator","exception":"","code":"","headers":{},"body":""}	{"timestamp":"03-14-2020T06:49:57.913+0000","thread":21,"fiber":"fiber-1","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.Main","method":"markReadyAndStartLivenessThread","timeInMillis":1584168597913,"message":"Starting Operator Liveness Thread","exception":"","code":"","headers":{},"body":""}
    ```

#### Configure NFS (Network File System) Server
To configure NFS server, install the nfs-utils package preferably on Master node:

```bash
$ sudo yum install nfs-utils
```

To start the nfs-server service, and configure the service to start following a system reboot:

```bash
$ sudo systemctl start nfs-server
$ sudo systemctl enable nfs-server
```

Create the directory you want to export as the NFS share, for example `/scratch/K8SVolume`:

```bash
$ sudo mkdir -p /scratch/K8SVolume
$ sudo chown -R 1000:1000 /scratch/K8SVolume
```

host name or IP address of the NFS Server

Note: Host name or IP address of the NFS Server and NFS Share path which is used when you create PV/PVC in further sections.

#### Prepare the Environment for the WebCenter Sites Domain
1. Unless you would like to use the default namespace, create a Kubernetes namespace that can host one or more domains:

    ```bash
    $ kubectl create namespace wcsites-ns
    namespace/wcsites-ns created
    ```
2. To manage domains in this namespace, configure the Operator using helm:
    
    > Helm upgrade weblogic-operator

    ```bash
    helm upgrade --reuse-values --set "domainNamespaces={wcsites-ns}" \
    --wait weblogic-kubernetes-operator kubernetes/charts/weblogic-operator --namespace operator-ns

    NAME: weblogic-kubernetes-operator
	LAST DEPLOYED: Tue May 19 04:06:23 2020
	NAMESPACE: opns
	STATUS: deployed
	REVISION: 2
	TEST SUITE: None
	```

3. Create Kubernetes secrets:

    a. Using the create-weblogic-credentials script, create a Kubernetes secret that contains the user name and password for the domain in the same Kubernetes namespace as the domain:
    
    Output:
    ```bash
    $ sh kubernetes/samples/scripts/create-weblogic-domain-credentials/create-weblogic-credentials.sh \
        -u weblogic -p Welcome1 -n wcsites-ns \
        -d wcsitesinfra -s wcsitesinfra-domain-credentials
     
    secret/wcsitesinfra-domain-credentials created
    secret/wcsitesinfra-domain-credentials labeled
    The secret wcsitesinfra-domain-credentials has been successfully created in the wcsites-ns namespace.
    ```
    Where:
    
       * weblogic                         is the weblogic username
       * Welcome1                         is the weblogic password
       * wcsitesinfra                     is the domain name
       * wcsites-ns                       is the domain namespace
       * wcsitesinfra-domain-credentials  is the secret name
    
    Note: You can inspect the credentials as follows:
    ```bash
    $ kubectl get secret wcsitesinfra-domain-credentials -o yaml -n wcsites-ns
    ```
    b. Create a Kubernetes secret for the Repository Configuration Utility (user name and password) using the `create-rcu-credentials.sh` script in the same Kubernetes namespace as the domain:

    Output:
    
    ```bash
    $ sh kubernetes/samples/scripts/create-rcu-credentials/create-rcu-credentials.sh \
        -u WCS1 -p Welcome1 -a sys -q Oradoc_db1 -n wcsites-ns \
        -d wcsitesinfra -s wcsitesinfra-rcu-credentials
     
    secret/wcsitesinfra-rcu-credentials created
    secret/wcsitesinfra-rcu-credentials labeled
    The secret wcsitesinfra-rcu-credentials has been successfully created in the wcsites-ns namespace.
    ```
    Where:
    
       * WCS1                             is the schema user
       * Welcome1                         is the schema password
       * Oradoc_db1                       is the database SYS users password
       * wcsitesinfra                     is the domain name
       * wcsites-ns                       is the domain namespace
       * wcsitesinfra-rcu-credentials     is the secret name
    
    Note: You can inspect the credentials as follows:

    ```bash
    $ kubectl get secret wcsitesinfra-rcu-credentials -o yaml -n wcsites-ns
    ```

4. Create a Kubernetes PV and PVC (Persistent Volume and Persistent Volume Claim):

    a. Update the `kubernetes/samples/scripts/create-wcsites-domain/utils/create-wcsites-pv-pvc-inputs.yaml`.
	
	Replace the token `%NFS_SERVER%` with the host name/IP of NFS Server created in [Configure NFS Server](#configure-nfs-server) section.   
	
	In the NFS Server, create a folder and grant permissions as given below:
    
    ```bash
    $ sudo rm -rf /scratch/K8SVolume/WCSites && sudo mkdir -p /scratch/K8SVolume/WCSites && sudo chown 1000:1000 /scratch/K8SVolume/WCSites
    ```
	
	Update the `weblogicDomainStoragePath` paramter with `/scratch/K8SVolume/WCSites`.
	
    
    b. Execute the `create-pv-pvc.sh` script to create the PV and PVC configuration files:
    
    ```bash
    $ sh kubernetes/samples/scripts/create-weblogic-domain-pv-pvc/create-pv-pvc.sh \
        -i kubernetes/samples/scripts/create-wcsites-domain/utils/create-wcsites-pv-pvc-inputs.yaml \
        -o kubernetes/samples/scripts/create-wcsites-domain/output
     
    Input parameters being used
	export version="create-weblogic-sample-domain-pv-pvc-inputs-v1"
	export baseName="domain"
	export domainUID="wcsitesinfra"
	export namespace="wcsites-ns"
	export weblogicDomainStorageType="HOST_PATH"
	export weblogicDomainStoragePath="/scratch/K8SVolume/WCSites"
	export weblogicDomainStorageReclaimPolicy="Retain"
	export weblogicDomainStorageSize="10Gi"
	
	Generating kubernetes/samples/scripts/create-wcsites-domain/output/pv-pvcs/wcsitesinfra-domain-pv.yaml
	Generating kubernetes/samples/scripts/create-wcsites-domain/output/pv-pvcs/wcsitesinfra-domain-pvc.yaml
	The following files were generated:
	kubernetes/samples/scripts/create-wcsites-domain/output/pv-pvcs/wcsitesinfra-domain-pv.yaml
	kubernetes/samples/scripts/create-wcsites-domain/output/pv-pvcs/wcsitesinfra-domain-pvc.yaml
	
	Completed
    ```
    
    c. To create the PV and PVC, use `kubectl create` with output configuration files: 
    
    Output:
    
    ```bash
    $ kubectl create -f kubernetes/samples/scripts/create-wcsites-domain/output/pv-pvcs/wcsitesinfra-domain-pv.yaml \
        -f kubernetes/samples/scripts/create-wcsites-domain/output/pv-pvcs/wcsitesinfra-domain-pvc.yaml
     
    persistentvolume/wcsitesinfra-domain-pv created
    persistentvolumeclaim/wcsitesinfra-domain-pvc created
    ```
    Note: You can verify the PV and PV's details as follows:
    
    ```bash
    $ kubectl describe pv wcsitesinfra-domain-pv -n wcsites-ns
    ```
    
    ```bash
    $ kubectl describe pvc wcsitesinfra-domain-pvc -n wcsites-ns
    ```
    
5. Label the nodes in the Kubernetes cluster for the targeted scheduling of the servers on particular nodes as needed:

    ```bash
    kubectl label node <node-name> name=abc
    ```
    
    Note: Here `<node-name>` is the node as displayed in the NAME field of `kubectl get nodes` command.
    abc is the label that we are defining.  Label is a key, value pair and can be anything meaningful. The same should be used for nodeSelector.
    
    For scheduling we can select these nodes based on the labels.

#### Configure access to your database

Oracle WebCenter Sites domains require a database with the necessary schemas installed in them. The Repository Creation Utility (RCU) allows you to create those schemas. You must set up the database before you create your domain. There are no additional requirements added by running Oracle WebCenter Sites in Kubernetes; the same existing requirements apply.

For production deployments, you must set up and use the standalone (non-container) based database running outside of Kubernetes.

Before creating a domain, you will need to set up the necessary schemas in your database.