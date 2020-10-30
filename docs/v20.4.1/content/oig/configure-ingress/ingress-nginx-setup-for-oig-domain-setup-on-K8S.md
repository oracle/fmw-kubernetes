---
title: "a. Using an Ingress with NGINX (non-SSL)"
description: "Steps to set up an Ingress for NGINX to direct traffic to the OIG domain (non-SSL)."
---

### Setting Up an ingress for NGINX for the OIG Domain on Kubernetes (non-SSL)

The instructions below explain how to set up NGINX as an ingress for the OIG domain with non-SSL termination.

**Note**: All the steps below should be performed on the **master** node.

1. [Install NGINX](#install-nginx)
    1. [Configure the repository](#configure-the-repository)
	1. [Create a Namespace](#create-a-namespace)
	1. [Install NGINX using helm](#install-nginx-using-helm)
	1. [Setup Routing Rules for the Domain](#setup-routing-rules-for-the-domain)
1. [Create an Ingress for the Domain](#create-an-ingress-for-the-domain)
1. [Verify that You can Access the Domain URL](#verify-that-you-can-access-the-domain-url)
1. [Cleanup](#cleanup)

### Install NGINX

Use helm to install NGINX.

#### Configure the repository

1. Add the Helm chart repository for NGINX using the following command:

   ```bash
   $ helm repo add stable https://kubernetes.github.io/ingress-nginx
   ```
   
   The output will look similar to the following:
   
   ```
   $ helm repo add stable https://kubernetes.github.io/ingress-nginx
   "stable" has been added to your repositories
   ```

1. Update the repository using the following command:

   ```bash
   $ helm repo update
   ```
   
   The output will look similar to the following:
   
   ```bash
   Hang tight while we grab the latest from your chart repositories...
   ...Successfully got an update from the "stable" chart repository
   Update Complete. Happy Helming!
   ```

#### Create a Namespace 

1. Create a Kubernetes namespace for NGINX by running the following command:

   ```
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

   ```
   $ helm install nginx-ingress -n nginx --set controller.service.type=NodePort --set controller.admissionWebhooks.enabled=false stable/ingress-nginx
   ```    

   The output will look similar to the following:
   
   ```
   NAME: nginx-ingress
   LAST DEPLOYED: Tue Sep 29 08:07:03 2020
   NAMESPACE: nginx
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   The nginx-ingress controller has been installed.
   Get the application URL by running these commands:
     export HTTP_NODE_PORT=$(kubectl --namespace nginx get services -o jsonpath="{.spec.ports[0].nodePort}" nginx-ingress-controller)
     export HTTPS_NODE_PORT=$(kubectl --namespace nginx get services -o jsonpath="{.spec.ports[1].nodePort}" nginx-ingress-controller)
     export NODE_IP=$(kubectl --namespace nginx get nodes -o jsonpath="{.items[0].status.addresses[1].address}")

     echo "Visit http://$NODE_IP:$HTTP_NODE_PORT to access your application via HTTP."
     echo "Visit https://$NODE_IP:$HTTPS_NODE_PORT to access your application via HTTPS."

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

   b) Using LoadBalancer

   ```
   $ helm install nginx-ingress -n nginx --set controller.service.type=LoadBalancer --set controller.admissionWebhooks.enabled=false stable/ingress-nginx
   ```

   The output will look similar to the following:

   ```
   NAME: nginx-ingress
   LAST DEPLOYED: Tue Sep 29 08:07:03 2020
   NAMESPACE: nginx
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   The nginx-ingress controller has been installed.
   It may take a few minutes for the LoadBalancer IP to be available.
   You can watch the status by running 'kubectl --namespace nginx get services -o wide -w nginx-ingress-controller'

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

#### Setup Routing Rules for the Domain

1. Setup routing rules by running the following commands:

   ```
   $ cd <work directory>/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain
   $ cp values.yaml values.yaml.orig
   $ vi values.yaml
   ```

   Edit `values.yaml` and ensure that `type=NGINX` and `tls=NONSSL` are set, for example:
   
   ```
   $ cat values.yaml
   # Copyright 2020 Oracle Corporation and/or its affiliates. 
   # Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


   # Default values for ingress-per-domain.
   # This is a YAML-formatted file.
   # Declare variables to be passed into your templates.

   # Load balancer type.  Supported values are: VOYAGER, NGINX
   type: NGINX
   # Type of Configuration Supported Values are : NONSSL,SSL
   # tls: NONSSL
   tls: NONSSL
   # TLS secret name if the mode is SSL
   secretName: domain1-tls-cert


   # WLS domain as backend to the load balancer
   wlsDomain:
     domainUID: oimcluster
     oimClusterName: oim_cluster
     soaClusterName: soa_cluster
     soaManagedServerPort: 8001
     oimManagedServerPort: 14000
     adminServerName: adminserver
     adminServerPort: 7001

   # Traefik specific values
   # traefik:
     # hostname used by host-routing
     # hostname: idmdemo.m8y.xyz

   # Voyager specific values
   voyager:
     # web port
     webPort: 30305
     # stats port
     statsPort: 30315
   ```


### Create an Ingress for the Domain

1. Create an Ingress for the domain (`oimcluster-nginx`), in the domain namespace by using the sample Helm chart:

   ```
   $ cd <work directory>/weblogic-kubernetes-operator
   $ helm install oimcluster-nginx kubernetes/samples/charts/ingress-per-domain --namespace <namespace> --values kubernetes/samples/charts/ingress-per-domain/values.yaml
   ```
  
   **Note**: The `<work directory>/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/templates/nginx-ingress.yaml` has `nginx.ingress.kubernetes.io/enable-access-log` set to `false`. If you want to enable access logs then set this value to `true` before executing the command. Enabling access-logs can cause issues with disk space if not regularly maintained.   
   
   For example:
   
   ```
   $ cd /scratch/OIGDockerK8S/weblogic-kubernetes-operator
   $ helm install oimcluster-nginx kubernetes/samples/charts/ingress-per-domain --namespace oimcluster --values kubernetes/samples/charts/ingress-per-domain/values.yaml
   ```
   
   The output will look similar to the following:

   ```
   $ helm install oimcluster-nginx kubernetes/samples/charts/ingress-per-domain --namespace oimcluster --values kubernetes/samples/charts/ingress-per-domain/values.yaml
   NAME: oimcluster-nginx
   LAST DEPLOYED:  Tue Sep 29 08:10:06 2020
   NAMESPACE: oimcluster
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   ```

1. Run the following command to show the ingress is created successfully:

   ```
   $ kubectl get ing -n <domain_namespace>
   ```
   
   For example:
   
   ```
   $ kubectl get ing -n oimcluster
   ```
   
   The output will look similar to the following:

   ```
   NAME               CLASS    HOSTS   ADDRESS   PORTS   AGE
   oimcluster-nginx   <none>   *                 80      47s
   ```
   
1. Find the NodePort of NGINX using the following command (only if you installed NGINX using NodePort):

   ```
   $ kubectl get services -n nginx -o jsonpath=”{.spec.ports[0].nodePort}” nginx-ingress-ingress-nginx-controller
   ```

   The output will look similar to the following:

   ```
   31578$
   ```

1. Run the following command to check the ingress:

   ```
   $ kubectl describe ing access-ingress -n <namespace>
   ```
   
   For example:
   
   ```
   $ kubectl describe ing oimcluster-nginx -n oimcluster
   ```
   
   The output will look similar to the following:

   ```
   Name:             oimcluster-nginx
   Namespace:        oimcluster
   Address:          10.97.68.171
   Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
   Rules:
     Host        Path  Backends
     ----        ----  --------
     *
                 /console       oimcluster-adminserver:7001 (10.244.1.42:7001)
                 /em            oimcluster-adminserver:7001 (10.244.1.42:7001)
                 /soa           oimcluster-cluster-soa-cluster:8001 (10.244.1.43:8001)
                 /integration   oimcluster-cluster-soa-cluster:8001 (10.244.1.43:8001)
                 /soa-infra     oimcluster-cluster-soa-cluster:8001 (10.244.1.43:8001)
                                oimcluster-cluster-oim-cluster:14000 (10.244.1.44:14000)
   Annotations:  meta.helm.sh/release-name: oimcluster-nginx
                 meta.helm.sh/release-namespace: oimcluster
   Events:
     Type    Reason  Age   From                      Message
     ----    ------  ----  ----                      -------
     Normal  CREATE  53s   nginx-ingress-controller  Ingress oimcluster/oimcluster-nginx
     Normal  UPDATE  42s   nginx-ingress-controller  Ingress oimcluster/oimcluster-nginx
   ```

1. To confirm that the new Ingress is successfully routing to the domain's server pods, run the following command to send a request to the URL for the "WebLogic ReadyApp framework":

   ```
   $ curl -v http://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/weblogic/ready
   ```
   
   For example:

   a) For NodePort
   
   ```
   $ curl -v http://masternode.example.com:31578/weblogic/ready
   ```

   b) For LoadBalancer

   ```
   $ curl -v http://masternode.example.com:80/weblogic/ready
   ```
   
   The output will look similar to the following:
   
   ```
   $ curl -v -k http://masternode.example.com:31578/weblogic/ready
   * About to connect() to masternode.example.com port 31578 (#0)
   *   Trying 12.345.67.890...
   * Connected to masternode.example.com (12.345.67.890) port 31578 (#0)
   > GET /weblogic/ready HTTP/1.1
   > User-Agent: curl/7.29.0
   > Host: masternode.example.com:31578
   > Accept: */*
   >
   < HTTP/1.1 200 OK
   < Server: nginx/1.19.2
   < Date: Tue, 29 Sep 2020 15:16:20 GMT
   < Content-Length: 0
   < Connection: keep-alive
   <
   * Connection #0 to host masternode.example.com left intact
   ```

### Verify that You can Access the Domain URL

After setting up the NGINX ingress, verify that the domain applications are accessible through the NGINX ingress port (for example 31578) as per [Validate Domain URLs ]({{< relref "/oig/validate-domain-urls" >}})

### Cleanup

If you need to remove the NGINX Ingress (for example to setup NGINX with SSL) then remove the ingress with the following commands:

```
$ helm delete oimcluster-nginx -n oimcluster

$ helm delete nginx-ingress -n nginx

$ kubectl delete namespace nginx

```

The output will look similar to the following:

```
$ helm delete oimcluster-nginx -n oimcluster
release "oimcluster-nginx" uninstalled

$ helm delete nginx-ingress -n nginx
release "nginx-ingress" uninstalled

$ kubectl delete namespace nginx
namespace "nginx" deleted
$
```