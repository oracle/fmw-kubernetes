+++
title = "a. Post Install Tasks"
description = "Perform post install tasks."
+++

Follow these post install configuration steps.


1. [Create a Server Overrides File](#create-a-server-overrides-file)
1. [Set OIMFrontendURL using MBeans](#set-oimfrontendurl-using-mbeans)

### Create a Server Overrides File

1. Navigate to the following directory:

   ```bash
   cd $WORKDIR/kubernetes/create-oim-domain/domain-home-on-pv/output/weblogic-domains/governancedomain
   ```
   
1. Create a `setUserOverrides.sh` with the following contents:

   ```
   DERBY_FLAG=false
   JAVA_OPTIONS="${JAVA_OPTIONS} -Djava.net.preferIPv4Stack=true"
   MEM_ARGS="-Xms8192m -Xmx8192m"
   ```
   
1. Copy the `setUserOverrides.sh` file to the Administration Server pod:

   ```bash
   $ chmod 755 setUserOverrides.sh
   $ kubectl cp setUserOverrides.sh oigns/governancedomain-adminserver:/u01/oracle/user_projects/domains/governancedomain/bin/setUserOverrides.sh
   ```
   
   Where `oigns` is the OIG namespace and `governancedomain` is the `domain_UID`.

1. Stop the OIG domain using the following command:
  
   ```bash
   $ kubectl -n <domain_namespace> patch domains <domain_uid> --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "NEVER" }]'
   ```
   
   For example:
   
   ```bash
   $ kubectl -n oigns patch domains governancedomain --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "NEVER" }]'
   ```
   
   The output will look similar to the following:
   
   ```
   domain.weblogic.oracle/governancedomain patched
   ```

1. Check that all the pods are stopped:

   ```bash
   $ kubectl get pods -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl get pods -n oigns
   ```
   
   The output will look similar to the following:

   ```
   NAME                                                 READY    STATUS        RESTARTS   AGE
   governancedomain-adminserver                         1/1     Terminating    0          18h
   governancedomain-create-fmw-infra-domain-job-8cww8   0/1     Completed      0          24h
   governancedomain-oim-server1                         1/1     Terminating    0          18h
   governancedomain-soa-server1                         1/1     Terminating    0          18h
   helper                                               1/1     Running        0          41h
   ```

   The Administration Server pods and Managed Server pods will move to a STATUS of `Terminating`. After a few minutes, run the command again and the pods should have disappeared:
   
   ```
   NAME                                                 READY   STATUS      RESTARTS   AGE
   governancedomain-create-fmw-infra-domain-job-8cww8   0/1     Completed   0          24h
   helper                                               1/1     Running     0          41h
   ```
   
1. Start the domain using the following command:

   ```bash
   $ kubectl -n <domain_namespace> patch domains <domain_uid> --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "IF_NEEDED" }]'
   ```
   
   For example:
   
   ```bash
   $ kubectl -n oigns patch domains governancedomain --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "IF_NEEDED" }]'
   ```
   
   Run the following kubectl command to view the pods:
   
   ```bash
   $ kubectl get pods -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl get pods -n oigns
   ```
   
   The output will look similar to the following:

   ```
   NAME                                                 READY   STATUS      RESTARTS   AGE
   governancedomain-create-fmw -infra-domain-job-vj69h  0/1     Completed   0          24h
   governancedomain-introspect-domain-job-7qx29         1/1     Running     0          8s
   helper                                               1/1     Running     0          41h
   ```
   
   The Administration Server pod will start followed by the OIG Managed Servers pods. This process will take several minutes, so keep executing the command until all the pods are running with `READY` status `1/1`:

   ```
   NAME                                                READY   STATUS      RESTARTS   AGE  
   governancedomain-adminserver                        1/1     Running     0          6m4s
   governancedomain-create-fmw-infra-domain-job-vj69h  0/1     Completed   0          24h
   governancedomain-oim-server1                        1/1     Running     0          3m5s
   governancedomain-soa-server1                        1/1     Running     0          3m5s
   helper                                              1/1     Running     0          41h
   ```

### Set OIMFrontendURL using MBeans

1. Login to Oracle Enterprise Manager using the following URL:

   `https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/em`

1. Click the Target Navigation icon in the top left of the screen and navigate to the following:

   * Expand *Identity and Access* > *Access* > *OIM* > *oim*
   * Right click the instance *oim* and select *System MBean Browser*
   * Under *Application Defined MBeans*, navigate to *oracle.iam*, *Server:oim_server1* > *Application:oim* > *XMLConfig*  > *Config* > *XMLConfig.DiscoveryConfig* > *Discovery*.

1. Enter a new value for the `OimFrontEndURL` attribute, in the format:

   * If using an External LoadBalancer for your ingress: `https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}`
   * If using NodePort for your ingress: `http://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}`
  

   Then click `Apply`.
   
   


