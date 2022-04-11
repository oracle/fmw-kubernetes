## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

if [[ ! $(kubectl get secret ${name} -n ${namespace}) ]]; then
    kubectl create secret generic ${name} -n ${namespace} \
        --from-literal=username=${username} \
        --from-literal=password='${password}'
fi