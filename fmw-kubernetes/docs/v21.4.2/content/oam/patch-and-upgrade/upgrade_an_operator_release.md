---
title: "b. Upgrade an operator release"
description: "Instructions on how to update the WebLogic Kubernetes Operator version."
---

These instructions apply to upgrading the operator within the 3.x release family as additional versions are released.

{{% notice note %}}
The new WebLogic Kubernetes Operator Docker image must be installed on the master node and each of the worker nodes in your Kubernetes cluster. Alternatively you can place the image in a Docker registry that your cluster can access.
{{% /notice %}}

1. Pull the WebLogic Kubernetes Operator 3.X.X image by running the following command on the master node:

   ```bash
   $ docker pull ghcr.io/oracle/weblogic-kubernetes-operator:3.X.X
   ```
   
   where `3.X.X` is the version of the operator you require.
   
1. Run the docker tag command as follows:

   ```bash
   $ docker tag ghcr.io/oracle/weblogic-kubernetes-operator:3.X.X weblogic-kubernetes-operator:3.X.X
   ```
   
   where `3.X.X` is the version of the operator downloaded.
   

   After installing the new WebLogic Kubernetes Operator Docker image, repeat the above on the worker nodes.
 
1. On the master node, download the new WebLogic Kubernetes Operator source code from the operator github project:

   ```bash
   $ mkdir <workdir>/weblogic-kubernetes-operator-3.X.X
   $ cd <workdir>/weblogic-kubernetes-operator-3.X.X
   $ git clone https://github.com/oracle/weblogic-kubernetes-operator.git --branch v3.X.X 
   ```
   
   For example:

   ```bash
   $ mkdir /scratch/OAMK8S/weblogic-kubernetes-operator-3.X.X
   $ cd /scratch/OAMK8S/weblogic-kubernetes-operator-3.X.X
   $ git clone https://github.com/oracle/weblogic-kubernetes-operator.git --branch v3.X.X 
   ```

   This will create the directory `<workdir>/weblogic-kubernetes-operator-3.X.X/weblogic-kubernetes-operator`
   
1. Run the following helm command to upgrade the operator:   
  
   ```bash
   $ cd <workdir>/weblogic-kubernetes-operator-3.X.X/weblogic-kubernetes-operator
   $ helm upgrade --reuse-values --set image=weblogic-kubernetes-operator:3.X.X --namespace <sample-kubernetes-operator-ns> --wait weblogic-kubernetes-operator kubernetes/charts/weblogic-operator
   ```
  
   For example:
  
   ```bash
   $ cd /scratch/OAMK8S/weblogic-kubernetes-operator-3.X.X/weblogic-kubernetes-operator
   $ helm upgrade --reuse-values --set image=weblogic-kubernetes-operator:3.X.X --namespace opns --wait weblogic-kubernetes-operator kubernetes/charts/weblogic-operator
   ```


   The output will look similar to the following:
   
   ```
   Release "weblogic-kubernetes-operator" has been upgraded. Happy Helming!
   NAME: weblogic-kubernetes-operator
   LAST DEPLOYED: Wed Nov  3 04:36:10 2021
   NAMESPACE: opns
   STATUS: deployed
   REVISION: 3
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
   NAME                                     READY   STATUS    RESTARTS   AGE
   pod/weblogic-operator-69546866bd-h58sk   2/2     Running   0          112s

   NAME                                     TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
   service/internal-weblogic-operator-svc   ClusterIP   10.106.72.42   <none>        8082/TCP   2d

   NAME                                READY   UP-TO-DATE   AVAILABLE   AGE
   deployment.apps/weblogic-operator   1/1     1            1           2d

   NAME                                           DESIRED   CURRENT   READY   AGE
   replicaset.apps/weblogic-operator-676d5cc6f4   0         0         0       2d
   replicaset.apps/weblogic-operator-69546866bd   1         1         1       112s
   ```