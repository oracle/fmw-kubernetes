---
title: "Runnning OIG Utilities"
weight: 3
pre : "<b>3. </b>"
description: "Describes the steps for running OIG utilities in Kubernetes."
---

Run OIG utlities inside the OIG Kubernetes cluster.

### Run utilities in an interactive bash shell

1. Access a bash shell inside the `oimcluster-oim-server1` pod:

   ```bash
   $ kubectl -n oimcluster exec -it oimcluster-oim-server1 -- bash
   ```
   
   This will take you into a bash shell in the running oimcluster-oim-server1 pod:
   
   ```bash
   [oracle@oimcluster-oim-server1 oracle]$
   ```
  
1. Navigate to the `/u01/oracle/idm/server/bin` directory and execute the utility as required. For example:

   ```bash
   [oracle@oimcluster-oim-server1 oracle] cd /u01/oracle/idm/server/bin
   [oracle@oimcluster-oim-server1 bin]$ ./<filename>.sh
   ```

### Passing inputs as a jar/xml file

1. Copy the input file to pass to a directory of your choice.

1. Run the following command to copy the input file to the running `oimcluster-oim-server1` pod.

   ```bash
   $ kubectl -n oimcluster cp /<path>/<inputFile> oimcluster-oim-server1:/u01/oracle/idm/server/bin/
   ```
   
1. Access a bash shell inside the `oimcluster-oim-server1` pod:

   ```bash
   $ kubectl -n oimcluster exec -it oimcluster-oim-server1 -- bash
   ```
   
   This will take you into a bash shell in the running `oimcluster-oim-server1` pod:
   
   ```bash
   [oracle@oimcluster-oim-server1 oracle]$
   ```
  
1. Navigate to the `/u01/oracle/idm/server/bin` directory and execute the utility as required, passing the input file. For example:

   ```bash
   [oracle@oimcluster-oim-server1 oracle] cd /u01/oracle/idm/server/bin
   [oracle@oimcluster-oim-server1 bin]$ ./<filename>.sh -inputFile <inputFile>
   ```
   
   **Note** As pods are stateless the copied input file will remain until the pod restarts.


### Editing property/profile files

To edit a property/profile file in the Kubernetes cluster:

1. Copy the input file from the pod to a <path> on the local system, for example:

   ```bash
   $ kubectl -n oimcluster cp oimcluster-oim-server1:/u01/oracle/idm/server/bin/<file.properties_profile> /<path>/<file.properties_profile>
   ```
   
   **Note**: If you see the message `tar: Removing leading '/' from member names` this can be ignored.

   
1. Edit the `</path>/<file.properties_profile>` in an editor of your choice.

1. Copy the file back to the pod:

   ```bash
   $ kubectl -n oimcluster cp /<path>/<file.properties_profile> oimcluster-oim-server1:/u01/oracle/idm/server/bin/
   ```
   
   **Note**: As pods are stateless the copied input file will remain until the pod restarts. Preserve a local copy in case you need to copy files back after pod restart.
