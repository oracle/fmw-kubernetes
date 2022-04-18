---
title: "Delete the OIG domain home"
weight: 6
pre : "<b>6. </b>"
description: "Learn about the steps to cleanup the OIG domain home."
---

Sometimes in production, but most likely in testing environments, you might want to remove the domain home that is generated using the `create-domain.sh` script. 

1. Run the following command to delete the domain:

   ```bash
   $ cd $WORKDIR/kubernetes/delete-domain
   $ ./delete-weblogic-domain-resources.sh -d <domain_uid>
   ```

   For example:

   ```bash
   $ cd $WORKDIR/kubernetes/delete-domain
   $ ./delete-weblogic-domain-resources.sh -d governancedomain
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
   

1. Delete the contents of the persistent volume:

   ```bash
   $ rm -rf <persistent_volume>/governancedomainpv/*
   ```

   For example:
   
   ```bash
   $ rm -rf /scratch/shared/governancedomainpv/*
   ```

   
1. Delete the WebLogic Kubernetes Operator, by running the following command:

   ```bash
   $ helm delete weblogic-kubernetes-operator -n opns
   ```

1. Delete the label from the OIG namespace:

   ```bash
   $ kubectl label namespaces <domain_namespace> weblogic-operator-
   ```
   
   For example:
   
   ```bash
   $ kubectl label namespaces oigns weblogic-operator-
   ```
   
1. Delete the service account for the operator:

   ```bash
   $ kubectl delete serviceaccount <sample-kubernetes-operator-sa> -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl delete serviceaccount op-sa -n opns
   ```

1. Delete the operator namespace:

   ```bash
   $ kubectl delete namespace <sample-kubernetes-operator-ns>
   ```
   
   For example:
   
   ```bash
   $ kubectl delete namespace opns
   ``` 
   
   
1. To delete NGINX:

   ```bash
   $ helm delete governancedomain-nginx-designconsole -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ helm delete governancedomain-nginx-designconsole -n oigns
   ```
   
   Then run:
	
   ```bash
   $ helm delete governancedomain-nginx -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ helm delete governancedomain-nginx -n oigns
   ```
   
   Then run:
   
   ```bash
   $ helm delete nginx-ingress -n <domain_namespace>
   ```
    
   For example:
   
   ```bash
   $ helm delete nginx-ingress -n nginxssl
   ```
   
   Then delete the NGINX namespace:
   
   ```bash
   $ kubectl delete namespace <namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl delete namespace nginxssl
   ```
   
   
1. Delete the OIG namespace:

   ```bash
   $ kubectl delete namespace <domain_namespace>
   ```
   
   For example:
   ```bash
   $ kubectl delete namespace oigns
   ```