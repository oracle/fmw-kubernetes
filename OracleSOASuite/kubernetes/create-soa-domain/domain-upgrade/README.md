> Note: The upgrade scripts are for preview release.

### Oracle SOA Suite domain release upgrade

This section provides details on how to upgrade OracleSOASuite domains from release 12.2.1.4 to 14.1.2.0.

#### Prerequisites

Check that the following have been met before starting the automated domain upgrade process:
* Administration and all collocated managed servers will be shutdown before upgrade process. Make sure that the servers in the domain can be brought down.
* All affected data is backed up.
* Domain home is backed up.
* Database version is certified by Oracle for Fusion Middleware upgrade.
* Certification and system requirements have been met.
* Review [here](https://docs.oracle.com/en/middleware/soa-suite/soa/14.1.2/release-notes/known-issues-and-workarounds-soarn.html#GUID-C8908FC6-EFA8-430D-ADFE-F7CFD8981B0D) for impacted scenarios after upgrade.

#### Prepare to use the domain upgrade scripts

The sample scripts for automating the domain upgrade (schema upgrade and domain home upgrade) for Oracle OracleSOASuite domain are available at `${WORKDIR}/create-soa-domain/domain-upgrade`.

You must edit `domain-upgrade-inputs.yaml` (or a copy of it) to provide the details for domain upgrade.

Refer to the configuration parameters below to understand the information that you must provide in this file.

#### Configuration parameters

The following parameters can be provided in the inputs file.

| Parameter | Definition | Default |
| --- | --- | --- |
| `domainHome` | Home directory of the OracleSOASuite domain. | `/u01/oracle/user_projects/domains/soainfra` |
| `domainPVMountPath` | Mount path of the domain persistent volume. | `/u01/oracle/user_projects` |
| `domainUID` | WebLogic Server domain name. | `soainfra` |
| `image` | OracleSOASuite 14.1.2 container image. | `soasuite:release-version` |
| `imagePullPolicy` | OracleSOASuite container image pull policy. Valid values are `IfNotPresent`, `Always`, `Never`. | `IfNotPresent` |
| `imagePullSecretName` | Name of the Kubernetes secret to access the container registry to pull the OracleSOASuite container image. The presence of the secret will be validated when this parameter is specified. |  |
| `namespace` | Kubernetes namespace of the domain. | `soans` |
| `persistentVolumeClaimName` | Name of the persistent volume claim used for the domain home.  | `soainfra-domain-pvc` |
| `rcuSchemaPrefix` | The schema prefix. | `SOA1`|
| `rcuDatabaseURL`  | The database URL. | `oracle-db.default.svc.cluster.local:1521/devpdb.k8s` |
| `rcuCredentialsSecret` | The Kubernetes secret containing the database credentials. | `soainfra-rcu-credentials` |
| `secureEnabled` | Boolean indicating if secure to be enabled for the domain. | `false` |

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
* Enables secure domain if flag `secureEnabled` is set to `true`.
* Updates the domain spec with the 14.1.2 image.
* Starts and waits for the domain to be up and running with 14.1.2 image.

#### Upgrade ingress

This step is required in case you have enabled `secureEnabled` to `true` during domain upgrade. For secure domain only `sslType=E2ESSL` is supported. In case the ingress controller is not installed with support for `E2ESSL`, for example, for NGINX, recreate the ingress controller accordingly. Then run the `helm upgrade` to update the ingress-per-domain with `--set wlsDomain.secureEnabled=true`. Sample command as below: 

```
$ cd $WORKDIR
$ helm install REPLACE-WITH-INGRESS-PER-DOMAIN-RELEASE-NAME charts/ingress-per-domain \
  --reuse-values --set wlsDomain.secureEnabled=true 
```
