#!/bin/bash
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
#
#
# Script to build a Docker image for Oracle SOA Quickstart
#
#=============================================================
usage() {
cat << EOF
Usage: build.sh -t [tag]
Builds a Docker Image with Oracle SOA Quickstart for JDeveloper
Parameters:
   -h: view usage
   -t: tag for image, default is 14.1.2
EOF
exit $1
}
#=============================================================
#== MAIN starts here...
#=============================================================
TAG="14.1.2.0.0"
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

buildID=$(cat /dev/urandom | tr -dc "A-Za-z0-9" | fold -w 16 | head -n 1)
IMAGE_NAME="oracle/soajdeveloper:$TAG"
DOCKERFILE_NAME=Containerfile
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
buildCmd="${BUILD_CLI:-docker} build $BUILD_OPTS --force-rm=true $PROXY_SETTINGS --build-arg BUILD_ID=$buildID -t $IMAGE_NAME -f $DOCKERFILE_NAME ."

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
INFO: Oracle SOA Quickstart image
      is ready to be extended.
      --> $IMAGE_NAME
INFO: Build completed in $BUILD_ELAPSED seconds.
EOF
else
  echo "ERROR: Oracle SOA Quickstart was NOT successfully created. Check the output and correct any reported problems with the ${BUILD_CLI:-docker} build operation."
fi

echo "Removing all dangling images created as part of this process!!!!."
${BUILD_CLI:-docker} image prune --filter label=com.oracle.soa.jdeveloper.buildid=$buildID -f
status=$?
if [ ! ${status} -eq 0 ]; then
   echo "WARNING !!!! Not able to clean up the intermediate images. Review and clean the dangling images to avoid space issues."
fi
