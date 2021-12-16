#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of Deleting a docker image
#
# Dependencies: ../common/functions.sh
#
# Usage: delete_docker_image.sh oud|oudsm|oam|oig|oiri-ui|oiri-cli|oiri|ding|ding-cli
#
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. $MYDIR/../common/functions.sh
. $RSPFILE

IMAGE_TYPE=$1
if [ "$IMAGE_TYPE" = "" ]
then
    echo Usage:
    echo "  delete_image.sh oud|oudsm|oam|oig|oiri"
    exit 1
fi 

echo -n "Are you sure you want to remove $IMAGE images on all kuberbetes nodes (y/n) :"
read ANS
if [ "$ANS" = "n" ]
then
    echo "Action Aborted"
fi

case $IMAGE_TYPE in
    oud )
          remove_image $OUD_IMAGE $OUD_VER
          ;;
    oudsm )
          remove_image $OUDSM_IMAGE $OUDSM_VER
          ;;
    oam )
          remove_image $OAM_IMAGE $OAM_VER
          ;;
    oig )
          remove_image $OIG_IMAGE $OIG_VER
          ;;
    oiri )
          remove_image $OIRI_IMAGE $OIRI_VER
          remove_image $OIRI_UI_IMAGE $OIRIUI_VER
          remove_image $OIRI_DING_IMAGE $OIRIDING_VER
          remove_image $OIRI_CLI_IMAGE $OIRICLI_VER
          ;;
esac
