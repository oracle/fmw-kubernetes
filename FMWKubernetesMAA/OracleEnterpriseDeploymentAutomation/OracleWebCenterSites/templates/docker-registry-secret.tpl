## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
if [[ ! $(kubectl get secret image-secret -n ${namespace}) ]]; then
    kubectl create secret docker-registry image-secret -n ${namespace} --docker-server='${repository}' --docker-username='${username}' --docker-password='${password}'
fi

