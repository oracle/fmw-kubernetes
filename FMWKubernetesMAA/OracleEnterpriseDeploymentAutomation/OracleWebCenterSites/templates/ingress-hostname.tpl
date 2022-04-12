## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

value=$(kubectl get svc traefik -n ${ingress_namespace} -o jsonpath="{.status.loadBalancer.ingress[*].ip}")
hostname='  hostname: "'$value'"'
echo "$hostname"

line=$(grep -n 'hostname:' ./fromtf.auto.yaml | cut -d ':' -f1)

sed -i "$line s/.*/$hostname/" ./fromtf.auto.yaml
echo "updated ingress hostname on fromtf.auto.yaml file"

