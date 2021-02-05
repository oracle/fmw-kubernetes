---
title: "Uninstall"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 5
pre : "<b>5. </b>"
description: "Clean up the Oracle WebCenter Sites domain setup."
---

Learn how to clean up the Oracle WebCenter Sites domain setup.

#### Stop all Administration and Managed server pods

First stop the all pods related to a domain. This can be done by patching domain "serverStartPolicy" to "NEVER". Here is the sample command for the same.

```bash
$ kubectl patch domain wcsites-domain-name -n wcsites-namespace --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "NEVER" }]'
```
For example:
```bash
$ kubectl patch domain wcsitesinfra -n wcsites-ns --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "NEVER" }]'
```

#### Drop the RCU schemas

```bash
$ cd work-dir-name/weblogic-kubernetes-operator
$ kubectl apply -f kubernetes/samples/scripts/create-wcsites-domain/output/weblogic-domains/wcsitesinfra/delete-domain-job.yaml
```

Check if the job has finished.


#### Remove the domain

1.	Remove the domain's ingress (for example, Traefik ingress) using Helm:

    ```bash
    $ helm uninstall wcsites-domain-ingress -n wcsites-namespace
    ```
    For example:
    ```bash
    $ helm uninstall wcsitesinfra-ingress -n wsites-ns
    ```


1.	Remove the domain resources by using the sample `delete-weblogic-domain-resources.sh` script present at `${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/delete-domain`:

    ```bash
	$ cd ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/delete-domain
    $ ./delete-weblogic-domain-resources.sh -d sample-domain1
    ```
    For example:
    ```bash
	$ cd ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/delete-domain
    $ ./delete-weblogic-domain-resources.sh -d wcsites-ns
    ```

1.	Use `kubectl` to confirm that the server pods and domain resource are deleted:

    ```bash
    $ kubectl get pods -n sample-domain1-ns
    $ kubectl get domains -n sample-domain1-ns
    ```
    For example:
    ```bash
    $ kubectl get pods -n wcsites-ns
    $ kubectl get domains -n wcsites-ns
    ```


#### Remove the domain namespace

1.	Configure the installed ingress load balancer (for example, Traefik) to stop managing the ingresses in the domain namespace:

    ```bash
    $ helm upgrade traefik-operator stable/traefik \
        --namespace traefik \
        --reuse-values \
        --set "kubernetes.namespaces={traefik}" \
        --wait
    ```

1.	Configure the operator to stop managing the domain:

    ```bash
    $ helm upgrade  sample-weblogic-operator \
      kubernetes/charts/weblogic-operator \
      --namespace sample-weblogic-operator-ns \
      --reuse-values \
      --set "domainNamespaces={}" \
      --wait \
    ```
    For example:
    ```bash
	$ cd ${WORKDIR}/weblogic-kubernetes-operator
    $ helm upgrade weblogic-kubernetes-operator \
      kubernetes/charts/weblogic-operator \
      --namespace operator-ns \
      --reuse-values \
      --set "domainNamespaces={}" \
      --wait \
    ```
1.	Delete the domain namespace:

    ```bash
    $ kubectl delete namespace sample-domain1-ns
    ```
    For example:
    ```bash
    $ kubectl delete namespace wcsites-ns
    ```

#### Remove the operator

1.	Remove the operator:

    ```bash
    $ helm uninstall sample-weblogic-operator -n sample-weblogic-operator-ns
    ```
    For example:
    ```bash
    $ helm uninstall weblogic-kubernetes-operator -n operator-ns
    ```

1.	Remove the operator's namespace:

    ```bash
    $ kubectl delete namespace sample-weblogic-operator-ns
    ```
    For example:
    ```bash
    $ kubectl delete namespace operator-ns
    ```

#### Remove the load balancer

1.	Remove the installed ingress based load balancer (for example, Traefik):

    ```bash
    $ helm uninstall traefik-operator -n traefik
    ```

1.	Remove the Traefik namespace:

    ```bash
    $ kubectl delete namespace traefik
    ```

#### Delete the domain home

To remove the domain home that is generated using the `create-domain.sh` script, with appropriate privileges manually delete the contents of the storage attached to the domain home persistent volume (PV).

For example, for the domain's persistent volume of type `host_path`:
```
$ rm -rf /scratch/K8SVolume/WCSites
```
