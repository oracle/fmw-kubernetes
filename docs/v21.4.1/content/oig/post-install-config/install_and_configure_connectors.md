+++
title = "b. Install and Configure Connectors"
description = "Install and Configure Connectors."
+++

### Download the Connector

1. Download the Connector you are interested in from [Oracle Identity Manager Connector Downloads](https://www.oracle.com/middleware/technologies/identity-management/oim-connectors-downloads.html).

1. Copy the connector zip file to a staging directory on the master node e.g. `/scratch/OIGDocker/stage` and unzip it:

   ```
   $ cp $HOME/Downloads/<connector>.zip <work directory>/<stage>/
   $ cd <work directory>/<stage>
   $ unzip <connector>.zip
   ```
   
   For example:
   
   ```
   $ cp $HOME/Downloads/Exchange-12.2.1.3.0.zip /scratch/OIGDocker/stage/
   $ cd /scratch/OIGDockerK8S/stage/
   $ unzip exchange-12.2.1.3.0.zip
   ```

   
### Create a directory in the persistent volume

1. On the master node run the following command to create a `ConnectorDefaultDirectory`:

   ```bash
   $ kubectl exec -ti governancedomain-oim-server1 -n <domain_namespace> -- mkdir -p /u01/oracle/user_projects/domains/ConnectorDefaultDirectory
   ```
   
   For example:
   
   ```bash
   $ kubectl exec -ti governancedomain-oim-server1 -n oigns -- mkdir -p /u01/oracle/user_projects/domains/ConnectorDefaultDirectory 
   ```
   
   **Note**: This will create a directory in the persistent volume e:g `/scratch/OIGDockerK8S/governancedomainpv/ConnectorDefaultDirectory`,
   
   
### Copy OIG Connectors

There are two options to copy OIG Connectors to your Kubernetes cluster:

   * a) Copy the connector directly to the Persistent Volume
   * b) Use the `kubectl cp` command to copy the connector to the Persistent Volume
 
It is recommended to use option a), however there may be cases, for example when using a Managed Service such as Oracle Kubernetes Engine on Oracle Cloud Infrastructure, where it may not be feasible to directly mount the domain directory. In such cases option b) should be used.


#### a) Copy the connector directly to the Persistent Volume

 
1. Copy the connector zip file to the persistent volume. For example:

   ```
   $ cp -R <path_to>/<connector> <work directory>/governancedomainpv/ConnectorDefaultDirectory/
   ```
   
   For example:
   
   ```
   $ cp -R /scratch/OIGDockerK8S/stage/Exchange-12.2.1.3.0 /scratch/OIGDockerK8S/governancedomainpv/ConnectorDefaultDirectory/
   ```
   

#### b) Use the `kubectl cp` command to copy the connector to the Persistent Volume
   
1. Run the following command to copy over the connector:

   ```
   $ kubectl -n <domain_namespace> cp <path_to>/<connector> <cluster_name>:/u01/oracle/idm/server/ConnectorDefaultDirectory/
   ```

   For example:

   ```
   $ kubectl -n oigns cp /scratch/OIGDockerK8S/stage/Exchange-12.2.1.3.0 governancedomain-oim-server1:/u01/oracle/idm/server/ConnectorDefaultDirectory/
   ```

### Install the Connector

The connectors are installed as they are on a standard on-premises setup, via Application On Boarding or via Connector Installer.

Refer to your Connector specific documentation for instructions.
