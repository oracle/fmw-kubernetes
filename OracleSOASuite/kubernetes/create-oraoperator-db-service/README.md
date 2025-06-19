# Deploy Single Instance Container Database managed by Oracle Database Operator

This documentation provides instructions for provisioning a ``Single Instance Container Database`` on a Kubernetes cluster managed by ``Oracle Database Operator``. Refer [Single Instance Database on Kubernetes](https://github.com/oracle/docker-images/tree/main/OracleDatabase/SingleInstance/samples/kubernetes) or [Single Instance Database on Kubernetes using helm chart](https://github.com/oracle/docker-images/tree/main/OracleDatabase/SingleInstance/helm-charts/oracle-db) to provision the Database without using an Oracle Database Operator.

## **Prerequisites**

- **Install cert-manager** with the following command : 
  ```sh
  $ kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.yaml
  ```
  >**Note** : Ignore the above step if ``cert-manager`` is already deployed in your Kubernetes cluster. 


- **Setup persistent storage** : The volumes are required for persistent storage of Database files. You can use a dynamic volume provisioner or pre-create a static persistent volume manually. Refer [Database Persistence Storage Configuration](https://github.com/oracle/oracle-database-operator/tree/main/docs/sidb#database-persistence-storage-configuration-options) for more options. Sample is provided to create a static persistent volume. You can update the ```single-instance-db-vol.yaml``` for <host_path> parameter and create the static persistent volume with below command.

  ```sh
  $ cd $WORKDIR/create-oraoperator-db-service/
  $ kubectl apply -f single-instance-db-vol.yaml
  ```

- **Setup cluster scope deployment** : Provide the ``serviceaccount:oracle-database-operator-system:default`` cluster wide access for the resources :

  ```sh
  $ kubectl apply -f https://raw.githubusercontent.com/oracle/oracle-database-operator/main/rbac/cluster-role-binding.yaml
  ```
  >**Note** :  OraOperator can be deployed to operate in a namespace to monitor one or more namespace. Refer [Namespace Scoped Deployment](https://github.com/oracle/oracle-database-operator/tree/main#2-namespace-scoped-deployment) for more details.

## **Deploy Oracle Database Operator**

- To install the Operator, apply the ```oracle-database-operator.yaml```. The operator will be deployed in ```oracle-database-operator-system``` namesapce. 

    ```sh
    $ kubectl apply -f https://raw.githubusercontent.com/oracle/oracle-database-operator/main/oracle-database-operator.yaml
    ```
- Verify the operator is running

  ```sh
  $ kubectl get po -n oracle-database-operator-system
  ```
  Expected output
  ```
  NAME                                                           READY   STATUS    RESTARTS   AGE
  oracle-database-operator-controller-manager-79df7fc74f-l5596   1/1     Running   0          9d
  oracle-database-operator-controller-manager-79df7fc74f-nzsf9   1/1     Running   0          9d
  oracle-database-operator-controller-manager-79df7fc74f-stlth   1/1     Running   0          9d
  ```
## **Create Kubernetes secret** 
- Create registry secret for image pull and Database admin secret using below commands
1. Create Oracle container registry Kubernetes secret
   ```sh
   $ kubectl create secret docker-registry "container-reg-credential" \
   --docker-server=container-registry.oracle.com \
   --docker-username="<user-name>"
   --docker-password="<password>" \
   --docker-email="user@example.com"
   ```
1. Create a Database admin secret ```db-admin-secret```
   ```sh
   $ kubectl create secret generic db-admin-secret --from-literal='oracle_pwd=Oradoc_db1'
   ```

## **Deploy Single Instance Container Database**

- Deploy ```single-instance-database.yaml```. This creates the Single Instance Database in default namespace with nodeport service. For more information refer [Single Instance Database with Oracle Database Operator](https://github.com/oracle/oracle-database-operator/blob/main/docs/sidb/README.md). Review the parameter configuration for ```persistent-volume```.
    ```sh
    $ cd $WORKDIR/create-oraoperator-db-service/
    $ kubectl apply -f single-instance-database.yaml
    ```
- Verify the database availability
  ```sh
  $ kubectl get singleinstancedatabases single-instance-database
  ```
  Expected output
  ```
  NAME                       EDITION      STATUS    ROLE      VERSION      CONNECT STR                   TCPS CONNECT STR   OEM EXPRESS URL
  single-instance-database   Enterprise   Healthy   PRIMARY   21.3.0.0.0   192.123.111.890:32454/ORCL1   Unavailable        https://192.123.111.890:31064/em
  ```
- Get ```pdb string``` of database to create rcu schema and for domain creation
  ```sh
  $ kubectl get singleinstancedatabase single-instance-database -o "jsonpath={.status.pdbConnectString}"
  ```
  Expected output
  ```
  192.123.111.890:32454/ORCLPDB1
  ```

