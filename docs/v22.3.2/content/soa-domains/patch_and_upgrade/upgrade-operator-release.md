---
title: "Upgrade an operator release"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 2
pre: "<b>b. </b>"
description: "Upgrade the WebLogic Kubernetes Operator release to a newer version."
---

To upgrade the WebLogic Kubernetes operator, use the `helm upgrade` command with new Helm chart and operator image. See the steps [here]({{< relref "/soa-domains/installguide/prepare-your-environment/#get-dependent-images" >}}) to pull the operator image and set up the Oracle SOA Suite repository that contains the operator chart. To upgrade the operator run the following command:

```
$ cd ${WORKDIR}
$ helm upgrade \
  --reuse-values \
  --set image=oracle/weblogic-kubernetes-operator:3.4.2 \
  --namespace weblogic-operator-namespace \
  --wait \
  weblogic-kubernetes-operator \
  charts/weblogic-operator
```

> Note: When the WebLogic Kubernetes Operator is upgraded from release version 3.2.1 to 3.3.0 or later, it may be expected that the Administration Server pod in the domain gets restarted.

#### Post upgrade steps

From operator 3.1.1, the T3 channel Kubernetes service name extension is changed from `-external` to `-ext`. If the Administration Server was configured to expose a T3 channel in your domain, then follow these steps to recreate the Kubernetes service (for T3 channel) with the new name `-ext`.

> Note: If these steps are not performed, then the domain restart using `spec.serverStartPolicy`, would fail to bring up the servers.

1. Get the existing Kubernetes service name for T3 channel from the domain namespace. For example, if the `domainUID` is `soainfra`, and the Administration Server name is `adminserver`, then the service would be:

   ```
   soainfra-adminserver-external
   ```

1. Delete the existing Kubernetes service for T3 channel, so that operator 3.1.1 creates a new one:
   ```
   $ kubectl delete service <T3 channel service> --namespace <domain-namespace>
   ```
   For example, if the `domainUID` is `soainfra`, the Administration Server name is `adminserver` and domain namespace is `soans`, then the  command would be:
   ```
   $ kubectl delete service soainfra-adminserver-external --namespace soans
   ```
1. Then the operator automatically creates a new Kubernetes service with `-ext` instead of `-external`:
   ```
   soainfra-adminserver-ext
   ```
