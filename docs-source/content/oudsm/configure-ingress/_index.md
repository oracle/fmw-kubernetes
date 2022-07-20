+++
title = "Configure an Ingress for OUDSM"
weight = 5 
pre = "<b>5. </b>"
description=  "This document provides steps to configure an ingress controller to direct traffic to OUDSM."

+++


1. [Introduction](#introduction)
1. [Install NGINX](#install-nginx)

    a. [Configure the repository](#configure-the-repository)
	
	b. [Create a namespace](#create-a-namespace)
	
	c. [Install NGINX using helm](#install-nginx-using-helm)
	
1. [Access to interfaces through ingress](#access-to-interfaces-through-ingress)


### Introduction

The instructions below explain how to set up NGINX as an ingress for OUDSM.

### Install NGINX 

Use Helm to install NGINX.

#### Configure the repository

1. Add the Helm chart repository for installing NGINX using the following command:

   ```bash
   $ helm repo add stable https://kubernetes.github.io/ingress-nginx
   ```
   
   The output will look similar to the following:

   ```
   "stable" has been added to your repositories
   ```
   
1. Update the repository using the following command:

   ```bash
   $ helm repo update
   ```
   
   The output will look similar to the following:
   
   ```
   Hang tight while we grab the latest from your chart repositories...
   ...Successfully got an update from the "stable" chart repository
   Update Complete. Happy Helming!
   ```
   

#### Create a namespace

1. Create a Kubernetes namespace for NGINX:

   ```bash
   $ kubectl create namespace <namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl create namespace mynginx
   ```
   
   The output will look similar to the following:
   
   ```
   namespace/mynginx created
   ```
   

#### Install NGINX using helm

1. Create a `$WORKDIR/kubernetes/helm/nginx-ingress-values-override.yaml` that contains the following:

   **Note**: The configuration below deploys an ingress using LoadBalancer. If you prefer to use NodePort, change the configuration accordingly. For more details about NGINX configuration see: [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/user-guide/exposing-tcp-udp-services/).

   ```yaml
   controller:
     admissionWebhooks:
       enabled: false
     extraArgs:
       # The secret referred to by this flag contains the default certificate to be used when accessing the catch-all server.
       # If this flag is not provided NGINX will use a self-signed certificate.
       # If the TLS Secret is in different namespace, name can be mentioned as <namespace>/<tlsSecretName>
       default-ssl-certificate: oudsmns/oudsm-tls-cert
     service:
       # controller service external IP addresses
       # externalIPs:
       #  - < External IP Address >
       # To configure Ingress Controller Service as LoadBalancer type of Service
       # Based on the Kubernetes configuration, External LoadBalancer would be linked to the Ingress Controller Service
       type: LoadBalancer
       # Configuration for NodePort to be used for Ports exposed through Ingress
       # If NodePorts are not defined/configured, Node Port would be assigned automatically by Kubernetes
       # These NodePorts are helpful while accessing services directly through Ingress and without having External Load Balancer.
       nodePorts:
         # For HTTP Interface exposed through LoadBalancer/Ingress
         http: 30080
         # For HTTPS Interface exposed through LoadBalancer/Ingress
         https: 30443
   ```

1. To install and configure NGINX ingress issue the following command:

   ```bash
   $ helm install --namespace <namespace> \
   --values nginx-ingress-values-override.yaml \
   lbr-nginx stable/ingress-nginx
   ```

   Where:
   * `lbr-nginx` is your deployment name
   * `stable/ingress-nginx` is the chart reference

   For example:
   
   ```bash
   $ helm install --namespace mynginx \
   --values nginx-ingress-values-override.yaml \
   lbr-nginx stable/ingress-nginx
   ```
   
   The output will be similar to the following:

   ```
   NAME: lbr-nginx
   LAST DEPLOYED: Mon Jul 11 17:07:32 2022
   NAMESPACE: mynginx
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   The ingress-nginx controller has been installed.
   It may take a few minutes for the LoadBalancer IP to be available.
   You can watch the status by running 'kubectl --namespace mynginx get services -o wide -w lbr-nginx-ingress-nginx-controller'
  
   An example Ingress that makes use of the controller:
     apiVersion: networking.k8s.io/v1
     kind: Ingress
     metadata:
       name: example
       namespace: foo
     spec:
       ingressClassName: nginx
       rules:
         - host: www.example.com
           http:
             paths:
               - pathType: Prefix
                 backend:
                   service:
                     name: exampleService
                     port:
                       number: 80
                 path: /
       # This section is only required if TLS is to be enabled for the Ingress
       tls:
         - hosts:
           - www.example.com
           secretName: example-tls

   If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

     apiVersion: v1
     kind: Secret
     metadata:
       name: example-tls
       namespace: foo
     data:
       tls.crt: <base64 encoded cert>
       tls.key: <base64 encoded key>
     type: kubernetes.io/tls
   ```
   
### Access to interfaces through ingress

Using the Helm chart, ingress objects are created according to configuration. The following table details the rules configured in ingress object(s) for access to Oracle Unified Directory Services Manager Interfaces through ingress.

| **Port** | **NodePort** | **Host** | **Example Hostname** | **Path** | **Backend Service:Port** | **Example Service Name:Port** | 
| ------ | ------ | ------ | ------ | ------ | ------ | ------ |  
| http/https | 30080/30443 | <deployment/release name>-N | oudsm-N | * | <deployment/release name>-N:http | oudsm-1:http | 
| http/https | 30080/30443 | * | * | /oudsm<br> /console| <deployment/release name>-lbr:http | oudsm-lbr:http | 

* In the table above, the Example Name for each Object is based on the value 'oudsm' as the deployment/release name for the Helm chart installation.
* The NodePorts mentioned in the table are according to ingress configuration described in previous section.
* When an External LoadBalancer is not available/configured, interfaces can be accessed through NodePort on the Kubernetes node.

#### Changes in /etc/hosts to validate hostname based ingress rules

If it is not possible to have LoadBalancer configuration updated to have host names added for Oracle Unified Directory Services Manager Interfaces, then the following entries can be added in /etc/hosts files on the host from where Oracle Unified Directory Services Manager interfaces would be accessed. 

```
<IP Address of External LBR or Kubernetes Node>	oudsm oudsm-1 oudsm-2 oudsm-N
```

* In the table above, host names are based on the value 'oudsm' as the deployment/release name for the Helm chart installation.
* When an External LoadBalancer is not available/configured, Interfaces can be accessed through NodePort on the Kubernetes Node.

### Validate OUDSM URL's

1. Launch a browser and access the OUDSM console. 

* If using an External LoadBalancer: `https://<External LBR Host>/oudsm`. 
* If not using an External LoadBalancer use `https://<Kubernetes Node>:30443/oudsm`. 

1. Access the WebLogic Administration console by accessing the following URL and login with `weblogic/<password>` where `weblogic/<password>` is the `adminUser` and `adminPass` set when creating the OUDSM instance.

* If using an External LoadBalancer: `https://<External LBR Host>/console`. 
* If not using an External LoadBalancer use `https://<Kubernetes Node>:30443/console`. 


