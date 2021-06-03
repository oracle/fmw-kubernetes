#### Configuring access to your database
   
Oracle SOA Suite domains require a database with the necessary schemas installed in them.
The Repository Creation Utility (RCU) allows you to create those schemas. You must set up the database before you create your domain.There are no additional requirements added by running SOA in Kubernetes; the same existing requirements apply.

For testing and development, you may choose to run your database inside Kubernetes or outside of Kubernetes.

{{% notice warning %}}
The Oracle Database images are supported for non-production use only.
For more details, see My Oracle Support note:
Oracle Support for Database Running on Docker (Doc ID 2216342.1).
{{% /notice %}}

##### Running the database inside Kubernetes

Follow these instructions to perform a basic deployment of the Oracle database in Kubernetes (for development and testing purpose only).

When running the Oracle database in Kubernetes, you have an option to attach persistent volumes (PV) so that the database storage will be persisted across database restarts. If you prefer not to persist the database storage, follow the instructions in this [document](https://github.com/oracle/weblogic-kubernetes-operator/tree/master/kubernetes/samples/scripts/create-rcu-schema#start-an-oracle-database-service-in-a-kubernetes-cluster) to set up a database in a container with no persistent volume (PV) attached.

>**NOTE**: `start-db-service.sh` by default creates the database in the `default` namespace. If you
>want to create the database in a different namespace, you can use `-n` flag.

These instructions will set up the database in a container with the persistent volume (PV) attached.
If you chose not to use persistent storage, please go to the [RCU creation step](#running-the-repository-creation-utility-to-set-up-your-database-schemas).

* Create the persistent volume and persistent volume claim for the database
using the [create-pv-pvc.sh](https://oracle.github.io/weblogic-kubernetes-operator/samples/simple/storage/) sample.
Refer to the instructions provided in that sample.

{{% notice note %}}
When creating the PV and PVC for the database, make sure that you use a different name
and storage class for the PV and PVC for the domain.
The name is set using the value of the `baseName` field in `create-pv-pvc-inputs.yaml`.
{{% /notice %}}

* Start the database and database service using the following commands:

>**NOTE**: Make sure you update the `create-database/db-with-pv.yaml` file with the name of the PVC created in the previous step. Also, update the value for all the occurrences of the namespace field to the namespace where the database PVC was created.

    ```bash
    $ cd <scripts_location>/create-database
    $ kubectl create -f db-with-pv.yaml
    ```

The database will take several minutes to start the first time, while it
performs setup operations.  You can watch the log to see its progress using
this command:

```bash
$ kubectl logs -f oracle-db -n soans
```

A log message will indicate when the database is ready.  Also, you can
verify the database service status using this command:

```bash
$ kubectl get pods,svc -n soans |grep oracle-db
po/oracle-db   1/1       Running   0          6m
svc/oracle-db   ClusterIP   None         <none>        1521/TCP,5500/TCP   7m
```
Before creating a domain, you will need to set up the necessary schemas in your database.

