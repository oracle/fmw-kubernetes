#!/bin/bash
# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of functions used to create an Ingress Controller
# 
#
# Dependencies: 
#               
#
# Usage: invoked as needed not directly
#
# Common Environment Variables
#


# Create Ingress Certificate
#
create_ingress_cert()
{
    ST=`date +%s`
    print_msg "Creating Certificate for Domain: *.$INGRESS_DOMAIN"
    cp $TEMPLATES_DIR/ssl_cert_config.txt $WORKDIR
    update_variable "<INGRESS_DOMAIN>" $INGRESS_DOMAIN $WORKDIR/ssl_cert_config.txt
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $WORKDIR/ingress.key -out $WORKDIR/ingress.crt -config $WORKDIR/ssl_cert_config.txt -extensions v3_req > $LOGDIR/create_cert.log 2>&1
    print_status $? $LOGDIR/create_cert.log

    printf "\t\t\tCreate Kubernetes Secret from Certificate - "
 
    kubectl -n $INGRESSNS create secret tls common-tls-cert --key $WORKDIR/ingress.key --cert $WORKDIR/ingress.crt  > $LOGDIR/create_cert_secret.log 2>&1
    grep -q created $LOGDIR/create_cert_secret.log
    if [ $? = 0 ]
    then
         echo "Success"
    else
          grep -q exists $LOGDIR/create_cert_secret.log
          if [ $? = 0 ]
          then
               echo "Already Exists"
          else
               echo kubectl -n $INGRESSNS create secret tls common-tls-cert --key $WORKDIR/ingress.key --cert $WORKDIR/ingress.crt  > $LOGDIR/create_cert_secret.log 2>&1
               echo "Failed - See $LOGDIR/create_cert_secret.log."
               exit 1
          fi
    fi
    ET=`date +%s`
    print_time STEP "Creating Ingress" $ST $ET >> $LOGDIR/timings.log
}
    
# Add ingress to Helm repository
#
create_ingress_repo()
{
    ST=`date +%s`
    print_msg "Adding Ingress Repository "
   
    helm repo add stable https://kubernetes.github.io/ingress-nginx > $LOGDIR/ingress.log 2>&1
    print_status $? $LOGDIR/ingress.log 2>&1

    printf "\t\t\tUpdate Ingress Repository - "
    helm repo update  >> $LOGDIR/ingress.log 2>&1
    print_status $? $LOGDIR/ingress.log 2>&1


    ET=`date +%s`
    print_time STEP "Add Ingress Repository" $ST $ET >> $LOGDIR/timings.log
}


#
# Create Ingress Controller using override file
#
create_ingress_controller()
{
    ST=`date +%s`
    print_msg "Create Ingress Controller "

    if [ "$INGRESS_ENABLE_TCP" = "true" ]  
    then
       cp $TEMPLATES_DIR/ldap_override.yaml $WORKDIR/ingress_override.yaml
       update_variable "<OUDNS>" $OUDNS $WORKDIR/ingress_override.yaml
       update_variable "<OUD_POD_PREFIX>" $OUD_POD_PREFIX $WORKDIR/ingress_override.yaml
       update_variable "<OUD_POD_PREFIX>" $OUD_POD_PREFIX $WORKDIR/ingress_override.yaml
       update_variable "<OUD_LDAP_K8>" $OUD_LDAP_K8 $WORKDIR/ingress_override.yaml
       update_variable "<OUD_LDAPS_K8>" $OUD_LDAPS_K8 $WORKDIR/ingress_override.yaml
    else
       cp $TEMPLATES_DIR/ingress_override.yaml $WORKDIR/ingress_override.yaml
    fi

    filename=$WORKDIR/ingress_override.yaml
    update_variable "<INGRESS_NAME>" $INGRESS_NAME $filename
    update_variable "<INGRESS_REPLICAS>" $INGRESS_REPLICAS $filename
    update_variable "<INGRESS_HTTP_K8>" $INGRESS_HTTP_K8 $filename
    update_variable "<INGRESS_HTTPS_K8>" $INGRESS_HTTPS_K8 $filename
    update_variable "<USE_PROM>" $USE_PROM $filename
   

    helm install nginx-ingress -n $INGRESSNS --values $filename\
      stable/ingress-nginx > $LOGDIR/create_controller.log 2>&1
    grep -q DEPLOYED $LOGDIR/create_controller.log
    print_status $? $LOGDIR/create_controller.log

    ET=`date +%s`
    print_time STEP "Create Ingress Controller" $ST $ET >> $LOGDIR/timings.log
}

