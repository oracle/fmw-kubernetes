+++
title = "Apache webtier"
date = 2019-02-22T15:44:42-05:00
draft = false
weight = 4
pre = "<b>c. </b>"
description = "Configure the Apache webtier load balancer for an Oracle WebCenter Portal domain."
+++

To load balance Oracle WebCenter Portal domain clusters, you can install  Apache webtier and configure it for non-SSL and SSL termination access of the application URL.
Follow these steps to set up Apache webtier as a load balancer for an Oracle WebCenter Portal domain in a Kubernetes cluster:

  1. [Build the Apache webtier image](#build-the-apache-webtier-image)
  1. [Create the Apache plugin configuration file](#create-the-apache-plugin-configuration-file)
  1. [Prepare the certificate and private key](#prepare-the-certificate-and-private-key)
  1. [Install the Apache webtier Helm chart](#install-the-apache-webtier-helm-chart)
  1. [Verify domain application URL access](#verify-domain-application-url-access)
  1. [Uninstall Apache webtier](#uninstall-apache-webtier)

#### Build the Apache webtier image

To build the Apache webtier Docker image, refer to the [sample](https://github.com/oracle/docker-images/tree/master/OracleWebLogic/samples/12213-webtier-apache).

#### Create the Apache plugin configuration file

1. The configuration file named `custom_mod_wl_apache.conf` should have all the URL routing rules for the Oracle WebCenter Portal applications deployed in the domain that needs to be accessible externally. Update this file with values based on your environment. The file content is similar to below.


{{%expand "Click here to see the sample content of the configuration file custom_mod_wl_apache.conf for wcp-domain domain" %}}
```bash
$ cat ${WORKDIR}/charts/apache-samples/custom-sample/custom_mod_wl_apache.conf

#Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
  
<IfModule mod_weblogic.c>
WebLogicHost <WEBLOGIC_HOST>
WebLogicPort 7001
</IfModule>
  
# Directive for weblogic admin Console deployed on Weblogic Admin Server
<Location /console>
SetHandler weblogic-handler
WebLogicHost wcp-domain-adminserver
WebLogicPort 7001
</Location>
  
<Location /em>
SetHandler weblogic-handler
WebLogicHost wcp-domain-adminserver
WebLogicPort 7001
</Location>
 
 <Location /webcenter>
WLSRequest On
WebLogicCluster wcp-domain-cluster-wcp-cluster:8888
PathTrim /weblogic1
</Location>
 
<Location /rsscrawl>
WLSRequest On
WebLogicCluster wcp-domain-cluster-wcp-cluster:8888
PathTrim /weblogic1
</Location>  

<Location /rest>
WLSRequest On
WebLogicCluster wcp-domain-cluster-wcp-cluster:8888
PathTrim /weblogic1
</Location>

<Location /webcenterhelp>
WLSRequest On
WebLogicCluster wcp-domain-cluster-wcp-cluster:8888
PathTrim /weblogic1
</Location> 

<Location /wsrp-tools>
WLSRequest On
WebLogicCluster wcp-domain-cluster-wcportlet-cluster:8889
PathTrim /weblogic1
</Location> 

<Location /portalTools>
WLSRequest On
WebLogicCluster wcp-domain-cluster-wcportlet-cluster:8889
PathTrim /weblogic1
</Location> 
```
{{% /expand %}}

1. Update `persistentVolumeClaimName` in `${WORKDIR}/charts/apache-samples/custom-sample/input.yaml`with Persistence Volume which contains your own custom_mod_wl_apache.conf file. Use the PV/PVC created at the time of preparing environment, Copy the custom_mod_wl_apache.conf file to existing PersistantVolume.
#### Prepare the certificate and private key

1. (For the SSL termination configuration only) Run the following commands to generate your own certificate and private key using `openssl`.

      ```bash  
       $ cd ${WORKDIR}/charts/apache-samples/custom-sample
       $ export VIRTUAL_HOST_NAME=WEBLOGIC_HOST
       $ export SSL_CERT_FILE=WEBLOGIC_HOST.crt
       $ export SSL_CERT_KEY_FILE=WEBLOGIC_HOST.key
       $ sh certgen.sh
    ```
    > NOTE: Replace WEBLOGIC_HOST with the name of the host on which Apache webtier is to be installed.

   {{%expand "Click here to see the output of the certifcate generation" %}}
   ```bash
    $ls
    certgen.sh  custom_mod_wl_apache.conf  custom_mod_wl_apache.conf_orig  input.yaml  README.md
    $ sh certgen.sh
    Generating certs for WEBLOGIC_HOST
    Generating a 2048 bit RSA private key
    ........................+++
    .......................................................................+++
    unable to write 'random state'
    writing new private key to 'apache-sample.key'
    -----
    $ ls
    certgen.sh                 custom_mod_wl_apache.conf_orig                             WEBLOGIC_HOST.info
    config.txt                 input.yaml                                                 WEBLOGIC_HOST.key
    custom_mod_wl_apache.conf  WEBLOGIC_HOST.crt  README.md
   ```
   {{% /expand %}}
1. Prepare input values for the Apache webtier Helm chart.

    Run the following commands to prepare the input value file for the Apache webtier Helm chart.

    ```bash
    $ base64 -i ${SSL_CERT_FILE} | tr -d '\n'
    $ base64 -i ${SSL_CERT_KEY_FILE} | tr -d '\n'
    $ touch input.yaml
    ```

    Update `virtualHostName` with the value of the `WEBLOGIC_HOST` in file `${WORKDIR}/charts/apache-samples/custom-sample/input.yaml`

   {{%expand "Click here to see the snapshot of the sample input.yaml file " %}}
   ```bash
    $ cat apache-samples/custom-sample/input.yaml
    # Use this to provide your own Apache webtier configuration as needed; simply define this
    # path and put your own custom_mod_wl_apache.conf file under this path.
    persistentVolumeClaimName: wcp-domain-domain-pvc

    # The VirtualHostName of the Apache HTTP server. It is used to enable custom SSL configuration.
    virtualHostName: <WEBLOGIC_HOST>
   ```
   {{% /expand %}}
#### Install the Apache webtier Helm chart

1. Install the Apache webtier Helm chart to the domain `wcpns` namespace with the specified input parameters:

   ```bash
   $ cd ${WORKDIR}/charts
   $ kubectl create namespace apache-webtier
   $ helm install  apache-webtier --values apache-samples/custom-sample/input.yaml --namespace wcpns apache-webtier --set image=oracle/apache:12.2.1.3
   ```

1. Check the status of the Apache webtier:

   ```bash
    $ kubectl get all -n wcpns | grep apache
   ```

   Sample output of the status of the apache webtier:
   ```bash
   pod/apache-webtier-apache-webtier-65f69dc6bc-zg5pj   1/1     Running     0          22h
   service/apache-webtier-apache-webtier   NodePort       10.108.29.98     <none>        80:30305/TCP,4433:30443/TCP   22h
   deployment.apps/apache-webtier-apache-webtier   1/1     1            1           22h
   replicaset.apps/apache-webtier-apache-webtier-65f69dc6bc   1         1         1       22h
   ```

#### Verify domain application URL access

Once the Apache webtier load balancer is up, verify that the domain applications are accessible through the load balancer port `30305/30443`. The application URLs for domain of type `wcp` are:

> Note: Port `30305` is the LOADBALANCER-Non-SSLPORT and Port `30443` is LOADBALANCER-SSLPORT.

##### Non-SSL configuration  

   ```bash
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/console
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/em
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/webcenter
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/webcenterhelp
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/rest
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/rsscrawl

 ```

##### SSL configuration

   ```bash
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/webcenter
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/console
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/em
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/rsscrawl
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/webcenterhelp
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/rest

   ```

#### Uninstall Apache webtier

   ```bash
   $ helm delete apache-webtier -n wcpns
   ```
