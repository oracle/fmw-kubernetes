+++
title = "Configure an Ingress for OID"
weight = 5 
pre = "<b>5. </b>"
description=  "This document provides steps to configure an ingress controller to direct traffic to OID."
+++

1. [Introduction](#introduction)
1. [Install NGINX](#install-nginx)

    a. [Configure the repository](#configure-the-repository)
	
	b. [Create a namespace](#create-a-namespace)
	
	c. [Install NGINX using helm](#install-nginx-using-helm)
	
1. [Access to interfaces through ingress](#access-to-interfaces-through-ingress)

    a. [Using LDAP utilities](#using-ldap-utilities)
	
	b. [Validate access using LDAP utilities](#validate-access-using-ldap-utilities)
	
	c. [Validate OID using Oracle Directory Services Manager](#validate-oid-using-oracle-directory-services-manager)


### Introduction

The instructions below explain how to set up NGINX as an ingress for OID.

By default the ingress configuration only supports HTTP and HTTPS ports. To allow LDAP and LDAPS communication over TCP, configuration is required at the ingress controller/implementation level.

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

   **Note**: The configuration below:
   
   * Assumes you have `oid` installed with value `oid` as a deployment/release name in the namespace `oidns`. If using a different deployment name and/or namespace change appropriately. 
   * Deploys an ingress using NodePort. If using an external loadbalancer, change the configuration accordingly. For more details about NGINX configuration see: [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/user-guide/exposing-tcp-udp-services/).

   ```yaml
   # Configuration for additional TCP ports to be exposed through Ingress
   # Format for each port would be like:
   # <PortNumber>: <Namespace>/<Service>
   tcp:
     # Map 1389 TCP port to LBR LDAP service to get requests handled through any available POD/Endpoint serving LDAP Port
     3060: oidns/oid-lbr-ldap:3060
     # Map 1636 TCP port to LBR LDAP service to get requests handled through any available POD/Endpoint serving LDAPS Port
     3131: oidns/oid-lbr-ldap:3131
     3061: oidns/oidhost1:3060
     3130: oidns/oidhost1:3131
     3062: oidns/oidhost2:3060
     3132: oidns/oidhost2:3131
     3063: oidns/oidhost3:3060
     3133: oidns/oidhost3:3131
     3064: oidns/oidhost4:3060
     3134: oidns/oidhost4:3131
     3065: oidns/oidhost5:3060
     3135: oidns/oidhost5:3131
   controller:
     admissionWebhooks:
       enabled: false
     extraArgs:
       # The secret referred to by this flag contains the default certificate to be used when accessing the catch-all server.
       # If this flag is not provided NGINX will use a self-signed certificate.
       # If the TLS Secret is in different namespace, name can be mentioned as <namespace>/<tlsSecretName>
       default-ssl-certificate: oidns/oid-tls-cert
     service:
       # controller service external IP addresses
       # externalIPs:
       #   - < External IP Address >
       # To configure Ingress Controller Service as LoadBalancer type of Service
       # Based on the Kubernetes configuration, External LoadBalancer would be linked to the Ingress Controller Service
       type: NodePort
       # Configuration for NodePort to be used for Ports exposed through Ingress
       # If NodePorts are not defied/configured, Node Port would be assigend automatically by Kubernetes
       # These NodePorts are helpful while accessing services directly through Ingress and without having External Load Balancer.
       # nodePorts:
         # For HTTP Interface exposed through LoadBalancer/Ingress
         # http: 30080
         # For HTTPS Interface exposed through LoadBalancer/Ingress
         # https: 30443
         #tcp:
           # For LDAP Interface
           # 3060: 31389
           # For LDAPS Interface
           # 3131: 31636
   ```
   
1. To install and configure NGINX Ingress issue the following command:

   ```bash
   $ helm install --namespace <namespace> \
   --values nginx-ingress-values-override.yaml \
   lbr-nginx stable/ingress-nginx \
   --set controller.admissionWebhooks.enabled=false
   ```

   Where:
   * `lbr-nginx` is your deployment name
   * `stable/ingress-nginx` is the chart reference

   For example:
   
   ```bash
   $ helm install --namespace mynginx \
   --values nginx-ingress-values-override.yaml \
   lbr-nginx stable/ingress-nginx \
   --set controller.admissionWebhooks.enabled=false
   ```
   
   The output will look similar to the following:

   ```
   NAME: lbr-nginx
   LAST DEPLOYED: Wed Mar 16 16:49:35 2022
   NAMESPACE: mynginx
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   The ingress-nginx controller has been installed.
   It may take a few minutes for the LoadBalancer IP to be available.
   You can watch the status by running 'kubectl --namespace mynginx get services -o wide -w lbr-nginx-ingress-nginx-controller'

   An example Ingress that makes use of the controller:

     apiVersion: networking.k8s.io/v1beta1
     kind: Ingress
     metadata:
       annotations:
         kubernetes.io/ingress.class: nginx
       name: example
       namespace: foo
     spec:
       rules:
         - host: www.example.com
           http:
             paths:
               - backend:
                   serviceName: exampleService
                   servicePort: 80
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

To view the ports for the ingress run the following command:

```bash
$ kubectl get all -n mynginx
```

The output will look similar to the following:

```bash
NAME                                         TYPE       CLUSTER-IP    EXTERNAL-IP   PORT(S)                                                                                                                                                                                                          AGE
service/lbr-nginx-ingress-nginx-controller   NodePort   10.97.43.76   <none>        80:30096/TCP,443:31581/TCP,3060:31862/TCP,3061:30271/TCP,3062:31507/TCP,3063:30673/TCP,3064:31562/TCP,3065:30294/TCP,3130:31220/TCP,3131:30127/TCP,3132:31969/TCP,3133:32649/TCP,3134:32042/TCP,3135:30408/TCP   71s

NAME                                                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/lbr-nginx-ingress-nginx-controller   1/1     1            1           71s

NAME                                                           DESIRED   CURRENT   READY   AGE
replicaset.apps/lbr-nginx-ingress-nginx-controller-d5577cfd7   1         1         1       71s
```


#### Using LDAP utilities

To use Oracle LDAP utilities such as `ldapbind`, `ldapsearch`, `ldapmodify` etc. you can either:

* Run the LDAP commands from an OID installation outside the Kubernetes cluster. This requires access to an On-Premises OID installation oustide the Kubernetes cluster.

* Run the LDAP commands from inside the OID Kubernetes pod. Execute the following command to enter the pod:

   ```bash
   $ kubectl exec -ti <pod> -n <namespace> -- bash
   ```
   
   For example:
   
   ```bash
   $ kubectl exec -ti oidhost1 -n oidns -- bash
   ```
   
   This will take you into a bash session in the pod:

   ```bash
   [oracle@oidhost1 oracle]$    
   ```
   
   Inside the container navigate to `/u01/oracle/bin` to view the LDAP utilties:

   ```bash
   [oracle@oidhost1 oracle]$ cd /u01/oracle/bin
   [oracle@oidhost1 bin]$ ls ldap*
   ldapadd  ldapaddmt  ldapbind  ldapcompare  ldapdelete  ldapmoddn  ldapmodify  ldapmodifymt  ldapsearch
   ```

   **Note**: For commands that require an ldif file, copy the file into the `<persistent_volume>/oud_user_projects` directory:
  
   ```bash
   $ cp file.ldif <peristent_volume>/oid_user_projects
   ```
  
   For example:
  
   ```bash
   $ cp file.ldif /scratch/shared/oid_user_projects
   ```
  
   The file can then be viewed inside the pod:
  
   ```bash
   [oracle@oidhost1 bin]$ cd /u01/oracle/user_projects
   [oracle@oidhost1 user_projects]$ ls *.ldif
   file.ldif
   ```
  

#### Validate access using LDAP utilities

1. Use an LDAP client such as `ldapbind` to connect to the OID service. In the example below ldapbind is used from inside the OID Kubernetes pod:

   ```bash
   [oracle@oidhost1 bin]$ ldapbind -D cn=orcladmin -w <password> -h <hostname_ingress> -p 31862
   ```

   where:

   * `-p 31862` : is the port mapping to the LDAP port `3060` (3060:31862) from the earlier `kubectl` command
   * `-h <hostname_ingress>` : is the hostname where the ingress is running

   The output should look similar to the following:
   
   ```bash
   bind successful
   ```

#### Validate OID using Oracle Directory Services Manager
   
1. Access the Oracle WebLogic Server Administration Console and Oracle Directory Services Manager (ODSM) via a browser using the service port which maps to HTTPS port 443. In this example the port is 31581 (`443:31581`) from the earlier `kubectl` command.

* Oracle WebLogic Server Administration Console    : `https://<hostname_ingress>:31581/console`.

  When prompted, enter the username and password which corresponds to `[adminUser]` and `[adminPassword]` passed in [Create OID instances](../create-oid-instances/#create-oid-instances).

* Oracle Directory Services Manager : `https://<hostname_ingress>:31851/odsm`.

  Select **Create a New Connection** and, when prompted, enter the following values.

  * Server: `<hostname_ingress>`
  * Port: Ingress mapped port for LDAP or LDAPS, in the example above `3060:31862/TCP` or `3131:30127/TCP`, namely `LDAP:31862`, `LDAPS:30127`
  * SSL Enabled: select if accessing LDAPS.
  * User Name: `cn=orcladmin`
  * Password: value of `orcladminPassword` passed in [Create OID instances](../create-oid-instances/#create-oid-instances)



   


