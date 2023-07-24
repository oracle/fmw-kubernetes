---
title: "a. Upgrade an operator release"
description: "Instructions on how to update the WebLogic Kubernetes Operator version."
---


These instructions apply to upgrading operators from 3.X.X to 4.X, or from within the 4.x release family as additional versions are released.

1. On the master node, download the new WebLogic Kubernetes Operator source code from the operator github project:

   ```bash
   $ mkdir <workdir>/weblogic-kubernetes-operator-4.X.X
   $ cd <workdir>/weblogic-kubernetes-operator-4.X.X
   $ git clone https://github.com/oracle/weblogic-kubernetes-operator.git --branch v4.X.X 
   ```
   
   For example:

   ```bash
   $ mkdir /scratch/OIGK8S/weblogic-kubernetes-operator-4.X.X
   $ cd /scratch/OIGK8S/weblogic-kubernetes-operator-4.X.X
   $ git clone https://github.com/oracle/weblogic-kubernetes-operator.git --branch v4.X.X  
   ```

   This will create the directory `<workdir>/weblogic-kubernetes-operator-4.X.X/weblogic-kubernetes-operator`
   
1. Run the following helm command to upgrade the operator:   
  
   ```bash
   $ cd <workdir>/weblogic-kubernetes-operator-4.X.X/weblogic-kubernetes-operator
   $ helm upgrade --reuse-values --set image=ghcr.io/oracle/weblogic-kubernetes-operator:4.X.X --namespace <sample-kubernetes-operator-ns> --wait weblogic-kubernetes-operator kubernetes/charts/weblogic-operator
   ```
  
   For example:
  
   ```bash
   $ cd /scratch/OIGK8S/weblogic-kubernetes-operator-4.X.X/weblogic-kubernetes-operator
   $ helm upgrade --reuse-values --set image=ghcr.io/oracle/weblogic-kubernetes-operator:4.X.X --namespace operator --wait weblogic-kubernetes-operator kubernetes/charts/weblogic-operator
   ```


   The output will look similar to the following:
   
   ```
   Release "weblogic-kubernetes-operator" has been upgraded. Happy Helming!
   NAME: weblogic-kubernetes-operator
   LAST DEPLOYED: <DATE>
   NAMESPACE: operator
   STATUS: deployed
   REVISION: 2
   TEST SUITE: None
   ```
   
1. Verify that the operator's pod and services are running by executing the following command:

   ```bash
   $ kubectl get all -n <sample-kubernetes-operator-ns>
   ```

   For example:

   ```bash
   $ kubectl get all -n opns
   ```
	
   The output will look similar to the following:
   
   ```
   NAME                                             READY   STATUS    RESTARTS   AGE
   pod/weblogic-operator-b7d6df78c-mfrc4            1/1     Running   0          40s
   pod/weblogic-operator-webhook-7996b8b58b-frtwp   1/1     Running   0          42s

   NAME                                     TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)             AGE
   service/internal-weblogic-operator-svc   ClusterIP   10.107.3.1     <none>        8082/TCP,8083/TCP   6d
   service/weblogic-operator-webhook-svc    ClusterIP   10.106.51.57   <none>        8083/TCP,8084/TCP   42s

   NAME                                        READY   UP-TO-DATE   AVAILABLE   AGE
   deployment.apps/weblogic-operator           1/1     1            1           6d
   deployment.apps/weblogic-operator-webhook   1/1     1            1           42s

   NAME                                                   DESIRED   CURRENT   READY   AGE
   replicaset.apps/weblogic-operator-5884685f4f           0         0         0       6d
   replicaset.apps/weblogic-operator-b7d6df78c            1         1         1       40s
   replicaset.apps/weblogic-operator-webhook-7996b8b58b   1         1         1       42s
   ```
   
   **Note**: When you upgrade a 3.x WebLogic Kubernetes Operator to 4.x, the upgrade process creates a WebLogic Domain resource conversion webhook deployment, and associated resources in the same namespace. The webhook automatically and transparently upgrades the existing WebLogic Domains from the 3.x schema to the 4.x schema. For more information, see [Domain Upgrade](https://oracle.github.io/weblogic-kubernetes-operator/managing-operators/conversion-webhook/) in the WebLogic Kubernetes Operator documentation.
   
   **Note**: In WebLogic Kubernetes Operator 4.X, changes are made to `serverStartPolicy` that affect starting/stopping of the domain. Refer to the `serverStartPolicy` entry in the [create-domain-inputs.yaml](../../create-oig-domains/#prepare-the-create-domain-script) for more information. Also see [Domain Life Cycle](../../manage-oig-domains/domain-lifecycle).