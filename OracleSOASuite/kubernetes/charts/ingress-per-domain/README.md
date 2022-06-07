# An Ingress per domain chart
This chart is for deploying an Ingress resource in front of an Oracle SOA Suite domain cluster. We support three Ingress types: Traeafik and Nginx.

## Prerequisites
- Have Docker and a Kubernetes cluster running and have `kubectl` installed and configured.
- Have Helm installed.
- The corresponding Ingress controller, [Traefik](https://github.com/oracle/weblogic-kubernetes-operator/tree/main/kubernetes/samples/charts/traefik), is installed in the Kubernetes cluster.
- An Oracle SOA Suite domain cluster deployed by `weblogic-operator` is running in the Kubernetes cluster.
- For Secured access (SSL) to the SOA applications enable `WebLogic plugin`.

## Install Nginx (kubernetes/ingress-nginx) Ingress Controller.
   
   ```bash
   $ helm install  nginx-ingress -n soans stable/nginx-ingress
   ```
## Installing the chart

To install the chart with the release name, `soa-traefik-ingress` or `soa-nginx-ingress`, with the given `values.yaml`:
```
# Change directory to the cloned git Oracle SOA Suite Kubernetes deployment scripts repo.
$ cd $WORKDIR

# Use helm to install the chart.  Use `--namespace` to specify the name of the Soa domain's namespace.

# Using Helm 3.x:
# Traefik:
$ helm install soa-traefik-ingress  charts/ingress-per-domain --namespace soans --values charts/ingress-per-domain/values.yaml --set "traefik.hostname=$(hostname -f)"  

#NGINX
$ helm install soa-nginx-ingress  charts/ingress-per-domain --namespace soans --values charts/ingress-per-domain/values.yaml --set "nginx.hostname=$(hostname -f)"

```
NOTE: Ingress per domain installing using helm command uses the values from `values.yml` available at `charts/ingress-per-domain/values.yaml`. This values.yaml contains the default values
The inputs provided in the helm install command will overwrite these default values.
> In the value.yaml the default values are: type: "TRAEFIK" , sslType: "NONSSL" and domainType: "soa".  
> If you want to use other than these default values then,  
>      1. Either modify the value.yaml file with the required values or  
>      2. Pass the required values through the helm command line.  
>
> For Example : For installing Nginx ingress with SSL Configuration pass "type=NGINX" and "sslType=SSL" on command line.  
> $ helm install soa-nginx-ingress charts/ingress-per-domain  --namespace soans --values charts/ingress-per-domain/values.yaml  --set "nginx.hostname=$(hostname -f)"  --set type=NGINX --set sslType=SSL  


The Ingress resource will be created in the same namespace as the SOA domain cluster.

## Generate Secret to access  SSL services

Command to Generate Secret: 
```
$ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls1.key -out /tmp/tls1.crt -subj "/CN=*"
$ kubectl -n soans create secret tls soainfra-tls-cert --key /tmp/tls1.key --cert /tmp/tls1.crt

```

Sample `values.yaml` for the Traefik and Nginx Ingress:
```
# Load balancer type.  Supported values are: TRAEFIK
# For Type NGINX Uncomment type NGINX and Comment type TRAEFIK
type: TRAEFIK
#type: NGINX

# Type of Configuration Supported Values are : NONSSL,SSL and E2ESSL
sslType: NONSSL
#sslType: SSL
#sslType: E2ESSL

# domainType Supported values are soa,osb and soaosb
# Uncomment only one domainType below and comment others based on the domain type of SOA Suite domain. Default domainType is 'soa'.
 domainType: soa
#domainType: osb
#domainType: soaosb

# WLS domain as backend to the load balancer
wlsDomain:
  domainUID: soainfra
  adminServerName: AdminServer
  adminServerPort: 7001
  adminServerSSLPort: 7002
  soaClusterName: soa_cluster
  soaManagedServerPort: 8001
  soaManagedServerSSLPort: 8002
  osbClusterName: osb_cluster
  osbManagedServerPort: 9001
  osbManagedServerSSLPort: 9002

# Host Specific Values
hostName:
  admin: admin.org
  soa: soa.org
  osb: osb.org

```
## Uninstalling the chart
To uninstall and delete the `my-ingress` deployment:
```
$ helm delete --purge <soa-traefik-ingress or soa-nginx-ingress >
```
## Configuration
The following table lists the configurable parameters of this chart and their default values.

| Parameter | Description | Default |
| --- | --- | --- |
| `type` | Type of Ingress controller. Legal values are `TRAEFIK` or `NGINX`. | `TRAEFIK` |
| `sslType` | Type of Configuration. values are `NONSSL` , `SSL` and `E2ESSL`. | `NONSSL` |
| `domainType` | Type of SOA Domain. values are `soa` or `osb` or`soaosb`. | `soa` |
| `hostName.admin` | Admin host name. | `admin.org` |
| `hostName.soa` | Soa host name. | `soa.org` |
| `hostName.osb` | Osb host name. | `osb.org` |
| `wlsDomain.domainUID` | DomainUID of the Soa domain. | `soainfra` |
| `wlsDomain.soaClusterName` | Cluster name in the SOA domain. | `soa_cluster` |
| `wlsDomain.osbClusterName` | Cluster name in the OSB domain. | `osb_cluster` |
| `wlsDomain.adminServerPort` | Port number of the Admin servers in the Soa domain cluster . | `7001` |
| `wlsDomain.adminServerSSLPort` | Port number of the Admin servers in the Soa domain cluster . | `7002` |
| `wlsDomain.soaManagedServerPort` | Port number of the managed servers in the Soa domain cluster. | `8001` |
| `wlsDomain.soaManagedServerSSLPort` | SSL Port number of the managed servers in the Soa domain cluster. | `8002` |
| `wlsDomain.osbManagedServerPort` | Port number of the managed servers in the Soa domain cluster. | `9001` |
| `wlsDomain.osbManagedServerSSLPort` | Port number of the managed servers in the Soa domain cluster. | `9002` |

>**NOTE:** The input values `domainUID` and `clusterName` will be used to generate the Kubernetes `serviceName` of the WLS cluster with the format `domainUID-cluster-clusterName`.
