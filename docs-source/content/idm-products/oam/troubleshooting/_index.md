+++
title = "Troubleshooting"
weight = 13
pre = "<b>13. </b>"
description = "How to Troubleshoot domain creation failure."
+++

#### Domain creation failure with WLST

The instructions in this section relate to problems creating OAM domains using WLST in [Create OAM domain using WLST](../create-oam-domains/create-oam-domains-using-wlst).

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
   
   Clean down the failed domain creation by following steps 1-3 in [Delete the OAM domain home](../manage-oam-domains/delete-domain-home). Then follow [RCU schema creation](../prepare-your-environment/#rcu-schema-creation) onwards to recreate the RCU schema, kubernetes secrets for domain and RCU, the persistent volume and the persistent volume claim. Then execute the [OAM domain creation](../create-oam-domains) steps again.
   
1. If any of the above commands return the following error:

   ```
   Failed to start container "create-fmw-infra-sample-domain-job": Error response from daemon: error while creating mount source path
   '/scratch/shared/accessdomainpv ': mkdir /scratch/shared/accessdomainpv : permission denied
   ```
    
   then there is a permissions error on the directory for the PV and PVC and the following should be checked:
   
   a) The directory has 777 permissions: `chmod -R 777 <persistent_volume>/accessdomainpv`.
   
   b) If it does have the permissions, check if an oracle user exists and the uid is 1000 and gid is 0.
   
   Create the oracle user if it doesn't exist and set the uid to 1000 and gid to 0.
   
   c) Edit the `$WORKDIR/kubernetes/create-weblogic-domain-pv-pvc/create-pv-pvc-inputs.yaml` and add a slash to the end of the directory for the `weblogicDomainStoragePath` parameter:
   
   ```
   weblogicDomainStoragePath: /scratch/shared/accessdomainpv/
   ```
   
   Clean down the failed domain creation by following steps 1-3 in [Delete the OAM domain home](../manage-oam-domains/delete-domain-home). Then follow [RCU schema creation](../prepare-your-environment/#rcu-schema-creation) onwards to recreate the RCU schema, kubernetes secrets for domain and RCU, the persistent volume and the persistent volume claim. Then execute the [OAM domain creation using WLST Offline Scripts](../create-oam-domains/create-oam-domains-using-wlst) steps again.

#### Domain creation failure with WDT Models

The instructions in this section relate to problems creating OAM domains using WDT models in [Create OAM domain using WDT Models](../create-oam-domains/create-oam-domains-using-wdt-models).

If the domain creation fails while creating domain resources using the `domain.yaml` file, run the following steps to diagnose the issue: 

1. Check the domain events, by running the following command:

   ```
   kubectl describe domain <domain name> -n <domain_namespace>
   ```
   
   For example:

   ```
   kubectl describe domain accessdomain -n oamns
   ```
   
   Using the output, you should be able to diagnose the problem and resolve the issue.

1. If the instrospector job fails due to validation errors, then you can recreate the domain resources using the commands:

   ```
   kubectl delete -f domain.yaml
   kubectl create -f domain.yaml
   ```
   
1. If the domain creation fails because of database issues, clean down the failed domain creation by following steps 1-3 in [Delete the OAM domain home](manage-oam-domains/delete-domain-home). Then follow [RCU schema creation](../prepare-your-environment/#rcu-schema-creation) recreate the RCU schema. Then execute the steps in [Create OAM domain using WDT Models](../create-oam-domains/create-oam-domains-using-wdt-models) again.

   **Note** You might need to recreate the domain creation image depending upon the errors. Domain creation logs are stored in `<persistent_volume>/domains/wdt-logs`.

1. If there is any issues bringing up the AdminServer, OAM Server or Policy Server pods, you can run the following to check the logs:

   ```
   $ kubectl logs -n oamns <POD_name> 
   ```

   If the above does not give any information you can also run:

   ```
   $ kubectl describe pod -n oamns
   ```
   
For more details related to debugging issues, refer to [Domain Debugging](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/debugging/).