#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
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
echo "Performing General Checks"
echo "-------------------------"

echo -n "Checking Images Directory :"
if [ -d $IMAGE_DIR ]
then
      echo "Success"
else
      echo "Directory Does not exist"
      exit 1
fi

echo -n "Checking Local Working Directory :"
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
         exit 1
      fi
fi

echo -n "Checking NFS server is reachable:"
nc -z $PVSERVER 2049
if [ $? ]
then
    echo "Success"
else
    echo "fail"
    exit 1
fi

echo ""
echo "Checking Docker Images are in the repository"
echo "--------------------------------------------"
# Check Docker Images
#

if [ "$INSTALL_OUD" = "true" ]
then
    check_docker_image oracle/oud 
    if ! [ $? = 0 ]
    then
        RETCODE=1
    fi
fi
if [ "$INSTALL_OUDSM" = "true" ]
then
    check_docker_image oracle/oudsm 
    if ! [ $? = 0 ]
    then
        RETCODE=1
    fi
fi
if [ "$INSTALL_OAM" = "true" ]
then
    check_docker_image oracle/oam 
    if ! [ $? = 0 ]
    then
        RETCODE=1
    fi
fi
if [ "$INSTALL_OIG" = "true" ]
then
    check_docker_image oracle/oig
    if ! [ $? = 0 ]
    then
        RETCODE=1
    fi
fi

if [ $RETCODE = 1 ]
then
        echo "Run load_docker_images.sh to attempt to load missing images"
fi

if [ "$INSTALL_OIG" = "true" ] || [ "$INSTALL_OAM" = "true" ]
then
    check_docker_image $OPER_IMAGE
    if ! [ $? = 0 ]
    then
        RETCODE=1
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
        RETCODE=1
    fi
    if ! check_lbr $OAM_ADMIN_LBR_HOST $OAM_ADMIN_LBR_PORT
    then
        echo "Setup $OAM_ADMIN_LBR_HOST:$OAM_ADMIN_LBR_HOST Before continuing."
        RETCODE=1
    fi
fi
if [ "$INSTALL_OIG" = "true" ]
then
    if ! check_lbr $OIG_LBR_HOST $OIG_LBR_PORT
    then
        echo "Setup $OIG_LBR_HOST:$OIG_LBR_HOST Before continuing."
        RETCODE=1
    fi
    if ! check_lbr $OIG_ADMIN_LBR_HOST $OIG_ADMIN_LBR_PORT
    then
        echo "Setup $OIG_ADMIN_LBR_HOST:$OIG_ADMIN_LBR_HOST Before continuing."
        RETCODE=1
    fi
    if ! check_lbr $OIG_LBR_INT_HOST $OIG_LBR_INT_PORT
    then
        echo "Setup $OIG_LBR_INT_HOST:$OIG_LBR_INT_PORT Before continuing."
        RETCODE=1
    fi
fi



# OUD CHECKS
#
echo ""
echo "Checking Oracle Unified Directory Pre-requisties"
echo "------------------------------------------------"
if [ "$INSTALL_OUD" = "true" ]
then
    echo -n "Checking local OUD config dir exists :"
    if [ -d $OUD_LOCAL_SHARE ]
    then
        echo "Success"
    else
      echo -n "Directory Does not exist - Creating"
      mkdir -p $OUD_LOCAL_SHARE
      if [ $? = 0 ]
      then
         echo ".. Success"
      else
         echo ".. Failed"
         exit 1
      fi
    fi
    echo -n "Checking local OUD config dir is mounted :"
    df -k | grep -q $OUD_LOCAL_SHARE 
    if [ $? = 0 ]
    then
        echo "Success"
    else
        echo "Fail"
        echo "The OUD config directory must be mounted locally so configuration files can be copied to it."
        exit 1
    fi

    echo -n "Checking local OUD config dir is writeable :"
    if [ -w "$OUD_LOCAL_SHARE" ] 
    then 
         echo "Success" 
    else 
         echo "Failed"
         echo "The OUD config directory must be writeable locally so configuration files can be copied to it."
         exit 1
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
          exit 1
       fi
    fi
fi

# OIRI CHECKS
#
echo ""
echo "Checking Oracle Identity Role Intelligence Pre-requisties"
echo "---------------------------------------------------------"
if [ "$INSTALL_OIRI" = "true" ]
then
    echo -n "Checking local OIRI dir exists :"
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
         exit 1
      fi
    fi
    echo -n "Checking local OIRI config dir is mounted :"
    df -k | grep -q $OIRI_LOCAL_SHARE 
    if [ $? = 0 ]
    then
        echo "Success"
    else
        echo "Fail"
        echo "The OIRI config directory must be mounted Locally"
        exit 1
    fi

    echo -n "Checking local OIRI config dir is writeable :"
    if [ -w "$OIRI_LOCAL_SHARE" ] 
    then 
         echo "Success" 
    else 
         echo "Failed"
         echo "The OIRI config directory must be writeable "
         exit 1
    fi

    echo -n "Checking local OIRI Ding dir exists :"
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
         exit 1
      fi
    fi
    echo -n "Checking local OIRI Ding dir is mounted :"
    df -k | grep -q $OIRI_DING_LOCAL_SHARE 
    if [ $? = 0 ]
    then
        echo "Success"
    else
        echo "Fail"
        echo "The OIRI config directory must be mounted Locally"
        exit 1
    fi

    echo -n "Checking local OIRI ding dir is writeable :"
    if [ -w "$OIRI_DING_LOCAL_SHARE" ] 
    then 
         echo "Success" 
    else 
         echo "Failed"
         echo "The OIRI config directory must be writeable "
         exit 1
    fi
fi
