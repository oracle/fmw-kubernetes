#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of deploying the Oracle WebLogic Operator
#
# Dependencies: ./common/functions.sh
#               ./responsefile/idm.rsp
#
# Usage: provision_operator.sh
#
. common/functions.sh
. $RSPFILE


WORKDIR=$LOCAL_WORKDIR
LOGDIR=$WORKDIR/OPER/logs

if [ "$INSTALL_OAM" != "true" ] && [ "$INSTALL_OAM" != "TRUE" ] &&  [ "$INSTALL_OIG" != "true" ] && [ "$INSTALL_OIG" != "TRUE" ]
then
     echo "You have not requested OAM or OIG installation"
     exit 1
fi

echo
echo -n "Provisioning WLS Operator on "
date +"%a %d %b %Y %T"
echo "-----------------------------------------------------"
echo

START_TIME=`date +%s`
create_local_workdir
create_logdir

echo -n "Provisioning WLS Operator on " >> $LOGDIR/timings.log
date >> $LOGDIR/timings.log
echo "----------------------------------------------------" >> $LOGDIR/timings.log

if [ -d $WORKDIR/weblogic-kubernetes-operator ]
then
   echo "Weblogic Operator Samples already downloaded - Skipping"
else 
   download_operator_samples $WORKDIR
fi

if [ -d $WORKDIR/fmw-kubernetes ]
then
   echo "IDM FMW Samples already downloaded - Skipping"
else
   download_samples $WORKDIR
fi

cp -rf $WORKDIR/fmw-kubernetes/OracleAccessManagement/kubernetes/$OPER_VER/create-access-domain $WORKDIR/weblogic-kubernetes-operator/kubernetes/samples/scripts/
cp -rf $WORKDIR/fmw-kubernetes/OracleIdentityGovernance/kubernetes/$OPER_VER/create-oim-domain $WORKDIR/weblogic-kubernetes-operator/kubernetes/samples/scripts/
mv -f ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain  ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain_backup
cp -rf ${WORKDIR}/fmw-kubernetes/OracleAccessManagement/kubernetes/3.0.1/ingress-per-domain ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain

delete_crd > /dev/null 2> /dev/null
create_namespace $OPERNS
create_service_account $OPER_ACT $OPERNS
cd $WORKDIR/weblogic-kubernetes-operator
helm install weblogic-kubernetes-operator kubernetes/charts/weblogic-operator --namespace $OPERNS --set image=weblogic-kubernetes-operator:$OPER_VER --set serviceAccount=$OPER_ACT --set "domainNamespaces={}" --set "javaLoggingLevel=FINE" --wait

check_running $OPERNS weblogic-operator 


exit

#
