+++
title = "Prepare your environment"
weight = 2
pre = "<b>  </b>"
description = "Prepare for creating the Oracle WebCenter Portal domain, This preparation includes but not limited to creating required secrets, persistent volume and volume claim, and database schema."
+++

Set up the environment, including setting up a Kubernetes cluster and the Weblogic Kubernetes Operator.

1. [Install Helm](#install-helm)
1. [Set Up your Kubernetes Cluster](#set-up-your-kubernetes-cluster)
1. [Obtain the Oracle WebCenter Portal Docker Image](#obtain-the-oracle-webcenter-portal-docker-image)
1. [Pull Other Dependent Images](#pull-other-dependent-images)
1. [Set Up the Code Repository to Deploy Oracle WebCenter Portal Domain](#set-up-the-code-repository-to-deploy-oracle-webcenter-portal-domain)
1. [Grant Roles and Clear Stale Resources](#grant-roles-and-clear-stale-resources)
1. [Install the WebLogic Kubernetes Operator](#install-the-weblogic-kubernetes-operator)
1. [Prepare the Environment for the WebCenter Portal Domain](#prepare-the-environment-for-the-webcenter-portal-domain)
 
    a. [Create a namespace for an Oracle WebCenter Portal domain](#create-a-namespace-for-an-oracle-webcenter-portal-domain)
    
    b. [Create a Kubernetes secret with domain credentials](#create-a-kubernetes-secret-with-domain-credentials)
    
    c. [Create a Kubernetes secret with the RCU credentials](#create-a-kubernetes-secret-with-the-rcu-credentials)
    
    d. [Create a persistent storage for an Oracle WebCenter Portal domain](#create-a-persistent-storage-for-an-oracle-webcenter-portal-domain)
    
    e. [Configure access to your database](#configure-access-to-your-database)
    
    f. [Run the Repository Creation Utility to set up your database schemas](#run-the-repository-creation-utility-to-set-up-your-database-schemas)

### Install Helm
    
 The operator uses Helm to create and deploy the necessary resources and then run the operator in a Kubernetes cluster. For Helm installation and usage information, see [here](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-operators/#install-helm).


### Set Up your Kubernetes Cluster

If you need help in setting up a Kubernetes environment, check our [cheat sheet](https://oracle.github.io/weblogic-kubernetes-operator/userguide/overview/k8s-setup).

After creating Kubernetes clusters, you can optionally:
* Create load balancers to direct traffic to backend domain
* Configure Kibana and Elasticsearch for your operator logs

### Obtain the Oracle WebCenter Portal Docker Image
The Oracle WebCenter Portal image with latest bundle patch and required interim patches can be obtained from My Oracle Support (MOS). This is the only image supported for production deployments. Follow the below steps to download the Oracle WebCenter Portal image from My Oracle Support.

1. Download patch [32688937](https://support.oracle.com/epmos/faces/ui/patch/PatchDetail.jspx?patchId=32688937) from My Oracle Support (MOS).

1. Unzip the downloaded patch zip file.

1. Load the image archive using the `docker load` command.

    For example:
    ```bash
    $ docker load < wcportal-12.2.1.4.0-210326.0857.320.tar
    Loaded image: oracle/wcportal:12.2.1.4.0-210326.0857.320
    ```
If you want to build and use an Oracle WebCenter Portal Docker image with any additional bundle patch or interim patches that are not part of the image obtained from My Oracle Support, then follow these [steps]({{< relref "/wcportal-domains/create-or-update-image/">}}) to create the image.

>Note: The default Oracle WebCenter Portal image name used for Oracle WebCenter Portal domain deployment is `oracle/wcportal:12.2.1.4`. The image obtained must be tagged as `oracle/wcportal:12.2.1.4` using the `docker tag` command. If you want to use a different name for the image, make sure to update the new image tag name in the `create-domain-inputs.yaml` file and also in other instances where the `oracle/wcportal:12.2.1.4` image name is used.




### Pull Other Dependent Images

Dependent images include WebLogic Kubernetes Operator, database, and Traefik. Pull these images and add them to your local registry:

1. Pull these docker images and re-tag them as shown:

To pull an image from the Oracle Container Registry, in a web browser, navigate to ```https://container-registry.oracle.com``` and log in using the Oracle Single Sign-On authentication service. If you do not already have SSO credentials, at the top of the page, click the Sign In link to create them.

Use the web interface to accept the Oracle Standard Terms and Restrictions for the Oracle software images that you intend to deploy. Your acceptance of these terms are stored in a database that links the software images to your Oracle Single Sign-On login credentials.

Then, pull these docker images:

```bash
$ docker login https://container-registry.oracle.com (enter your Oracle email Id and password)
#This step is required once at every node to get access to the Oracle Container Registry.
```

WebLogic Kubernetes Operator image:
```bash
$ docker pull ghcr.io/oracle/weblogic-kubernetes-operator:3.1.1

```

2. Copy all the built and pulled images to all the nodes in your cluster or add to a Docker registry that your cluster can access.

NOTE: If you're not running Kubernetes on your development machine, you'll need to make the Docker image available to a registry visible to your Kubernetes cluster.
       Upload your image to a machine running Docker and Kubernetes as follows:
```bash
# on your build machine
$ docker save Image_Name:Tag > Image_Name-Tag.tar
$ scp Image_Name-Tag.tar YOUR_USER@YOUR_SERVER:/some/path/Image_Name-Tag.tar

# on the Kubernetes server
$ docker load < /some/path/Image_Name-Tag.tar
```

### Set Up the Code Repository to Deploy Oracle WebCenter Portal Domain

Oracle WebCenter Portal domain deployment on Kubernetes leverages the WebLogic Kubernetes Operator infrastructure. For deploying the Oracle WebCenter Portal domain, you need to set up the deployment scripts as below:

1. Create a working directory to set up the source code.
   ```bash
   $ export WORKDIR=$HOME/wcp_3.1.1
   $ mkdir <WORKDIR>
   $ cd <WORKDIR>
   ```

1. Download the supported version of WebLogic Kubernetes Operator source code archive file (`.zip`/`.tar.gz`) from the operator [relases page](https://github.com/oracle/weblogic-kubernetes-operator/releases). You can also download the supported operator version from [3.1.1](https://github.com/oracle/weblogic-kubernetes-operator/archive/v3.1.1.zip).
    ```bash
    $ git clone https://github.com/oracle/weblogic-kubernetes-operator.git --branch release/3.1.1
    ```

1. Download the WebCenter Portal Kubernetes deployment scripts from this [repository](https://github.com/oracle/fmw-kubernetes.git) and copy them in to WebLogic operator samples location.

   ```bash
   $ git clone https://github.com/oracle/fmw-kubernetes.git --branch release/21.2.3
   
   $ cp -rf ${WORKDIR}/fmw-kubernetes/OracleWebCenterPortal/kubernetes/create-wcp-domain  ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/
   $ cp -rf ${WORKDIR}/fmw-kubernetes/OracleWebCenterPortal/kubernetes/ingress-per-domain  ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/
   $ cp -rf ${WORKDIR}/fmw-kubernetes/OracleWebCenterPortal/kubernetes/create-wcp-es-cluster  ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/
   $ cp -rf ${WORKDIR}/fmw-kubernetes/OracleWebCenterPortal/kubernetes/imagetool-scripts  ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/ 
   $ cp -rf ${WORKDIR}/fmw-kubernetes/OracleWebCenterPortal/kubernetes/charts  ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/
   ```

You can now use the deployment scripts from `<$WORKDIR>/weblogic-kubernetes-operator` to set up the WebCenter Portal domain as described later in this document.

Your home directory for running all the required scripts:

```bash
$ cd <$WORKDIR>/weblogic-kubernetes-operator
```

### Grant Roles and Clear Stale Resources

1. To confirm if there is already a WebLogic custom resource definition, execute the following command:

    ```bash
    $ kubectl get crd
    NAME                      CREATED AT
    domains.weblogic.oracle   2020-03-14T12:10:21Z
    ```
1. Delete the WebLogic custom resource definition, if you find any, by executing the following command:
    ```bash
    $ kubectl delete crd domains.weblogic.oracle
    customresourcedefinition.apiextensions.k8s.io "domains.weblogic.oracle" deleted
    ```
    
### Install the WebLogic Kubernetes Operator

1. Create a namespace for the WebLogic Kubernetes Operator:

    ```bash
    $ kubectl create namespace operator-ns
    namespace/operator-ns created
    ```
    NOTE: In this procedure, the namespace is called “operator-ns”. You can use any name.
             
    You can use:
    * domainUID/domainname  as   `wcp-domain`
    * Domain namespace      as   `wcpns`
    * Operator namespace    as   `operator-ns`
    * traefik namespace     as   `traefik`
    
1. Create a service account for the WebLogic Kubernetes Operator in the operator's namespace:

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
    LAST DEPLOYED: Wed Jan  6 01:47:33 2021
    NAMESPACE: operator-ns
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
	```

1. To verify that the operator's pod is running, list the pods in the operator's namespace. You should see one for the WebLogic Kubernetes Operator:

    ```bash
    $ kubectl get pods -n operator-ns
    NAME                                 READY   STATUS    RESTARTS   AGE
	weblogic-operator-67df5fddc5-tlc4b   2/2     Running   0          3m15s
    ```

1. Then, check by viewing the Operator pod's log as shown in the following sample log snippet:

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
	{"timestamp":"03-14-2020T06:49:53.944+0000","thread":1,"fiber":"","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.Main","method":"main","timeInMillis":1584168593944,"message":"Oracle WebLogic Server Kubernetes Operator, version: 3.0.4, implementation: master.4d4fe0a, build time: 2019-11-15T21:19:56-0500","exception":"","code":"","headers":{},"body":""}
	{"timestamp":"03-14-2020T06:49:53.972+0000","thread":11,"fiber":"","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.Main","method":"begin","timeInMillis":1584168593972,"message":"Operator namespace is: operator-ns","exception":"","code":"","headers":{},"body":""}
	{"timestamp":"03-14-2020T06:49:54.009+0000","thread":11,"fiber":"","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.Main","method":"begin","timeInMillis":1584168594009,"message":"Operator target namespaces are: operator-ns","exception":"","code":"","headers":{},"body":""}
	{"timestamp":"03-14-2020T06:49:54.013+0000","thread":11,"fiber":"","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.Main","method":"begin","timeInMillis":1584168594013,"message":"Operator service account is: operator-sa","exception":"","code":"","headers":{},"body":""}	{"timestamp":"03-14-2020T06:49:54.031+0000","thread":11,"fiber":"","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.helpers.HealthCheckHelper","method":"performK8sVersionCheck","timeInMillis":1584168594031,"message":"Verifying Kubernetes minimum version","exception":"","code":"","headers":{},"body":""}	{"timestamp":"03-14-2020T06:49:54.286+0000","thread":11,"fiber":"","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.helpers.ClientPool","method":"getApiClient","timeInMillis":1584168594286,"message":"The Kuberenetes Master URL is set to https://10.96.0.1:443","exception":"","code":"","headers":{},"body":""}	{"timestamp":"03-14-2020T06:49:54.673+0000","thread":11,"fiber":"","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.helpers.HealthCheckHelper","method":"createAndValidateKubernetesVersion","timeInMillis":1584168594673,"message":"Kubernetes version is: v1.13.7","exception":"","code":"","headers":{},"body":""}	{"timestamp":"03-14-2020T06:49:55.259+0000","thread":12,"fiber":"engine-operator-thread-2-fiber-1","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.helpers.CrdHelper$CrdContext$CreateResponseStep","method":"onSuccess","timeInMillis":1584168595259,"message":"Create Custom Resource Definition: oracle.kubernetes.operator.calls.CallResponse@470b40c","exception":"","code":"","headers":{},"body":""}	{"timestamp":"03-14-2020T06:49:55.356+0000","thread":16,"fiber":"fiber-1-child-2","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.helpers.HealthCheckHelper","method":"performSecurityChecks","timeInMillis":1584168595356,"message":"Verifying that operator service account can access required operations on required resources in namespace operator-ns","exception":"","code":"","headers":{},"body":""}	{"timestamp":"03-14-2020T06:49:55.598+0000","thread":18,"fiber":"fiber-1-child-2","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.helpers.ConfigMapHelper$ScriptConfigMapContext$CreateResponseStep","method":"onSuccess","timeInMillis":1584168595598,"message":"Creating domain config map, operator-ns, for namespace: {1}.","exception":"","code":"","headers":{},"body":""}	{"timestamp":"03-14-2020T06:49:55.937+0000","thread":21,"fiber":"fiber-1","domainUID":"","level":"WARNING","class":"oracle.kubernetes.operator.utils.Certificates","method":"getCertificate","timeInMillis":1584168595937,"message":"Can't read certificate at /operator/external-identity/externalOperatorCert","exception":"\njava.nio.file.NoSuchFileException: /operator/external-identity/externalOperatorCert\n\tat java.base/sun.nio.fs.UnixException.translateToIOException(UnixException.java:92)\n\tat java.base/sun.nio.fs.UnixException.rethrowAsIOException(UnixException.java:111)\n\tat java.base/sun.nio.fs.UnixException.rethrowAsIOException(UnixException.java:116)\n\tat java.base/sun.nio.fs.UnixFileSystemProvider.newByteChannel(UnixFileSystemProvider.java:215)\n\tat java.base/java.nio.file.Files.newByteChannel(Files.java:370)\n\tat java.base/java.nio.file.Files.newByteChannel(Files.java:421)\n\tat java.base/java.nio.file.Files.readAllBytes(Files.java:3205)\n\tat oracle.kubernetes.operator.utils.Certificates.getCertificate(Certificates.java:48)\n\tat oracle.kubernetes.operator.utils.Certificates.getOperatorExternalCertificateData(Certificates.java:39)\n\tat oracle.kubernetes.operator.rest.RestConfigImpl.getOperatorExternalCertificateData(RestConfigImpl.java:52)\n\tat oracle.kubernetes.operator.rest.RestServer.isExternalSslConfigured(RestServer.java:383)\n\tat oracle.kubernetes.operator.rest.RestServer.start(RestServer.java:199)\n\tat oracle.kubernetes.operator.Main.startRestServer(Main.java:353)\n\tat oracle.kubernetes.operator.Main.completeBegin(Main.java:198)\n\tat oracle.kubernetes.operator.Main$NullCompletionCallback.onCompletion(Main.java:701)\n\tat oracle.kubernetes.operator.work.Fiber.completionCheck(Fiber.java:475)\n\tat oracle.kubernetes.operator.work.Fiber.run(Fiber.java:448)\n\tat oracle.kubernetes.operator.work.ThreadLocalContainerResolver.lambda$wrapExecutor$0(ThreadLocalContainerResolver.java:87)\n\tat java.base/java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:515)\n\tat java.base/java.util.concurrent.FutureTask.run(FutureTask.java:264)\n\tat java.base/java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.run(ScheduledThreadPoolExecutor.java:304)\n\tat java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1128)\n\tat java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:628)\n\tat java.base/java.lang.Thread.run(Thread.java:834)\n","code":"","headers":{},"body":""}
	{"timestamp":"03-14-2020T06:49:55.967+0000","thread":21,"fiber":"fiber-1","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.rest.RestServer","method":"start","timeInMillis":1584168595967,"message":"Did not start the external ssl REST server because external ssl has not been configured.","exception":"","code":"","headers":{},"body":""}
	{"timestamp":"03-14-2020T06:49:57.910+0000","thread":21,"fiber":"fiber-1","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.rest.RestServer","method":"start","timeInMillis":1584168597910,"message":"Started the internal ssl REST server on https://0.0.0.0:8082/operator","exception":"","code":"","headers":{},"body":""}	{"timestamp":"03-14-2020T06:49:57.913+0000","thread":21,"fiber":"fiber-1","domainUID":"","level":"INFO","class":"oracle.kubernetes.operator.Main","method":"markReadyAndStartLivenessThread","timeInMillis":1584168597913,"message":"Starting Operator Liveness Thread","exception":"","code":"","headers":{},"body":""}
  
    ```
   
### Prepare the Environment for the WebCenter Portal Domain

#### Create a namespace for an Oracle WebCenter Portal domain
   Unless you want to use the default namespace, create a Kubernetes namespace that can host one or more domains:
```bash
$ kubectl create namespace wcpns
    namespace/wcpns created
```  
    

 To manage domain in this namespace, configure the operator using helm:
        
   
>Helm upgrade weblogic-operator
```bash
    $ helm upgrade --reuse-values --set "domainNamespaces={wcpns}" \
    --wait weblogic-kubernetes-operator kubernetes/charts/weblogic-operator --namespace operator-ns

    NAME: weblogic-kubernetes-operator
    LAST DEPLOYED: Wed Jan  6 01:52:58 2021
    NAMESPACE: operator-ns
    STATUS: deployed
    REVISION: 2
```

#### Create a Kubernetes secret with domain credentials


   Using the create-weblogic-credentials script, create a Kubernetes secret that contains the user name and password for the domain in the same Kubernetes namespace as the domain:
    
```bash
$ sh kubernetes/samples/scripts/create-weblogic-domain-credentials/create-weblogic-credentials.sh \
    -u weblogic -p welcome1 -n wcpns \
    -d wcp-domain -s wcpinfra-domain-credentials
 
 secret/wcpinfra-domain-credentials created
 secret/wcpinfra-domain-credentials labeled
 The secret wcpinfra-domain-credentials has been successfully created in the wcpns namespace.
 ```
    Where:
    
       * weblogic                         is the weblogic username
       * welcome1                         is the weblogic password
       * wcp-domain                       is the domain name
       * wcpns                            is the domain namespace
       * wcpinfra-domain-credentials  is the secret name
    
    Note: You can inspect the credentials as follows:
 ```bash
   $ kubectl get secret wcpinfra-domain-credentials -o yaml -n wcpns
```
 #### Create a Kubernetes secret with the RCU credentials
 Create a Kubernetes secret for the Repository Configuration Utility (user name and password) using the `create-rcu-credentials.sh` script in the same Kubernetes namespace as the domain:

 ```bash
   $ sh kubernetes/samples/scripts/create-rcu-credentials/create-rcu-credentials.sh \
       -u WCP1 -p welcome1 -a sys -q Oradoc_db1 -n wcpns \
       -d wcp-domain -s wcpinfra-rcu-credentials
     
   secret/wcpinfra-rcu-credentials created
   secret/wcpinfra-rcu-credentials labeled
   The secret wcpinfra-rcu-credentials has been successfully created in the wcpns namespace.
 ```
    Where:
    
       * WCP1                             is the schema user
       * welcome1                         is the schema password
       * Oradoc_db1                       is the database SYS users password
       * wcp-domain                       is the domain name
       * wcpns                            is the domain namespace
       * wcpinfra-rcu-credentials         is the secret name
    
    Note: You can inspect the credentials as follows:

  ```bash
    $ kubectl get secret wcpinfra-rcu-credentials -o yaml -n wcpns
 ```

#### Create a persistent storage for an Oracle WebCenter Portal domain
 Create a Kubernetes PV and PVC (Persistent Volume and Persistent Volume Claim):

   In the Kubernetes namespace you created, create the PV and PVC for the domain by running the [create-pv-pvc.sh](https://oracle.github.io/weblogic-kubernetes-operator/samples/simple/storage/) script. Follow the instructions for using the script to create a dedicated PV and PVC for the Oracle WebCenter Portal domain.

  * Review the configuration parameters for PV creation [here](https://oracle.github.io/weblogic-kubernetes-operator/samples/simple/storage/#configuration-parameters). Based on your requirements, update the values in the `create-pv-pvc-inputs.yaml` file located at `${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-weblogic-domain-pv-pvc/`. Sample configuration parameter values for an Oracle WebCenter Portal domain are:
    * `baseName`: domain
    * `domainUID`: wcp-domain
    * `namespace`: wcpns
    * `weblogicDomainStorageType`: HOST_PATH
    * `weblogicDomainStoragePath`: /scratch/kubevolume

  * Ensure that the path for the `weblogicDomainStoragePath` property exists (create one if it doesn't exist), that it has full access permissions, and that the folder is empty.
  * Run the `create-pv-pvc.sh` script:
     ```bash
    $ cd ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-weblogic-domain-pv-pvc
    $ ./create-pv-pvc.sh -i create-pv-pvc-inputs.yaml -o output
      Input parameters being used
      export version="create-weblogic-sample-domain-pv-pvc-inputs-v1"
      export baseName="domain"
      export domainUID="wcp-domain"
      export namespace="wcpns"
      export weblogicDomainStorageType="HOST_PATH"
      export weblogicDomainStoragePath="/scratch/kubevolume"
      export weblogicDomainStorageReclaimPolicy="Retain"
      export weblogicDomainStorageSize="10Gi"
      
      Generating output/pv-pvcs/wcp-domain-domain-pv.yaml
      Generating output/pv-pvcs/wcp-domain-domain-pvc.yaml
      The following files were generated:
        output/pv-pvcs/wcp-domain-domain-pv.yaml
        output/pv-pvcs/wcp-domain-domain-pvc.yaml
    ```
  * The `create-pv-pvc.sh` script creates a subdirectory `pv-pvcs` under the given `/path/to/output-directory` directory and creates two YAML configuration files for PV and PVC. Apply these two YAML files to create the PV and PVC Kubernetes resources using the `kubectl create -f` command:
    ```bash
    $ kubectl create -f output/pv-pvcs/wcp-domain-domain-pv.yaml
    $ kubectl create -f output/pv-pvcs/wcp-domain-domain-pvc.yaml
    ```
#### Configure access to your database

Oracle WebCenter Portal domain requires a database which is configured with the necessary schemas. The Repository Creation Utility (RCU) allows you to create
those schemas. You must set up the database before you create your domain. 

For production deployments, you must set up and use a standalone (non-container) database running outside of Kubernetes.

Before creating a domain, you need to set up the necessary schemas in your database.
#### Run the Repository Creation Utility to set up your database schemas
   Run a container to create Repository Creation Utility.
    
 ```bash
    $ kubectl run rcu --generator=run-pod/v1 --image oracle/wcportal:12.2.1.4 -n wcpns  -- sleep infinity
    #check the status of rcu pod
    $ kubectl get pods -n wcpns
    #make sure rcu pod status is running before executing this
    $ kubectl exec -n wcpns -ti rcu /bin/bash
    export CONNECTION_STRING=databasehostname:<port>/<servicename>
    export RCUPREFIX=WCP1
    echo -e <Sys_User_Password>"\n"<Schema_User_Password> > /tmp/pwd.txt
    /u01/oracle/oracle_common/bin/rcu -silent -dropRepository -databaseType ORACLE -connectString $CONNECTION_STRING -dbUser sys -dbRole sysdba -selectDependentsForComponents true -schemaPrefix $RCUPREFIX -component OPSS -component IAU_VIEWER -component WEBCENTER -component MDS -component IAU_APPEND -component STB -component IAU -component WLS -component ACTIVITIES -f < /tmp/pwd.txt
    /u01/oracle/oracle_common/bin/rcu -silent -createRepository -databaseType ORACLE -connectString $CONNECTION_STRING -dbUser sys -dbRole sysdba -useSamePasswordForAllSchemaUsers true -selectDependentsForComponents true -schemaPrefix $RCUPREFIX -component OPSS -component IAU_VIEWER -component WEBCENTER -component MDS -component IAU_APPEND -component STB -component IAU -component WLS -component ACTIVITIES -tablespace USERS -tempTablespace TEMP -f < /tmp/pwd.txt
    #exit from the container
    exit
   ```