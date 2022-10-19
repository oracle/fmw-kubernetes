#!/bin/bash

# Copyright (c) 2020, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

cur_dir=`dirname $(readlink -f "$0")`
. $cur_dir/oamconfig.properties

OAP_SERVICEPORT=30540
SSL_PORT=443
NONSSL_PORT=80
OAP_PORT=5575
LBR_PROTOCOL='https'
WEBLOGIC_TIMEOUT_IN_SEC=600

usage() {
    echo "Usage: "
    echo "$0 <OAM_ADMIN_USER>:<OAM_ADMIN_PASSWORD>"
}

if [ $# -ne 1 ] ; then
   usage
   exit 1
else
	user=$1   
fi   


username=`echo $user | cut -d ":" -f1`
password=`echo $user | cut -d ":" -f2`

domainUID=`kubectl get domains -n $OAM_NAMESPACE | awk '{ print $1 }'| tr  '\n' ':' | cut -d ":"  -f2`
OAM_SERVER=$domainUID'-oam-server'

echo "LBR_PROTOCOL: $LBR_PROTOCOL"
echo "domainUID: $domainUID"
echo "OAM_SERVER: $OAM_SERVER"
echo "OAM_NAMESPACE: $OAM_NAMESPACE"
echo "INGRESS: $INGRESS "
echo "INGRESS_NAME: $INGRESS_NAME"


if [ $INGRESS == "nginx" ]; then
	ING_TYPE=`kubectl --namespace $OAM_NAMESPACE get services $INGRESS_NAME-ingress-nginx-controller -o jsonpath="{.spec.type}"`
else
	 echo "Error: Invalid INGRESS : $INGRESS"		
 exit 1 
fi  

echo "ING_TYPE : $ING_TYPE "

if [ $ING_TYPE == "NodePort" ]; then
	if [ $INGRESS == "nginx" ]; then
	 LBR_PORT=`kubectl --namespace $OAM_NAMESPACE get services -o jsonpath="{.spec.ports[1].nodePort}" $INGRESS_NAME-ingress-nginx-controller`
	else
	 echo "Error: Invalid INGRESS : $INGRESS"	
	 exit 1 
	fi
elif [ $ING_TYPE == "LoadBalancer" ]; then	
	LBR_PORT=$SSL_PORT
else
 echo "Error: Invalid INGRESS TYPE : $ING_TYPE"		
 exit 1 
fi

if [ $ING_TYPE == "LoadBalancer" ]; then
  if [ $INGRESS == "nginx" ]; then	
	LBR_HOST=`kubectl --namespace $OAM_NAMESPACE get service $INGRESS_NAME-ingress-nginx-controller | grep controller | awk '{ print $4 }' | tr -d '\n'`
  else 
    echo "Error: Invalid INGRESS : $INGRESS"	
	exit 1 	
  fi
fi	
echo "LBR_HOST: $LBR_HOST"
echo "LBR_PORT: $LBR_PORT"
echo "Started Executing Command "

line=`curl -x '' -X GET $LBR_PROTOCOL://$LBR_HOST:$LBR_PORT/iam/admin/config/api/v1/config -ikL -H 'Content-Type: application/xml' --user $user | grep ClusterId`

old_cluster_id=`echo $line| cut -d '>' -f2 | cut -d '<' -f1`
shortHostname=`hostname -s`
new_cluster_id=`echo $old_cluster_id | sed "s/localhost/$shortHostname/g"`

echo "new_cluster_id: $new_cluster_id"

mkdir -p $cur_dir/output
cp $cur_dir/clusterCreate_template.py $cur_dir/output/clusterCreate.py

cp $cur_dir/oamconfig_modify_template.xml $cur_dir/output/oamconfig_modify.xml
sed -i -e "s:@OAM_SERVER@:$OAM_SERVER:g" $cur_dir/output/oamconfig_modify.xml
sed -i -e "s:@LBR_HOST@:$LBR_HOST:g" $cur_dir/output/oamconfig_modify.xml
sed -i -e "s:@LBR_PORT@:$LBR_PORT:g" $cur_dir/output/oamconfig_modify.xml
sed -i -e "s:@LBR_PROTOCOL@:$LBR_PROTOCOL:g" $cur_dir/output/oamconfig_modify.xml
sed -i -e "s:@OAP_PORT@:$OAP_PORT:g" $cur_dir/output/oamconfig_modify.xml
sed -i -e "s:@OAP_SERVICEPORT@:$OAP_SERVICEPORT:g" $cur_dir/output/oamconfig_modify.xml

cp $cur_dir/oamoap-service-template.yaml $cur_dir/output/oamoap-service.yaml
sed -i -e "s:@OAM_NAMESPACE@:$OAM_NAMESPACE:g" $cur_dir/output/oamoap-service.yaml
sed -i -e "s:@DOMAINID@:$domainUID:g" $cur_dir/output/oamoap-service.yaml

kubectl create -f $cur_dir/output/oamoap-service.yaml
kubectl get services -n $OAM_NAMESPACE | grep NodePort


sed -i -e "s:@CLUSTER_ID@:$new_cluster_id:g" $cur_dir/output/clusterCreate.py
sed -i -e "s:@USERNAME@:$username:g" $cur_dir/output/clusterCreate.py
sed -i -e "s:@PASSWORD@:$password:g" $cur_dir/output/clusterCreate.py
sed -i -e "s:@DOMAIN_UID@:$domainUID:g" $cur_dir/output/clusterCreate.py

curl -x '' -X PUT $LBR_PROTOCOL://$LBR_HOST:$LBR_PORT/iam/admin/config/api/v1/config -ikL -H 'Content-Type: application/xml' --user $user -H 'cache-control: no-cache' -d @$cur_dir/output/oamconfig_modify.xml
if [ $? -eq 0 ]; then
  echo -e "\n\n $cur_dir/output/oamconfig_modify.xml executed successfully"
  echo "---------------------------------------------------------------------------"    
else
  echo -e "\n\n $cur_dir/output/oamconfig_modify.xml failed to execute"
  exit 1  
fi

# Below code is needed if there is a need to modify ClusterId
kubectl cp $cur_dir/output/clusterCreate.py $OAM_NAMESPACE/$domainUID-adminserver:/tmp/clusterCreate.py
kubectl exec $domainUID-adminserver -n $OAM_NAMESPACE -- chmod +x /tmp/clusterCreate.py
kubectl exec $domainUID-adminserver -n $OAM_NAMESPACE -- wlst.sh /tmp/clusterCreate.py
kubectl exec $domainUID-adminserver -n $OAM_NAMESPACE -- rm -f /tmp/clusterCreate.py

echo -e "\nPlease wait for some time for the server to restart"
kubectl delete pod -l weblogic.clusterName=oam_cluster -n $OAM_NAMESPACE

count_wls_alive=0
while :
do
  if [ $count_wls_alive -ge $WEBLOGIC_TIMEOUT_IN_SEC ]; then
    echo "Error: Time out limit of $WEBLOGIC_TIMEOUT_IN_SEC exceeded for WLS server startup hence exiting."
    exit 1
  fi  

  ret1=`kubectl get po -n $OAM_NAMESPACE | grep ${OAM_SERVER}1`
  ret2=`kubectl get po -n $OAM_NAMESPACE | grep ${OAM_SERVER}2`

  echo $ret1 | grep '1/1'
  rc1=$?
  echo $ret2 | grep '1/1'
  rc2=$?

  if [[ ($rc1 -eq 0) && ($rc2 -eq 0) ]]; then
    echo "OAM servers started successfully"
    break
  else
    count_wls_alive=$((count_wls_alive+10))
    sleep 10
    echo "Waiting continuously at an interval of 10 secs for servers to start.."
    continue
  fi  
done

