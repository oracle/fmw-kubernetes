#!/bin/bash
# Copyright (c) 2021, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which will check that will load container images into the local
# repository on each kubernetes node
#
# Dependencies: ../common/functions.sh
#               ../responsefile/idm.rsp
#
# Usage: load_image.sh
#
. ../common/functions.sh
. $RSPFILE



function upload_operator_if_needed {
    IMAGE=$1
    VER=$2
    KNODES=`get_k8nodes`
    if [ "$IMAGE_TYPE" = "docker" ]
    then
        CMD="docker"
    else
        CMD="sudo podman"
    fi
    for node in $KNODES
    do
         echo -n "Checking $IMAGE on $node :"
         if [[ $($SSH $node "$CMD images | grep $IMAGE | grep $VER| tr -s ' ' | cut -d ' ' -f 3") = "" ]]
         then
             echo " . Loading"
             $SSH $node "$CMD pull $OPER_IMAGE:$VER"
    
         else
             echo "exists"
         fi
    done
    
}

if [ "$INSTALL_OUD" = "true" ]  
then
    OUD_IMAGE=oud-$OUD_VER.tar
    upload_image_if_needed oud $OUD_IMAGE
fi


if [ "$INSTALL_OAM" = "true" ]  
then
    OAM_IMAGE=oam-$OAM_VER.tar
    upload_image_if_needed oam $OAM_IMAGE
fi

if [ "$INSTALL_OIG" = "true" ]  
then
    OIG_IMAGE=oig-$OIG_VER.tar
    upload_image_if_needed oig $OIG_IMAGE
fi

if [ "$INSTALL_OUDSM" = "true" ]  
then
    OUDSM_IMAGE=oudsm-$OUDSM_VER.tar
    upload_image_if_needed oudsm $OUDSM_IMAGE
fi

if [ "$INSTALL_OAM" = "true" ]  || [ "$INSTALL_OIG" = "true" ]
then
  upload_operator_if_needed weblogic-kubernetes-operator $OPER_VER
fi

exit
if [ "$INSTALL_OIRI" = "true" ]  
then
    OIRI_IMAGE=oiri-$OIRI_VER.tar
    OIRI_CLI_IMAGE=oiri-cli-$OIRICLI_VER.tar
    OIRI_DING_IMAGE=oiri-ding-$OIRIDING_VER.tar
    OIRI_UI_IMAGE=oiri-ui-$OIRIUI_VER.tar
    upload_image_if_needed oiri $OIRI_IMAGE
    upload_image_if_needed oiri-cli $OIRI_CLI_IMAGE
    upload_image_if_needed oiri-ding $OIRI_DING_IMAGE
    upload_image_if_needed oiri-ui $OIRI_UI_IMAGE
fi
