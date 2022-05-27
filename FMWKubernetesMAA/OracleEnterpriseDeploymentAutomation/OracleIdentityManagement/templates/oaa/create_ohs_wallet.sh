#/bin/bash
# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of Creating an OHS Wallet
#
export ORACLE_HOME=<OHS_ORACLE_HOME>
export PATH=$ORACLE_HOME/bin:$ORACLE_HOME/oracle_common/bin:$PATH

if [ -f <OHS_DOMAIN>/ohswallet/cwallet.sso ]
then
    echo "Oracle Wallet Exists"
else
    orapki wallet create -wallet <OHS_DOMAIN>/ohswallet -auto_login_only
fi
openssl s_client -connect <K8_WORKER_HOST1>:<OAA_K8> -showcerts </dev/null 2>/dev/null|openssl x509 -outform PEM > oaa.pem
orapki wallet add -wallet <OHS_DOMAIN>/ohswallet -trusted_cert -cert oaa.pem -auto_login_only
