---
title: "With SSL"
draft: false
weight: 2
pre: "<b>ii. </b>"
description: "Steps to set up an Ingress for Traefik to direct traffic to the OIG domain using SSL."
---


### Setting up an ingress for Traefik for the OIG domain on Kubernetes

The instructions below explain how to set up Traefik as an ingress for the OIG domain with SSL termination.

**Note**: All the steps below should be performed on the administrative host.

1. [Install the Traefik repository](#install-the-traefik-repository)

1. [Create a namespace](#create-a-namespace)

1. [Generate a SSL certificate](#generate-a-ssl-certificate)

1. [Create a Kubernetes secret for SSL](#create-a-kubernetes-secret-for-ssl)

1. [Install the Traefik](#install-the-traefik)

1. [Preparing the ingress values.yaml](#preparing-the-ingress-valuesyaml)
	
1. [Creating the ingress](#creating-the-ingress)

1. [Verify that you can access the domain URL](#verify-that-you-can-access-the-domain-url)



#### Install the Traefik repository

1. Add the Helm chart repository for installing Traefik using the following command:

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

1. Create a Kubernetes namespace for Traefik:

   ```bash
   $ kubectl create namespace traefik
   ```

   The output will look similar to the following:

   ```
   namespace/traefik created
   ```
### Generate a SSL certificate

For production environments it is recommended to use a commercially available certificate, traceable to a trusted Certificate Authority. For sandbox environments, you can generate your own self-signed certificates.

#### Using a Third Party CA for Generating Certificates

Generate a private key and certificate signing request (CSR) using a tool of your choice. Send the CSR to your certificate authority (CA) to generate the certificate.

If you are configuring the ingress controller to use SSL, you must use a wildcard certificate to prevent issues with the Common Name (CN) in the certificate. A wildcard certificate is a certificate that protects the primary domain and it's sub-domains. It uses a wildcard character (`*`) in the CN, for example `*.yourdomain.com`.

How you generate the key and certificate signing request for a wildcard certificate will depend on your Certificate Authority. Contact your Certificate Authority vendor for details.

In order to configure the ingress controller for SSL you require the following files:

+ The private key for your certificate, for example `oig.key`.
+ The certificate, for example `oig.crt` in PEM format.
+ The trusted certificate authority (CA) certificate, for example `rootca.crt` in PEM format.
+ If there are multiple trusted CA certificates in the chain, you need all the certificates in the chain, for example `rootca1.crt`, `rootca2.crt` etc.

Once you have received the files, perform the following steps:

1. On the administrative host, create a $WORKDIR>/ssl directory and navigate to the folder:

   ```
	$ mkdir $WORKDIR>/ssl
	$ cd $WORKDIR>/ssl
   ```
1. Copy the files listed above to the `$WORKDIR>/ssl` directory.

1. If your CA has multiple certificates in a chain, create a `bundle.pem` that contains all the CA certificates:
   
   ```
   $ cat rootca.pem rootca1.pem rootca2.pem >>bundle.pem
   ```
	
#### Using Self-Signed Certificates

1. On the administrative host, create a $WORKDIR>/ssl directory and navigate to the folder:

   ```
	$ mkdir $WORKDIR>/ssl
	$ cd $WORKDIR>/ssl
   ```
	
1. Run the following command to create the self-signed certificate:

   ```
   $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout oig.key -out oig.crt -subj "/CN=<hostname>"
   ```
	
	For example:
	
   ```
   $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout oig.key -out oig.crt -subj "/CN=oig.example.com"
   ```

   The output will look similar to the following:

   ```
   Generating a 2048 bit RSA private key
   ..........................................+++
   .......................................................................................................+++
   writing new private key to 'oig.key'
   -----
	```



  
### Create a Kubernetes secret for SSL

1. Create a secret for SSL containing the SSL certificate by running the following command:

   ```bash
   $ kubectl -n traefik create secret tls <domain_uid>-tls-cert --key $WORKDIR/ssl/oig.key --cert $WORKDIR/ssl/oig.crt
   ```
   
   For example:
   
   ```bash
   $ kubectl -n traefik create secret tls governancedomain-tls-cert --key /scratch/OIGK8S/ssl/oig.key --cert /scratch/OIGK8S/ssl/oig.crt
   ```
   
   The output will look similar to the following:
   
   ```
   secret/governancedomain-tls-cert created
   ```

1. Confirm that the secret is created by running the following command:

   ```bash
   $ kubectl get secret <domain_uid>-tls-cert -o yaml -n oigns
   ```
   
   For example:
   
   ```bash
   $ kubectl get secret governancedomain-tls-cert -o yaml -n oigns
   ```
   
   The output will look similar to the following:
   
   ```
   apiVersion: v1
   data:
     tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURGVENDQWYyZ0F3SUJBZ0lKQUl3ZjVRMWVxZnljTUEwR0NTcUdTSWIzRFFFQkN3VUFNQ0V4SHpBZEJnTlYKQkFNTUZtUmxiakF4WlhadkxuVnpMbTl5WVdOc1pTNWpiMjB3SGhjTk1qQXdPREV3TVRReE9UUXpXaGNOTWpFdwpPREV3TVRReE9UUXpXakFoTVI4d0hRWURWUVFEREJaa1pXNHdNV1YyYnk1MWN5NXZjbUZqYkdVdVkyOXRNSUlCCklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUEyY0lpVUhwcTRVZzBhaGR6aXkycHY2cHQKSVIza2s5REd2eVRNY0syaWZQQ2dtUU5CdHV6VXNFN0l4c294eldITmU5RFpXRXJTSjVON3Ym1lTzJkMVd2NQp1aFhzbkFTbnkwY1N9xVDNQSlpDVk1MK0llZVFKdnhaVjZaWWU4V2FFL1NQSGJzczRjYy9wcG1mc3pxCnErUi83cXEyMm9ueHNHaE9vQ1h1TlQvMFF2WXVzMnNucGtueWRKRHUxelhGbDREYkFIZGMvamNVK0NPWWROeS8KT3Iza2JIV0FaTkR4OWxaZUREOTRmNXZLcUF2V0FkSVJZa2UrSmpNTHg0VHo2ZlM0VXoxbzdBSTVuSApPQ1ZMblV5U0JkaGVuWTNGNEdFU0wwbnorVlhFWjRWVjRucWNjRmo5cnJ0Q29pT1BBNlgvNGdxMEZJbi9Qd0lECkFRQUJvMUF3VGpBZEJnTlZIUTRFRmdRVWw1VnVpVDBDT0xGTzcxMFBlcHRxSC9DRWZyY3dId1lEVlIwakJCZ3cKRm9BVWw1VnVpVDBDT0xGTzcxMFBlcHRxSC9DRWZyY3dEQVlEVlIwVEJBVXdBd0VCL3pBTkJna3Foa2lHOXcwQgpBUXNGQUFPQ0FRRUFXdEN4b2ZmNGgrWXZEcVVpTFFtUnpqQkVBMHJCOUMwL1FWOG9JQzJ3d1hzYi9KaVNuMHdOCjNMdHppejc0aStEbk1yQytoNFQ3enRaSkc3NVluSGRKcmxQajgzVWdDLzhYTlFCSUNDbTFUa3RlVU1jWG0reG4KTEZEMHpReFhpVzV0N1FHcWtvK2FjeTlhUnUvN3JRMXlNSE9HdVVkTTZETzErNXF4cTdFNXFMamhyNEdKejV5OAoraW8zK25UcUVKMHFQOVRocG96RXhBMW80OEY0ZHJybWdqd3ROUldEQVpBYmYyV1JNMXFKWXhxTTJqdU1FQWNsCnFMek1TdEZUQ2o1UGFTQ0NUV1VEK3ZlSWtsRWRpaFdpRm02dzk3Y1diZ0lGMlhlNGk4L2szMmF1N2xUTDEvd28KU3Q2dHpsa20yV25uUFlVMzBnRURnVTQ4OU02Z1dybklpZz09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
     tls.key: LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUV1d0lCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktVd2dnU2hBZ0VBQW9JQkFRRFp3aUpRZW1yaFNEUnEKRjNPTExhbS9xbTBoSGVTVDBNYS9KTXh3cmFKODhLQ1pBMEcyN05Td1Rzakd5akhOWWMxNzBObFlTdEluazN1cApkdVo0N1ozVmEvbTZGZXljQktmTFJ4SW84NnIwSmhQYzhsa0pVd3Y0aDU1QW0vRmxYcGxoN3hab1Q5SThkdXl6Cmh4eittbVorek9xcjVIL3VxcmJhaWZHd2FFNmdKZTQxUC9SQzlpNnpheWVtU2ZKMGtPN1hOY1dYZ05zQWQxeisKTnhUNEk1aDAzTDg2dmVSc2RZQmswUEgyVmw0TVAzaC9tOHFWdW5mK1NvQzlZQjBoRmlSNzRtTXd2SGhQUHA5TApoVFBXanNBam1jYzRKVXVkVEpJRjJGNmRqY1hnWVJJdlNmUDVWY1JuaFZYaWVweHdXUDJ1dTBLaUk0OERwZi9pCkNyUVVpZjgvQWdNQkFBRUNnZjl6cnE2TUVueTFNYWFtdGM2c0laWU1QSDI5R2lSVVlwVXk5bG1sZ3BqUHh3V0sKUkRDay9Td0FmZG9yd1Q2ejNVRk1oYWJ4UU01a04vVjZFYkJlamQxT15bjdvWTVEQWJRRTR3RG9SZWlrVApONndWU0FrVC92Z1RXc1RqRlY1bXFKMCt6U2ppOWtySkZQNVNRN1F2cUswQ3BHRlNhVjY2dW8ycktiNmJWSkJYCkxPZmZPMytlS0tVazBaTnE1Q1NVQk9mbnFoNVFJSGdpaDNiMTRlNjB6bndrNWhaMHBHZE9BQm9aTkoKZ21lanUyTEdzVWxXTjBLOVdsUy9lcUllQzVzQm9jaWlocmxMVUpGWnpPRUV6LzErT2cyemhmT29yTE9rMTIrTgpjQnV0cTJWQ2I4ZFJDaFg1ZzJ0WnBrdzgzcXN5RSt3M09zYlQxa0VDZ1lFQTdxUnRLWGFONUx1SENvWlM1VWhNCm1WcnYxTEg0eGNhaDJIZnMksrMHJqQkJONGpkZkFDMmF3R3ZzU1EyR0lYRzVGYmYyK0pwL1kxbktKOEgKZU80MzNLWVgwTDE4NlNNLzFVay9HSEdTek1CWS9KdGR6WkRrbTA4UnBwaTl4bExTeDBWUWtFNVJVcnJJcTRJVwplZzBOM2RVTHZhTVl1UTBrR2dncUFETUNnWUVBNlpqWCtjU2VMZ1BVajJENWRpUGJ1TmVFd2RMeFNPZDFZMUFjCkUzQ01YTWozK2JxQ3BGUVIrTldYWWVuVmM1QiszajlSdHVnQ0YyTkNSdVdkZWowalBpL243UExIRHdCZVY0bVIKM3VQVHJmamRJbFovSFgzQ2NjVE94TmlaajU4VitFdkRHNHNHOGxtRTRieStYRExIYTJyMWxmUk9sUVRMSyswVgpyTU93eU1VQ2dZRUF1dm14WGM4NWxZRW9hU0tkU0cvQk9kMWlYSUtmc2VDZHRNT2M1elJ0UXRsSDQwS0RscE54CmxYcXBjbVc3MWpyYzk1RzVKNmE1ZG5xTE9OSFZoWW8wUEpmSXhPU052RXI2MTE5NjRBMm5sZXRHYlk0M0twUkEKaHBPRHlmdkZoSllmK29kaUJpZFUyL3ZBMCtUczNSUHJzRzBSOUVDOEZqVDNaZVhaNTF1R0xPa0NnWUFpTmU0NwplQjRxWXdrNFRsMTZmZG5xQWpaQkpLR05xY2c1V1R3alpMSkp6R3owdCtuMkl4SFd2WUZFSjdqSkNmcHFsaDlqCmlDcjJQZVV3K09QTlNUTG1JcUgydzc5L1pQQnNKWXVsZHZ4RFdGVWFlRXg1aHpkNDdmZlNRRjZNK0NHQmthYnIKVzdzU3R5V000ZFdITHpDaGZMS20yWGJBd0VqNUQrbkN1WTRrZVFLQmdFSkRHb0puM1NCRXcra2xXTE85N09aOApnc3lYQm9mUW1lRktIS2NHNzFZUFhJbTRlV1kyUi9KOCt5anc5b1FJQ3o5NlRidkdSZEN5QlJhbWhoTmFGUzVyCk9MZUc0ejVENE4zdThUc0dNem9QcU13KzBGSXJiQ3FzTnpGWTg3ekZweEdVaXZvRWZLNE82YkdERTZjNHFqNGEKNmlmK0RSRSt1TWRMWTQyYTA3ekoKLS0tLS1FTkQgUFJJVkFURSBLRVktLS0tLQo=
   kind: Secret
   metadata:
     creationTimestamp: "<DATE>"
     name: governancedomain-tls-cert
     namespace: oigns
     resourceVersion: "3319899"
     uid: 274cc960-281a-494c-a3e3-d93c3abd051f
   type: kubernetes.io/tls

   ```
   


### Install the Traefik

If you can connect directly to a worler node IP address from a browser, then install Traefik with the `--set service.spec.type=NodePort` parameter.

If you are using a Managed Service for your Kubernetes cluster, for example Oracle Kubernetes Engine (OKE) on Oracle Cloud Infrastructure (OCI), and connect from a browser to the Load Balancer IP address, then use the `--set service.spec.type=LoadBalancer` parameter. This instructs the Managed Service to setup a Load Balancer to direct traffic to the Traefik ingress.

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

   
### Preparing the ingress values.yaml

1. Setup routing rules by running the following commands:

   ```bash
   $ cd $WORKDIR/kubernetes/charts/ingress-per-domain
   ```
   
   Edit `values.yaml` and change the `domainUID` parameter to match your `domainUID`, for example `domainUID: governancedomain`. Change `sslType` to `SSL`.  The file should look as follows:
  
   ```
   # Load balancer type. Supported values are: NGINX, TRAEFIK
   type: TRAEFIK

   # SSL configuration Type. Supported Values are : NONSSL,SSL
   sslType: SSL

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

#### Creating the ingress

1. Create an Ingress for the domain (`governancedomain-traefik`), in the domain namespace by using the sample Helm chart:

   ```bash
   $ cd $WORKDIR
   $ helm install governancedomain-traefik kubernetes/charts/ingress-per-domain --namespace <domain_namespace> --values kubernetes/charts/ingress-per-domain/values.yaml
   ```
   
   For example:
   
   ```bash
   $ cd $WORKDIR
   $ helm install governancedomain-traefik kubernetes/charts/ingress-per-domain --namespace oigns --values kubernetes/charts/ingress-per-domain/values.yaml
   ```

   The output will look similar to the following:

   ```
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


1. To confirm that the new ingress is successfully routing to the domain's server pods, run the following command to send a request to the URL for the `WebLogic ReadyApp framework`:

   **Note**: If using a load balancer for your ingress replace `${HOSTNAME}:${PORT}` with `${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}`.

   ```bash
   $ curl -v -k https://${HOSTNAME}:${PORT}/weblogic/ready
   ```
   
   For example:
   
   ```bash
   $ curl -v -k  https://oig.example.com:30443/weblogic/ready
   ```
   
   The output will look similar to the following:
   
   ```
   $ curl -v -k https://oig.example.com:30443/weblogic/ready
   * About to connect() to X.X.X.X port 30433 (#0)
   *   Trying X.X.X.X...
   * Connected to oig.example.com (X.X.X.X) port 30433 (#0)
   * Initializing NSS with certpath: sql:/etc/pki/nssdb
   * skipping SSL peer certificate verification
   * SSL connection using TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
   * Server certificate:
   *       subject: CN=oig.example.com
   *       start date: <DATE>
   *       expire date: <DATE>
   *       common name: oig.example.com
   *       issuer: CN=oig.example.com
   > GET /weblogic/ready HTTP/1.1
   > User-Agent: curl/7.29.0
   > Host: X.X.X.X:30433
   > Accept: */*
   >
   < HTTP/1.1 200 OK
   < Content-Length: 0
   < Connection: keep-alive
   <
   * Connection #0 to host X.X.X.X left intact
   ```

#### Verify that you can access the domain URL

After setting up the Traefik ingress, verify that the domain applications are accessible through the Traefik ingress port (for example 30433) as per [Validate Domain URLs ](../../../validate-domain-urls)
