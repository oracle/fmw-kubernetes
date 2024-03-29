#!/bin/bash
# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

usage() {

  cat << EOF

  This is a helper script for creating and labeling a Kubernetes secret.
  The secret is labeled with the specified domain-uid.
 
  Usage:
 
  $(basename $0) [-n mynamespace] [-d mydomainuid] \\
    -s mysecretname [-l key1=val1] [-l key2=val2] [-f key=fileloc ]...
  
  -d <domain_uid>     : Defaults to 'sample-domain1' otherwise.

  -n <namespace>      : Defaults to 'sample-domain1-ns' otherwise.

  -s <secret-name>    : Name of secret. Required.

  -l <key-value-pair> : Secret 'literal' key/value pair, for example
                        '-l "password=abc123"'. Can be specified more than once.

  -f <key-file-pair>  : Secret 'file-name' key/file pair, for example
                        '-l walletFile=./ewallet.p12'.
                        Can be specified more than once. 

  -dry ${KUBERNETES_CLI}        : Show the ${KUBERNETES_CLI} commands (prefixed with 'dryrun:')
                        but do not perform them. 

  -dry yaml           : Show the yaml (prefixed with 'dryrun:') but do not
                        apply it. 

  -?                  : This help.

  Note: Spaces are not supported in the '-f' or '-l' parameters.
   
EOF
}

set -e
set -o pipefail

KUBERNETES_CLI="${KUBERNETES_CLI:-kubectl}"
DOMAIN_UID="sample-domain1"
NAMESPACE="sample-domain1-ns"
SECRET_NAME=""
LITERALS=""
FILENAMES=""
DRY_RUN="false"

while [ ! "${1:-}" = "" ]; do
  if [ ! "$1" = "-?" ] && [ "${2:-}" = "" ]; then
    echo "Syntax Error. Pass '-?' for usage."
    exit 1
  fi
  case "$1" in
    -s)   SECRET_NAME="${2}" ;;
    -n)   NAMESPACE="${2}" ;;
    -d)   DOMAIN_UID="${2}" ;;
    -l)   LITERALS="${LITERALS} --from-literal='${2}'" ;;
    -f)   FILENAMES="${FILENAMES} --from-file=${2}" ;;
    -dry) DRY_RUN="${2}"
          case "$DRY_RUN" in
            ${KUBERNETES_CLI}|yaml) ;;
            *) echo "Error: Syntax Error. Pass '-?' for usage."
               exit 1
               ;;
          esac
          ;;
    -?)   usage ; exit 1 ;;
    *)    echo "Syntax Error. Pass '-?' for usage." ; exit 1 ;;
  esac
  shift
  shift
done

if [ -z "$SECRET_NAME" ]; then
  echo "Error: Syntax Error. Must specify '-s'. Pass '-?' for usage."
  exit 1
fi

if [ -z "${LITERALS}${FILENAMES}" ]; then
  echo "Error: Syntax Error. Must specify at least one '-l' or '-f'. Pass '-?' for usage."
  exit
fi

set -eu

kubernetesCLIDryRunDelete() {
cat << EOF
dryrun:${KUBERNETES_CLI} -n $NAMESPACE delete secret \\
dryrun:  $SECRET_NAME \\
dryrun:  --ignore-not-found
EOF
}

kubernetesCLIDryRunCreate() {
local moredry=""
if [ "$DRY_RUN" = "yaml" ]; then
  local moredry="--dry-run=client -o yaml"
fi
cat << EOF
dryrun:${KUBERNETES_CLI} -n $NAMESPACE create secret generic \\
dryrun:  $SECRET_NAME \\
dryrun:  $LITERALS $FILENAMES ${moredry}
EOF
}

kubernetesCLIDryRunLabel() {
cat << EOF
dryrun:${KUBERNETES_CLI} -n $NAMESPACE label  secret \\
dryrun:  $SECRET_NAME \\
dryrun:  weblogic.domainUID=$DOMAIN_UID
EOF
}

kubernetesCLIDryRun() {
cat << EOF
dryrun:
dryrun:echo "@@ Info: Setting up secret '$SECRET_NAME'."
dryrun:
EOF
kubernetesCLIDryRunDelete
kubernetesCLIDryRunCreate
kubernetesCLIDryRunLabel
cat << EOF
dryrun:
EOF
}

if [ "$DRY_RUN" = "${KUBERNETES_CLI}" ]; then

  kubernetesCLIDryRun

elif [ "$DRY_RUN" = "yaml" ]; then

  echo "dryrun:---"
  echo "dryrun:"

  # don't change indent of the sed '/a' commands - the spaces are significant
  # (we use an old form of sed append to stay compatible with old bash on mac)

  source <( kubernetesCLIDryRunCreate |  sed 's/dryrun://') \
  | sed -e '/ name:/a\
  labels:' \
  | sed -e '/labels:/a\
    weblogic.domainUID:' \
  | sed "s/domainUID:/domainUID: $DOMAIN_UID/" \
  | grep -v creationTimestamp \
  | sed "s/^/dryrun:/"

else

  source <( kubernetesCLIDryRun | sed 's/dryrun://')
fi
