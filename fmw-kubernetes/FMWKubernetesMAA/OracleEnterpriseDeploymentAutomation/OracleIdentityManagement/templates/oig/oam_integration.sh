#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script to run OIGOAMIntegration.sh
#
export JAVA_HOME=/u01/jdk
export APPSERVER_TYPE=wls
export ORACLE_HOME=/u01/oracle
export OIM_ORACLE_HOME=/u01/oracle/idm
export WL_HOME=/u01/oracle/wlserver

cd /u01/oracle/idm/server/ssointg/bin
chmod +x *.sh
./OIGOAMIntegration.sh -configureSSOIntegration

