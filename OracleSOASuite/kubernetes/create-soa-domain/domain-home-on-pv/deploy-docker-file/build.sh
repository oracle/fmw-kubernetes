#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
#
# Script to build a Docker image for Oracle SOA suite artifacts.
#
#=============================================================
usage() {
cat << EOF
Usage: build.sh -t [tag]
Builds a Docker Image with Oracle SOA/OSB artifacts
Parameters:
   -h: view usage
   -t: tag for image, default is 12.2.1.4
EOF
exit $1
}
#=============================================================
#== MAIN starts here...
#=============================================================
TAG="12.2.1.4"
while getopts "ht:" optname; do
  case "$optname" in
    "h")
      usage 0
      ;;
    "t")
      TAG="$OPTARG"
      ;;
    *)
      # Should not occur
      echo "ERROR: Invalid argument for build.sh"
      usage 1
      ;;
  esac
done

IMAGE_NAME="artifacts:$TAG"
DOCKERFILE_NAME=Dockerfile
# Proxy settings - Set your own proxy environment
if [ "${http_proxy}" != "" ]; then
  PROXY_SETTINGS="--build-arg http_proxy=${http_proxy}"
fi

if [ "${https_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg https_proxy=${https_proxy}"
fi

if [ "${no_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg no_proxy=${no_proxy}"
fi

# ################## #
# BUILDING THE IMAGE #
# ################## #
buildCmd="docker build $BUILD_OPTS --force-rm=true $PROXY_SETTINGS -t $IMAGE_NAME -f $DOCKERFILE_NAME ."

# BUILD THE IMAGE (replace all environment variables)
BUILD_START=$(date '+%s')
${buildCmd} || {
  echo "ERROR: There was an error building the image."
  exit 1
}
status=$?

BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`


if [ ${status} -eq 0 ]; then
  cat << EOF
INFO: Artifacts image for Oracle SOA suite
      is ready to be extended.
      --> $IMAGE_NAME
INFO: Build completed in $BUILD_ELAPSED seconds.
EOF
else
  echo "ERROR: Artifacts image for Oracle SOA Suite was NOT successfully created. Check the output and correct any reported problems with the docker build operation."
fi
