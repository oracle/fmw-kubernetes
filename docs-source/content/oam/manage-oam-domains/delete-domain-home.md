---
title: "Delete the OAM domain home"
draft: false
weight: 5
pre : "<b>5. </b>"
description: "Learn about the steps to cleanup the OAM domain home."
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
   $ kubectl delete jobs accessdomain-create-oam-infra-domain-job -n oamns
   $ kubectl delete domain accessdomain -n oamns
   $ kubectl delete configmaps accessdomain-create-oam-infra-domain-job-cm -n oamns
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
   
  
1. Delete the Persistent Volume and Persistent Volume Claim:

   ```bash
   $ kubectl delete pv <pv-name>
   $ kubectl delete pvc <pvc-name> -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl delete pv accessdomain-domain-pv
   $ kubectl delete pvc accessdomain-domain-pvc -n oamns
   ```


1. Delete the contents of the persistent volume, for example:

   ```bash
   $ rm -rf <work directory>/accessdomainpv/*
   ```

   For example:
   
   ```bash
   $ rm -rf /scratch/OAMDockerK8S/accessdomainpv/*
   ```

   
5. Delete the Oracle WebLogic Server Kubernetes Operator, by running the following command:

   ```bash
   $ helm delete weblogic-kubernetes-operator -n opns
   ```
   
6. To delete NGINX:

    
   ```bash
   cd <work_directory>/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain
   $ kubectl delete -f ssl-nginx-ingress.yaml
   ```
   
   Then run:
   
   ```bash
   $ helm delete nginx-ingress -n <domain namespace>
   ```
    
   For example:
   
   ```bash
   $ helm delete nginx-ingress -n oamns
   ```
   

7. To delete Voyager:
    
   ```bash
   helm delete voyager-operator -n voyager
   ```
   then: 
   
   ```bash
   $ helm delete oam-voyager-ingress -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ helm delete oam-voyager-ingress -n oamns
   ```
   
   
