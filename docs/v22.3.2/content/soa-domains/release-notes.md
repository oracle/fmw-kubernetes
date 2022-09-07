---
title: "Release Notes"
date: 2019-03-15T11:25:28-04:00
draft: false
weight: 1
pre: "<b>1. </b>"
---

Review the latest changes and known issues for Oracle SOA Suite on Kubernetes.

### Recent changes

| Date | Version | Change |
| --- | --- | --- |
|August 31, 2022 | 22.3.2 | Supports Oracle SOA Suite 12.2.1.4 domains deployment using July 2022 PSU and known bug fixes. [Enterprise Deployment Guide]({{< relref "/soa-domains/edg-guide" >}}) as preview release. Oracle SOA Suite 12.2.1.4 Docker image for this release can be downloaded from My Oracle Support (MOS patch [34410491](https://support.oracle.com/epmos/faces/ui/patch/PatchDetail.jspx?patchId=34410491)).
|May 31, 2022 | 22.2.2 | Supports Oracle SOA Suite 12.2.1.4 domains deployment using April 2022 PSU and known bug fixes. Oracle SOA Suite 12.2.1.4 Docker image for this release can be downloaded from My Oracle Support (MOS patch [34077593](https://support.oracle.com/epmos/faces/ui/patch/PatchDetail.jspx?patchId=34077593)).
|February 25, 2022 | 22.1.2 | Supports Oracle SOA Suite 12.2.1.4 domains deployment using January 2022 PSU and known bug fixes. Oracle SOA Suite 12.2.1.4 Docker image for this release can be downloaded from My Oracle Support (MOS patch [33749496](https://support.oracle.com/epmos/faces/ui/patch/PatchDetail.jspx?patchId=33749496)).
|November 30, 2021 | 21.4.2 | Supports Oracle SOA Suite 12.2.1.4 domains deployment using October 2021 PSU and known bug fixes. Oracle SOA Suite 12.2.1.4 Docker image for this release can be downloaded from My Oracle Support (MOS patch [33467899](https://support.oracle.com/epmos/faces/ui/patch/PatchDetail.jspx?patchId=33467899)).
|August 6, 2021 | 21.3.2 | Supports Oracle SOA Suite 12.2.1.4 domains deployment using July 2021 PSU and known bug fixes. Oracle SOA Suite 12.2.1.4 Docker image for this release can be downloaded from My Oracle Support (MOS patch [33125465](https://support.oracle.com/epmos/faces/ui/patch/PatchDetail.jspx?patchId=33125465)).
| May 31, 2021 | 21.2.2 | Supports Oracle SOA Suite 12.2.1.4 domains deployment using April 2021 PSU and known bug fixes. Oracle SOA Suite 12.2.1.4 Docker image for this release can be downloaded from My Oracle Support (MOS patch [32794257](https://support.oracle.com/epmos/faces/ui/patch/PatchDetail.jspx?patchId=32794257)).
| February 28, 2021 | 21.1.2 | Supports Oracle SOA Suite 12.2.1.4 domains deployment using January 2021 PSU and known bug fixes. Oracle SOA Suite 12.2.1.4 Docker image for this release can be downloaded from My Oracle Support (MOS patch [32398542](https://support.oracle.com/epmos/faces/ui/patch/PatchDetail.jspx?patchId=32398542)).
| November 30, 2020 | 20.4.2 | Supports Oracle SOA Suite 12.2.1.4 domains deployment using October 2020 PSU and known bug fixes. Added HEALTHCHECK support for Oracle SOA Suite docker image. Oracle SOA Suite 12.2.1.4 Docker image for this release can be downloaded from My Oracle Support (MOS patch [32215749](https://support.oracle.com/epmos/faces/ui/patch/PatchDetail.jspx?patchId=32215749)).
| October 3, 2020 | 20.3.3 | Certified Oracle WebLogic Kubernetes Operator version 3.0.1. Kubernetes 1.14.8+, 1.15.7+, 1.16.0+, 1.17.0+, and 1.18.0+ support. Flannel is the only supported CNI in this release. SSL enabling for the Administration Server and Managed Servers is supported. Only Oracle SOA Suite 12.2.1.4 is supported.


### Known issues

1. [Overriding tuning parameters is not supported using configuration overrides]({{< relref "/soa-domains/faq#overriding-tuning-parameters-is-not-supported-using-configuration-overrides" >}})
1. [Deployments in WebLogic administration console display unexpected error]({{< relref "/soa-domains/faq#deployments-in-the-weblogic-server-administration-console-may-display-unexpected-error" >}})
1. [Enterprise Manager console may display ADF_FACES-30200 error]({{< relref "/soa-domains/faq#enterprise-manager-console-may-display-adf_faces-30200-error" >}})
1. [Configure the external URL access for Oracle SOA Suite composite applications]({{< relref "/soa-domains/faq#configure-the-external-url-access-for-oracle-soa-suite-composite-applications" >}})
1. [Configure the external access for the Oracle Enterprise Scheduler WebServices WSDL URLs]({{< relref "/soa-domains/faq#configure-the-external-access-for-the-oracle-enterprise-scheduler-webservices-wsdl-urls" >}})
1. [Missing gif images in Oracle Service Bus console pipeline configuration page]({{<relref "/soa-domains/faq#missing-gif-images-in-oracle-service-bus-console-pipeline-configuration-page" >}})
