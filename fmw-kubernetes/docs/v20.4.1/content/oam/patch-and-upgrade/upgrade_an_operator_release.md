---
title: "b. Upgrade an operator release"
description: "Instructions on how to update the Oracle WebLogic Server Kubernetes Operator version."
---

These instructions apply to upgrading the operator within the 3.x release family as additional versions are released.

{{% notice note %}}
The new Oracle WebLogic Server Kubernetes Operator Docker image must be installed on the master node AND each of the worker nodes in your Kubernetes cluster. Alternatively you can place the image in a Docker registry that your cluster can access.
{{% /notice %}}

1. Pull the Oracle WebLogic Server Kubernetes Operator 3.X.X image by running the following command on the master node:

   ```bash
   $ docker pull ghcr.io/oracle/weblogic-kubernetes-operator:3.X.X
   ```
   
   where `3.X.X` is the version of the operator you require.
   
1. Run the docker tag command as follows:

   ```bash
   $ docker tag ghcr.io/oracle/weblogic-kubernetes-operator:3.X.X weblogic-kubernetes-operator:3.X.X
   ```
   
   where `3.X.X` is the version of the operator downloaded.
   

   After installing the new Oracle WebLogic Server Kubernetes Operator Docker image, repeat the above on the worker nodes.
 
1. On the master node, download the new Oracle WebLogic Server Kubernetes Operator source code from the operator github project:

   ```bash
   $ mkdir <work directory>/weblogic-kubernetes-operator-3.X.X
   $ cd <work directory>/weblogic-kubernetes-operator-3.X.X
   $ git clone https://github.com/oracle/weblogic-kubernetes-operator.git --branch release/3.X.X 
   ```
   
   For example:

   ```bash
   $ cd /scratch/OAMDockerK8S/weblogic-kubernetes-operator-3.X.X
   $ git clone https://github.com/oracle/weblogic-kubernetes-operator.git --branch release/3.X.X 
   ```

   This will create the directory `<work directory>/weblogic-kubernetes-operator-3.X.X/weblogic-kubernetes-operator`
   
1. Run the following helm command to upgrade the operator:   
  
   ```bash
   $ cd <work directory>/weblogic-kubernetes-operator-3.X.X/weblogic-kubernetes-operator
   $ helm upgrade --reuse-values --set image=weblogic-kubernetes-operator:3.X.X --namespace <sample-kubernetes-operator-ns> --wait weblogic-kubernetes-operator kubernetes/charts/weblogic-operator
   ```
  
   For example:
  
   ```bash
   $ cd /scratch/OAMDockerK8S/weblogic-kubernetes-operator-3.X.X/weblogic-kubernetes-operator
   $ helm upgrade --reuse-values --set image=weblogic-kubernetes-operator:3.X.X --namespace opns --wait weblogic-kubernetes-operator kubernetes/charts/weblogic-operator
   ```


   The output will look similar to the following:
   
   ```bash
   Release "weblogic-kubernetes-operator" has been upgraded. Happy Helming!
   NAME: weblogic-kubernetes-operator
   LAST DEPLOYED: Mon Sep 28 02:50:07 2020
   NAMESPACE: opns
   STATUS: deployed
   REVISION: 3
   TEST SUITE: None
   ```
