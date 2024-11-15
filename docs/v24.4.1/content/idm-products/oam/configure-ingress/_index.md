+++
title = "Configure an Ingress for an OAM domain"
weight = 6 
pre = "<b>6. </b>"
description=  "This document provides steps to configure an Ingress to direct traffic to the OAM domain."
+++

## Configuring an ingress for NGINX for the OAM Domain

The instructions below explain how to set up NGINX as an ingress for the OAM domain.

The ingress can be configured in the following ways:

+ Without SSL
+ With SSL
+ OAM URI's are accessible from all hosts
+ OAM URI's are accessible using virtual hostnames only


The option you choose will depend on the architecture you are configuring. For example, if you have an architecture such as [Oracle HTTP Server on an independent Kubernetes cluster](../../../ohs/introduction/#oracle-http-server-on-an-independent-kubernetes-cluster), where SSL is terminated at the load balancer, then you would configure the ingress without SSL.

In almost all circumstances, the ingress should be configured to be accessible from all hosts (using `host.enabled: false` in the `values.yaml`). You can only configure ingress to use virtual hostnames only (using `host.enabled: true` in the `values.yaml`), if all of the following criteria are met:

+ SSL is terminated at the load balancer
+ The SSL port is 443
+ You have separate hostnames for OAM administration URL's (for example `https://admin.example.com/console`), and OAM runtime URL's (for example `https://runtime.example.com/oam/server`).  

See, [Prepare the values.yaml for the ingress](#prepare-the-valuesyaml-for-the-ingress) for more details.


The steps to generate an ingress are as follows:

1. [Install NGINX](#install-nginx)
1. [Generate a SSL Certificate](#generate-a-ssl-certificate)
1. [Create an ingress controller](#create-an-ingress-controller)
1. [Prepare the values.yaml for the ingress](#prepare-the-valuesyaml-for-the-ingress)
1. [Create the Ingress](#create-the-ingress)
1. [Verify that you can access the domain URL](#verify-that-you-can-access-the-domain-urls)


  
### Install NGINX

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


### Generate a SSL Certificate

This section should only be followed if you want to configure your ingress for SSL.

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
	
	
### Create an ingress controller 

In this section you create an ingress controller. 

If you can connect directly to the master node IP address from a browser, then install NGINX with the `--set controller.service.type=NodePort` parameter.

If you are using a Managed Service for your Kubernetes cluster, for example Oracle Kubernetes Engine (OKE) on Oracle Cloud Infrastructure (OCI), and connect from a browser to the Load Balancer IP address, then use the `--set controller.service.type=LoadBalancer` parameter. This instructs the Managed Service to setup a Load Balancer to direct traffic to the NGINX ingress.

The instructions below use `--set controller.service.type=NodePort`. If using a managed service, change to `--set controller.service.type=LoadBalancer`.

The following sections show how to install the ingress with SSL or without SSL. Follow the relevant section based on your architecture.


#### Configure an ingress controller with SSL
 
1. To configure the ingress controller to use SSL, run the following command:

   ```bash
   $ helm install nginx-ingress -n <domain_namespace> --set controller.service.nodePorts.http=<http_port> --set controller.service.nodePorts.https=<https_port> --set controller.extraArgs.default-ssl-certificate=<domain_namespace>/<ssl_secret> --set controller.service.type=<type> --set controller.config.use-forwarded-headers=true --set controller.config.enable-underscores-in-headers=true --set controller.admissionWebhooks.enabled=false stable/ingress-nginx
   ```
	
	where:
	
	+ `<domain_namespace>` is your namespace, for example `oamns`.
	+ `<http_port>` is the HTTP port that you want the controller to listen on, for example `30777`.
	+ `<https_port>` is the HTTPS port that you want the controller to listen on, for example `30443`.
	+ `<type>` is the controller type. If using NodePort set to `NodePort`. If using a managed service set to `LoadBalancer`. If using `LoadBalancer` remove `--set controller.service.nodePorts.http=<http_port>` and `--set controller.service.nodePorts.https=<https_port>`.
	+ `<ssl_secret>` is the secret you created in [Generate a SSL Certificate](#generate-a-ssl-certificate).
	

   For example:
	
   ```bash
   $ helm install nginx-ingress -n oamns --set controller.service.nodePorts.http=30777 --set controller.service.nodePorts.https=30443 --set controller.extraArgs.default-ssl-certificate=oamns/accessdomain-tls-cert --set controller.service.type=NodePort --set controller.config.use-forwarded-headers=true --set controller.config.enable-underscores-in-headers=true --set controller.admissionWebhooks.enabled=false stable/ingress-nginx --version 4.7.2
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
     export HTTP_NODE_PORT=30777
     export HTTPS_NODE_PORT=30443
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


#### Configure an ingress controller without SSL
 
1. To configure the ingress controller without SSL, run the following command:

   ```bash
   $ helm install nginx-ingress -n <domain_namespace> --set controller.service.nodePorts.http=<http_port> --set controller.service.type=NodePort --set controller.config.use-forwarded-headers=true --set controller.config.enable-underscores-in-headers=true --set controller.admissionWebhooks.enabled=false stable/ingress-nginx
   ```
	
	where:
	
	+ `<domain_namespace>` is your namespace, for example `oamns`.
	+ `<http_port>` is the HTTP port that you want the controller to listen on, for example `30777`.
	+ `<type>` is the controller type. If using NodePort set to `NodePort`. If using a managed service set to `LoadBalancer`. If using `LoadBalancer` remove `--set controller.service.nodePorts.http=<http_port>`.
	
   For example:
	
   ```bash
   $ helm install nginx-ingress -n oamns --set controller.service.nodePorts.http=30777 --set controller.service.type=NodePort --set controller.config.use-forwarded-headers=true --set controller.config.enable-underscores-in-headers=true --set controller.admissionWebhooks.enabled=false stable/ingress-nginx --version 4.7.2
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
     export HTTP_NODE_PORT=30777
     export HTTPS_NODE_PORT=$(kubectl --namespace oamns get services -o jsonpath="{.spec.ports[1].nodePort}" nginx-ingress-ingress-nginx-controller)
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
 
 
   
### Prepare the values.yaml for the ingress

1. Navigate to the following directory and make a copy of the values.yaml:

   ```
   $ cd $WORKDIR/kubernetes/charts/ingress-per-domain
   $ cp values.yaml $WORKDIR/
   ```
      
1. Edit the `$WORKDIR/kubernetes/charts/ingress-per-domain/values.yaml` and modify the following parameters if required:


   + `domainUID:` - If you created your OAM domain with anything other than the default `accessdomain`, change accordingly.
   + `sslType:` - Values supported are `SSL` and `NONSSL`. If you created your ingress controller to use SSL then set to `SSL`, otherwise set to `NONSSL`.
   + `hostName.enabled: false` - This should be set to `false` in almost all circumstances. Setting to `false` allows OAM URI's to be accessible from all hosts. Setting to `true` configures ingress for virtual hostnames only. See [Configuring an ingress for NGINX for the OAM Domain](#configuring-an-ingress-for-nginx-for-the-oam-domain) for full details of the criteria that must be met set to this value to `true`.
	+ `hostName.admin: <hostname>` - Should only be set if `hostName.enabled: true` and `sslType: NONSSL`. This should be set to the `hostname.domain` of the URL you access OAM administration URL's from, for example if you access the OAM Administration Console via `https://admin.example.com/oamconsole`, then set to `admin.example.com`.
   + `hostName.runtime: <hostname>` - Should only be set if `hostName.enabled: true`. This should be set to the `hostname.domain` of the URL you access OAM runtime URL's from, for example if the `oam/server` URI is accessed via `https://runtime.example.com/oam/server`, then set to `runtime.example.com`.


	
	The following shows example files based on different configuration types:
	
	
	{{%expand "Click here to see a values.yaml for SSL" %}}
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
   {{% /expand %}}

	
	{{%expand "Click here to see a values.yaml for NONSSL using all hostnames" %}}
   ```
   # Load balancer type.  Supported values are: NGINX
   type: NGINX

   # Type of Configuration Supported Values are : SSL and NONSSL
   sslType: NONSSL

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
   {{% /expand %}}
	
	
   {{%expand "Click here to see a values.yaml for NONSSL using virtual hostnames" %}}
   ```
   # Load balancer type.  Supported values are: NGINX
   type: NGINX

   # Type of Configuration Supported Values are : SSL and NONSSL
   sslType: NONSSL

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
     enabled: true
     admin: admin.example.com
     runtime: runtime.example.com
   ```
   {{% /expand %}}
	
	
### Create the ingress	

1. Run the following helm command to create the ingress:

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
   
   If `hostname.enabled: false`, the output will look similar to the following:
   
   ```
   NAME                 CLASS    HOSTS   ADDRESS   PORTS   AGE
   accessdomain-nginx   <none>   *                 80      5s
   ```
   
	If `hostname.enabled: true`, the output will look similar to the following:
	
	```
	NAME                 CLASS   HOSTS                   ADDRESS   PORTS   AGE
   oamadmin-ingress     nginx   admin.example.com                 80      14s
   oamruntime-ingress   nginx   runtime.example.com               80      14s
	```
	
1. Run the following command to check the ingress:

   
   
   ```bash
   $ kubectl describe ing <ingress> -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl describe ing accessdomain-nginx -n oamns
   ```
   
   The output will look similar to the following for `accessdomain-nginx`:
   
   ```
   Name:             accessdomain-nginx
   Labels:           app.kubernetes.io/managed-by=Helm
   Namespace:        oamns
   Address:          
   Ingress Class:    <none>
   Default backend:  <default>
   Rules:
     Host        Path  Backends
     ----        ----  --------
     *
                 /console                        accessdomain-adminserver:7001 (10.244.1.200:7001)
                 /consolehelp                    accessdomain-adminserver:7001 (10.244.1.200:7001)
                 /rreg/rreg                      accessdomain-adminserver:7001 (10.244.1.200:7001)
                 /em                             accessdomain-adminserver:7001 (10.244.1.200:7001)
                 /oamconsole                     accessdomain-adminserver:7001 (10.244.1.200:7001)
                 /dms                            accessdomain-adminserver:7001 (10.244.1.200:7001)
                 /oam/services/rest              accessdomain-adminserver:7001 (10.244.1.200:7001)
                 /iam/admin/config               accessdomain-adminserver:7001 (10.244.1.200:7001)
                 /iam/admin/diag                 accessdomain-adminserver:7001 (10.244.1.200:7001)
                 /iam/access                     accessdomain-cluster-oam-cluster:14100 (10.244.2.127:14100)
                 /oam/admin/api                  accessdomain-adminserver:7001 (10.244.1.200:7001)
                 /oam/services/rest/access/api   accessdomain-cluster-oam-cluster:14100 (10.244.2.127:14100)
                 /access                         accessdomain-cluster-policy-cluster:15100 (10.244.2.126:15100)
                 /oam                            accessdomain-cluster-oam-cluster:14100 (10.244.2.127:14100)
                 /                               accessdomain-cluster-oam-cluster:14100 (10.244.2.127:14100)
   Annotations:  meta.helm.sh/release-name: oam-nginx
                 meta.helm.sh/release-namespace: oamns
                 nginx.ingress.kubernetes.io/enable-access-log: false
                 nginx.ingress.kubernetes.io/proxy-buffer-size: 2000k
   Events:       <none>
	  Type    Reason  Age   From                      Message
     ----    ------  ----  ----                      -------
     Normal  Sync    33s   nginx-ingress-controller  Scheduled for sync
   ```

   The output will look similar to the following for `oamadmin-ingress`:
  
   ```
   Name:             oamadmin-ingress
   Labels:           app.kubernetes.io/managed-by=Helm
   Namespace:        oamns
   Address:
   Ingress Class:    nginx
   Default backend:  <default>
   Rules:
     Host                                    Path  Backends
     ----                                    ----  --------
     admin.example.com
                                             /console                        accessdomain-adminserver:7001 (10.244.1.200:7001)
                                             /consolehelp                    accessdomain-adminserver:7001 (10.244.1.200:7001)
                                             /rreg/rreg                      accessdomain-adminserver:7001 (10.244.1.200:7001)
                                             /em                             accessdomain-adminserver:7001 (10.244.1.200:7001)
                                             /oamconsole                     accessdomain-adminserver:7001 (10.244.1.200:7001)
                                             /dms                            accessdomain-adminserver:7001 (10.244.1.200:7001)
                                             /oam/services/rest              accessdomain-adminserver:7001 (10.244.1.200:7001)
                                             /iam/admin/config               accessdomain-adminserver:7001 (10.244.1.200:7001)
                                             /oam/admin/api                  accessdomain-adminserver:7001 (10.244.1.200:7001)
                                             /iam/admin/diag                 accessdomain-adminserver:7001 (10.244.1.200:7001)
                                             /oam/services                   accessdomain-adminserver:7001 (10.244.1.200:7001)
                                             /iam/admin                      accessdomain-adminserver:7001 (10.244.1.200:7001)
                                             /oam/services/rest/11.1.2.0.0   accessdomain-adminserver:7001 (10.244.1.200:7001)
                                             /oam/services/rest/ssa          accessdomain-cluster-oam-cluster:14100 (10.244.2.127:14100)
                                             /access                         accessdomain-cluster-policy-cluster:15100 (10.244.2.126:15100)
   Annotations:                              meta.helm.sh/release-name: oam-nginx
                                             meta.helm.sh/release-namespace: oamns
                                             nginx.ingress.kubernetes.io/affinity: cookie
                                             nginx.ingress.kubernetes.io/enable-access-log: false
                                             nginx.ingress.kubernetes.io/ingress.allow-http: true
                                             nginx.ingress.kubernetes.io/proxy-buffer-size: 2000k
                                             nginx.ingress.kubernetes.io/ssl-redirect: false
   Events:
     Type    Reason  Age   From                      Message
     ----    ------  ----  ----                      -------
     Normal  Sync    32s   nginx-ingress-controller  Scheduled for sync
   ```
	
	
     
    The output will look similar to the following for `oamruntime-ingress`:
	
   ```
   Name:             oamruntime-ingress
   Labels:           app.kubernetes.io/managed-by=Helm
   Namespace:        oamns
   Address:          10.106.62.184
   Ingress Class:    nginx
   Default backend:  <default>
   Rules:
     Host                                    Path  Backends
     ----                                    ----  --------
     runtime.example.com
                                             /ms_oauth                           accessdomain-cluster-oam-cluster:14100 (10.244.2.127:14100)
                                             /oam/services/rest/auth             accessdomain-cluster-oam-cluster:14100 (10.244.2.127:14100)
                                             /oam/services/rest/access           accessdomain-cluster-oam-cluster:14100 (10.244.2.127:14100)
                                             /oamfed                             accessdomain-cluster-oam-cluster:14100 (10.244.2.127:14100)
                                             /otpfp/                             accessdomain-cluster-oam-cluster:14100 (10.244.2.127:14100)
                                             /oauth2                             accessdomain-cluster-oam-cluster:14100 (10.244.2.127:14100)
                                             /oam                                accessdomain-cluster-oam-cluster:14100 (10.244.2.127:14100)
                                             /.well-known/openid-configuration   accessdomain-cluster-oam-cluster:14100 (10.244.2.127:14100)
                                             /.well-known/oidc-configuration     accessdomain-cluster-oam-cluster:14100 (10.244.2.127:14100)
                                             /CustomConsent                      accessdomain-cluster-oam-cluster:14100 (10.244.2.127:14100)
                                             /iam/access                         accessdomain-cluster-oam-cluster:14100 (10.244.2.127:14100)
   Annotations:                              meta.helm.sh/release-name: oam-nginx
                                             meta.helm.sh/release-namespace: oamns
                                             nginx.ingress.kubernetes.io/affinity: cookie
                                             nginx.ingress.kubernetes.io/enable-access-log: false
                                             nginx.ingress.kubernetes.io/proxy-buffer-size: 2000k
   Events:
     Type    Reason  Age                    From                      Message
     ----    ------  ----                   ----                      -------
     Normal  Sync    3m34s (x2 over 4m10s)  nginx-ingress-controller  Scheduled for sync
   ```	
	
	
  
1. To confirm that the new ingress is successfully routing to the domain's server pods, run the following command to send a request to the OAM Administration Console:

   For SSL: 
	
   ```bash
   $ curl -v -k https://${HOSTNAME}:${PORT}/oamconsole
   ```
   
	For NON SSL: 
   
	```bash
   $ curl -v http://${HOSTNAME}:${PORT}/oamconsole
   ```
	
	The `${HOSTNAME}:${PORT}` to use depends on the value set for `hostName.enabled`. If `hostName.enabled: false` use the hostname and port where the ingress controller is installed, for example `http://masternode.example.com:30777`. 
	
	If using `hostName.enabled: true` then you can only access via the admin hostname, for example `https://admin.example.com/oamconsole`. **Note**: You can only access via the admin URL if it is currently accessible and routing correctly to the ingress host and port.
	
	
   For example:


   ```bash
   $ curl -v http://masternode.example.com:30777/oamconsole
   ```
   
   The output will look similar to the following. You should receive a `302 Moved Temporarily` message:
   
   ```
   > GET /oamconsole HTTP/1.1
   > Host: masternode.example:30777
   > User-Agent: curl/7.61.1
   > Accept: */*
   >
   < HTTP/1.1 302 Moved Temporarily
   < Date: <DATE>
   < Content-Type: text/html
   < Content-Length: 333
   < Connection: keep-alive
   < Location: http://masternode.example.com:30777/oamconsole/
   < X-Content-Type-Options: nosniff
   < X-Frame-Options: DENY
   <
   <html><head><title>302 Moved Temporarily</title></head>
   <body bgcolor="#FFFFFF">
   <p>This document you requested has moved
   temporarily.</p>
   <p>It's now at <a href="http://masternode.example.com:30777/oamconsole/">http://masternode.example.com:30777/oamconsole/</a>.</p>
   </body></html>
   * Connection #0 to host doc-master.lcma.susengdev2phx.oraclevcn.com left intact
   ```
   
#### Verify that you can access the domain URLs

After setting up the NGINX ingress, verify that the domain applications are accessible as per [Validate Domain URLs ](../validate-domain-urls)


