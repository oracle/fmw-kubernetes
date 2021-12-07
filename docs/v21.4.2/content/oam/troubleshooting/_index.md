+++
title = "Troubleshooting"
weight = 12
pre = "<b>12. </b>"
description = "How to Troubleshoot domain creation failure."
+++

#### Domain creation failure

If the OAM domain creation fails when running `create-domain.sh`, run the following to diagnose the issue:

1. Run the following command to diagnose the create domain job:

   ```bash
   $ kubectl logs <domain_job> -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl logs accessdomain-create-fmw-infra-sample-domain-job-c6vfb -n oamns
   ```
   
   Also run:

   ```bash
   $ kubectl describe pod <domain_job> -n <domain_namespace>
   ```   

   For example:
   
   ```bash
   $ kubectl describe pod accessdomain-create-fmw-infra-sample-domain-job-c6vfb -n oamns
   ```
   
   Using the output you should be able to diagnose the problem and resolve the issue. 
   
   Clean down the failed domain creation by following steps 1-3 in [Delete the OAM domain home]({{< relref "/oam/manage-oam-domains/delete-domain-home" >}}). Then follow [RCU schema creation]({{< relref "/oam/prepare-your-environment/#rcu-schema-creation" >}}) onwards to recreate the RCU schema, kubernetes secrets for domain and RCU, the persistent volume and the persistent volume claim. Then execute the [OAM domain creation]({{< relref "/oam/create-oam-domains" >}}) steps again.
   
1. If any of the above commands return the following error:

   ```
   Failed to start container "create-fmw-infra-sample-domain-job": Error response from daemon: error while creating mount source path
   '/scratch/OAMK8S/accessdomainpv ': mkdir /scratch/OAMK8S/accessdomainpv : permission denied
   ```
    
   then there is a permissions error on the directory for the PV and PVC and the following should be checked:
   
   a) The directory has 777 permissions: `chmod -R 777 <workdir>/accessdomainpv`.
   
   b) If it does have the permissions, check if an `oracle` user exists and the `uid` and `gid` equal `1000`.
   
   Create the `oracle` user if it doesn't exist and set the `uid` and `gid` to `1000`.
   
   c) Edit the `$WORKDIR/kubernetes/create-weblogic-domain-pv-pvc/create-pv-pvc-inputs.yaml` and add a slash to the end of the directory for the `weblogicDomainStoragePath` parameter:
   
   ```
   weblogicDomainStoragePath: /scratch/OAMK8S/accessdomainpv/
   ```
   
   Clean down the failed domain creation by following steps 1-3 in [Delete the OAM domain home]({{< relref "/oam/manage-oam-domains/delete-domain-home" >}}). Then follow [RCU schema creation]({{< relref "/oam/prepare-your-environment/#rcu-schema-creation" >}}) onwards to recreate the RCU schema, kubernetes secrets for domain and RCU, the persistent volume and the persistent volume claim. Then execute the [OAM domain creation]({{< relref "/oam/create-oam-domains" >}}) steps again.
