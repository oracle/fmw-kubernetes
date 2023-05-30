---
title: "Apache webtier"
date: 2023-05-10T15:44:42-05:00
draft: false
weight: 3
pre: "<b>c. </b>"
description: "Configure the Apache webtier load balancer for Oracle WebCenter Sites domains."
---

This section provides information about how to install and configure the *Apache webtier* to load balance Oracle WebCenter Sites domain clusters. You can configure Apache webtier for non-SSL and SSL termination access of the application URL.

Follow these steps to set up the Apache webtier as a load balancer for an Oracle WebCenter Sites domain in a Kubernetes cluster:

  1. [Build the Apache webtier image](#build-the-apache-webtier-image)
  1. [Create the Apache plugin configuration file](#create-the-apache-plugin-configuration-file)
  1. [Prepare the certificate and private key](#prepare-the-certificate-and-private-key)
  1. [Install the Apache webtier Helm chart](#install-the-apache-webtier-helm-chart)
  1. [Verify domain application URL access](#verify-domain-application-url-access)
  1. [Uninstall Apache webtier](#uninstall-apache-webtier)

#### Build the Apache webtier image

Refer to the [sample](https://github.com/oracle/docker-images/tree/main/OracleWebLogic/samples/12213-webtier-apache), to build the Apache webtier Docker image.

#### Create the Apache plugin configuration file

1. The configuration file named `custom_mod_wl_apache.conf` should have all the URL routing rules for the Oracle WebCenter Sites applications deployed in the domain that needs to be accessible externally. Update this file with values based on your environment. The file content is similar to below.


   {{%expand "Click here to see the sample content of the configuration file custom_mod_wl_apache.conf for wcs domain" %}}
   ```bash

    # Copyright (c) 2018, 2021, Oracle and/or its affiliates.
	# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

	<IfModule mod_weblogic.c>
	WebLogicHost ${WEBLOGIC_HOST}
	WebLogicPort 7001
	</IfModule>

	# Directive for weblogic admin Console deployed on Weblogic Admin Server
	<Location /console>
	SetHandler weblogic-handler
	WebLogicHost wcsitesinfra-adminserver
	WebLogicPort 7001
	</Location>

	<Location /em>
	SetHandler weblogic-handler
	WebLogicHost wcsitesinfra-adminserver
	WebLogicPort 7001
	</Location>

	<Location /wls-exporter>
	SetHandler weblogic-handler
	WebLogicHost wcsitesinfra-adminserver
	WebLogicPort 7001
	</Location>

	<Location /weblogic>
	SetHandler weblogic-handler
	WebLogicHost wcsitesinfra-adminserver
	WebLogicPort 7001
	</Location>
	 
	# Directive for all application deployed on weblogic cluster with a prepath defined by LOCATION variable
	# For example, if the LOCAITON is set to '/weblogic', all applications deployed on the cluster can be accessed via 
	# http://myhost:myport/weblogic/application_end_url
	# where 'myhost' is the IP of the machine that runs the Apache webtier, and 
	#       'myport' is the port that the Apache webtier is publicly exposed to.
	# Note that LOCATION cannot be set to '/' unless this is the only Location module configured.
	<Location /sites>
	WLSRequest On
	WebLogicCluster wcsitesinfra-cluster-wcsites-cluster:8001
	PathTrim /weblogic1
	</Location>

	<Location /cas>
	WLSRequest On
	WebLogicCluster wcsitesinfra-cluster-wcsites-cluster:8001
	PathTrim /weblogic1
	</Location>

	<Location /wls-exporter>
	WLSRequest On
	WebLogicCluster wcsitesinfra-cluster-wcsites-cluster:8001
	PathTrim /weblogic1
	</Location>
   ```

   {{% /expand %}}

1. Create a PV and PVC (pv-claim-name) that can be used to store the custom_mod_wl_apache.conf. Refer to the [Sample](https://github.com/oracle/weblogic-kubernetes-operator/blob/v4.0.6/kubernetes/samples/scripts/create-weblogic-domain-pv-pvc/README.md) for creating a PV or PVC.

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

    Update the input parameters file, `charts/apache-samples/custom-sample/input.yaml`.

   {{%expand "Click here to see the snapshot of the sample input.yaml file " %}}
   ```bash
    $ cat apache-samples/custom-sample/input.yaml
    # Use this to provide your own Apache webtier configuration as needed; simply define this
    # Persistence Volume which contains your own custom_mod_wl_apache.conf file.
    persistentVolumeClaimName: <pv-claim-name>

    # The VirtualHostName of the Apache HTTP server. It is used to enable custom SSL configuration.
    virtualHostName: <WEBLOGIC_HOST>

    # The customer-supplied certificate to use for Apache webtier SSL configuration.
    # The value must be a string containing a base64 encoded certificate. Run following command to get it.
    # base64 -i ${SSL_CERT_FILE} | tr -d '\n'
    customCert: <cert_data>

    # The customer-supplied private key to use for Apache webtier SSL configuration.
    # The value must be a string containing a base64 encoded key. Run following command to get it.
    # base64 -i ${SSL_KEY_FILE} | tr -d '\n'
    customKey: <key_data>
   ```
   {{% /expand %}}

#### Install the Apache webtier Helm chart

1. Install the Apache webtier Helm chart to the domain namespace (for example `wcsites-ns`) with the specified input parameters:

   ```bash
   $ cd ${WORKDIR}/charts
   $ helm install apache-webtier --values apache-samples/custom-sample/input.yaml --namespace wcsites-ns apache-webtier --set image=oracle/apache:12.2.1.3
   ```

1. Check the status of the Apache webtier:

   ```bash
    $ kubectl get all -n wcsites-ns | grep apache
   ```

   Sample output of the status of the Apache webtier:
   ```bash
   pod/apache-webtier-apache-webtier-65f69dc6bc-zg5pj   1/1     Running     0          22h
   service/apache-webtier-apache-webtier   NodePort       10.108.29.98     <none>        80:30305/TCP,4433:30443/TCP   22h
   deployment.apps/apache-webtier-apache-webtier   1/1     1            1           22h
   replicaset.apps/apache-webtier-apache-webtier-65f69dc6bc   1         1         1       22h
   ```

#### Verify domain application URL access

After the Apache webtier load balancer is running, verify that the domain applications are accessible through the load balancer port `30305/30443`. The application URLs for domain of type `wcs` are:

> Note: Port `30305` is the LOADBALANCER-Non-SSLPORT and port `30443` is LOADBALANCER-SSLPORT.

##### NONSSL configuration  

   ```bash
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/weblogic/ready
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/console
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/em
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/sites/version.jsp
   ```

##### SSL configuration

   ```bash
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/weblogic/ready
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/console
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/em
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/sites/version.jsp
   ```

#### Uninstall Apache webtier

   ```bash
   $ helm delete apache-webtier -n wcsites-ns
   ```
