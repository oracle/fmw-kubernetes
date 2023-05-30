## Copyright (c) 2022, 2023, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

if [[ ! $(kubectl get ns ${namespace}) ]]; then
    kubectl create namespace ${namespace};
	kubectl label namespace ${namespace} weblogic-operator=enabled;
fi