#!/bin/bash
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

export DOMAIN_HOME=${DOMAIN_HOME_DIR}

# Create the domain
if [ -z "${JAVA_HOME}" ]; then
  JAVA_HOME=/usr/java/latest
fi

export CUSTOM_KEYSTORE_DIR="${DOMAIN_HOME}/keystore/${ALIAS_PREFIX}"
mkdir -p ${CUSTOM_KEYSTORE_DIR}
export CUSTOM_IDEN_KEYSTORE_TYPE=`cat /weblogic-operator/custom-keystore-secrets/identity_type`
export CUSTOM_IDEN_KEYSTORE_FILE="${CUSTOM_KEYSTORE_DIR}/identity.p12";
export CUSTOM_IDEN_KEYSTORE_PWD=`cat /weblogic-operator/custom-keystore-secrets/identity_password`;
export CUSTOM_TRUST_KEYSTORE_TYPE=`cat /weblogic-operator/custom-keystore-secrets/trust_type`;
export CUSTOM_TRUST_KEYSTORE_FILE="${CUSTOM_KEYSTORE_DIR}/trust.p12";
export CUSTOM_TRUST_KEYSTORE_PWD=`cat /weblogic-operator/custom-keystore-secrets/trust_password`;
export IDENTITY_ALIAS="servercert${ALIAS_PREFIX}"
export TRUST_ALIAS="trustcert${ALIAS_PREFIX}"

${JAVA_HOME}/bin/keytool -noprompt -genkey -alias ${IDENTITY_ALIAS}  -dname "CN=${CN_HOSTNAME}, OU=WebLogic, O=ORACLE, L=SA, S=CA, C=US" -keyalg RSA -keysize 2048 -sigalg SHA256withRSA -validity 365 -keystore ${CUSTOM_IDEN_KEYSTORE_FILE}  -keypass ${CUSTOM_IDEN_KEYSTORE_PWD}   -storepass ${CUSTOM_IDEN_KEYSTORE_PWD}

${JAVA_HOME}/bin/keytool -export -alias ${IDENTITY_ALIAS} -noprompt -file ${CUSTOM_KEYSTORE_DIR}/server.cert  -keystore ${CUSTOM_IDEN_KEYSTORE_FILE}  -storepass ${CUSTOM_IDEN_KEYSTORE_PWD}

${JAVA_HOME}/bin/keytool -noprompt -import -alias ${TRUST_ALIAS} -file ${CUSTOM_KEYSTORE_DIR}/server.cert  -keystore ${CUSTOM_TRUST_KEYSTORE_FILE}  -storepass ${CUSTOM_TRUST_KEYSTORE_PWD}

${JAVA_HOME}/bin/keytool -list -v -keystore  ${CUSTOM_IDEN_KEYSTORE_FILE}  -storepass ${CUSTOM_IDEN_KEYSTORE_PWD}

${JAVA_HOME}/bin/keytool -list -v -keystore ${CUSTOM_TRUST_KEYSTORE_FILE}  -storepass ${CUSTOM_TRUST_KEYSTORE_PWD}

wlst.sh -skipWLSModuleScanning \
        /u01/scripts/configure-custom-keystore.py \
        -oh /u01/oracle \
        -jh ${JAVA_HOME} \
        -parent ${DOMAIN_HOME}/.. \
        -name ${CUSTOM_DOMAIN_NAME} \
        -identityFile ${CUSTOM_IDEN_KEYSTORE_FILE} \
        -identityType ${CUSTOM_IDEN_KEYSTORE_TYPE} \
        -identityPassword ${CUSTOM_IDEN_KEYSTORE_PWD} \
        -trustFile ${CUSTOM_TRUST_KEYSTORE_FILE} \
        -trustType ${CUSTOM_TRUST_KEYSTORE_TYPE} \
        -trustPassword ${CUSTOM_TRUST_KEYSTORE_PWD} \
        -identityAlias ${IDENTITY_ALIAS} 

