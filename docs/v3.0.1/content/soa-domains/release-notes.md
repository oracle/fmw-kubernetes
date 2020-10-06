---
title: "Release Notes"
date: 2019-03-15T11:25:28-04:00
draft: false
weight: 1
pre: "<b>1. </b>"
---

Review the latest changes and known issues for Oracle SOA Suite on Kubernetes.

### Recent changes

| Date | Version | Introduces backward incompatibilities | Change |
| --- | --- | --- | --- |
| October 3, 2020 | 20.3.3 | no | Certified Oracle WebLogic Kubernetes operator version 3.0.1. Kubernetes 1.14.8+, 1.15.7+, 1.16.0+, 1.17.0+, and 1.18.0+ support. Flannel is the only supported CNI in this release. SSL enabling for the Administration Server and Managed Servers is supported. Only Oracle SOA Suite 12.2.1.4 is supported.


### Known issues

1. [Overriding tuning parameters is not supported using configuration overrides]({{< relref "/soa-domains/faq#overriding-tuning-parameters-is-not-supported-using-configuration-overrides" >}})
1. [Deployments in WebLogic administration console display unexpected error]({{< relref "/soa-domains/faq#deployments-in-the-weblogic-server-administration-console-may-display-unexpected-error" >}})
1. [Enterprise Manager console may display ADF_FACES-30200 error]({{< relref "/soa-domains/faq#enterprise-manager-console-may-display-adf_faces-30200-error" >}})
1. [Configure the external URL access for Oracle SOA Suite composite applications]({{< relref "/soa-domains/faq#configure-the-external-url-access-for-oracle-soa-suite-composite-applications" >}})
1. [Configure the external access for the Oracle Enterprise Scheduler WebServices WSDL URLs]({{< relref "/soa-domains/faq#configure-the-external-access-for-the-oracle-enterprise-scheduler-webservices-wsdl-urls" >}})
