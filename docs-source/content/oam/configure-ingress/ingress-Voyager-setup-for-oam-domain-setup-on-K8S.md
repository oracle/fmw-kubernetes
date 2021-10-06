---
title: "b. Using an Ingress with Voyager"
description: "Steps to set up an Ingress for Voyager to direct traffic to the OAM domain."
---

### Setting Up an Ingress for Voyager for the OAM Domain on K8S

The instructions below explain how to set up Voyager as an Ingress for the OAM domain with SSL termination.

**Note**: All the steps below should be performed on the **master** node.

1. [Generate a SSL Certificate](#generate-a-ssl-certificate)
2. [Install Voyager](#install-voyager)
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

   **Note**: The CN should match the host.domain of the master node in order to prevent hostname problems during certificate verification.
   
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
   
   
#### Install Voyager

Use helm to install Voyager.

1. Add the appscode chart repository using the following command:

   ```bash
   $ helm repo add appscode https://charts.appscode.com/stable/
   ```
   
   The output will look similar to the following:
   
   ```bash
   "appscode" has been added to your repositories
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
   
1. Run the following command to show the voyager chart was added successfully.

   ```bash
   $ helm search repo appscode/voyager
   ```
   
   The output will look similar to the following:
   
   ```bash
   NAME                    CHART VERSION   APP VERSION     DESCRIPTION
   appscode/voyager        v12.0.0         v12.0.0         Voyager by AppsCode - Secure HAProxy Ingress Co...
   ```
   
1. Create a namespace for the voyager:

   ```bash
   $ kubectl create namespace voyager
   ```
   
   The output will look similar to the following:
   
   ```bash
   namespace/voyager created
   ```
      
   
1. Install Voyager using the following helm command:

   ```bash
   $ helm install voyager-operator appscode/voyager --version 12.0.0 --namespace voyager --set cloudProvider=baremetal --set apiserver.enableValidatingWebhook=false
   ```
   
   **Note**: For bare metal Kubernetes use `--set cloudProvider=baremetal`. If using a managed Kubernetes service then the value should be set for your specific service as per the [Voyager](https://voyagermesh.com/docs/6.0.0/setup/install/) install guide.
   
   The output will look similar to the following:
   
   ```bash 
   NAME: voyager-operator
   LAST DEPLOYED: Fri Sep 25 01:15:31 2020
   NAMESPACE: voyager
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   Set cloudProvider for installing Voyager

   To verify that Voyager has started, run:

   kubectl get deployment --namespace voyager -l "app.kubernetes.io/name=voyager,app.kubernetes.io/instance=voyager-operator"
   ```

#### Create an Ingress for the Domain

1. Edit the `values.yaml` and change domainUID to the domainUID you created previously:

   ```bash
   $ cd <work directory>/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain
   ```
   
   For example:
   
   ```bash
   $ cd /scratch/OAMDockerK8S/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain
   ```
   
   Edit `values.yaml` and change `Namespace: <domain namespace>`, for example `Namespace: oamns`. Also change `domainUID: <domain_UID>`, for example `domainUID: accessdomain`.
   
1. Navigate to the following directory:
 
   ```bash
   $ cd <work directory>/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/templates
   ```
   
   For example:
   
   ```bash
   $ cd /scratch/OAMDockerK8S/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/templates
   ```
   
   Edit the `voyager-ingress.yaml` and change the `secretName` to the value created earlier, for example:
   
   ```bash
   # Copyright (c) 2020, Oracle Corporation and/or its affiliates. 
   # Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


   {{- if eq .Values.type "VOYAGER" }}
   ---
   apiVersion: voyager.appscode.com/v1beta1
   kind: Ingress
   metadata:
     name: {{ .Values.wlsDomain.domainUID }}-voyager
     namespace: {{ .Release.Namespace }}
     annotations:
       ingress.appscode.com/type: 'NodePort'
       kubernetes.io/ingress.class: 'voyager'
       ingress.appscode.com/stats: 'true'
       ingress.appscode.com/default-timeout: '{"connect": "1800s", "server": "1800s"}'
       ingress.appscode.com/proxy-body-size: "2000000"
      labels:
        weblogic.resourceVersion: domain-v2
   spec:
   {{- if eq .Values.tls "SSL" }}
     frontendRules:
     - port: 443
       rules:
       - http-request set-header WL-Proxy-SSL true
     tls:
     - secretName: accessdomain-tls-cert
       hosts:
       - '*'
   {{- end }}
   ...
   ```

   
1. Create an Ingress for the domain (`oam-voyager-ingress`), in the domain namespace by using the sample Helm chart.

   ```bash
   $ cd <work directory>/weblogic-kubernetes-operator
   $ helm install oam-voyager-ingress kubernetes/samples/charts/ingress-per-domain  --namespace <domain_namespace>  --values kubernetes/samples/charts/ingress-per-domain/values.yaml
   ```
   
   For example:
   
   ```bash
   $ cd /scratch/OAMDockerK8S/weblogic-kubernetes-operator
   $ helm install oam-voyager-ingress kubernetes/samples/charts/ingress-per-domain  --namespace oamns  --values kubernetes/samples/charts/ingress-per-domain/values.yaml
   ```
   
   The output will look similar to the following:
   ```bash
   NAME: oam-voyager-ingress
   Fri Sep 25 01:18:01 2020
   NAMESPACE: oamns
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   ```
   
1. Run the following command to show the ingress is created successfully:

   ```bash
   $ kubectl get ingress.voyager.appscode.com --all-namespaces
   ```
   
   The output will look similar to the following:
   ```bash
   NAMESPACE   NAME                  HOSTS   LOAD_BALANCER_IP   AGE
   oamns    accessdomain-voyager   *                          80s
   ```
   
1. Find the node port of the ingress using the following command:

   ```bash
   $ kubectl describe svc voyager-accessdomain-voyager -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl describe svc voyager-accessdomain-voyager -n oamns
   ```
   
   The output will look similar to the following:
   ```bash
   Name:                     voyager-accessdomain-voyager
   Namespace:                oamns
   Labels:                   app.kubernetes.io/managed-by=Helm
                             origin=voyager
                             origin-api-group=voyager.appscode.com
                             origin-name=accessdomain-voyager
                             weblogic.resourceVersion=domain-v2
   Annotations:              ingress.appscode.com/last-applied-annotation-keys:
                             ingress.appscode.com/origin-api-schema: voyager.appscode.com/v1beta1
                             ingress.appscode.com/origin-name: accessdomain-voyager
   Selector:                 origin-api-group=voyager.appscode.com,origin-name=accessdomain-voyager,origin=voyager
   Type:                     NodePort
   IP:                       10.105.242.191
   Port:                     tcp-443  443/TCP
   TargetPort:               443/TCP
   NodePort:                 tcp-443  30305/TCP
   Endpoints:                10.244.2.4:443
   Port:                     tcp-80  80/TCP
   TargetPort:               80/TCP
   NodePort:                 tcp-80  32064/TCP
   Endpoints:                10.244.2.4:80
   Session Affinity:         None
   External Traffic Policy:  Cluster
   Events:                   <none>
   ```

   In the above example the `NodePort` for `tcp-443` is `30305`.
  
1. To confirm that the new Ingress is successfully routing to the domain's server pods, run the following command to send a request to the URL for the "WebLogic ReadyApp framework":

   ```bash
   $ curl -v https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/weblogic/ready
   ```
   
   For example:
   
   ```bash
   $ curl -v -k https://masternode.example.com:30305/weblogic/ready
   ```
   
   The output will look similar to the following:
   
   ```bash
   *   Trying 12.345.67.89...
   * Connected to 12.345.67.89 (12.345.67.89) port 30305 (#0)
   * Initializing NSS with certpath: sql:/etc/pki/nssdb
   * skipping SSL peer certificate verification
   * SSL connection using TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
   * Server certificate:
   *       subject: CN=masternode.example.com
   *       start date:  Sep 24 14:30:46 2020 GMT
   *       expire date: Sep 24 14:30:46 2021 GMT
   *       common name: masternode.example.com
   *       issuer: CN=masternode.example.com
   > GET /weblogic/ready HTTP/1.1
   > User-Agent: curl/7.29.0
   > Host: masternode.example.com:30305
   > Accept: */*
   >
   < HTTP/1.1 200 OK
   < Date: 25 Sep 2020 08:22:11 GMT
   < Content-Length: 0
   < Strict-Transport-Security: max-age=15768000
   <
   * Connection #0 to host 12.345.67.89 left intact
   ```
   
#### Verify that you can access the domain URL

After setting up the Voyager ingress, verify that the domain applications are accessible through the Voyager ingress port (for example 30305) as per [Validate Domain URLs ]({{< relref "/oam/validate-domain-urls" >}})
