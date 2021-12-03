+++
title = "Troubleshooting"
weight = 12
pre = "<b>12. </b>"
description = "Sample for creating an OIG domain home on an existing PV or PVC, and the domain resource YAML file for deploying the generated OIG domain."
+++

#### Domain creation failure

If the OIG domain creation fails when running `create-domain.sh`, run the following to diagnose the issue:

1. Run the following command to diagnose the create domain job:

   ```bash
   $ kubectl logs <job_name> -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl logs governancedomain-create-fmw-infra-sample-domain-job-9wqzb -n oigns
   ```
   
   Also run:

   ```bash
   $ kubectl describe pod <job_domain> -n <domain_namespace>
   ```   

   For example:
   
   ```bash
   $ kubectl describe pod governancedomain-create-fmw-infra-sample-domain-job-9wqzb -n oigns
   ```
   
   Using the output you should be able to diagnose the problem and resolve the issue. 
   
   Clean down the failed domain creation by following steps 1-3 in [Delete the OIG domain home]({{< relref "/oig/manage-oig-domains/delete-domain-home" >}}). Then follow [RCU schema creation]({{< relref "/oig/prepare-your-environment/#rcu-schema-creation" >}}) onwards to recreate the RCU schema, kubernetes secrets for domain and RCU, the persistent volume and the persistent volume claim. Then execute the [OIG domain creation]({{< relref "/oig/create-oig-domains" >}}) steps again.
   
2. If any of the above commands return the following error:

   ```
   Failed to start container "create-fmw-infra-sample-domain-job": Error response from daemon: error while creating mount source path
   '/scratch/OIGK8S/governancedomainpv ': mkdir /scratch/OIGK8S/governancedomainpv : permission denied
   ```
    
   then there is a permissions error on the directory for the PV and PVC and the following should be checked:
   
   a) The directory has 777 permissions: `chmod -R 777 <workdir>/governancedomainpv`.
   
   b) If it does have the permissions, check if an `oracle` user exists and the `uid` and `gid` equal `1000`, for example:
   
   ```bash
   $ uid=1000(oracle) gid=1000(spg) groups=1000(spg),59968(oinstall),8500(dba),100(users),1007(cgbudba)
   ```
   
   Create the `oracle` user if it doesn't exist and set the `uid` and `gid` to `1000`.
   
   c) Edit the `$WORKDIR/kubernetes/create-weblogic-domain-pv-pvc/create-pv-pvc-inputs.yaml` and add a slash to the end of the directory for the `weblogicDomainStoragePath` parameter:
   
   ```
   weblogicDomainStoragePath: /scratch/OIGK8S/governancedomainpv/
   ```
   
   Clean down the failed domain creation by following steps 1-3 in [Delete the OIG domain home]({{< relref "/oig/manage-oig-domains/delete-domain-home" >}}). Then follow [RCU schema creation]({{< relref "/oig/prepare-your-environment/#rcu-schema-creation" >}}) onwards to recreate the RCU schema, kubernetes secrets for domain and RCU, the persistent volume and the persistent volume claim. Then execute the [OIG domain creation]({{< relref "/oig/create-oig-domains" >}}) steps again.