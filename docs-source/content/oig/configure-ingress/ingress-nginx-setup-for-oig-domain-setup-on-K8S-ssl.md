---
title: "b. Using an Ingress with NGINX (SSL)"
description: "Steps to set up an Ingress for NGINX to direct traffic to the OIG domain (SSL)."
---

### Setting Up an Ingress for NGINX for the OIG Domain on Kubernetes

The instructions below explain how to set up NGINX as an ingress for the OIG domain with SSL termination.

**Note**: All the steps below should be performed on the **master** node.

1. [Create a SSL Certificate](#create-a-ssl-certificate)
    1. [Generate SSL Certificate](#generate-ssl-certificate)
	1. [Create a Kubernetes Secret for SSL](#create-a-kubernetes-secret-for-ssl)
1. [Install NGINX](#install-nginx)
    1. [Configure the repository](#configure-the-repository)
	1. [Create a Namespace](#create-a-namespace)
	1. [Install NGINX using helm](#install-nginx-using-helm)
1. [Create an Ingress for the Domain](#create-an-ingress-for-the-domain)
1. [Verify that You can Access the Domain URL](#verify-that-you-can-access-the-domain-url)
1. [Cleanup](#cleanup)

### Create a SSL Certificate

#### Generate SSL Certificate

1. Generate a private key and certificate signing request (CSR) using a tool of your choice. Send the CSR to your certificate authority (CA) to generate the certificate.

   If you want to use a certificate for testing purposes you can generate a self signed certificate using openssl:

   ```
   $ mkdir <work directory>/ssl
   $ cd <work directory>/ssl
   $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=<nginx-hostname>"
   ```
   
   For example:
   
   ```
   $ mkdir /scratch/OIGDockerK8S/ssl
   $ cd /scratch/OIGDockerK8S/ssl
   $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=masternode.example.com"
   ```

   **Note**: The `CN` should match the host.domain of the master node in order to prevent hostname problems during certificate verification.
   
   The output will look similar to the following:
   
   ```
   $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=masternode.example.com"
   Generating a 2048 bit RSA private key
   ..........................................+++
   .......................................................................................................+++
   writing new private key to 'tls.key'
   -----
   ```

#### Create a Kubernetes Secret for SSL

1. Create a secret for SSL containing the SSL certificate by running the following command:

   ```
   $ kubectl -n oigns create secret tls <domain_id>-tls-cert --key <work directory>/tls.key --cert <work directory>/tls.crt
   ```
   
   For example:
   
   ```
   $ kubectl -n oigns create secret tls governancedomain-tls-cert --key /scratch/OIGDockerK8S/ssl/tls.key --cert /scratch/OIGDockerK8S/ssl/tls.crt
   ```
   
   The output will look similar to the following:
   
   ```
   $ kubectl -n oigns create secret tls governancedomain-tls-cert --key /scratch/OIGDockerK8S/ssl/tls.key --cert /scratch/OIGDockerK8S/ssl/tls.crt
   secret/governancedomain-tls-cert created
   $
   ```

1. Confirm that the secret is created by running the following command:

   ```
   $ kubectl get secret governancedomain-tls-cert -o yaml -n oigns
   ```
   
   The output will look similar to the following:
   
   ```
   apiVersion: v1
   data:
     tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURGVENDQWYyZ0F3SUJBZ0lKQUl3ZjVRMWVxZnljTUEwR0NTcUdTSWIzRFFFQkN3VUFNQ0V4SHpBZEJnTlYKQkFNTUZtUmxiakF4WlhadkxuVnpMbTl5WVdOc1pTNWpiMjB3SGhjTk1qQXdPREV3TVRReE9UUXpXaGNOTWpFdwpPREV3TVRReE9UUXpXakFoTVI4d0hRWURWUVFEREJaa1pXNHdNV1YyYnk1MWN5NXZjbUZqYkdVdVkyOXRNSUlCCklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUEyY0lpVUhwcTRVZzBhaGR6aXkycHY2cHQKSVIza2s5REd2eVRNY0syaWZQQ2dtUU5CdHV6VXNFN0l4c294eldITmU5RFpXRXJTSjVON3FYYm1lTzJkMVd2NQp1aFhzbkFTbnkwY1NLUE9xVDNQSlpDVk1MK0llZVFKdnhaVjZaWWU4V2FFL1NQSGJzczRjYy9wcG1mc3pxCnErUi83cXEyMm9ueHNHaE9vQ1h1TlQvMFF2WXVzMnNucGtueWRKRHUxelhGbDREYkFIZGMvamNVK0NPWWROeS8KT3Iza2JIV0FaTkR4OWxaZUREOTRmNXZLcUF2V0FkSVJZa2UrSmpNTHg0VHo2ZlM0VXoxbzdBSTVuSApPQ1ZMblV5U0JkaGVuWTNGNEdFU0wwbnorVlhFWjRWVjRucWNjRmo5cnJ0Q29pT1BBNlgvNGdxMEZJbi9Qd0lECkFRQUJvMUF3VGpBZEJnTlZIUTRFRmdRVWw1VnVpVDBDT0xGTzcxMFBlcHRxSC9DRWZyY3dId1lEVlIwakJCZ3cKRm9BVWw1VnVpVDBDT0xGTzcxMFBlcHRxSC9DRWZyY3dEQVlEVlIwVEJBVXdBd0VCL3pBTkJna3Foa2lHOXcwQgpBUXNGQUFPQ0FRRUFXdEN4b2ZmNGgrWXZEcVVpTFFtUnpqQkVBMHJCOUMwL1FWOG9JQzJ3d1hzYi9KaVNuMHdOCjNMdHppejc0aStEbk1yQytoNFQ3enRaSkc3NVluSGRKcmxQajgzVWdDLzhYTlFCSUNDbTFUa3RlVU1jWG0reG4KTEZEMHpReFhpVzV0N1FHcWtvK2FjeTlhUnUvN3JRMXlNSE9HdVVkTTZETzErNXF4cTdFNXFMamhyNEdKejV5OAoraW8zK25UcUVKMHFQOVRocG96RXhBMW80OEY0ZHJybWdqd3ROUldEQVpBYmYyV1JNMXFKWXhxTTJqdU1FQWNsCnFMek1TdEZUQ2o1UGFTQ0NUV1VEK3ZlSWtsRWRpaFdpRm02dzk3Y1diZ0lGMlhlNGk4L2szMmF1N2xUTDEvd28KU3Q2dHpsa20yV25uUFlVMzBnRURnVTQ4OU02Z1dybklpZz09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
     tls.key: LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUV1d0lCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktVd2dnU2hBZ0VBQW9JQkFRRFp3aUpRZW1yaFNEUnEKRjNPTExhbS9xbTBoSGVTVDBNYS9KTXh3cmFKODhLQ1pBMEcyN05Td1Rzakd5akhOWWMxNzBObFlTdEluazN1cApkdVo0N1ozVmEvbTZGZXljQktmTFJ4SW84NnIwSmhQYzhsa0pVd3Y0aDU1QW0vRmxYcGxoN3hab1Q5SThkdXl6Cmh4eittbVorek9xcjVIL3VxcmJhaWZHd2FFNmdKZTQxUC9SQzlpNnpheWVtU2ZKMGtPN1hOY1dYZ05zQWQxeisKTnhUNEk1aDAzTDg2dmVSc2RZQmswUEgyVmw0TVAzaC9tOHFWdW5mK1NvQzlZQjBoRmlSNzRtTXd2SGhQUHA5TApoVFBXanNBam1jYzRKVXVkVEpJRjJGNmRqY1hnWVJJdlNmUDVWY1JuaFZYaWVweHdXUDJ1dTBLaUk0OERwZi9pCkNyUVVpZjgvQWdNQkFBRUNnZjl6cnE2TUVueTFNYWFtdGM2c0laWU1QSDI5R2lSVVlwVXk5bG1sZ3BqUHh3V0sKUkRDay9Td0FmZG9yd1Q2ejNVRk1oYWJ4UU01a04vVjZFYkJlamQxT15bjdvWTVEQWJRRTR3RG9SZWlrVApONndWU0FrVC92Z1RXc1RqRlY1bXFKMCt6U2ppOWtySkZQNVNRN1F2cUswQ3BHRlNhVjY2dW8ycktiNmJWSkJYCkxPZmZPMytlS0tVazBaTnE1Q1NVQk9mbnFoNVFJSGdpaDNiMTRlNjB6bndrNWhaMHBHZE9BQm9aTkoKZ21lanUyTEdzVWxXTjBLOVdsUy9lcUllQzVzQm9jaWlocmxMVUpGWnpPRUV6LzErT2cyemhmT29yTE9rMTIrTgpjQnV0cTJWQ2I4ZFJDaFg1ZzJ0WnBrdzgzcXN5RSt3M09zYlQxa0VDZ1lFQTdxUnRLWGFONUx1SENvWlM1VWhNCm9Hak1WcnYxTEg0eGNhaDJITmZnMksrMHJqQkJONGpkZkFDMmF3R3ZzU1EyR0lYRzVGYmYyK0pwL1kxbktKOEgKZU80MzNLWVgwTDE4NlNNLzFVay9HSEdTek1CWS9KdGR6WkRrbTA4UnBwaTl4bExTeDBWUWtFNVJVcnJJcTRJVwplZzBOM2RVTHZhTVl1UTBrR2dncUFETUNnWUVBNlpqWCtjU2VMZ1BVajJENWRpUGJ1TmVFd2RMeFNPZDFZMUFjCkUzQ01YTWozK2JxQ3BGUVIrTldYWWVuVmM1QiszajlSdHVnQ0YyTkNSdVdkZWowalBpL243UExIRHdCZVY0bVIKM3VQVHJmamRJbFovSFgzQ2NjVE94TmlaajU4VitFdkRHNHNHOGxtRTRieStYRExIYTJyMWxmUk9sUVRMSyswVgpyTU93eU1VQ2dZRUF1dm14WGM4NWxZRW9hU0tkU0cvQk9kMWlYSUtmc2VDZHRNT2M1elJ0UXRsSDQwS0RscE54CmxYcXBjbVc3MWpyYzk1RzVKNmE1ZG5xTE9OSFZoWW8wUEpmSXhPU052RXI2MTE5NjRBMm5sZXRHYlk0M0twUkEKaHBPRHlmdkZoSllmK29kaUJpZFUyL3ZBMCtUczNSUHJzRzBSOUVDOEZqVDNaZVhaNTF1R0xPa0NnWUFpTmU0NwplQjRxWXdrNFRsMTZmZG5xQWpaQkpLR05xY2c1V1R3alpMSkp6R3owdCtuMkl4SFd2WUZFSjdqSkNmcHFsaDlqCmlDcjJQZVV3K09QTlNUTG1JcUgydzc5L1pQQnNKWXVsZHZ4RFdGVWFlRXg1aHpkNDdmZlNRRjZNK0NHQmthYnIKVzdzU3R5V000ZFdITHpDaGZMS20yWGJBd0VqNUQrbkN1WTRrZVFLQmdFSkRHb0puM1NCRXcra2xXTE85N09aOApnc3lYQm9mUW1lRktIS2NHNzFZUFhJbTRlV1kyUi9KOCt5anc5b1FJQ3o5NlRidkdSZEN5QlJhbWhoTmFGUzVyCk9MZUc0ejVENE4zdThUc0dNem9QcU13KzBGSXJiQ3FzTnpGWTg3ekZweEdVaXZvRWZLNE82YkdERTZjNHFqNGEKNmlmK0RSRSt1TWRMWTQyYTA3ekoKLS0tLS1FTkQgUFJJVkFURSBLRVktLS0tLQo=
   kind: Secret
   metadata:
     creationTimestamp: "2020-09-29T15:51:22Z"
     managedFields:
     - apiVersion: v1
       fieldsType: FieldsV1
       fieldsV1:
         f:data:
           .: {}
           f:tls.crt: {}
           f:tls.key: {}
         f:type: {}
       manager: kubectl
       operation: Update
       time: "2020-09-29T15:51:22Z"
     name: governancedomain-tls-cert
     namespace: oigns
     resourceVersion: "1291036"
     selfLink: /api/v1/namespaces/oigns/secrets/governancedomain-tls-cert
     uid: a127e5fd-705b-43e1-ab56-590834efda5e
   type: kubernetes.io/tls
   ```
   
### Install NGINX

Use helm to install NGINX.

#### Configure the repository

1. Add the Helm chart repository for installing NGINX using the following command:

   ```
   $ helm repo add stable https://kubernetes.github.io/ingress-nginx
   ```
   
   The output will look similar to the following:
   
   ```
   "stable" has been added to your repositories
   ```

1. Update the repository using the following command:

   ```
   $ helm repo update
   ```
   
   The output will look similar to the following:
   
   ```
   Hang tight while we grab the latest from your chart repositories...
   ...Successfully got an update from the "stable" chart repository
   Update Complete. Happy Helming!
   ```

#### Create a Namespace

1. Create a Kubernetes namespace for NGINX:

   ```
   $ kubectl create namespace nginxssl
   ```

   The output will look similar to the following:

   ```
   namespace/nginxssl created
   ```

#### Install NGINX using helm

If you can connect directly to the master node IP address from a browser, then install NGINX with the `--set controller.service.type=NodePort` parameter.

If you are using a Managed Service for your Kubernetes cluster, for example Oracle Kubernetes Engine (OKE) on Oracle Cloud Infrastructure (OCI), and connect from a browser to the Load Balancer IP address, then use the `--set controller.service.type=LoadBalancer` parameter. This instructs the Managed Service to setup a Load Balancer to direct traffic to the NGINX ingress.

1. To install NGINX use the following helm command depending on if you are using `NodePort` or `LoadBalancer`:

   a) Using NodePort

   ```
   $ helm install nginx-ingress -n nginxssl --set controller.extraArgs.default-ssl-certificate=oigns/governancedomain-tls-cert  --set controller.service.type=NodePort --set controller.admissionWebhooks.enabled=false stable/ingress-nginx --version=3.34.0
   ```    

   The output will look similar to the following:
   
   ```
   $ helm install nginx-ingress -n nginxssl --set controller.extraArgs.default-ssl-certificate=oigns/governancedomain-tls-cert  --set controller.service.type=NodePort --set controller.admissionWebhooks.enabled=false stable/ingress-nginx --version=3.34.0
   NAME: nginx-ingress
   LAST DEPLOYED: Tue Sep 29 08:53:30 2020
   NAMESPACE: nginxssl
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   The nginx-ingress controller has been installed.
   Get the application URL by running these commands:
     export HTTP_NODE_PORT=$(kubectl --namespace nginxssl get services -o jsonpath="{.spec.ports[0].nodePort}" nginx-ingress-controller)
     export HTTPS_NODE_PORT=$(kubectl --namespace nginxssl get services -o jsonpath="{.spec.ports[1].nodePort}" nginx-ingress-controller)
     export NODE_IP=$(kubectl --namespace nginxssl get nodes -o jsonpath="{.items[0].status.addresses[1].address}")

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
   $ helm install nginx-ingress -n nginxssl --set controller.extraArgs.default-ssl-certificate=oigns/governancedomain-tls-cert  --set controller.service.type=LoadBalancer --set controller.admissionWebhooks.enabled=false stable/ingress-nginx --version=3.34.0
   ```    

   The output will look similar to the following:
   
   ```
   $ helm install nginx-ingress -n nginxssl --set controller.extraArgs.default-ssl-certificate=oigns/governancedomain-tls-cert  --set controller.service.type=LoadBalancer --set controller.admissionWebhooks.enabled=false stable/ingress-nginx --version=3.34.0
   NAME: nginx-ingress
   LAST DEPLOYED: Tue Sep 29 08:53:30 2020
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

#### Setup Routing Rules for the Domain

1. Setup routing rules by running the following commands:

   ```
   $ cd <work directory>/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain
   $ cp values.yaml values.yaml.orig
   $ vi values.yaml
   ```

1. Edit `values.yaml` and ensure that the values `type=NGINX`, `tls=SSL` and `secretName=governancedomain-tls-cert` are set. Change the `domainUID` to the value of the domain e.g `governancedomain`, for example:
   
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
   tls: SSL
   # TLS secret name if the mode is SSL
   secretName: governancedomain-tls-cert


   # WLS domain as backend to the load balancer
   wlsDomain:
     domainUID: governancedomain
     oimClusterName: oim_cluster
     soaClusterName: soa_cluster
     soaManagedServerPort: 8001
     oimManagedServerPort: 14000
     adminServerName: adminserver
     adminServerPort: 7001

   # Voyager specific values
   voyager:
     # web port
     webPort: 30305
     # stats port
     statsPort: 30315
   ```

#### Create an Ingress for the Domain

1. Create an Ingress for the domain (`governancedomain-nginx`), in the domain namespace by using the sample Helm chart:

   ```
   $ cd <work directory>/weblogic-kubernetes-operator
   $ helm install governancedomain-nginx kubernetes/samples/charts/ingress-per-domain --namespace oigns --values kubernetes/samples/charts/ingress-per-domain/values.yaml
   ```
   
   **Note**: The `<work directory>/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/templates/nginx-ingress.yaml` has `nginx.ingress.kubernetes.io/enable-access-log` set to `false`. If you want to enable access logs then set this value to `true` before executing the command. Enabling access-logs can cause issues with disk space if not regularly maintained. 
	
   For example:
   
   ```
   $ cd /scratch/OIGDockerK8S/weblogic-kubernetes-operator
   $ helm install governancedomain-nginx kubernetes/samples/charts/ingress-per-domain --namespace oigns --values kubernetes/samples/charts/ingress-per-domain/values.yaml
   ```

   The output will look similar to the following:

   ```
   NAME: governancedomain-nginx
   LAST DEPLOYED: Tue Sep 29 08:56:38 2020
   NAMESPACE: oigns
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   ```

1. Run the following command to show the ingress is created successfully:

   ```
   $ kubectl get ing -n <namespace>
   ```
   
   For example:
   
   ```
   $ kubectl get ing -n oigns
   ```
   
   The output will look similar to the following:

   ```
   NAME               CLASS    HOSTS   ADDRESS   PORTS   AGE
   governancedomain-nginx   <none>   *                 80      49s
   ```
   
1. Find the node port of NGINX using the following command:

   ```
   $ kubectl get services -n nginxssl -o jsonpath="{.spec.ports[1].nodePort}" nginx-ingress-ingress-nginx-controller
   ```

   The output will look similar to the following:

   ```
   32033$
   ```

1. Run the following command to check the ingress:

   ```
   $ kubectl describe ing governancedomain-nginx -n <namespace>
   ```
   
   For example:
   
   ```
   $ kubectl describe ing governancedomain-nginx -n oigns
   ```
   
   The output will look similar to the following:

   ```
   Name:             governancedomain-nginx
   Namespace:        oigns
   Address:          10.103.131.225
   Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
   Rules:
     Host        Path  Backends
     ----        ----  --------
     *
                 /console       governancedomain-adminserver:7001 (10.244.1.42:7001)
                 /em            governancedomain-adminserver:7001 (10.244.1.42:7001)
                 /soa           governancedomain-cluster-soa-cluster:8001 (10.244.1.43:8001)
                 /integration   governancedomain-cluster-soa-cluster:8001 (10.244.1.43:8001)
                 /soa-infra     governancedomain-cluster-soa-cluster:8001 (10.244.1.43:8001)
                                governancedomain-cluster-oim-cluster:14000 (10.244.1.44:14000)
   Annotations:  kubernetes.io/ingress.class: nginx
                 meta.helm.sh/release-name: governancedomain-nginx
                 meta.helm.sh/release-namespace: oigns
                 nginx.ingress.kubernetes.io/configuration-snippet:
                   more_set_input_headers "X-Forwarded-Proto: https";
                   more_set_input_headers "WL-Proxy-SSL: true";
                 nginx.ingress.kubernetes.io/ingress.allow-http: false
                 nginx.ingress.kubernetes.io/proxy-buffer-size: 2000k
   Events:
     Type    Reason  Age   From                      Message
     ----    ------  ----  ----                      -------
     Normal  CREATE  5m4s  nginx-ingress-controller  Ingress oigns/governancedomain-nginx
     Normal  UPDATE  4m9s  nginx-ingress-controller  Ingress oigns/governancedomain-nginx
   ```

1. To confirm that the new Ingress is successfully routing to the domain's server pods, run the following command to send a request to the URL for the "WebLogic ReadyApp framework":

   ```
   $ curl -v -k https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/weblogic/ready
   ```
   
   For example:
   
   ```
   $ curl -v -k  https://masternode.example.com:32033/weblogic/ready
   ```
   
   The output will look similar to the following:
   
   ```
   $ curl -v https://masternode.example.com:32033/weblogic/ready
   * About to connect() to 12.345.678.9 port 32033 (#0)
   *   Trying 12.345.678.9...
   * Connected to 12.345.678.9 (12.345.678.9) port 32033 (#0)
   * Initializing NSS with certpath: sql:/etc/pki/nssdb
   * skipping SSL peer certificate verification
   * SSL connection using TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
   * Server certificate:
   *       subject: CN=masternode.example.com
   *       start date: Sep 29 14:52:35 2020 GMT
   *       expire date: Sep 29 14:52:35 2021 GMT
   *       common name: masternode.example.com
   *       issuer: CN=masternode.example.com
   > GET /weblogic/ready HTTP/1.1
   > User-Agent: curl/7.29.0
   > Host: 12.345.678.9:32033
   > Accept: */*
   >
   < HTTP/1.1 200 OK
   < Server: nginx/1.19.1
   < Date: Tue, 29 Sep 2020 16:10:10 GMT
   < Content-Length: 0
   < Connection: keep-alive
   < Strict-Transport-Security: max-age=15724800; includeSubDomains
   <
   * Connection #0 to host 12.345.678.9 left intact
   ```

#### Verify that You can Access the Domain URL

After setting up the NGINX ingress, verify that the domain applications are accessible through the NGINX ingress port (for example 32033) as per [Validate Domain URLs ]({{< relref "/oig/validate-domain-urls" >}})

#### Cleanup

If you need to remove the NGINX Ingress then remove the ingress with the following commands:

```
$ helm delete governancedomain-nginx -n oigns
$ helm delete nginx-ingress -n nginxssl
$ kubectl delete namespace nginxssl
```

The output will look similar to the following:

```
$ helm delete governancedomain-nginx -n oigns
release "governancedomain-nginx" uninstalled

$ helm delete nginx-ingress -n nginxssl
release "nginx-ingress" uninstalled

$ kubectl delete namespace nginxssl
namespace "nginxssl" deleted
```