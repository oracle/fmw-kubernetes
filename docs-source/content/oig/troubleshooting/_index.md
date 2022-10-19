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
   '/scratch/shared/governancedomainpv ': mkdir /scratch/shared/governancedomainpv : permission denied
   ```
    
   then there is a permissions error on the directory for the PV and PVC and the following should be checked:
   
   a) The directory has 777 permissions: `chmod -R 777 <persistent_volume>/governancedomainpv`.
   
   b) If it does have the permissions, check if an `oracle` user exists and the `uid` and `gid` equal `1000`, for example:
   
   ```bash
   $ uid=1000(oracle) gid=1000(spg) groups=1000(spg),59968(oinstall),8500(dba),100(users),1007(cgbudba)
   ```
   
   Create the `oracle` user if it doesn't exist and set the `uid` and `gid` to `1000`.
   
   c) Edit the `$WORKDIR/kubernetes/create-weblogic-domain-pv-pvc/create-pv-pvc-inputs.yaml` and add a slash to the end of the directory for the `weblogicDomainStoragePath` parameter:
   
   ```
   weblogicDomainStoragePath: /scratch/shared/governancedomainpv/
   ```
   
   Clean down the failed domain creation by following steps 1-3 in [Delete the OIG domain home]({{< relref "/oig/manage-oig-domains/delete-domain-home" >}}). Then follow [RCU schema creation]({{< relref "/oig/prepare-your-environment/#rcu-schema-creation" >}}) onwards to recreate the RCU schema, kubernetes secrets for domain and RCU, the persistent volume and the persistent volume claim. Then execute the [OIG domain creation]({{< relref "/oig/create-oig-domains" >}}) steps again.
   
   
   
### Patch domain failures

The instructions in this section relate to problems patching a deployment with a new image as per [Patch an image](../patch-and-upgrade/patch-an-image).

1. If the OIG domain patching fails when running `patch_oig_domain.sh`, run the following to diagnose the issue:

   ```
   $ kubectl describe domain <domain name> -n <domain_namespace>
   ```

   For example:

   ```
   $ kubectl describe domain governancedomain -n oigns
   ```

   Using the output you should be able to diagnose the problem and resolve the issue.

   If the domain is already patched successfully and the script failed at the last step of waiting for pods to come up with the new image, then you do not need to rerun the script again after issue resolution. The pods will come up automatically once you resolve the underlying issue.

1. If the script is stuck at the following message for a long time:

   ```
   "[INFO] Waiting for weblogic pods to be ready..This may take several minutes, do not close the window. Check log /scratch/OIGK8Slatest/fmw-kubernetes/OracleIdentityGovernance/kubernetes/domain-lifecycle/log/oim_patch_log-<DATE>/monitor_weblogic_pods.log for progress"
   ```
   
   run the following command to diagnose the issue:

   ```
   $ kubectl get pods -n <domain_namespace>
   ```
   
   For example:

   ```
   $ kubectl get pods -n oigns
   ```
   
   Run the following to check the logs of the AdminServer, SOA server or OIM server pods, as there may be an issue that is not allowing the domain pods to start properly:
   
   ```bash
   $ kubectl logs <pod> -n oigns
   ```
   
   If the above does not glean any information you can also run:
   
   ```
   $ kubectl describe pod <pod> -n oigns
   ```
   
   Further diagnostic logs can also be found under the `$WORKDIR/kubernetes/domain-lifecycle`.
   
   Once any issue is resolved the pods will come up automatically without the need to rerun the script.

    