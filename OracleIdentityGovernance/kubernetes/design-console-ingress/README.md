# An Ingress per domain chart
This chart is for deploying an Ingress resource in front of a WebLogic domain cluster for using Oracle Identity Governance Design Console. We support the Ingress type: NGINX .

## Prerequisites
- Have Docker and a Kubernetes cluster running and have `kubectl` installed and configured.
- Have Helm installed.
- The corresponding Ingress controller, NGINX, is installed in the Kubernetes cluster.
- A WebLogic domain cluster deployed by `weblogic-operator` is running in the Kubernetes cluster.

## Installing the chart

To install the chart with the release name, `my-ingress`, with the given `values.yaml`:
```
# Change directory to the cloned git weblogic-kubernetes-operator repo.
$ cd kubernetes/samples/charts

# Use helm to install the chart.  Use `--namespace` to specify the name of the WebLogic domain's namespace.
$ helm install design-conosle-ingress --name my-ingress --namespace my-domain-namespace --values values.yaml
```
The Ingress resource will be created in the same namespace as the WebLogic domain cluster.

Sample `values.yaml` for the NGINX Ingress:
```
type: NGINX
# Type of Configuration Supported Values are : NONSSL,SSL
# tls: NONSSL
tls: NONSSL
# TLS secret name if the mode is SSL
secretName: dc-tls-cert


# WLS domain as backend to the load balancer
wlsDomain:
  domainUID: oimcluster
  oimClusterName: oim_cluster
  oimServerT3Port: 14002
```

## Uninstalling the chart
To uninstall and delete the `my-ingress` deployment:
```
$ helm delete my-ingress
```
## Configuration
The following table lists the configurable parameters of this chart and their default values.

| Parameter | Description | Default |
| --- | --- | --- |
| `type` | Type of Ingress controller. Legal value is `NGINX` . | `NGINX` |
| `tls` | Mode of Ingress controller. Legal values are `NONSSL` or `SSL`. | `NONSSL` |
| `secretName` | TLS secret name if the mode is `SSL` | `dc-tls-cert` |
| `wlsDomain.domainUID` | DomainUID of the Oracle WebLogic Server domain. | `domain1` |
| `wlsDomain.oimClusterName` | OIM Cluster name in the Oracle WebLogic Server domain. | `cluster-1` |
| `wlsDomain.oimServerT3Port` | T3 Port number of the oim managed servers in the Oracle WebLogic Server domain cluster. | `14002` |

**Note:** The input values `domainUID` and `clusterName` will be used to generate the Kubernetes `serviceName` of the Oracle WebLogic Server cluster with the format `domainUID-cluster-clusterName`.
