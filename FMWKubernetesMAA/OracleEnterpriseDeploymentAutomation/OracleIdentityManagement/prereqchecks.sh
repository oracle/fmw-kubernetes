#!/bin/bash
# Copyright (c) 2021, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of the checks that can be performed before Provisioning Identity Management
# to reduce the likelihood of provisioning failing.
#
# Dependencies: ./common/functions.sh
#               ./responsefile/idm.rsp
# 
# Usage: prereqchecks.sh
#

. ./common/functions.sh
. $RSPFILE

echo "***********************************"
echo "*                                 *"
echo "* Performing Pre-requisite checks *"
echo "*                                 *"
echo "***********************************"
echo
FAIL=0
WARN=0
echo "Performing General Checks"
echo "-------------------------"

if [ "$INSTALL_OUD" = "true" ] && [ "$INSTALL_OID" = "true" ]
then
    echo "Install OUD or OID but not both."
    FAIL=$((FAIL+1))
fi

if [ "$INSTALL_OAM" = "true" ] && [ ! "$INSTALL_WLSOPER" = "true" ]
then
    echo "Install OAM requires Installation of the WebLogic Kubernetes Operator"
    FAIL=$((FAIL+1))
fi

if [ "$INSTALL_OIG" = "true" ] && [ ! "$INSTALL_WLSOPER" = "true" ]
then
    echo "Install OAM requires Installation of the WebLogic Kubernetes Operator"
    FAIL=$((FAIL+1))
fi

if [ "USE_INGRESS" = "true" ] && [ ! "$INSTALL_INGRESS" = "true" ]
then
    echo "You have requested Ingress but are not Installing it - WARNING"
    WARN=$((WARN+1))
fi

if [ ! "$USE_REGISTRY" = "true" ]
then
   echo -n "Checking Images Directory : "
   if [ -d $IMAGE_DIR ]
   then
     echo "Success"
   else
     echo "Directory Does not exist"
     FAIL=$((FAIL+1))
   fi
else
   REG=`echo $REGISTRY |  cut -f1 -d \/`
   echo -n "Checking Container Registry $REG is reachable : "
   nc -z $REG 443
   
   if [ "$?" = "0" ]
   then
      echo "Success"
   else
      echo "Failed"
      FAIL=$((FAIL+1))
   fi
fi

echo -n "Checking Local Working Directory : "
if [ -d $LOCAL_WORKDIR ]
then
      echo "Success"
else
      echo -n "Directory Does not exist - Creating"
      mkdir -p $LOCAL_WORKDIR
      if [ $? = 0 ]
      then
         echo ".. Success"
      else
         echo ".. Failed"
         FAIL=$((FAIL+1))
      fi
fi

echo -n "Checking NFS server is reachable : "
nc -z $PVSERVER 2049
print_status $?

echo ""
echo "Checking Images are in the repository"
echo "-------------------------------------"
# Check Images
#

if [ "$CREATE_REGSECRET" = "false" ]
then
   if [ "$INSTALL_OUD" = "true" ]
   then
       check_image_exists $OUD_IMAGE $OUD_VER
       if [  $? -gt 0 ]
       then
          FAIL=$((FAIL+1))
       fi
   fi
   if [ "$INSTALL_OUDSM" = "true" ]
   then
       check_image_exists $OUDSM_IMAGE $OUDSM_VER
       if  [ $? -gt  0 ]
       then
          FAIL=$((FAIL+1))
       fi
   fi
   if [ "$INSTALL_OAM" = "true" ]
   then
       check_image_exists $OAM_IMAGE $OAM_VER
       if  [ $? -gt  0 ]
       then
          FAIL=$((FAIL+1))
       fi
   fi

   if [ "$INSTALL_OIG" = "true" ]
   then
       check_image_exists $OIG_IMAGE $OIG_VER
       if  [ $? -gt  0 ]
       then
         FAIL=$((FAIL+1))
       fi
   fi

   if [ "$INSTALL_OIG" = "true" ] || [ "$INSTALL_OAM" = "true" ]
   then
      check_image_exists $OPER_IMAGE $OPER_VER
      if  [ $? -gt 0 ]
      then
         FAIL=$((FAIL+1))
      fi
   fi


   if [ "$INSTALL_OIRI" = "true" ]
   then
       check_image_exists $OIRI_IMAGE $OIRI_VER
       if  [ $? -gt  0 ]
       then
          FAIL=$((FAIL+1))
       fi
       check_image_exists $OIRI_CLI_IMAGE $OIRICLI_VER
       if  [ $? -gt  0 ]
       then
         FAIL=$((FAIL+1))
       fi
       check_image_exists $OIRI_UI_IMAGE $OIRIUI_VER
       if  [ $? -gt  0 ]
       then
         FAIL=$((FAIL+1))
       fi
       check_image_exists $OIRI_DING_IMAGE $OIRIDING_VER
       if  [ $? -gt  0 ]
       then
         FAIL=$((FAIL+1))
       fi
   fi

   if [ "$INSTALL_OAA" = "true" ]
   then
       check_image_exists $OAA_MGT_IMAGE $OAAMGT_VER
       if  [ $? -gt  0 ]
       then
         FAIL=$((FAIL+1))
       fi
   fi

fi

# Check Load Balancers are set up
#


echo ""
echo "Checking Loadbalancers are setup"
echo "--------------------------------"
if [ "$INSTALL_OAM" = "true" ]
then
    if ! check_lbr $OAM_LOGIN_LBR_HOST $OAM_LOGIN_LBR_PORT
    then
        echo "Setup $OAM_LOGIN_LBR_HOST:$OAM_LOGIN_LBR_HOST Before continuing."
        FAIL=$((FAIL+1))
    fi
    if ! check_lbr $OAM_ADMIN_LBR_HOST $OAM_ADMIN_LBR_PORT
    then
        echo "Setup $OAM_ADMIN_LBR_HOST:$OAM_ADMIN_LBR_HOST Before continuing."
        FAIL=$((FAIL+1))
    fi
fi

if [ "$INSTALL_OIG" = "true" ]
then
    if ! check_lbr $OIG_LBR_HOST $OIG_LBR_PORT
    then
        echo "Setup $OIG_LBR_HOST:$OIG_LBR_HOST Before continuing."
        FAIL=$((FAIL+1))
    fi
    if ! check_lbr $OIG_ADMIN_LBR_HOST $OIG_ADMIN_LBR_PORT
    then
        echo "Setup $OIG_ADMIN_LBR_HOST:$OIG_ADMIN_LBR_HOST Before continuing."
        FAIL=$((FAIL+1))
    fi

    if ! check_lbr $OIG_LBR_INT_HOST $OIG_LBR_INT_PORT
    then
        echo "Setup $OIG_LBR_INT_HOST:$OIG_LBR_INT_PORT Before continuing. It is OK to ignore this one if running on a deployment host"
        WARN=$((WARN+1))
    fi
fi

# Check DB
#
echo ""
echo "Checking Database Connectivity"
echo "------------------------------"

if [ "$INSTALL_OAM" = "true" ]
then
    echo -n "Checking OAM Database : "
    nc -z $OAM_DB_SCAN $OAM_DB_LISTENER
    if [ $? = 0 ] 
    then
       echo "Success"
    else
       echo "Failed"
       FAIL=$((FAIL+1))
    fi
fi
    
if [ "$INSTALL_OIG" = "true" ]
then
    echo -n "Checking OIG Database : "
    nc -z $OIG_DB_SCAN $OIG_DB_LISTENER
    if [ $? = 0 ] 
    then
       echo "Success"
    else
       echo "Failed"
       FAIL=$((FAIL+1))
    fi
fi

if [ "$INSTALL_OIRI" = "true" ]
then
    echo -n "Checking OIRI Database : "
    nc -z $OIRI_DB_SCAN $OIRI_DB_LISTENER
    if [ $? = 0 ] 
    then
       echo "Success"
    else
       echo "Failed"
       FAIL=$((FAIL+1))
    fi
fi

if [ "$INSTALL_OAA" = "true" ]
then
    echo -n "Checking OAA Database : "
    nc -z $OAA_DB_SCAN $OAA_DB_LISTENER
    if [ $? = 0 ] 
    then
       echo "Success"
    else
       echo "Failed"
       FAIL=$((FAIL+1))
    fi
fi


# OHS CHECKS
#


if [ "$INSTALL_OHS" = "true" ] || [ "$USE_OHS" = "true" ]
then
    echo ""
    echo "Checking Oracle Http Server Pre-requisties"
    echo "------------------------------------------"

    if [ ! "$OHS_HOST1" = "" ] 
    then
       echo -n "Checking $OHS_HOST1 is reachable : "
       nc -z $OHS_HOST1 22
       if [ $? = 0 ] 
       then
          echo "Success"
       else
          echo "Failed"
          FAIL=$((FAIL+1))
       fi
       
       echo -n "Checking Passwordless SSH to $OHS_HOST1: "
       ssh -o ConnectTimeout=4 $OHS_HOST1 date > /dev/null 2>&1
       if [ $? = 0 ] 
       then
          echo "Success"
       else
          echo "Failed"
          FAIL=$((FAIL+1))
       fi

    fi

    if [ ! "$OHS_HOST2" = "" ] 
    then
       echo -n "Checking $OHS_HOST2 is reachable : "
       nc -z $OHS_HOST2 22
       if [ $? = 0 ] 
       then
          echo "Success"
       else
          echo "Failed"
          FAIL=$((FAIL+1))
       fi
       echo -n "Checking Passwordless SSH to $OHS_HOST2: "
       ssh -o ConnectTimeout=4 $OHS_HOST2 date > /dev/null 2>&1
       if [ $? = 0 ] 
       then
          echo "Success"
       else
          echo "Failed"
          FAIL=$((FAIL+1))
       fi
    fi

    if [  "$INSTALL_OHS" = "true" ] 
    then
       echo -n "Checking OHS Installer exists : "
       if [ -e $SCRIPTDIR/templates/ohs/installer/$OHS_INSTALLER ]
       then
          echo "Success"
       else
          echo "Failed"
          FAIL=$((FAIL+1))
       fi 
    fi
fi



# OUD CHECKS
#
echo ""
echo "Checking Oracle Unified Directory Pre-requisties"
echo "------------------------------------------------"
if [ "$INSTALL_OUD" = "true" ]
then
    echo -n "Checking local OUD config dir exists : "
    if [ -d $OUD_LOCAL_CONFIG_SHARE ]
    then
        echo "Success"
    else
      echo -n "Directory Does not exist - Creating"
      mkdir -p $OUD_LOCAL_CONFIG_SHARE
      if [ $? = 0 ]
      then
         echo ".. Success"
      else
         echo ".. Failed"
         FAIL=$((FAIL+1))
      fi
    fi
    echo -n "Checking local OUD config dir is mounted : "
    df -k | grep -q $OUD_LOCAL_CONFIG_SHARE 
    if [ $? = 0 ]
    then
        echo "Success"
    else
        echo "Fail"
        echo "The OUD config directory must be mounted locally so configuration files can be copied to it."
        FAIL=$((FAIL+1))
    fi

    echo -n "Checking local OUD config dir is writeable : "
    if [ -w "$OUD_LOCAL_CONFIG_SHARE" ] 
    then 
         echo "Success" 
    else 
         echo "Failed"
         echo "The OUD config directory must be writeable locally so configuration files can be copied to it."
         FAIL=$((FAIL+1))
    fi

    echo -n "Checking LDAP User Password Format : "
    if check_password "UN" $LDAP_USER_PWD
    then
      echo "Success"
    else
      FAIL=$((FAIL+1))
    fi
fi

#  OUDSM CHECKS
echo ""
echo "Checking Oracle Unified Directory "
echo "----------------------------------"
echo
if [ "$INSTALL_OUDSM" = "true" ]
then
    echo -n "Checking local OUDSM dir exists : "
    if [ -d $OUDSM_LOCAL_SHARE ]
    then
        echo "Success"
    else
      echo -n "Directory Does not exist - Creating"
      mkdir -p $OUDSM_LOCAL_SHARE
      if [ $? = 0 ]
      then
         echo ".. Success"
      else
         echo ".. Failed"
         FAIL=$((FAIL+1))
      fi
    fi

    echo -n "Checking local OUDSM dir is mounted : "
    df -k | grep -q $OUDSM_LOCAL_SHARE
    if [ $? = 0 ]
    then
      echo "Success"
    else
      echo "Warning"
      echo "The OUDSM directory must be mounted locally to run delete_oudsm"
      FAIL=$((FAIL+1))
    fi

    echo -n "Checking local OUDSM dir is writeable : "
    if [ -w "$OUDSM_LOCAL_SHARE" ]
    then
      echo "Success"
    else
      echo "Failed"
      echo "The OUDSM config directory must be writeable. "
      FAIL=$((FAIL+1))
    fi
    echo -n "Checking OUDSM Admin Password Format : "
    if check_password "UN" $OUDSM_PWD
    then
      echo "Success"
    else
       FAIL=$((FAIL+1))
    fi
fi

#  OAM CHECKS
echo ""
echo "Checking Oracle Access Manager"
echo "------------------------------"
echo
if [ "$INSTALL_OAM" = "true" ]
then
    echo -n "Checking local OAM dir exists : "
    if [ -d $OAM_LOCAL_SHARE ]
    then
        echo "Success"
    else
      echo -n "Directory Does not exist - Creating"
      mkdir -p $OAM_LOCAL_SHARE
      if [ $? = 0 ]
      then
         echo ".. Success"
      else
         echo ".. Failed"
         WARN=$((WARN+1))
      fi
    fi

    echo -n "Checking local OAM dir is mounted : "
    df -k | grep -q $OAM_LOCAL_SHARE
    if [ $? = 0 ]
    then
      echo "Success"
    else
      echo "Warning"
      echo "The OAM directory must be mounted locally to run delete_oam"
      WARN=$((WARN+1))
    fi

    echo -n "Checking local OAM dir is writeable : "
    if [ -w "$OAM_LOCAL_SHARE" ]
    then
      echo "Success"
    else
      echo "Failed"
      echo "The OAM config directory must be writeable. "
      WARN=$((WARN+1))
    fi
    echo -n "Checking OAM Schema Password Format : "
    if check_password "UNS" $OAM_SCHEMA_PWD
    then
      echo "Success"
    else
      FAIL=$((FAIL+1))
    fi
    echo -n "Checking OAM WebLogic Password Format : "
    if check_password "UN" $OAM_WEBLOGIC_PWD
    then
      echo "Success"
    else
      FAIL=$((FAIL+1))
    fi
fi

#  OIG CHECKS
echo ""
echo "Checking Oracle Identity Governance "
echo "------------------------------------"
echo
if [ "$INSTALL_OIG" = "true" ]
then
    if [ "$INSTALL_OAM" = "true" ]
    then 
       echo -n "Checking Connector Bundle has been downloaded to $CONNECTOR_DIR - "
       if [ -d $CONNECTOR_DIR/OID-12.2.1* ] 
       then 
          echo "Success"
       else
          echo " Connector Bundle not found.  Please download and stage before continuing"
          FAIL=$((FAIL+1))
       fi
    fi
    echo -n "Checking local OIG dir exists : "
    if [ -d $OIG_LOCAL_SHARE ]
    then
        echo "Success"
    else
      echo -n "Directory Does not exist - Creating"
      mkdir -p $OIG_LOCAL_SHARE
      if [ $? = 0 ]
      then
         echo ".. Success"
      else
         echo ".. Failed"
         WARN=$((WARN+1))
      fi
    fi

    echo -n "Checking local OIG dir is mounted : "
    df -k | grep -q $OIG_LOCAL_SHARE
    if [ $? = 0 ]
    then
      echo "Success"
    else
      echo "Warning"
      echo "The OIG directory must be mounted locally to run delete_oig"
      WARN=$((WARN+1))
    fi

    echo -n "Checking local OIG dir is writeable : "
    if [ -w "$OIG_LOCAL_SHARE" ]
    then
      echo "Success"
    else
      echo "Failed"
      echo "The OIG config directory must be writeable. "
      WARN=$((WARN+1))
    fi
    echo -n "Checking OIG Schema Password Format : "
    if check_password "UNS" $OIG_SCHEMA_PWD
    then
      echo "Success"
    else
      FAIL=$((FAIL+1))
    fi
    echo -n "Checking OIG WebLogic Password Format : "
    if check_password "UN" $OIG_WEBLOGIC_PWD
    then
      echo "Success"
    else
      FAIL=$((FAIL+1))
    fi
fi

# OIRI CHECKS
#
echo ""
echo "Checking Oracle Identity Role Intelligence Pre-requisties"
echo "---------------------------------------------------------"
if [ "$INSTALL_OIRI" = "true" ]
then
    echo -n "Checking local OIRI dir exists : "
    if [ -d $OIRI_LOCAL_SHARE ]
    then
        echo "Success"
    else
      echo -n "Directory Does not exist - Creating"
      mkdir -p $OIRI_LOCAL_SHARE
      if [ $? = 0 ]
      then
        echo ".. Success"
      else
        echo ".. Failed"
        FAIL=$((FAIL+1)) 
      fi
    fi
    echo -n "Checking local OIRI config dir is mounted : "
    df -k | grep -q $OIRI_LOCAL_SHARE 
    if [ $? = 0 ]
    then
      echo "Success"
    else
      echo "Fail"
      echo "The OIRI config directory must be mounted Locally"
      FAIL=$((FAIL+1))
    fi

    echo -n "Checking local OIRI config dir is writeable : "
    if [ -w "$OIRI_LOCAL_SHARE" ] 
    then 
      echo "Success" 
    else 
      echo "Failed"
      echo "The OIRI config directory must be writeable "
      FAIL=$((FAIL+1))
    fi

    echo -n "Checking local OIRI Ding dir exists : "
    if [ -d $OIRI_DING_LOCAL_SHARE ]
    then
        echo "Success"
    else
      echo -n "Directory Does not exist - Creating"
      mkdir -p $OIRI_DING_LOCAL_SHARE
      if [ $? = 0 ]
      then
         echo ".. Success"
      else
         echo ".. Failed"
         FAIL=$((FAIL+1))
      fi
    fi

    echo -n "Checking local OIRI Ding dir is mounted : "
    df -k | grep -q $OIRI_DING_LOCAL_SHARE 
    if [ $? = 0 ]
    then
        echo "Success"
    else
      echo "Fail"
      echo "The OIRI config directory must be mounted Locally"
      FAIL=$((FAIL+1))
    fi

    echo -n "Checking local OIRI ding dir is writeable : "
    if [ -w "$OIRI_DING_LOCAL_SHARE" ] 
    then 
      echo "Success" 
    else 
      echo "Failed"
      echo "The OIRI config directory must be writeable "
      FAIL=$((FAIL+1))
    fi

    echo -n "Checking OIRI Schema Password Format : "
    if check_password "UNS" $OIRI_SCHEMA_PWD
    then
      echo "Success"
    else
      FAIL=$((FAIL+1))
    fi

    echo -n "Checking OIRI Keystore Password Format : "
    if check_password "UN" $OIRI_KEYSTORE_PWD
    then
      echo "Success"
    else
      FAIL=$((FAIL+1))
    fi

    echo -n "Checking OIRI Engineer Password Format : "
    if check_password "UN" $OIRI_ENG_PWD
    then
      echo "Success"
    else
      FAIL=$((FAIL+1))
    fi

    echo -n "Checking OIRI Service Password Format : "
    if check_password "UN" $OIRI_SERVICE_PWD
    then
      echo "Success"
    else
      FAIL=$((FAIL+1))
    fi
fi


# OAA CHECKS
#
echo ""
echo "Checking Oracle Advanced Authentication Pre-requisties"
echo "------------------------------------------------------"
if [ "$INSTALL_OAA" = "true" ]
then
    echo -n "Checking local OAA Config dir exists : "
    if [ -d $OAA_LOCAL_CONFIG_SHARE ]
    then
        echo "Success"
    else
      echo -n "Directory Does not exist - Creating"
      mkdir -p $OAA_LOCAL_CONFIG_SHARE
      if [ $? = 0 ]
      then
         echo ".. Success"
      else
         echo ".. Failed"
         FAIL=$((FAIL+1))
      fi
    fi
    echo -n "Checking local OAA config dir is mounted : "
    df -k | grep -q $OAA_LOCAL_CONFIG_SHARE 
    if [ $? = 0 ]
    then
        echo "Success"
    else
        echo "Fail"
        echo "The OAA config directory must be mounted Locally"
        FAIL=$((FAIL+1))
    fi

    echo -n "Checking local OAA config dir is writeable : "
    if [ -w "$OAA_LOCAL_CONFIG_SHARE" ] 
    then 
         echo "Success" 
    else 
         echo "Failed"
         echo "The OAA config directory must be writeable "
         FAIL=$((FAIL+1))
    fi

    echo -n "Checking local OAA Credential Store dir exists : "
    if [ -d $OAA_LOCAL_CRED_SHARE ]
    then
        echo "Success"
    else
      echo -n "Directory Does not exist - Creating"
      mkdir -p $OAA_LOCAL_CRED_SHARE
      if [ $? = 0 ]
      then
         echo ".. Success"
      else
         echo ".. Failed"
         FAIL=$((FAIL+1))
      fi
    fi
    echo -n "Checking local OAA Credential dir is mounted : "
    df -k | grep -q $OAA_LOCAL_CRED_SHARE 
    if [ $? = 0 ]
    then
        echo "Success"
    else
        echo "Fail"
        echo "The OAA Credential directory must be mounted Locally"
        FAIL=$((FAIL+1))
    fi

    echo -n "Checking local OAA Credential dir is writeable : "
    if [ -w "$OAA_LOCAL_CRED_SHARE" ] 
    then 
         echo "Success" 
    else 
      echo "Failed"
      echo "The OAA Credential directory must be writeable "
      FAIL=$((FAIL+1))
    fi

    echo -n "Checking local OAA Log dir exists : "
    if [ -d $OAA_LOCAL_LOG_SHARE ]
    then
        echo "Success"
    else
      echo -n "Directory Does not exist - Creating"
      mkdir -p $OAA_LOCAL_LOG_SHARE
      if [ $? = 0 ]
      then
         echo ".. Success"
      else
         echo ".. Failed"
         FAIL=$((FAIL+1))
      fi
    fi

    echo -n "Checking local OAA Log dir is mounted : "
    df -k | grep -q $OAA_LOCAL_LOG_SHARE 
    if [ $? = 0 ]
    then
        echo "Success"
    else
        echo "Fail"
        echo "The OAA Log directory must be mounted Locally"
        FAIL=$((FAIL+1))
    fi

    echo -n "Checking local OAA Log dir is writeable : "
    if [ -w "$OAA_LOCAL_LOG_SHARE" ] 
    then 
         echo "Success" 
    else 
         echo "Failed"
         echo "The OAA Log directory must be writeable "
         FAIL=$((FAIL+1))
    fi

    if [ "$OAA_VAULT_TYPE" = "file" ]
    then
       echo -n "Checking local OAA Vault dir exists : "
       if [ -d $OAA_LOCAL_VAULT_SHARE ]
       then
           echo "Success"
       else
         echo -n "Directory Does not exist - Creating"
         mkdir -p $OAA_LOCAL_VAULT_SHARE
         if [ $? = 0 ]
         then
            echo ".. Success"
         else
            echo ".. Failed"
            FAIL=$((FAIL+1))
         fi
       fi
       echo -n "Checking local OAA Vault dir is mounted : "
       df -k | grep -q $OAA_LOCAL_VAULT_SHARE 
       if [ $? = 0 ]
       then
           echo "Success"
       else
           echo "Fail"
           echo "The OAA Vault directory must be mounted Locally"
           FAIL=$((FAIL+1))
       fi

       echo -n "Checking local OAA Vault dir is writeable : "
       if [ -w "$OAA_LOCAL_VAULT_SHARE" ] 
       then 
            echo "Success" 
       else 
            echo "Failed"
            echo "The OAA Vault directory must be writeable "
            FAIL=$((FAIL+1))
       fi
    fi

    echo -n "Checking OAA Schema Password Format : "
    if check_password "UNS" $OAA_SCHEMA_PWD
    then
      echo "Success"
    else
      FAIL=$((FAIL+1))
    fi

    echo -n "Checking OAA User Password Format : "
    if check_password "UN" $OAA_USER_PWD
    then
      echo "Success"
    else
      FAIL=$((FAIL+1))
    fi

    echo -n "Checking OAA Admin Password Format : "
    if check_password "UN" $OAA_ADMIN_PWD
    then
      echo "Success"
    else
      FAIL=$((FAIL+1))
    fi

    echo -n "Checking OAA Keystore Password Format : "
    if check_password "UN" $OAA_KEYSTORE_PWD
    then
      echo "Success"
    else
      FAIL=$((FAIL+1))
    fi

    echo -n "Checking OAA OAuth Password Format : "
    if check_password "NS" $OAA_OAUTH_PWD
    then
      echo "Success"
    else
      FAIL=$((FAIL+1))
    fi

    echo -n "Checking OAA API Password Format : "
    if check_password "UN" $OAA_API_PWD
    then
      echo "Success"
    else
      FAIL=$((FAIL+1))
    fi

    echo -n "Checking OAA Policy Password Format : "
    if check_password "UN" $OAA_POLICY_PWD
    then
      echo "Success"
    else
      FAIL=$((FAIL+1))
    fi

    echo -n "Checking OAA API Password Format : "
    if check_password "UN" $OAA_API_PWD
    then
      echo "Success"
    else
      FAIL=$((FAIL+1))
    fi

    echo -n "Checking OAA Factor Password Format : "
    if check_password "UN" $OAA_FACT_PWD
    then
      echo "Success"
    else
      FAIL=$((FAIL+1))
    fi

    echo -n "Checking OAA Vault Password Format : "
    if check_password "UN" $OAA_VAULT_PWD
    then
      echo "Success"
    else
      FAIL=$((FAIL+1))
    fi
fi


echo
echo "Summary"
echo "--------------------"
echo
if [ $FAIL = 0 ]
then
      echo "All checks Passed"
else
      echo "$FAIL checks Failed"
      exit 1
fi

if [ $WARN -gt 0 ]
then
      echo "$WARN Warnings found."
      exit 2
fi
