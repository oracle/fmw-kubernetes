#!/bin/bash
# Copyright (c) 2020, Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

serverName=$1
ns=$2
maxtries=$3
wait=$4
cnt=1; 
while [[ $(kubectl -n $ns get pods -l weblogic.serverName=$serverName -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]];
do 
	echo "waiting for $serverName Server pod; Try count $((cnt++))/$maxtries" && sleep $wait
	if [ $cnt -gt $maxtries ]
	then
		break
	fi
done
