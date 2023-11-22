---
title: "a. Enterprise Deployment Guide"
description: "The Enterprise Deployment Guide shows how to deploy the entire Oracle Identity Management suite in a production environment"
---

### Enterprise Deployment Guide


The [Enterprise Deployment Guide for Oracle Identity and Access Management in a Kubernetes Cluster](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/index.html) is a step by step guide that describes how to deploy the entire Oracle Identity and Access Management Suite in a production environment. It incorporates best practices learned over many years to ensure that your Identity and Access Management deployment maintains the highest levels of Availability and Security.
 
It includes:
 
   * Preparing your On-premises Kubernetes, or Oracle Cloud Infrastructure Container Engine for Kubernetes (OCI OKE), for an Identity Management (IDM) Deployment. 
   * Deploying and configuring Oracle Unified Directory (OUD) seeding data needed by other IDM products.
   * Deploying and Configuring an Ingress Controller.
   * Deploying and Configuring the WebLogic Kubernetes Operator
   * Deploying and Configuring Oracle Access Management (OAM) and integrating with OUD.
   * Deploying and Configuring Oracle Identity Governance (OIG) and integrating with OUD and OAM.
   * Deploying and Configuring Oracle Identity Role Intelligence (OIRI) and integrating with OIG.
   * Deploying and configuring Oracle Advanced Authentication (OAA) and Oracle Adaptive Risk Management (OARM) and integrating with OAM.
   * Deploying and Configuring Monitoring and Centralised logging and configuring IDM to send monitoring and logging information to it.
 
Additionally, as per [Enterprise Deployment Automation](../enterprise-deployment-automation), all of the above can be automated using open source scripts.