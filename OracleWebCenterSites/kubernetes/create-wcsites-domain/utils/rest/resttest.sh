#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl


KUBERNETES_SERVER=${KUBERNETES_SERVER_HOSTNAME}
URL_TAIL=operator/latest/domains/wcsitesinfra/clusters/wcsites_cluster/scale


REST_PORT=`kubectl get services -n operator-ns -o jsonpath='{.items[?(@.metadata.name == "external-weblogic-operator-svc")].spec.ports[?(@.name == "rest")].nodePort}'`
REST_ADDR="https://${KUBERNETES_SERVER}:${REST_PORT}"
SECRET=`kubectl get serviceaccount operator-sa -n operator-ns -o jsonpath='{.secrets[0].name}'`
ENCODED_TOKEN=`kubectl get secret ${SECRET} -n operator-ns -o jsonpath='{.data.token}'`
TOKEN=`echo ${ENCODED_TOKEN} | base64 --decode`
OPERATOR_CERT_DATA=`kubectl get secret -n operator-ns weblogic-operator-identity -o jsonpath='{.data.tls\.crt}'`
OPERATOR_CERT_FILE="/tmp/operator.cert.pem"
echo ${OPERATOR_CERT_DATA} | base64 --decode > ${OPERATOR_CERT_FILE}
cat ${OPERATOR_CERT_FILE}

echo "Ready to call operator REST APIs"


STATUS_CODE=`curl \
  -v \
  -k \
  -H "X-Requested-By:MyClient" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H Accept:application/json \
  -H Content-Type:application/json \
  -X POST ${REST_ADDR}/${URL_TAIL} \
  -d '{ "managedServerCount": 1 }' \
  -o curl.out \
  --stderr curl.err \
  -w "%{http_code}"`

cat curl.err
cat curl.out | jq .
