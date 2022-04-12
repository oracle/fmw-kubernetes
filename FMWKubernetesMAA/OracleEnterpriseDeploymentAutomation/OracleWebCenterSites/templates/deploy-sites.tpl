## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl


helm install ${sites_domain_name} ./charts/wc-sites \
    -f fromtf.auto.yaml \
    --namespace ${sites_namespace} \
    --version 0.1.0 \
    --wait  \
    --timeout 600s || exit 1

echo "Sites Domain is installed, please wait for all pods to be READY"
