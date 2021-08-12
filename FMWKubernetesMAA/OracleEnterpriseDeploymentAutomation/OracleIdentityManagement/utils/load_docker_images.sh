#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.  
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which will check that will load docker images into the docker
# repository on each kubernetes node
#
# Dependencies: ../common/functions.sh
#               ../responsefile/idm.rsp
#
# Usage: load_docker_images.sh
#
. ../common/functions.sh
. $RSPFILE



function upload_operator_if_needed {
    IMAGE=$1
    VER=$2
    KNODES=`get_k8nodes`
    for node in $KNODES
    do
         echo -n "Checking $IMAGE on $node :"
         if [[ $(ssh $node "docker images" | grep $IMAGE | grep $VER| tr -s ' ' | cut -d ' ' -f 3) = "" ]]
         then
             echo " . Loading"
             ssh $node "docker pull oracle/weblogic-kubernetes-operator:$VER"
             ssh $node "docker tag oracle/weblogic-kubernetes-operator:$VER weblogic-kubernetes-operator:$VER"
    
         else
             echo "exists"
         fi
    done
    
}

if [ "$INSTALL_OUD" = "true" ]  
then
    OUD_IMAGE=$(get_image_file $IMAGE_DIR oud)
    upload_image_if_needed oud $OUD_IMAGE
fi

if [ "$INSTALL_OAM" = "true" ]  
then
    OAM_IMAGE=$(get_image_file $IMAGE_DIR oam)
    upload_image_if_needed oam $OAM_IMAGE
fi

if [ "$INSTALL_OIG" = "true" ]  
then
    OIG_IMAGE=$(get_image_file $IMAGE_DIR oig)
    upload_image_if_needed oig $OIG_IMAGE
fi

if [ "$INSTALL_OUDSM" = "true" ]  
then
    OUDSM_IMAGE=$(get_image_file $IMAGE_DIR oudsm)
    upload_image_if_needed oudsm $OUDSM_IMAGE
fi

upload_operator_if_needed weblogic-kubernetes-operator $OPER_VER
