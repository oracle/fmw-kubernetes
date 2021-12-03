#!/usr/bin/env bash
# Copyright (c) 2020, Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

myServiceLB=$1
nameSpace=$2
while true; do
    successCond="$(kubectl -n "$nameSpace" get svc "$myServiceLB" \
        --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")"
    if [[ -z "$successCond" ]]; then
        echo "Waiting for endpoint readiness..."
        sleep 10
    else
        sleep 2
        export lbIngAdd="$successCond"
        echo " The Internal LoadBalancer is up! "
        break
    fi
done
