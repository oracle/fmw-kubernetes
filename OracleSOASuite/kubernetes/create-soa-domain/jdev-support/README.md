# Deploy Oracle SOA Suite and Oracle Service Bus applications using JDeveloper to Oracle SOA Suite on Kubernetes

This section provides details on how to deploy Oracle SOA Suite and Oracle Service Bus composite applications from Oracle JDeveloper to Oracle SOA Suite on Kubernetes environment.

Follow below instructions for performing deployment using JDeveloper to Oracle SOA Suite on Kubernetes environment:

1. First create an Oracle SOA Quickstart container image with below steps:

   a. Download the Oracle SOA Quickstart binaries `fmw_14.1.2.0.0_soa_quickstart_generic.jar` and `fmw_14.1.2.0.0_soa_quickstart_generic2.jar` and copy both binaries into the folder `$WORKDIR/jdev-support/containerfiles`.

   - By default the scripts use `docker` to build the Oracle SOA Quickstart image. To use `podman`, set the below parameters before proceeding to the next step:
      ```
      $ export BUILD_CLI=podman
      $ export BUILD_OPTS="--format docker"
      ```

   - Next you need an Oracle JDK17 image (`container-registry.oracle.com/java/jdk:17`) which can be pulled from the Oracle Container Registry. Navigate to `https://container-registry.oracle.com/ords/ocr/ba/java/jdk`, sign in using your Oracle Account and accept the Oracle Standard Terms. If you do not already have an Oracle Account you will be given the opportunity to create one.

      After accepting the license terms, on your build host use the `docker` or `podman` login command:
      ```
      $ podman login container-registry.oracle.com
      Username: <Oracle Account Username>
      Password: <auth token>
      Login successful.
      ```

   - Once you have successfully logged in, pull the JDK image by running the following command:
      ```
      $ podman pull container-registry.oracle.com/java/jdk:17
      ```

   - Create the Oracle SOA Quickstart image for JDeveloper by running the following command:
   ```
      $ sh build.sh -t 14.1.2.0.0
   ```

   - Above step creates the Oracle SOA Quickstart image `oracle/soajeveloper:14.1.2.0.0` along with required packages for VNC server access.


1. Push the Oracle SOA Quickstart image `oracle/soajeveloper:14.1.2.0.0` to a container registry so that your Kubernetes Cluster hosting the domain can you pull.
   ```
   $ podman tag oracle/soajeveloper:14.1.2.0.0 your-registry.com/oracle/soajeveloper:14.1.2.0.0
   $ podman push your-registry/oracle/soajeveloper:14.1.2.0.0
   ```

1. Place the SOA/Oracle Service Bus composite project at a share location (for example at /share/apps). Make sure to provide oracle user ( uid: 1000 and gid: 0) permission to directory /share/apps, so that it is accessible and writable inside the container.
   ```
   $ sudo chown -R 1000:0 /share/apps
   ```   

1. Create a PersistentVolume and PersistentVolumeClaim (`soadeploy-pv.yaml` and `soadeploy-pvc.yaml`) with your SOA/Oracle Service Bus composite project placed at `/share/apps`.

   a. Create a PersistentVolume with the sample provided (`soadeploy-pv.yaml`), which uses NFS (you can use hostPath or any other supported PV type):

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
         path: "/share/apps"
      ```
      ```
      $ kubectl apply -f soadeploy-pv.yaml
      ```

   b.  Create a PersistentVolumeClaim (`soadeploy-pvc.yaml`):
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
      ```
      $ kubectl apply -f soadeploy-pvc.yaml
      ```

1. Create an image pull secret if a credential is required to pull the image `your-registry.com/oracle/soajeveloper:14.1.2.0.0` by the Kubernetes pod
   ```
   $ kubectl create secret docker-registry image-secret -n <domain-namespace> --docker-server=your-registry.com --docker-username=xxxxxx --docker-password=xxxxxxx  --docker-email=my@company.com
   ```

1. You need to create the JDeveloper environment in the same namespace as the domain namespace using the script `jdev_helper.sh`. 

   ```
   $ cd jdev_support/scripts
   $ ./jdev_helper.sh -h

      This is a helper script for SOA jdeveloper access setup in container environment.

      Please see README.md for more details.

      Usage:

         jdev_helper.sh [-c persistentVolumeClaimName] [-m mountPath]  [-n namespace] [-i image] [-u imagePullPolicy] [-t serviceType] [-d vncpassword] [-k killvnc] [-h]"

         [-c | --claimName]                : Persistent volume claim name.

         [-m | --mountPath]                : Mount path of the persistent volume in jdevhelper deployment.

         [-n | --namespace]                : Domain namespace. Default is 'default'.

         [-i | --image]                    : Container image for the jdevhelper deployment (optional). Default is 'ghcr.io/oracle/oraclelinux:8'.

         [-u | --imagePullPolicy]          : Image pull policy for the helper deployment (optional). Default is 'IfNotPresent'.

         [-p | --imagePullSecret]          : Image pull secret for the helper deployment (optional). Default is 'None'.

         [-t | --serviceType]              : Kubernetes service type for VNC port. Default is 'NodePort'. Supported values are NodePort and LoadBalancer.

         [-d | --vncpassword]              : Password for VNC access. Default is 'vncpassword'.

         [-k | --killvnc                   : Removes the Kubernetes resources created in the namespace created for SOA JDeveloper access through VNC.

         [-h | --help]                     : This help.
   ```
   Sample command with the PersistentVolumeClaim, image pull secret and Oracle SOA Quickstart image created above is:
   ```
   ./jdev_helper.sh -n soans -i your-registry.com/oracle/soajeveloper:14.1.2.0.0  -t NodePort -d welcome -p image-secret -c soadeploy-pvc
   ```
   
   Output:
   ```
   [2024-07-12T10:05:17.250564395Z][INFO] Creating deployment 'jdevhelper' using image 'your-registry.com/oracle/soajeveloper:14.1.2.0.0', persistent volume claim 'soadeploy-pvc' and mount path '/shared'.
   deployment.apps "jdevhelper" deleted
   deployment.apps/jdevhelper created
   service/jdevhelper unchanged
   [2024-07-12T10:05:30.917075513Z][INFO] =========================================== VNC environment details ====================================================
   [2024-07-12T10:05:30.920164769Z][INFO] VNCSERVER started on DISPLAY= <NODE PORT>
   [2024-07-12T10:05:30.921882024Z][INFO] To start using Oracle JDeveloper ==> connect via VNC viewer with <NODE NAME>:<NODE PORT>
   [2024-07-12T10:05:30.924094226Z][INFO]
   [2024-07-12T10:05:30.928925615Z][INFO] Your projects/applications hosted at persistentvolumeClaim soadeploy-pvc, are available for JDeveloper access at /shared
   [2024-07-12T10:05:30.930312223Z][INFO] ========================================================================================================================
   [2024-07-12T10:05:30.931901926Z][INFO] Navigate to the following location from VNCViewer on terminal
   [2024-07-12T10:05:30.933337276Z][INFO] $ cd /u01/oracle/jdeveloper/jdev/bin
   [2024-07-12T10:05:30.934801172Z][INFO]
   [2024-07-12T10:05:30.936312907Z][INFO] For example, to connect to secure Oracle SOA Domain with DemoTrust, run the following command:
   [2024-07-12T10:05:30.939333282Z][INFO] $ ./jdev -J-Dweblogic.security.SSL.ignoreHostnameVerify=true -J-Dweblogic.security.TrustKeyStore=DemoTrust
   [2024-07-12T10:05:30.941008547Z][INFO]
   [2024-07-12T10:05:30.949161692Z][INFO] While creating Application Server Connection, use Administration server pod name and internal configured ports.
   [2024-07-12T10:05:30.951463685Z][INFO] For example 'WebLogic Hostname' value is 'soainfra-adminserver'
   [2024-07-12T10:05:30.956109261Z][INFO] 'SSL Port' is '9002' for secure domain or 'Port' is '7001' for non-secure domain
   [2024-07-12T10:05:30.957739730Z][INFO] ========================================================================================================================
   [2024-07-12T10:05:30.959372215Z][INFO]
   [2024-07-12T10:05:30.960767620Z][INFO]
   [2024-07-12T10:05:30.962397769Z][INFO] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   [2024-07-12T10:05:30.963984357Z][INFO] >>>>>> To cleanup the Kubernetes resources created for Oracle JDeveloper access through VNC
   [2024-07-12T10:05:30.965782926Z][INFO] >>>>>> Run: $ ./jdev_helper.sh -k -n soans
   [2024-07-12T10:05:30.967358203Z][INFO] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   $   
   ```

   Sample command to create a JDeveloper environment with VNC access using password as `welcome` without a presistenceVolumeClaimName:  
   ```
   $ ./jdev_helper.sh -n soans -i your-registry.com/oracle/soajdeveloper:14.1.2.0.0 -t NodePort -d welcome -p image-secret 
   ```

   Sample output:
   ```
    [2024-07-08T17:59:38.277941559Z][INFO] CAUTION!!!! The presistenceVolumeClaimName is not provided. Projects/applications stored in this setup is ephemeral and not persistent
    [2024-07-08T17:59:38.279462462Z][INFO] CAUTION!!!! In case you want the projects/applications created to be persistent, recommended to pass a persistentVolumeClaimName with option -c
    [2024-07-08T17:59:38.281126958Z][INFO] Creating deployment 'jdevhelper' using image 'your-registry.com/oracle/soajdeveloper:14.1.2.0.0', persistent volume claim '' and mount path '/shared'.
    deployment.apps "jdevhelper" deleted
    deployment.apps/jdevhelper created
    service/jdevhelper unchanged
    [2024-07-08T17:59:51.926915480Z][INFO] =========================================== VNC environment details ====================================================
    [2024-07-08T17:59:51.928832925Z][INFO] VNCSERVER started on DISPLAY= <NODE PORT>
    [2024-07-08T17:59:51.930804513Z][INFO] To start using Oracle JDeveloper ==> connect via VNC viewer with <NODE NAME>:<NODE PORT>
    [2024-07-08T17:59:51.932756905Z][INFO]
    [2024-07-08T17:59:51.935113101Z][INFO] Your projects/applications created are ephemeral and not persistent as no persistentvolumeClaim is used
    [2024-07-08T17:59:51.937168808Z][INFO] ========================================================================================================================
    [2024-07-08T17:59:51.940554959Z][INFO] Navigate to the following location from VNCViewer on terminal
    [2024-07-08T17:59:51.942509904Z][INFO] $ cd /u01/oracle/jdeveloper/jdev/bin
    [2024-07-08T17:59:51.944227450Z][INFO]
    [2024-07-08T17:59:51.945968141Z][INFO] For example, to connect to secure Oracle SOA Domain with DemoTrust, run the following command:
    [2024-07-08T17:59:51.948112907Z][INFO] $ ./jdev -J-Dweblogic.security.SSL.ignoreHostnameVerify=true -J-Dweblogic.security.TrustKeyStore=DemoTrust
    [2024-07-08T17:59:51.950122988Z][INFO]
    [2024-07-08T17:59:51.952409522Z][INFO] While creating Application Server Connection, use Administration server pod name and internal configured ports.
    [2024-07-08T17:59:51.954187243Z][INFO] For example 'WebLogic Hostname' value is 'soainfra-adminserver'
    [2024-07-08T17:59:51.955624588Z][INFO] 'SSL Port' is '9002' for secure domain. 'Port' is '7001' for non-secure domain
    [2024-07-08T17:59:51.956996289Z][INFO] ========================================================================================================================
    [2024-07-08T17:59:51.958355926Z][INFO]
    [2024-07-08T17:59:51.959729069Z][INFO]
    [2024-07-08T17:59:51.961092794Z][INFO] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    [2024-07-08T17:59:51.962525360Z][INFO] >>>>>> To cleanup the Kubernetes resources created for Oracle JDeveloper access through VNC
    [2024-07-08T17:59:51.963854601Z][INFO] >>>>>> Run: $ ./jdev_helper.sh -k -n soans
    [2024-07-08T17:59:51.965774791Z][INFO] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    $
   ```

1. To start using Oracle JDeveloper, connect via VNC viewer with `<NODE NAME>:<NODE PORT>` obtained from the `jdev_helper.sh` output.


1. Navigate to the following location from VNCViewer:
   ```
   $ cd /u01/oracle/jdeveloper/jdev/bin
   ```

1. Connect to secure Oracle SOA Domain for example with DemoTrust by running the following command:
   ```
   $ ./jdev -J-Dweblogic.security.SSL.ignoreHostnameVerify=true -J-Dweblogic.security.TrustKeyStore=DemoTrust
   ```

1. While creating Application Server Connection, use Administration server pod name and internal configured ports. For example `WebLogic Hostname` value is `soainfra-adminserver`. For a secure domain `SSL Port` is `9002` and for a non-secure domain `Port` is `7001`.

1. To cleanup the Kubernetes resources created for Oracle JDeveloper access through VNC, run the following command:
   ```
   $ ./jdev_helper.sh -k -n <domain namespace>
   ```

