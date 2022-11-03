---
title: "Uninstall"
date: 2021-02-15T15:44:42-05:00
draft: false
weight: 6
pre : "<b>6. </b>"
description: "Clean up the Oracle WebCenter Content domain setup."
---

Learn how to clean up the Oracle WebCenter Content domain setup.

#### Stop all Administration and Managed server pods

First stop the all pods related to a domain. This can be done by patching domain "serverStartPolicy" to "NEVER". Here is the sample command for the same.

```bash
$ kubectl patch domain wcc-domain-name -n wcc-namespace --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "NEVER" }]'
```
For example:
```bash
kubectl patch domain wccinfra -n wccns --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "NEVER" }]'
```

#### Remove the domain

1.	Remove the domain's ingress (for example, Traefik ingress) using Helm:

    ```bash
    $ helm uninstall wcc-domain-ingress -n sample-domain1-ns
    ```
    For example:
    ```bash
    $ helm uninstall wccinfra-traefik -n wccns
    ```


1.	Remove the domain resources by using the sample `delete-weblogic-domain-resources.sh` script present at `${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/delete-domain`:

    ```bash
	$ cd ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/delete-domain
    $ ./delete-weblogic-domain-resources.sh -d sample-domain1
    ```
    For example:
    ```bash
	$ cd ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/delete-domain
    $ ./delete-weblogic-domain-resources.sh -d wccinfra
    ```

1.	Use `kubectl` to confirm that the server pods and domain resource are deleted:

    ```bash
    $ kubectl get pods -n sample-domain1-ns
    $ kubectl get domains -n sample-domain1-ns
    ```
    For example:
    ```bash
    $ kubectl get pods -n wccns
    $ kubectl get domains -n wccns
    ```

#### Drop the RCU schemas

Follow [these steps]({{< relref "/wccontent-domains/installguide/prepare-your-environment/#create-or-drop-schemas" >}})
to drop the RCU schemas created for Oracle WebCenter Content domain.

#### Remove the domain namespace

1.	Configure the installed ingress load balancer (for example, Traefik) to stop managing the ingresses in the domain namespace:

    ```bash
    $ helm upgrade traefik-operator traefik/traefik \
        --namespace traefik \
        --reuse-values \
        --set "kubernetes.namespaces={traefik}" \
        --wait
    ```

1.	Configure the WebLogic Kubernetes Operator to stop managing the domain:

    ```bash
    $ helm upgrade  sample-weblogic-operator \
      kubernetes/charts/weblogic-operator \
      --namespace sample-weblogic-operator-ns \
      --reuse-values \
      --set "domainNamespaces={}" \
      --wait
    ```
    For example:
    ```bash
	$ cd ${WORKDIR}/weblogic-kubernetes-operator
    $ helm upgrade weblogic-kubernetes-operator \
      kubernetes/charts/weblogic-operator \
      --namespace opns \
      --reuse-values \
      --set "domainNamespaces={}" \
      --wait
    ```
1.	Delete the domain namespace:

    ```bash
    $ kubectl delete namespace sample-domain1-ns
    ```
    For example:
    ```bash
    $ kubectl delete namespace wccns
    ```

#### Remove the WebLogic Kubernetes Operator

1.	Remove the WebLogic Kubernetes Operator:

    ```bash
    $ helm uninstall sample-weblogic-operator -n sample-weblogic-operator-ns
    ```
    For example:
    ```bash
    $ helm uninstall weblogic-kubernetes-operator -n opns
    ```

1.	Remove WebLogic Kubernetes Operator's namespace:

    ```bash
    $ kubectl delete namespace sample-weblogic-operator-ns
    ```
    For example:
    ```bash
    $ kubectl delete namespace opns
    ```

#### Remove the load balancer

1.	Remove the installed ingress based load balancer (for example, Traefik):

    ```bash
    $ helm uninstall traefik -n traefik
    ```

1.	Remove the Traefik namespace:

    ```bash
    $ kubectl delete namespace traefik
    ```

#### Delete the domain home

To remove the domain home that is generated using the `create-domain.sh` script, with appropriate privileges manually delete the contents of the storage attached to the domain home persistent volume (PV).

For example, for the domain's persistent volume of type `host_path`:
```
$ rm -rf /scratch/k8s_dir/WCC
```
