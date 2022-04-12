## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

helm upgrade ${sites_domain_name} ./charts/wc-sites -n ${sites_namespace} \
    --reuse-values \
    --set domain.enabled=false \
    --wait

helm delete ${sites_domain_name} -n ${sites_namespace}
