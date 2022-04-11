#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of an script to run the idmConfigTool inside Kubernetes
#
export CLASSPATH=$CLASSPATH:/u01/oracle/wlserver/server/lib/weblogic.jar
export ORACLE_HOME=/u01/oracle/idm
export MW_HOME=/u01/oracle
cd $ORACLE_HOME/idmtools/bin

if [ -f configoam.log ]
then
     rm configoam.log 
fi

./idmConfigTool.sh -configOAM input_file=<WORK_DIR>/configoam.props log_file=<WORK_DIR>/configoam.log


exit
