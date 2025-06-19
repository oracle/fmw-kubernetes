# Deploy Oracle SOA Suite on Kubernetes with the WebLogic Operator

The Helm chart to deploy Oracle SOA Suite on Kubernetes. This chart also has sub-chart for deploying Oracle Single Instance Database.


## 1. Mandatory Prerequisites

To deploy this chart, you will need:

- An Oracle Container Registry account created through the Oracle Single Sign-On portal.
- Acknowledge terms of use for the Oracle SOA Suite Docker image on the Oracle Container Registry.
- Acknowledge terms of use for the Oracle Database Docker image on the Oracle Container Registry to deploy the test Oracle database in your cluster (NOT for production).
- A Network File Server (NFS) and mount point accessible from within your cluster.

### 1.1 Oracle Container Registry

You will need an Oracle Container Registry account created through the Oracle Single Sign-On portal [https://profile.oracle.com/myprofile/account/create-account.jspx](https://profile.oracle.com/myprofile/account/create-account.jspx).

Log in with your Oracle account credentials or create a new account, and agree to the terms of use for the images you need to use:

### 1.2 Oracle SOA Suite Docker Image

The chart uses the Oracle SOA Suite Docker image from the Oracle Container Registry. This is a mandatory requirement.

You must accept the terms of use for this image before using the chart, or it will fail to pull the image from registry.

- At [https://container-registry.oracle.com](https://container-registry.oracle.com), search for 'SOA'.
- Click **soasuite**.
- Click to accept the License terms and condition on the right.
- Fill in your information (if you haven't already).
- Accept the License.

### 1.3 Oracle Database Docker Image

You may provision the database supporting the Oracle SOA suite domain schemas separately, and point the chart to it by providing the database url. The database must be accessible from the Kubernetes cluster. 

If you intend on deploying the database within the Kubernetes cluster, you must agree to the terms of the Oracle database Docker image:

- Search for Database.
- Click **Enterprise**.
- Click to accept the License terms and condition on the right.
- Fill in your information (if you haven't already).
- Accept the License.


## 2. Other Prerequisites

### 2.1 Create a Secret with your Oracle Container Registry Credentials

In this document, we will be deploying everything in the `soans` namespace. Change the namespace name according to your needs.

We're creating a docker registry login credential secret named `image-secret`

```bash
kubectl -n soans create secret docker-registry image-secret \
--docker-server=container-registry.oracle.com \
--docker-username=<Oracle Container Registry login email> \
--docker-password=<Oracle Container Registry login password> \
--docker-email=<Oracle Container Registry login email>
```

### 2.2 Network File System (NFS Server)

You must have provisioned a Network File Storage (NFS) server and mount point before deploying this chart.

The chart requires the IP address of the NFS server and the path for the mount point.

### 2.3 Provision Chart Dependencies

This SOA Suite Helm chart has dependencies on the WebLogic Kubernetes Operator, and Oracle Database. To access the application URLs you need to install the ingress controller and the corresponding ingresses.

- The WebLogic Kubernetes Operator chart needs to be installed prior to installing this chart. It is installed once to deploy any number of WebLogic or SOA domains. This version requires WebLogic Operator v4.1.2 or greater.

- The Oracle Database can be provisioned separately and connection URL details can be provided to chart. This chart can also provision an Oracle Single Insatnce Database. But before that we need to install the Oracle Database Operator. To provision within your cluster as a pod as part of this chart you need to enable the flag `oracledb.provision` and providing the necessary parameters.

#### 2.3.1 Create a Namespace for the SOA Suite Domain

1. Create a namespace for the SOA Suite domain:

```bash
kubectl create namespace soans
```

Note: We create the SOA Suite deployment namespace prior to installing the other charts, so we can pass this name to the dependent charts. If you don't know the namespace or might create it later, you will need to update the dependent charts with the namespace name after it is created.

#### 2.3.2 Provision the WebLogic Kubernetes Operator

1. Create a namespace for the WebLogic Kubernetes Operator:

    ```bash
    kubectl create namespace weblogic-operator
    ```

1. Create a service account for the WebLogic Kubernetes Operator:

    ```bash
    kubectl create serviceaccount -n weblogic-operator weblogic-operator
    ```

1. Add the weblogic-kubernetes-operator repository to your Helm repositories:

    ```bash
    helm repo add weblogic-operator https://oracle.github.io/weblogic-kubernetes-operator/charts --force-update
    ```

1. Install the Helm chart:

    In this example we're installing the chart in the `weblogic-operator` namespace created above.

    ```bash
    helm install weblogic-operator \
    weblogic-operator/weblogic-operator \
    --version 4.1.2 \
    --namespace weblogic-operator \
    --set image=ghcr.io/oracle/weblogic-kubernetes-operator:3.4.0 \
    --set serviceAccount=weblogic-operator \
    --wait
    ```

#### 2.3.3 Provision the Traefik Ingress Controller

1. Create a namespace for Traefik

    ```bash
    kubectl create namespace traefik
    ```

1. Add the Traefik Helm repository to the known repositories

    ```bash
    helm repo add traefik https://helm.traefik.io/traefik
    ```

1. Install the Traefik Helm chart:

    ```bash
    helm install traefik-operator \
    traefik/traefik \
    --version 10.19.5 \
    --namespace traefik \
    --set image.tag=2.6.6 \
    --set ports.traefik.expose=true \
    --set ports.web.exposedPort=30305 \
    --set ports.web.nodePort=30305 \
    --set ports.websecure.exposedPort=30443 \
    --set ports.websecure.nodePort=30443 \
    --set "kubernetes.namespaces={traefik,soans}" \
    --wait
    ```

    Note: Use the additional option `--set service.type=NodePort` when deploying on a cluster without a load balancer service.

    Note: Here again we pass the `soans` namespace created earlier to the ingress controller chart. If the namespace is created later, update the traefik chart with:

    ```bash
    helm upgrade traefik-operator \
    traefik/traefik \
    --namespace traefik \
    --reuse-values \
    --set "kubernetes.namespaces={traefik,soans}" \
    --wait
    ```

## 3. Usage

### 3.1 Credentials

We're providing examples passing username and passwords as Helm chart values, but we recommend using secrets to store these credentials.

To create the secrets, use:

```bash
kubectl create secret generic ${name} -n ${namespace} \
        --from-literal=username=${username} \
        --from-literal=password='${password}'
```

Then pass the name of the secret as `secretName` when `credentials` are required (i.e. `domain.credentials.secretName`, `domain.rcuSchema.credentials.secretName`, and `oracledb.credentials.secretName`)

### 3.1 Install the SOA Suite Helm Chart

1. Add this repository to your list of known repositories

    ```bash
    helm repo add oracle https://oracle.github.io/helm-charts --force-update
    ```

1. To install the chart, you need to specify a few variables, including:

    - The name of the secret to access the Oracle Container Registry account.
    - The `domain.domainName`: name of the domain to create.
    - The `domain.type`: type of SOA domain. Possible values are: `soa`, `soaosb`, `soaess`, `soaessosb`
    - The `domain.credentials.username` and `domain.credentials.password`: username and password for the Admin login.
    - The `domain.rcuSchema.prefix`: password for the RCU schemas.
    - The `domain.rcuSchema.credentials.password`: password for the RCU schemas.
    - The `domain.storage.nfs.server`: NFS server IP.
    - The `domain.storage.path`: NFS server mount point path.
    - The `oracledb.credentials.password`: password for the SYS user on the database.
    - The `oracledb.url`: connection URL for the Oracle database to use to create the RCU schema.

    ```bash
    helm install soainfra soa-suite \
        --namespace soans \
        --set domain.imagePullSecrets=image-secret \
        --set domain.domainName=soainfra \
        --set domain.type=soaosb \
        --set domain.credentials.username=weblogic \
        --set domain.credentials.password=Welcome1 \
        --set domain.rcuSchema.credentials.password="<RCU_password>" \
        --set domain.storage.nfs.server=<FILE_STORAGE_IP> \
        --set domain.storage.path=<FILE_STROAGE_MOUNT_PATH> \
        --set oracledb.provision=false \
        --set oracledb.sysPassword="<SYS_PASSWORD>" \
        --set oracledb.url="<DATABASE_URL>" \
        --wait  \
        --timeout 600s
    ```

If you wish to provision the database as part of the chart:

1. Before provisioning the database, install the Oracle Database Operator (OraOperator), so that chart can create the Oracle Single Instance Database. Refer  [Oracle Database Operator](https://github.com/oracle/oracle-database-operator#prerequisites) documentation for details.
1. Next, instead of supplying the `oracledb.url`, set the following values:

    ```bash
        --namespace soans \
        --set domain.imagePullSecrets=image-secret \
        --set domain.domainName=soainfra \
        --set domain.type=soaessosb \
        --set domain.credentials.username=weblogic \
        --set domain.credentials.password=Welcome1 \
        --set domain.rcuSchema.credentials.password="<RCU_password>" \
        --set domain.storage.nfs.server=<FILE_STORAGE_IP> \
        --set domain.storage.path=<FILE_STROAGE_MOUNT_PATH> \
        --set oracledb.sysPassword="<SYS_PASSWORD>" \
        --set oracledb.provision=true \
        --wait  \
        --timeout 600s
    ```

    The Oracle database will be provisioned with the default pdb=`pdb`, cdb=`cdb` unless overridden.

Upon installation, the RCU schema will be created and the domain files will be created on the file storage provided.

### Stopping the domain

```bash
helm upgrade soainfra soa-suite -n soans \
    --reuse-values \
    --set domain.enabled=false
```

### Uninstall the chart

Uninstalling the chart will destroy the domain entirely, deleting the files on file storage and dropping the schema on the database.

For the files to be removed properly, the domain must be shut down first as per the step above (stopping the domain)

Once the domain was shut down, delete the chart with:

```bash
helm delete soainfra -n soans
```
