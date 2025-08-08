> Note: The upgrade scripts are for preview release.

### OracleSOASuite domain release upgrade

This section provides details on how to upgrade OracleSOASuite domains from release 12.2.1.4 to 14.1.2.0.

#### Prerequisites

Check that the following have been met before starting the automated domain upgrade process:
* Administration and all collocated managed servers will be shutdown before upgrade process. Make sure that the servers in the domain can be brought down.
* All affected data is backed up.
* Domain home is backed up.
* Database version is certified by Oracle for Fusion Middleware upgrade.
* Certification and system requirements have been met.

#### Prepare to use the domain upgrade scripts

The sample scripts for automating the domain upgrade (schema upgrade and domain home upgrade) for OracleSOASuite domain are available at `${WORKDIR}/domain-upgrade`.

You must edit `domain-upgrade-inputs.yaml` (or a copy of it) to provide the details for domain upgrade.

Refer to the configuration parameters below to understand the information that you must provide in this file.

#### Configuration parameters

* If SSL is disabled in the source environment, then you can not enable secure mode directly during upgrade process. Hence do not set `secureEnabled` to true as this will result in unexpected behaviour. You can perform below steps to enable secure domain:
       - First upgrade to non-secure 14.1.2 domain using the domain upgrade scripts.
       - Post upgrade, once the servers are up and running, refer to [Enable Secure domain post upgrade](#enable-secure-domain-post-upgrade) to enable the secure domain.

* If SSL is enabled in the source environment then you can set `secureEnabled` to `true` to enable secure domain during the upgrade process. 

The following parameters can be provided in the inputs file.

| Parameter | Definition | Default |
| --- | --- | --- |
| `domainHome` | Home directory of the OracleSOASuite domain. | `"/u01/oracle/user_projects/domains/soainfra"` |
| `domainPVMountPath` | Mount path of the domain persistent volume. | `"/u01/oracle/user_projects"` |
| `domainUID` | WebLogic Server domain name. | `soainfra` |
| `image` | OracleSOASuite 14.1.2 container image. | `"soasuite:release-version"` |
| `imagePullPolicy` | OracleSOASuite container image pull policy. Valid values are `IfNotPresent`, `Always`, `Never`. | `IfNotPresent` |
| `imagePullSecretName` | Name of the Kubernetes secret to access the container registry to pull the OracleSOASuite container image. The presence of the secret will be validated when this parameter is specified. |  |
| `namespace` | Kubernetes namespace of the domain. | `soans` |
| `persistentVolumeClaimName` | Name of the persistent volume claim used for the domain home.  | `soainfra-domain-pvc` |
| `rcuSchemaPrefix` | The schema prefix. | `SOA1`|
| `rcuDatabaseURL`  | The database URL. | `"xxxxx.example.com:1521/xxxxx.example.com"` |
| `rcuCredentialsSecret` | The Kubernetes secret containing the database credentials. | `soainfra-rcu-credentials` |
| `secureEnabled` | Boolean indicating if secure to be enabled for the domain. | `false` |


**Note**:  The values for the parameters in the inputs file are to be provided without any blank space. Refer [create-rcu-credentials](https://github.com/oracle/fmw-kubernetes/blob/master/OracleSOASuite/kubernetes/create-rcu-credentials/README.md) to create the Kubernetes secret (`rcuCredentialsSecret`) containing the database credentials.


#### Run the domain upgrade script

Run the domain upgrade script, specifying your inputs file and an output directory to store the
generated artifacts:

```
$ cd domain-upgrade
$ ./domain-upgrade.sh \
  -i domain-upgrade-inputs.yaml \
  -o <path to output-directory>
```

The script will perform the following steps:

* Stops the domain
* Creates pod using the 14.1.2 image and the persistent volume claim used for the domain home for performing the domain upgrade.
* Performs UA schema upgrade.
* Performs domain home upgrade.
* Sets the database values for new WLS_RUNTIME schema.
* Performs product specific workarounds/tasks if any.
* Enables secure domain if flag `secureEnabled` is set to `true`.
* Updates the domain spec with the 14.1.2 image.
* Starts and waits for the domain to be up and running with 14.1.2 image.
* All upgrade checkpoints/logs are captured inside domain home root (Mount path of the domain persistent volume) inside "upgrade_<domain-uid>" directory

#### Upgrade ingress

This step is required in case you have enabled `secureEnabled` to `true` during domain upgrade. For secure domain only `sslType=E2ESSL` is supported. In case the ingress controller is not installed with support for `E2ESSL`, for example, for NGINX, recreate the ingress controller accordingly. Then run the `helm upgrade` to update the ingress-per-domain with `--set wlsDomain.secureEnabled=true`. Sample command as below: 

```
$ cd $WORKDIR
$ helm upgrade REPLACE-WITH-INGRESS-PER-DOMAIN-RELEASE-NAME charts/ingress-per-domain \
  --reuse-values --set wlsDomain.secureEnabled=true 
```
#### Enable secure domain post upgrade

Perform the below steps to enable the secure domain in a non-SSL OracleSOASuite 14.1.2 domain:

* Connect to an Administration Server using WebLogic Remote console.
* In the **Edit Tree**, go to **Environment**, then **Domain** and enable the `Secured Production Mode` toggle on Domain screen.
* Click **Save**.
* Next in the **Edit Tree**, go to **Environment**, then **Servers**, and then **AdminServer**.
* Verify that **SSL Listen Port Enabled** field is enabled now. Then update `7002` in **SSL Listen Port** field and `9002` in **Local Administration Port Override** field.
* Click **Save**.
* Next in the **Edit Tree**, go to **Environment**, then **Servers** and then **soa_server1**.  
* Update the **SSL Listen Port** as `7004` and **Local Administration Port Override** as `9004`. Click **Save**. 
* Similarly update **SSL Listen Port** as `7004` and **Local Administration Port Override** as `9004` for all SOA managed servers in the cluster (For example, soa_server2, soa_server3, soa_server4 and soa_server5).
* If your domain has Oracle Service Bus cluster, then go to **Environment**, **Servers** and then **osb_server1**. Update the **SSL Listen Port** as `8003` and **Local Administration Port Override** as `9007`. Click **Save**.
* Similarly update **SSL Listen Port** as `8003` and **Local Administration Port Override** as `9007` for all OSB servers in the cluster (For example, osb_server2, osb_server3, osb_server4 and osb_server5). 
* After updating and saving, click **Commit changes** under **Click to view shopping cart actions**.
* Perform domain full shutdown and restart. Refer [Full domain restarts](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-lifecycle/startup/#full-domain-restarts) for details.

> **Note** : Once you have enabled "Secured Production Mode", existing ingress to access the domain URLs will not work. Refer to [Upgrade ingress](#upgrade-ingress) for details. 


