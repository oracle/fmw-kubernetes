---
title: "Upgrade an operator release"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 2
pre: "<b>b. </b>"
description: "Upgrade the WebLogic Kubernetes Operator release to a newer version."
---

These instructions apply to upgrading operators within the 4.x release family
as additional versions are released.

To upgrade the Kubernetes operator, use the `helm upgrade` command. When upgrading the operator,
the `helm upgrade` command requires that you supply a new Helm chart and image. For example:

```
$ helm upgrade \
  --reuse-values \
  --set image=oracle/weblogic-kubernetes-operator:4.0.6 \
  --namespace weblogic-operator-namespace \
  --wait \
  weblogic-operator \
  kubernetes/charts/weblogic-operator
```
