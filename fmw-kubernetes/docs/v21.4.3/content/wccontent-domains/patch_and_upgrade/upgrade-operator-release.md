---
title: "Upgrade an WebLogic Kubernetes Operator release"
date: 2020-12-4T15:44:42-05:00
draft: false
weight: 2
pre: "<b>b. </b>"
description: "Upgrade the WebLogic Kubernetes Operator release to a newer version."
---

These instructions apply to upgrading WebLogic Kubernetes Operators within the 3.x release family
as additional versions are released.

To upgrade WebLogic Kubernetes Operator, use the `helm upgrade` command. Make sure that the weblogic-kubernetes-operator repository on your local machine is at the WebLogic Kubernetes Operator release to which you are upgrading. When upgrading the WebLogic Kubernetes Operator, the `helm upgrade` command requires that you supply a new Helm chart and image. For example:

```
$ helm upgrade \
  --reuse-values \
  --set image=oracle/weblogic-kubernetes-operator:3.2.5 \
  --namespace weblogic-operator-namespace \
  --wait \
  weblogic-kubernetes-operator \
  kubernetes/charts/weblogic-operator
```
