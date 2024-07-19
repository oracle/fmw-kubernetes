+++
title = "Oracle Identity Management on Kubernetes"
date = 2019-04-18T06:46:23-05:00
description=  "This document lists all the Oracle Identity Management products deployment supported on Kubernetes."
+++

### Oracle Fusion Middleware on Kubernetes

Oracle supports the deployment of the following Oracle Identity Management products on Kubernetes. Click on the appropriate document link below to get started on configuring the product.

Please note the following:

+ The individual product guides below for [Oracle Access Management](../idm-products/oam), [Oracle Identity Governance](../idm-products/oig), [Oracle Unified Directory](../idm-products/oud), and [Oracle Unified Directory Services Manager](../idm-products/oudsm), are for configuring that product on a Kubernetes cluster where no other Oracle Identity Management products will be deployed. For example, if you are deploying Oracle Access Management (OAM) only, then you can follow the [Oracle Access Management](../idm-products/oam) guide. If you are deploying multiple Oracle Identity Management products on the same Kubernetes cluster, then you must follow the Enterprise Deployment Guide outlined in [Enterprise Deployments](../idm-products/enterprise-deployments). Please note, you also have the option to follow the Enterprise Deployment Guide even if you are only installing one product, such as OAM for example.

+ The individual product guides do not explain how to configure a Kubernetes cluster given the product can be deployed on any compliant Kubernetes vendor. If you need to understand how to configure a Kubernetes cluster ready for an Oracle Identity Management deployment, you should follow the Enterprise Deployment Guide in [Enterprise Deployments](../idm-products/enterprise-deployments).

+ The [Enterprise Deployment Automation](../idm-products/enterprise-deployments/enterprise-deployment-automation) section also contains details on automation scripts that can:

   + Automate the creation of a Kubernetes cluster on Oracle Cloud Infrastructure (OCI), ready for the deployment of Oracle Identity Management products.
   + Automate the deployment of Oracle Identity Management products on any compliant Kubernetes cluster.


  
 
{{% children style="h3" description="true" %}}

