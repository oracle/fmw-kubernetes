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
  --set image=ghcr.io/oracle/weblogic-kubernetes-operator:4.0.4 \
  --namespace weblogic-operator-namespace \
  --wait \
  weblogic-kubernetes-operator \
  charts/weblogic-operator
```

> Note: When the WebLogic Kubernetes Operator is upgraded from release version 3.2.1 to 3.3.0 or later, it may be expected that the Administration Server pod in the domain gets restarted.

#### Post upgrade steps

When you upgrade a 3.x operator to 4.0, the upgrade process creates a WebLogic Domain resource conversion webhook deployment and its associated resources in the same namespace. If the conversion webhook deployment already exists in another namespace, then a new conversion webhook deployment is not created. The webhook automatically and transparently upgrades the existing WebLogic Domains from the 3.x schema to the 4.0 schema. For more information, see [WebLogic Domain resource conversion webhook](https://oracle.github.io/weblogic-kubernetes-operator/managing-operators/conversion-webhook/).

If you have a single WebLogic Kubernetes Operator per Kubernetes cluster (most common use case), you can upgrade directly from any 3.x operator release to 4.0.4. The Helm chart for 4.0.4 automatically installs the schema conversion webhook.

If there is more than one WebLogic Kubernetes Operator in a single Kubernetes cluster:

- You must upgrade every operator to at least version 3.4.1 before upgrading any operator to 4.0.0.
- As the 4.0.x Helm chart also installs a singleton schema conversion webhook that is shared by all 4.0.x operators in the cluster, use the webhookOnly Helm chart option to install this webhook in its own namespace prior to installing any of the 4.0.0 operators, and also use the preserveWebhook Helm chart option with each operator to prevent an operator uninstall from uninstalling the shared webhook.
- The operator provides a utility that can be used to convert existing “v8” Domain YAML files to “v9”.
- Several Helm chart default values have been changed. If you upgrade 3.x installations using the `--reuse-values` option during the Helm upgrade, the installations will continue to use the values from their original installation.

If you are still using an older operator version (from 3.1.1) the T3 channel Kubernetes service name extension is changed from `-external` to `-ext`. If the Administration Server was configured to expose a T3 channel in your domain, then follow these steps to recreate the Kubernetes service (for T3 channel) with the new name `-ext`.

> Note: If these steps are not performed, then the domain restart using `spec.serverStartPolicy` fails to bring up the servers.

1. Get the existing Kubernetes service name for the T3 channel from the domain namespace. For example, if the `domainUID` is `soainfra`, and the Administration Server name is `adminserver`, then the service is:

   ```
   soainfra-adminserver-external
   ```

1. Delete the existing Kubernetes service for T3 channel, so that operator 3.1.1 creates a new one:
   ```
   $ kubectl delete service <T3 channel service> --namespace <domain-namespace>
   ```
   For example, if the `domainUID` is `soainfra`, the Administration Server name is `adminserver` and domain namespace is `soans`, then the command is:
   ```
   $ kubectl delete service soainfra-adminserver-external --namespace soans
   ```
Now, the operator automatically creates a new Kubernetes service with `-ext` instead of `-external`:
   ```
   soainfra-adminserver-ext
   ```
