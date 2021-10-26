---
title: "Delete the OIG domain home"
weight: 6
pre : "<b>6. </b>"
description: "Learn about the steps to cleanup the OIG domain home."
---

Sometimes in production, but most likely in testing environments, you might want to remove the domain home that is generated using the `create-domain.sh` script. 

1. Run the following command to delete the jobs, domain, and configmaps:

   ```bash
    $ kubectl delete jobs <domain_job> -n <domain_namespace>
	$ kubectl delete domain <domain_uid> -n <domain_namespace>
	$ kubectl delete configmaps <domain_job>-cm -n <domain_namespace>
   ```

   For example:

   ```bash
   $ kubectl delete jobs governancedomain-create-fmw-infra-sample-domain-job -n oigns
   $ kubectl delete domain governancedomain -n oigns
   $ kubectl delete configmaps governancedomain-create-fmw-infra-sample-domain-job-cm -n oigns
   ```

   
   
1. Drop the RCU schemas as follows:

   ```bash
   $ kubectl exec -it helper -n <domain_namespace> -- /bin/bash
   [oracle@helper ~]$
   [oracle@helper ~]$ export CONNECTION_STRING=<db_host.domain>:<db_port>/<service_name>
   [oracle@helper ~]$ export RCUPREFIX=<rcu_schema_prefix>
   
   /u01/oracle/oracle_common/bin/rcu -silent -dropRepository -databaseType ORACLE -connectString $CONNECTION_STRING \
   -dbUser sys -dbRole sysdba -selectDependentsForComponents true -schemaPrefix $RCUPREFIX \
   -component MDS -component IAU -component IAU_APPEND -component IAU_VIEWER -component OPSS \
   -component WLS -component STB -component OIM -component SOAINFRA -component UCSUMS -f < /tmp/pwd.txt
   ```
   
   For example:
   
   ```bash
   $ kubectl exec -it helper -n oigns -- /bin/bash
   [oracle@helper ~]$ export CONNECTION_STRING=mydatabasehost.example.com:1521/orcl.example.com
   [oracle@helper ~]$ export RCUPREFIX=OIGK8S
   /u01/oracle/oracle_common/bin/rcu -silent -dropRepository -databaseType ORACLE -connectString $CONNECTION_STRING \
   -dbUser sys -dbRole sysdba -selectDependentsForComponents true -schemaPrefix $RCUPREFIX \
   -component MDS -component IAU -component IAU_APPEND -component IAU_VIEWER -component OPSS \
   -component WLS -component STB -component OIM -component SOAINFRA -component UCSUMS -f < /tmp/pwd.txt
   ```   
   
1. Delete the Persistent Volume and Persistent Volume Claim:

   ```bash
   $ kubectl delete pv <pv-name> -n <domain_namespace>
   $ kubectl delete pvc <pvc-name> -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl delete pv governancedomain-domain-pv -n oigns
   $ kubectl delete pvc governancedomain-domain-pvc -n oigns
   ```
   
1. Delete the contents of the persistent volume, for example:

   ```bash
   $ rm -rf /<work directory>/governancedomainpv/*
   ```

   For example:
   
   ```bash
   $ rm -rf /scratch/OIGDockerK8S/governancedomainpv/*
   ```
   

   
5. Delete the WebLogic Kubernetes Operator, by running the following command:

   ```bash
   $ helm delete weblogic-kubernetes-operator -n opns
   ```
   
6. To delete NGINX:


   ```bash
   $ helm delete governancedomain-nginx -n oigns
   $ helm delete nginx-ingress -n nginx
   $ kubectl delete namespace nginx
   ```
   
   or if using SSL:
   
   ```bash
   $ helm delete governancedomain-nginx -n oigns
   $ helm delete nginx-ingress -n nginxssl
   $ kubectl delete namespace nginxssl
   ```

7. To delete Voyager:
    
   ```bash
   $ helm delete governancedomain-voyager -n oigns
   $ helm delete voyager-ingress -n voyager
   $ kubectl delete namespace voyager
   ```
   
   or if using SSL:
  
   ```bash
   $ helm delete governancedomain-voyager -n oigns
   $ helm delete voyager-ingress -n voyagerssl
   $ kubectl delete namespace voyagerssl
   ```