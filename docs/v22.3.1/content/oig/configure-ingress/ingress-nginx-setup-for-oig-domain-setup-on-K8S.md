---
title: "a. Using an Ingress with NGINX (non-SSL)"
description: "Steps to set up an Ingress for NGINX to direct traffic to the OIG domain (non-SSL)."
---

### Setting up an ingress for NGINX for the OIG domain on Kubernetes (non-SSL)

The instructions below explain how to set up NGINX as an ingress for the OIG domain with non-SSL termination.

**Note**: All the steps below should be performed on the **master** node.

1. [Install NGINX](#install-nginx)

    a. [Configure the repository](#configure-the-repository)

	b. [Create a namespace](#create-a-namespace)

	c. [Install NGINX using helm](#install-nginx-using-helm)

	d. [Setup routing rules for the domain](#setup-routing-rules-for-the-domain)
	
1. [Create an ingress for the domain](#create-an-ingress-for-the-domain)
1. [Verify that you can access the domain URL](#verify-that-you-can-access-the-domain-url)

### Install NGINX

Use helm to install NGINX.

#### Configure the repository

1. Add the Helm chart repository for NGINX using the following command:

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

1. Create a Kubernetes namespace for NGINX by running the following command:

   ```bash
   $ kubectl create namespace nginx
   ```

   The output will look similar to the following:

   ```
   namespace/nginx created
   ```

#### Install NGINX using helm

If you can connect directly to the master node IP address from a browser, then install NGINX with the `--set controller.service.type=NodePort` parameter.

If you are using a Managed Service for your Kubernetes cluster,for example Oracle Kubernetes Engine (OKE) on Oracle Cloud Infrastructure (OCI), and connect from a browser to the Load Balancer IP address, then use the `--set controller.service.type=LoadBalancer` parameter. This instructs the Managed Service to setup a Load Balancer to direct traffic to the NGINX ingress.

1. To install NGINX use the following helm command depending on if you are using `NodePort` or `LoadBalancer`:

   a) Using NodePort

   ```bash
   $ helm install nginx-ingress -n nginx --set controller.service.type=NodePort --set controller.admissionWebhooks.enabled=false stable/ingress-nginx
   ``` 

   The output will look similar to the following:
   
   ```
   NAME: nginx-ingress
   LAST DEPLOYED: Thu 13 Jul 2022 14:13:33 GMT
   NAMESPACE: nginx
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   The ingress-nginx controller has been installed.
   Get the application URL by running these commands:
     export HTTP_NODE_PORT=$(kubectl --namespace nginx get services -o jsonpath="{.spec.ports[0].nodePort}" nginx-ingress-ingress-nginx-controller)
     export HTTPS_NODE_PORT=$(kubectl --namespace nginx get services -o jsonpath="{.spec.ports[1].nodePort}" nginx-ingress-ingress-nginx-controller)
     export NODE_IP=$(kubectl --namespace nginx get nodes -o jsonpath="{.items[0].status.addresses[1].address}")

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

   ```bash
   $ helm install nginx-ingress -n nginx --set controller.service.type=LoadBalancer --set controller.admissionWebhooks.enabled=false stable/ingress-nginx
   ```   

   The output will look similar to the following:

   ```
   NAME: nginx-ingress
   LAST DEPLOYED: Thu Jul 13 14:15:33 2022
   NAMESPACE: nginx
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   The nginx-ingress controller has been installed.
   It may take a few minutes for the LoadBalancer IP to be available.
   You can watch the status by running 'kubectl --namespace nginx get services -o wide -w nginx-ingress-controller'

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

#### Setup routing rules for the domain

1. Setup routing rules by running the following commands:

   ```bash
   $ cd $WORKDIR/kubernetes/charts/ingress-per-domain
   ```
   
   Edit `values.yaml` and change the `domainUID` parameter to match your `domainUID`, for example `domainUID: governancedomain`. Also change `sslType` to `NONSSL`.  The file should look as follows:
   
   ```
   # Load balancer type.  Supported values are: TRAEFIK, NGINX
   type: NGINX

   # Type of Configuration Supported Values are : NONSSL, SSL
   sslType: NONSSL
   
   # TimeOut value to be set for nginx parameters proxy-read-timeout and proxy-send-timeout
   nginxTimeOut: 180

   # TLS secret name if the mode is SSL
   secretName: domain1-tls-cert

   #WLS domain as backend to the load balancer
   wlsDomain:
     domainUID: governancedomain
     adminServerName: AdminServer
     adminServerPort: 7001
     soaClusterName: soa_cluster
     soaManagedServerPort: 8001
     oimClusterName: oim_cluster
     oimManagedServerPort: 14000
   ```


### Create an ingress for the domain

1. Create an Ingress for the domain (`governancedomain-nginx`), in the domain namespace by using the sample Helm chart:

   ```bash
   $ cd $WORKDIR
   $ helm install governancedomain-nginx kubernetes/charts/ingress-per-domain --namespace <namespace> --values kubernetes/charts/ingress-per-domain/values.yaml
   ```
  
   **Note**: The `<workdir>/samples/kubernetes/charts/ingress-per-domain/templates//nginx-ingress-k8s1.19.yaml and nginx-ingress.yaml` has `nginx.ingress.kubernetes.io/enable-access-log` set to `false`. If you want to enable access logs then set this value to `true` before executing the command. Enabling access-logs can cause issues with disk space if not regularly maintained.   
   
   For example:
   
   ```bash
   $ cd $WORKDIR
   $ helm install governancedomain-nginx kubernetes/charts/ingress-per-domain --namespace oigns --values kubernetes/charts/ingress-per-domain/values.yaml
   ```
   
   The output will look similar to the following:

   ```
   $ helm install governancedomain-nginx kubernetes/charts/ingress-per-domain --namespace oigns --values kubernetes/charts/ingress-per-domain/values.yaml
   NAME: governancedomain-nginx
   LAST DEPLOYED:  Thu Jul 13 14:18:23 2022
   NAMESPACE: oigns
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
   $ kubectl get ing -n oigns
   ```
   
   The output will look similar to the following:

   ```
   NAME                     CLASS    HOSTS   ADDRESS   PORTS   AGE
   governancedomain-nginx   <none>   *       x.x.x.x   80      47s
   ```
   
1. Find the NodePort of NGINX using the following command (only if you installed NGINX using NodePort):

   ```bash
   $ kubectl get services -n nginx -o jsonpath=”{.spec.ports[0].nodePort}” nginx-ingress-ingress-nginx-controller
   ```

   The output will look similar to the following:

   ```
   31530
   ```

1. Run the following command to check the ingress:

   ```bash
   $ kubectl describe ing governancedomain-ingress -n <namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl describe ing governancedomain-nginx -n oigns
   ```
   
   The output will look similar to the following:

   ```
   Name:             governancedomain-nginx
   Namespace:        oigns
   Address:
   Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
   Rules:
     Host        Path  Backends
     ----        ----  --------
     *
                 /console                        governancedomain-adminserver:7001 (10.244.2.59:7001)
                 /em                             governancedomain-adminserver:7001 (10.244.2.59:7001)
                 /soa                            governancedomain-cluster-soa-cluster:8001 (10.244.2.60:8001)
                 /integration                    governancedomain-cluster-soa-cluster:8001 (10.244.2.60:8001)
                 /soa-infra                      governancedomain-cluster-soa-cluster:8001 (10.244.2.60:8001)
                 /identity                       governancedomain-cluster-oim-cluster:14000 (10.244.1.25:14000)
                 /admin                          governancedomain-cluster-oim-cluster:14000 (10.244.1.25:14000)
                 /oim                            governancedomain-cluster-oim-cluster:14000 (10.244.1.25:14000)
                 /sysadmin                       governancedomain-cluster-oim-cluster:14000 (10.244.1.25:14000)
                 /workflowservice                governancedomain-cluster-oim-cluster:14000 (10.244.1.25:14000)
                 /xlWebApp                       governancedomain-cluster-oim-cluster:14000 (10.244.1.25:14000)
                 /Nexaweb                        governancedomain-cluster-oim-cluster:14000 (10.244.1.25:14000)
                 /callbackResponseService        governancedomain-cluster-oim-cluster:14000 (10.244.1.25:14000)
                 /spml-xsd                       governancedomain-cluster-oim-cluster:14000 (10.244.1.25:14000)
                 /HTTPClnt                       governancedomain-cluster-oim-cluster:14000 (10.244.1.25:14000)
                 /reqsvc                         governancedomain-cluster-oim-cluster:14000 (10.244.1.25:14000)
                 /iam                            governancedomain-cluster-oim-cluster:14000 (10.244.1.25:14000)
                 /provisioning-callback          governancedomain-cluster-oim-cluster:14000 (10.244.1.25:14000)
                 /CertificationCallbackService   governancedomain-cluster-oim-cluster:14000 (10.244.1.25:14000)
                 /ucs                            governancedomain-cluster-oim-cluster:14000 (10.244.1.25:14000)
                 /FacadeWebApp                   governancedomain-cluster-oim-cluster:14000 (10.244.1.25:14000)
                 /OIGUI                          governancedomain-cluster-oim-cluster:14000 (10.244.1.25:14000)
                 /weblogic                       governancedomain-cluster-oim-cluster:14000 (10.244.1.25:14000)
   Annotations:  kubernetes.io/ingress.class: nginx
                 meta.helm.sh/release-name: governancedomain-nginx
                 meta.helm.sh/release-namespace: oigns
                 nginx.ingress.kubernetes.io/affinity: cookie
                 nginx.ingress.kubernetes.io/enable-access-log: false
   Events:
     Type    Reason  Age   From                      Message
     ----    ------  ----  ----                      -------
     Normal  Sync    35s   nginx-ingress-controller  Scheduled for sync
   ```

1. To confirm that the new ingress is successfully routing to the domain's server pods, run the following command to send a request to the URL for the `WebLogic ReadyApp framework`:

   **Note**: If using a load balancer for your ingress replace `${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}` with `${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}`.

   ```bash
   $ curl -v http://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/weblogic/ready
   ```
   
   For example:

   a) For NodePort
   
   ```bash
   $ curl -v http://masternode.example.com:31530/weblogic/ready
   ```

   b) For LoadBalancer

   ```bash
   $ curl -v http://masternode.example.com:80/weblogic/ready
   ```
   
   The output will look similar to the following:
   
   ```
   $ curl -v http://masternode.example.com:31530/weblogic/ready
   * About to connect() to masternode.example.com port 31530 (#0)
   *   Trying X.X.X.X...
   * Connected to masternode.example.com (X.X.X.X) port 31530 (#0)
   > GET /weblogic/ready HTTP/1.1
   > User-Agent: curl/7.29.0
   > Host: masternode.example.com:31530
   > Accept: */*
   >
   < HTTP/1.1 200 OK
   < Server: nginx/1.19.2
   < Date: Thu Jul 13 14:21:14 2022
   < Content-Length: 0
   < Connection: keep-alive
   <
   * Connection #0 to host masternode.example.com left intact
   ```

### Verify that you can access the domain URL

After setting up the NGINX ingress, verify that the domain applications are accessible through the NGINX ingress port (for example 31530) as per [Validate Domain URLs ]({{< relref "/oig/validate-domain-urls" >}})

