#!/usr/bin/env bash
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Description
# This sample script automatically builds the domain creation image based in supplied input property file.
# Domain creation images are used for supplying WebLogic Deploy Tooling (WDT) model files, WDT variables files,
# WDT application archive files (collectively known as WDT model files), and the directory where the WebLogic Deploy Tooling
# software is installed (known as the WDT Home) when deploying a domain using a Domain on PV model.
# You distribute WDT model files and the WDT executable using these images, then the operator uses them to manage the domain.
# NOTE: These images are only used for creating the domain and will not be used to update the domain.

# The script installs Weblogic Image Tool and downloads Weblogic Deploy Tool, then invokes weblogic image tool to build aux image
# based on given inputs in build-domain-creation-image.properties file. There is also a password file to pass Registry password for pushing
# the image to private registry

# The following pre-requisites must be handled prior to running this script:
#    * A container image client on the build machine, such as Docker or Podman.
#        * For Docker, a minimum version of 18.03.1.ce is required.
#        * For Podman, a minimum version of 3.0.1 is required.
#    *  An installed version of Java to run Image Tool, version 8+.

# Usage:
#   Set values for the input shell environment variables in build-domain-creation-image.properties as needed before calling this script.
#   ./build-domain-creation-image.sh -i inputPropertyFile [-p passwordFile] [=w workdir] [-h]
#


# Initialize
script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"

function usage {
  echo usage: ${script} -i file [-w workdir] [-p passwordFile] [-h]
  echo "  -i Parameter inputs file, must be specified."
  echo "  -w Specify the directory where WDT and WIT will be downloaded/installed, optional."
  echo "  -p Specify the password file containing the registry password for pushing image, optional"
  echo "  -h Help"
  exit $1
}

#
# Parse the command line options
#
while getopts "hi:w:p:" opt; do
  case $opt in
    i) valuesInputFile="${OPTARG}"
    ;;
    w) workDir="${OPTARG}"
    ;;
    p) passwordFile="${OPTARG}"
    ;;
    h) usage 0
    ;;
    *) usage 1
    ;;
  esac
done

if [ -z ${valuesInputFile} ]; then
  echo "${script}: -i must be specified."
  missingRequiredOption="true"
fi

if [ "${missingRequiredOption}" == "true" ]; then
  usage 1
fi

if [ ! -f ${valuesInputFile} ]; then
    echo "Unable to locate the input parameters file ${valuesInputFile}"
    exit 1
else
    . ${valuesInputFile}
fi

if [ ! -z ${passwordFile} ]; then
    if [ ! -f ${passwordFile} ]; then
        echo "Unable to locate the password file ${passwordFile}"
        exit 1
    else
        . ${passwordFile}
    fi
fi

if [ ! -z ${workDir} ]; then
    if [ ! -d ${workDir} ]; then
        echo "Directory ${workDir} doesn't exist."
        exit 1
    fi
fi


if [ -z ${WDT_MODEL_FILE} ]; then
    echo "WDT_MODEL_FILE is not set, image will be built without any model files"
fi

if [ -z ${WDT_VARIABLE_FILE} ]; then
    echo "WDT_VAR_FILE is not set, image will be built without any WDT property file"
fi


WDT_DIR=${workDir:-${scriptDir}/workdir}
echo "using WDT_DIR: $WDT_DIR"
WDT_VERSION=${WDT_VERSION:-LATEST}
echo "Using WDT_VERSION $WDT_VERSION"

WIT_DIR=${workDir:-${scriptDir}/workdir}
echo "Using WIT_DIR $WIT_DIR"
WIT_VERSION=${WIT_VERSION:-LATEST}
echo "Using WIT_VERSION $WIT_VERSION"

IMAGE_TAG=${IMAGE_TAG:-oam-aux-v1}
echo "Using Image tag: $IMAGE_TAG"
BASE_IMAGE=${BASE_IMAGE:-ghcr.io/oracle/oraclelinux:8-slim}
echo "using Base Image: $BASE_IMAGE"
#
#function to display error, if any, on the screen
function fail {
  echo "[ERROR] $*" >&2
  exit 1
}
#function to display information on the screen
function info {
  echo "[INFO] $*"
}

#function to run prechecks
function prechecks {

  # wdt min version check
  if [[ "$WDT_VERSION" < "3.2.3" ]]; then
    fail "Minimum supported WDT version is 3.2.3. Exiting..."
  fi

  #docker or podman check
  if [ ! -x "$(command -v docker)" ]; then
    if [ ! -x "$(command -v podman)" ]; then
        echo "Can't find docker or podman.  Please add it to the path."
        exit 1
    else
        podmanVersion=$(podman version --format '{{.Version}}')
        if [[ $podmanVersion < '3.0.1' ]]; then
            echo "For Podman, a minimum version of 3.0.1 is required. Current podman version: $podmanVersion"
            exit 1
        else
            IMAGE_BUILDER_EXE=$(which podman)
            echo "using IMAGE_BUILDER_EXE $IMAGE_BUILDER_EXE"
        fi
    fi
  else
    dockerVersion=$(docker version --format '{{.Server.Version}}')
    if [[ $dockerVersion < '18.03.1' ]]; then
        echo "For docker, a minimum version of 18.03.1.ce is required. Current docker version: $dockerVersion"
        exit 1
    else
        IMAGE_BUILDER_EXE=$(which docker)
        echo "Using IMAGE_BUILDER_EXE: $IMAGE_BUILDER_EXE"
    fi
  fi

  #java check
  if [ -z ${JAVA_HOME} ]; then
    fail "Please set the JAVA_HOME environment variable to match the location of your Java installation. Java 8 or newer is required"
  fi
  if [ ! -d ${JAVA_HOME} ]; then
    fail "JAVA_HOME $JAVA_HOME doesn't exist, please set correct location of your JAVA Installation. Java 8 or newer is required"
  else
    echo "JAVA_HOME is set to ${JAVA_HOME}"
    export JAVA_HOME
  fi

  #jar check
  if [ ! -x "$(command -v jar)" ]; then
      if [ ! -f ${JAVA_HOME}/bin/jar ]; then
        fail "jar command not found and ${JAVA_HOME}/bin/jar utility does not exist, make sure jar is added to path and JAVA_HOME is valid."
      else
        JAR_CMD=${JAVA_HOME}/bin/jar
      fi
  else
    JAR_CMD="jar"
  fi
}


function download {
  local fileUrl="${1}"
  local zipFile="${2}"

  local curl_res=1
  max=20
  count=0
  while [ $curl_res -ne 0 -a $count -lt $max ] ; do
    sleep 1
    count=`expr $count + 1`
    for proxy in "${https_proxy}" "${https_proxy2}"; do
	  echo @@ "Info:  Downloading $fileUrl with https_proxy=\"$proxy\""
	  https_proxy="${proxy}" \
	    curl --silent --show-error --connect-timeout 10 -fL $fileUrl -o $zipFile
	  curl_res=$?
	  [ $curl_res -eq 0 ] && break
	done
  done
  if [ $curl_res -ne 0 ]; then
    echo @@ "Error: Download failed."
    return 1
  fi
}

function setup_wdt_shared_dir() {
  mkdir -p $WDT_DIR || return 1
}

#
# Install Weblogic Server Deploy Tooling to ${WDT_DIR}
#
function install_wdt() {

  WDT_INSTALL_ZIP_FILE="${WDT_INSTALL_ZIP_FILE:-weblogic-deploy.zip}"

  echo @@ " Info: WDT_INSTALL_ZIP_URL is '$WDT_INSTALL_ZIP_URL'"
  if [ -z ${WDT_INSTALL_ZIP_URL} ]; then
    echo @@ "WDT_INSTALL_ZIP_URL is not set"
    if [ "$WDT_VERSION" == "LATEST" ]; then
      WDT_INSTALL_ZIP_URL=${WDT_INSTALL_ZIP_URL:-"https://github.com/oracle/weblogic-deploy-tooling/releases/latest/download/$WDT_INSTALL_ZIP_FILE"}
    else
      WDT_INSTALL_ZIP_URL=${WDT_INSTALL_ZIP_URL:-"https://github.com/oracle/weblogic-deploy-tooling/releases/download/release-$WDT_VERSION/$WDT_INSTALL_ZIP_FILE"}
    fi
  fi

  local save_dir=`pwd`
  cd $WDT_DIR || return 1

  echo @@ "Info:  Downloading $WDT_INSTALL_ZIP_URL "
  download $WDT_INSTALL_ZIP_URL  $WDT_INSTALL_ZIP_FILE || return 1

  if [ ! -f $WDT_INSTALL_ZIP_FILE ]; then
    cd $save_dir
    echo @@ "Error: Download failed or $WDT_INSTALL_ZIP_FILE not found."
    return 1
  fi

  echo @@ "Info: Archive downloaded to $WDT_DIR/$WDT_INSTALL_ZIP_FILE"
  return 0

}

#
# Install WebLogic Image Tool to ${WIT_DIR}. Used by install_wit_if_needed.
# Do not call this function directory.
#
function install_wit() {

  WIT_INSTALL_ZIP_FILE="${WIT_INSTALL_ZIP_FILE:-imagetool.zip}"

  echo @@ " Info: WIT_INSTALL_ZIP_URL is '$WIT_INSTALL_ZIP_URL'"
  if [ -z ${WIT_INSTALL_ZIP_URL} ]; then
    echo @@ "WIT_INSTALL_ZIP_URL is not set"
    if [ "$WIT_VERSION" == "LATEST" ]; then
      WIT_INSTALL_ZIP_URL=${WDT_INSTALL_ZIP_URL:-"https://github.com/oracle/weblogic-image-tool/releases/latest/download/$WIT_INSTALL_ZIP_FILE"}
    else
      WIT_INSTALL_ZIP_URL=${WIT_INSTALL_ZIP_URL:-"https://github.com/oracle/weblogic-image-tool/releases/download/release-$WIT_VERSION/$WIT_INSTALL_ZIP_FILE"}
    fi
  fi

  local save_dir=`pwd`

  echo @@ "imagetool.sh not found in ${imagetoolBinDir}. Installing imagetool..."

  echo @@ "Info:  Downloading $WIT_INSTALL_ZIP_URL "
  download $WIT_INSTALL_ZIP_URL $WIT_INSTALL_ZIP_FILE || return 1

  if [ ! -f $WIT_INSTALL_ZIP_FILE ]; then
    cd $save_dir
    echo @@ "Error: Download failed or $WIT_INSTALL_ZIP_FILE not found."
    return 1
  fi
  echo @@ "Info: Archive downloaded to $WIT_DIR/$WIT_INSTALL_ZIP_FILE, about to unzip via '${JAR_CMD} xf'."

  ${JAR_CMD} xf $WIT_INSTALL_ZIP_FILE
  local jar_res=$?

  cd $save_dir

  if [ $jar_res -ne 0 ]; then
    echo @@ "Error: Install failed while unzipping $WIT_DIR/$WIT_INSTALL_ZIP_FILE"
    return $jar_res
  fi

  if [ ! -d "$WIT_DIR/imagetool/bin" ]; then
    echo @@ "Error: Install failed: directory '$WIT_DIR/imagetool/bin' not found."
    return 1
  fi

  chmod 775 $WIT_DIR/imagetool/bin/* || return 1

  #Set logging handler to both FileHandler and ConsoleHandler
  sed -i -e "s:^handlers:##handlers:g" $WIT_DIR/imagetool/bin/logging.properties
  sed -i -e "s:^#handlers:handlers:g" $WIT_DIR/imagetool/bin/logging.properties

}

#
# Checks whether WebLogic Image Tool is already installed under ${WIT_DIR}, and install
# it if not.
#
function install_wit_if_needed() {

  local save_dir=`pwd`

  mkdir -p $WIT_DIR || return 1
  cd $WIT_DIR || return 1

  imagetoolBinDir=$WIT_DIR/imagetool/bin
  if [ -f $imagetoolBinDir/imagetool.sh ]; then
    echo @@ "Info: imagetool.sh already exist in ${imagetoolBinDir}. Skipping WIT installation."
  else
    install_wit
  fi

  export WLSIMG_CACHEDIR="$WIT_DIR/imagetool-cache"

  # Check existing imageTool cache entry for WDT:
  # - if there is already an entry, and the WDT installer file specified in the cache entry exists, skip WDT installation
  # - if file in cache entry doesn't exist, delete cache entry, install WDT, and add WDT installer to cache
  # - if entry does not exist, install WDT, and add WDT installer to cache
  if [ "$WDT_VERSION" == "LATEST" ]; then
    wdtCacheVersion="latest"
  else
    wdtCacheVersion=$WDT_VERSION
  fi

  local listItems=$( ${imagetoolBinDir}/imagetool.sh cache listItems | grep "wdt_${wdtCacheVersion}" )

  if [ ! -z "$listItems" ]; then
    local wdt_file_path_in_cache=$(echo $listItems | sed 's/.*=\(.*\)/\1/')
    if [ -f "$wdt_file_path_in_cache" ]; then
      skip_wdt_install=true
    else
      echo @@ "Info: imageTool cache contains an entry for WDT zip at $wdt_file_path_in_cache which does not exist. Removing from cache entry."
      ${imagetoolBinDir}/imagetool.sh cache deleteEntry \
         --key wdt_${wdtCacheVersion}
    fi
  fi

  if [ -z "$skip_wdt_install" ]; then
    echo @@ "Info: imageTool cache does not contain a valid entry for wdt_${wdtCacheVersion}. Installing WDT"
    setup_wdt_shared_dir || return 1
    install_wdt || return 1
    ${imagetoolBinDir}/imagetool.sh cache addInstaller \
      --type wdt \
      --version $WDT_VERSION \
      --path $WDT_DIR/$WDT_INSTALL_ZIP_FILE  || return 1
  else
    echo @@ "Info: imageTool cache already contains entry ${listItems}. Skipping WDT installation."
  fi

  cd $save_dir

  echo @@ "Info: Install succeeded, imagetool install is in the $WIT_DIR/imagetool directory."
  return 0
}

prechecks
install_wit_if_needed

IMAGE=$REPOSITORY:$IMAGE_TAG
echo "Starting Building Image $IMAGE"

# Collect arguments for creating the image
WIT_CREATE_AUX_IMAGE_ARGS="createAuxImage \"--builder=${IMAGE_BUILDER_EXE}\" --tag=${IMAGE}"
if [ "${HTTPS_PROXY}" != "" ]; then
    WIT_CREATE_AUX_IMAGE_ARGS="${WIT_CREATE_AUX_IMAGE_ARGS} --httpsProxyUrl=\"${HTTPS_PROXY}\""
fi

# Login to the Image Registry, if required
if [ "${IMAGE_PUSH_REQUIRES_AUTH}" = "true" ]; then
    if [ -z $REPOSITORY ]; then
        fail "IMAGE_PUSH_REQUIRES_AUTH is set to true, but REPOSITORY is not provided in $valuesInputFile"
    fi

    if [ -z $passwordFile ]; then
        fail "IMAGE_PUSH_REQUIRES_AUTH is set to true, but no passwordFile is given"
    fi

    if [ -z $REG_USER ]; then
        fail "IMAGE_PUSH_REQUIRES_AUTH is set to true, but REG_USER is not set in input property file $valuesInputFile"
    fi

    if [ -z $REG_PASSWORD ]; then
        fail "IMAGE_PUSH_REQUIRES_AUTH is set to true, REG_PASSWORD is not set in input property file $passwordFile"
    fi

    if [ "${REG_USER}" != "" ] && [ "${REG_PASSWORD}" != "" ]; then
        if ! echo "${REG_PASSWORD}" | ${IMAGE_BUILDER_EXE} login $REPOSITORY --username ${REG_USER} --password-stdin ; then
            echo "Failed to log into $REPOSITORY">&2
            exit 1
        fi
    fi
fi

#always pull base image
WIT_CREATE_AUX_IMAGE_ARGS="${WIT_CREATE_AUX_IMAGE_ARGS} --pull"


# Gather WDT-related arguments.
WIT_CREATE_AUX_IMAGE_ARGS="${WIT_CREATE_AUX_IMAGE_ARGS} --wdtVersion=${WDT_VERSION}"

if [ "${BASE_IMAGE}" != "" ]; then
  WIT_CREATE_AUX_IMAGE_ARGS="${WIT_CREATE_AUX_IMAGE_ARGS} --fromImage=\"${BASE_IMAGE}\""
fi

if [ "${WDT_HOME}" != "" ]; then
    echo "WDT_HOME is set to ${WDT_HOME}"
    WIT_CREATE_AUX_IMAGE_ARGS="${WIT_CREATE_AUX_IMAGE_ARGS} --wdtHome=\"${WDT_HOME}\""
fi

if [ "${WDT_MODEL_HOME}" != "" ]; then
    echo "WDT_MODEL_HOME is set to ${WDT_MODEL_HOME}"
    WIT_CREATE_AUX_IMAGE_ARGS="${WIT_CREATE_AUX_IMAGE_ARGS} --wdtModelHome=\"${WDT_MODEL_HOME}\""
fi

if [ "${WDT_MODEL_FILE}" != "" ]; then
    echo "WDT_MODEL_FILE is set to ${WDT_MODEL_FILE}"
    WIT_CREATE_AUX_IMAGE_ARGS="${WIT_CREATE_AUX_IMAGE_ARGS} --wdtModel=\"${WDT_MODEL_FILE}\""
fi

if [ "${WDT_VARIABLE_FILE}" != "" ]; then
    echo "WDT_VARIABLE_FILE is set to ${WDT_VARIABLE_FILE}"
    WIT_CREATE_AUX_IMAGE_ARGS="${WIT_CREATE_AUX_IMAGE_ARGS} --wdtVariables=\"${WDT_VARIABLE_FILE}\""
fi

if [ "${WDT_ARCHIVE_FILE}" != "" ]; then
    echo "WDT_ARCHIVE_FILE is set to ${WDT_ARCHIVE_FILE}"
    WIT_CREATE_AUX_IMAGE_ARGS="${WIT_CREATE_AUX_IMAGE_ARGS} --wdtArchive=\"${WDT_ARCHIVE_FILE}\""
fi

if [ "${TARGET}" != "" ]; then
    echo "TARGET is set to ${TARGET}"
    WIT_CREATE_AUX_IMAGE_ARGS="${WIT_CREATE_AUX_IMAGE_ARGS} --target=\"${TARGET}\""
fi

if [ "${CHOWN}" != "" ]; then
    echo "CHOWN is set to ${CHOWN}"
    WIT_CREATE_AUX_IMAGE_ARGS="${WIT_CREATE_AUX_IMAGE_ARGS} --chown=\"${CHOWN}\""
fi

if [ "${BUILD_NETWORK}" != "" ]; then
    echo "BUILD_NETWORK is set to ${BUILD_NETWORK}"
    WIT_CREATE_AUX_IMAGE_ARGS="${WIT_CREATE_AUX_IMAGE_ARGS} --buildNetwork=\"${BUILD_NETWORK}\""
fi

# Add logic for copying custom typedef json file to WDT installer and set permissions
ADDITIONAL_BUILD_COMMANDS_FILE="${scriptDir}/additonal-build-files/build-files.txt"
ADDITIONAL_BUILD_FILES="${scriptDir}/additonal-build-files/OAM.json"

if [ "${ADDITIONAL_BUILD_COMMANDS_FILE}" != "" ]; then
    echo "Additional Build Commands file is set to ${ADDITIONAL_BUILD_COMMANDS_FILE}"
    WIT_CREATE_AUX_IMAGE_ARGS="${WIT_CREATE_AUX_IMAGE_ARGS} --additionalBuildCommands=\"${ADDITIONAL_BUILD_COMMANDS_FILE}\""
fi

if [ "${ADDITIONAL_BUILD_FILES}" != "" ]; then
    echo "Additonal Build file is set to ${ADDITIONAL_BUILD_FILES}"
    WIT_CREATE_AUX_IMAGE_ARGS="${WIT_CREATE_AUX_IMAGE_ARGS} --additionalBuildFiles=\"${ADDITIONAL_BUILD_FILES}\""
fi

# Create the image.
if ! "${imagetoolBinDir}/imagetool.sh" ${WIT_CREATE_AUX_IMAGE_ARGS}; then
    echo "Failed to create image ${IMAGE}">&2
    exit 1
fi

# Push image ${IMAGE_TAG}
if ! "${IMAGE_BUILDER_EXE}" push ${IMAGE}; then
    echo "Failed to push image ${IMAGE}">&2
    exit 1
else
    echo "Pushed image ${IMAGE} to image repository"
fi
