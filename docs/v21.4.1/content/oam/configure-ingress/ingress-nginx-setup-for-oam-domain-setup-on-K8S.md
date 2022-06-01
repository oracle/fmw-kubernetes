---
title: "a. Using an Ingress with NGINX"
description: "Steps to set up an Ingress for NGINX to direct traffic to the OAM domain."
---

### Setting up an ingress for NGINX for the OAM Domain

The instructions below explain how to set up NGINX as an ingress for the OAM domain with SSL termination.

**Note**: All the steps below should be performed on the **master** node.

1. [Generate a SSL Certificate](#generate-a-ssl-certificate)
2. [Install NGINX](#install-nginx)
3. [Create an Ingress for the Domain](#create-an-ingress-for-the-domain)
4. [Verify that you can access the domain URL](#verify-that-you-can-access-the-domain-url)


#### Generate a SSL Certificate

1. Generate a private key and certificate signing request (CSR) using a tool of your choice. Send the CSR to your certificate authority (CA) to generate the certificate.

   If you want to use a certificate for testing purposes you can generate a self signed certificate using openssl:

   ```bash
   $ mkdir <work directory>/ssl
   $ cd <work directory>/ssl
   $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=<nginx-hostname>"
   ```
   
   For example:
   
   ```bash
   $ mkdir /scratch/OAMDockerK8S/ssl
   $ cd /scratch/OAMDockerK8S/ssl
   $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=masternode.example.com"
   ```

   **Note**: The `CN` should match the host.domain of the master node in order to prevent hostname problems during certificate verification.
   
   The output will look similar to the following:
   
   ```bash
   Generating a 2048 bit RSA private key
   ..........................................+++
   .......................................................................................................+++
   writing new private key to 'tls.key'
   -----
   ```
   
2. Create a secret for SSL by running the following command:

   ```bash
   $ kubectl -n oamns create secret tls <domain_uid>-tls-cert --key <work directory>/tls.key --cert <work directory>/tls.crt
   ```
   
   For example:
   
   ```bash
   $ kubectl -n oamns create secret tls accessdomain-tls-cert --key /scratch/OAMDockerK8S/ssl/tls.key --cert /scratch/OAMDockerK8S/ssl/tls.crt
   ```
   
   The output will look similar to the following:
   
   ```bash
   secret/accessdomain-tls-cert created
   ```
   
   
#### Install NGINX

Use helm to install NGINX.

1. Add the helm chart repository for NGINX using the following command:

   ```bash
   $ helm repo add stable https://kubernetes.github.io/ingress-nginx
   ```
   
   The output will look similar to the following:
   
   ```bash
   "stable" has been added to your repositories
   ```


1. Update the repository using the following command:

   ```bash
   $ helm repo update
   ```
   
   The output will look similar to the following:
   
   ```bash
   Hang tight while we grab the latest from your chart repositories...
   ...Successfully got an update from the "appscode" chart repository
   ...Successfully got an update from the "stable" chart repository
   Update Complete. ⎈ Happy Helming!⎈
   ```

##### Install NGINX using helm 
 
If you can connect directly to the master node IP address from a browser, then install NGINX with the `--set controller.service.type=NodePort` parameter.

If you are using a Managed Service for your Kubernetes cluster, for example Oracle Kubernetes Engine (OKE) on Oracle Cloud Infrastructure (OCI), and connect from a browser to the Load Balancer IP address, then use the `--set controller.service.type=LoadBalancer` parameter. This instructs the Managed Service to setup a Load Balancer to direct traffic to the NGINX ingress.
 
1. To install NGINX use the following helm command depending on if you are using `NodePort` or `LoadBalancer`:

   a) Using NodePort

   ```bash
   $ helm install nginx-ingress -n <domain_namespace> --set controller.extraArgs.default-ssl-certificate=<domain_namespace>/<ssl_secret> --set controller.service.type=NodePort --set controller.admissionWebhooks.enabled=false stable/ingress-nginx --version=3.34.0
   ```
	
   For example:
	
   ```bash
   $ helm install nginx-ingress -n oamns --set controller.extraArgs.default-ssl-certificate=oamns/accessdomain-tls-cert --set controller.service.type=NodePort --set controller.admissionWebhooks.enabled=false stable/ingress-nginx --version=3.34.0
   ```
    
   The output will look similar to the following:
   
   ```bash 
   NAME: nginx-ingress
   LAST DEPLOYED: Thu Sep 24 07:31:51 2020

   NAMESPACE: oamns
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   The nginx-ingress controller has been installed.
   Get the application URL by running these commands:
     export HTTP_NODE_PORT=$(kubectl --namespace oamns get services -o jsonpath="{.spec.ports[0].nodePort}" nginx-ingress-controller)
     export HTTPS_NODE_PORT=$(kubectl --namespace oamns get services -o jsonpath="{.spec.ports[1].nodePort}" nginx-ingress-controller)
     export NODE_IP=$(kubectl --namespace oamns get nodes -o jsonpath="{.items[0].status.addresses[1].address}")

     echo "Visit http://$NODE_IP:$HTTP_NODE_PORT to access your application via HTTP."
     echo "Visit https://$NODE_IP:$HTTPS_NODE_PORT to access your application via HTTPS."

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

   b) Using LoadBalancer

   ```
   $ helm install nginx-ingress -n oamns --set controller.extraArgs.default-ssl-certificate=oamns/accessdomain-tls-cert  --set controller.service.type=LoadBalancer --set controller.admissionWebhooks.enabled=false stable/ingress-nginx --version=3.34.0
   ```    
   
   The output will look similar to the following:
   
   ```
   $ helm install nginx-ingress -n oamns --set controller.extraArgs.default-ssl-certificate=oamns/accessdomain-tls-cert  --set controller.service.type=LoadBalancer --set controller.admissionWebhooks.enabled=false stable/ingress-nginx --version=3.34.0
   
   NAME: nginx-ingress
   LAST DEPLOYED: Thu Sep 24 07:45:52 2020
   NAMESPACE: nginxssl
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   The ingress-nginx controller has been installed.
   It may take a few minutes for the LoadBalancer IP to be available.
   You can watch the status by running 'kubectl --namespace nginxssl get services -o wide -w nginx-ingress-ingress-nginx-controller'

   An example Ingress that makes use of the controller:

     apiVersion: extensions/v1beta1
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
   
#### Create an Ingress for the Domain

1. Navigate to the following directory:

   ```
   cd <work directory>/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain
   ```
   
   For example:
   
   ```
   $ cd /scratch/OAMDockerK8S/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain
   ```
   
1. Edit the `ssl-nginx-ingress.yaml` and edit the following parameters:

   ```
   namespace: <domain_namespace>
   serviceName: <domain_uid>-adminserver
   serviceName: <domain_uid>-cluster-oam-cluster
   serviceName: <domain_uid>-cluster-policy-cluster
   ```
    
   For example:
   
   ```
   # Copyright (c) 2020, Oracle and/or its affiliates.
   # Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

   apiVersion: extensions/v1beta1
   kind: Ingress
   metadata:
     name: access-ingress
     namespace: oamns
     annotations:
       nginx.ingress.kubernetes.io/proxy-buffer-size: "2000k"
       kubernetes.io/ingress.class: nginx
       nginx.ingress.kubernetes.io/enable-access-log: "false"
       nginx.ingress.kubernetes.io/configuration-snippet: |
         more_set_input_headers "X-Forwarded-Proto: https";
         more_set_input_headers "WL-Proxy-SSL: true";
       nginx.ingress.kubernetes.io/ingress.allow-http: "false"
   spec:
     rules:
      - http:
         paths:
         - path: /console
           backend:
             serviceName: accessdomain-adminserver
             servicePort: 7001
         - path: /rreg/rreg
           backend:
             serviceName: accessdomain-adminserver
             servicePort: 7001
         - path: /em
           backend:
             serviceName: accessdomain-adminserver
             servicePort: 7001
         - path: /oamconsole
           backend:
             serviceName: accessdomain-adminserver
             servicePort: 7001
         - path: /dms
           backend:
             serviceName: accessdomain-adminserver
             servicePort: 7001
         - path: /oam/services/rest
           backend:
             serviceName: accessdomain-adminserver
             servicePort: 7001
         - path: /iam/admin/config
           backend:
             serviceName: accessdomain-adminserver
             servicePort: 7001
         - path: /oam/admin/api
           backend:
             serviceName: accessdomain-adminserver
             servicePort: 7001
         - path: /iam/admin/diag
           backend:
             serviceName: accessdomain-adminserver
             servicePort: 7001
         - path: /iam/access
           backend:
             serviceName: accessdomain-cluster-oam-cluster
             servicePort: 14100
         - path: /oam/services/rest/access/api
           backend:
             serviceName: accessdomain-cluster-oam-cluster
             servicePort: 14100
         - path: /access
           backend:
             serviceName: accessdomain-cluster-policy-cluster
             servicePort: 15100
         - path: /
           backend:
             serviceName: accessdomain-cluster-oam-cluster
             servicePort: 14100
   ```
   
1. Create an Ingress for the domain (`access-ingress`), in the domain namespace by using the sample Helm chart.

   ```bash
   $ kubectl create -f ssl-nginx-ingress.yaml
   ```
   
   **Note**: The `ssl-nginx-ingress.yaml` has `nginx.ingress.kubernetes.io/enable-access-log` set to `false`. If you want to enable access logs then set this value to `true` before executing the command. Enabling access-logs can cause issues with disk space if not regularly maintained.
   
   The output will look similar to the following:
   
   ```bash
   ingress.extensions/access-ingress created
   ```  
   
1. Run the following command to show the ingress is created successfully:

   ```bash
   $ kubectl get ing -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl get ing -n oamns
   ```
   
   The output will look similar to the following:
   ```bash
   NAME             CLASS    HOSTS   ADDRESS          PORTS   AGE
   access-ingress   <none>   *                        80      2m53s
   ```
   
1. Find the node port of NGINX using the following command:

   ```bash
   $ kubectl --namespace oamns get services -o jsonpath="{.spec.ports[1].nodePort}" nginx-ingress-ingress-nginx-controller
   ```
   
   The output will look similar to the following:
   
   ```bash
   30099
   ```

1. Run the following command to check the ingress:

   ```bash
   $ kubectl describe ing access-ingress -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl describe ing access-ingress -n oamns
   ```
   
   The output will look similar to the following:
   ```bash
   Name:             access-ingress
   Namespace:        oamns
   Address:          10.107.181.157
   Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
   Rules:
     Host        Path  Backends
     ----        ----  --------
     *
                 /console                        accessdomain-adminserver:7001 (10.244.1.7:7001)
                 /rreg/rreg                      accessdomain-adminserver:7001 (10.244.1.7:7001)
                 /em                             accessdomain-adminserver:7001 (10.244.1.7:7001)
                 /oamconsole                     accessdomain-adminserver:7001 (10.244.1.7:7001)
                 /dms                            accessdomain-adminserver:7001 (10.244.1.7:7001)
                 /oam/services/rest              accessdomain-adminserver:7001 (10.244.1.7:7001)
                 /iam/admin/config               accessdomain-adminserver:7001 (10.244.1.7:7001)
                 /oam/admin/api                  accessdomain-adminserver:7001 (10.244.1.7:7001)
                 /iam/admin/diag                 accessdomain-adminserver:7001 (10.244.1.7:7001)
                 /iam/access                     accessdomain-cluster-oam-cluster:14100 (10.244.1.8:14100,10.244.2.3:14100)
                 /oam/services/rest/access/api   accessdomain-cluster-oam-cluster:14100 (10.244.1.8:14100,10.244.2.3:14100)
                 /access                         accessdomain-cluster-policy-cluster:15100 (10.244.1.9:15100)
                 /                               accessdomain-cluster-oam-cluster:14100 (10.244.1.8:14100,10.244.2.3:14100)
   Annotations:  kubernetes.io/ingress.class: nginx
                 nginx.ingress.kubernetes.io/configuration-snippet:
                   more_set_input_headers "X-Forwarded-Proto: https";
                   more_set_input_headers "WL-Proxy-SSL: true";
                 nginx.ingress.kubernetes.io/ingress.allow-http: false
                 nginx.ingress.kubernetes.io/proxy-buffer-size: 2000k
   Events:
     Type    Reason  Age   From                      Message
     ----    ------  ----  ----                      -------
     Normal  CREATE  85s   nginx-ingress-controller  Ingress oamns/access-ingress
     Normal  UPDATE  40s   nginx-ingress-controller  Ingress oamns/access-ingress
   ```

  
1. To confirm that the new Ingress is successfully routing to the domain's server pods, run the following command to send a request to the URL for the "WebLogic ReadyApp framework":

   ```bash
   $ curl -v -k https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/weblogic/ready
   ```
   
   For example:
   
   ```bash
   $ curl -v -k https://masternode.example.com:30099/weblogic/ready
   ```
   
   The output will look similar to the following:
   
   ```bash
   *   Trying 12.345.67.89...
   * Connected to 12.345.67.89 (12.345.67.89) port 30099 (#0)
   * Initializing NSS with certpath: sql:/etc/pki/nssdb
   * skipping SSL peer certificate verification
   * SSL connection using TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
   * Server certificate:
   *       subject: CN=masternode.example.com
   *       start date: Sep 24 14:30:46 2020 GMT
   *       expire date: Sep 24 14:30:46 2021 GMT
   *       common name: masternode.example.com
   *       issuer: CN=masternode.example.com
   > GET /weblogic/ready HTTP/1.1
   > User-Agent: curl/7.29.0
   > Host: masternode.example.com:30099
   > Accept: */*
   >
   < HTTP/1.1 200 OK
   < Server: nginx/1.19.2
   < Date: Thu, 24 Sep 2020 14:51:06 GMT
   < Content-Length: 0
   < Connection: keep-alive
   < Strict-Transport-Security: max-age=15724800; includeSubDomains
   <
   * Connection #0 to host 10.247.94.49 left intact
   ```
   
#### Verify that you can access the domain URL

After setting up the NGINX ingress, verify that the domain applications are accessible through the NGINX ingress port (for example 30099) as per [Validate Domain URLs ]({{< relref "/oam/validate-domain-urls" >}})
