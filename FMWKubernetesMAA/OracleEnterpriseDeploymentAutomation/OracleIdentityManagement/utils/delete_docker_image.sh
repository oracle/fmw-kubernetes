#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of Deleting a docker image
#
# Dependencies: ../common/functions.sh
#
# Usage: delete_docker_image.sh oud|oudsm|oam|oig
#
. ../common/functions.sh

IMAGE=$1
if [ "$IMAGE" = "" ]
then
    echo Usage:
    echo "  delete_docker_image.sh oud|oudsm|oam|oig"
    exit 1
fi 

echo -n "Are you sure you want to remove $IMAGE docker images on all Kubernetes nodes (y/n) :"
read ANS
if [ "$ANS" = "y" ]
then
    remove_docker_image $IMAGE
else
    echo "Action Aborted"
fi
