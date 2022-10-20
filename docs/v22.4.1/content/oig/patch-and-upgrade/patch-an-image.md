---
title: "b. Patch an image"
description: "Instructions on how to update your OIG Kubernetes cluster with a new OIG container image."
---


### Introduction

The OIG domain patching script automatically performs the update of your OIG Kubernetes cluster with a new OIG container image. 

The script executes the following steps sequentially:

* Checks if the helper pod exists in the given namespace. If yes, then it deletes the helper pod.
* Brings up a new helper pod with the new image. 
* Stops the Administration Server, SOA and OIM managed servers using `serverStartPolicy` set as `NEVER` in the domain definition yaml.
* Waits for all servers to be stopped (default timeout 2000s)
* Introspects database properties including credentials from the job configmap.
* Performs database schema changes from the helper pod
* Starts the Administration Server, SOA and OIM managed servers by setting `serverStartPolicy` to IF_NEEDED and `image` to new image tag.
* Waits for all the servers to be ready (default timeout 2000s)
    
The script exits with a failure if a configurable timeout is reached before the target pod count is reached, depending upon the domain configuration. It also exits if there is any failure while patching the database schema and domain.

**Note**: The script execution will cause downtime while patching the OIG deployment and database schemas.

### Prerequisites

Before you begin, perform the following steps:

1. Review the [Domain resource](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/domain-resource) documentation.

1. Ensure that you have a running OIG deployment in your cluster.

1. Ensure that the database is up and running.


### Download the latest code repository

Download the latest code repository as follows:

1. Create a working directory to setup the source code.
   ```bash
   $ mkdir <workdir>
   ```
   
   For example:
   ```bash
   $ mkdir /scratch/OIGK8Slatest
   ```
   
1. Download the latest OIG deployment scripts from the OIG repository.

   ```bash
   $ cd <workdir>
   $ git clone https://github.com/oracle/fmw-kubernetes.git --branch release/22.4.1
   ```
   
   For example:
   
   ```bash
   $ cd /scratch/OIGK8Slatest
   $ git clone https://github.com/oracle/fmw-kubernetes.git --branch release/22.4.1
   ```

1. Set the `$WORKDIR` environment variable as follows:

   ```bash
   $ export WORKDIR=<workdir>/fmw-kubernetes/OracleIdentityGovernance
   ```

   For example:
   
   ```bash
   $ export WORKDIR=/scratch/OIGK8Slatest/fmw-kubernetes/OracleIdentityGovernance
   ```

### Run the patch domain script

1. Run the patch domain script as follows. Specify the inputs required by the script. If you need help understanding the inputs run the command help `-h`.
   
   ```bash
   $ cd $WORKDIR/kubernetes/domain-lifecycle
   $ ./patch_oig_domain.sh -h
   $ ./patch_oig_domain.sh -i <target_image_tag> -n <oig_namespace>
   ```
   
   For example:

   ```bash
   $ cd $WORKDIR/kubernetes/domain-lifecycle
   $ ./patch_oig_domain.sh -h
   $ ./patch_oig_domain.sh -i 12.2.1.4.0-8-ol7-<October`22> -n oigns
   ```

   The output will look similar to the following

   ```
   [INFO] Found domain name: governancedomain
   [INFO] Image Registry: container-registry.oracle.com/middleware/oig_cpu
   [INFO] Domain governancedomain is currently running with image: container-registry.oracle.com/middleware/oig_cpu:12.2.1.4-jdk8-ol7-<July`22>
   current no of pods under governancedomain are 3
   [INFO] The pod helper already exists in namespace oigns.
   [INFO] Deleting pod helper
   pod "helper" deleted
   [INFO] Fetched Image Pull Secret: orclcred
   [INFO] Creating new helper pod with image: container-registry.oracle.com/middleware/oig_cpu:12.2.1.4-jdk8-ol7-<October`22>
   pod/helper created
   Checking helper  Running
   [INFO] Stopping Admin, SOA and OIM servers in domain governancedomain. This may take some time, monitor log /scratch/OIGK8Slatest/fmw-kubernetes/OracleIdentityGovernance/kubernetes/domain-lifecycle/log/oim_patch_log-<DATE>/stop_servers.log for details
   [INFO] All servers are now stopped successfully. Proceeding with DB Schema changes
   [INFO] Patching OIM schemas...
   [INFO] DB schema update successful. Check log /scratch/OIGK8Slatest/fmw-kubernetes/OracleIdentityGovernance/kubernetes/domain-lifecycle/log/oim_patch_log-<DATE>/patch_oim_wls.log for details
   [INFO] Starting Admin, SOA and OIM servers with new image container-registry.oracle.com/middleware/oig_cpu:12.2.1.4-jdk8-ol7-<October`22>
   [INFO] Waiting for 3 weblogic pods to be ready..This may take several minutes, do not close the window. Check log /scratch/OIGK8Slatest/fmw-kubernetes/OracleIdentityGovernance/kubernetes/domain-lifecycle/log/oim_patch_log-<DATE>/monitor_weblogic_pods.log for progress
   [SUCCESS] All servers under governancedomain are now in ready state with new image: container-registry.oracle.com/middleware/oig_cpu:12.2.1.4-jdk8-ol7-<October`22>
   ```

   The logs are available at `$WORKDIR/kubernetes/domain-lifecycle` by default. A custom log location can also be provided to the script.

   **Note**: If the patch domain script creation fails, refer to the [Troubleshooting](../../troubleshooting/#patch-domain-failures) section.
