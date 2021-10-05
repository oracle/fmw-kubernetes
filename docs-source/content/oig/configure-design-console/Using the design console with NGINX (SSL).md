---
title: "b. Using Design Console with NGINX(SSL)"
weight: 2
description: "Configure Design Console with NGINX(SSL)."
---

Configure an NGINX ingress (SSL) to allow Design Console to connect to your Kubernetes cluster.

#### Generate SSL Certificate

**Note**: If already using NGINX with SSL for OIG you can skip this section:

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


### Add the NGINX ingress using helm

**Note**: If already using NGINX with SSL for OIG you can skip this section:

1. Add the Helm chart repository for NGINX using the following command:

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
   ...Successfully got an update from the "stable" chart repository
   Update Complete. Happy Helming!
   ```

1. Create a Kubernetes namespace for NGINX:

   ```
   $ kubectl create namespace nginxssl
   ```

   The output will look similar to the following:

   ```
   namespace/nginxssl created

### Install NGINX ingress using helm

Install a NGINX ingress for the Design Console:

If you can connect directly to the master node IP address from a browser, then install NGINX with the `--set controller.service.type=NodePort` parameter.

If you are using a Managed Service for your Kubernetes cluster,for example Oracle Kubernetes Engine (OKE) on Oracle Cloud Infrastructure (OCI), and connect from a browser to the Load Balancer IP address, then use the `--set controller.service.type=LoadBalancer` parameter. This instructs the Managed Service to setup a Load Balancer to direct traffic to the NGINX ingress.

1. To install NGINX use the following helm command depending on if you are using `NodePort` or `LoadBalancer`:

   a) Using NodePort

   ```
   $ helm install nginx-dc-operator-ssl -n nginxssl --set controller.extraArgs.default-ssl-certificate=oigns/governancedomain-tls-cert --set controller.service.type=NodePort --set controller.admissionWebhooks.enabled=false --set controller.service.nodePorts.https=30321 --set controller.ingressClass=nginx-designconsole stable/ingress-nginx --version=3.34.0
   ```
   The output will look similar to the following:

   ```
   LAST DEPLOYED: Wed Oct 21 03:52:25 2020
   NAMESPACE: nginxssl
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   The ingress-nginx controller has been installed.
   Get the application URL by running these commands:
     export HTTP_NODE_PORT=$(kubectl --namespace nginxssl get services -o jsonpath="{.spec.ports[0].nodePort}" nginx-dc-operator-ssl-ingress-nginx-controller)
     export HTTPS_NODE_PORT=30321
     export NODE_IP=$(kubectl --namespace nginxssl get nodes -o jsonpath="{.items[0].status.addresses[1].address}")

     echo "Visit http://$NODE_IP:$HTTP_NODE_PORT to access your application via HTTP."
     echo "Visit https://$NODE_IP:$HTTPS_NODE_PORT to access your application via HTTPS."

   An example Ingress that makes use of the controller:

     apiVersion: networking.k8s.io/v1beta1
     kind: Ingress
     metadata:
       annotations:
         kubernetes.io/ingress.class: nginx-designconsole
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
   $ helm install nginx-dc-operator-ssl -n nginxssl --set controller.extraArgs.default-ssl-certificate=oigns/governancedomain-tls-cert --set controller.service.type=LoadBalancer --set controller.admissionWebhooks.enabled=false stable/ingress-nginx --version=3.34.0
   ```

   The output will look similar to the following:

   ```
   NAME: nginx-dc-operator-ssl-lbr
   LAST DEPLOYED: Wed Oct 21 04:02:35 2020
   NAMESPACE: nginxssl
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   The ingress-nginx controller has been installed.
   It may take a few minutes for the LoadBalancer IP to be available.
   You can watch the status by running 'kubectl --namespace nginxssl get services -o wide -w nginx-dc-operator-ssl-lbr-ingress-nginx-controller'

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

### Setup Routing Rules for the Design Console ingress

1. Setup routing rules by running the following commands:

   ```
   $ cd <work directory>/weblogic-kubernetes-operator/kubernetes/samples/charts/design-console-ingress
   $ cp values.yaml values.yaml.orig
   $ vi values.yaml
   ```

   Edit `values.yaml` and ensure that `type=NGINX`, `tls=SSL`, `domainUID: governancedomain` and `secretName: governancedomain-tls-cert` are set, for example:
   
   ```
   $ cat values.yaml
   # Copyright 2020 Oracle Corporation and/or its affiliates.
   # Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

   # Default values for design-console-ingress.
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
     oimServerT3Port: 14001

   # Voyager specific values
   voyager:
     # web port
     webPort: 30320
     # stats port
     statsPort: 30321
   ```

### Create the ingress

1. Run the following command to create the ingress:
   
   ```
   $ cd <work directory>/weblogic-kubernetes-operator
   $ helm install governancedomain-nginx-designconsole kubernetes/samples/charts/design-console-ingress  --namespace oigns  --values kubernetes/samples/charts/design-console-ingress/values.yaml
   ```
  
   For example:
   
   ```
   $ cd /scratch/OIGDockerK8S/weblogic-kubernetes-operator
   $ helm install governancedomain-nginx-designconsole kubernetes/samples/charts/design-console-ingress  --namespace oigns  --values kubernetes/samples/charts/design-console-ingress/values.yaml
   ```
   
   The output will look similar to the following:

   ```
   NAME: governancedomain-nginx-designconsole
   LAST DEPLOYED: Wed Oct 21 04:12:00 2020
   NAMESPACE: oigns
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   ```

1. Run the following command to show the ingress is created successfully:

   ```
   $ kubectl describe ing governancedomain-nginx-designconsole -n <domain_namespace>
   ```
   
   For example:
   
   ```
   $ kubectl describe ing governancedomain-nginx-designconsole -n oigns
   ```
   
   The output will look similar to the following:

   ```  
   Name:             governancedomain-nginx-designconsole
   Namespace:        oigns
   Address:          10.106.181.99
   Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
   Rules:
     Host        Path  Backends
     ----        ----  --------
     *
                    governancedomain-cluster-oim-cluster:14001 ()
   Annotations:  kubernetes.io/ingress.class: nginx-designconsole
                 meta.helm.sh/release-name: governancedomain-nginx-designconsole
                 meta.helm.sh/release-namespace: oigns
                 nginx.ingress.kubernetes.io/affinity: cookie
                 nginx.ingress.kubernetes.io/configuration-snippet:
                   more_set_input_headers "X-Forwarded-Proto: https";
                   more_set_input_headers "WL-Proxy-SSL: true";
                 nginx.ingress.kubernetes.io/enable-access-log: false
                 nginx.ingress.kubernetes.io/ingress.allow-http: false
                 nginx.ingress.kubernetes.io/proxy-buffer-size: 2000k
   Events:
     Type    Reason  Age   From                      Message
     ----    ------  ----  ----                      -------
     Normal  CREATE  38s   nginx-ingress-controller  Ingress oigns/governancedomain-nginx-designconsole
     Normal  UPDATE  10s   nginx-ingress-controller  Ingress oigns/governancedomain-nginx-designconsole
   ```
   
  
### Design Console Client

It is possible to use Design Console from an on-premises install, or from a container image.

#### Using an on-premises installed Design Console

The instructions below should be performed on the client where Design Console is installed.

1. Import the CA certificate into the java keystore

   If in [Generate a SSL Certificate](../using-the-design-console-with-nginx-ssl/#generate-ssl-certificate) you requested a certificate from a Certificate Authority (CA), then you must import the CA certificate (e.g cacert.crt) that signed your certificate, into the java truststore used by Design Console.

   If in [Generate a SSL Certificate](../using-the-design-console-with-nginx-ssl/#generate-ssl-certificate) you generated a self-signed certicate (e.g tls.crt), you must import the self-signed certificate into the java truststore used by Design Console.

   Import the certificate using the following command:

   ```
   $ keytool -import -trustcacerts -alias dc -file <certificate> -keystore $JAVA_HOME/jre/lib/security/cacerts
   ```

   where `<certificate>` is the CA certificate, or self-signed certicate.

1. Once complete follow [Login to the Design Console](../using-the-design-console-with-nginx-ssl/#login-to-the-design-console).

#### Using a container image for Design Console

The Design Console can be run from a container using X windows emulation.

1. On the parent machine where the Design Console is to be displayed, run `xhost+`.

1. Execute the following command to start a container to run Design Console:

   ```
   $ docker run -u root --name oigdcbase -it <image> bash
   ```
   
   For example:
   
   ```
   $ docker run -u root -it --name oigdcbase oracle/oig:12.2.1.4.0 bash
   ```

   This will take you into a bash shell inside the container:
   
   ```
   bash-4.2#
   ```
   
1. Inside the container set the proxy, for example:

   ```
   bash-4.2# export https_proxy=http://proxy.example.com:80
   ```

1. Install the relevant X windows packages in the container:

   ```
   bash-4.2# yum install libXext libXrender libXtst
   ```
   
1. Execute the following outside the container to create a new Design Console image from the container:

   ```
   $ docker commit <container_name> <design_console_image_name>
   ```
   
   For example:
   
   ```
   $ docker commit oigdcbase oigdc
   ```
   
1. Exit the container bash session:

   ```
   bash-4.2# exit
   ```
   
1. Start a new container using the Design Console image:

   ```
   $ docker run --name oigdc -it oigdc /bin/bash
   ```
   
   This will take you into a bash shell for the container:
   
   ```
   bash-4.2#
   ```
   
1. Copy the Ingress CA certificate into the container

   If in [Generate a SSL Certificate](../using-the-design-console-with-nginx-ssl/#generate-ssl-certificate) you requested a certificate from a Certificate Authority (CA), then you must copy the CA certificate (e.g cacert.crt) that signed your certificate, into the container

   If in [Generate a SSL Certificate](../using-the-design-console-with-nginx-ssl/#generate-ssl-certificate) you generated a self-signed certicate (e.g tls.crt), you must copy the self-signed certificate into the container

   Run the following command outside the container:

   ```
   $ cd <work directory>/ssl
   $ docker cp <certificate> <container_name>:/u01/jdk/jre/lib/security/<certificate>
   ```

   For example:
   
   ```
   $ cd /scratch/OIGDockerK8S/ssl
   $ docker cp tls.crt oigdc:/u01/jdk/jre/lib/security/tls.crt
   

1. Import the certificate using the following command:

   ```
   bash-4.2# /u01/jdk/bin/keytool -import -trustcacerts -alias dc -file /u01/jdk/jre/lib/security/<certificate> -keystore /u01/jdk/jre/lib/security/cacerts
   ```

   For example:
   
   ```
   bash-4.2# /u01/jdk/bin/keytool -import -trustcacerts -alias dc -file /u01/jdk/jre/lib/security/tls.crt -keystore /u01/jdk/jre/lib/security/cacerts
   ```


1. In the container run the following to export the DISPLAY:

   ```
   $ export DISPLAY=<parent_machine_hostname:1>
   ```   

1. Start the Design Console from the container:

   ```
   bash-4.2# cd idm/designconsole
   bash-4.2# sh xlclient.sh
   ```
   
   The Design Console login should be displayed. Now follow [Login to the Design Console](../using-the-design-console-with-nginx-ssl/#login-to-the-design-console).



#### Login to the Design Console

1. Launch the Design Console and in the Oracle Identity Manager Design Console login page enter the following details: 

   Enter the following details and click Login:
   * `Server URL`: `<url>`
   * `User ID`: `xelsysadm`
   * `Password`: `<password>`.

    where `<url>` is as per the following:
	
   a) For NodePort: `https://<masternode.example.com>:<NodePort>`
   
   where `<NodePort>` is the value passed in the command earlier, for example: `--set controller.service.nodePorts.http=30321`
   
   b) For LoadBalancer: `https://<loadbalancer.example.com>:<LBRPort>`
   
   

1. If successful the Design Console will be displayed. If the VNC session disappears then the connection failed so double check the connection details and try again.

