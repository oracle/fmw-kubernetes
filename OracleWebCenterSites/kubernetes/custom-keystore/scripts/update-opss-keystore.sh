#!/bin/bash
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

function toDNS1123Legal {
  local val=`echo $1 | tr "[:upper:]" "[:lower:]"`
  val=${val//"_"/"-"}
  echo "$val"
}
export DOMAIN_HOME=${DOMAIN_HOME_DIR}

# Create the domain
if [ -z "${JAVA_HOME}" ]; then
  JAVA_HOME=/usr/java/latest
fi

CUSTOM_KEYSTORE_DIR="${DOMAIN_HOME}/keystore/${ALIAS_PREFIX}"
CUSTOM_IDEN_KEYSTORE_FILE="${CUSTOM_KEYSTORE_DIR}/identity.p12";
CUSTOM_IDEN_KEYSTORE_PWD=`cat /weblogic-operator/custom-keystore-secrets/identity_password`;
CUSTOM_TRUST_KEYSTORE_FILE="${CUSTOM_KEYSTORE_DIR}/trust.p12";
CUSTOM_TRUST_KEYSTORE_PWD=`cat /weblogic-operator/custom-keystore-secrets/trust_password`;
CUSTOM_KEYSTORE_KEYPAIR_FILE="${CUSTOM_KEYSTORE_DIR}/file.p12"
adminServerPodName="${CUSTOM_DOMAIN_NAME}-$(toDNS1123Legal ${CUSTOM_ADMIN_NAME})"
if [ "${CUSTOM_SECURE_MODE}" == "true" ]; then
  ADMIN_URL="t3s://${adminServerPodName}:${ADMIN_SECURE_PORT}"
else
  ADMIN_URL="t3://${adminServerPodName}:${CUSTOM_ADMIN_LISTEN_PORT}"
fi  

domainca="domainca${ALIAS_PREFIX}"
${JAVA_HOME}/bin/keytool -genkeypair -alias ${domainca} -keyalg RSA -keysize 2048 -dname "CN=${CN_HOSTNAME}, OU=WebLogic, O=ORACLE, L=SA, S=CA, C=US"  -validity 3650 -keystore ${CUSTOM_KEYSTORE_KEYPAIR_FILE} -storepass ${CUSTOM_IDEN_KEYSTORE_PWD}  -keypass  ${CUSTOM_IDEN_KEYSTORE_PWD}

export WLST_PROPERTIES="-Dweblogic.security.TrustKeyStore=CustomTrust -Dweblogic.security.CustomTrustKeyStoreFileName=${CUSTOM_TRUST_KEYSTORE_FILE} -Dweblogic.security.CustomTrustKeyStorePassPhrase=${CUSTOM_TRUST_KEYSTORE_PWD} -Dweblogic.security.SSL.ignoreHostnameVerification=true"

export JAVA_OPTIONS="-Dweblogic.security.SSL.trustedCAKeyStore=${CUSTOM_TRUST_KEYSTORE_FILE} -Dweblogic.security.SSL.trustedCAKeyStorePassPhrase=${CUSTOM_TRUST_KEYSTORE_PWD}"

wlst.sh -skipWLSModuleScanning \
        /u01/scripts/update-opss-keystore.py \
        -domainName ${CUSTOM_DOMAIN_NAME} \
        -adminURL ${ADMIN_URL}  \
        -username `cat /weblogic-operator/secrets/username` \
        -password `cat /weblogic-operator/secrets/password` \
        -keyStoreFilePath ${CUSTOM_KEYSTORE_KEYPAIR_FILE} \
        -identityPassword ${CUSTOM_IDEN_KEYSTORE_PWD} \
        -identityType `cat /weblogic-operator/custom-keystore-secrets/identity_type` \
        -si keystore.db  -key ca.key.alias -value ${domainca}

echo "Removing DemoTrust.jks from setDomainEnv.sh...."
cp "${DOMAIN_HOME}/bin/setDomainEnv.sh" "${DOMAIN_HOME}/bin/setDomainEnv.sh.orig"
echo "Backup is available at ${DOMAIN_HOME}/bin/setDomainEnv.sh.orig"
sed -i -e "s/-Djavax.net.ssl.trustStore=\${WL_HOME}\/server\/lib\/DemoTrust.jks//g" ${DOMAIN_HOME}/bin/setDomainEnv.sh
echo "Updated setDomainEnv.sh successfully"

