+++
title = "Configure an Ingress for an OAM domain"
weight = 5 
pre = "<b>5. </b>"
description=  "This document provides steps to configure an Ingress to direct traffic to the OAM domain."
+++

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
   $ mkdir <workdir>/ssl
   $ cd <workdir>/ssl
   $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=<nginx-hostname>"
   ```
   
   For example:
   
   ```bash
   $ mkdir /scratch/OAMK8S/ssl
   $ cd /scratch/OAMK8S/ssl
   $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=masternode.example.com"
   ```

   **Note**: The `CN` should match the host.domain of the master node in order to prevent hostname problems during certificate verification.
   
   The output will look similar to the following:
   
   ```
   Generating a 2048 bit RSA private key
   ..........................................+++
   .......................................................................................................+++
   writing new private key to 'tls.key'
   -----
   ```
   
2. Create a secret for SSL by running the following command:

   ```bash
   $ kubectl -n oamns create secret tls <domain_uid>-tls-cert --key <workdir>/tls.key --cert <workdir>/tls.crt
   ```
   
   For example:
   
   ```bash
   $ kubectl -n oamns create secret tls accessdomain-tls-cert --key /scratch/OAMK8S/ssl/tls.key --cert /scratch/OAMK8S/ssl/tls.crt
   ```
   
   The output will look similar to the following:
   
   ```
   secret/accessdomain-tls-cert created
   ```
   
   
#### Install NGINX

Use helm to install NGINX.

1. Add the helm chart repository for NGINX using the following command:

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
   Update Complete. ⎈ Happy Helming!⎈
   ```

##### Install NGINX using helm 
 
If you can connect directly to the master node IP address from a browser, then install NGINX with the `--set controller.service.type=NodePort` parameter.

If you are using a Managed Service for your Kubernetes cluster, for example Oracle Kubernetes Engine (OKE) on Oracle Cloud Infrastructure (OCI), and connect from a browser to the Load Balancer IP address, then use the `--set controller.service.type=LoadBalancer` parameter. This instructs the Managed Service to setup a Load Balancer to direct traffic to the NGINX ingress.
 
1. To install NGINX use the following helm command depending on if you are using `NodePort` or `LoadBalancer`:

   a) Using NodePort

   ```bash
   $ helm install nginx-ingress -n <domain_namespace> --set controller.extraArgs.default-ssl-certificate=<domain_namespace>/<ssl_secret> --set controller.service.type=NodePort --set controller.admissionWebhooks.enabled=false stable/ingress-nginx
   ```
	
   For example:
	
   ```bash
   $ helm install nginx-ingress -n oamns --set controller.extraArgs.default-ssl-certificate=oamns/accessdomain-tls-cert --set controller.service.type=NodePort --set controller.admissionWebhooks.enabled=false stable/ingress-nginx
   ```
   
    
   The output will look similar to the following:
   
   ``` 
   NAME: nginx-ingress
   LAST DEPLOYED: <DATE>

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

     apiVersion: networking.k8s.io/v1
     kind: Ingress
     metadata:
       annotations:
         kubernetes.io/ingress.class: nginx
       name: example
       namespace: foo
     spec:
       ingressClassName: example-class
       rules:
          - host: www.example.com
           http:
             paths:
               - path: /
                 pathType: Prefix
                 backend:
                   service:
                     name: exampleService
                     port: 80
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
   $ helm install nginx-ingress -n oamns --set controller.extraArgs.default-ssl-certificate=oamns/accessdomain-tls-cert  --set controller.service.type=LoadBalancer --set controller.admissionWebhooks.enabled=false stable/ingress-nginx
   ```
   
   The output will look similar to the following:
   
   ```
   $ helm install nginx-ingress -n oamns --set controller.extraArgs.default-ssl-certificate=oamns/accessdomain-tls-cert  --set controller.service.type=LoadBalancer --set controller.admissionWebhooks.enabled=false stable/ingress-nginx
   
   NAME: nginx-ingress
   LAST DEPLOYED: <DATE>
   NAMESPACE: nginxssl
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   The ingress-nginx controller has been installed.
   It may take a few minutes for the LoadBalancer IP to be available.
   You can watch the status by running 'kubectl --namespace oamns get services -o wide -w nginx-ingress-ingress-nginx-controller'

   An example Ingress that makes use of the controller:

     apiVersion: networking.k8s.io/v1
     kind: Ingress
     metadata:
       annotations:
         kubernetes.io/ingress.class: nginx
       name: example
       namespace: foo
     spec:
       ingressClassName: example-class
       rules:
          - host: www.example.com
           http:
             paths:
               - path: /
                 pathType: Prefix
                 backend:
                   service:
                     name: exampleService
                     port: 80
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
   $ cd $WORKDIR/kubernetes/charts/ingress-per-domain
   ```
   
   
1. Edit the `values.yaml` and change the `domainUID:` parameter to match your `domainUID`, for example `domainUID: accessdomain`. The file should look as follows:
   
   ```
   # Load balancer type.  Supported values are: NGINX
   type: NGINX

   # Type of Configuration Supported Values are : SSL and NONSSL
   sslType: SSL

   # domainType. Supported values are: oam
   domainType: oam


   #WLS domain as backend to the load balancer
   wlsDomain:
     domainUID: accessdomain
     adminServerName: AdminServer
     adminServerPort: 7001
     adminServerSSLPort:
     oamClusterName: oam_cluster
     oamManagedServerPort: 14100
     oamManagedServerSSLPort:
     policyClusterName: policy_cluster
     policyManagedServerPort: 15100
     policyManagedServerSSLPort:
	 
   # Host  specific values
   hostName:
     enabled: false
     admin: 
     runtime: 
   ```


1. Run the following helm command to install the ingress:

   ```bash
   $ cd $WORKDIR
   $ helm install oam-nginx kubernetes/charts/ingress-per-domain --namespace <domain_namespace> --values kubernetes/charts/ingress-per-domain/values.yaml
   ```
   
   For example:
   
   ```bash
   $ cd $WORKDIR
   $ helm install oam-nginx kubernetes/charts/ingress-per-domain --namespace oamns --values kubernetes/charts/ingress-per-domain/values.yaml
   ```
   
   The output will look similar to the following:
   
   ```
   NAME: oam-nginx
   LAST DEPLOYED: <DATE>
   NAMESPACE: oamns
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
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
   
   ```
   NAME             CLASS    HOSTS   ADDRESS          PORTS   AGE
   access-ingress   <none>   *       10.101.132.251   80      2m53s
   ```
   
1. Find the node port of NGINX using the following command:

   ```bash
   $ kubectl --namespace <domain_namespace> get services -o jsonpath="{.spec.ports[1].nodePort}" nginx-ingress-ingress-nginx-controller
   ```
   
   For example:
   
   ```bash
   $ kubectl --namespace oamns get services -o jsonpath="{.spec.ports[1].nodePort}" nginx-ingress-ingress-nginx-controller
   ```
     
   The output will look similar to the following:
   
   ```
   31051
   ```

1. Run the following command to check the ingress:

   ```bash
   $ kubectl describe ing <domainUID>-nginx -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl describe ing accessdomain-nginx -n oamns
   ```
   
   The output will look similar to the following:
   
   ```
   Name:             accessdomain-nginx
   Namespace:        oamns
   Address:          10.106.70.55
   Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
   Rules:
     Host        Path  Backends
     ----        ----  --------
     *
                 /console                        accessdomain-adminserver:7001 (10.244.1.18:7001)
                 /consolehelp                    accessdomain-adminserver:7001 (10.244.1.18:7001)
                 /rreg/rreg                      accessdomain-adminserver:7001 (10.244.1.18:7001)
                 /em                             accessdomain-adminserver:7001 (10.244.1.18:7001)
                 /oamconsole                     accessdomain-adminserver:7001 (10.244.1.18:7001)
                 /dms                            accessdomain-adminserver:7001 (10.244.1.18:7001)
                 /oam/services/rest              accessdomain-adminserver:7001 (10.244.1.18:7001)
                 /iam/admin/config               accessdomain-adminserver:7001 (10.244.1.18:7001)
                 /iam/admin/diag                 accessdomain-adminserver:7001 (10.244.1.18:7001)
                 /iam/access                     accessdomain-cluster-oam-cluster:14100 (10.244.1.20:14100,10.244.2.13:14100)
                 /oam/admin/api                  accessdomain-adminserver:7001 (10.244.1.18:7001)
                 /oam/services/rest/access/api   accessdomain-cluster-oam-cluster:14100 (10.244.1.20:14100,10.244.2.13:14100)
                 /access                         accessdomain-cluster-policy-cluster:15100 (10.244.1.19:15100,10.244.2.12:15100)
                 /                               accessdomain-cluster-oam-cluster:14100 (10.244.1.20:14100,10.244.2.13:14100)
   Annotations:  kubernetes.io/ingress.class: nginx
                 meta.helm.sh/release-name: oam-nginx
                 meta.helm.sh/release-namespace: oamns
                 nginx.ingress.kubernetes.io/configuration-snippet:
                   more_clear_input_headers "WL-Proxy-Client-IP" "WL-Proxy-SSL";
                   more_set_input_headers "X-Forwarded-Proto: https";
                   more_set_input_headers "WL-Proxy-SSL: true";
                 nginx.ingress.kubernetes.io/enable-access-log: false
                 nginx.ingress.kubernetes.io/ingress.allow-http: false
                 nginx.ingress.kubernetes.io/proxy-buffer-size: 2000k
   Events:
     Type    Reason  Age                From                      Message
     ----    ------  ----               ----                      -------
     Normal  Sync    14m (x2 over 15m)  nginx-ingress-controller  Scheduled for sync
   ```

  
1. To confirm that the new ingress is successfully routing to the domain's server pods, run the following command to send a request to the URL for the 'WebLogic ReadyApp framework':

   ```bash
   $ curl -v -k https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/weblogic/ready
   ```
  
   
   
   For example:
   
   a) For NodePort

   ```bash
   $ curl -v -k https://masternode.example.com:31051/weblogic/ready
   ```
   
   b) For LoadBalancer:
   
   ```bash
   $ curl -v -k https://loadbalancer.example.com/weblogic/ready
   ```

   The output will look similar to the following:
   
   ```
   *   Trying 12.345.67.89...
   * Connected to 12.345.67.89 (12.345.67.89) port 31051 (#0)
   * Initializing NSS with certpath: sql:/etc/pki/nssdb
   * skipping SSL peer certificate verification
   * SSL connection using TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
   * Server certificate:
   *       subject: CN=masternode.example.com
   *       start date: <DATE>
   *       expire date: <DATE>
   *       common name: masternode.example.com
   *       issuer: CN=masternode.example.com
   > GET /weblogic/ready HTTP/1.1
   > User-Agent: curl/7.29.0
   > Host: masternode.example.com:31051
   > Accept: */*
   >
   < HTTP/1.1 200 OK
   < Date: Mon, 12 Jul 2021 15:06:12 GMT
   < Content-Length: 0
   < Connection: keep-alive
   < Strict-Transport-Security: max-age=15724800; includeSubDomains
   <
   * Connection #0 to host 12.345.67.89 left intact
   ```
   
#### Verify that you can access the domain URL

After setting up the NGINX ingress, verify that the domain applications are accessible through the NGINX ingress port (for example 31051) as per [Validate Domain URLs ](../validate-domain-urls)


