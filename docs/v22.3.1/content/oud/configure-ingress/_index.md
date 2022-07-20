+++
title = "Configure an Ingress for OUD"
weight = 5 
pre = "<b>5. </b>"
description=  "This document provides steps to configure an ingress controller to direct traffic to OUD."
+++

1. [Introduction](#introduction)
1. [Install NGINX](#install-nginx)

    a. [Configure the repository](#configure-the-repository)
	
	b. [Create a namespace](#create-a-namespace)
	
	c. [Install NGINX using helm](#install-nginx-using-helm)
	
1. [Access to interfaces through ingress](#access-to-interfaces-through-ingress)

    a. [Changes in /etc/hosts to validate hostname based ingress rules](#changes-in-etchosts-to-validate-hostname-based-ingress-rules)
	
	b. [Using LDAP utilities](#using-ldap-utilities)
	
	c. [Validate access using LDAP](#validate-access-using-ldap)
	
	d. [Validate access using HTTPS](#validate-access-using-https)


### Introduction

The instructions below explain how to set up NGINX as an ingress for OUD.

By default the ingress configuration only supports HTTP and HTTPS ports. To allow LDAP and LDAPS communication over TCP, configuration is required at the ingress controller/implementation level.

### Install NGINX 

Use Helm to install NGINX.

#### Configure the repository

1. Add the Helm chart repository for installing NGINX using the following command:

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

1. Create a Kubernetes namespace for NGINX:

   ```bash
   $ kubectl create namespace <namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl create namespace mynginx
   ```
   
   The output will look similar to the following:
   
   ```
   namespace/mynginx created
   ```
   

#### Install NGINX using helm

1. Create a `$WORKDIR/kubernetes/helm/nginx-ingress-values-override.yaml` that contains the following:

   **Note**: The configuration below:

   *  Assumes that you have `oud-ds-rs` installed with value `oud-ds-rs` as a deployment/release name in the namespace `oudns`. If using a different deployment name and/or namespace change appropriately.
   * Deploys an ingress using LoadBalancer. If you prefer to use NodePort, change the configuration accordingly. For more details about NGINX configuration see: [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/user-guide/exposing-tcp-udp-services/).

   ```yaml
   # Configuration for additional TCP ports to be exposed through Ingress
   # Format for each port would be like:
   # <PortNumber>: <Namespace>/<Service>
   tcp:
     # Map 1389 TCP port to LBR LDAP service to get requests handled through any available POD/Endpoint serving LDAP Port
     1389: oudns/oud-ds-rs-lbr-ldap:ldap
     # Map 1636 TCP port to LBR LDAP service to get requests handled through any available POD/Endpoint serving LDAPS Port
     1636: oudns/oud-ds-rs-lbr-ldap:ldaps
   controller:
     admissionWebhooks:
       enabled: false
     extraArgs:
       # The secret referred to by this flag contains the default certificate to be used when accessing the catch-all server.
       # If this flag is not provided NGINX will use a self-signed certificate.
       # If the TLS Secret is in different namespace, name can be mentioned as <namespace>/<tlsSecretName>
       default-ssl-certificate: oudns/oud-ds-rs-tls-cert
     service:
       # controller service external IP addresses
       # externalIPs:
       #   - < External IP Address >
       # To configure Ingress Controller Service as LoadBalancer type of Service
       # Based on the Kubernetes configuration, External LoadBalancer would be linked to the Ingress Controller Service
       type: LoadBalancer
       # Configuration for NodePort to be used for Ports exposed through Ingress
       # If NodePorts are not defied/configured, Node Port would be assigend automatically by Kubernetes
       # These NodePorts are helpful while accessing services directly through Ingress and without having External Load Balancer.
       nodePorts:
         # For HTTP Interface exposed through LoadBalancer/Ingress
         http: 30080
         # For HTTPS Interface exposed through LoadBalancer/Ingress
         https: 30443
         tcp:
           # For LDAP Interface
           1389: 31389
           # For LDAPS Interface
           1636: 31636
   ```
   
1. To install and configure NGINX Ingress issue the following command:

   ```bash
   $ helm install --namespace <namespace> \
   --values nginx-ingress-values-override.yaml \
   lbr-nginx stable/ingress-nginx
   ```

   Where:
   * `lbr-nginx` is your deployment name
   * `stable/ingress-nginx` is the chart reference

   For example:
   
   ```bash
   $ helm install --namespace mynginx \
   --values nginx-ingress-values-override.yaml \
   lbr-nginx stable/ingress-nginx
   ```
   
   The output will look similar to the following:

   ```
   NAME: lbr-nginx
   LAST DEPLOYED: Mon Jul 11 16:49:35 2022
   NAMESPACE: mynginx
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   The ingress-nginx controller has been installed.
   It may take a few minutes for the LoadBalancer IP to be available.
   You can watch the status by running 'kubectl --namespace mynginx get services -o wide -w lbr-nginx-ingress-nginx-controller'

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


##### Optional: Command `helm upgrade` to update nginx-ingress

If required, an nginx-ingress deployment can be updated/upgraded with following command. In this example, nginx-ingress configuration is updated with an additional TCP port and Node Port for accessing the LDAP/LDAPS port of a specific POD:

1. Create a `nginx-ingress-values-override.yaml` that contains the following:

   ```yaml
   # Configuration for additional TCP ports to be exposed through Ingress
   # Format for each port would be like:
   # <PortNumber>: <Namespace>/<Service>
   tcp: 
     # Map 1389 TCP port to LBR LDAP service to get requests handled through any available POD/Endpoint serving LDAP Port
     1389: oudns/oud-ds-rs-lbr-ldap:ldap
     # Map 1636 TCP port to LBR LDAP service to get requests handled through any available POD/Endpoint serving LDAPS Port
     1636: oudns/oud-ds-rs-lbr-ldap:ldaps
     # Map specific ports for LDAP and LDAPS communication from individual Services/Pods
     # To redirect requests on 3890 port to oudns/oud-ds-rs-ldap-0:ldap
     3890: oudns/oud-ds-rs-ldap-0:ldap
     # To redirect requests on 6360 port to oudns/oud-ds-rs-ldaps-0:ldap
     6360: oudns/oud-ds-rs-ldap-0:ldaps
     # To redirect requests on 3891 port to oudns/oud-ds-rs-ldap-1:ldap
     3891: oudns/oud-ds-rs-ldap-1:ldap
     # To redirect requests on 6361 port to oudns/oud-ds-rs-ldaps-1:ldap
     6361: oudns/oud-ds-rs-ldap-1:ldaps
     # To redirect requests on 3892 port to oudns/oud-ds-rs-ldap-2:ldap
     3892: oudns/oud-ds-rs-ldap-2:ldap
     # To redirect requests on 6362 port to oudns/oud-ds-rs-ldaps-2:ldap
     6362: oudns/oud-ds-rs-ldap-2:ldaps
     # Map 1444 TCP port to LBR Admin service to get requests handled through any available POD/Endpoint serving Admin LDAPS Port
     1444: oudns/oud-ds-rs-lbr-admin:adminldaps
     # To redirect requests on 4440 port to oudns/oud-ds-rs-0:adminldaps
     4440: oudns/oud-ds-rs-0:adminldaps
     # To redirect requests on 4441 port to oudns/oud-ds-rs-1:adminldaps
     4441: oudns/oud-ds-rs-1:adminldaps
     # To redirect requests on 4442 port to oudns/oud-ds-rs-2:adminldaps
     4442: oudns/oud-ds-rs-2:adminldaps
   controller:
     admissionWebhooks:
       enabled: false
     extraArgs:
       # The secret referred to by this flag contains the default certificate to be used when accessing the catch-all server.
       # If this flag is not provided NGINX will use a self-signed certificate.
       # If the TLS Secret is in different namespace, name can be mentioned as <namespace>/<tlsSecretName>
       default-ssl-certificate: oudns/oud-ds-rs-tls-cert
     service:
       # controller service external IP addresses
       # externalIPs:
       #   - < External IP Address >
       # To configure Ingress Controller Service as LoadBalancer type of Service
       # Based on the Kubernetes configuration, External LoadBalancer would be linked to the Ingress Controller Service
       type: LoadBalancer
       # Configuration for NodePort to be used for Ports exposed through Ingress
       # If NodePorts are not defied/configured, Node Port would be assigend automatically by Kubernetes
       # These NodePorts are helpful while accessing services directly through Ingress and without having External Load Balancer.
       nodePorts:
         # For HTTP Interface exposed through LoadBalancer/Ingress
         http: 30080
         # For HTTPS Interface exposed through LoadBalancer/Ingress
         https: 30443
         tcp:
           # For LDAP Interface referring to LBR LDAP services serving LDAP port
           1389: 31389
           # For LDAPS Interface referring to LBR LDAP services serving LDAPS port
           1636: 31636
           # For LDAP Interface from specific service oud-ds-rs-ldap-0
           3890: 30890
           # For LDAPS Interface from specific service oud-ds-rs-ldap-0
           6360: 30360
           # For LDAP Interface from specific service oud-ds-rs-ldap-1
           3891: 30891
           # For LDAPS Interface from specific service oud-ds-rs-ldap-1
           6361: 30361
           # For LDAP Interface from specific service oud-ds-rs-ldap-2
           3892: 30892
           # For LDAPS Interface from specific service oud-ds-rs-ldap-2
           6362: 30362
           # For LDAPS Interface referring to LBR Admin services serving adminldaps port
           1444: 31444
           # For Admin LDAPS Interface from specific service oud-ds-rs-0
           4440: 30440
           # For Admin LDAPS Interface from specific service oud-ds-rs-1
           4441: 30441
           # For Admin LDAPS Interface from specific service oud-ds-rs-2
           4442: 30442
   ```


1. Run the following command to upgrade the ingress:

   ```bash
   $ helm upgrade --namespace <namespace> \
   --values nginx-ingress-values-override.yaml \
   lbr-nginx stable/ingress-nginx 
   ```
   
   Where:
   * `lbr-nginx` is your deployment name
   * `stable/ingress-nginx` is the chart reference

   For example:
   
   ```bash
   $ helm upgrade --namespace mynginx \
   --values nginx-ingress-values-override.yaml \
   lbr-nginx stable/ingress-nginx 
   ```
   
### Access to interfaces through ingress

Using the Helm chart, ingress objects are created according to configuration. The following table details the rules configured in ingress object(s) for access to Oracle Unified Directory Interfaces through ingress.

| **Port** | **NodePort** | **Host** | **Example Hostname** | **Path** | **Backend Service:Port** | **Example Service Name:Port** | 
| ------ | ------ | ------ | ------ | ------ | ------ | ------ |  
| http/https | 30080/30443 | <deployment/release name>-admin-0 | oud-ds-rs-admin-0 | * | <deployment/release name>-0:adminhttps | oud-ds-rs-0:adminhttps | 
| http/https | 30080/30443 | <deployment/release name>-admin-N | oud-ds-rs-admin-N | * | <deployment/release name>-N:adminhttps | oud-ds-rs-1:adminhttps | 
| http/https | 30080/30443 | <deployment/release name>-admin | oud-ds-rs-admin | * | <deployment/release name>-lbr-admin:adminhttps | oud-ds-rs-lbr-admin:adminhttps | 
| http/https | 30080/30443 | * | * | /rest/v1/admin | <deployment/release name>-lbr-admin:adminhttps | oud-ds-rs-lbr-admin:adminhttps | 
| http/https | 30080/30443 | <deployment/release name>-http-0 | oud-ds-rs-http-0 | * | <deployment/release name>-http-0:http | oud-ds-rs-http-0:http | 
| http/https | 30080/30443 | <deployment/release name>-http-N | oud-ds-rs-http-N | * | <deployment/release name>-http-N:http | oud-ds-rs-http-N:http | 
| http/https | 30080/30443 | <deployment/release name>-http | oud-ds-rs-http | * | <deployment/release name>-lbr-http:http | oud-ds-rs-lbr-http:http | 
| http/https | 30080/30443 | * | * | /rest/v1/directory | <deployment/release name>-lbr-http:http | oud-ds-rs-lbr-http:http | 
| http/https | 30080/30443 | * | * | /iam/directory | <deployment/release name>-lbr-http:http | oud-ds-rs-lbr-http:http | 

> In the table above, example values are based on the value 'oud-ds-rs' as the deployment/release name for Helm chart installation.<br>
> The NodePorts mentioned in the table are according to ingress configuration described in previous section.<br>
> When External LoadBalancer is not available/configured, interfaces can be accessed through NodePort on a Kubernetes node.

For LDAP/LDAPS access (based on the updated/upgraded configuration mentioned in previous section)

| **Port** | **NodePort** | **Backend Service:Port** | **Example Service Name:Port** | 
| ------ | ------ | ------ | ------ | 
| 1389 | 31389 | <deployment/release name>-lbr-ldap:ldap | oud-ds-rs-lbr-ldap:ldap | 
| 1636 | 31636 | <deployment/release name>-lbr-ldap:ldap | oud-ds-rs-lbr-ldap:ldaps |
| 1444 | 31444 | <deployment/release name>-lbr-admin:adminldaps | oud-ds-rs-lbr-admin:adminldaps |
| 3890 | 30890 | <deployment/release name>-ldap-0:ldap | oud-ds-rs-ldap-0:ldap | 
| 6360 | 30360 | <deployment/release name>-ldap-0:ldaps | oud-ds-rs-ldap-0:ldaps | 
| 3891 | 30891 | <deployment/release name>-ldap-1:ldap | oud-ds-rs-ldap-1:ldap | 
| 6361 | 30361 | <deployment/release name>-ldap-1:ldaps | oud-ds-rs-ldap-1:ldaps | 
| 3892 | 30892 | <deployment/release name>-ldap-2:ldap | oud-ds-rs-ldap-2:ldap | 
| 6362 | 30362 | <deployment/release name>-ldap-2:ldaps | oud-ds-rs-ldap-2:ldaps |
| 4440 | 30440 | <deployment/release name>-0:adminldaps | oud-ds-rs-ldap-0:adminldaps |
| 4441 | 30441 | <deployment/release name>-1:adminldaps | oud-ds-rs-ldap-1:adminldaps |
| 4442 | 30442 | <deployment/release name>-2:adminldaps | oud-ds-rs-ldap-2:adminldaps |

* In the table above, example values are based on value 'oud-ds-rs' as the deployment/release name for helm chart installation.
* The NodePorts mentioned in the table are according to Ingress configuration described in previous section.
* When external LoadBalancer is not available/configured, Interfaces can be accessed through NodePort on a Kubernetes Node.

#### Changes in /etc/hosts to validate hostname based ingress rules

If it is not possible to have a LoadBalancer configuration updated to have host names added for Oracle Unified Directory Interfaces then the following entries can be added in `/etc/hosts` files on the host from where Oracle Unified Directory interfaces will be accessed. 

```
<IP Address of External LBR or Kubernetes Node>	oud-ds-rs-http oud-ds-rs-http-0 oud-ds-rs-http-1 oud-ds-rs-http-2 oud-ds-rs-http-N
<IP Address of External LBR or Kubernetes Node>	oud-ds-rs-admin oud-ds-rs-admin-0 oud-ds-rs-admin-1 oud-ds-rs-admin-2 oud-ds-rs-admin-N
```

* In the table above, host names are based on the value 'oud-ds-rs' as the deployment/release name for Helm chart installation.
* When External LoadBalancer is not available/configured, Interfaces can be accessed through NodePort on Kubernetes Node.


#### Using LDAP utilities

To use Oracle LDAP utilities such as `ldapbind`, `ldapsearch`, `ldapmodify` etc. you can either:

* Run the LDAP commands from an OUD installation outside the Kubernetes cluster. This requires access to an On-Premises OUD installation oustide the Kubernetes cluster.

* Run the LDAP commands from inside the OUD Kubernetes pod.

   ```bash
   $ kubectl exec -ti <pod> -n <namespace> -- bash
   ```
   
   For example:
   
   ```bash
   $ kubectl exec -ti oud-ds-rs-0 -n oudns -- bash
   ```
   
   This will take you into a bash session in the pod:

   ```bash
   [oracle@oud-ds-rs-0 oracle]$    
   ```
   
   Inside the container navigate to `/u01/oracle/oud/bin` to view the LDAP utilties:

   ```bash
   [oracle@oud-ds-rs-0 oracle]$ cd /u01/oracle/oud/bin
   [oracle@oud-ds-rs-0 bin]$ ls ldap*
   ldapcompare  ldapdelete  ldapmodify  ldappasswordmodify  ldapsearch
   ```

   **Note**: For commands that require an ldif file, copy the file into the `<persistent_volume>/oud_user_projects` directory:
  
   ```bash
   $ cp file.ldif <peristent_volume>/oud_user_projects
   ```
  
   For example:
  
   ```bash
   $ cp file.ldif /scratch/shared/oud_user_projects
   ```
  
   The file can then be viewed inside the pod:
  
   ```bash
   [oracle@oud-ds-rs-0 bin]$ cd /u01/oracle/oud_user_projects
   [oracle@oud-ds-rs-0 user_projects]$ ls *.ldif
   file.ldif
   ```

#### Validate access using LDAP

**Note**: The examples assume sample data was installed when creating the OUD instance.


##### LDAP against External Load Balancer

**Note** If your ingress is configured with `type: LoadBalancer` then you cannot connect to the external LoadBalancer hostname and ports from inside the pod and must connect from an OUD installation outside the cluster.


* Command to perform `ldapsearch` against External LBR and LDAP port

   ```bash
   $OUD_HOME/bin/ldapsearch --hostname <External LBR> --port 1389 \
   -D "<Root User DN>" -w <Password for Root User DN> \
   -b "" -s base "(objectClass=*)" "*"
   ```

   
   The output will look similar to the following:
 
   ```ldif
   dn: 
   objectClass: top
   objectClass: ds-root-dse
   lastChangeNumber: 0
   firstChangeNumber: 0
   changelog: cn=changelog
   entryDN: 
   pwdPolicySubentry: cn=Default Password Policy,cn=Password Policies,cn=config
   subschemaSubentry: cn=schema
   supportedAuthPasswordSchemes: SHA256
   supportedAuthPasswordSchemes: SHA1
   supportedAuthPasswordSchemes: SHA384
   supportedAuthPasswordSchemes: SHA512
   supportedAuthPasswordSchemes: MD5
   numSubordinates: 1
   supportedFeatures: 1.3.6.1.1.14
   supportedFeatures: 1.3.6.1.4.1.4203.1.5.1
   supportedFeatures: 1.3.6.1.4.1.4203.1.5.2
   supportedFeatures: 1.3.6.1.4.1.4203.1.5.3
   lastExternalChangelogCookie: 
   vendorName: Oracle Corporation
   vendorVersion: Oracle Unified Directory 12.2.1.4.0
   componentVersion: 4
   releaseVersion: 1
   platformVersion: 0
   supportedLDAPVersion: 2
   supportedLDAPVersion: 3
   supportedControl: 1.2.826.0.1.3344810.2.3
   supportedControl: 1.2.840.113556.1.4.1413
   supportedControl: 1.2.840.113556.1.4.319
   supportedControl: 1.2.840.113556.1.4.473
   supportedControl: 1.2.840.113556.1.4.805
   supportedControl: 1.3.6.1.1.12
   supportedControl: 1.3.6.1.1.13.1
   supportedControl: 1.3.6.1.1.13.2
   supportedControl: 1.3.6.1.4.1.26027.1.5.2
   supportedControl: 1.3.6.1.4.1.26027.1.5.4
   supportedControl: 1.3.6.1.4.1.26027.1.5.5
   supportedControl: 1.3.6.1.4.1.26027.1.5.6
   supportedControl: 1.3.6.1.4.1.26027.2.3.1
   supportedControl: 1.3.6.1.4.1.26027.2.3.2
   supportedControl: 1.3.6.1.4.1.26027.2.3.4
   supportedControl: 1.3.6.1.4.1.42.2.27.8.5.1
   supportedControl: 1.3.6.1.4.1.42.2.27.9.5.2
   supportedControl: 1.3.6.1.4.1.42.2.27.9.5.8
   supportedControl: 1.3.6.1.4.1.4203.1.10.1
   supportedControl: 1.3.6.1.4.1.4203.1.10.2
   supportedControl: 2.16.840.1.113730.3.4.12
   supportedControl: 2.16.840.1.113730.3.4.16
   supportedControl: 2.16.840.1.113730.3.4.17
   supportedControl: 2.16.840.1.113730.3.4.18
   supportedControl: 2.16.840.1.113730.3.4.19
   supportedControl: 2.16.840.1.113730.3.4.2
   supportedControl: 2.16.840.1.113730.3.4.3
   supportedControl: 2.16.840.1.113730.3.4.4
   supportedControl: 2.16.840.1.113730.3.4.5
   supportedControl: 2.16.840.1.113730.3.4.9
   supportedControl: 2.16.840.1.113894.1.8.21
   supportedControl: 2.16.840.1.113894.1.8.31
   supportedControl: 2.16.840.1.113894.1.8.36
   maintenanceVersion: 2
   supportedSASLMechanisms: PLAIN
   supportedSASLMechanisms: EXTERNAL
   supportedSASLMechanisms: CRAM-MD5
   supportedSASLMechanisms: DIGEST-MD5
   majorVersion: 12
   orclGUID: D41D8CD98F003204A9800998ECF8427E
   entryUUID: d41d8cd9-8f00-3204-a980-0998ecf8427e
   ds-private-naming-contexts: cn=schema
   hasSubordinates: true
   nsUniqueId: d41d8cd9-8f003204-a9800998-ecf8427e
   structuralObjectClass: ds-root-dse
   supportedExtension: 1.3.6.1.4.1.4203.1.11.1
   supportedExtension: 1.3.6.1.4.1.4203.1.11.3
   supportedExtension: 1.3.6.1.1.8
   supportedExtension: 1.3.6.1.4.1.26027.1.6.3
   supportedExtension: 1.3.6.1.4.1.26027.1.6.2
   supportedExtension: 1.3.6.1.4.1.26027.1.6.1
   supportedExtension: 1.3.6.1.4.1.1466.20037
   namingContexts: cn=changelog
   namingContexts: dc=example,dc=com
   ```

* Command to perform `ldapsearch` against External LBR and LDAP port for specific Oracle Unified Directory Interface

   ```bash
   $OUD_HOME/bin/ldapsearch --hostname <External LBR> --port 3890 \
   -D "<Root User DN>" -w <Password for Root User DN> \
   -b "" -s base "(objectClass=*)" "*"
   ```

##### LDAPS against Kubernetes NodePort for Ingress Controller Service

In the example below LDAP utilities are executed from inside the `oud-ds-rs-0` pod.  If your ingress is configured with `type: LoadBalancer` you can connect to the Kubernetes hostname where the ingress is deployed using the NodePorts.


* Command to perform `ldapsearch` against Kubernetes NodePort and LDAP port

   ```bash
   [oracle@oud-ds-rs-0 bin]$ ldapsearch --hostname <Kubernetes Node> --port 31636 \
   --useSSL --trustAll \
   -D "<Root User DN>" -w <Password for Root User DN> \
   -b "" -s base "(objectClass=*)" "*"
   ```
 

   
#### Validate access using HTTPS

##### HTTPS/REST API against External LBR Host:Port

**Note**: In all the examples below:

a) You need to have an external IP assigned at ingress level. 

b) `| json_pp` is used to format output in readable json format on the client side. It can be ignored if you do not have the `json_pp` library.

c) Base64 of `userDN:userPassword` can be generated using `echo -n "userDN:userPassword" | base64`.




* Command to invoke Data REST API: 

   ```bash
   $curl --noproxy "*" -k  --location \
   --request GET 'https://<External LBR Host>/rest/v1/directory/uid=user.1,ou=People,dc=example,dc=com?scope=sub&attributes=*' \
   --header 'Authorization: Basic <Base64 of userDN:userPassword>' | json_pp
   ```
   
   The output will look similar to the following: 

   ```json
   {
      "msgType" : "urn:ietf:params:rest:schemas:oracle:oud:1.0:SearchResponse",
      "totalResults" : 1,
      "searchResultEntries" : [
         {
            "dn" : "uid=user.1,ou=People,dc=example,dc=com",
            "attributes" : {
               "st" : "OH",
               "employeeNumber" : "1",
               "postalCode" : "93694",
               "description" : "This is the description for Aaren Atp.",
               "telephoneNumber" : "+1 390 103 6917",
               "homePhone" : "+1 280 375 4325",
               "initials" : "ALA",
               "objectClass" : [
                  "top",
                  "inetorgperson",
                  "organizationalperson",
                  "person"
               ],
               "uid" : "user.1",
               "sn" : "Atp",
               "street" : "70110 Fourth Street",
               "mobile" : "+1 680 734 6300",
               "givenName" : "Aaren",
               "mail" : "user.1@maildomain.net",
               "l" : "New Haven",
               "postalAddress" : "Aaren Atp$70110 Fourth Street$New Haven, OH  93694",
               "pager" : "+1 850 883 8888",
               "cn" : "Aaren Atp"
            }
         }
       ]
   }
   ```

* Command to invoke Data REST API against specific Oracle Unified Directory Interface: 

   ```bash
   $ curl --noproxy "*" -k  --location \
   --request GET 'https://oud-ds-rs-http-0/rest/v1/directory/uid=user.1,ou=People,dc=example,dc=com?scope=sub&attributes=*' \
   --header 'Authorization: Basic <Base64 of userDN:userPassword>' | json_pp
   ```

   * For this example, it is assumed that the value 'oud-ds-rs' is used as the deployment/release name for helm chart installation.
   * It is assumed that 'oud-ds-rs-http-0' points to an External LoadBalancer

##### HTTPS/REST API against Kubernetes NodePort for Ingress Controller Service

**Note**: In all the examples below:
 
a) `| json_pp` is used to format output in readable json format on the client side. It can be ignored if you do not have the `json_pp` library.

b) Base64 of `userDN:userPassword` can be generated using `echo -n "userDN:userPassword" | base64`.

c) It is assumed that the value 'oud-ds-rs' is used as the deployment/release name for helm chart installation.

   
   
* Command to invoke Data SCIM API: 

   ```bash
   $ curl --noproxy "*" -k --location \
   --request GET 'https://<Kubernetes Node>:30443/iam/directory/oud/scim/v1/Users' \
   --header 'Authorization: Basic <Base64 of userDN:userPassword>' | json_pp
   ```

   The output will look similar to the following: 
   
   ```json
   {
      "Resources" : [
         {
            "id" : "ad55a34a-763f-358f-93f9-da86f9ecd9e4",
            "userName" : [
               {
                  "value" : "user.0"
               }
            ],
            "schemas" : [
               "urn:ietf:params:scim:schemas:core:2.0:User",
               "urn:ietf:params:scim:schemas:extension:oracle:2.0:OUD:User",
               "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User"
            ],
            "meta" : {
               "location" : "http://<Kubernetes Node>:30443/iam/directory/oud/scim/v1/Users/ad55a34a-763f-358f-93f9-da86f9ecd9e4",
               "resourceType" : "User"
            },
            "addresses" : [
               {
                  "postalCode" : "50369",
                  "formatted" : "Aaccf Amar$01251 Chestnut Street$Panama City, DE  50369",
                  "streetAddress" : "01251 Chestnut Street",
                  "locality" : "Panama City",
                  "region" : "DE"
               }
            ],
            "urn:ietf:params:scim:schemas:extension:oracle:2.0:OUD:User" : {
               "description" : [
                  {
                     "value" : "This is the description for Aaccf Amar."
                  }
               ],
               "mobile" : [
                  {
                     "value" : "+1 010 154 3228"
                  }
               ],
               "pager" : [
                  {
                     "value" : "+1 779 041 6341"
                  }
               ],
               "objectClass" : [
                  {
                     "value" : "top"
                  },
                  {
                     "value" : "organizationalperson"
                  },
                  {
                     "value" : "person"
                  },
                  {
                     "value" : "inetorgperson"
                  }
               ],
               "initials" : [
                  {
                     "value" : "ASA"
                  }
               ],
               "homePhone" : [
                  {
                     "value" : "+1 225 216 5900"
                  }
               ]
            },
            "name" : [
               {
                  "givenName" : "Aaccf",
                  "familyName" : "Amar",
                  "formatted" : "Aaccf Amar"
               }
            ],
            "emails" : [
               {
                  "value" : "user.0@maildomain.net"
               }
            ],
            "phoneNumbers" : [
               {
                  "value" : "+1 685 622 6202"
               }
            ],
            "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User" : {
               "employeeNumber" : [
                  {
                     "value" : "0"
                  }
               ]
            }
         }
         ,
    .
    .
    .
    }
   ```

* Command to invoke Data SCIM API against specific Oracle Unified Directory Interface: 

   ```bash
   $ curl --noproxy "*" -k --location \
   --request GET 'https://oud-ds-rs-http-0:30443/iam/directory/oud/scim/v1/Users' \
   --header 'Authorization: Basic <Base64 of userDN:userPassword>' | json_pp
   ```

   

##### HTTPS/REST Admin API

**Note**: In all the examples below:

a) `| json_pp` is used to format output in readable json format on the client side. It can be ignored if you do not have the `json_pp` library.

b) Base64 of `userDN:userPassword` can be generated using `echo -n "userDN:userPassword" | base64`.

* Command to invoke Admin REST API against External LBR: 

   ```bash
   $ curl --noproxy "*" -k --insecure --location \
   --request GET 'https://<External LBR Host>/rest/v1/admin/?scope=base&attributes=vendorName&attributes=vendorVersion&attributes=ds-private-naming-contexts&attributes=subschemaSubentry' \
   --header 'Content-Type: application/json' \
   --header 'Authorization: Basic <Base64 of userDN:userPassword>' | json_pp
   ```

   The output will look similar to the following: 

   ```json
   {
      "totalResults" : 1,
      "searchResultEntries" : [
         {
            "dn" : "",
            "attributes" : {
               "vendorVersion" : "Oracle Unified Directory 12.2.1.4.0",
               "ds-private-naming-contexts" : [
                  "cn=admin data",
                  "cn=ads-truststore",
                  "cn=backups",
                  "cn=config",
                  "cn=monitor",
                  "cn=schema",
                  "cn=tasks",
                  "cn=virtual acis",
                  "dc=replicationchanges"
               ],
               "subschemaSubentry" : "cn=schema",
               "vendorName" : "Oracle Corporation"
            }
         }
      ],
      "msgType" : "urn:ietf:params:rest:schemas:oracle:oud:1.0:SearchResponse"
   }
   ```

* Command to invoke Admin REST API against specific Oracle Unified Directory Admin Interface: 

   ```bash
   $ curl --noproxy "*" -k --insecure --location \
   --request GET 'https://oud-ds-rs-admin-0/rest/v1/admin/?scope=base&attributes=vendorName&attributes=vendorVersion&attributes=ds-private-naming-contexts&attributes=subschemaSubentry' \
   --header 'Content-Type: application/json' \
   --header 'Authorization: Basic <Base64 of userDN:userPassword>' | json_pp
   ```

   
* Command to invoke Admin REST API against Kubernetes NodePort for Ingress Controller Service 

   ```bash
   $ curl --noproxy "*" -k --insecure --location \
   --request GET 'https://oud-ds-rs-admin-0:30443/rest/v1/admin/?scope=base&attributes=vendorName&attributes=vendorVersion&attributes=ds-private-naming-contexts&attributes=subschemaSubentry' \
   --header 'Content-Type: application/json' \
   --header 'Authorization: Basic <Base64 of userDN:userPassword>' | json_pp
   ```