---
title: "Uninstall"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 6
pre : "<b>6. </b>"
description: "Clean up the Oracle SOA Suite domain setup."
---

Learn how to clean up the Oracle SOA Suite domain setup.

#### Remove the domain

1.	Remove the domain's ingress (for example, Traefik ingress) using Helm:

    ```bash
    $ helm uninstall soa-domain-ingress -n sample-domain1-ns
    ```
    For example:
    ```bash
    $ helm uninstall soainfra-traefik -n soans
    ```


1.	Remove the domain resources by using the sample `delete-weblogic-domain-resources.sh` script present at `${WORKDIR}/delete-domain`:

    ```bash
	$ cd ${WORKDIR}/delete-domain
    $ ./delete-weblogic-domain-resources.sh -d sample-domain1
    ```
    For example:
    ```bash
	$ cd ${WORKDIR}/delete-domain
    $ ./delete-weblogic-domain-resources.sh -d soainfra
    ```

1.	Use `kubectl` to confirm that the server pods and domain resource are deleted:

    ```bash
    $ kubectl get pods -n sample-domain1-ns
    $ kubectl get domains -n sample-domain1-ns
    ```
    For example:
    ```bash
    $ kubectl get pods -n soans
    $ kubectl get domains -n soans
    ```

#### Drop the RCU schemas

Follow [these steps]({{< relref "/soa-domains/installguide/prepare-your-environment/#drop-schemas" >}}) to drop the RCU schemas created for Oracle SOA Suite domains.

#### Remove the domain namespace

1.	Configure the installed ingress load balancer (for example, Traefik) to stop managing the ingresses in the domain namespace:

    ```bash
    $ helm upgrade traefik traefik/traefik \
        --namespace traefik \
        --reuse-values \
        --set "kubernetes.namespaces={traefik}" \
        --wait
    ```

1.	Configure the operator to stop managing the domain:

    ```bash
    $ helm upgrade  sample-weblogic-operator \
      charts/weblogic-operator \
      --namespace sample-weblogic-operator-ns \
      --reuse-values \
      --set "domainNamespaces={}" \
      --wait
    ```
    For example:
    ```bash
	$ cd ${WORKDIR}
    $ helm upgrade weblogic-kubernetes-operator \
      charts/weblogic-operator \
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
    $ kubectl delete namespace soans
    ```

#### Remove the operator

1.	Remove the operator:

    ```bash
    $ helm uninstall sample-weblogic-operator -n sample-weblogic-operator-ns
    ```
    For example:
    ```bash
    $ helm uninstall weblogic-kubernetes-operator -n opns
    ```

1.	Remove the operator's namespace:

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
$ rm -rf /scratch/k8s_dir/SOA/*
```
