---
title: "b. Upgrade Elasticsearch and Kibana"
description: "Instructions on how to upgrade Elastic Search and Kibana."
---

This section shows how to upgrade Elasticsearch and Kibana.

To determine if this step is required for the version you are upgrading to, refer to the [Release Notes](../../release-notes).

### Download the latest code repository

Download the latest code repository as follows:

1. Create a working directory to setup the source code.
   ```bash
   $ mkdir <workdir>
   ```
   
   For example:
   ```bash
   $ mkdir /scratch/OUDSMK8Slatest
   ```
   
1. Download the latest OUDSM deployment scripts from the OUDSM repository.

   ```bash
   $ cd <workdir>
   $ git clone https://github.com/oracle/fmw-kubernetes.git
   ```
   
   For example:
   
   ```bash
   $ cd /scratch/OUDSMK8Slatest
   $ git clone https://github.com/oracle/fmw-kubernetes.git
   ```

1. Set the `$WORKDIR` environment variable as follows:

   ```bash
   $ export WORKDIR=<workdir>/fmw-kubernetes/OracleUnifiedDirectorySM
   ```

   For example:
   
   ```bash
   $ export WORKDIR=/scratch/OUDSMK8Slatest/fmw-kubernetes/OracleUnifiedDirectorySM
   ```

### Undeploy Elasticsearch and Kibana

From October 22 (22.4.1) onwards, OUDSM logs should be stored on a centralized Elasticsearch and Kibana (ELK) stack.

Deployments prior to October 22 (22.4.1) used local deployments of Elasticsearch and Kibana. 

If you are upgrading from July 22 (22.3.1) or earlier, to October 22 (22.4.1) or later, you must first undeploy Elasticsearch and Kibana using the steps below:

1. Navigate to the `$WORKDIR/kubernetes/helm` directory and create a `logging-override-values-uninstall.yaml` with the following:

   ```
   elk:
     enabled: false
   ```

1. Run the following command to remove the existing ELK deployment:

   ```
   $ helm upgrade --namespace <domain_namespace> --values <valuesfile.yaml> <releasename> oudsm --reuse-values
   ```
   
   For example:

   ```
   $ helm upgrade --namespace oudsmns --values logging-override-values-uninstall.yaml oudsm oudsm --reuse-values
   ```

### Deploy Elasticsearch and Kibana in centralized stack

1. Follow [Install Elasticsearch stack and Kibana](../../manage-oudsm-containers/logging-and-visualization/#install-elasticsearch-stack-and-kibana) to deploy Elasticsearch and Kibana in a centralized stack.
