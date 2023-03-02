# Creating RCU credentials for a OracleSOASuite domain

This sample demonstrates how to create a Kubernetes secret containing the
RCU credentials for a OracleSOASuite domain.  The operator expects this secret to be
named following the pattern `domainUID-rcu-credentials`, where `domainUID`
is the unique identifier of the domain.  It must be in the same namespace
that the domain will run in.

To use the sample, run the command:

```
$ ./create-rcu-credentials.sh \
  -u username \
  -p password \
  -a sys_username \
  -q sys_password \
  -d domainUID \
  -n namespace \
  -s secretName
```

The parameters are as follows:

```  
  -u username for schema owner (regular user), must be specified.
   -p password for schema owner (regular user), must be provided using the -p argument or user will be prompted to enter a value.
  -a username for SYSDBA user, must be specified.
  -q password for SYSDBA user, must be provided using the -q argument or user will be prompted to enter a value.
  -d domainUID, optional. The default value is soainfra. If specified, the secret will be labeled with the domainUID unless the given value is an empty string.
  -n namespace, optional. Use the soans namespace if not specified.
  -s secretName, optional. If not specified, the secret name will be determined based on the domainUID value.
```

This creates a `generic` secret containing the user name and password as literal values.

You can check the secret with the `${KUBERNETES_CLI:-kubectl} describe secret` command.  An example is shown below,
including the output:

```
$ ${KUBERNETES_CLI:-kubectl} -n soans describe secret soainfra-rcu-credentials -o yaml
Name:         soainfra-rcu-credentials
Namespace:    soans
Labels:       weblogic.domainName=soainfra
              weblogic.domainUID=soainfra
Annotations:  <none>

Type:  Opaque

Data
====
password:      12 bytes
sys_password:  12 bytes
sys_username:  3 bytes
username:      4 bytes
```

