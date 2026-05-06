---
title: "With non-SSL"
draft: false
weight: 1
pre: "<b>i. </b>"
description: "Steps to set up an Ingress for Traefik to direct traffic to the OIG domain (non-SSL)."
---

### Setting up an ingress for Traefik for the OIG domain on Kubernetes (non-SSL)

The instructions below explain how to set up Traefik as an ingress for the OIG domain with non-SSL termination.

**Note**: All the steps below should be performed on the administrative host.

1. [Install Traefik](#install-traefik)

    a. [Configure the repository](#configure-the-repository)

	b. [Create a namespace](#create-a-namespace)

	c. [Install Traefik using helm](#install-traefik-using-helm)

	d. [Setup routing rules for the domain](#setup-routing-rules-for-the-domain)
	
1. [Create an ingress for the domain](#create-an-ingress-for-the-domain)
1. [Verify that you can access the domain URL](#verify-that-you-can-access-the-domain-url)

### Install Traefik

Use helm to install Traefik.

#### Configure the repository

1. Add the Helm chart repository for Traefik using the following command:

   ```bash
   $ helm repo add traefik https://helm.traefik.io/traefik --force-update
   ```
   
   The output will look similar to the following:
   
   ```
   "traefik" has been added to your repositories
   ```

1. Update the repository using the following command:

   ```bash
   $ helm repo update
   ```
   
   The output will look similar to the following:
   
   ```
   Hang tight while we grab the latest from your chart repositories...
   ...Successfully got an update from the "traefik" chart repository
   Update Complete. Happy Helming!
   ```

#### Create a namespace 

1. Create a Kubernetes namespace for Traefik by running the following command:

   ```bash
   $ kubectl create namespace traefik
   ```

   The output will look similar to the following:

   ```
   namespace/traefik created
   ```

#### Install Traefik using helm

If you can connect directly to the master or worker node IP address from a browser, then install Traefik with the `--set service.spec.type=NodePort` parameter.

If you are using a Managed Service for your Kubernetes cluster,for example Oracle Kubernetes Engine (OKE) on Oracle Cloud Infrastructure (OCI), and connect from a browser to the Load Balancer IP address, then use the `--set service.spec.type=LoadBalancer` parameter. This instructs the Managed Service to setup a Load Balancer to direct traffic to the Traefik ingress.

1. Create a `$WORKDIR/kubernetes/charts/traefik/traefik-ingress-values-override.yaml` that contains the following:
    The configuration below deploys an ingress using LoadBalancer. If you prefer to use NodePort, change the configuration accordingly. For more details about Traefik configuration see: [Traefik Ingress Controller](https://github.com/traefik/traefik-helm-chart/blob/master/traefik/VALUES.md).

    ```yaml
    ingressRoute:
      dashboard:
        enabled: true
    providers:
      kubernetesCRD:
        enabled: true
      kubernetesIngress:
        enabled: true
    ports:
      traefik:
        port: 9000
        exposedPort: 9000
        protocol: TCP
      web:
        port: 8000
        exposedPort: 30305
        nodePort: 30305
        protocol: TCP
      websecure:
        expose:
          default: false
    service:
      spec:
        type: LoadBalancer
    ```

1. To install and configure Traefik ingress, run the following command:

   ```bash
   $ helm install traefik --namespace <namespace> \
   --values traefik-ingress-values-override.yaml \
   traefik/traefik
   ```

        where:

        + `<namespace>` is your namespace, for example `traefik`.
        + `ports.web.exposedPort` is the HTTP port that you want the controller to listen on, for example `30305`.
        + `service.spec.type` is the controller type. If using NodePort set to `NodePort`.

#### Setup routing rules for the domain

1. Setup routing rules by running the following commands:

   ```bash
   $ cd $WORKDIR/kubernetes/charts/ingress-per-domain
   ```
   
   Edit `values.yaml` and change the `domainUID` parameter to match your `domainUID`, for example `domainUID: governancedomain`. Also change `type` to `TRAEFIK` and `sslType` to `NONSSL`.  The file should look as follows:
   
   ```
   # Load balancer type. Supported values are: NGINX, TRAEFIK
   type: TRAEFIK

   # SSL configuration Type. Supported Values are : NONSSL,SSL
   sslType: NONSSL

   # domainType. Supported values are: oim
   domainType: oim

   #WLS domain as backend to the load balancer
   wlsDomain:
     domainUID: governancedomain
     adminServerName: AdminServer
     adminServerPort: 7001
     adminServerSSLPort:
     soaClusterName: soa_cluster
     soaManagedServerPort: 8001
     soaManagedServerSSLPort:
     oimClusterName: oim_cluster
     oimManagedServerPort: 14000
     oimManagedServerSSLPort:

   # Host  specific values
   hostName:
     enabled: false
     admin:
     runtime:
     internal:

   ```


### Create an ingress for the domain

1. Create an Ingress for the domain (`governancedomain-traefik`), in the domain namespace by using the sample Helm chart:

   ```bash
   $ cd $WORKDIR
   $ helm install governancedomain-traefik kubernetes/charts/ingress-per-domain --namespace <namespace> --values kubernetes/charts/ingress-per-domain/values.yaml
   ```
  
   For example:
   
   ```bash
   $ cd $WORKDIR
   $ helm install governancedomain-traefik kubernetes/charts/ingress-per-domain --namespace oigns --values kubernetes/charts/ingress-per-domain/values.yaml
   ```
   
   The output will look similar to the following:

   ```
   $ helm install governancedomain-traefik kubernetes/charts/ingress-per-domain --namespace oigns --values kubernetes/charts/ingress-per-domain/values.yaml
   NAME: governancedomain-traefik
   LAST DEPLOYED:  <DATE>
   NAMESPACE: oigns
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   ```

1. Run the following command to show the ingress is created successfully:

   ```bash
   $ kubectl get ingressRoute -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl get ingressRoute -n oigns
   ```
   
   The output will look similar to the following:

   ```
   NAME          AGE
   oim-traefik   45s
   ```
   
1. Find the NodePort of Traefik using the following command (only if you installed Traefik using NodePort):

   ```bash
   $ kubectl get services -n traefik -o jsonpath=”{.spec.ports[0].nodePort}” traefik-traefik
   ```

   The output will look similar to the following:

   ```
   30240
   ```

1. Run the following command to check the ingressRoute resources:

   ```bash
   $ kubectl describe ingressRoute oim-traefik -n <namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl describe ingressRoute oim-traefik -n oigns
   ```
   
   The output will look similar to the following:

   ```
	$ kubectl describe IngressRoute -n traefik oim-traefik
	Name:         oim-traefik
	Namespace:    traefik
	Labels:       app.kubernetes.io/managed-by=Helm
				  weblogic.resourceVersion=domain-v2
	Annotations:  kubernetes.io/ingress.class: traefik
				  meta.helm.sh/release-name: governancedomain-traefik
				  meta.helm.sh/release-namespace: traefik
	API Version:  traefik.io/v1alpha1
	Kind:         IngressRoute
	Metadata:
	  Creation Timestamp:  2026-04-29T11:33:37Z
	  Generation:          1
	  Resource Version:    5165
	  UID:                 4198b263-c4f1-428d-ad87-fe034897af05
	Spec:
	  Entry Points:
		web
	  Routes:
		Kind:   Rule
		Match:  PathPrefix(`/console`)
		Services:
		  Name:  oim-adminserver
		  Port:  7001
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
		Kind:             Rule
		Match:            PathPrefix(`/consolehelp`)
		Services:
		  Name:  oim-adminserver
		  Port:  7001
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
		Kind:             Rule
		Match:            PathPrefix(`/em`)
		Services:
		  Name:  oim-adminserver
		  Port:  7001
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
		Kind:             Rule
		Match:            PathPrefix(`/ws_utc`)
		Services:
		  Name:  oim-cluster-soa-cluster
		  Port:  7003
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
		Kind:             Rule
		Match:            PathPrefix(`/soa`)
		Services:
		  Name:  oim-cluster-soa-cluster
		  Port:  7003
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
		Kind:             Rule
		Match:            PathPrefix(`/integration`)
		Services:
		  Name:  oim-cluster-soa-cluster
		  Port:  7003
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
		Kind:             Rule
		Match:            PathPrefix(`/soa-infra`)
		Services:
		  Name:  oim-cluster-soa-cluster
		  Port:  7003
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
		Kind:             Rule
		Match:            PathPrefix(`/identity`)
		Services:
		  Name:  oim-cluster-oim-cluster
		  Port:  14000
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
		Kind:             Rule
		Match:            PathPrefix(`/admin`)
		Services:
		  Name:  oim-cluster-oim-cluster
		  Port:  14000
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
		Kind:             Rule
		Match:            PathPrefix(`/dms`)
		Services:
		  Name:  oim-adminserver
		  Port:  7001
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
		Kind:             Rule
		Match:            PathPrefix(`/oim`)
		Services:
		  Name:  oim-cluster-oim-cluster
		  Port:  14000
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
		Kind:             Rule
		Match:            PathPrefix(`/sysadmin`)
		Services:
		  Name:  oim-cluster-oim-cluster
		  Port:  14000
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
		Kind:             Rule
		Match:            PathPrefix(`/workflowservice`)
		Services:
		  Name:  oim-cluster-oim-cluster
		  Port:  14000
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
		Kind:             Rule
		Match:            PathPrefix(`/callbackResponseService`)
		Services:
		  Name:  oim-cluster-oim-cluster
		  Port:  14000
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
		Kind:             Rule
		Match:            PathPrefix(`/spml-xsd`)
		Services:
		  Name:  oim-cluster-oim-cluster
		  Port:  14000
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
		Kind:             Rule
		Match:            PathPrefix(`/HTTPClnt`)
		Services:
		  Name:  oim-cluster-oim-cluster
		  Port:  14000
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
		Kind:             Rule
		Match:            PathPrefix(`/reqsvc`)
		Services:
		  Name:  oim-cluster-oim-cluster
		  Port:  14000
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
		Kind:             Rule
		Match:            PathPrefix(`/iam`)
		Services:
		  Name:  oim-cluster-oim-cluster
		  Port:  14000
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
		Kind:             Rule
		Match:            PathPrefix(`/provisioning-callback`)
		Services:
		  Name:  oim-cluster-oim-cluster
		  Port:  14000
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
		Kind:             Rule
		Match:            PathPrefix(`/CertificationCallbackService`)
		Services:
		  Name:  oim-cluster-oim-cluster
		  Port:  14000
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
		Kind:             Rule
		Match:            PathPrefix(`/ucs`)
		Services:
		  Name:  oim-cluster-oim-cluster
		  Port:  14000
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
		Kind:             Rule
		Match:            PathPrefix(`/FacadeWebApp`)
		Services:
		  Name:  oim-cluster-oim-cluster
		  Port:  14000
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
		Kind:             Rule
		Match:            PathPrefix(`/OIGUI`)
		Services:
		  Name:  oim-cluster-oim-cluster
		  Port:  14000
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
		Kind:             Rule
		Match:            PathPrefix(`/weblogic`)
		Services:
		  Name:  oim-cluster-oim-cluster
		  Port:  14000
		  Sticky:
			Cookie:
			  Http Only:  true
			  Name:       sticky-cookie
	Events:               <none>

   ```

1. To confirm that the new ingressRoute's are successfully routing to the domain's server pods, run the following command to send a request to the URL for the `WebLogic ReadyApp framework`:

   **Note**: If using a load balancer for your ingress replace `${HOSTNAME}:${PORT}` with `${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}`.

   ```bash
   $ curl -v http://${HOSTNAME}:${PORT}/weblogic/ready
   ```
   
   For example:

   a) For NodePort
   
   ```bash
   $ curl -v http://oam.example.com:30240/weblogic/ready
   ```

   b) For LoadBalancer

   ```bash
   $ curl -v http://oam.example.com:30305/weblogic/ready
   ```
   
   The output will look similar to the following:
   
   ```
   $ curl -v http://oam.example.com:30240/weblogic/ready
   * About to connect() to oam.example.com port 30240 (#0)
   *   Trying X.X.X.X...
   * Connected to oam.example.com (X.X.X.X) port 30240 (#0)
   > GET /weblogic/ready HTTP/1.1
   > Host: oam.example.com:30240
   > User-Agent: curl/7.61.1
   > Accept: */*
   > 
   < HTTP/1.1 200 OK
   < Content-Length: 0
   < Date: Sun, 03 May 2026 12:20:21 GMT
   < Set-Cookie: sticky-cookie=ee8af81e43bb3e7b; Path=/; HttpOnly
   < 
   * Connection #0 to host oam.example.com left intact
   ```

### Verify that you can access the domain URL

After setting up the Traefik ingressRoutes, verify that the domain applications are accessible through the traefik port (for example 30240) as per [Validate Domain URLs ](../../../validate-domain-urls)

