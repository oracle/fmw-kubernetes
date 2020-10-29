---
title: "Deploy using Maven and Ant"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 2
pre : "<b>b. </b>"
description: "Deploy Oracle SOA Suite and Oracle Service Bus composite applications using the Maven and Ant based approach in an Oracle SOA Suite deployment."
---

Learn how to deploy Oracle SOA Suite and Oracle Service Bus composite applications using the Maven and Ant based approach in an Oracle SOA Suite in WebLogic Kubernetes operator environment.

Before deploying composite applications, we need to create a Kubernetes pod in the same cluster where the Oracle SOA Suite domain is running, so that composite applications can be deployed using the internal Kubernetes Service for the Administration Server URL.

Place the SOA/OSB composite project at a share location (for example at `/share/soa-deploy`) mounted at `/soacomposites` inside container.
Make sure to provide `oracle` user *( uid: 1000 and gid: 1000)* permission to directory `/share/soa-deploy`, so that it is accessible and writable inside the container.

```
$ sudo chown -R 1000:1000 /share/soa-deploy
```

Follow the steps in this section to create a container and then use it to deploy Oracle SOA Suite and Oracle Service Bus composite applications using Maven or Ant.


### Create a composite deployment container
Before creating a Kubernetes pod, make sure that the Oracle SOA Suite Docker image is available on a node, or you can create an image pull secret so that the pod can pull the Docker image on the host where it gets created.

1. Create an image pull secret to pull image `soasuite:12.2.1.4` by the Kubernetes pod:
   ```
   $ kubectl create secret docker-registry image-secret -n soans --docker-server=your-registry.com --docker-username=xxxxxx --docker-password=xxxxxxx  --docker-email=my@company.com
   ```

1. Create a PersistentVolume and PersistentVolumeClaim (`soadeploy-pv.yaml` and `soadeploy-pvc.yaml`) with sample composites for build and deploy placed at `/share/soa-deploy`.

   a) Create a PersistentVolume with the sample provided (`soadeploy-pv.yaml`), which uses NFS (you can use `hostPath` or any other supported PV type):
      ```
      apiVersion: v1
      kind: PersistentVolume
      metadata:
        name: soadeploy-pv
      spec:
        storageClassName: soadeploy-storage-class
        capacity:
         storage: 10Gi
        accessModes:
          - ReadWriteMany
        # Valid values are Retain, Delete or Recycle
        persistentVolumeReclaimPolicy: Retain
        # hostPath:
        nfs:
          server: X.X.X.X
          path: "/share/soa-deploy"
      ```

   b) Apply the YAML:
      ```
      $ kubectl apply -f soadeploy-pv.yaml
      ```

   c) Create a PersistentVolumeClaim (`soadeploy-pvc.yaml`):

      ```
      kind: PersistentVolumeClaim
      apiVersion: v1
      metadata:
        name: soadeploy-pvc
        namespace: soans
      spec:
        storageClassName: soadeploy-storage-class
        accessModes:
          - ReadWriteMany
        resources:
          requests:
            storage: 10Gi      
      ```

   d) Apply the YAML:
      ```
      $ kubectl apply apply -f soadeploy-pvc.yaml
      ```


1. Create a composite deploy pod using `soadeploy.yaml` to mount the composites inside pod at `/composites`:       
      ```
      apiVersion: v1
      kind: Pod
      metadata:
        labels:
          run: soadeploy
        name: soadeploy
        namespace: soans
      spec:
        imagePullSecrets:
        - name: image-secret
        containers:
        - image: soasuite:12.2.1.4
          name: soadeploy
          env:
          - name: M2_HOME
            value: /u01/oracle/oracle_common/modules/org.apache.maven_3.2.5
          command: ["/bin/bash", "-c", "echo 'export PATH=$PATH:$M2_HOME/bin' >> $HOME/.bashrc; sleep infinity"]
          imagePullPolicy: Always
          volumeMounts:
          - name: mycomposite
            mountPath: /composites
        volumes:
        - name: mycomposite
          persistentVolumeClaim:
             claimName: soadeploy-pvc
      ```

1. Create the pod:
      ```
      $ kubectl apply -f soadeploy.yaml
      ```   

1. Once the Kubernetes pod is deployed, exec into the pod to perform Maven/Ant based build and deploy:
   ```
   $ kubectl exec -it -n soans soadeploy -- bash
   ```

### Maven based build and deploy

> Note: Make sure to execute these commands inside the `soadeploy` pod.

Set up proxy details for Maven to pull dependencies from the internet.

   If your environment is not running behind a proxy, then skip this step. Otherwise, replace `REPLACE-WITH-PROXY-HOST`, `REPLACE-WITH-PROXY-PORT` and the value for `nonProxyHosts` attribute per your environment and create the `settings.xml`:

   ```
      $ mkdir $HOME/.m2
      $ cat <<EOF > $HOME/.m2/settings.xml
      <settings>
      <proxies>
      <proxy>
      <active>true</active>
      <protocol>http</protocol>
      <host>REPLACE-WITH-PROXY-HOST</host>
      <port>REPLACE-WITH-PROXY-PORT</port>
      <nonProxyHosts>soainfra-cluster-soa-cluster|soainfra-adminserver</nonProxyHosts>
      </proxy>
      </proxies>
      </settings>
      EOF
   ```

#### For Oracle SOA Suite composite applications

1. Set up the environment for Maven:
   ```
   #Perform Maven Sync
   $ cd /u01/oracle/oracle_common/plugins/maven/com/oracle/maven/oracle-maven-sync/12.2.1/
   $ mvn install:install-file \
       -DpomFile=oracle-maven-sync-12.2.1.pom \
       -Dfile=oracle-maven-sync-12.2.1.jar

   #install Maven plugin
   $ mvn help:describe \
       -Dplugin=com.oracle.maven:oracle-maven-sync \
       -Ddetail

   #push libraries into internal repository
   $ mvn com.oracle.maven:oracle-maven-sync:push \
       -DoracleHome=/u01/oracle \
       -DtestingOnly=false

   $ mvn archetype:crawl \
       -Dcatalog=$HOME/.m2/archetype-catalog.xml \
       -DarchetypeArtifactId=oracle-soa-application \
       -DarchetypeVersion=12.2.1-4-0
   ```

1. Build the SOA Archive (SAR) for your sample deployment available at `/composites/mavenproject/my-soa-app`:
   ```
   $ cd /composites/mavenproject/my-soa-app
   $ mvn package
   ```

   The SAR will be generated at `/composites/mavenproject/my-soa-app/my-project/target/sca_my-project.jar`.

1. Deploy into the Oracle SOA Suite instance. For example, if the instance URL is `http://soainfra-cluster-soa-cluster:8001` with credentials `username`: weblogic and `password`: Welcome1, enter the following commands:
   ```
   $ cd /composites/mavenproject/my-soa-app
   $ mvn pre-integration-test \
       -DoracleServerUrl=http://soainfra-cluster-soa-cluster:8001 \
       -DsarLocation=/composites/mavenproject/my-soa-app/my-project/target/sca_my-project.jar \
       -Doverwrite=true \
       -DforceDefault=true \
       -Dcomposite.partition=default \
       -Duser=weblogic  -Dpassword=Welcome1
   ```

#### For Oracle Service Bus composite applications

1. Set up the environment for Maven:
   ```
   #Perform Maven Sync
   $ cd /u01/oracle/oracle_common/plugins/maven/com/oracle/maven/oracle-maven-sync/12.2.1/
   $ mvn install:install-file \
       -DpomFile=oracle-maven-sync-12.2.1.pom \
       -Dfile=oracle-maven-sync-12.2.1.jar

   #push libraries into internal repository
   $ mvn com.oracle.maven:oracle-maven-sync:push \
       -DoracleHome=$ORACLE_HOME
   $ mvn archetype:crawl \
       -Dcatalog=$HOME/.m2/archetype-catalog.xml

   #Verify the mvn setup
   $ mvn help:describe \
       -DgroupId=com.oracle.servicebus.plugin \
       -DartifactId=oracle-servicebus-plugin \
       -Dversion=12.2.1-4-0
   ```

1. Build the Oracle Service Bus Archive (`sbconfig.sbar`)

   Build `sbconfig.sbar` for your sample deployment available at `/composites/mavenproject/HelloWorldSB`:
      ```
      $ cd /composites/mavenproject/HelloWorldSB
      $ mvn com.oracle.servicebus.plugin:oracle-servicebus-plugin:package
      ```
   The Service Bus Archive (SBAR) will be generated at `/composites/mavenproject/HelloWorldSB/.data/maven/sbconfig.sbar`.

1. Deploy the generated `sbconfig.sbar` into the Oracle Service Bus instance. For example, if the Administration URL is `http://soainfra-adminserver:7001` with credentials `username`: weblogic and `password`: Welcome1, enter the following commands:
:
   ```
   $ cd /composites/mavenproject/HelloWorldSB
   $ mvn pre-integration-test   \
       -DoracleServerUrl=t3://soainfra-adminserver:7001 \
       -DoracleUsername=weblogic -DoraclePassword=Welcome1
   ```


### Ant based build and deploy
> Note: Make sure to execute these commands inside the `soadeploy` pod.
#### For Oracle SOA Suite composite applications

1. Build an Oracle SOA Suite composite application using Ant. For example, if the composite application to be deployed is available at  `/composites/antproject/Project`, enter the following commands:
   ```
   $ cd /u01/oracle/soa/bin
   $ ant -f ant-sca-package.xml \
         -DcompositeDir=/composites/antproject/Project \
         -DcompositeName=Project \
         -Drevision=0.1
   ```

   The SOA Archive is generated at `/composites/antproject/Project/deploy/sca_Project_rev0.1.jar`, which will be used for deploying.


1. Deploy into the Oracle SOA Suite instance using Ant:
   ```
   $ cd /u01/oracle/soa/bin
   $ ant -f ant-sca-deploy.xml \
         -DserverURL=http://soainfra-cluster-soa-cluster:8001  \
         -DsarLocation=/composites/antproject/Project/deploy/sca_Project_rev0.1.jar \
         -Doverwrite=true \
         -Duser=weblogic -Dpassword=Welcome1
   ```

#### For Oracle Service Bus composite applications

See [Developing Services Using Oracle Service Bus](https://docs.oracle.com/en/middleware/soa-suite/service-bus/12.2.1.4/develop/importing-and-exporting-resources-and-configurations.html#GUID-B4B84A13-FDED-4A2B-8AD8-597B92DC12E9) to deploy Oracle Service Bus composite applications using Ant.
