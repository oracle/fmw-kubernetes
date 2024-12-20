#!/bin/bash
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Create (Domain and Database) namespace and label the Domain namespace for WebLogic Kubernetes Operator manage

NS=$1
DBNS=$2
${KUBERNETES_CLI:-kubectl} get namespace $NS  2> /dev/null
exit_status=$?

if [ $exit_status -eq 0 ]; then
  echo "Namespace $NS Already exists"
else
  echo "Missing Namespace $NS creating now"
  ${KUBERNETES_CLI:-kubectl}  create namespace $NS
fi
${KUBERNETES_CLI:-kubectl} label namespace $NS "weblogic-operator=enabled"  2> /dev/null

if [ $DBNS != "None" ]; then
   ${KUBERNETES_CLI:-kubectl} get namespace $DBNS  2> /dev/null
   exit_status=$?

   if [ $exit_status -eq 0 ]; then
     echo "Namespace $DBNS Already exists"
   else
     echo "Missing Namespace $DBNS creating now"
     ${KUBERNETES_CLI:-kubectl}  create namespace $DBNS
   fi
fi
sleep 10
