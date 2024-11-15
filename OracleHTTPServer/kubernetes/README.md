# Deploying Oracle HTTP Server in Kubernetes

For full documentation see: [https://oracle.github.io/fmw-kubernetes/ohs](https://oracle.github.io/fmw-kubernetes/ohs)


## Obtaining the Scripts

The sample scripts are available for download from GitHub.

To obtain the scripts, use the following command:

```
git clone https://github.com/oracle/fmw-kubernetes.git
```

The scripts appear in the following directory:

```
fmw-kubernetes/OracleHTTPServer/kubernetes
```


## Scope
This section lists the actions that the scripts perform as part of the deployment process. It also lists the tasks the scripts do not perform.

### What the Scripts Will do

The scripts will deploy Oracle HTTP Server in Kubernetes. 

The scripts perform the following actions:

* Create an Oracle HTTP Server Instance in Kubernetes, with your own configuration.
* Deploy Oracle WebGate and its associated configuration.
* Create a NodePort Service for accessing the Oracle HTTP Server

## Create a Namespace

Create a namespace for your Oracle HTTP Server:

`kubectl create namespace ohsns`

## Create Secrets

### Create Registry Secret

If you are pulling your container image from a  protected registry then you must create a secret with the connection credentials, for example,

`kubectl create secret -n hosts docker-registry regcred --docker-server=<REGISTRY> --docker-username=<REG_USER> --docker-password=<REG_PWD>`

Where:

* \<REGISTRY\> is the name of the registry you are using.
* \<REG_USER\> is the name of the user you use to connect to the registry.
* \<REG_PWD\> is the password you use to connect to the registry.


### Create OHS Secret

The Oracle HTTP Server requires a username and password for the standalone OHS domain.  To create this secret use the following command:

`kubectl create secret generic ohs-secret -n\<namespace> --from-literal=username=weblogic --from-literal=password='<password>'`

Replace \<password\> with a password of your choice.

## Prepare your OHS configuration files

Before you deploy OHS, you must prepare your OHS configuration files.  Oracle HTTP Server in containers stores the OHS configuration inside Kubernetes configmaps, rather than on the filesystem.   This allows the configuration to be independent of both the instance and filesystem.

The steps below assume familiarity with on premises Oracle HTTP Server in terms of general configuration and use of Oracle WebGate.

**Note:** Administrators should be aware of the following:

* If you do not specify configuration files beforehand, then the OHS container is deployed with a default configuration of Oracle HTTP Server.
* The directories listed below are optional. For example, if you do not want to deploy WebGate then you do not need to create the webgateConf and webgateWallet directories. Similarly, if you do not want to copy files to htdocs then you do not need to create the htdocs directory.

Create the following directories for your OHS configuration:

```
mkdir -p $WORKDIR/ohsConfig/httpconf
mkdir -p $WORKDIR/ohsConfig/moduleconf
mkdir -p $WORKDIR/ohsConfig/htdocs
mkdir -p $WORKDIR/ohsConfig/htdocs/myapp
mkdir -p $WORKDIR/ohsConfig/webgate/config/wallet
mkdir -p $WORKDIR/ohsConfig/wallet/mywallet
```

**Where:**

* **httpconf** - contains any configuration files you want to configure that are usually found in the $OHS\_DOMAIN\_HOME/config/fmwconfig/components/OHS/ohs1 directory. For example httpd.conf, ssl.conf and mod\_wl\_ohs.conf. The webgate.conf does not need to be copied as this will get generated automatically if deploying with WebGate.
* **moduleconf** - contains any additional config files, for example virtual host configuration files that you want to copy to the $OHS\_DOMAIN\_HOME/config/fmwconfig/components/OHS/ohs1/moduleconf folder in the container.
* **htdocs** - contains any html files, or similar, that you want to copy to the $OHS\_DOMAIN\_HOME/config/fmwconfig/components/OHS/ohs1/htdocs folder in the container.
* **htdocs/myapp** - myapp is an example directory name that exists under htdocs. If you need to copy any directories under htdocs above, then create the directories you require.
* **webgate/config** - contains the extracted WebGate configuration. For example, when you download the \<agent\>.zip file from Oracle Access Management Console, you extract the zip file into this directory. If you are accessing OAM URL’s via SSL, this directory must also contain the Certificate Authority cacert.pem file that signed the certificate of the OAM entry point. For example, if you will access OAM via a HTTPS Load Balancer URL, then cacert.pem is the CA certificate that signed the load balancer certificate.
* **webgate/config/wallet** - contains the contents of the wallet directory extracted from the \<agent.zip\> file.
* **wallet/mywallet** - If OHS is to be configured to use SSL, this directory contains the preconfigured OHS Wallet file cwallet.sso.

**Note:** Administrators should be aware of the following if configuring OHS for SSL:

* The wallet must contain a valid certificate.
* Only auto-login-only wallets (cwallet.sso only) are supported. For example, wallets created with orapki using the -auto-login-only option. Password protected wallets (ewallet.p12) are not supported.
* You must configure ssl.conf in $WORKDIR/ohsConfig/httpconf and set the directory for SSLWallet to: SSLWallet "${ORACLE\_INSTANCE}/config/fmwconfig/components/${COMPONENT\_TYPE}/instances/${COMPONENT\_NAME}/keystores/wallet/mywallet".

An example file system may contain the following:

```
ls -R $WORKDIR/ohsConfig

/home/opc/OHSK8S/ohsConfig:

htdocs  httpconf  moduleconf  wallet  webgate

/home/opc/OHSK8S/ohsConfig/htdocs:

myapp  mypage.html

/home/opc/OHSK8S/ohsConfig/htdocs/myapp:

index.html

/home/opc/OHSK8S/ohsConfig/httpconf:

httpd.conf  mod_wl_ohs.conf  ssl.conf

/home/opc/OHSK8S/ohsConfig/moduleconf:

vh.conf

/home/opc/OHSK8S/ohsConfig/wallet:

mywallet

/home/opc/OHSK8S/ohsConfig/wallet/mywallet:

cwallet.sso

/home/opc/OHSK8S/ohsConfig/webgate:

config

/home/opc/OHSK8S/ohsConfig/webgate/config:

cacert.pem  cwallet.sso  cwallet.sso.lck  ObAccessClient.xml  wallet

/home/opc/OHSK8S/ohsConfig/webgate/config/wallet:

cwallet.sso  cwallet.sso.lck
```

## Create configmaps for the OHS configuration files

**Note:** Before following this section, make sure you have created the directories and files as per Prepare your OHS configuration files.

Run the following commands to create the required configmaps for the OHS directories and files created in Prepare your OHS configuration files.

```
cd $WORKDIR
 
kubectl create cm -n ohsns ohs-config --from-file=ohsConfig/moduleconf
kubectl create cm -n ohsns ohs-httpd --from-file=ohsConfig/httpconf
kubectl create cm -n ohsns ohs-htdocs --from-file=ohsConfig/htdocs
kubectl create cm -n ohsns ohs-myapp --from-file=ohsConfig/htdocs/myapp
kubectl create cm -n ohsns webgate-config --from-file=ohsConfig/webgate/config
kubectl create cm -n ohsns webgate-wallet --from-file=ohsConfig/webgate/config/wallet
kubectl create cm -n ohsns ohs-wallet --from-file=ohsConfig/wallet/mywallet
```
**Note:** Only create the configmaps for directories that you want to copy to OHS.



## Filling in the Sample Files

### Prepare the ohs.yaml file

In this section you prepare the `ohs.yaml` file ready for OHS deployment.

Make a copy of the ohs.yaml file:

 `$ cp ohs.yaml ohs.yaml.orig`
 
Edit the ohs.yaml and change the following parameters to match your installation:

**Notes:**

* During the earlier creation of the namespace, configmaps, and secret, if you changed the names from the given examples, then you will need to update the values accordingly.
* All configMaps are shown for completeness. Remove any configMaps that you are not using, for example if you don’t require htdocs then remove the ohs-htdocs configMap. If you are not deploying webgate then remove the webgate-config and webgate-wallet configMaps, and so forth.
* If you have created any additional directories under htdocs, then add the additional entries in that match the configmap and directory names.
* All configMaps used must mount to the directories stated.
* Change the image to the correct image tag on Oracle Container Registry. If you are using your own container registry for the image, you will need to change the image location appropriately. If your own container registry is open, you do not need the imagePullSecrets.
* Ports can be changed if required.
* Set DEPLOY_WG to true or false depending on whether webgate is to be deployed.

### Prepare the ohs_service.yaml file

Make a copy of the ohs_service.yaml file:

```
cd $WORKDIR
cp ohs_service.yaml ohs_service.yaml.orig
```
Edit the ohs_service.yaml and modify the file accordingly. For example, if you are using your own httpd.conf file and have changed the port to anything other than 7777, you must change the targetPort and port to match. Similarly, if you don’t require SSL, then you would remove the section relating to -port: 4443.

## Deploying Oracle HTTP Server

### Creating the OHS Container

In this section you create the OHS container using the ohs.yaml file created in Prepare the ohs.yaml file.

Run the following command to create the OHS container:

`kubectl create -f $WORKDIR/ohs.yaml`

The output will look similar to the following:

configmap/ohs-script-configmap created

deployment.apps/ohs-domain created

Run the following command to view the status of the pods:

`kubectl get pods -n <namespace> -w`

### Creating OHS NodePort Service

Run the following command to create a Kubernetes service nodeport for OHS.

**Note:** Administrators should be aware of the following:

As this is a Kubernetes service it will deploy to whichever node it is run from. If that node goes down then it will start on another node.

If you create another OHS container on a different port, you will need to create another nodeport service for that OHS.

`kubectl create -f $WORKDIR/ohs_service.yaml`

The output will look similar to the following:

service/ohs-domain-nodeport created

Validate the service has been created using the command:

`kubectl get service -n <namespace>`


