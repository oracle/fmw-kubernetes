---
title: "e. Delete the OAM domain home"
description: "Learn about the steps to cleanup the OAM domain home."
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
   $ ./delete-weblogic-domain-resources.sh -d accessdomain
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
   -component WLS -component STB -component OAM -f < /tmp/pwd.txt
   ```
   
   For example:
   
   ```bash
   $ kubectl exec -it helper -n oamns -- /bin/bash
   [oracle@helper ~]$ export CONNECTION_STRING=mydatabasehost.example.com:1521/orcl.example.com
   [oracle@helper ~]$ export RCUPREFIX=OAMK8S
   /u01/oracle/oracle_common/bin/rcu -silent -dropRepository -databaseType ORACLE -connectString $CONNECTION_STRING \
   -dbUser sys -dbRole sysdba -selectDependentsForComponents true -schemaPrefix $RCUPREFIX \
   -component MDS -component IAU -component IAU_APPEND -component IAU_VIEWER -component OPSS \
   -component WLS -component STB -component OAM -f < /tmp/pwd.txt
   ```
  
1. Delete the contents of the persistent volume, for example:

   ```bash
   $ rm -rf <workdir>/accessdomainpv/*
   ```

   For example:
   
   ```bash
   $ rm -rf /scratch/OAMK8S/accessdomainpv/*
   ```

   
1. Delete the WebLogic Kubernetes Operator, by running the following command:

   ```bash
   $ helm delete weblogic-kubernetes-operator -n opns
   ```

1. Delete the label from the OAM namespace:

   ```bash
   $ kubectl label namespaces <domain_namespace> weblogic-operator-
   ```
   
   For example:
   
   ```bash
   $ kubectl label namespaces oamns weblogic-operator-
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
   $ helm delete oam-nginx -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ helm delete oam-nginx -n oamns
   ```
   
   Then run:
   
   ```bash
   $ helm delete nginx-ingress -n <domain_namespace>
   ```
    
   For example:
   
   ```bash
   $ helm delete nginx-ingress -n oamns
   ```
   
1. Delete the OAM namespace:

   ```bash
   $ kubectl delete namespace <domain_namespace>
   ```
   
   For example:
   ```bash
   $ kubectl delete namespace oamns
   ```
