---
title: "Apache webtier"
date: 2021-15-02 T15:44:42-05:00
draft: false
weight: 4
pre: "<b>d. </b>"
description: "Configure the Apache webtier load balancer for Oracle WebCenter Content domain."
---

This section provides information about how to install and configure *Apache webtier* to load balance Oracle  WebCenter Content domain clusters. You can configure Apache webtier for non-SSL and SSL termination access of the application URL.

Follow these steps to set up Apache webtier as a load balancer for an Oracle WebCenter Content domain in a Kubernetes cluster:

  1. [Build the Apache webtier image](#build-the-apache-webtier-image)
  1. [Create the Apache plugin configuration file](#create-the-apache-plugin-configuration-file)
  1. [Prepare the certificate and private key](#prepare-the-certificate-and-private-key)
  1. [Install the Apache webtier Helm chart](#install-the-apache-webtier-helm-chart)
  1. [Verify domain application URL access](#verify-domain-application-url-access)
  1. [Uninstall Apache webtier](#uninstall-apache-webtier)

#### Build the Apache webtier image

Refer to the [sample](https://github.com/oracle/docker-images/tree/master/OracleWebLogic/samples/12213-webtier-apache), to build the Apache webtier Docker image.

#### Create the Apache plugin configuration file

1. The configuration file named `custom_mod_wl_apache.conf` should have all the URL routing rules for the Oracle WebCenter Content application deployed in the domain that needs to be accessible externally. Update this file with values based on your environment. The file content is similar to below mentioned sample.

{{%expand "Click here to see the sample content of the configuration file custom_mod_wl_apache.conf for Oracle WebCenter Content domain" %}}

```bash
# Copyright (c) 2018, 2020, Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

<IfModule mod_weblogic.c>
WebLogicHost  <WEBLOGIC_HOST>
WebLogicPort  7001
</IfModule>

# Directive for weblogic admin Console deployed on Weblogic Admin Server
<Location /console>
SetHandler weblogic-handler
WebLogicHost wccinfra-adminserver
WebLogicPort 7001
</Location>

<Location /em>
SetHandler weblogic-handler
WebLogicHost wccinfra-adminserver
WebLogicPort 7001
</Location>

<Location /weblogic/ready>
SetHandler weblogic-handler
WebLogicHost wccinfra-adminserver
WebLogicPort 7001
</Location>
# Directive for all application deployed on weblogic cluster with a prepath defined by LOCATION variable
# For example, if the LOCAITON is set to '/weblogic', all applications deployed on the cluster can be accessed via
# http://myhost:myport/weblogic/application_end_url
# where 'myhost' is the IP of the machine that runs the Apache web tier, and
#       'myport' is the port that the Apache web tier is publicly exposed to.
# Note that LOCATION cannot be set to '/' unless this is the only Location module configured.
<Location /cs>
WLSRequest On
WebLogicCluster wccinfra-cluster-ucm-cluster:16200
PathTrim /weblogic1
</Location>

<Location /adfAuthentication>
WLSRequest On
WebLogicCluster wccinfra-cluster-ucm-cluster:16200
PathTrim /weblogic1
</Location>

<Location /ibr>
WLSRequest On
WebLogicCluster wccinfra-cluster-ibr-cluster:16250
PathTrim /weblogic1
</Location>

<Location /ibr/adfAuthentication>
WLSRequest On
WebLogicCluster wccinfra-cluster-ibr-cluster:16250
PathTrim /weblogic1
</Location>

# Directive for all application deployed on weblogic cluster with a prepath defined by LOCATION2 variable
# For example, if the LOCAITON2 is set to '/weblogic2', all applications deployed on the cluster can be accessed via
# http://myhost:myport/weblogic2/application_end_url
# where 'myhost' is the IP of the machine that runs the Apache web tier, and
#       'myport' is the port that the Apache webt ier is publicly exposed to.
#<Location /weblogic2>
#WLSRequest On
#WebLogicCluster domain2-cluster-cluster-1:8021
#PathTrim /weblogic2
#</Location>

```
{{% /expand %}}



1. Update `persistentVolumeClaimName` with your PV-claim-name which contains your `custom_mod_wl_apache.conf` in file `kubernetes/samples/charts/apache-samples/custom-sample/input.yaml`.

#### Prepare the certificate and private key

1. (For the SSL termination configuration only) Run the following commands to generate your own certificate and private key using `openssl`.

      ```bash     
       $ cd ${WORKDIR}/weblogic-kubernetes-operator
       $ cd kubernetes/samples/charts/apache-samples/custom-sample
       $ export VIRTUAL_HOST_NAME=WEBLOGIC_HOST
       $ export SSL_CERT_FILE=WEBLOGIC_HOST.crt
       $ export SSL_CERT_KEY_FILE=WEBLOGIC_HOST.key
       $ sh certgen.sh
    ```
    > NOTE: Replace WEBLOGIC_HOST with the host name on which Apache webtier is to be installed.

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

    Update `virtualHostName` with the value of the `WEBLOGIC_HOST` in file `kubernetes/samples/charts/apache-samples/custom-sample/input.yaml`

   {{%expand "Click here to see the snapshot of the sample input.yaml file " %}}
   ```bash
    $ cat apache-samples/custom-sample/input.yaml
    # Use this to provide your own Apache webtier configuration as needed; simply define this
    # path and put your own custom_mod_wl_apache.conf file under this path.
    persistentVolumeClaimName: <pv-claim-name>

    # The VirtualHostName of the Apache HTTP server. It is used to enable custom SSL configuration.
    virtualHostName: <WEBLOGIC_HOST>
   ```
   {{% /expand %}}

#### Install the Apache webtier Helm chart

1. Install the Apache webtier Helm chart to the domain `wccns` namespace with the specified input parameters:

   ```bash
   $ cd ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts
   $ kubectl create namespace apache-webtier
   
   $ helm install  apache-webtier --values apache-samples/custom-sample/input.yaml --namespace wccns apache-webtier --set image=oracle/apache:12.2.1.3
   ```

1. Check the status of the Apache webtier:

   ```bash
    $ kubectl get all -n wccns | grep apache
   ```

   Sample output of the status of the apache webtier:
```bash
pod/apache-webtier-new-apache-webtier-65d8d7c59f-k27wf         1/1     Running     0          9d
service/apache-webtier-new-apache-webtier         NodePort    10.108.12.143    <none>            80:30505/TCP,4433:30453/TCP   9d
deployment.apps/apache-webtier-new-apache-webtier         1/1     1            1           9d
replicaset.apps/apache-webtier-new-apache-webtier-65d8d7c59f         1         1         1       9d

```

#### Verify domain application URL access

Post the Apache webtier load balancer is up, verify that the domain applications are accessible through the load balancer port `30505/30453`. The application URLs for domain of type `wcc` are:

> Note: Port `30505` is the LOADBALANCER-Non-SSLPORT and Port `30453` is LOADBALANCER-SSLPORT.

##### Non-SSL configuration  

   ```bash
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/weblogic/ready
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/console
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/em
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/cs
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/ibr
   ```

##### SSL configuration

   ```bash
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/weblogic/ready
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/console
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/em
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/cs
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/ibr
   ```

#### Uninstall Apache webtier

   ```bash
   $ helm delete apache-webtier -n wccns
   ```
