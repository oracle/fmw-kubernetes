### OracleAccessManagement domain release upgrade

This section provides details on how to upgrade OracleAccessManagement domains from release 12.2.1.4 to 14.1.2.0.

#### Prerequisites

Check that the following have been met before starting the automated domain upgrade process:
* Administration and all collocated managed servers will be shutdown before upgrade process. Make sure that the servers in the domain can be brought down.
* All affected data is backed up.
* Domain home is backed up.
* Database version is certified by Oracle for Fusion Middleware upgrade.
* Certification and system requirements have been met.

#### Prepare to use the domain upgrade scripts

The sample scripts for automating the domain upgrade (schema upgrade and domain home upgrade) for OracleAccessManagement domain are available at `${WORKDIR}/domain-upgrade`.

You must edit `domain-upgrade-inputs.yaml` (or a copy of it) to provide the details for domain upgrade.

Refer to the configuration parameters below to understand the information that you must provide in this file.

#### Configuration parameters

The following parameters can be provided in the inputs file.

| Parameter | Definition | Default |
| --- | --- | --- |
| `domainHome` | Home directory of the OracleAccessManagement domain. | `"/u01/oracle/user_projects/domains/accessdomain"` |
| `domainPVMountPath` | Mount path of the domain persistent volume. | `"/u01/oracle/user_projects/domains"` |
| `domainUID` | WebLogic Server domain name. | `accessdomain` |
| `image` | OracleAccessManagement 14.1.2 container image. | `"oracle/oam:release-version"` |
| `imagePullPolicy` | OracleAccessManagement container image pull policy. Valid values are `IfNotPresent`, `Always`, `Never`. | `IfNotPresent` |
| `imagePullSecretName` | Name of the Kubernetes secret to access the container registry to pull the OracleAccessManagement container image. The presence of the secret will be validated when this parameter is specified. | `` |
| `namespace` | Kubernetes namespace of the domain. | `oamns` |
| `persistentVolumeClaimName` | Name of the persistent volume claim used for the domain home.  | `accessdomain-domain-pvc` |
| `rcuSchemaPrefix` | The schema prefix. | `OAMPD`|
| `rcuDatabaseURL`  | The database URL. | `"xxxxx.example.com:1521/oampdb1.example.com"` |
| `rcuCredentialsSecret` | The Kubernetes secret containing the database credentials. | `accessdomain-rcu-credentials` |


**Note**: The values for the parameters in the inputs file are to be provided without any blank space. Refer [create-rcu-credentials](https://github.com/oracle/fmw-kubernetes/blob/master/OracleAccessManagement/kubernetes/create-rcu-credentials/README.md) to create the Kubernetes secret (`rcuCredentialsSecret`) containing the database credentials.


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
* Performs product specfic workarounds/tasks if any.
* Updates the domain spec with the 14.1.2 image.
* Starts and waits for the domain to be up and running with 14.1.2 image.
* All upgrade checkpoints/logs are captured inside domain home root (Mount path of the domain persistent volume) inside "upgrade_<domain-uid>" directory

