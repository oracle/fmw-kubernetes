# An Ingress per domain chart
This chart is for deploying an Ingress resource in front of a WebLogic domain cluster. We support two Ingress types: NGINX and Voyager.

## Prerequisites
- Have Docker and a Kubernetes cluster running and have `kubectl` installed and configured.
- Have Helm installed.
- The corresponding Ingress controller, NGINX or Voyager, is installed in the Kubernetes cluster.
- A WebLogic domain cluster deployed by `weblogic-operator` is running in the Kubernetes cluster.

## Installing the chart

To install the chart with the release name, `my-ingress`, with the given `values.yaml`:
```
# Change directory to the cloned git weblogic-kubernetes-operator repo.
$ cd kubernetes/samples/charts

# Use helm to install the chart.  Use `--namespace` to specify the name of the WebLogic domain's namespace.
$ helm install ingress-per-domain --name my-ingress --namespace my-domain-namespace --values values.yaml
```
The Ingress resource will be created in the same namespace as the WebLogic domain cluster.

Sample `values.yaml` for the NGINX Ingress:
```
type: NGINX

# Oracle WebLogic Server domain as backend to the load balancer
wlsDomain:
  domainUID: oimcluster
  oimClusterName: oim_cluster
  soaClusterName: soa_cluster
  soaManagedServerPort: 8001
  oimManagedServerPort: 14000
  adminServerName: adminserver
  adminServerPort: 7001
```

Sample `values.yaml` for the Voyager Ingress:
```
type: VOYAGER

# Oracle WebLogic Server domain as backend to the load balancer
wlsDomain:
  domainUID: oimcluster
  oimClusterName: oim_cluster
  soaClusterName: soa_cluster
  soaManagedServerPort: 8001
  oimManagedServerPort: 14000
  adminServerName: adminserver
  adminServerPort: 7001

# Voyager specific values
voyager:
  # web port
  webPort: 30305
  # stats port
  statsPort: 30315
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
| `type` | Type of Ingress controller. Legal values are `NGINX` or `VOYAGER`. | `VOYAGER` |
| `wlsDomain.domainUID` | DomainUID of the Oracle WebLogic Server domain. | `oimcluster` |
| `wlsDomain.oimClusterName` | OIM Cluster name in the Oracle WebLogic Server domain. | `oim_cluster` |
| `wlsDomain.soaClusterName` | SOA Cluster name in the Oracle WebLogic Server domain. | `soa_cluster` |
| `wlsDomain.soaManagedServerPort` | Port number of the SOA managed server in the SOA cluster. | `8001` |
| `wlsDomain.oimManagedServerPort` | Port number of the OIM managed server in the OIM cluster. | `14000` |
| `wlsDomain.adminServerName` | Port number of the admin server in the Oracle WebLogic Server domain cluster. | `adminserver` |
| `wlsDomain.adminServerPort` | Port number of the admin server in the Oracle WebLogic Server domain cluster. | `7001` |
| `voyager.webPort` | Web port to access the Voyager load balancer. | `30305` |
| `voyager.statsPort` | Port to access the Voyager/HAProxy stats page. | `30315` |

**Note:** The input values `domainUID` and `clusterName` will be used to generate the Kubernetes `serviceName` of the Oracle WebLogic Server cluster with the format `domainUID-cluster-clusterName`.
