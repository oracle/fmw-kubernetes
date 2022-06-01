---
title: "Runnning OIG utilities"
weight: 3
pre : "<b>3. </b>"
description: "Describes the steps for running OIG utilities in Kubernetes."
---

Run OIG utlities inside the OIG Kubernetes cluster.

### Run utilities in an interactive bash shell

1. Access a bash shell inside the `<domain_uid>-oim-server1` pod:

   ```bash
   $ kubectl -n oigns exec -it <domain_uid>-oim-server1 -- bash
   ```
   
   For example:
   
   ```bash
   $ kubectl -n oigns exec -it governancedomain-oim-server1 -- bash
   ```
   
   This will take you into a bash shell in the running `<domain_uid>-oim-server1` pod:
   
   ```bash
   [oracle@governancedomain-oim-server1 oracle]$
   ```
  
1. Navigate to the `/u01/oracle/idm/server/bin` directory and execute the utility as required. For example:

   ```bash
   [oracle@governancedomain-oim-server1 oracle] cd /u01/oracle/idm/server/bin
   [oracle@governancedomain-oim-server1 bin]$ ./<filename>.sh
   ```
   
   **Note**: Some utilties such as PurgeCache.sh, GenerateSnapshot.sh etc, may prompt to enter the t3 URL, for example:
   
   ```
   [oracle@governancedomain-oim-server1 bin]$ sh GenerateSnapshot.sh
   For running the Utilities the following environment variables need to be set
   APP_SERVER is weblogic
   OIM_ORACLE_HOME is /u01/oracle/idm/
   JAVA_HOME is /u01/jdk
   MW_HOME is /u01/oracle
   WL_HOME is /u01/oracle/wlserver
   DOMAIN_HOME is /u01/oracle/user_projects/domains/governancedomain
   Executing -Dweblogic.security.SSL.trustedCAKeyStore= in IPv4 mode
   [Enter Xellerate admin username :]xelsysadm
   [Enter password for xelsysadm :]
   [Threads to use [ 8 ]]
   [Enter serverURL :[t3://oimhostname:oimportno ]]
   ```
   
   To find the t3 URL run:
   
   ```
   $ kubectl get services -n oigns | grep oim-cluster
   ```
   
   The output will look similar to the following:
   
   ```
   governancedomain-cluster-oim-cluster   ClusterIP   10.110.161.82    <none>        14002/TCP,14000/TCP   4d
   ```
   
   In this case the t3 URL is: `t3://governancedomain-cluster-oim-cluster:14000`.

   

### Passing inputs as a jar/xml file

1. Copy the input file to pass to a directory of your choice.

1. Run the following command to copy the input file to the running `governancedomain-oim-server1` pod.

   ```bash
   $ kubectl -n oigns cp /<path>/<inputFile> governancedomain-oim-server1:/u01/oracle/idm/server/bin/
   ```
   
1. Access a bash shell inside the `governancedomain-oim-server1` pod:

   ```bash
   $ kubectl -n oigns exec -it governancedomain-oim-server1 -- bash
   ```
   
   This will take you into a bash shell in the running `governancedomain-oim-server1` pod:
   
   ```bash
   [oracle@governancedomain-oim-server1 oracle]$
   ```
  
1. Navigate to the `/u01/oracle/idm/server/bin` directory and execute the utility as required, passing the input file. For example:

   ```bash
   [oracle@governancedomain-oim-server1 oracle] cd /u01/oracle/idm/server/bin
   [oracle@governancedomain-oim-server1 bin]$ ./<filename>.sh -inputFile <inputFile>
   ```
   
   **Note** As pods are stateless the copied input file will remain until the pod restarts.


### Editing property/profile files

To edit a property/profile file in the Kubernetes cluster:

1. Copy the input file from the pod to a <path> on the local system, for example:

   ```bash
   $ kubectl -n oigns cp governancedomain-oim-server1:/u01/oracle/idm/server/bin/<file.properties_profile> /<path>/<file.properties_profile>
   ```
   
   **Note**: If you see the message `tar: Removing leading '/' from member names` this can be ignored.

   
1. Edit the `</path>/<file.properties_profile>` in an editor of your choice.

1. Copy the file back to the pod:

   ```bash
   $ kubectl -n oigns cp /<path>/<file.properties_profile> governancedomain-oim-server1:/u01/oracle/idm/server/bin/
   ```
   
   **Note**: As pods are stateless the copied input file will remain until the pod restarts. Preserve a local copy in case you need to copy files back after pod restart.
