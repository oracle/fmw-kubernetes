#!/bin/bash
# Copyright (c) 2021, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example script to add the Global Passphrase to  OIGOAMIntegration.sh property files
#
PP=`/u01/oracle/oracle_common/common/bin/wlst.sh /u01/oracle/user_projects/workdir/get_passphrase.py | sed '1,13d;15,$d'`

if [ "$PP" = "" ]
then
    echo "Failed to get Global Passphrase"
    exit 1
fi
echo s/#SSO_KEYSTORE_JKS_PASSWORD:.*/SSO_KEYSTORE_JKS_PASSWORD: $PP/ >> /u01/oracle/user_projects/workdir/oamoig.sedfile
echo s/#SSO_GLOBAL_PASSPHRASE:.*/SSO_GLOBAL_PASSPHRASE: $PP/  >> /u01/oracle/user_projects/workdir/oamoig.sedfile
