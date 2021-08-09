---
title: "Apache web tier"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 4
pre: "<b>d. </b>"
description: "Configure the Apache web tier load balancer for Oracle SOA Suite domains."
---

This section provides information about how to install and configure the *Apache web tier* to load balance Oracle SOA Suite domain clusters. You can configure Apache web tier for non-SSL and SSL termination access of the application URL.

Follow these steps to set up the Apache web tier as a load balancer for an Oracle SOA Suite domain in a Kubernetes cluster:

  1. [Build the Apache web tier image](#build-the-apache-web-tier-image)
  1. [Create the Apache plugin configuration file](#create-the-apache-plugin-configuration-file)
  1. [Prepare the certificate and private key](#prepare-the-certificate-and-private-key)
  1. [Install the Apache web tier Helm chart](#install-the-apache-web-tier-helm-chart)
  1. [Verify domain application URL access](#verify-domain-application-url-access)
  1. [Uninstall Apache web tier](#uninstall-apache-web-tier)

#### Build the Apache web tier image

Refer to the [sample](https://github.com/oracle/docker-images/tree/main/OracleWebLogic/samples/12213-webtier-apache), to build the Apache web tier Docker image.

#### Create the Apache plugin configuration file

1. The configuration file named `custom_mod_wl_apache.conf` should have all the URL routing rules for the Oracle SOA Suite applications deployed in the domain that needs to be accessible externally. Update this file with values based on your environment. The file content is similar to below.


   {{%expand "Click here to see the sample content of the configuration file custom_mod_wl_apache.conf for soa domain" %}}
   ```bash

    # Copyright (c) 2020 Oracle and/or its affiliates.
    #
    # Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
    #

    <IfModule mod_weblogic.c>
    WebLogicHost <WEBLOGIC_HOST>
    WebLogicPort 7001
    </IfModule>

    # Directive for weblogic admin Console deployed on WebLogic Admin Server

    <Location /console>
    SetHandler weblogic-handler
    WebLogicHost soainfra-adminserver
    WebLogicPort 7001
    </Location>

    <Location /em>
    SetHandler weblogic-handler
    WebLogicHost soainfra-adminserver
    WebLogicPort 7001
    </Location>

    <Location /servicebus>
    SetHandler weblogic-handler
    WebLogicHost soainfra-adminserver
    WebLogicPort 7001
    </Location>

    <Location /lwpfconsole>
    SetHandler weblogic-handler
    WebLogicHost soainfra-adminserver
    WebLogicPort 7001
    </Location>

    <Location /xbusrouting>
    SetHandler weblogic-handler
    WebLogicHost soainfra-adminserver
    WebLogicPort 7001
    </Location>

    <Location /xbustransform>
    SetHandler weblogic-handler
    WebLogicHost soainfra-adminserver
    WebLogicPort 7001
    </Location>

    <Location /weblogic/ready>
    SetHandler weblogic-handler
    WebLogicHost soainfra-adminserver
    WebLogicPort 7001
    </Location>
   # Directive for all applications deployed on weblogic cluster with a prepath defined by LOCATION variable.
   # For example, if the LOCATION is set to '/weblogic', all applications deployed on the cluster can be accessed via
   # http://myhost:myport/weblogic/application_end_url
   # where 'myhost' is the IP of the machine that runs the Apache web tier, and
   #       'myport' is the port that the Apache web tier is publicly exposed to.
   # Note that LOCATION cannot be set to '/' unless this is the only Location module configured.
   <Location /soa-infra>
   WLSRequest On
   WebLogicCluster soainfra-cluster-soa-cluster:8001
   PathTrim /weblogic1
   </Location>

   <Location /soa/composer>
    WLSRequest On
    WebLogicCluster soainfra-cluster-soa-cluster:8001
    PathTrim /weblogic1
   </Location>

   <Location /integration/worklistapp>
   WLSRequest On
   WebLogicCluster soainfra-cluster-soa-cluster:8001
   PathTrim /weblogic1
   </Location>

   <Location /ess>
   WLSRequest On
   WebLogicCluster soainfra-cluster-soa-cluster:8001
   PathTrim /weblogic1
   </Location>

   <Location /EssHealthCheck>
   WLSRequest On
   WebLogicCluster soainfra-cluster-soa-cluster:8001
   PathTrim /weblogic1
   </Location>

   # Directive for all application deployed on weblogic cluster with a prepath defined by LOCATION2 variable
   # For example, if the LOCATION2 is set to '/weblogic2', all applications deployed on the cluster can be accessed via
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

1. Create a PV and PVC (pv-claim-name) that can be used to store the custom_mod_wl_apache.conf. Refer to the [Sample](https://github.com/oracle/weblogic-kubernetes-operator/blob/v3.2.1/kubernetes/samples/scripts/create-weblogic-domain-pv-pvc/README.md) for creating a PV or PVC.

#### Prepare the certificate and private key

1. (For the SSL termination configuration only) Run the following commands to generate your own certificate and private key using `openssl`.

      ```bash     
       $ cd ${WORKDIR}
       $ cd charts/apache-samples/custom-sample
       $ export VIRTUAL_HOST_NAME=WEBLOGIC_HOST
       $ export SSL_CERT_FILE=WEBLOGIC_HOST.crt
       $ export SSL_CERT_KEY_FILE=WEBLOGIC_HOST.key
       $ sh certgen.sh
    ```
    > NOTE: Replace WEBLOGIC_HOST with the host name on which Apache web tier is to be installed.

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

1. Prepare input values for the Apache web tier Helm chart.

    Run the following commands to prepare the input value file for the Apache web tier Helm chart.

    ```bash
    $ base64 -i ${SSL_CERT_FILE} | tr -d '\n'
    $ base64 -i ${SSL_CERT_KEY_FILE} | tr -d '\n'
    $ touch input.yaml
    ```

    Update the input parameters file, `charts/apache-samples/custom-sample/input.yaml`.

   {{%expand "Click here to see the snapshot of the sample input.yaml file " %}}
   ```bash
    $ cat apache-samples/custom-sample/input.yaml
    # Use this to provide your own Apache web tier configuration as needed; simply define this
    # Persistence Volume which contains your own custom_mod_wl_apache.conf file.
    persistentVolumeClaimName: <pv-claim-name>

    # The VirtualHostName of the Apache HTTP server. It is used to enable custom SSL configuration.
    virtualHostName: <WEBLOGIC_HOST>

    # The customer-supplied certificate to use for Apache web tier SSL configuration.
    # The value must be a string containing a base64 encoded certificate. Run following command to get it.
    # base64 -i ${SSL_CERT_FILE} | tr -d '\n'
    customCert: <cert_data>

    # The customer-supplied private key to use for Apache web tier SSL configuration.
    # The value must be a string containing a base64 encoded key. Run following command to get it.
    # base64 -i ${SSL_KEY_FILE} | tr -d '\n'
    customKey: <key_data>
   ```
   {{% /expand %}}

#### Install the Apache web tier Helm chart

1. Install the Apache web tier Helm chart to the domain `soans` namespace with the specified input parameters:

   ```bash
   $ cd ${WORKDIR}/charts
   $ kubectl create namespace apache-webtier
   $ helm install apache-webtier --values apache-samples/custom-sample/input.yaml --namespace soans apache-webtier --set image=oracle/apache:12.2.1.3
   ```

1. Check the status of the Apache web tier:

   ```bash
    $ kubectl get all -n soans | grep apache
   ```

   Sample output of the status of the Apache web tier:
   ```bash
   pod/apache-webtier-apache-webtier-65f69dc6bc-zg5pj   1/1     Running     0          22h
   service/apache-webtier-apache-webtier   NodePort       10.108.29.98     <none>        80:30305/TCP,4433:30443/TCP   22h
   deployment.apps/apache-webtier-apache-webtier   1/1     1            1           22h
   replicaset.apps/apache-webtier-apache-webtier-65f69dc6bc   1         1         1       22h
   ```

#### Verify domain application URL access

After the Apache web tier load balancer is running, verify that the domain applications are accessible through the load balancer port `30305/30443`. The application URLs for domain of type `soa` are:

> Note: Port `30305` is the LOADBALANCER-Non-SSLPORT and port `30443` is LOADBALANCER-SSLPORT.

##### NONSSL configuration  

   ```bash
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/weblogic/ready
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/console
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/em
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/soa-infra
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/soa/composer
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/integration/worklistapp
   ```

##### SSL configuration

   ```bash
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/weblogic/ready
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/console
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/em
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/soa-infra
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/soa/composer
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/integration/worklistapp
   ```

#### Uninstall Apache web tier

   ```bash
   $ helm delete apache-webtier -n soans
   ```
