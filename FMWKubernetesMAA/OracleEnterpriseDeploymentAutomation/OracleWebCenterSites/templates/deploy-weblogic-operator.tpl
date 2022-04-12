## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

if [[ ! $(kubectl get serviceaccount weblogic-operator -n ${weblogic_operator_namespace}) ]]; then
  kubectl create serviceaccount -n ${weblogic_operator_namespace} weblogic-operator;
fi

# wait for at least 1 node to be ready

while [[ $(for i in $(kubectl get nodes -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}'); do if [[ "$i" == "True" ]]; then echo $i; fi; done | wc -l | tr -d " ") -lt 1 ]]; do
    echo "waiting for at least 1 node to be ready..." && sleep 1;
done

CHART_VERSION=3.1.4

helm repo add weblogic-operator https://oracle.github.io/weblogic-kubernetes-operator/charts --force-update

helm install weblogic-operator weblogic-operator/weblogic-operator \
  --version $CHART_VERSION \
  --namespace ${weblogic_operator_namespace} \
  --set image=ghcr.io/oracle/weblogic-kubernetes-operator:$CHART_VERSION \
  --set serviceAccount=weblogic-operator \
  --set "domainNamespaces={${sites_namespace}}" \
  --wait \
  --timeout 600s || exit 1

while [[ ! $(kubectl get customresourcedefinition domains.weblogic.oracle -n ${weblogic_operator_namespace}) ]]; do
  echo "Waiting for CRD to be created";
  sleep 1;
done

echo "WebLogic Operator is installed and running"
