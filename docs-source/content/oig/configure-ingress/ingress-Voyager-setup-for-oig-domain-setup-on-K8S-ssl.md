---
title: "d. Using an Ingress with Voyager (SSL)"
description: "Steps to set up an Ingress for Voyager to direct traffic to the OIG domain (SSL)."
---

### Setting Up an Ingress for Voyager for the OIG Domain on Kubernetes

The instructions below explain how to set up Voyager as an Ingress for the OIG domain with SSL termination.

**Note**: All the steps below should be performed on the **master** node.

1. [Create a SSL Certificate](#create-a-ssl-certificate)
    1. [Generate SSL Certificate](#generate-ssl-certificate)
	1. [Create a Kubernetes Secret for SSL](#create-a-kubernetes-secret-for-ssl)
1. [Install Voyager](#install-voyager)
    1. [Configure the repository](#configure-the-repository)
	1. [Create Namespace and Install Voyager](#create-namespace-and-install-voyager)
	1. [Setup Routing Rules for the Domain](#setup-routing-rules-for-the-domain)
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
   $
   ```

#### Create a Kubernetes Secret for SSL

1. Create a secret for SSL containing the SSL certificate by running the following command:

   ```
   $ kubectl -n oimcluster create secret tls <domain_id>-tls-cert --key <work directory>/tls.key --cert <work directory>/tls.crt
   ```
   
   For example:
   
   ```
   $ kubectl -n oimcluster create secret tls oimcluster-tls-cert --key /scratch/OIGDockerK8S/ssl/tls.key --cert /scratch/OIGDockerK8S/ssl/tls.crt
   ```
   
   The output will look similar to the following:
   
   ```
   secret/oimcluster-tls-cert created
   ```

   Confirm that the secret is created by running the following command:

   ```
   $ kubectl get secret oimcluster-tls-cert -o yaml -n oimcluster
   ```

   The output will look similar to the following:

   ```
   apiVersion: v1
   data:
     tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURGVENDQWYyZ0F3SUJBZ0lKQUl3ZjVRMWVxZnljTUEwR0NTcUdTSWIzRFFFQkN3VUFNQ0V4SHpBZEJnTlYKQkFNTUZtUmxiakF4WlhadkxuVnpMbTl5WVdOc1pTNWpiMjB3SGhjTk1qQXdPREV3TVRReE9UUXpXaGNOTWpFdwpPREV3TVRReE9UUXpXakFoTVI4d0hRWURWUVFEREJaa1pXNHdNV1YyYnk1MWN5NXZjbUZqYkdVdVkyOXRNSUlCCklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUEyY0lpVUhwcTRVZzBhaGR6aXkycHY2cHQKSVIza2s5REd2eVRNY0syaWZQQ2dtUU5CdHV6VXNFN0l4c294eldITmU5RFpXRXJTSjVON3FYYm1lTzJkMVd2NQp1aFhzbkFTbnkwY1NLUE9xOUNZVDNQSlpDVk1MK0llZVFKdnhaVjZaWWU4V2FFL1NQSGJzczRjYy9wcG1mc3pxCnErUi83cXEyMm9ueHNHaE9vQ1h1TlQvMFF2WXVzMnNucGtueWRKRHUxelhGbDREYkFIZGMvamNVK0NPWWROeS8KT3Iza2JIV0FaTkR4OWxaZUREOTRmNXZLbGJwMy9rcUF2V0FkSVJZa2UrSmpNTHg0VHo2ZlM0VXoxbzdBSTVuSApPQ1ZMblV5U0JkaGVuWTNGNEdFU0wwbnorVlhFWjRWVjRucWNjRmo5cnJ0Q29pT1BBNlgvNGdxMEZJbi9Qd0lECkFRQUJvMUF3VGpBZEJnTlZIUTRFRmdRVWw1VnVpVDBDT0xGTzcxMFBlcHRxSC9DRWZyY3dId1lEVlIwakJCZ3cKRm9BVWw1VnVpVDBDT0xGTzcxMFBlcHRxSC9DRWZyY3dEQVlEVlIwVEJBVXdBd0VCL3pBTkJna3Foa2lHOXcwQgpBUXNGQUFPQ0FRRUFXdEN4b2ZmNGgrWXZEcVVpTFFtUnpqQkVBMHJCOUMwL1FWOG9JQzJ3d1hzYi9KaVNuMHdOCjNMdHppejc0aStEbk1yQytoNFQ3enRaSkc3NVluSGRKcmxQajgzVWdDLzhYTlFCSUNDbTFUa3RlVU1jWG0reG4KTEZEMHpReFhpVzV0N1FHcWtvK2FjeN3JRMXlNSE9HdVVkTTZETzErNXF4cTdFNXFMamhyNEdKejV5OAoraW8zK25UcUVKMHFQOVRocG96RXhBMW80OEY0ZHJybWdqd3ROUldEQVpBYmYyV1JNMXFKWXhxTTJqdU1FQWNsCnFMek1TdEZUQ2o1UGFTQ0NUV1VEK3ZlSWtsRWRpaFdpRm02dzk3Y1diZ0lGMlhlNGk4L2szMmF1N2xUTDEvd28KU3Q2dHpsa20yV25uUFlVMzBnRURnVTQ4OU02Z1dybklpZz09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
     tls.key: LS0tLS1CRUdJQVRFIEtFWS0tLS0tCk1JSUV1d0lCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktVd2dnU2hBZ0VBQW9JQkFRRFp3aUpRZW1yaFNEUnEKRjNPTExhbS9xbTBoSGVTVDBNYS9KTXh3cmFKODhLQ1pBMEcyN05Td1Rzakd5akhOWWMxNzBObFlTdEluazN1cApkdVo0N1ozVmEvbTZGZXljQktmTFJ4SW84NnIwSmhQYzhsa0pVd3Y0aDU1QW0vRmxYcGxoN3hab1Q5SThkdXl6Cmh4eittbVorek9xcjVIL3VxcmJhaWZHd2FFNmdKZTQxUC9SQzlpNnpheWVtU2ZKMGtPN1hOY1dYZ05zQWQxeisKTnhUNEk1aDAzTDg2dmVSc2RZQmswUEgyVmw0TVAzaC9tOHFWdW5mK1NvQzlZQjBoRmlSNzRtTXd2SGhQUHA5TApoVFBXanNBam1jYzRKVXVkVEpJRjJGNmRqY1hnWVJJdlNmUDVWY1JuaFZYaWVweHdXUDJ1dTBLaUk0OERwZi9pCkNyUVVpZjgvQWdNQkFBRUNnZjl6cnE2TUVueTFNYWFtdGM2c0laWU1QSDI5R2lSVVlwVXk5bG1sZ3BqUHh3V0sKUkRDay9Td0FmZG9yd1Q2ejNVRk1oYWJ4UU01a04vVjZFYkJlamQxTGhCRW15bjdvWTVEQWJRRTR3RG9SZWlrVApONndWU0FrVC92Z1RXc1RqRlY1bXFKMCt6U2ppOWtySkZQNVNRN1F2cUswQ3BHRlNhVjY2dW8ycktiNmJWSkJYCkxPZmZPMytlS0tVazBaTnE1Q1NVQk9mbnFoNVFJSGdpaDNiMTRlNjBDdGhYcEh6bndrNWhaMHBHZE9BQm9aTkoKZ21lanUyTEdzVWxXTjBLOVdsUy9lcUllQzVzQm9jaWlocmxMVUpGWnpPRUV6LzErT2cyemhmT29yTE9rMTIrTgpjQnV0cTJWQ2I4ZFJDaFg1ZzJ0WnBrdzgzcXN5RSt3M09zYlQxa0VDZ1lFQTdxUnRLWGFONUx1SENvWlM1VWhNCm9Hak1WcnYxTEg0eGNhaDJITmZnMksrMHJqQkJONGpkZkFDMmF3R3ZzU1EyR0lYRzVGYmYyK0pwL1kxbktKOEgKZU80MzNLWVgwTDE4NlNNLzFVay9HSEdTek1CWS9KdGR6WkRrbTA4UnBwaTl4bExTeDBWUWtFNVJVcnJJcTRJVwplZzBOM2RVTHZhTVl1UTBrR2dncUFETUNnWUVBNlpqWCtjU2VMZ1BVajJENWRpUGJ1TmVFd2RMeFNPZDFZMUFjCkUzQ01YTWozK2JxQ3BGUVIrTldYWWVuVmM1QiszajlSdHVnQ0YyTkNSdVdkZWowalBpL243UExIRHdCZVY0bVIKM3VQVHJmamRJbFovSFgzQ2NjVE94TmlaajU4VitFdkRHNHNHOGxtRTRieStYRExIYTJyMWxmUk9sUVRMSyswVgpyTU93eU1VQ2dZRUF1dm14WGM4NWxZRW9hU0tkU0cvQk9kMWlYSUtmc2VDZHRNT2M1elJ0UXRsSDQwS0RscE54CmxYcXBjbVc3MWpyYzk1RzVKNmE1ZG5xTE9OSFZoWW8wUEpmSXhPU052RXI2MTE5NjRBMm5sZXRHYlk0M0twUkEKaHBPRHlmdkZoSllmK29kaUJpZFUyL3ZBMCtUczNSUHJzRzBSOUVDOEZqVDNaZVhaNTF1R0xPa0NnWUFpTmU0NwplQjRxWXdrNFRsMTZmZG5xQWpaQkpLR05xY2c1V1R3alpMSkp6R3owdCtuMkl4SFd2WUZFSjdqSkNmcHFsaDlqCmlDcjJQZVV3K09QTlNUTG1JcUgydzc5L1pQQnNKWXVsZHZ4RFdGVWFlRXg1aHpkNDdmZlNRRjZNK0NHQmthYnIKVzdzU3R5V000ZFdITHpDaGZMS20yWGJBd0VqNUQrbkN1WTRrZVFLQmdFSkRHb0puM1NCRXcra2xXTE85N09aOApnc3lYQm9mUW1lRktIS2NHNzFZUFhJbTRlV1kyUi9KOCt5anc5b1FJQ3o5NlRidkdSZEN5QlJhbWhoTmFGUzVyCk9MZUc0ejVENE4zdThUc0dNem9QcU13KzBGSXJiQ3FzTnpGWTg3ekZweEdVaXZvRWZLNE82YkdERTZjNHFqNGEKNmlmK0RSRSt1TWRMWTQyYTA3ekoKLS0tLS1FTkQgUFJJVkFURSBLRVktLS0tLQo=
   kind: Secret
   metadata:
     creationTimestamp: "2020-08-10T14:22:52Z"
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
       time: "2020-08-10T14:22:52Z"
     name: oimcluster-tls-cert
     namespace: oimcluster
     resourceVersion: "3722477"
     selfLink: /api/v1/namespaces/oimcluster/secrets/oimcluster-tls-cert
     uid: 596fe0fe-effd-4eb9-974d-691da3a3b15a
   type: kubernetes.io/tls
   ```

### Install Voyager

Use Helm to install Voyager. For detailed information, see [this document](https://github.com/oracle/weblogic-kubernetes-operator/blob/master/kubernetes/samples/charts/voyager/README.md).

#### Configure the repository

1. Add the Helm chart repository for installing Voyager using the following command:

   ```
   $ helm repo add appscode https://charts.appscode.com/stable
   ```
   
   The output will look similar to the following:
   
   ```
   $ helm repo add appscode https://charts.appscode.com/stable
   "appscode" has been added to your repositories
   ```

1. Update the repository using the following command:

   ```
   $ helm repo update
   ```
   
   The output will look similar to the following:
   
   ```
   Hang tight while we grab the latest from your chart repositories...
   ...Successfully got an update from the "appscode" chart repository
   Update Complete. Happy Helming!
   ```
   
1. Run the following command to show the Voyager chart was added successfully.

   ```
   $ helm search repo appscode/voyager
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                    CHART VERSION   APP VERSION     DESCRIPTION
   appscode/voyager        v12.0.0         v12.0.0         Voyager by AppsCode - Secure HAProxy Ingress Co...
   ```

#### Create Namespace and Install Voyager
 
1. Create a namespace for Voyager:

   ```
   $ kubectl create namespace voyagerssl
   ```
   
   The output will look similar to the following:
   
   ```
   namespace/voyagerssl created
   ```  

1. Install Voyager using the following Helm command:

   ```
   $ helm install voyager-ingress appscode/voyager --version 12.0.0 --namespace voyagerssl --set cloudProvider=baremetal --set apiserver.enableValidatingWebhook=false
   ```

   **Note**: For bare metal Kubernetes use `--set cloudProvider=baremetal`. If using a managed Kubernetes service then the value should be set for your specific service as per the [Voyager](https://voyagermesh.com/docs/6.0.0/setup/install/) install guide.

   The output will look similar to the following:
   
   ```
   NAME: voyager-ingress
   LAST DEPLOYED: Wed Aug 12 09:00:58 2020
   NAMESPACE: voyagerssl
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   Set cloudProvider for installing Voyager

   To verify that Voyager has started, run:

     kubectl get deployment --namespace voyagerssl -l "app.kubernetes.io/name=voyager,app.kubernetes.io/instance=voyager-ingress"
   ```

1. Verify that the ingress has started by running the following command:

   ```
   $ kubectl get deployment --namespace voyagerssl -l "app.kubernetes.io/name=voyager,app.kubernetes.io/instance=voyager-ingress"
   ```

   The output will look similar to the following:

   ```
   NAME              READY   UP-TO-DATE   AVAILABLE   AGE
   voyager-ingress   1/1     1            1           89s
   ```

#### Setup Routing Rules for the Domain

1. Setup routing rules using the following commands:

   ```
   $ cd <work directory>/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain
   $ cp values.yaml values.yaml.orig
   $ vi values.yaml
   ```

1. Edit `values.yaml` and ensure that `type=VOYAGER`,`tls=SSL`, and secretName: `<SSL Secret>` , for example:

   ```
   $ cat values.yaml
   # Copyright 2020 Oracle Corporation and/or its affiliates. 
   # Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


   # Default values for ingress-per-domain.
   # This is a YAML-formatted file.
   # Declare variables to be passed into your templates.

   # Load balancer type.  Supported values are: VOYAGER, NGINX
   type: VOYAGER
   # Type of Configuration Supported Values are : NONSSL,SSL
   # tls: NONSSL
   tls: SSL
   # TLS secret name if the mode is SSL
   secretName: oimcluster-tls-cert


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
   $
   ```

### Create an Ingress for the Domain

1. Create an Ingress for the domain (`oimcluster-voyager`), in the domain namespace by using the sample Helm chart.

   ```
   $ cd <work directory>/weblogic-kubernetes-operator
   $ helm install oimcluster-voyager kubernetes/samples/charts/ingress-per-domain  --namespace <namespace>  --values kubernetes/samples/charts/ingress-per-domain/values.yaml
   ```

   For example:
   
   ```
   $ cd /scratch/OIGDockerK8S/weblogic-kubernetes-operator
   $ helm install oimcluster-voyager kubernetes/samples/charts/ingress-per-domain  --namespace oimcluster  --values kubernetes/samples/charts/ingress-per-domain/values.yaml
   ```

   The output will look similar to the following:

   ```
   NAME: oimcluster-voyager
   LAST DEPLOYED: Wed Sep 30 01:51:05 2020
   NAMESPACE: oimcluster
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   ```
   
1. Run the following command to show the ingress is created successfully:

   ```
   $ kubectl get ingress.voyager.appscode.com -n oimcluster
   ```
   
   The output will look similar to the following:

   ```
   NAME                 HOSTS   LOAD_BALANCER_IP   AGE
   oimcluster-voyager   *                          3m44s
   ```
   
1. Return details of the ingress using the following command:

   ```
   $ kubectl describe ingress.voyager.appscode.com oimcluster-voyager -n oimcluster
   ```
   
   The output will look similar to the following:

   ```
   Name:         oimcluster-voyager
   Namespace:    oimcluster
   Labels:       app.kubernetes.io/managed-by=Helm
                 weblogic.resourceVersion=domain-v2
   Annotations:  ingress.appscode.com/affinity: cookie
                 ingress.appscode.com/stats: true
                 ingress.appscode.com/type: NodePort
                 meta.helm.sh/release-name: oimcluster-voyager
                 meta.helm.sh/release-namespace: oimcluster
   API Version:  voyager.appscode.com/v1beta1
   Kind:         Ingress
   Metadata:
     Creation Timestamp:  2020-09-30T08:51:05Z
     Generation:          1
     Managed Fields:
       API Version:  voyager.appscode.com/v1beta1
       Fields Type:  FieldsV1
       fieldsV1:
         f:metadata:
           f:annotations:
             .:
             f:ingress.appscode.com/affinity:
             f:ingress.appscode.com/stats:
             f:ingress.appscode.com/type:
             f:meta.helm.sh/release-name:
             f:meta.helm.sh/release-namespace:
           f:labels:
             .:
             f:app.kubernetes.io/managed-by:
             f:weblogic.resourceVersion:
         f:spec:
           .:
           f:frontendRules:
           f:rules:
           f:tls:
       Manager:         Go-http-client
       Operation:       Update
       Time:            2020-09-30T08:51:05Z
     Resource Version:  1440614
     Self Link:         /apis/voyager.appscode.com/v1beta1/namespaces/oimcluster/ingresses/oimcluster-voyager
     UID:               875e7d90-b166-40ff-b792-c764d514c0c3
   Spec:
     Frontend Rules:
       Port:  443
       Rules:
         http-request set-header WL-Proxy-SSL true
     Rules:
       Host:  *
       Http:
         Node Port:  30305
         Paths:
           Backend:
             Service Name:  oimcluster-adminserver
             Service Port:  7001
           Path:            /console
           Backend:
             Service Name:  oimcluster-adminserver
             Service Port:  7001
           Path:            /em
           Backend:
             Service Name:  oimcluster-cluster-soa-cluster
             Service Port:  8001
           Path:            /soa-infra
           Backend:
             Service Name:  oimcluster-cluster-soa-cluster
             Service Port:  8001
           Path:            /soa
           Backend:
             Service Name:  oimcluster-cluster-soa-cluster
             Service Port:  8001
           Path:            /integration
           Backend:
             Service Name:  oimcluster-cluster-oim-cluster
             Service Port:  14000
           Path:            /
     Tls:
       Hosts:
         *
       Secret Name:  oimcluster-tls-cert
   Events:
     Type    Reason                           Age   From              Message
     ----    ------                           ----  ----              -------
     Normal  ServiceReconcileSuccessful       65s   voyager-operator  Successfully created NodePort Service voyager-oimcluster-voyager
     Normal  ConfigMapReconcileSuccessful     64s   voyager-operator  Successfully created ConfigMap voyager-oimcluster-voyager
     Normal  RBACSuccessful                   64s   voyager-operator  Successfully created ServiceAccount voyager-oimcluster-voyager
     Normal  RBACSuccessful                   64s   voyager-operator  Successfully created Role voyager-oimcluster-voyager
     Normal  RBACSuccessful                   64s   voyager-operator  Successfully created RoleBinding voyager-oimcluster-voyager
     Normal  DeploymentReconcileSuccessful    64s   voyager-operator  Successfully created HAProxy Deployment voyager-oimcluster-voyager
     Normal  StatsServiceReconcileSuccessful  64s   voyager-operator  Successfully created stats Service voyager-oimcluster-voyager-stats
     Normal  DeploymentReconcileSuccessful    64s   voyager-operator  Successfully patched HAProxy Deployment voyager-oimcluster-voyager
   ```

1. Find the NodePort of Voyager using the following command:

   ```
   $ kubectl get svc -n oimcluster
   ```

   The output will look similar to the following:

   ```
   NAME                               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
   oimcluster-adminserver             ClusterIP   None             <none>        7001/TCP                     18h
   oimcluster-cluster-oim-cluster     ClusterIP   10.97.121.159    <none>        14000/TCP                    18h
   oimcluster-cluster-soa-cluster     ClusterIP   10.111.231.242   <none>        8001/TCP                     18h
   oimcluster-oim-server1             ClusterIP   None             <none>        14000/TCP                    18h
   oimcluster-oim-server2             ClusterIP   10.108.139.30    <none>        14000/TCP                    18h
   oimcluster-oim-server3             ClusterIP   10.97.170.104    <none>        14000/TCP                    18h
   oimcluster-oim-server4             ClusterIP   10.99.82.214     <none>        14000/TCP                    18h
   oimcluster-oim-server5             ClusterIP   10.98.75.228     <none>        14000/TCP                    18h
   oimcluster-soa-server1             ClusterIP   None             <none>        8001/TCP                     18h
   oimcluster-soa-server2             ClusterIP   10.107.232.220   <none>        8001/TCP                     18h
   oimcluster-soa-server3             ClusterIP   10.108.203.6     <none>        8001/TCP                     18h
   oimcluster-soa-server4             ClusterIP   10.96.178.0      <none>        8001/TCP                     18h
   oimcluster-soa-server5             ClusterIP   10.107.83.62     <none>        8001/TCP                     18h
   oimcluster-voyager-stats           NodePort    10.96.62.0       <none>        56789:30315/TCP              3m19s
   voyager-oimcluster-voyager         NodePort    10.97.231.109    <none>        443:30305/TCP,80:30419/TCP   3m12s
   voyager-oimcluster-voyager-stats   ClusterIP   10.99.185.46     <none>        56789/TCP                    3m6s
   ```

   Identify the service `voyager-oimcluster-voyager` in the above output and get the `NodePort` which corresponds to port `443`. In this example it will be `30305`.
  
1. To confirm that the new Ingress is successfully routing to the domain's server pods, run the following command to send a request to the URL for the "WebLogic ReadyApp framework":

   ```
   $ curl -v -k https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/weblogic/ready
   ```
   
   For example:
   
   ```
   $ curl -v -k https://masternode.example.com:30305/weblogic/ready
   ```
   
   The output will look similar to the following:
   
   ```
   * About to connect() to masternode.example.com port 30305 (#0)
   *   Trying 12.345.678.9...
   * Connected to masternode.example.com (12.345.678.9) port 30305 (#0)
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
   > Host: masternode.example.com:30305
   > Accept: */*
   >
   < HTTP/1.1 200 OK
   < Date: Wed, 30 Sep 2020 08:56:08 GMT
   < Content-Length: 0
   < Strict-Transport-Security: max-age=15768000
   < Set-Cookie: SERVERID=pod-oimcluster-oim-server1; path=/
   < Cache-control: private
   <
   * Connection #0 to host masternode.example.com left intact
   ```
   
### Verify that You can Access the Domain URL

After setting up the Voyager ingress, verify that the domain applications are accessible through the Voyager ingress port (for example 30305) as per [Validate Domain URLs ]({{< relref "/oig/validate-domain-urls" >}})


#### Cleanup

If you need to remove the Voyager Ingress then remove the ingress with the following commands:

```
$ helm delete oimcluster-voyager -n oimcluster
$ helm delete voyager-ingress -n voyagerssl
$ kubectl delete namespace voyagerssl
```

The output will look similar to the following:

```
$ helm delete oimcluster-voyager -n oimcluster
release "oimcluster-voyager" uninstalled

$ helm delete voyager-ingress -n voyagerssl
release "voyager-ingress" uninstalled

$ kubectl delete namespace voyagerssl
namespace "voyagerssl" deleted
```
