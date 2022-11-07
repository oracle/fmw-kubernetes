#!/bin/bash
# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which will delete an OAA deployment
#
# Dependencies: ../common/functions.sh
#               ../common/oaa_functions.sh
#               ../responsefile/idm.rsp
#
# Usage: delete_oaa.sh
#
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. $MYDIR/../common/functions.sh
. $MYDIR/../common/oaa_functions.sh
. $RSPFILE
WORKDIR=$LOCAL_WORKDIR/OAA
LOGDIR=$WORKDIR/logs
PROGRESS=$(get_progress)
TEMPLATE_DIR=$MYDIR/../templates/oaa

START_TIME=`date +%s`

mkdir $LOCAL_WORKDIR/deleteLogs > /dev/null 2>&1

LOG=$LOCAL_WORKDIR/deleteLogs/delete_oaa_`date +%F_%T`.log

echo "Deleting Oracle Advanced Authentication"
echo "---------------------------------------"
echo 
echo Log of Delete Session can be found at: $LOG
echo 

echo "Delete OAA Applicaiton"
oaa_mgmt "helm uninstall $OAA_DEPLOYMENT -n $OAANS" > $LOG 2>&1

echo "Check Servers have stopped"
check_stopped $OAANS $OAA_DEPLOYMENT-oaa-admin
check_stopped $OAANS $OAA_DEPLOYMENT-oaa-policy

echo "Checking for STS Resources"

kubectl get sts -n $OAANS | grep -q cache
if [ $? = 0 ]
then
    echo "STS services still running.  Attempting to delete"
    kubectl patch sts -n $OAANS $OAA_DEPLOYMENT-cache-rest -p '{"spec":{"replicas":0}}' >> $LOG 2>&1
    kubectl patch sts -n $OAANS $OAA_DEPLOYMENT-cache-proxy -p '{"spec":{"replicas":0}}' >> $LOG 2>&1
    kubectl patch sts -n $OAANS $OAA_DEPLOYMENT-cache-storage -p '{"spec":{"replicas":0}}' >> $LOG 2>&1
fi

kubectl get sts -n $OAANS | grep -q cache
if [ $? = 0 ]
then
    echo "STS services still running.  Delete before continuing"
    exit 1
fi

USER=`encode_pwd ${OAM_OAMADMIN_USER}:${OAM_OAMADMIN_PWD}`

ADMIN_URL=http://$K8_WORKER_HOST1:$OAM_ADMIN_K8

echo "Deleting OAuth Client  "
printf "\nDeleting OAuth Client  " >> $LOG
curl --location --request DELETE "$ADMIN_URL/oam/services/rest/ssa/api/v1/oauthpolicyadmin/client?name=OAAClient&identityDomainName=$OAA_DOMAIN"  --header "Authorization: Basic $USER" >> $LOG 2>&1

echo "Deleting OAuth Resource Server"
printf "\nDeleting OAuth Resource Server" >> $LOG
curl --location --request DELETE "$ADMIN_URL/oam/services/rest/ssa/api/v1/oauthpolicyadmin/application?name=OAAResource&identityDomainName=$OAA_DOMAIN" --header "Authorization: Basic $USER" >> $LOG 2>&1

echo "Deleting OAuth Domain"
printf "\nDeleting OAuth Domain" >> $LOG
curl --location --request DELETE "$ADMIN_URL/oam/services/rest/ssa/api/v1/oauthpolicyadmin/oauthidentitydomain?name=$OAA_DOMAIN" \
--header "Authorization: Basic $USER" >> $LOG 2>&1

echo "Deleting Authentication Policy"
printf "\nDeleting Authentication Policy" >> $LOG
delete_auth_policy $LOG

echo "Deleting Authentication Scheme"
printf "\nDeleting Authentication Scheme" >> $LOG
delete_auth_scheme $LOG

if [ $PROGRESS -gt 14 ]
then
   echo "Deleting Schemas"
   delete_schemas >> $LOG 2>&1
fi

echo "Deleting Role Bindings"
kubectl delete rolebinding -n $OAANS oaa-rolebinding >> $LOG 2>&1
echo "Deleting Cluster Role Bindings"
kubectl delete clusterrolebinding oaa-clusterrolebinding >> $LOG 2>&1
kubectl delete clusterrolebinding oaa-clusteradmin >> $LOG 2>&1
echo "Deleting Roles Bindings"
kubectl delete role oaa-ns-role -n $OAANS >> $LOG 2>&1
echo "Deleting Service Account"
kubectl delete serviceaccount -n $OAANS oaa-service-account >> $LOG 2>&1

echo "Deleting Management Pod"
kubectl delete pod -n $OAANS oaa-mgmt >> $LOG 2>&1

echo "Deleting Namespaces"
kubectl delete namespace $OAANS >> $LOG 2>&1

echo  "Deleting Volumes"
rm -rf $LOGDIR/progressfile $WORKDIR/* >> $LOG 2>&1
rm -rf $OAA_LOCAL_CRED_SHARE/* $OAA_LOCAL_CONFIG_SHARE/* $OAA_LOCAL_LOG_SHARE/*  >> $LOG 2>&1
rm -rf $LOGDIR/progressfile $WORKDIR/* $LOCAL_WORKDIR/oaa_installed >> $LOG 2>&1

if [ "$OAA_VAULT_TYPE" = "file" ]
then
    echo "Deleting Vault Filesystem"
    rm -rf  $OAA_LOCAL_VAULT_SHARE/* $OAA_LOCAL_VAULT_SHARE/.??* >> $LOG 2>&1
fi

FINISH_TIME=`date +%s`
print_time TOTAL "Delete OAA " $START_TIME $FINISH_TIME
