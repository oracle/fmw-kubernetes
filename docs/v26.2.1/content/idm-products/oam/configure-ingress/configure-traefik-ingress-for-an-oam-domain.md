+++
title = "b. Configure an Traefik ingress for an OAM domain"
description=  "Steps to set up an Ingress for Traefik to direct traffic to the OAM domain."
+++

## Configuring an ingress for Traefik for the OAM Domain

The instructions below explain how to set up Traefik as an ingress for the OAM domain.

The ingress can be configured in the following ways:

+ Without SSL
+ With SSL
+ OAM URI's are accessible from all hosts
+ OAM URI's are accessible using virtual hostnames only


The option you choose will depend on the architecture you are configuring. For example, if you have an architecture such as [Oracle HTTP Server on an independent Kubernetes cluster](../../../ohs/introduction/#oracle-http-server-on-an-independent-kubernetes-cluster), where SSL is terminated at the load balancer, then you would configure the ingress without SSL.

In almost all circumstances, the ingress should be configured to be accessible from all hosts (using `host.enabled: false` in the `values.yaml`). You can only configure ingress to use virtual hostnames only (using `host.enabled: true` in the `values.yaml`), if all of the following criteria are met:

+ SSL is terminated at the load balancer
+ The SSL port is 8443
+ You have separate hostnames for OAM administration URL's (for example `https://admin.example.com/console`), and OAM runtime URL's (for example `https://runtime.example.com/oam/server`).  

See, [Prepare the values.yaml for the ingress](#prepare-the-valuesyaml-for-the-ingress) for more details.


The steps to generate an ingress are as follows:

1. [Install Traefik](#install-traefik)
1. [Generate a SSL Certificate](#generate-a-ssl-certificate)
1. [Create an ingress controller](#create-an-ingress-controller)
1. [Prepare the values.yaml for the ingress](#prepare-the-valuesyaml-for-the-ingress)
1. [Create the Ingress](#create-the-ingress)
1. [Verify that you can access the domain URL](#verify-that-you-can-access-the-domain-urls)


  
### Install Traefik

Use helm to install Traefik.

1. Add the helm chart repository for Traefik using the following command:

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
   Update Complete. ⎈ Happy Helming!⎈
   ```

### Create a Kubernetes namespace for Traefik

Create a Kubernetes namespace for the Traefik deployment by running the following command:

```
kubectl create namespace <namespace>
```

For example:

```
kubectl create namespace traefik
```

The output will look similar to the following:

```
namespace/traefik created
```


### Generate a SSL Certificate

This section should only be followed if you want to configure your ingress for SSL.

For production environments it is recommended to use a commercially available certificate, traceable to a trusted Certificate Authority.

For sandbox environments, you can generate your own self-signed certificates.

**Note**: Using self-signed certificates you will get certificate errors when accessing the ingress controller via a browser.

#### Using a Third Party CA for Generating Certificates

If you are configuring the ingress controller to use SSL, you must use a wildcard certificate to prevent issues with the Common Name (CN) in the certificate. A wildcard certificate is a certificate that protects the primary domain and it's sub-domains. It uses a wildcard character (*) in the CN, for example `*.yourdomain.com`.

How you generate the key and certificate signing request for a wildcard certificate will depend on your Certificate Authority. Contact your Certificate Authority vendor for details.

In order to configure the ingress controller for SSL you require the following files:

+ The private key for your certificate, for example `oam.key`.
+ The certificate, for example oam.crt in PEM format.
+ The trusted certificate authority (CA) certificate, for example `rootca.crt` in PEM format.
+ If there are multiple trusted CA certificates in the chain, you need all the certificates in the chain, for example `rootca1.crt`, `rootca2.crt` etc.

Once you have received the files, perform the following steps:

1. On the administrative host, create a `$WORKDIR>/ssl` directory and navigate to the folder:

   ```
   mkdir $WORKDIR>/ssl
   cd $WORKDIR>/ssl
   ```	

1. Copy the files listed above to the `$WORKDIR>/ssl` directory.

1. If your CA has multiple certificates in a chain, create a `bundle.pem` that contains all the CA certificates:

   ```
   cat rootca.pem rootca1.pem rootca2.pem >>bundle.pem
   ```

#### Using Self-Signed Certificates

1. On the administrative host, create a `$WORKDIR>/ssl` directory and navigate to the folder:

   ```
   mkdir $WORKDIR>/ssl
   cd $WORKDIR>/ssl
   ```	

1. Run the following command to create the self-signed certificate:

   ```bash
   $ mkdir <workdir>/ssl
   $ cd <workdir>/ssl
   $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout oam.key -out oam.crt -subj "/CN=<hostname>"
   ```
   
   For example:
   
   ```bash
   $ mkdir /scratch/OAMK8S/ssl
   $ cd /scratch/OAMK8S/ssl
   $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout oam.key -out oam.crt -subj "/CN=oam.example.com"
   ```
   
   The output will look similar to the following:
   
   ```
   Generating a 2048 bit RSA private key
   ..........................................+++
   .......................................................................................................+++
   writing new private key to 'tls.key'
   -----
   ```

### Create a Kubernetes Secret for SSL


Run the following command to create a Kubernetes secret for SSL:

   ```bash
   $ kubectl -n traefik create secret tls <domain_uid>-tls-cert --key $WORKDIR>/ssl/oam.key --cert $WORKDIR>/ssl/oam.crt
   ```
   
	**Note**: If you have multiple CA certificates in the chain use `--cert <workdir>/bundle.crt`.
	
   For example:
   
   ```bash
   $ kubectl -n traefik create secret tls accessdomain-tls-cert --key /scratch/OAMK8S/ssl/oam.key --cert /scratch/OAMK8S/ssl/oam.crt
   ```
   
   The output will look similar to the following:
   
   ```
   secret/accessdomain-tls-cert created
   ```
	
	
### Install the ingress controller 

In this section you install the ingress controller. 

If you can connect directly to a worker node IP address from a browser, then install NGINX with the `--set service.spec.type=NodePort` parameter.

If you are using a Managed Service for your Kubernetes cluster, for example Oracle Kubernetes Engine (OKE) on Oracle Cloud Infrastructure (OCI), and connect from a browser to the Load Balancer IP address, then use the `--set service.spec.type=LoadBalancer` parameter. This instructs the Managed Service to setup a Load Balancer to direct traffic to the Traefik resources.

The instructions below use `--set service.spec.type=NodePort`. If using a managed service, change to `--set service.spec.type=LoadBalancer`.

The following sections show how to install the ingress with SSL or without SSL. Follow the relevant section based on your architecture.


#### Configure an ingress controller with SSL

1. Create a `$WORKDIR/kubernetes/kubernetes/charts/traefik/traefik-ingress-values-override.yaml` that contains the following: 
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
        port: 8443
        exposedPort: 30443
        nodePort: 30443
        protocol: TCP
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
	+ `ports.websecure.exposedPort` is the HTTPS port that you want the controller to listen on, for example `30443`.
	+ `service.spec.type` is the controller type. If using NodePort set to `NodePort`. 
	

#### Configure an ingress controller without SSL

1. Create a `$WORKDIR/kubernetes/kubernetes/charts/traefik/traefik-ingress-values-override.yaml` that contains the following:
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
 
   
### Prepare the values.yaml for the ingress

1. Navigate to the following directory and make a copy of the values.yaml:

   ```
   $ cd $WORKDIR/kubernetes/charts/ingress-per-domain
   $ cp values.yaml $WORKDIR/
   ```
      
1. Edit the `$WORKDIR/kubernetes/charts/ingress-per-domain/values.yaml` and modify the following parameters if required:


   + `domainUID:` - If you created your OAM domain with anything other than the default `accessdomain`, change accordingly.
   + `type:` - For Traefik, set to `TRAEFIK`. 
   + `sslType:` - Values supported are `SSL` and `NONSSL`. If you created your ingress controller to use SSL then set to `SSL`, otherwise set to `NONSSL`.
   + `hostName.enabled: false` - This should be set to `false` in almost all circumstances. Setting to `false` allows OAM URI's to be accessible from all hosts. Setting to `true` configures ingress for virtual hostnames only. See [Configuring an ingress for NGINX for the OAM Domain](#configuring-an-ingress-for-nginx-for-the-oam-domain) for full details of the criteria that must be met set to this value to `true`.
	+ `hostName.admin: <hostname>` - Should only be set if `hostName.enabled: true` and `sslType: NONSSL`. This should be set to the `hostname.domain` of the URL you access OAM administration URL's from, for example if you access the OAM Administration Console via `https://admin.example.com/oamconsole`, then set to `admin.example.com`.
   + `hostName.runtime: <hostname>` - Should only be set if `hostName.enabled: true`. This should be set to the `hostname.domain` of the URL you access OAM runtime URL's from, for example if the `oam/server` URI is accessed via `https://runtime.example.com/oam/server`, then set to `runtime.example.com`.


	
	The following shows example files based on different configuration types:
	
	
	{{%expand "Click here to see a values.yaml for SSL" %}}
   ```
   # Load balancer type.  Supported values are: NGINX, TRAEFIK
   type: TRAEFIK

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
   # Load balancer type.  Supported values are: NGINX, TRAEFIK
   type: TRAEFIK

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
   # Load balancer type.  Supported values are: NGINX, TRAEFIK
   type: TRAEFIK

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
   $ helm install oam-traefik kubernetes/charts/ingress-per-domain --namespace <domain_namespace> --values kubernetes/charts/ingress-per-domain/values.yaml
   ```
   
   For example:
   
   ```bash
   $ cd $WORKDIR
   $ helm install oam-traefik kubernetes/charts/ingress-per-domain --namespace oamns --values kubernetes/charts/ingress-per-domain/values.yaml
   ```
   
   The output will look similar to the following:
   
   ```
   NAME: oam-traefik
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
   accessdomain-traefik <none>   *                 80      5s
   ```
   
	If `hostname.enabled: true`, the output will look similar to the following:
	
	```
	NAME                 CLASS   HOSTS                   ADDRESS   PORTS   AGE
   oamadmin-ingress     traefik   admin.example.com                 80      14s
   oamruntime-ingress   traefik   runtime.example.com               80      14s
   ```
	
1. Run the following command to check the ingress:

   
   
   ```bash
   $ kubectl describe ing <ingress> -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl describe ing accessdomain-traefik -n oamns
   ```
   
   The output will look similar to the following for `accessdomain-traefik`:
   
   ```
   Name:             accessdomain-traefik
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
   Annotations:  meta.helm.sh/release-name: oam-traefik
                 meta.helm.sh/release-namespace: oamns
                 kubernetes.io/ingress.class: traefik
   Events:       <none>
	  Type    Reason  Age   From                      Message
     ----    ------  ----  ----                      -------
     Normal  Sync    33s   nginx-ingress-controller  Scheduled for sync
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
	
	The `${HOSTNAME}:${PORT}` to use depends on the value set for `hostName.enabled`. If `hostName.enabled: false` use the hostname and port where the ingress controller is installed, for example `http://oam.example.com:30777`. 
	
	If using `hostName.enabled: true` then you can only access via the admin hostname, for example `https://admin.example.com/oamconsole`. **Note**: You can only access via the admin URL if it is currently accessible and routing correctly to the ingress host and port.
	
	
   For example:


   ```bash
   $ curl -v http://oam.example.com:30777/oamconsole
   ```
   
   The output will look similar to the following. You should receive a `302 Moved Temporarily` message:
   
   ```
   > GET /oamconsole HTTP/1.1
   > Host: oam.example:30777
   > User-Agent: curl/7.61.1
   > Accept: */*
   >
   < HTTP/1.1 302 Moved Temporarily
   < Date: <DATE>
   < Content-Type: text/html
   < Content-Length: 333
   < Connection: keep-alive
   < Location: http://oam.example.com:30777/oamconsole/
   < X-Content-Type-Options: nosniff
   < X-Frame-Options: DENY
   <
   <html><head><title>302 Moved Temporarily</title></head>
   <body bgcolor="#FFFFFF">
   <p>This document you requested has moved
   temporarily.</p>
   <p>It's now at <a href="http://oam.example.com:30777/oamconsole/">http://oam.example.com:30777/oamconsole/</a>.</p>
   </body></html>
   * Connection #0 to host oam.example.com left intact
   ```
   
#### Verify that you can access the domain URLs

After setting up the Traefik ingress, verify that the domain applications are accessible as per [Validate Domain URLs ](../../validate-domain-urls)


