#!/bin/bash
# Copyright (c) 2021, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example script to populate the responsefile
# 
#
# Dependencies: ./common/functions.sh
#               ./responsefile/idm.rsp
#
# Usage: start_here.sh
#
RSPFILE=responsefile/idm.rsp
PWDFILE=responsefile/.idmpwds
. $RSPFILE
. $PWDFILE

. common/functions.sh

echo "Checking Pre-requisites"
echo "-----------------------"

echo -n "Do you wish to get the images from a container registry (y/n) :"
read ANS
if ! check_yes $ANS
then
  echo -n "Have you downloaded and staged the container images (y/n) :"
  read ANS
  if check_yes $ANS
  then
     USE_REGISTRY=false
  else
     echo "Download the docker images referring to support note (2723908.1)"
     exit 1
  fi
else
  USE_REGISTRY=true
fi

replace_value USE_REGISTRY $USE_REGISTRY $RSPFILE

echo -n "Have you a running Kubernetes Cluster (y/n) :"
read ANS
if ! check_yes $ANS
then
    echo "You must first build a Kubernetes cluster"
    exit 1
fi

echo -n "What type of container runtime are you using (docker/crio) [$IMAGE_TYPE]:"
read ANS

if  [ "$ANS" = "" ]
then 
    ANS=$IMAGE_TYPE
fi

case "$ANS" in
  "docker") IMAGE_TYPE=$ANS
      ;;
  "crio") IMAGE_TYPE=$ANS
      ;;
  *) echo "Invalid Value enter docker or crio"
     exit 1
     ;;
esac

if  [ ! "$ANS" = "" ]
then
     replace_value IMAGE_TYPE $ANS $RSPFILE
fi

if [ "$USE_REGISTRY" = "false" ]
then
    echo -n "Have you set up SSH equivalence to each Kubernetes node (y/n) :"
    read ANS
    if ! check_yes $ANS
    then
        echo "It is recommended that you set up SSH equivalence for the duration of the setup"
        exit 1
    fi
fi

if [ "$USE_REGISTRY" = "true" ]
then
     echo -n "Enter Registry Location ($REGISTRY) :"
     read ANS
     if  [ ! "$ANS" = "" ]
     then 
         replace_value REGISTRY $ANS $RSPFILE
     fi

     echo -n "Enter Registry User ($REG_USER) :"
     read ANS
     if  [ ! "$ANS" = "" ]
     then 
         replace_value REG_USER $ANS $RSPFILE
     fi

      echo -n "Enter Password of Registry User :"
      read -s ANS

      if  [ ! "$ANS" = "" ]
      then
           echo
           echo -n "Confirm Password of Registry User :"
           read -s ACHECK
           if  [ ! "$ANS" = "$ACHECK" ]
           then
              echo "Passwords do not match!"
              exit
           else
               echo
               replace_password REG_PWD $ANS $PWDFILE
           fi
      else
         echo "Leaving value as previously defined"
      fi
      replace_value CREATE_REGSECRET true $RSPFILE
fi

echo 
echo -n  "Do you wish to create a GITHUB secret (y/n) : "
read ANS
if  check_yes $ANS
then
    CREATE_GITSECRET=true
else
    CREATE_GITSECRET=false
fi
replace_value CREATE_GITSECRET $CREATE_GITSECRET $RSPFILE

if [ "$CREATE_GITSECRET" = "true" ]
then
    echo -n "Enter GIT Username [$GIT_USER]:"
    read ANS

    if  [ ! "$ANS" = "" ]
    then
        replace_value GIT_USER $ANS $RSPFILE
    fi

    echo -n "Enter GIT Token :" 
    read -s ANS

    if [ ! "$ANS" = "" ]
    then
         replace_value GIT_TOKEN $ANS $RSPFILE
     else
         echo "Leaving value as previously defined"
     fi
fi
     


echo 
echo -n  "Do you wish to change the default ports (y/n) : "
read ANS
if  check_yes $ANS
then
    GET_PORT=true
else
    GET_PORT=false
fi

echo -n  "Do you wish to change the default namespaces (y/n) : "
read ANS
if  check_yes $ANS
then
    GET_NS=true
else
    GET_NS=false
fi

echo -n  "Do you wish to change the default user/group names (y/n) : "
read ANS
if  check_yes $ANS
then
    GET_USER=true
else
    GET_USER=false
fi

echo
echo -n  "Do you wish to update OHS config files (y/n) : "
read ANS
if  check_yes $ANS
then
    UPDATE_OHS=true
else
    UPDATE_OHS=false
fi

echo -n  "Do you wish to copy WebGate config files (y/n) : "
read ANS
if  check_yes $ANS
then
    COPY_WG_FILES=true
else
    COPY_WG_FILES=false
fi

echo -n "Do you wish to configure products using Ingress (y/n) : "
read ANS

if check_yes $ANS 
then
    USE_INGRESS=true
else
    USE_INGRESS=false
fi

echo -n "Do you wish to send Logs to Elastic Search (y/n) : "
read ANS

if check_yes $ANS 
then
    USE_ELK=true
else
    USE_ELK=false
fi

echo -n "Do you wish to send Monitoring Information to Prometheus (y/n) : "
read ANS

if check_yes $ANS 
then
    USE_PROM=true
else
    USE_PROM=false
fi

echo 
echo "Products to Install and Configure"
echo "---------------------------------"
echo " "
echo -n  "  Do you wish to install/config Elastic Search and Kibana (y/n) : "
read ANS

if check_yes $ANS 
then
    INSTALL_ELK=true
else
    INSTALL_ELK=false
fi

echo -n  "  Do you wish to install/config Prometheus and Grafana (y/n) : "
read ANS

if check_yes $ANS 
then
    INSTALL_PROM=true
else
    INSTALL_PROM=false
fi

echo -n  "  Do you wish to install/config an Ingress Controller (y/n) : "
read ANS

if check_yes $ANS 
then
    INSTALL_INGRESS=true
else
    INSTALL_INGRESS=false
fi

echo -n  "  Do you wish to install/config Oracle HTTP Server (y/n) : "
read ANS

if check_yes $ANS 
then
    INSTALL_OHS=true
else
    INSTALL_OHS=false
fi

echo -n  "  Do you wish to deploy Oracle WebGate (y/n) : "
read ANS

if check_yes $ANS 
then
    DEPLOY_WG=true
else
    DEPLOY_WG=false
fi

echo -n  "  Do you wish to install/config OUD (y/n) : "
read ANS

if check_yes $ANS 
then
    INSTALL_OUD=true
else
    INSTALL_OUD=false
fi

echo -n  "  Do you wish to install/config OUDSM (y/n) : "
read ANS

if check_yes $ANS 
then
    INSTALL_OUDSM=true
else
    INSTALL_OUDSM=false
fi

echo -n  "  Do you wish to install/config WebLogic Kubernetes Operator (y/n) : "
read ANS

if check_yes $ANS 
then
    INSTALL_WLSOPER=true
else
    INSTALL_WLSOPER=false
fi

echo -n  "  Do you wish to install/config Oracle Access Manager (y/n) : "
read ANS

if check_yes $ANS 
then
    INSTALL_OAM=true
else
    INSTALL_OAM=false
fi

echo -n  "  Do you wish to install/config Oracle Identity Governance (y/n) : "
read ANS

if check_yes $ANS 
then
    INSTALL_OIG=true
else
    INSTALL_OIG=false
fi

echo -n  "  Do you wish to install/config Oracle Identity Role Intelligence (y/n) : "
read ANS

if check_yes $ANS 
then
    INSTALL_OIRI=true
else
    INSTALL_OIRI=false
fi

echo -n  "  Do you wish to install/config Oracle Advanced Authentication (y/n) : "
read ANS

if check_yes $ANS 
then
    INSTALL_OAA=true
else
    INSTALL_OAA=false
fi

replace_value INSTALL_ELK $INSTALL_ELK $RSPFILE
replace_value INSTALL_PROM $INSTALL_PROM $RSPFILE
replace_value INSTALL_INGRESS $INSTALL_INGRESS $RSPFILE
replace_value INSTALL_OHS $INSTALL_OHS $RSPFILE
replace_value DEPLOY_WG $DEPLOY_WG $RSPFILE
replace_value INSTALL_OUD $INSTALL_OUD $RSPFILE
replace_value INSTALL_OUDSM $INSTALL_OUDSM $RSPFILE
replace_value INSTALL_WLSOPER $INSTALL_WLSOPER $RSPFILE
replace_value INSTALL_OAM $INSTALL_OAM $RSPFILE
replace_value INSTALL_OIG $INSTALL_OIG $RSPFILE
replace_value INSTALL_OIRI $INSTALL_OIRI $RSPFILE
replace_value INSTALL_OAA $INSTALL_OAA $RSPFILE

replace_value USE_INGRESS $USE_INGRESS $RSPFILE
replace_value USE_ELK $USE_ELK $RSPFILE
replace_value USE_PROM $USE_PROM $RSPFILE
replace_value UPDATE_OHS $UPDATE_OHS $RSPFILE
replace_value COPY_WG_FILES $COPY_WG_FILES $RSPFILE

echo " "
echo "File Locations"
echo "--------------"
echo 


if [ "$USE_REGISTRY" = "false" ]
then
    echo -n "Enter location of container images [$IMAGE_DIR]:"
    read ANS
    
        if  [ ! "$ANS" = "" ]
    then
         replace_value IMAGE_DIR $ANS $RSPFILE
    fi
fi


echo -n "Enter location of local working directory [$LOCAL_WORKDIR]:"
read ANS

if  [ ! "$ANS" = "" ]
then
     replace_value LOCAL_WORKDIR $ANS $RSPFILE
fi


echo " "
echo "NFS Locations"
echo "--------------"

echo -n "Enter Name/IP of NFS Server [$PVSERVER]:"
read ANS

if [ ! "$ANS" = "" ]
then
     replace_value PVSERVER $ANS $RSPFILE
fi

echo " "
echo "SSL Parameters"
echo "--------------"

echo -n "Enter SSL Country Code [$SSL_COUNTRY]:"
read ANS

if [ ! "$ANS" = "" ]
then
     replace_value SSL_COUNTRY $ANS $RSPFILE
fi

echo -n "Enter SSL Organisation Name [$SSL_ORG]:"
read ANS

if [ ! "$ANS" = "" ]
then
     replace_value SSL_ORG "$ANS" $RSPFILE
fi


echo -n "Enter SSL City Name [$SSL_CITY]:"
read ANS

if [ ! "$ANS" = "" ]
then
     replace_value SSL_CITY "$ANS" $RSPFILE
fi

echo -n "Enter SSL State Name [$SSL_STATE]:"
read ANS

if [ ! "$ANS" = "" ]
then
     replace_value SSL_STATE "$ANS" $RSPFILE
fi


if [ "$INSTALL_ELK" = "true" ] || [ "$USE_ELK" = "true" ]
then

      echo " "
      echo "Elastic Search/Kibana"
      echo "---------------------"

      if [ "$INSTALL_ELK" = "true" ]
      then
        if [ "$GET_NS" = "true" ] 
        then
          echo -n "Enter Kubernetes Namespace for Elastic Search [$ELKNS] :"
          read ANS

          if [ ! "$ANS" = "" ]
          then
               replace_value ELKNS $ANS $RSPFILE
          fi
        fi

        echo -n "Version to Install [$ELK_VER] :"
        read ANS
        if [ ! "$ANS" = "" ]
        then
           replace_value ELK_VER $ANS $RSPFILE
        fi

        echo -n "Kubernetes Storage Class to Use [$ELK_STORAGE] :"
        read ANS
        if [ ! "$ANS" = "" ]
        then
          replace_value ELK_STORAGE $ANS $RSPFILE
        fi

        echo -n "Enter ELK Persistent Volume NFS Mount Point [$ELK_SHARE] :"
        read ANS

        if [ ! "$ANS" = "" ]
        then
           replace_value ELK_SHARE $ANS $RSPFILE
        fi

      else
        echo -n "Elastic Search Host [$ELK_HOST] : "
        read ANS

        if [ ! "$ANS" = "" ]
        then
          replace_value ELK_HOST $ELK_HOST $RSPFILE
        fi
      fi

      if [ "$GET_PORT" = "true" ]
      then
         echo -n "Enter Elastic Search Port [$ELK_K8] :"
         read ANS

         if [ ! "$ANS" = "" ]
         then
           if check_number $ANS
           then
             replace_value ELK_K8 $ANS $RSPFILE
           else
              echo "Port must be numeric - leaving value unchanged."
           fi
         fi

         echo -n "Enter Kibana Port [$ELK_KIBANA_K8] :"
         read ANS

         if [ ! "$ANS" = "" ]
         then
           if check_number $ANS
           then
              replace_value ELK_KIBANA_K8 $ANS $RSPFILE
           else
              echo "Port must be numeric - leaving value unchanged."
           fi
         fi
      fi

      echo -n "Enter logstash_writer Password :"
      read -s ANS

      if [ ! "$ANS" = "" ]
      then
           echo
           echo -n "Confirm Password of logstash_writer :"
           read -s ACHECK
           if [ ! "$ANS" = "$ACHECK" ]
           then
              echo "Passwords do not match!"
              exit
           else
               echo
               replace_password ELK_USER_PWD $ANS $PWDFILE
           fi
      else
           echo "Leaving value as previously defined"
      fi
fi

if [ "$INSTALL_PROM" = "true" ] || [ "$USE_PROM" = "true" ]
then

      echo " "
      echo "Prometheus and Grafana"
      echo "----------------------"

      if [ "$INSTALL_PROM" = "true" ]
      then
        if [ "$GET_NS" = "true" ] 
        then
          echo -n "Enter Kubernetes Namespace for Prometheus [$PROMNS]:"
          read ANS

          if [ ! "$ANS" = "" ]
          then
               replace_value PROMNS $ANS $RSPFILE
          fi

        echo -n "Enter Grafana Admin Password :"
        read -s ANS

        if [ ! "$ANS" = "" ]
        then
             echo
             echo -n "Confirm Password of Grafana :"
             read -s ACHECK
             if [ ! "$ANS" = "$ACHECK" ]
             then
                echo "Passwords do not match!"
                exit
             else
                 echo
                 replace_password PROM_ADMIN_PWD $ANS $PWDFILE
             fi
          else
             echo "Leaving value as previously defined"
          fi
        fi

        if [ "$GET_PORT" = "true" ]
        then
          echo -n "Enter Prometheus Port [$PROM_K8]:"
          read ANS
  
          if [ ! "$ANS" = "" ]
          then
            if check_number $ANS
            then
              replace_value PROM_K8 $ANS $RSPFILE
            else
               echo "Port must be numeric - leaving value unchanged."
            fi
          fi

          echo -n "Enter Alert Manager Port [$PROM_ALERT_K8]:"
          read ANS
  
          if [ ! "$ANS" = "" ]
          then
            if check_number $ANS
            then
              replace_value PROM_ALERT_K8 $ANS $RSPFILE
            else
              echo "Port must be numeric - leaving value unchanged."
           fi
          fi

          echo -n "Enter Grafana Port [$PROM_GRAF_K8]:"
          read ANS
  
          if [ ! "$ANS" = "" ]
          then
            if check_number $ANS
            then
               replace_value PROM_GRAF_K8 $ANS $RSPFILE
            else
               echo "Port must be numeric - leaving value unchanged."
            fi
          fi
        fi
      fi
fi

if [ "$INSTALL_INGRESS" = "true" ]
then

      echo " "
      echo "Ingress - NGINX"
      echo "---------------"

      if [ "$GET_NS" = "true" ]
      then
          echo -n "Enter Kubernetes Namespace for Ingress [$INGRESSNS]:"
          read ANS

          if [ ! "$ANS" = "" ]
          then
               replace_value INGRESSNS $ANS $RSPFILE
          fi
      fi

      echo -n "Do you wish to Enable SSL Support (y/n) : "
      read ANS

      if check_yes $ANS 
      then
          INGRESS_SSL=true
      else
          INGRESS_SSL=false
      fi
      replace_value INGRESS_SSL $INGRESS_SSL $RSPFILE

      echo -n "Do you wish to Enable TCP Support for LDAP Connections (y/n) : "
      read ANS

      if check_yes $ANS 
      then
          INGRESS_ENABLE_TCP=true
      else
          INGRESS_ENABLE_TCP=false
      fi
      replace_value INGRESS_ENABLE_TCP $INGRESS_ENABLE_TCP $RSPFILE

      echo -n "Enter Ingress Name [$INGRESS_NAME]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value INGRESS_NAME $ANS $RSPFILE
      fi

      echo -n "Enter Ingress Domain Name [$INGRESS_DOMAIN]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value INGRESS_DOMAIN $ANS $RSPFILE
      fi

      echo -n "Enter Number of Ingress Replicas required  [$INGRESS_REPLICAS]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
        if check_number $ANS
        then
           replace_value INGRESS_REPLICAS $ANS $RSPFILE
        else
           echo "Port must be numeric - leaving value unchanged."
        fi
      fi

      if [ "$GET_PORT" = "true" ]
      then
         echo -n "Enter Ingress HTTP Port [$INGRESS_HTTP_K8]:"
         read ANS

         if [ ! "$ANS" = "" ]
         then
           if check_number $ANS
           then
              replace_value INGRESS_HTTP_K8 $ANS $RSPFILE
           else
              echo "Port must be numeric - leaving value unchanged."
           fi
         fi

         if [ "$INGRESS_SSL" = "true" ]
         then
           echo -n "Enter Ingress HTTPS Port [$INGRESS_HTTPS_K8]:"
           read ANS

           if [ ! "$ANS" = "" ]
           then
             if check_number $ANS
             then
                replace_value INGRESS_HTTPS_K8 $ANS $RSPFILE
             else
                echo "Port must be numeric - leaving value unchanged."
             fi
           fi
         fi
      fi
fi

if [ "$INSTALL_OUD" = "true" ]
then
      echo " "
      echo "Oracle Unified Directory"
      echo "------------------------"
      
      echo -n "Enter OUD Image Name [$OUD_IMAGE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OUD_IMAGE $ANS $RSPFILE
      fi

      echo -n "Enter OUD Image Version [$OUD_VER]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OUD_VER $ANS $RSPFILE

      fi

      echo -n "Enter Docker Hub Username [$DH_USER]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value DH_USER $ANS $RSPFILE

      fi

      echo -n "Enter Password of Docker Hub :" 
      read -s ANS

      if [ ! "$ANS" = "" ]
      then
           echo
           echo -n "Confirm Password of Docker Hub :"
           read -s ACHECK
           if [ ! "$ANS" = "$ACHECK" ]
           then
              echo "Passwords do not match!"
              exit
           else
               echo
               replace_password DH_PWD $ANS $PWDFILE
           fi
      else
         echo "Leaving value as previously defined"
      fi

      echo -n "Enter Kubernetes OUD POD Prefix [$OUD_POD_PREFIX]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OUD_POD_PREFIX $ANS $RSPFILE
      fi
      echo -n "Enter OUD Persistent Volume NFS Mount Point [$OUD_SHARE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OUD_SHARE $ANS $RSPFILE
      fi

      echo -n "Enter OUD PV local Mount Point [$OUD_LOCAL_SHARE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OUD_LOCAL_SHARE $ANS $RSPFILE
      fi

      echo -n "Enter OUD Config PV Local Mount Point [$OUD_CONFIG_SHARE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OUD_CONFIG_SHARE $ANS $RSPFILE
      fi

      echo -n "Enter OUD Config Share Local Mount Point [$OUD_LOCAL_CONFIG_SHARE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OUD_LOCAL_CONFIG_SHARE $ANS $RSPFILE
      fi

      if [ "$GET_NS" = "true" ]
      then
          echo -n "Enter Kubernetes Namespace for OUD [$OUDNS]:"
          read ANS

          if [ ! "$ANS" = "" ]
          then
               replace_value OUDNS $ANS $RSPFILE
          fi
      fi

      if [ "$GET_USER" = "true" ]
      then
           echo -n "Enter Name of OUD Admin User to be used [$LDAP_ADMIN_USER]:"
           read ANS

           if [ ! "$ANS" = "" ]
           then
                replace_value LDAP_ADMIN_USER $ANS $RSPFILE
           fi
      fi

      echo -n "Enter Password of OUD Admin User ($LDAP_ADMIN_USER) :" 
      read -s ANS

      if [ ! "$ANS" = "" ]
      then
           echo
           echo -n "Confirm Password of OUD Admin User :"
           read -s ACHECK
           if [ ! "$ANS" = "$ACHECK" ]
           then
              echo "Passwords do not match!"
              exit
           else
               echo
               replace_password LDAP_ADMIN_PWD $ANS $PWDFILE
           fi
      else
         echo "Leaving value as previously defined"
      fi


      echo -n "Enter Number of OUD Replicas required (In addition to Primary) [$OUD_REPLICAS]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
        if check_number $ANS
        then
           replace_value OUD_REPLICAS $ANS $RSPFILE
        else
           echo "Port must be numeric - leaving value unchanged."
        fi
      fi
      
      echo -n "Create OUD Node Port Service (true/false) [$OUD_CREATE_NODEPORT]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OUD_CREATE_NODEPORT $ANS $RSPFILE
      fi

      if [ "$OUD_CREATE_NODEPORT" = "true" ] && [ "$GET_PORT" = "true" ]
      then
          echo -n "Enter Kubernetes LDAP Service port  [$OUD_LDAP_K8]:"
          read ANS

          if [ ! "$ANS" = "" ]
          then
               replace_value OUD_LDAP_K8 $ANS $RSPFILE
          fi

          echo -n "Enter Kubernetes LDAPS Service port  [$OUD_LDAPS_K8]:"
          read ANS

          if [ ! "$ANS" = "" ]
          then
               replace_value OUD_LDAPS_K8 $ANS $RSPFILE
          fi
      fi

      OLD_SEARCHBASE=$LDAP_SEARCHBASE
      echo -n "OUD Base DN [$LDAP_SEARCHBASE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           global_replace_value $OLD_SEARCHBASE $ANS $RSPFILE
           LDAP_SEARCHBASE=$ANS
           OUD_REGION=`echo $ANS | cut -f1 -d, | cut -f2 -d=`
           replace_value OUD_REGION $OUD_REGION $RSPFILE
           OAM_COOKIE_DOMAIN=`echo $LDAP_SEARCHBASE | sed 's/dc=/./g;s/,//g'`
           replace_value OAM_COOKIE_DOMAIN $OAM_COOKIE_DOMAIN $RSPFILE
      fi

      echo -n "Container to store systems IDS  [$LDAP_SYSTEMIDS]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value LDAP_SYSTEMIDS $ANS $RSPFILE
      fi

      if [ "$GET_USER" = "true" ]
      then
           echo -n "OAM Administrator User [$LDAP_OAMADMIN_USER]:"
           read ANS

           if [ ! "$ANS" = "" ]
           then
                replace_value LDAP_OAMADMIN_USER $ANS $RSPFILE
           fi

           echo -n "OAM LDAP Connection User [$LDAP_OAMLDAP_USER]:"
           read ANS

           if [ ! "$ANS" = "" ]
           then
                replace_value LDAP_OAMLDAP_USER $ANS $RSPFILE
           fi

           echo -n "OIG LDAP Connection User [$LDAP_OIGLDAP_USER]:"
           read ANS

           if [ ! "$ANS" = "" ]
           then
                replace_value LDAP_OIGLDAP_USER $ANS $RSPFILE
           fi

           echo -n "LDAP WebLogic Administration User [$LDAP_WLSADMIN_USER]:"
           read ANS

           if [ ! "$ANS" = "" ]
           then
                replace_value LDAP_WLSADMIN_USER $ANS $RSPFILE
           fi

           echo -n "LDAP OIG Administration User [$LDAP_XELSYSADM_USER]:"
           read ANS

           if [ ! "$ANS" = "" ]
           then
                replace_value LDAP_XELSYSADM_USER $ANS $RSPFILE
           fi

    fi
    echo -n "Enter Password of OUD Users :"
    read -s ANS

    if [ ! "$ANS" = "" ]
    then
      echo
      echo -n "Confirm Password of OUD Users :"
      read -s ACHECK
      if [ ! "$ANS" = "$ACHECK" ]
      then
         echo "Passwords do not match!"
         exit
      else
         echo
         if  check_password "UN" $ANS
         then
             replace_password LDAP_USER_PWD $ANS $PWDFILE
         else
             echo "Password not set"
         fi
      fi
    else
      echo "Leaving value as previously defined"
    fi

    echo -n "LDAP User Expiry Date (YYYY-MM-DD) [$OUD_PWD_EXPIRY]:"
    read ANS

    if [ ! "$ANS" = "" ]
    then
      replace_value OUD_PWD_EXPIRY $ANS $RSPFILE
    fi

    if [ "$GET_USER" = "true" ]
    then
      echo -n "LDAP OAM Administration Group [$LDAP_OAMADMIN_GRP]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value LDAP_OAMADMIN_GRP $ANS $RSPFILE
      fi

      echo -n "LDAP OIG Administration Group [$LDAP_OIGADMIN_GRP]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value LDAP_OIGADMIN_GRP $ANS $RSPFILE
      fi

      echo -n "LDAP WebLogic Administration Group [$LDAP_WLSADMIN_GRP]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value LDAP_WLSADMIN_GRP $ANS $RSPFILE
      fi
   fi
fi


if [ "$INSTALL_OUDSM" = "true" ]
then
      echo
      echo "OUDSM Parameters"
      echo "----------------"
      echo
      echo -n "Enter OUDSM Image Name [$OUDSM_IMAGE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OUDSM_IMAGE $ANS $RSPFILE
      fi

      echo -n "Enter OUDSM Image Version [$OUDSM_VER]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OUDSM_VER $ANS $RSPFILE

      fi

      echo -n "Enter OUDSM Persistent Volume NFS Mount Point [$OUDSM_SHARE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OUDSM_SHARE $ANS $RSPFILE
      fi

      echo -n "Enter OUDSM PV local Mount Point [$OUDSM_LOCAL_SHARE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OUDSM_LOCAL_SHARE $ANS $RSPFILE
      fi

      if [ "$GET_USER" = "true" ]
      then
         echo -n "Enter OUDSM Admin User [$OUDSM_USER]:"
         read ANS

         if [ ! "$ANS" = "" ]
         then
              replace_value OUDSM_USER $ANS $RSPFILE
         fi
      fi

      echo -n "Enter Password of OUDSM Admin User :"
      read -s ANS

      if [ ! "$ANS" = "" ]
      then
           echo
           echo -n "Confirm Password of OUDSM Admin User :"
           read -s ACHECK
           if [ ! "$ANS" = "$ACHECK" ]
           then
              echo "Passwords do not match!"
              exit
           else
               echo
               if  check_password "UN" $ANS
               then
                 replace_password OUDSM_PWD $ANS $PWDFILE
               else
                   echo "Password not set"
               fi
           fi
      else
         echo "Leaving value as previously defined"
      fi
fi

if [ "$INSTALL_OAM" = "true" ] || [ "$INSTALL_OIG" = "true" ]
then
      echo
      echo "WebLogic Kubernetes Operator Parameters"
      echo "---------------------------------------"
      echo

      if [ "$GET_NS" = "true" ]
      then
         echo -n "Enter Operator Namespace [$OPERNS]:"
         read ANS

         if [ ! "$ANS" = "" ]
         then
              replace_value OPERNS $ANS $RSPFILE
         fi
      fi

      if [ "$GET_USER" = "true" ]
      then
          echo -n "Enter Operator Service Account [$OPER_ACT]:"
          read ANS

          if [ ! "$ANS" = "" ]
          then
               replace_value OPER_ACT $ANS $RSPFILE
          fi

      fi
fi

if [ "$INSTALL_OAM" = "true" ] 
then
      echo
      echo "Oracle Access Manager Parameters"
      echo "--------------------------------"
      echo

      echo -n "Enter OAM Image Name [$OAM_IMAGE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAM_IMAGE $ANS $RSPFILE
      fi

      echo -n "Enter OAM Image Version [$OAM_VER]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAM_VER $ANS $RSPFILE

      fi

      if [ "$GET_NS" = "true" ]
      then
         echo -n "Enter OAM Namespace [$OAMNS]:"
         read ANS

         if [ ! "$ANS" = "" ]
         then
              replace_value OAMNS $ANS $RSPFILE
         fi
      fi

      echo -n "Enter OAM Persistent Volume NFS Mount Point [$OAM_SHARE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAM_SHARE $ANS $RSPFILE
      fi

      echo -n "Enter OAM PV local Mount Point [$OAM_LOCAL_SHARE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAM_LOCAL_SHARE $ANS $RSPFILE
      fi

      echo -n "Enter Number of OAM Servers to configure (More than you will ever need) [$OAM_SERVER_COUNT]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
        if check_number $ANS
        then
           replace_value OAM_SERVER_COUNT $ANS $RSPFILE
        else
           echo "Port must be numeric - leaving value unchanged."
        fi
      fi

      echo -n "Enter Number of OAM Servers to start (Number you normally use) [$OAM_SERVER_INITIAL]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
        if check_number $ANS
        then
           replace_value OAM_SERVER_INITIAL $ANS $RSPFILE
        else
           echo "Port must be numeric - leaving value unchanged."
        fi
      fi

      echo ""

      if [ "$GET_PORT" = "true" ]
      then
         echo -n "Enter Admin Server Port for OAM [$OAM_ADMIN_PORT]:"
         read ANS

         if [ ! "$ANS" = "" ]
         then
           if check_number $ANS
           then
              replace_value OAM_ADMIN_PORT $ANS $RSPFILE
           else
              echo "Port must be numeric - leaving value unchanged."
           fi
         fi
       
         echo -n "Enter Kubernetes Service Port for Admin Server [$OAM_ADMIN_K8]:"
         read ANS

         if [ ! "$ANS" = "" ]
         then
           if check_number $ANS
           then
              replace_value OAM_ADMIN_K8 $ANS $RSPFILE
           else
              echo "Port must be numeric - leaving value unchanged."
           fi
         fi
       
         echo -n "Enter Kubernetes Service Port for OAM Server [$OAM_OAM_K8]:"
         read ANS

         if [ ! "$ANS" = "" ]
         then
           if check_number $ANS
           then
              replace_value OAM_OAM_K8 $ANS $RSPFILE
           else
              echo "Port must be numeric - leaving value unchanged."
           fi
         fi

         echo -n "Enter Kubernetes Service Port for OAM Policy Server [$OAM_POLICY_K8]:"
         read ANS

         if [ ! "$ANS" = "" ]
         then
           if check_number $ANS
           then
              replace_value OAM_POLICY_K8 $ANS $RSPFILE
           else
              echo "Port must be numeric - leaving value unchanged."
           fi
         fi

      fi
      echo -n "Enter Database Scan Address (Use Hostname for non-RAC)  [$OAM_DB_SCAN]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
        if check_number $ANS
        then
           replace_value OAM_DB_SCAN $ANS $RSPFILE
        else
           echo "Port must be numeric - leaving value unchanged."
        fi
      fi

      echo -n "Enter Database Listener Port [$OAM_DB_LISTENER]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
        if check_number $ANS
        then
           replace_value OAM_DB_LISTENER $ANS $RSPFILE
        else
           echo "Port must be numeric - leaving value unchanged."
        fi
      fi

      echo -n "Enter OAM Database Service Name [$OAM_DB_SERVICE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAM_DB_SERVICE $ANS $RSPFILE
      fi

      echo -n "Enter SYS Password :"
      read -s ANS

      if [ ! "$ANS" = "" ]
      then
           echo
           echo -n "Confirm Password of SYS Users :"
           read -s ACHECK
           if [ ! "$ANS" = "$ACHECK" ]
           then
              echo "Passwords do not match!"
              exit
           else
               echo
               replace_password OAM_DB_SYS_PWD $ANS $PWDFILE
           fi
      else
         echo "Leaving value as previously defined"
      fi

      echo -n "Enter RCU Prefix [$OAM_RCU_PREFIX]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAM_RCU_PREFIX $ANS $RSPFILE
      fi

      echo -n "Enter Password for OAM Schemas: "
      read -s ANS

      if [ ! "$ANS" = "" ]
      then
           echo
           echo -n "Confirm Password of OAM Schemas :"
           read -s ACHECK
           if [ ! "$ANS" = "$ACHECK" ]
           then
              echo "Passwords do not match!"
              exit
           else
               echo
               if  check_password "UN" $ANS
               then
                 replace_password OAM_SCHEMA_PWD $ANS $PWDFILE
               else
                   echo "Password not set"
               fi
           fi
      else
         echo "Leaving value as previously defined"
      fi

      echo -n "Enter WebLogic Domain Name [$OAM_DOMAIN_NAME]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAM_DOMAIN_NAME $ANS $RSPFILE
      fi

      echo -n "Enter OAM Login Loadbalancer Host [$OAM_LOGIN_LBR_HOST]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAM_LOGIN_LBR_HOST $ANS $RSPFILE
      fi

      echo -n "Enter OAM Login Loadbalancer Port [$OAM_LOGIN_LBR_PORT]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
        if check_number $ANS
        then
           replace_value OAM_LOGIN_LBR_PORT $ANS $RSPFILE
        else
           echo "Port must be numeric - leaving value unchanged."
        fi
      fi

      echo -n "Enter OAM Login Loadbalancer Protocol [$OAM_LOGIN_LBR_PROTOCOL]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAM_LOGIN_LBR_PROTOCOL $ANS $RSPFILE
      fi

      echo -n "Enter OAM Admin Loadbalancer Host [$OAM_ADMIN_LBR_HOST]:"
      read ANS
      if [ ! "$ANS" = "" ]
      then
           replace_value OAM_ADMIN_LBR_HOST $ANS $RSPFILE
      fi

      echo -n "Enter OAM Admin Loadbalancer Port [$OAM_ADMIN_LBR_PORT]:"
      read ANS
      if [ ! "$ANS" = "" ]
      then
        if check_number $ANS
        then
           replace_value OAM_ADMIN_LBR_PORT $ANS $RSPFILE
        else
           echo "Port must be numeric - leaving value unchanged."
        fi
      fi


      if [ "$GET_USER" = "true" ]
      then
         echo -n "Enter WebLogic Domain Administrator [$OAM_WEBLOGIC_USER]:"
         read ANS

         if [ ! "$ANS" = "" ]
         then
              replace_value OAM_WEBLOGIC_USER $ANS $RSPFILE
         fi
      fi 

      echo -n "Enter Password for $OAM_WEBLOGIC_USER account: "
      read -s ANS

      if [ ! "$ANS" = "" ]
      then
           echo
           echo -n "Confirm Password :"
           read -s ACHECK
           if [ ! "$ANS" = "$ACHECK" ]
           then
              echo "Passwords do not match!"
              exit
           else
               echo
               if  check_password "UN" $ANS
               then
                 replace_password OAM_WEBLOGIC_PWD $ANS $PWDFILE
               else
                   echo "Password not set"
               fi
           fi
      else
         echo "Leaving value as previously defined"
      fi

      echo OAM_COOKIE_DOMAIN=`echo $LDAP_SEARCHBASE | sed 's/dc=/./g;s/,//g'`
      replace_value OAM_COOKIE_DOMAIN $OAM_COOKIE_DOMAIN $RSPFILE

fi

if [ "$INSTALL_OIG" = "true" ] 
then
      echo
      echo "Oracle Identity Governance Parameters"
      echo "-------------------------------------"
      echo

      echo -n "Enter OIG Image Name [$OIG_IMAGE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIG_IMAGE $ANS $RSPFILE
      fi

      echo -n "Enter OIG Image Version [$OIG_VER]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIG_VER $ANS $RSPFILE

      fi

      if [ "$GET_NS" = "true" ]
      then
         echo -n "Enter OIG Namespace [$OIGNS] :"
         read ANS

         if [ ! "$ANS" = "" ]
         then
              replace_value OIGNS $ANS $RSPFILE
         fi

      fi
      echo -n "Enter OIG Persistent Volume NFS Mount Point [$OIG_SHARE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIG_SHARE $ANS $RSPFILE
      fi

      echo -n "Enter OIG PV local Mount Point [$OIG_LOCAL_SHARE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIG_LOCAL_SHARE $ANS $RSPFILE
      fi

      echo -n "Enter Number of OIG Servers to configure (More than you will ever need) [$OIG_SERVER_COUNT] :"
      read ANS

      if [ ! "$ANS" = "" ]
      then
        if check_number $ANS
        then
           replace_value OIG_SERVER_COUNT $ANS $RSPFILE
        else
           echo "Port must be numeric - leaving value unchanged."
        fi
      fi

      echo -n "Enter Number of OIG Servers to start (Number you normally use) [$OIG_SERVER_INITIAL]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
        if check_number $ANS
        then
           replace_value OIG_SERVER_INITIAL $ANS $RSPFILE
        else
           echo "Port must be numeric - leaving value unchanged."
        fi
      fi

      echo ""

       
      echo -n "Enter Database Scan Address (Use Hostname for non-RAC)  [$OIG_DB_SCAN]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIG_DB_SCAN $ANS $RSPFILE
      fi

      echo -n "Enter Database Listener Port [$OIG_DB_LISTENER]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
        if check_number $ANS
        then
           replace_value OIG_DB_LISTENER $ANS $RSPFILE
        else
           echo "Port must be numeric - leaving value unchanged."
        fi
      fi

      echo -n "Enter OIG Database Service Name [$OIG_DB_SERVICE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIG_DB_SERVICE $ANS $RSPFILE
      fi

      echo -n "Enter SYS Password :"
      read -s ANS

      if [ ! "$ANS" = "" ]
      then
           echo
           echo -n "Confirm Password of SYS Users :"
           read -s ACHECK
           if [ ! "$ANS" = "$ACHECK" ]
           then
              echo "Passwords do not match!"
              exit
           else
               echo
               if  check_password "UN" $ANS
               then
                 replace_password OIG_DB_SYS_PWD $ANS $PWDFILE
               else
                 echo "Password not set"
               fi
           fi
      else
         echo "Leaving value as previously defined"
      fi

      echo -n "Enter RCU Prefix [$OIG_RCU_PREFIX]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIG_RCU_PREFIX $ANS $RSPFILE
      fi

      echo -n "Enter Password for OIG Schemas "
      read -s ANS

      if [ ! "$ANS" = "" ]
      then
           echo
           echo -n "Confirm Password of OIG Schemas :"
           read -s ACHECK
           if [ ! "$ANS" = "$ACHECK" ]
           then
              echo "Passwords do not match!"
              exit
           else
               echo
               if  check_password "UNS" $ANS
               then
                 replace_password OIG_SCHEMA_PWD $ANS $PWDFILE
               else
                 echo "Password not set"
               fi
           fi
      else
         echo "Leaving value as previously defined"
      fi

      echo -n "Enter WebLogic Domain Name [$OIG_DOMAIN_NAME]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIG_DOMAIN_NAME $ANS $RSPFILE
      fi

      echo -n "Enter OIG Loadbalancer Host [$OIG_LBR_HOST]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIG_LBR_HOST $ANS $RSPFILE
      fi

      echo -n "Enter OIG Loadbalancer Port [$OIG_LBR_PORT]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
        if check_number $ANS
        then
           replace_value OIG_LBR_PORT $ANS $RSPFILE
        else
           echo "Port must be numeric - leaving value unchanged."
        fi
      fi

      echo -n "Enter OIG Loadbalancer Protocol [$OIG_LBR_PROTOCOL]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIG_LBR_PROTOCOL $ANS $RSPFILE
      fi

      echo -n "Enter OIG Admin Loadbalancer Host [$OIG_ADMIN_LBR_HOST]:"
      read ANS
      if [ ! "$ANS" = "" ]
      then
           replace_value OIG_ADMIN_LBR_HOST $ANS $RSPFILE
      fi

      echo -n "Enter OIG Admin Loadbalancer Port [$OIG_ADMIN_LBR_PORT]:"
      read ANS
      if  [ ! "$ANS" = "" ]
      then
        if check_number $ANS
        then
           replace_value OIG_ADMIN_LBR_PORT $ANS $RSPFILE
        else
           echo "Port must be numeric - leaving value unchanged."
        fi
      fi

      if [ "$GET_PORT" = "true" ]
      then
         echo -n "Enter Admin Server Port for OIG [$OIG_ADMIN_PORT]:"
         read ANS

         if [ ! "$ANS" = "" ]
         then
           if check_number $ANS
           then
              replace_value OIG_ADMIN_PORT $ANS $RSPFILE
           else
              echo "Port must be numeric - leaving value unchanged."
           fi
         fi
      
         echo -n "Enter Kubernetes Service Port for Admin Server [$OIG_ADMIN_K8]:"
         read ANS
         if [ ! "$ANS" = "" ]
         then
           if check_number $ANS
           then
              replace_value OIG_ADMIN_K8 $ANS $RSPFILE
           else
              echo "Port must be numeric - leaving value unchanged."
           fi
         fi

         echo -n "Enter Kubernetes Service Port for OIM Servers [$OIG_OIM_PORT_K8]:"
         read ANS

         if [ ! "$ANS" = "" ]
         then
           if check_number $ANS
           then
              replace_value OIG_OIM_PORT_K8 $ANS $RSPFILE
           else
              echo "Port must be numeric - leaving value unchanged."
           fi
         fi

         echo -n "Enter Kubernetes Service Port for SOA Servers [$OIG_SOA_PORT_K8]:"
         read ANS
         if  [ ! "$ANS" = "" ]
         then
           if check_number $ANS
           then
              replace_value OIG_SOA_PORT_K8 $ANS $RSPFILE
           else
              echo "Port must be numeric - leaving value unchanged."
           fi
         fi
      fi
       
      echo -n "Enter OIG Internal Loadbalancer Host [$OIG_LBR_INT_HOST]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIG_LBR_INT_HOST $ANS $RSPFILE
      fi

      echo -n "Enter OIG Internal Loadbalancer Port [$OIG_LBR_INT_PORT]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
        if check_number $ANS
        then
           replace_value OIG_LBR_PORT $ANS $RSPFILE
        else
           echo "Port must be numeric - leaving value unchanged."
        fi
      fi

      echo -n "Enter OIG Internal Loadbalancer Protocol [$OIG_LBR_INT_PROTOCOL]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIG_LBR_INT_PROTOCOL $ANS $RSPFILE
      fi


      if [ "$GET_USER" = "true" ]
      then
         echo -n "Enter WebLogic Domain Administrator [$OIG_WEBLOGIC_USER]:"
         read ANS

         if [ ! "$ANS" = "" ]
         then
              replace_value OIG_WEBLOGIC_USER $ANS $RSPFILE
         fi
      fi

      echo -n "Enter Password for $OIG_WEBLOGIC_USER account: "
      read -s ANS

      if [ ! "$ANS" = "" ]
      then
           echo
           echo -n "Confirm Password :"
           read -s ACHECK
           if [ ! "$ANS" = "$ACHECK" ]
           then
              echo "Passwords do not match!"
              exit
           else
               echo
               if  check_password "UN" $ANS
               then
                 replace_password OIG_WEBLOGIC_PWD $ANS $PWDFILE
               else
                 echo "Password not set"
               fi
           fi
      else
         echo "Leaving value as previously defined"
      fi

      echo -n "Integrate with BI Publisher (true/false) [$OIG_BI_INTEG]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIG_BI_INTEG $ANS $RSPFILE
      fi
      
      OIG_BI_INTEG=$ANS

      if [ "$OIG_BI_INTEG" = "true" ]
      then
         echo -n "Enter BI Host can be a loadbalancer [$OIG_BI_HOST]:"
         read ANS

         if [ ! "$ANS" = "" ]
         then
              replace_value OIG_BI_HOST $ANS $RSPFILE
         fi

         echo -n "Enter BI Port can be a loadbalancer [$OIG_BI_PORT]:"
         read ANS

         if [ ! "$ANS" = "" ]
         then
           if check_number $ANS
           then
              replace_value OIG_BI_PORT $ANS $RSPFILE
           else
              echo "Port must be numeric - leaving value unchanged."
           fi
         fi

         echo -n "Enter BI Prototol can be a loadbalancer [$OIG_BI_PROTOCOL]:"
         read ANS

         if [ ! "$ANS" = "" ]
         then
              replace_value OIG_BI_PROTOCOL $ANS $RSPFILE
         fi

         echo -n "Enter BI Report User [$OIG_BI_USER]:"
         read ANS

         if [ ! "$ANS" = "" ]
         then
              replace_value OIG_BI_USER $ANS $RSPFILE
         fi

         echo -n "Enter Password for $OIG_BI_USER account "
         read -s ANS

         if [ ! "$ANS" = "" ]
         then
              echo
              echo -n "Confirm Password :"
              read -s ACHECK
              if [ ! "$ANS" = "$ACHECK" ]
              then
                 echo "Passwords do not match!"
                 exit
              else
                  echo
                  replace_password OIG_BI_USER_PWD $ANS $PWDFILE
              fi
         else
             echo "Leaving value as previously defined"
         fi
     fi

fi

if [ "$INSTALL_OIRI" = "true" ] 
then
      echo
      echo "Oracle Identity Role Intelligence Parameters"
      echo "--------------------------------------------"
      echo

      echo -n "Enter OIRI Image Name [$OIRI_IMAGE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIRI_IMAGE $ANS $RSPFILE
      fi

      echo -n "Enter OIRI Image Version [$OIRI_VER]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIRI_VER $ANS $RSPFILE

      fi
      echo -n "Enter OIRI UI Image Name [$OIRI_UI_IMAGE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIRI_UI_IMAGE $ANS $RSPFILE
      fi

      echo -n "Enter OIRI UI Image Version [$OIRIUI_VER]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIRIUI_VER $ANS $RSPFILE

      fi

      echo -n "Enter OIRI DING Image Name [$OIRI_DING_IMAGE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIRI_DING_IMAGE $ANS $RSPFILE
      fi

      echo -n "Enter OIRI DING Image Version [$OIRIDING_VER]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIRIDING_VER $ANS $RSPFILE
      fi

      echo -n "Enter OIRI CLI Image Name [$OIRI_CLI_IMAGE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIRI_CLI_IMAGE $ANS $RSPFILE
      fi

      echo -n "Enter OIRI CLI Image Version [$OIRICLI_VER]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIRICLI_VER $ANS $RSPFILE

      fi

      if [ "$GET_NS" = "true" ]
      then
         echo -n "Enter OIRI Namespace [$OIRINS]:"
         read ANS

         if [ ! "$ANS" = "" ]
         then
              replace_value OIRINS $ANS $RSPFILE
         fi

         echo -n "Enter OIRI DING Namespace [$DINGNS]:"
         read ANS

         if [ ! "$ANS" = "" ]
         then
              replace_value DINGNS $ANS $RSPFILE
         fi
      fi

      echo -n "Enter OIRI Persistent Volume NFS Mount Point [$OIRI_SHARE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIRI_SHARE $ANS $RSPFILE
      fi

      echo -n "Enter OIRI PV local Mount Point [$OIRI_LOCAL_SHARE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIRI_LOCAL_SHARE $ANS $RSPFILE
      fi

      echo -n "Enter OIRI DING Persistent Volume NFS Mount Point [$OIRI_DING_SHARE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIRI_DING_SHARE $ANS $RSPFILE
      fi

      echo -n "Enter OIRI DING PV local Mount Point [$OIRI_DING_LOCAL_SHARE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIRI_DING_LOCAL_SHARE $ANS $RSPFILE
      fi

      echo -n "Enter OIRI Work Persistent Volume NFS Mount Point [$OIRI_WORK_SHARE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIRI_WORK_SHARE $ANS $RSPFILE
      fi

      echo -n "Enter Number of OIRI Servers to start  [$OIRI_REPLICAS]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
        if check_number $ANS
        then
           replace_value OIRI_REPLICAS $ANS $RSPFILE
        else
           echo "Port must be numeric - leaving value unchanged."
        fi
      fi

      echo -n "Enter Number of OIRI UI Servers to start  [$OIRI_UI_REPLICAS]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
        if check_number $ANS
        then
           replace_value OIRI_UI_REPLICAS $ANS $RSPFILE
        else
           echo "Port must be numeric - leaving value unchanged."
        fi
      fi

      echo -n "Enter Number of OIRI DING Servers to start  [$OIRI_SPARK_REPLICAS]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
        if check_number $ANS
        then
           replace_value OIRI_SPARK_REPLICAS $ANS $RSPFILE
        else
           echo "Port must be numeric - leaving value unchanged."
        fi
      fi

      echo ""

      echo -n "Enter OIRI Database Scan Address (Use Hostname for non-RAC)  [$OIRI_DB_SCAN]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIRI_DB_SCAN $ANS $RSPFILE
      fi

      echo -n "Enter Database Listener Port [$OIRI_DB_LISTENER]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
        if check_number $ANS
        then
           replace_value OIRI_DB_LISTENER $ANS $RSPFILE
        else
           echo "Port must be numeric - leaving value unchanged."
        fi
      fi

      echo -n "Enter OIRI Database Service Name [$OIRI_DB_SERVICE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIRI_DB_SERVICE $ANS $RSPFILE
      fi

      echo -n "Enter SYS Password :"
      read -s ANS

      if [ ! "$ANS" = "" ]
      then
           echo
           echo -n "Confirm Password of SYS Users :"
           read -s ACHECK
           if [ ! "$ANS" = "$ACHECK" ]
           then
              echo "Passwords do not match!"
              exit
           else
               echo
               if  check_password "UN" $ANS
               then
                 replace_password OIRI_DB_SYS_PWD $ANS $PWDFILE
               else
                 echo "Password not set"
               fi
           fi
      else
         echo "Leaving value as previously defined"
      fi

      echo -n "Enter RCU Prefix [$OIRI_RCU_PREFIX]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIRI_RCU_PREFIX $ANS $RSPFILE
      fi

      echo -n "Enter Password for OIRI Schemas: "
      read -s ANS

      if [ ! "$ANS" = "" ]
      then
           echo
           echo -n "Confirm Password of OIRI Schemas :"
           read -s ACHECK
           if [ ! "$ANS" = "$ACHECK" ]
           then
              echo "Passwords do not match!"
              exit
           else
               echo
               if  check_password "UN" $ANS
               then
                 replace_password OIRI_SCHEMA_PWD $ANS $PWDFILE
               else
                 echo "Password not set"
               fi
           fi
      else
         echo "Leaving value as previously defined"
      fi

      echo -n "Enter Password for OIRI Keystore: "
      read -s ANS

      if [ ! "$ANS" = "" ]
      then
           echo
           echo -n "Confirm Password of OIRI Keystore :"
           read -s ACHECK
           if [ ! "$ANS" = "$ACHECK" ]
           then
              echo "Passwords do not match!"
              exit
           else
               echo
               replace_password OIRI_KEYSTORE_PWD $ANS $PWDFILE
           fi
      else
         echo "Leaving value as previously defined"
      fi

      if [ "$GET_USER" = "true" ]
      then
         echo -n "Enter OIRI Service User [$OIRI_SERVICE_USER]:"
         read ANS

         if [ ! "$ANS" = "" ]
         then
              replace_value OIRI_SERVICE_USER $ANS $RSPFILE
         fi
      fi 

      echo -n "Enter Password for $OIRI_SERVICE_USER account: "
      read -s ANS

      if [ ! "$ANS" = "" ]
      then
           echo
           echo -n "Confirm Password :"
           read -s ACHECK
           if [ ! "$ANS" = "$ACHECK" ]
           then
              echo "Passwords do not match!"
              exit
           else
               echo
               replace_password OIRI_SERVICE_PWD $ANS $PWDFILE
           fi
      else
         echo "Leaving value as previously defined"
      fi

      if [ "$GET_USER" = "true" ]
      then
         echo -n "Enter OIRI Engineering User [$OIRI_ENG_USER]:"
         read ANS

         if [ ! "$ANS" = "" ]
         then
              replace_value OIRI_ENG_USER $ANS $RSPFILE
         fi
      fi 

      echo -n "Enter Password for $OIRI_ENG_USER account: "
      read -s ANS

      if [ ! "$ANS" = "" ]
      then
           echo
           echo -n "Confirm Password :"
           read -s ACHECK
           if [ ! "$ANS" = "$ACHECK" ]
           then
              echo "Passwords do not match!"
              exit
           else
               echo
               replace_password OIRI_ENG_PWD $ANS $PWDFILE
           fi
      else
         echo "Leaving value as previously defined"
      fi

      echo -n "Enter OIG Internal URL [$OIRI_OIG_URL]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OIRI_OIG_URL $ANS $RSPFILE
      fi

      echo -n "Perform Initial OIG Data Load [$OIRI_LOAD_DATA]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           if [ "$ANS" = "true" ] ||  [ "$ANS" = "false" ]
           then
               replace_value OIRI_LOAD_DATA $ANS $RSPFILE
           else
               echo "Enter true or false."
           fi
      fi
fi
if [ "$INSTALL_OAA" = "true" ] 
then
      echo
      echo "Oracle Advanced Authentication Parameters"
      echo "-----------------------------------------"
      echo

      echo -n "Enter OAA Management Image Name [$OAA_MGT_IMAGE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAA_MGT_IMAGE $ANS $RSPFILE
      fi

      echo -n "Enter OAA Management Image Version [$OAAMGT_VER]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAAMGT_VER $ANS $RSPFILE

      fi

      echo -n "Enter OAA Images Version [$OAA_VER]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAA_VER $ANS $RSPFILE

      fi


      if [ "$GET_NS" = "true" ]
      then
         echo -n "Enter OAA Namespace [$OAANS]:"
         read ANS

         if [ ! "$ANS" = "" ]
         then
              replace_value OAANS $ANS $RSPFILE
         fi

         echo -n "Enter Coherence Namespace [$OAACONS]:"
         read ANS

         if [ ! "$ANS" = "" ]
         then
              replace_value OAACONS $ANS $RSPFILE
         fi
      fi

      echo -n "Enter OAA Deployment Name [$OAA_DEPLOYMENT]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           if [ "$ANS" = "oaa" ]
           then
               echo "A deployment name of oaa is not permitted, using - $OAA_DEPLOYMENT"
           else
               replace_value OAA_DEPLOYMENT $ANS $RSPFILE
           fi
      fi

      echo -n "Enter OAA Domain Name [$OAA_DOMAIN]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAA_DOMAIN $ANS $RSPFILE
      fi

      echo -n "Enter OAA Vault Type (file/oci) [$OAA_VAULT_TYPE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           if [ "$ANS" = "file" ] || [ "$ANS" = "oci" ]
           then
               replace_value OAA_DOMAIN $ANS $RSPFILE
           else
               echo "Invalid Value - Defaulting to OAA_VAULT_TYPE"
           fi
      fi

      if [ "$USE_INGRESS" = "true" ]
      then
         echo -n "Enter OAA Runtime Host Name [$OAA_RUNTIME_HOST]:"
         read ANS
   
         if [ ! "$ANS" = "" ]
         then
             replace_value OAA_RUNTIME_HOST $ANS $RSPFILE
         fi
   
         echo -n "Enter OAA Admin Host Name [$OAA_ADMIN_HOST]:"
         read ANS
   
         if [ ! "$ANS" = "" ]
         then
             replace_value OAA_ADMIN_HOST $ANS $RSPFILE
         fi

         echo -n "Do you wish to create OHS Sample Files (y/n) : "
         read ANS

         if check_yes $ANS 
         then
             OAA_CREATE_OHS=true
         else
             OAA_CREATE_OHS=false
         fi
         replace_value OAA_CREATE_OHS $OAA_CREATE_OHS $RSPFILE
      fi
   
      echo -n "Enter OAA Configuration Persistent Volume NFS Mount Point [$OAA_CONFIG_SHARE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAA_CONFIG_SHARE $ANS $RSPFILE
      fi

      echo -n "Enter OAA PV local Mount Point [$OAA_LOCAL_CONFIG_SHARE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAA_LOCAL_CONFIG_SHARE $ANS $RSPFILE
      fi

      echo -n "Enter OAA Credential Persistent Volume NFS Mount Point [$OAA_CRED_SHARE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAA_CRED_SHARE $ANS $RSPFILE
      fi

      echo -n "Enter OAA Credential PV local Mount Point [$OAA_LOCAL_CRED_SHARE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAA_LOCAL_CRED_SHARE $ANS $RSPFILE
      fi

      echo -n "Enter OAA Log Persistent Volume NFS Mount Point [$OAA_LOG_SHARE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAA_LOG_SHARE $ANS $RSPFILE
      fi

      echo -n "Enter OAA Log PV local Mount Point [$OAA_LOCAL_LOG_SHARE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAA_LOCAL_LOG_SHARE $ANS $RSPFILE
      fi

      if [ "$OAA_VAULT_TYPE" = "file" ]
      then
           echo -n "Enter OAA Vault Persistent Volume NFS Mount Point [$OAA_VAULT_SHARE]:"
           read ANS

           if [ ! "$ANS" = "" ]
           then
                replace_value OAA_VAULT_SHARE $ANS $RSPFILE
           fi

           echo -n "Enter OAA Vault PV local Mount Point [$OAA_LOCAL_VAULT_SHARE]:"
           read ANS

           if [ ! "$ANS" = "" ]
           then
                replace_value OAA_LOCAL_VAULT_SHARE $ANS $RSPFILE
           fi

           echo -n "Enter Vault Password :"
           read -s ANS

           if [ ! "$ANS" = "" ]
           then
                echo
                echo -n "Confirm Password of Vault Users :"
                read -s ACHECK
                if [ ! "$ANS" = "$ACHECK" ]
                then
                   echo "Passwords do not match!"
                   exit
                else
                    echo
                    replace_password OAA_VAULT_PWD $ANS $PWDFILE
                fi
            else
               echo "Leaving value as previously defined"
            fi
      fi

      echo -n "Enter Number of OAA Servers to start  [$OAA_REPLICAS]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
        if check_number $ANS
        then
           replace_value OAA_REPLICAS $ANS $RSPFILE
           replace_value OAA_ADMIN_REPLICAS $ANS $RSPFILE
           replace_value OAA_POLICY_REPLICAS $ANS $RSPFILE
           replace_value OAA_SPUI_REPLICAS $ANS $RSPFILE
           replace_value OAA_TOTP_REPLICAS $ANS $RSPFILE
           replace_value OAA_YOTP_REPLICAS $ANS $RSPFILE
           replace_value OAA_FIDO_REPLICAS $ANS $RSPFILE
           replace_value OAA_EMAIL_REPLICAS $ANS $RSPFILE
           replace_value OAA_SMS_REPLICAS $ANS $RSPFILE
           replace_value OAA_PUSH_REPLICAS $ANS $RSPFILE
        else
           echo "Port must be numeric - leaving value unchanged."
        fi
      fi

      echo -n "Enter Number of OAA Risk Servers to start  [$OAA_RISK_REPLICAS]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
        if check_number $ANS
        then
           replace_value OAA_RISK_REPLICAS $ANS $RSPFILE
           replace_value OAA_RISKCC_REPLICAS $ANS $RSPFILE
        else
           echo "Port must be numeric - leaving value unchanged."
        fi
      fi

      echo ""

      echo -n "Enter OAA Database Scan Address (Use Hostname for non-RAC)  [$OAA_DB_SCAN]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAA_DB_SCAN $ANS $RSPFILE
      fi

      echo -n "Enter Database Listener Port [$OAA_DB_LISTENER]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
        if check_number $ANS
        then
           replace_value OAA_DB_LISTENER $ANS $RSPFILE
        else
           echo "Port must be numeric - leaving value unchanged."
        fi
      fi

      echo -n "Enter OAA Database Service Name [$OAA_DB_SERVICE]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAA_DB_SERVICE $ANS $RSPFILE
      fi

      echo -n "Enter OAA a Database Host Name [$OAA_DB_HOST]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAA_DB_HOST $ANS $RSPFILE
      fi

      echo -n "Enter OAA Database Host User Name [$OAA_DB_USER]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAA_DB_USER $ANS $RSPFILE
      fi

      echo -n "Enter OAA Database ORACLE_SID [$OAA_DB_SID]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAA_DB_SID $ANS $RSPFILE
      fi

      echo -n "Enter OAA Database ORACLE_HOME [$OAA_DB_HOME]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAA_DB_HOME $ANS $RSPFILE
      fi

      echo -n "Enter SYS Password :"
      read -s ANS

      if [ ! "$ANS" = "" ]
      then
           echo
           echo -n "Confirm Password of SYS Users :"
           read -s ACHECK
           if [ ! "$ANS" = "$ACHECK" ]
           then
              echo "Passwords do not match!"
              exit
           else
               echo
               if  check_password "UN" $ANS
               then
                 replace_password OAA_DB_SYS_PWD $ANS $PWDFILE
               else
                 echo "Password not set"
               fi
           fi
      else
         echo "Leaving value as previously defined"
      fi

      echo -n "Enter RCU Prefix [$OAA_RCU_PREFIX]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAA_RCU_PREFIX $ANS $RSPFILE
      fi

      echo -n "Enter Password for OAA Schemas: "
      read -s ANS

      if [ ! "$ANS" = "" ]
      then
           echo
           echo -n "Confirm Password of OAA Schemas :"
           read -s ACHECK
           if [ ! "$ANS" = "$ACHECK" ]
           then
              echo "Passwords do not match!"
              exit
           else
               echo
               if  check_password "UN" $ANS
               then
                 replace_password OAA_SCHEMA_PWD $ANS $PWDFILE
               else
                 echo "Password not set"
               fi
           fi
      else
         echo "Leaving value as previously defined"
      fi

      echo -n "Enter Password for OAA Keystores: "
      read -s ANS

      if [ ! "$ANS" = "" ]
      then
           echo
           echo -n "Confirm Password of OAA Keystore :"
           read -s ACHECK
           if [ ! "$ANS" = "$ACHECK" ]
           then
              echo "Passwords do not match!"
              exit
           else
               echo
               replace_password OAA_KEYSTORE_PWD $ANS $PWDFILE
           fi
      else
         echo "Leaving value as previously defined"
      fi

      if [ "$GET_USER" = "true" ]
      then
         echo -n "Enter OAA Admin User [$OAA_ADMIN_USER]:"
         read ANS

         if [ ! "$ANS" = "" ]
         then
              replace_value OAA_ADMIN_USER $ANS $RSPFILE
         fi
      fi 

      echo -n "Enter Password for $OAA_ADMIN_USER account: "
      read -s ANS

      if [ ! "$ANS" = "" ]
      then
           echo
           echo -n "Confirm Password :"
           read -s ACHECK
           if [ ! "$ANS" = "$ACHECK" ]
           then
              echo "Passwords do not match!"
              exit
           else
               echo
               if  check_password "UN" $ANS
               then
                 replace_password OAA_ADMIN_PWD $ANS $PWDFILE
               else
                 echo "Password not set"
               fi
           fi
      else
         echo "Leaving value as previously defined"
      fi

      echo -n "Enter Password for OAM_OAUTH account: "
      read -s ANS

      if [ ! "$ANS" = "" ]
      then
           echo
           echo -n "Confirm Password :"
           read -s ACHECK
           if [ ! "$ANS" = "$ACHECK" ]
           then
              echo "Passwords do not match!"
              exit
           else
               echo
               if  check_password "NS" $ANS
               then
                 replace_password OAA_OAUTH_PWD $ANS $PWDFILE
               else
                 echo "Password not set"
               fi
           fi
      else
         echo "Leaving value as previously defined"
      fi

      echo -n "Do you wish to Create an OAA Test User (y/n) : "
      read ANS

      if check_yes $ANS 
      then
          OAA_CREATE_TESTUSER=true
      else
          OAA_CREATE_TESTUSER=false
      fi
      replace_value OAA_CREATE_TESTUSER $OAA_CREATE_TESTUSER $RSPFILE

      if [ "$OAA_CREATE_TESTUSER" = "true" ]
      then
         if [ "$GET_USER" = "true" ] 
         then
            echo -n "Enter OAA Test User name [$OAA_USER]:"
            read ANS
   
            if [ ! "$ANS" = "" ]
            then
                 replace_value OAA_USER $ANS $RSPFILE
            fi
         fi 

         echo -n "Enter Password for $OAA_USER account: "
         read -s ANS

         if [ ! "$ANS" = "" ]
         then
              echo
              echo -n "Confirm Password :"
              read -s ACHECK
              if [ ! "$ANS" = "$ACHECK" ]
              then
                 echo "Passwords do not match!"
                 exit
              else
                  echo
                  if  check_password "UN" $ANS
                  then
                     replace_password OAA_USER $ANS $PWDFILE
                  else
                     echo "Password not set"
                  fi
              fi
         else
            echo "Leaving value as previously defined"
         fi

         echo -n "Enter Email Address for $OAA_USER account [$OAA_USER_EMAIL] : "
         read ANS

         if [ ! "$ANS" = "" ]
         then
             replace_value OAA_USER_EMAIL $ANS $RSPFILE
         fi

         echo -n "Enter Post Code for $OAA_USER account [$OAA_USER_POSTCODE] : "
         read ANS

         if [ ! "$ANS" = "" ]
         then
             replace_value OAA_USER_POSTCODE $ANS $RSPFILE
         fi
      fi

      echo -n "Enter Unified Messaging Service URL [$OAA_EMAIL_SERVER]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAA_EMAIL_SERVER $ANS $RSPFILE
           replace_value OAA_SMS_SERVER $ANS $RSPFILE
      fi

      echo -n "Enter Unified Messaging Service User [$OAA_EMAIL_USER]:"
      read ANS

      if [ ! "$ANS" = "" ]
      then
           replace_value OAA_EMAIL_USER $ANS $RSPFILE
           replace_value OAA_SMS_USER $ANS $RSPFILE
      fi

      echo -n "Enter Password for $OAA_EMAIL_USER account: "
      read -s ANS

      if [ ! "$ANS" = "" ]
      then
           echo
           echo -n "Confirm Password :"
           read -s ACHECK
           if [ ! "$ANS" = "$ACHECK" ]
           then
              echo "Passwords do not match!"
              exit
           else
               echo
               replace_password OAA_EMAIL_PWD $ANS $PWDFILE
               replace_password OAA_SMS_PWD $ANS $PWDFILE
           fi
      else
         echo "Leaving value as previously defined"
      fi

fi
echo
echo "Oracle HTTP Server Parameters"
echo "-----------------------------"
echo

if [ "$INSTALL_OHS" = "true" ] || [ "$UPDATE_OHS" = "true" ]
then

    echo -n "Enter OHS1 Hostname [$OHS_HOST1]:"
    read ANS

    if [ ! "$ANS" = "" ]
    then
      replace_value OHS_HOST1 $ANS $RSPFILE
    fi


    echo -n "Enter OHS1 Instance Name [$OHS1_NAME]:"
    read ANS

    if [ ! "$ANS" = "" ]
    then
      replace_value OHS1_NAME $ANS $RSPFILE
    fi

    echo -n "Enter OHS2 Hostname [$OHS_HOST2]:"
    read ANS

    if  [ ! "$ANS" = "" ]
    then
      replace_value OHS_HOST2 $ANS $RSPFILE
    fi

    echo -n "Enter OHS2 Instance Name [$OHS2_NAME]:"
    read ANS

    if [ ! "$ANS" = "" ]
    then
      replace_value OHS2_NAME $ANS $RSPFILE
    fi

    echo -n "Enter OHS Listen Port [$OHS_PORT]:"
    read ANS

    if [ ! "$ANS" = "" ]
    then
      replace_value OHS_PORT $ANS $RSPFILE
    fi

    echo -n "Oracle HTTP Base Directory [$OHS_BASE]:"
    read ANS

    if [ ! "$ANS" = "" ]
    then
      replace_value OHS_BASE $ANS $RSPFILE
      OHS_BASE=$ANS
    fi

    echo -n "Oracle HTTP Oracle Home Directory [$OHS_ORACLE_HOME]:"
    read ANS

    if [ ! "$ANS" = "" ]
    then
       replace_value OHS_ORACLE_HOME $ANS $RSPFILE
    fi

    echo -n "Oracle HTTP Domain Directory [$OHS_DOMAIN]:"
    read ANS

    if [ ! "$ANS" = "" ]
    then
      replace_value OHS_DOMAIN $ANS $RSPFILE
    fi

fi

if [ "$INSTALL_OHS" = "true" ]
then
    echo -n "Oracle HTTP Installer Name [$OHS_INSTALLER]:"
    read ANS

    if [ ! "$ANS" = "" ]
    then
       replace_value OHS_INSTALLER $ANS $RSPFILE
    fi

    if [ "$GET_USER" = "true" ]
    then
       echo -n "Enter Name of Node Manager Admin User to be used [$NM_ADMIN_USER]:"
       read ANS

       if [ ! "$ANS" = "" ]
       then
          replace_value NM_ADMIN_USER $ANS $RSPFILE
       fi

       echo -n "Enter Password for $NM_ADMIN_USER account: "
       read -s ANS

       if [ ! "$ANS" = "" ]
       then
          echo
          echo -n "Confirm Password :"
          read -s ACHECK
          if [ ! "$ANS" = "$ACHECK" ]
          then
             echo "Passwords do not match!"
             exit 1
          else
              echo
              if  check_password "UN" $ANS
              then
                 replace_password NM_ADMIN_PWD $ANS $PWDFILE
              else
                 echo "Password not set"
                 exit 1
              fi
          fi
       else
          echo "Leaving value as previously defined"
       fi
      fi

    if [ "$GET_PORT" = "true" ]
    then
       echo -n "Enter SSL Listen Port for OHS [$OHS_HTTPS_PORT]:"
       read ANS

       if [ ! "$ANS" = "" ]
       then
         if check_number $ANS
         then
            replace_value OHS_HTTPS_PORT $ANS $RSPFILE
         else
            echo "Port must be numeric - leaving value unchanged."
         fi
       fi

       echo -n "Enter Node Manager Listen Port [$NM_PORT]:"
       read ANS

       if [ ! "$ANS" = "" ]
       then
         if check_number $ANS
         then
          replace_value NM_PORT $ANS $RSPFILE
         else
          echo "Port must be numeric - leaving value unchanged."
         fi
       fi
    fi
fi


WORKER_NODES=`kubectl get nodes | grep -v NAME | grep Ready | grep -v master | head -2 | awk '{ print $1 }'`
K8_WORKER_HOST1=`echo $WORKER_NODES | cut -f1 -d' '`
K8_WORKER_HOST2=`echo $WORKER_NODES | cut -f2 -d' '`
if ! [[ $K8_WORKER_HOST1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] 
then
   DOMAIN=`domainname`
   if [ "$DOMAIN" = "(none)" ] ||  [ "$DOMAIN" = "" ]
   then
      K8_WORKER_HOST1=$K8_WORKER_HOST1
      K8_WORKER_HOST2=$K8_WORKER_HOST2
   else
      K8_WORKER_HOST1=$K8_WORKER_HOST1.$DOMAIN
      K8_WORKER_HOST2=$K8_WORKER_HOST2.$DOMAIN
   fi
fi

replace_value K8_WORKER_HOST1 $K8_WORKER_HOST1 $RSPFILE
replace_value K8_WORKER_HOST2 $K8_WORKER_HOST2 $RSPFILE
replace_value OAM_OAP_HOST $K8_WORKER_HOST1 $RSPFILE

echo ""
echo "You have Successfully created/edited the response file : $SCRIPTDIR/responsefile/idm.rsp."
echo "You have Successfully created/edited the response password file: $SCRIPTDIR/responsefile/.idmpwds"
echo ""
echo "Review these files before starting provisioning."
echo "You can run $SCRIPTDIR/prereqchecks.sh to check your environment before proceeding."

