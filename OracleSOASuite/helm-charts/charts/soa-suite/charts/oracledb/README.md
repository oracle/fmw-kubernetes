# Oracle Database Helm Chart

This Helm chart deploys a development instance of the Oracle database version 12.2.0.1, for use with the Oracle SOA Suite Helm chart.

## Disclaimer

This chart is for demo purpose only. It stores data in the container itself which will be lost if the pod is re-assigned or deleted.

## Prerequisites

To deploy this chart, you will need:

- An Oracle Container Registry account created through the Oracle Single Sign-On portal.
- Acknowledge terms of use for the Oracle Database Docker image on the Oracle Container Registry.

### 1.1 Oracle Container Registry

You will need an Oracle Container Registry account created through the Oracle Single Sign-On portal [https://profile.oracle.com/myprofile/account/create-account.jspx](https://profile.oracle.com/myprofile/account/create-account.jspx).

Log in with your Oracle account credentials or create a new account, and agree to the terms of use for the images you need to use:

### 1.2 Oracle Database Docker Image

You may provision the database supporting the Oracle SOA suite domain schemas separately, and point the chart to it by providing the database url. The database must be accessible from the Kubernetes cluster. This is the recommended way to deploy this chart.

If you intend on deploying the database within the kubernetes cluster (optional; not for production), you must agree to the terms of the Oracle database Docker image:

- At [https://container-registry.oracle.com](https://container-registry.oracle.com), search for 'database'.
- Click **Enterprise**.
- Click to accept the License terms and condition on the right.
- Fill in your information (if you haven't already).
- Accept the License.

Note that the deployment in cluster is for testing purpose only and not for production.

### Create a docker-registry Secret

The chart needs to pull the image from the Oracle Container Registry, and for doing so requires the credentials to be stored in a docker-registry secret.

```bash
kubectl create secret docker-registry image-secret -n ${namespace} --docker-server=container-registry.oracle.com --docker-username='${email}' --docker-password='${password}' --docker-email='${email}'
```

## Usage

1. Add the Helm repository to your known repositories

    ```bash
    helm repo add oracle https://oracle.github.io/helm-charts --force-update
    ```

2. Create a secret for the database credentials.

    This step is optional but recommended. You can also pass credentials directly as `credentials.username` and `credentials.password` values, however they will be available in clear through the `helm get values <deployment>` command.

    ```bash
    kubectl create secret generic db_credentials \
      -n ${namespace}
      --from-literal=username=SYS \
      --from-literal=password='<password_containing_1upper_1number_1special>'
    ```

3. Deploy the chart

    ```bash
    helm install ${deployment_name} oracle/oracledb \
        --namespace ${namespace} \
        --set credentials.secretName=db_credentials \
        --set sid=${cdb_name} \
        --set pdb=${pdb_name} \
        --set domain=${domain_name} \
        --set 'imagePullSecrets[0].name=image-secret'
    ```
