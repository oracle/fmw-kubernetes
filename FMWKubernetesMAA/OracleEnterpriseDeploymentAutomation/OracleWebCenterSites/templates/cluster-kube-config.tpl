## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

mkdir -p $HOME/.kube/ 
oci ce cluster create-kubeconfig --cluster-id ${cluster_id} --file $HOME/.kube/config --region ${region} --token-version 2.0.0
