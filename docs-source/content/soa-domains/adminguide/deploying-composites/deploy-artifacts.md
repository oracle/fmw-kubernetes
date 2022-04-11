---
title: "Deploy using composites in a persistent volume or image"
date: 2021-10-19T12:04:42-05:00
draft: false
weight: 3
pre : "<b>c. </b>"
description: "Deploy Oracle SOA Suite and Oracle Service Bus composite applications artifacts in a persistent volume or in an image."
---

Learn how to deploy Oracle SOA Suite and Oracle Service Bus composite applications artifacts in a Kubernetes persistent volume or in an image to an Oracle SOA Suite environment deployed using a WebLogic Kubernetes Operator.

The deployment methods described in [Deploy using JDeveloper]({{< relref "/soa-domains/adminguide/deploying-composites/supportjdev.md" >}}) and [Deploy using Maven and Ant]({{< relref "/soa-domains/adminguide/deploying-composites/deploy-using-maven-ant.md" >}}) are manual processes. If you have the deployment artifacts (archives) already built, then you can package them either into a Kubernetes persistent volume or in an image and use this automated process to deploy the artifacts to an Oracle SOA Suite domain.

#### Prepare to use the deploy artifacts script

The sample scripts for deploying artifacts are available at `${WORKDIR}/create-soa-domain/domain-home-on-pv/`

You must edit `deploy-artifacts-inputs.yaml` (or a copy of it) to provide the details of your domain and artifacts.
Refer to the configuration parameters below to understand the information that you must provide in this file.

#### Configuration parameters
The following parameters can be provided in the inputs file.

| Parameter | Definition | Default |
| --- | --- | --- |
| `adminPort` | Port number of the Administration Server inside the Kubernetes cluster. | `7001` |
| `adminServerName` | Name of the Administration Server. | `AdminServer` |
| `domainUID` | Unique ID that is used to identify the domain. This ID cannot contain any characters that are not valid in a Kubernetes service name. | `soainfra` |
| `domainType` | Type of the domain. Mandatory input for Oracle SOA Suite domains. You must provide one of the supported domain type values: `soa` (deploys artifacts into an Oracle SOA Suite domain), `osb` (deploys artifacts into an Oracle Service Bus domain), or `soaosb` (deploys artifacts into both Oracle SOA Suite and Oracle Service Bus domains). | `soa`
| `soaClusterName` | Name of the SOA WebLogic Server cluster instance in the domain. By default, the cluster name is `soa_cluster`. This configuration parameter is applicable only for `soa` and `soaosb` domain types.| `soa_cluster` |
| `image` | SOA Suite Docker image. The artifacts deployment process requires Oracle SOA Suite 12.2.1.4. Refer to [Obtain the Oracle SOA Suite Docker image]({{< relref "/soa-domains/installguide/prepare-your-environment#obtain-the-oracle-soa-suite-docker-image" >}}) for details on how to obtain or create the image. | `soasuite:12.2.1.4` |
| `imagePullPolicy` | Oracle SOA Suite Docker image pull policy. Valid values are `IfNotPresent`, `Always`, `Never`. | `IfNotPresent` |
| `imagePullSecretName` | Name of the Kubernetes secret to access the Docker Store to pull the Oracle SOA Suite Docker image. The presence of the secret will be validated when this parameter is specified. |  |
| `weblogicCredentialsSecretName` | Name of the Kubernetes secret for the Administration Server's user name and password. If not specified, then the value is derived from the `domainUID` as `<domainUID>-weblogic-credentials`. | `soainfra-domain-credentials` |
| `namespace` | Kubernetes namespace in which the domain was created. | `soans` |
| `artifactsSourceType` | The deploy artifacts source type. Set to `PersistentVolume` for deploy artifacts available in a persistent volume and `Image` for deploy artifacts available as an image. | `Image` |
| `persistentVolumeClaimName` | Name of the persistent volume claim created that hosts the deployment artifacts. If not specified, the value is derived from the `domainUID` as `<domainUID>-deploy-artifacts-pvc`. | `soainfra-deploy-artifacts-pvc` |
| `artifactsImage` | Deploy artifacts image. Required if `artifactsSourceType` is `Image`. | `artifacts:12.2.1.4` |
| `artifactsImagePullPolicy` | Deploy artifacts image pull policy. Valid values are `IfNotPresent`, `Always`, `Never`. | `IfNotPresent` |
| `artifactsImagePullSecretName` | Name of the Kubernetes secret to access the deploy artifacts image. The presence of the secret will be validated when this parameter is specified. |  |
| `deployScriptFilesDir` | Directory on the host machine to locate the required files to deploy artifacts to the Oracle SOA Suite domain, including the script that is specified in the `deployScriptName` parameter. By default, this directory is set to the relative path `deploy`. | `deploy` |
| `deployScriptsMountPath` | Mount path where the deploy artifacts scripts are located inside a pod. The `deploy-artifacts.sh` script creates a Kubernetes job to run the script (specified by the `deployScriptName` parameter) in a Kubernetes pod to deploy the artifacts. Files in the `deployScriptFilesDir` directory are mounted to this location in the pod, so that the Kubernetes pod can use the scripts and supporting files to deploy artifacts. | `/u01/weblogic` |
| `deployScriptName` | Script that the deploy artifacts script uses to deploy artifacts to the Oracle SOA Suite domain. For Oracle SOA Suite, the script placed in the `soa` directory is used. For Oracle Service Bus, the script placed in the `osb` directory is used. The `deploy-artifacts.sh` script creates a Kubernetes job to run this script to deploy artifacts. The script is located in the in-pod directory that is specified by the `deployScriptsMountPath` parameter.  | `deploy.sh` |
| `soaArtifactsArchivePath` | Directory inside container where Oracle SOA Suite archives are placed. | `/u01/sarchives` |
| `osbArtifactsArchivePath` | Directory inside container where Oracle Service Bus archives are placed. | `/u01/sbarchives` |


The sample demonstrates how to deploy Oracle SOA Suite composites or Oracle Service Bus applications to an Oracle SOA Suite domain home.

#### Run the deploy artifacts script

Run the deploy artifacts script, specifying your inputs file and an output directory to store the
generated artifacts:

```
$ ./deploy-artifacts.sh \
  -i deploy-artifacts-inputs.yaml \
  -o <path to output-directory>
```

The script performs the following steps:

* Creates a directory for the generated Kubernetes YAML files for the artifacts deployment process if it does not
  already exist. The path name is `<path to output-directory>/weblogic-domains/<domainUID>/<YYYYMMDD-hhmmss>`.
  If the directory already exists, its contents must be removed before running this script.
* Creates a Kubernetes job that starts a utility Oracle SOA Suite container and run
  scripts to deploy artifacts provided either in an image or in a persistent volume.

##### Deploy artifacts from an image

1. Create an image with artifacts

   a. A sample Dockerfile to create the artifacts in an image is available at `$WORKDIR/create-soa-domain/domain-home-on-pv/deploy-docker-file`. This expects the Oracle SOA Suite related archives to be available in the `soa` directory and Oracle Service Bus archives to be available in the `osb` directory.

   b. Create the `soa` directory and copy the Oracle SOA Suite archives to be deployed to the directory:
      ```
	  $ cd $WORKDIR/create-soa-domain/domain-home-on-pv/deploy-docker-file
	  $ mkdir soa
	  $ cp /path/sca_sampleBPEL.jar soa
      ```
   c. Create the `osb` directory and copy the Oracle Service Bus archives to be deployed to the directory:
      ```
	  $ cd $WORKDIR/create-soa-domain/domain-home-on-pv/deploy-docker-file
	  $ mkdir osb
	  $ cp /path/simple_sbconfig.jar osb
      ```
   d. Create the image using `build.sh`. This script creates the image with default tag 12.2.1.4 (`artifacts:12.2.1.4`):
      ```
      $ cd $WORKDIR/create-soa-domain/domain-home-on-pv/deploy-docker-file
	  $ ./build.sh  -h
        Usage: build.sh -t [tag]
        Builds a Docker Image with Oracle SOA/OSB artifacts
        Parameters:
           -h: view usage
           -t: tag for image, default is 12.2.1.4
      ```

	  {{%expand "Click here to see sample output of script with tag 12.2.1.4-v1" %}}
	  ```
	  $ ./build.sh -t 12.2.1.4-v1
		Sending build context to Docker daemon  36.35kB
		Step 1/13 : FROM busybox
		 ---> 16ea53ea7c65
		Step 2/13 : ARG SOA_ARTIFACTS_ARCHIVE_PATH=/u01/sarchives
		 ---> Using cache
		 ---> 411edf07f267
		Step 3/13 : ARG OSB_ARTIFACTS_ARCHIVE_PATH=/u01/sbarchives
		 ---> Using cache
		 ---> c4214b9cf0ae
		Step 4/13 : ARG USER=oracle
		 ---> Using cache
		 ---> c8ebcd5ee546
		Step 5/13 : ARG USERID=1000
		 ---> Using cache
		 ---> 5780beb0c3cf
		Step 6/13 : ARG GROUP=root
		 ---> Using cache
		 ---> 048e67c71f92
		Step 7/13 : ENV SOA_ARTIFACTS_ARCHIVE_PATH=${SOA_ARTIFACTS_ARCHIVE_PATH}
		 ---> Using cache
		 ---> 31ae33cfd9bb
		Step 8/13 : ENV OSB_ARTIFACTS_ARCHIVE_PATH=${OSB_ARTIFACTS_ARCHIVE_PATH}
		 ---> Using cache
		 ---> 79602bf64dc0
		Step 9/13 : RUN adduser -D -u ${USERID} -G $GROUP $USER
		 ---> Using cache
		 ---> 07c12cea52f9
		Step 10/13 : COPY soa/ ${SOA_ARTIFACTS_ARCHIVE_PATH}/
		 ---> bfeb138516d8
		Step 11/13 : COPY osb/ ${OSB_ARTIFACTS_ARCHIVE_PATH}/
		 ---> 0359a11f8f76
		Step 12/13 : RUN chown -R $USER:$GROUP ${SOA_ARTIFACTS_ARCHIVE_PATH}/ ${OSB_ARTIFACTS_ARCHIVE_PATH}/
		 ---> Running in 285fb2bd8434
		Removing intermediate container 285fb2bd8434
		 ---> 2e8d8c337de0
		Step 13/13 : USER $USER
		 ---> Running in c9db494e46ab
		Removing intermediate container c9db494e46ab
		 ---> 40295aa15317
		Successfully built 40295aa15317
		Successfully tagged artifacts:12.2.1.4-v1
		INFO: Artifacts image for Oracle SOA suite
			  is ready to be extended.
			  --> artifacts:12.2.1.4-v1
		INFO: Build completed in 4 seconds.
      ```
	  {{% /expand %}}

1. Update the image details in `deploy-artifacts-inputs.yaml` for parameter `artifactsImage` and invoke `deploy-artifacts.sh` to perform deployment of artifacts.

   {{%expand "Click here to see sample output of deployment for domainType of soaosb" %}}
   ```
   $ ./deploy-artifacts.sh -i deploy-artifacts-inputs.yaml -o out-deploy
	Input parameters being used
	export version="deploy-artifacts-inputs-v1"
	export adminPort="7001"
	export adminServerName="AdminServer"
	export domainUID="soainfra"
	export domainType="soaosb"
	export soaClusterName="soa_cluster"
	export soaManagedServerPort="8001"
	export image="soasuite:12.2.1.4"
	export imagePullPolicy="IfNotPresent"
	export weblogicCredentialsSecretName="soainfra-domain-credentials"
	export namespace="soans"
	export artifactsSourceType="Image"
	export artifactsImage="artifacts:12.2.1.4-v1"
	export artifactsImagePullPolicy="IfNotPresent"
	export deployScriptsMountPath="/u01/weblogic"
	export deployScriptName="deploy.sh"
	export deployScriptFilesDir="deploy"
	export soaArtifactsArchivePath="/u01/sarchives"
	export osbArtifactsArchivePath="/u01/sbarchives"

	Generating out-deploy/deploy-artifacts/soainfra/20211022-152335/deploy-artifacts-job.yaml
	Checking to see if the secret soainfra-domain-credentials exists in namespace soans
	configmap/soainfra-deploy-scripts-soa-job-cm created
	Checking the configmap soainfra-deploy-scripts-soa-job-cm was created
	configmap/soainfra-deploy-scripts-soa-job-cm labeled
	configmap/soainfra-deploy-scripts-osb-job-cm created
	Checking the configmap soainfra-deploy-scripts-osb-job-cm was created
	configmap/soainfra-deploy-scripts-osb-job-cm labeled
	Checking if object type job with name soainfra-deploy-artifacts-job-20211022-152335 exists
	Deploying artifacts by creating the job out-deploy/deploy-artifacts/soainfra/20211022-152335/deploy-artifacts-job.yaml
	job.batch/soainfra-deploy-artifacts-job-20211022-152335 created
	Waiting for the job to complete...
	status on iteration 1 of 20 for soainfra
	pod soainfra-deploy-artifacts-job-20211022-152335-r7ffj status is NotReady
	status on iteration 2 of 20 for soainfra
	pod soainfra-deploy-artifacts-job-20211022-152335-r7ffj status is Completed
	configmap "soainfra-deploy-scripts-soa-job-cm" deleted
	configmap "soainfra-deploy-scripts-osb-job-cm" deleted
	The following files were generated:
	  out-deploy/deploy-artifacts/soainfra/20211022-152335/deploy-artifacts-inputs.yaml
	  out-deploy/deploy-artifacts/soainfra/20211022-152335/deploy-artifacts-job.yaml


	Completed

   $ kubectl get all -n soans|grep deploy
   pod/soainfra-deploy-artifacts-job-20211022-152335-r7ffj   0/2     Completed   0          15m
   job.batch/soainfra-deploy-artifacts-job-20211022-152335   1/1           43s        15m
   $
   ```
   {{% /expand %}}

   > Note: When you are running the script for domainType `soaosb`, a deployment pod is created with two containers, one for Oracle SOA Suite artifacts deployments and another for Oracle Service Bus artifacts deployments. When the deployment completes for one container while other container is still running, the pod status will move from `Ready` to `NotReady`. Once both the deployments  complete successfully, the status of the pod moves to `Completed`.

##### Deploy artifacts from a persistent volume

1. Copy the artifacts for Oracle SOA Suite to the `soa` directory and Oracle Service Bus to the `osb` directory at the share location.
   For example, with location `/share`, artifacts for Oracle SOA Suite are in `/share/soa` and Oracle Service Bus are in `/share/osb`.
   ```
   $ ls /share/soa
   sca_sampleBPEL.jar
   $
   $ ls /share/osb/
   simple_sbconfig.jar
   $
   ```

1. Create a `PersistentVolume` with the sample provided (`artifacts-pv.yaml`):
      ```
      apiVersion: v1
      kind: PersistentVolume
      metadata:
        name: soainfra-deploy-artifacts-pv
      spec:
        storageClassName: deploy-storage-class
        capacity:
          storage: 10Gi
        accessModes:
          - ReadOnlyMany
        persistentVolumeReclaimPolicy: Retain
        hostPath:
          path: "/share"
      ```

      ```
	$ kubectl apply -f artifacts-pv.yaml
      ```

1. Create a `PersistentVolumeClaim` with the sample provided (`artifacts-pvc.yaml`):
    ```
	apiVersion: v1
	kind: PersistentVolumeClaim
	metadata:
	  name: soainfra-deploy-artifacts-pvc
	  namespace: soans
	spec:
	  storageClassName: deploy-storage-class
	  accessModes:
		- ReadOnlyMany
	  resources:
		requests:
		  storage: 10Gi
    ```

    ```
    $ kubectl apply -f artifacts-pvc.yaml
    ```

1. Update the `artifactsSourceType` to `PersistentVolume` and provide the name for `persistentVolumeClaimName` in `deploy-artifacts-inputs.yaml`.

1. Invoke `deploy-artifacts.sh` to deploy artifacts for artifacts present in `persistentVolumeClaimName`.

   {{%expand "Click here to see sample output of deployment for domainType of soaosb" %}}
   ```
   $ ./deploy-artifacts.sh -i deploy-artifacts-inputs.yaml -o out-deploy
	Input parameters being used
	export version="deploy-artifacts-inputs-v1"
	export adminPort="7001"
	export adminServerName="AdminServer"
	export domainUID="soainfra"
	export domainType="soaosb"
	export soaClusterName="soa_cluster"
	export soaManagedServerPort="8001"
	export image="soasuite:12.2.1.4"
	export imagePullPolicy="IfNotPresent"
	export weblogicCredentialsSecretName="soainfra-domain-credentials"
	export namespace="soans"
	export artifactsSourceType="PersistentVolume"
	export persistentVolumeClaimName="soainfra-deploy-artifacts-pvc"
	export deployScriptsMountPath="/u01/weblogic"
	export deployScriptName="deploy.sh"
	export deployScriptFilesDir="deploy"
	export soaArtifactsArchivePath="/u01/sarchives"
	export osbArtifactsArchivePath="/u01/sbarchives"

	Generating out-deploy/deploy-artifacts/soainfra/20211022-164735/deploy-artifacts-job.yaml
	Checking to see if the secret soainfra-domain-credentials exists in namespace soans
	configmap/soainfra-deploy-scripts-soa-job-cm created
	Checking the configmap soainfra-deploy-scripts-soa-job-cm was created
	configmap/soainfra-deploy-scripts-soa-job-cm labeled
	configmap/soainfra-deploy-scripts-osb-job-cm created
	Checking the configmap soainfra-deploy-scripts-osb-job-cm was created
	configmap/soainfra-deploy-scripts-osb-job-cm labeled
	Checking if object type job with name soainfra-deploy-artifacts-job-20211022-164735 exists
	Deploying artifacts by creating the job out-deploy/deploy-artifacts/soainfra/20211022-164735/deploy-artifacts-job.yaml
	job.batch/soainfra-deploy-artifacts-job-20211022-164735 created
	Waiting for the job to complete...
	status on iteration 1 of 20 for soainfra
	pod soainfra-deploy-artifacts-job-20211022-164735-66fvn status is NotReady
	status on iteration 2 of 20 for soainfra
	pod soainfra-deploy-artifacts-job-20211022-164735-66fvn status is Completed
	configmap "soainfra-deploy-scripts-soa-job-cm" deleted
	configmap "soainfra-deploy-scripts-osb-job-cm" deleted
	The following files were generated:
	  out-deploy/deploy-artifacts/soainfra/20211022-164735/deploy-artifacts-inputs.yaml
	  out-deploy/deploy-artifacts/soainfra/20211022-164735/deploy-artifacts-job.yaml


	Completed

   $ kubectl get all -n soans |grep deploy
   pod/soainfra-deploy-artifacts-job-20211022-164735-66fvn   0/2     Completed   0          3m1s
   job.batch/soainfra-deploy-artifacts-job-20211022-164735   1/1           37s        3m1s
   $
   ```
   {{% /expand %}}
   > Note: When you are running the script for domainType of `soaosb`, a deployment pod is created with two containers, one for Oracle SOA Suite artifacts deployments and one for Oracle Service Bus artifacts deployments. When the deployment completes for one container while other container is still running, the pod status moves from `Ready` to `NotReady`. Once both the deployments  successfully complete, the status of the pod moves to `Completed`.


#### Verify the deployment logs

To confirm the deployment of artifacts was successful, verify the output using the `kubectl logs` command:

> Note: Replace `<YYYYMMDD-hhmmss>`, `<domainUID>` and `<namespace>` with values for your environment.

For Oracle SOA Suite artifacts:

```
$ kubectl logs job.batch/<domainUID>-deploy-artifacts-job-<YYYYMMDD-hhmmss> -n <namespace>  soa-deploy-artifacts-job
```

For Oracle Service Bus artifacts:

```
$ kubectl logs job.batch/<domainUID>-deploy-artifacts-job-<YYYYMMDD-hhmmss> -n <namespace>  osb-deploy-artifacts-job
```
