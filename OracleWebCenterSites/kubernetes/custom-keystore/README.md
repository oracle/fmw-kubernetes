This section provides details on how to configure custom keystore for OracleWebCenterSites domains.

> **Note**: The page is applicable for OracleWebCenterSites 14.1.2.0.0

#### Prerequisites

Before you begin, complete the following steps:

1. Create the [OracleWebCenterSites](https://github.com/oracle/fmw-kubernetes) with `sslEnabled` set to `true`.
1. [Set up a load balancer](https://github.com/oracle/fmw-kubernetes)

    - With `sslType=E2ESSL`
    - Choose appropriate values for `hostName.xxxx`, so that it matches the certificate common name,`cnHostname` passed as an input below for configuring custom keystore.

#### Prepare to use the configure custom keystore scripts

The sample scripts for configuring the custom keystore for OracleWebCenterSites domain are available at `${WORKDIR}/custom-keystore`.

You must edit `custom-keystore-inputs.yaml` (or a copy of it) to provide the details for custom keystore.

By default the custom keystore is created with Identity Keystore password as `identityStorePassword`, Identity Keystore type as `PKCS12`, Trust Keystore password as `trustKeystorePassword` and Trust Keystore type as `PKCS12`. To create custom keystore with different values, create a Kubernetes secret with below command:

```
$ ${KUBERNETES_CLI:-kubectl} -n NAMESPACE create secret generic custKeystoreCredentialsSecretName \
  --from-literal=identity_type=MY_CUSTOM_IDENTITY_TYPE \
  --from-literal=identity_password=MY_CUSTOM_IDENTITY_PASSWORD \
  --from-literal=trust_type=MY_CUSTOM_TRUST_TYPE \
  --from-literal=trust_password=MY_CUSTOM_TRUST_PASSWORD
```
- Replace MY_CUSTOM_IDENTITY_TYPE with the custom keystore identity type.
- Replace MY_CUSTOM_IDENTITY_PASSWORD with the custom keystore identity password.
- Replace MY_CUSTOM_TRUST_TYPE with the custom keystore trust type.
- Replace MY_CUSTOM_TRUST_PASSWORD with the custom keystore trust password.

Refer to the configuration parameters below to understand the information that you must
provide in this file.

#### Configuration parameters
The following parameters can be provided in the inputs file.

| Parameter | Definition | Default |
| --- | --- | --- |
| `adminPort` | Port number of the Administration Server. | `7011` |
| `adminServerName` | Name of the Administration Server. | `AdminServer` |
| `domainHome` | Home directory of the OracleWebCenterSites domain. | `/u01/oracle/user_projects/domains/wcsitesinfra` |
| `domainPVMountPath` | Mount path of the domain persistent volume. | `/u01/oracle/user_projects` |
| `domainUID` | WebLogic Server domain name. | `wcsitesinfra` |
| `image` | OracleWebCenterSites container image. | `oracle/wcsites:release-version` |
| `imagePullPolicy` | OracleWebCenterSites container image pull policy. Valid values are `IfNotPresent`, `Always`, `Never`. | `IfNotPresent` |
| `imagePullSecretName` | Name of the Kubernetes secret to access the container registry to pull the OracleWebCenterSites container image. The presence of the secret will be validated when this parameter is specified. |  |
| `namespace` | Kubernetes namespace of the domain. | `wcsites-ns` |
| `persistentVolumeClaimName` | Name of the persistent volume claim used for the domain home.  | `wcsitesinfra-domain-pvc` |
| `weblogicCredentialsSecretName` | Name of the Kubernetes secret of the Administration Server's user name and password. | `wcsitesinfra-domain-credentials` |
| `custKeystoreCredentialsSecretName` | Name of the Kubernetes secret that contains custome keystore identity/trust type and password. | `wcsitesinfra-custom-keystore-credentials` |
| `weblogicImagePullSecretName` | Name of the Kubernetes secret for the Docker Store, used to pull the WebLogic Server image. |   |
| `secureEnabled` | Boolean indicating if secure is enabled for the domain.|  `true` |
| `cnHostname` | Hostname to be used for "CN" of keystore|  `"*.domain.org"` |
| `aliasPrefix` | Keystore alias prefix. This will be used to append the alias used for custom keystore. Unique value is required on every execution. Also this value will be used to create the directory under $DOMAIN_HOME/keystore where the generated keystore files will be stored. |  `1` |

#### Run the custom keystore configure script

Run the custom keystore script, specifying your inputs file and an output directory to store the
generated artifacts:

```
$ cd custom-keystore
$ ./custom-keystore.sh \
  -i custom-keystore-inputs.yaml \
  -o <path to output-directory>
```

The script will perform the following steps:

* Creates pod for configuring custom keystore
* Creates the custom identity and trust keystore in `$DOMAIN_HOME/keystore` directory
* Perform custom keystore configuring and updating OPSS
* Restarts and waits for the servers/domain to be up and running

