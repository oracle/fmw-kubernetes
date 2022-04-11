+++
title = "Troubleshooting"
weight = 9
pre = "<b>9. </b>"
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
   $ kubectl logs oimcluster-create-fmw-infra-sample-domain-job-9wqzb -n oimcluster
   ```
   
   Also run:

   ```bash
   $ kubectl describe pod <job_domain> -n <domain_namespace>
   ```   

   For example:
   
   ```bash
   $ kubectl describe pod oimcluster-create-fmw-infra-sample-domain-job-9wqzb -n oimcluster
   ```
   
   Using the output you should be able to diagnose the problem and resolve the issue. 
   
   Clean down the failed domain creation by following steps 1-4 in [Delete the OIG domain home]({{< relref "/oig/manage-oig-domains/delete-domain-home" >}}). Then 
   [recreate the PC and PVC]({{< relref "/oig/prepare-your-environment/#create-a-kubernetes-persistent-volume-and-persistent-volume-claim" >}}) then execute the [OIG domain creation]({{< relref "/oig/create-oig-domains" >}}) steps again.
   
2. If any of the above commands return the following error:

   ```bash
   Failed to start container "create-fmw-infra-sample-domain-job": Error response from daemon: error while creating mount source path
   '/scratch/OIGDockerK8S/oimclusterdomainpv ': mkdir /scratch/OIGDockerK8S/oimclusterdomainpv : permission denied
   ```
    
   then there is a permissions error on the directory for the PV and PVC and the following should be checked:
   
   a) The directory has 777 permissions: `chmod -R 777 <work directory>/oimclusterdomainpv`.
   
   b) If it does have the permissions, check if an `oracle` user exists and the `uid` and `gid` equal `1000`, for example:
   
   ```bash
   $ uid=1000(oracle) gid=1000(spg) groups=1000(spg),59968(oinstall),8500(dba),100(users),1007(cgbudba)
   ```
   
   Create the `oracle` user if it doesn't exist and set the `uid` and `gid` to `1000`.
   
   c) Edit the `<work directory>/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-oim-domain-pv-pvc/create-pv-pvc-inputs.yaml` and add a slash to the end of the directory for the `weblogicDomainStoragePath` parameter:
   
   ```bash
   weblogicDomainStoragePath: /scratch/OIGDockerK8S/oimclusterdomainpv/
   ```
   
   Clean down the failed domain creation by following steps 1-4 in [Delete the OIG domain home]({{< relref "/oig/manage-oig-domains/delete-domain-home" >}}). Then 
   [recreate the PC and PVC]({{< relref "/oig/prepare-your-environment/#create-a-kubernetes-persistent-volume-and-persistent-volume-claim" >}}) and then execute the [OIG domain creation]({{< relref "/oig/create-oig-domains" >}}) steps again.