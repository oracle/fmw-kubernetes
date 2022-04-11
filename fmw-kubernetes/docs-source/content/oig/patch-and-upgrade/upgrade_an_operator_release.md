---
title: "b. Upgrade an operator release"
description: "Instructions on how to update the WebLogic Kubernetes Operator version."
---

These instructions apply to upgrading operators within the 3.x release family as additional versions are released.

{{% notice note %}}
The new WebLogic Kubernetes Operator Docker image must be installed on the master node AND each of the worker nodes in your Kubernetes cluster. Alternatively you can place the image in a Docker registry that your cluster can access.
{{% /notice %}}

1. Pull the WebLogic Kubernetes Operator 3.X.X image by running the following command on the master node:

   ```bash
   $ docker pull oracle/weblogic-kubernetes-operator:3.X.X
   ```
   
   where `3.X.X` is the version of the operator you require.
   
1. Run the `docker tag` command as follows:

   ```bash
   $ docker tag oracle/weblogic-kubernetes-operator:3.X.X weblogic-kubernetes-operator:3.X.X
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
   $ mkdir /scratch/OIGK8S/weblogic-kubernetes-operator-3.X.X
   $ cd /scratch/OIGK8S/weblogic-kubernetes-operator-3.X.X
   $ git clone https://github.com/oracle/weblogic-kubernetes-operator.git --branch v3.X.X  
   ```

   This will create the directory `<workdir>/weblogic-kubernetes-operator-3.X.X/weblogic-kubernetes-operator`
   
1. Run the following helm command to upgrade the operator:   
  
   ```bash
   $ cd <workdir>/weblogic-kubernetes-operator-3.X.X/weblogic-kubernetes-operator
   $ helm upgrade --reuse-values --set image=oracle/weblogic-kubernetes-operator:3.X.X --namespace <sample-kubernetes-operator-ns> --wait weblogic-kubernetes-operator kubernetes/charts/weblogic-operator
   ```
  
   For example:
  
   ```bash
   $ cd /scratch/OIGK8S/weblogic-kubernetes-operator-3.X.X/weblogic-kubernetes-operator
   $ helm upgrade --reuse-values --set image=oracle/weblogic-kubernetes-operator:3.X.X --namespace operator --wait weblogic-kubernetes-operator kubernetes/charts/weblogic-operator
   ```


   The output will look similar to the following:
   
   ```
   Release "weblogic-kubernetes-operator" has been upgraded. Happy Helming!
   NAME: weblogic-kubernetes-operator
   LAST DEPLOYED: Mon Nov 15 09:24:40 2021
   NAMESPACE: operator
   STATUS: deployed
   REVISION: 3
   TEST SUITE: None
   ```