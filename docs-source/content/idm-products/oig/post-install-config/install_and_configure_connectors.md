+++
title = "b. Install and configure connectors"
description = "Install and Configure Connectors."
+++

### Download the connector

1. Download the Connector you are interested in from [Oracle Identity Manager Connector Downloads](https://www.oracle.com/middleware/technologies/identity-management/oim-connectors-downloads.html).

1. Copy the connector zip file to a staging directory on the master node e.g. `<workdir>/stage` and unzip it:

   ```bash
   $ cp $HOME/Downloads/<connector>.zip <workdir>/<stage>/
   $ cd <workdir>/<stage>
   $ unzip <connector>.zip
   $ chmod -R 755 *
   ```
   
   For example:
   
   ```bash
   $ cp $HOME/Downloads/Exchange-12.2.1.3.0.zip /scratch/OIGK8S/stage/
   $ cd /scratch/OIGK8S/stage/
   $ unzip exchange-12.2.1.3.0.zip
   $ chmod -R 755 *
   ```
    
   
### Copy OIG connectors

There are two options to copy OIG Connectors to your Kubernetes cluster:

   * a) Copy the connector directly to the Persistent Volume
   * b) Use the `kubectl cp` command to copy the connector to the Persistent Volume
 
It is recommended to use option a), however there may be cases, for example when using a Managed Service such as Oracle Kubernetes Engine on Oracle Cloud Infrastructure, where it may not be feasible to directly mount the domain directory. In such cases option b) should be used.


#### a) Copy the connector directly to the persistent volume

 
1. Copy the connector zip file to the persistent volume. For example:

   ```bash
   $ cp -R <path_to>/<connector> <persistent_volume>/governancedomainpv/ConnectorDefaultDirectory/
   ```
   
   For example:
   
   ```bash
   $ cp -R /scratch/OIGK8S/stage/Exchange-12.2.1.3.0 /scratch/shared/governancedomainpv/ConnectorDefaultDirectory/
   ```
   

#### b) Use the `kubectl cp` command to copy the connector to the persistent volume
   
1. Run the following command to copy over the connector:

   ```bash
   $ kubectl -n <domain_namespace> cp <path_to>/<connector> <cluster_name>:/u01/oracle/idm/server/ConnectorDefaultDirectory/
   ```

   For example:

   ```bash
   $ kubectl -n oigns cp /scratch/OIGK8S/stage/Exchange-12.2.1.3.0 governancedomain-oim-server1:/u01/oracle/idm/server/ConnectorDefaultDirectory/
   ```

### Install the connector

The connectors are installed as they are on a standard on-premises setup, via Application On Boarding or via Connector Installer.

Refer to your Connector specific documentation for instructions.
