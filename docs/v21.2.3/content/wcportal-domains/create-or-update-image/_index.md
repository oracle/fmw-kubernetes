+++
title=  "Create or update an image"
date = 2019-04-18T06:46:23-05:00
weight = 4
pre = "<b>4. </b>"
description = "Create or update an Oracle WebCenter Portal Docker image used for deploying Oracle WebCenter Portal domains. An Oracle WebCenter Portal Docker image can be created using the WebLogic Image Tool or using the Dockerfile approach."
+++

You can build an Oracle WebCenter Portal image for production deployments with patches (bundle or interim) using the WebLogic Image Tool, you must have access to the My Oracle Support (MOS) to download (bundle or interim) patches. 

* [Create or update an Oracle WebCenter Portal Docker image using the WebLogic Image Tool](#create-or-update-an-oracle-webcenter-portal-docker-image-using-the-weblogic-image-tool)
    * [Set up the WebLogic Image Tool](#set-up-the-weblogic-image-tool)
    * [Create an image](#create-an-image)
    * [Update an image](#update-an-image)
* [Create an Oracle WebCenter Portal Docker image using Dockerfile](#create-an-oracle-webcenter-portal-docker-image-using-dockerfile)


### Create or update an Oracle WebCenter Portal Docker image using the WebLogic Image Tool

Using the WebLogic Image Tool, you can [create]({{< relref "/wcportal-domains/create-or-update-image/#create-an-image" >}}) a new Oracle WebCenter Portal Docker image (can include patches as well) or [update]({{< relref "/wcportal-domains/create-or-update-image/#update-an-image" >}}) an existing image with one or more patches (bundle patch and interim patches).

> **Recommendations:**
>  * Use [create]({{< relref "/wcportal-domains/create-or-update-image/#create-an-image" >}}) for creating a new Oracle WebCenter Portal Docker image:
>    *  without any patches
>    *  or, containing the Oracle WebCenter Portal binaries, bundle , and interim patches. This is the recommended approach if you have access to the Oracle WebCenter Portal patches because it optimizes the size of the image.
>  * Use [update]({{< relref "/wcportal-domains/create-or-update-image/#update-an-image" >}}) for patching an existing Oracle WebCenter Portal Docker image with a single interim patch. Note that the patched image size may increase considerably due to additional image layers introduced by the patch application tool.  



* [Prerequisites](#prerequisites)
* [Set up the WebLogic Image Tool](#set-up-the-weblogic-image-tool)
* [Validate the setup](#validate-the-setup)
* [WebLogic Image Tool build directory](#weblogic-image-tool-build-directory)
* [WebLogic Image Tool cache](#weblogic-image-tool-cache)
* [Set up additional build scripts](#set-up-additional-build-scripts)

##### Prerequisites

Verify that your environment meets the following prerequisites:

* Docker client and daemon on the build machine, with minimum Docker version 18.03.1.ce.
* Bash version 4.0 or later, to enable the <tab> command complete feature.
* JAVA_HOME environment variable set to the appropriate JDK location.

##### Set up the WebLogic Image Tool

To set up the WebLogic Image Tool:

1. Create a working directory and change to it. In these steps, this directory is `imagetool-setup`.
    ```bash
    $ mkdir imagetool-setup
    $ cd imagetool-setup
    ```
1. Download the latest version of the WebLogic Image Tool from the [releases page](https://github.com/oracle/weblogic-image-tool/releases/latest).
1. Unzip the release ZIP file to the `imagetool-setup` directory.
1. Execute the following commands to set up the WebLogic Image Tool on a Linux environment:

    ```bash
    $ cd imagetool-setup/imagetool/bin
    $ source setup.sh
    ```

##### Validate the setup
To validate the setup of the WebLogic Image Tool:

1. Enter the following command to retrieve the version of the WebLogic Image Tool:

    ``` bash
    $ imagetool --version
    ```

2. Enter `imagetool` then press the Tab key to display the available `imagetool` commands:

    ``` bash
    $ imagetool <TAB>
    cache   create  help    rebase  update
    ```

##### WebLogic Image Tool build directory

The WebLogic Image Tool creates a temporary Docker context directory, prefixed by `wlsimgbuilder_temp`, every time the tool runs. Under normal circumstances, this context directory is deleted. However, if the process is aborted or the tool is unable to remove the directory, it is safe for you to delete it manually. By default, the WebLogic Image Tool creates the Docker context directory under the user's home directory. If you prefer to use a different directory for the temporary context, set the environment variable `WLSIMG_BLDDIR`:

``` bash
$ export WLSIMG_BLDDIR="/path/to/buid/dir"
```

##### WebLogic Image Tool cache

The WebLogic Image Tool maintains a local file cache store. This store is used to look up where the Java, WebLogic Server installers, and WebLogic Server patches reside in the local file system. By default, the cache store is located in the user's `$HOME/cache` directory. Under this directory, the lookup information is stored in the `.metadata` file. All automatically downloaded patches also reside in this directory. You can change the default cache store location by setting the environment variable `WLSIMG_CACHEDIR`:

```bash
$ export WLSIMG_CACHEDIR="/path/to/cachedir"
```

##### Set up additional build scripts

To create an Oracle WebCenter Portal Docker image using the WebLogic Image Tool, additional container scripts for Oracle WebCenter Portal domains are required.
1. Clone the [docker-images](https://github.com/oracle/docker-images.git) repository to set up those scripts. In these steps, this directory is `DOCKER_REPO`:

    ```bash
    $ cd imagetool-setup
    $ git clone https://github.com/oracle/docker-images.git
    ```
1. Copy the additional WebLogic Image Tool build files from the operator source repository to the `imagetool-setup` location:

    ```bash
    $ mkdir -p imagetool-setup/docker-images/OracleWebCenterPortal/imagetool/12.2.1.4.0
    $ cd imagetool-setup/docker-images/OracleWebCenterPortal/imagetool/12.2.1.4.0
    $ cp -rf ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/imagetool-scripts/* .
    ```
>Note: To create the image, continue with the following steps. To update the image, see  [update an image](#update-an-image).

#### Create an image
After [setting up the WebLogic Image Tool]({{< relref "/wcportal-domains/create-or-update-image/#set-up-the-weblogic-image-tool" >}}) and configuring the required build scripts, create a new Oracle WebCenter Portal Docker image using the WebLogic Image Tool as described ahead.

##### Download the Oracle WebCenter Portal installation binaries and patches

You must download the required Oracle WebCenter Portal installation binaries and patches listed below from the [Oracle Software Delivery Cloud](https://edelivery.oracle.com/) and save them in a directory of your choice. In these steps, the directory is `download location`.

The installation binaries and patches required for release 21.2.3  are:

* JDK:  
    * jdk-8u281-linux-x64.tar.gz

* Fusion Middleware Infrastructure installer:  
    * fmw_12.2.1.4.0_infrastructure.jar

* WCP installers:  
    * fmw_12.2.1.4.0_wcportal.jar

* Fusion Middleware Infrastructure patches:  
    * p28186730_139425_Generic.zip (OPatch)
    * p32253037_122140_Generic.zip(WLS)
    * p31544353_122140_Linux-x86-64.zip(WLS ADR Patch)
    * p32124456_122140_Generic.zip(Bundle patch for Oracle Coherence Version 12.2.1.4.7)
    * p31666198_122140_Generic.zip(OPSS Bundle Patch 12.2.1.4.200724)
    * p32357288_122140_Generic.zip(ADF BUNDLE PATCH 12.2.1.4.210107)
    
* WCP patches:   
    * p32224021_122140_Generic.zip(WCP BUNDLE PATCH 12.2.1.4.201126)
    * p31852495_122140_Generic.zip(WEBCENTER CORE BUNDLE PATCH 12.2.1.4.200905))
 
##### Update required build files

The following files in the code repository location `<imagetool-setup-location>/docker-images/OracleWebCenterPortal/imagetool/12.2.1.4.0` are used for creating the image:

* `additionalBuildCmds.txt`
* `buildArgs`

1. In the `buildArgs` file, update all occurrences of `%DOCKER_REPO%` with the `docker-images` repository location, which is the complete path of `<imagetool-setup-location>/docker-images`.

   For example, update:

   `%DOCKER_REPO%/OracleWebCenterPortal/imagetool/12.2.1.4.0/`

   to:  

   `<imagetool-setup-location>/docker-images/OracleWebCenterPortal/imagetool/12.2.1.4.0/`


1. Similarly, update the placeholders `%JDK_VERSION%` and `%BUILDTAG%` with appropriate values.

1. Update the response file `<imagetool-setup-location>/docker-images/OracleFMWInfrastructure/dockerfiles/12.2.1.4/install.file` to add the parameter `INSTALL_TYPE="Fusion Middleware Infrastructure"` in the `[GENERIC]` section.


##### Create the image

1. Add a JDK package to the WebLogic Image Tool cache:

    ``` bash
    $ imagetool cache addInstaller --type jdk --version 8u281 --path <download location>/jdk-8u281-linux-x64.tar.gz
    ```

1. Add the downloaded installation binaries to the WebLogic Image Tool cache:

    ``` bash
    $ imagetool cache addInstaller --type fmw --version 12.2.1.4.0 --path <download location>/fmw_12.2.1.4.0_infrastructure.jar

    $ imagetool cache addInstaller --type wcp --version 12.2.1.4.0 --path <download location>/fmw_12.2.1.4.0_wcportal.jar

    ```
1. Add the downloaded OPatch patch to the WebLogic Image Tool cache:

    ``` bash
    $ imagetool cache addEntry --key 28186730_13.9.4.2.5 --value <download location>/p28186730_139425_Generic.zip
    ```

1. Append the `--opatchBugNumber` flag and the OPatch patch key to the `create` command in the `buildArgs` file:

    ``` bash
    --opatchBugNumber 28186730_13.9.4.2.5
    ```

1. Add the downloaded product patches to the WebLogic Image Tool cache:  

    ``` bash
    $ imagetool cache addEntry --key 32253037_12.2.1.4.0 --value <download location>/p32253037_122140_Generic.zip

    $ imagetool cache addEntry --key 32124456_12.2.1.4.0 --value <download location>/p32124456_122140_Generic.zip
   
    $ imagetool cache addEntry --key 32357288_12.2.1.4.0 --value <download location>/p32357288_122140_Generic.zip

    $ imagetool cache addEntry --key 32224021_12.2.1.4.0 --value <download location>/p32224021_122140_Generic.zip
   
    $ imagetool cache addEntry --key 31666198_12.2.1.4.0 --value <download location>/p31666198_122140_Generic.zip
    
    $ imagetool cache addEntry --key 31544353_12.2.1.4.0 --value <download location>/p31544353_122140_Linux-x86-64.zip
   
   $ imagetool cache addEntry --key 31852495_12.2.1.4.0 --value <download location>/p31852495_122140_Generic.zip
    ```

1. Append the `--patches` flag and the product patch keys to the `create` command in the `buildArgs` file. The `--patches` list must be a comma-separated collection of patch `--key` values used in the `imagetool cache addEntry` commands above.

   Sample `--patches` list for the product patches added in to the cache:

      ```
      --patches 32253037_12.2.1.4.0,32124456_12.2.1.4.0,32357288_12.2.1.4.0,32224021_12.2.1.4.0
      ```

    Example `buildArgs` file after appending the OPatch patch and product patches:

    ```
    create
    --jdkVersion=8u281
    --type wcp
    --version=12.2.1.4.0
    --tag=oracle/wcportal:12.2.1.4
    --pull
    --additionalBuildCommands <imagetool-setup-location>/docker-images/OracleWebCenterPortal/imagetool/12.2.1.4.0/additionalBuildCmds.txt
    --additionalBuildFiles <imagetool-setup-location>/docker-images/OracleWebCenterPortal/dockerfiles/12.2.1.4/container-scripts
    --opatchBugNumber 28186730_13.9.4.2.5
    --patches 32253037_12.2.1.4.0,32124456_12.2.1.4.0,32357288_12.2.1.4.0,32224021_12.2.1.4.0,31666198_12.2.1.4.0,31544353_12.2.1.4.0,31852495_12.2.1.4.0
    ```
    >Note: In the `buildArgs` file:  
    > * `--jdkVersion` value must match the `--version` value used in the `imagetool cache addInstaller` command for `--type jdk`.  
    > * `--version` value must match the `--version` value used in the `imagetool cache addInstaller` command for `--type wcp`.  
    > * `--pull` always pulls the latest base Linux image `oraclelinux:7-slim` from the Docker registry. This flag can be removed if you want to use the Linux image `oraclelinux:7-slim`, which is already available on the host where the WCP image is created.

    Refer to [this page](https://github.com/oracle/weblogic-image-tool/blob/master/site/create-image.md) for the complete list of options available with the WebLogic Image Tool `create` command.

1. Create the Oracle WebCenter Portal image:

    ```bash
    $ imagetool @<absolute path to buildargs file>
    ```
    >Note: Make sure that the absolute path to the `buildargs` file is prepended with a `@` character, as shown in the example above.

    For example:

    ```bash
    $ imagetool @<imagetool-setup-location>/docker-images/OracleWebCenterPortal/imagetool/12.2.1.4.0/buildArgs
    ```

    {{%expand "Click here to see the sample Dockerfile generated with the imagetool command." %}}
        ########## BEGIN DOCKERFILE ##########
        #
        # Copyright (c) 2019, 2021, Oracle and/or its affiliates.
        #
        # Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
        #
        #
        FROM ghcr.io/oracle/oraclelinux:7-slim as os_update
        LABEL com.oracle.weblogic.imagetool.buildid="dabe3ff7-ec35-4b8d-b62a-c3c02fed5571"
        USER root
        
        RUN yum -y --downloaddir=/tmp/imagetool install gzip tar unzip libaio jq hostname procps sudo zip  \
         && yum -y --downloaddir=/tmp/imagetool clean all \
         && rm -rf /var/cache/yum/* \
         && rm -rf /tmp/imagetool
        
        ## Create user and group
        RUN if [ -z "$(getent group oracle)" ]; then hash groupadd &> /dev/null && groupadd oracle || exit -1 ; fi \
         && if [ -z "$(getent passwd oracle)" ]; then hash useradd &> /dev/null && useradd -g oracle oracle || exit -1; fi \
         && mkdir -p /u01 \
         && chown oracle:oracle /u01 \
         && chmod 775 /u01
        
        # Install Java
        FROM os_update as jdk_build
        LABEL com.oracle.weblogic.imagetool.buildid="dabe3ff7-ec35-4b8d-b62a-c3c02fed5571"
        
        ENV JAVA_HOME=/u01/jdk
        
        COPY --chown=oracle:oracle jdk-8u251-linux-x64.tar.gz /tmp/imagetool/
        
        USER oracle
        
        
        RUN tar xzf /tmp/imagetool/jdk-8u251-linux-x64.tar.gz -C /u01 \
         && $(test -d /u01/jdk* && mv /u01/jdk* /u01/jdk || mv /u01/graal* /u01/jdk) \
         && rm -rf /tmp/imagetool \
         && rm -f /u01/jdk/javafx-src.zip /u01/jdk/src.zip
        
        
        # Install Middleware
        FROM os_update as wls_build
        LABEL com.oracle.weblogic.imagetool.buildid="dabe3ff7-ec35-4b8d-b62a-c3c02fed5571"
        
        ENV JAVA_HOME=/u01/jdk \
            ORACLE_HOME=/u01/oracle \
            OPATCH_NO_FUSER=true
        
        RUN mkdir -p /u01/oracle \
         && mkdir -p /u01/oracle/oraInventory \
         && chown oracle:oracle /u01/oracle/oraInventory \
         && chown oracle:oracle /u01/oracle
        
        COPY --from=jdk_build --chown=oracle:oracle /u01/jdk /u01/jdk/
        
        COPY --chown=oracle:oracle fmw_12.2.1.4.0_infrastructure.jar fmw.rsp /tmp/imagetool/
        COPY --chown=oracle:oracle fmw_12.2.1.4.0_wcportal.jar wcp.rsp /tmp/imagetool/
        COPY --chown=oracle:oracle oraInst.loc /u01/oracle/
        
            COPY --chown=oracle:oracle p28186730_139425_Generic.zip /tmp/imagetool/opatch/
        
            COPY --chown=oracle:oracle patches/* /tmp/imagetool/patches/
        
        USER oracle
        
        
        RUN echo "INSTALLING MIDDLEWARE" \
         && echo "INSTALLING fmw" \
         &&  \
            /u01/jdk/bin/java -Xmx1024m -jar /tmp/imagetool/fmw_12.2.1.4.0_infrastructure.jar -silent ORACLE_HOME=/u01/oracle \
            -responseFile /tmp/imagetool/fmw.rsp -invPtrLoc /u01/oracle/oraInst.loc -ignoreSysPrereqs -force -novalidation \
         && echo "INSTALLING wcp" \
         &&  \
            /u01/jdk/bin/java -Xmx1024m -jar /tmp/imagetool/fmw_12.2.1.4.0_wcportal.jar -silent ORACLE_HOME=/u01/oracle \
            -responseFile /tmp/imagetool/wcp.rsp -invPtrLoc /u01/oracle/oraInst.loc -ignoreSysPrereqs -force -novalidation \
         && chmod -R g+r /u01/oracle
        
        RUN cd /tmp/imagetool/opatch \
         && /u01/jdk/bin/jar -xf /tmp/imagetool/opatch/p28186730_139425_Generic.zip \
         && /u01/jdk/bin/java -jar /tmp/imagetool/opatch/6880880/opatch_generic.jar -silent -ignoreSysPrereqs -force -novalidation oracle_home=/u01/oracle
        
                # Apply all patches provided at the same time
                RUN /u01/oracle/OPatch/opatch napply -silent -oh /u01/oracle -phBaseDir /tmp/imagetool/patches \
                && test $? -eq 0 \
                && /u01/oracle/OPatch/opatch util cleanup -silent -oh /u01/oracle \
                || (cat /u01/oracle/cfgtoollogs/opatch/opatch*.log && exit 1)
        
        
        
        FROM os_update as final_build
        
        ARG ADMIN_NAME
        ARG ADMIN_HOST
        ARG ADMIN_PORT
        ARG MANAGED_SERVER_PORT
        
        ENV ORACLE_HOME=/u01/oracle \
            JAVA_HOME=/u01/jdk \
            PATH=${PATH}:/u01/jdk/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle
        
        LABEL com.oracle.weblogic.imagetool.buildid="dabe3ff7-ec35-4b8d-b62a-c3c02fed5571"
        
            COPY --from=jdk_build --chown=oracle:oracle /u01/jdk /u01/jdk/
        
        COPY --from=wls_build --chown=oracle:oracle /u01/oracle /u01/oracle/
        
        
        
        USER oracle
        WORKDIR /u01/oracle
        
        #ENTRYPOINT /bin/bash
        
        
            ENV ORACLE_HOME=/u01/oracle \
                SCRIPT_FILE=/u01/oracle/container-scripts/* \
                USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" \
                PATH=$PATH:/usr/java/default/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/container-scripts
        
            USER root
        
            RUN env && \
                mkdir -p /u01/oracle/container-scripts && \
                mkdir -p /u01/oracle/logs && \
                mkdir -p /u01/esHome/esNode && \
                chown oracle:oracle -R /u01 $VOLUME_DIR && \
                chmod a+xr /u01
        
            COPY --chown=oracle:oracle files/container-scripts/ /u01/oracle/container-scripts/
            RUN chmod +xr $SCRIPT_FILE && \
                rm /u01/oracle/oracle_common/lib/ons.jar /u01/oracle/oracle_common/modules/oracle.jdbc/simplefan.jar
        
            USER oracle
            EXPOSE $WCPORTAL_PORT $ADMIN_PORT
        
            WORKDIR ${ORACLE_HOME}
            CMD ["/u01/oracle/container-scripts/configureOrStartAdminServer.sh"]
        
        
        
        ########## END DOCKERFILE ##########

    {{% /expand %}}

1. Check the created image using the `docker images` command:

    ```bash
      $ docker images | grep wcportal
    ```

#### Update an image

After [setting up the WebLogic Image Tool]({{< relref "/wcportal-domains/create-or-update-image/#set-up-the-weblogic-image-tool" >}}) and configuring the build scripts, use the WebLogic Image Tool to `update` an existing Oracle WebCenter Portal Docker image:

1. Enter the following command to add the OPatch patch to the WebLogic Image Tool cache:

   ```bash
   $ imagetool cache addEntry --key 28186730_13.9.4.2.5 --value <downloaded-patches-location>/p28186730_139425_Generic.zip
   ```
1. Execute the `imagetool cache addEntry` command for each patch to add the required patch(es) to the WebLogic Image Tool cache. For example, to add patch `p30761841_122140_Generic.zip`:

    ```bash wrap
    $ imagetool cache addEntry --key=32224021_12.2.1.4.0 --value <downloaded-patches-location>/p32224021_122140_Generic.zip
    ```
1. Provide the following arguments to the WebLogic Image Tool `update` command:

    * `–-fromImage` - Identify the image that needs to be updated. In the example below, the image to be updated is `oracle/wcportal:12.2.1.4`.
    * `–-patches` - Multiple patches can be specified as a comma-separated list.
    * `--tag` - Specify the new tag to be applied for the image being built.

    Refer [here](https://github.com/oracle/weblogic-image-tool/blob/master/site/update-image.md) for the complete list of options available with the WebLogic Image Tool `update` command.

    > Note: The WebLogic Image Tool cache should have the latest OPatch zip. The WebLogic Image Tool updates the OPatch if it is not already updated in the image.

    ##### Examples

    {{%expand "Click here to see the example of update command:" %}}


        $ imagetool update --fromImage oracle/wcportal:12.2.1.4 --tag=wcportal:12.2.1.4-32224021 --patches=32224021_12.2.1.4.0
        [INFO   ] Image Tool build ID: 50f9b9aa-596c-4bae-bdff-c47c16b4c928
        [INFO   ] Temporary directory used for docker build context: /scratch/asirasag/imagetoolcache/builddir/wlsimgbuilder_temp5130105621506307568
        [INFO   ] Using patch 28186730_13.9.4.2.5 from cache: /home/asirasag/imagetool-setup/jars/p28186730_139425_Generic.zip
        [INFO   ] Updating OPatch in final image from version 13.9.4.2.1 to version 13.9.4.2.5
        [WARNING] Skipping patch conflict check, no support credentials provided
        [WARNING] No credentials provided, skipping validation of patches
        [INFO   ] Using patch 32224021_12.2.1.4 from cache: /home/asirasag/imagetool-setup/jars/p32224021_122140_Generic.zip
        [INFO   ] docker cmd = docker build --no-cache --force-rm --tag wcportal:12.2.1.4-32224021 --build-arg http_proxy=http://www-proxy.us.oracle.com:80 --build-arg https_proxy=http://www-proxy.us.oracle.com:80 --build-arg no_proxy=localhost,127.0.0.0/8,.us.oracle.com,.oraclecorp.com,/var/run/docker.sock,100.111.157.155 /scratch/asirasag/imagetoolcache/builddir/wlsimgbuilder_temp5130105621506307568
        Sending build context to Docker daemon  192.4MB
        
        Step 1/9 : FROM oracle/wcportal:12.2.1.4 as final_build
         ---> 5592ff7e5a02
        Step 2/9 : USER root
         ---> Running in 0b3ff2600f11
        Removing intermediate container 0b3ff2600f11
         ---> faad3a32f39c
        Step 3/9 : ENV OPATCH_NO_FUSER=true
         ---> Running in 2beab0bfe88b
        Removing intermediate container 2beab0bfe88b
         ---> 6fd9e1664818
        Step 4/9 : LABEL com.oracle.weblogic.imagetool.buildid="50f9b9aa-596c-4bae-bdff-c47c16b4c928"
         ---> Running in 9a5f8fc172c9
        Removing intermediate container 9a5f8fc172c9
         ---> 499620a1f857
        Step 5/9 : USER oracle
         ---> Running in fe28af056858
        Removing intermediate container fe28af056858
         ---> 3507971c35d5
        Step 6/9 : COPY --chown=oracle:oracle p28186730_139425_Generic.zip /tmp/imagetool/opatch/
         ---> c44c3c7b17f7
        Step 7/9 : RUN cd /tmp/imagetool/opatch     && /u01/jdk/bin/jar -xf /tmp/imagetool/opatch/p28186730_139425_Generic.zip     && /u01/jdk/bin/java -jar /tmp/imagetool/opatch/6880880/opatch_generic.jar -silent -ignoreSysPrereqs -force -novalidation oracle_home=/u01/oracle     && rm -rf /tmp/imagetool
         ---> Running in 8380260fe62d
        Launcher log file is /tmp/OraInstall2021-04-08_05-18-14AM/launcher2021-04-08_05-18-14AM.log.
        Extracting the installer . . . . Done
        Checking if CPU speed is above 300 MHz.   Actual 2195.098 MHz    Passed
        Checking swap space: must be greater than 512 MB.   Actual 14999 MB    Passed
        Checking if this platform requires a 64-bit JVM.   Actual 64    Passed (64-bit not required)
        Checking temp space: must be greater than 300 MB.   Actual 152772 MB    Passed
        Preparing to launch the Oracle Universal Installer from /tmp/OraInstall2021-04-08_05-18-14AM
        Installation Summary
        
        
        Disk Space : Required 34 MB, Available 152,736 MB
        Feature Sets to Install:
                Next Generation Install Core 13.9.4.0.1
                OPatch 13.9.4.2.5
                OPatch Auto OPlan 13.9.4.2.5
        Session log file is /tmp/OraInstall2021-04-08_05-18-14AM/install2021-04-08_05-18-14AM.log
        
        Loading products list. Please wait.
         1%
         40%
        
        Loading products. Please wait.
         
         98%
         99%
        
        Updating Libraries
        
        Starting Installations
         1%
         94%
         95%
         96%
        
        Install pending
        
        Installation in progress
        
         Component : oracle.glcm.logging 1.6.4.0.0
        
        Copying files for oracle.glcm.logging 1.6.4.0.0
        
         Component : oracle.glcm.comdev 7.8.4.0.0
        
        Copying files for oracle.glcm.comdev 7.8.4.0.0
        
         Component : oracle.glcm.dependency 1.8.4.0.0
        
        Copying files for oracle.glcm.dependency 1.8.4.0.0
        
         Component : oracle.glcm.xmldh 3.4.4.0.0
        
        Copying files for oracle.glcm.xmldh 3.4.4.0.0
        
         Component : oracle.glcm.wizard 7.8.4.0.0
        
        Copying files for oracle.glcm.wizard 7.8.4.0.0
        
         Component : oracle.glcm.opatch.common.api 13.9.4.0.0
        
        Copying files for oracle.glcm.opatch.common.api 13.9.4.0.0
        
         Component : oracle.nginst.common 13.9.4.0.0
        
        Copying files for oracle.nginst.common 13.9.4.0.0
        
         Component : oracle.nginst.core 13.9.4.0.0
        
        Copying files for oracle.nginst.core 13.9.4.0.0
        
         Component : oracle.glcm.encryption 2.7.4.0.0
        
        Copying files for oracle.glcm.encryption 2.7.4.0.0
        
         Component : oracle.swd.opatch 13.9.4.2.5
        
        Copying files for oracle.swd.opatch 13.9.4.2.5
        
         Component : oracle.glcm.osys.core 13.9.1.0.0
        
        Copying files for oracle.glcm.osys.core 13.9.1.0.0
        
         Component : oracle.glcm.oplan.core 13.9.4.2.0
        
        Copying files for oracle.glcm.oplan.core 13.9.4.2.0
        
        Install successful
        
        Post feature install pending
        
        Post Feature installing
        
         Feature Set : glcm_common_lib
        
         Feature Set : glcm_common_logging_lib
        
        Post Feature installing glcm_common_lib
        
        Post Feature installing glcm_common_logging_lib
        
         Feature Set : commons-cli_1.3.1.0.0
        
        Post Feature installing commons-cli_1.3.1.0.0
        
         Feature Set : oracle.glcm.opatch.common.api.classpath
        
        Post Feature installing oracle.glcm.opatch.common.api.classpath
        
         Feature Set : glcm_encryption_lib
        
        Post Feature installing glcm_encryption_lib
        
         Feature Set : oracle.glcm.osys.core.classpath
        
        Post Feature installing oracle.glcm.osys.core.classpath
        
         Feature Set : oracle.glcm.oplan.core.classpath
        
        Post Feature installing oracle.glcm.oplan.core.classpath
        
         Feature Set : oracle.glcm.opatchauto.core.classpath
        
        Post Feature installing oracle.glcm.opatchauto.core.classpath
        
         Feature Set : oracle.glcm.opatchauto.core.binary.classpath
        
        Post Feature installing oracle.glcm.opatchauto.core.binary.classpath
        
         Feature Set : oracle.glcm.opatchauto.core.actions.classpath
        
        Post Feature installing oracle.glcm.opatchauto.core.actions.classpath
        
         Feature Set : oracle.glcm.opatchauto.core.wallet.classpath
        
        Post Feature installing oracle.glcm.opatchauto.core.wallet.classpath
        
        Post feature install complete
        
        String substitutions pending
        
        String substituting
        
         Component : oracle.glcm.logging 1.6.4.0.0
        
        String substituting oracle.glcm.logging 1.6.4.0.0
        
         Component : oracle.glcm.comdev 7.8.4.0.0
        
        String substituting oracle.glcm.comdev 7.8.4.0.0
        
         Component : oracle.glcm.dependency 1.8.4.0.0
        
        String substituting oracle.glcm.dependency 1.8.4.0.0
        
         Component : oracle.glcm.xmldh 3.4.4.0.0
        
        String substituting oracle.glcm.xmldh 3.4.4.0.0
        
         Component : oracle.glcm.wizard 7.8.4.0.0
        
        String substituting oracle.glcm.wizard 7.8.4.0.0
        
         Component : oracle.glcm.opatch.common.api 13.9.4.0.0
        
        String substituting oracle.glcm.opatch.common.api 13.9.4.0.0
        
         Component : oracle.nginst.common 13.9.4.0.0
        
        String substituting oracle.nginst.common 13.9.4.0.0
        
         Component : oracle.nginst.core 13.9.4.0.0
        
        String substituting oracle.nginst.core 13.9.4.0.0
        
         Component : oracle.glcm.encryption 2.7.4.0.0
        
        String substituting oracle.glcm.encryption 2.7.4.0.0
        
         Component : oracle.swd.opatch 13.9.4.2.5
        
        String substituting oracle.swd.opatch 13.9.4.2.5
        
         Component : oracle.glcm.osys.core 13.9.1.0.0
        
        String substituting oracle.glcm.osys.core 13.9.1.0.0
        
         Component : oracle.glcm.oplan.core 13.9.4.2.0
        
        String substituting oracle.glcm.oplan.core 13.9.4.2.0
        
        String substitutions complete
        
        Link pending
        
        Linking in progress
        
         Component : oracle.glcm.logging 1.6.4.0.0
        
        Linking oracle.glcm.logging 1.6.4.0.0
        
         Component : oracle.glcm.comdev 7.8.4.0.0
        
        Linking oracle.glcm.comdev 7.8.4.0.0
        
         Component : oracle.glcm.dependency 1.8.4.0.0
        
        Linking oracle.glcm.dependency 1.8.4.0.0
        
         Component : oracle.glcm.xmldh 3.4.4.0.0
        
        Linking oracle.glcm.xmldh 3.4.4.0.0
        
         Component : oracle.glcm.wizard 7.8.4.0.0
        
        Linking oracle.glcm.wizard 7.8.4.0.0
        
         Component : oracle.glcm.opatch.common.api 13.9.4.0.0
        
        Linking oracle.glcm.opatch.common.api 13.9.4.0.0
        
         Component : oracle.nginst.common 13.9.4.0.0
        
        Linking oracle.nginst.common 13.9.4.0.0
        
         Component : oracle.nginst.core 13.9.4.0.0
        
        Linking oracle.nginst.core 13.9.4.0.0
        
         Component : oracle.glcm.encryption 2.7.4.0.0
        
        Linking oracle.glcm.encryption 2.7.4.0.0
        
         Component : oracle.swd.opatch 13.9.4.2.5
        
        Linking oracle.swd.opatch 13.9.4.2.5
        
         Component : oracle.glcm.osys.core 13.9.1.0.0
        
        Linking oracle.glcm.osys.core 13.9.1.0.0
        
         Component : oracle.glcm.oplan.core 13.9.4.2.0
        
        Linking oracle.glcm.oplan.core 13.9.4.2.0
        
        Linking in progress
        
        Link successful
        
        Setup pending
        
        Setup in progress
        
         Component : oracle.glcm.logging 1.6.4.0.0
        
        Setting up oracle.glcm.logging 1.6.4.0.0
        
         Component : oracle.glcm.comdev 7.8.4.0.0
        
        Setting up oracle.glcm.comdev 7.8.4.0.0
        
         Component : oracle.glcm.dependency 1.8.4.0.0
        
        Setting up oracle.glcm.dependency 1.8.4.0.0
        
         Component : oracle.glcm.xmldh 3.4.4.0.0
        
        Setting up oracle.glcm.xmldh 3.4.4.0.0
        
         Component : oracle.glcm.wizard 7.8.4.0.0
        
        Setting up oracle.glcm.wizard 7.8.4.0.0
        
         Component : oracle.glcm.opatch.common.api 13.9.4.0.0
        
        Setting up oracle.glcm.opatch.common.api 13.9.4.0.0
        
         Component : oracle.nginst.common 13.9.4.0.0
        
        Setting up oracle.nginst.common 13.9.4.0.0
        
         Component : oracle.nginst.core 13.9.4.0.0
        
        Setting up oracle.nginst.core 13.9.4.0.0
        
         Component : oracle.glcm.encryption 2.7.4.0.0
        
        Setting up oracle.glcm.encryption 2.7.4.0.0
        
         Component : oracle.swd.opatch 13.9.4.2.5
        
        Setting up oracle.swd.opatch 13.9.4.2.5
        
         Component : oracle.glcm.osys.core 13.9.1.0.0
        
        Setting up oracle.glcm.osys.core 13.9.1.0.0
        
         Component : oracle.glcm.oplan.core 13.9.4.2.0
        
        Setting up oracle.glcm.oplan.core 13.9.4.2.0
        
        Setup successful
        
        Save inventory pending
        
        Saving inventory
         97%
        
        Saving inventory complete
         98%
        
        Configuration complete
        
         Component : glcm_common_logging_lib
        
        Saving the inventory glcm_common_logging_lib
        
         Component : glcm_encryption_lib
        
         Component : oracle.glcm.opatch.common.api.classpath
        
        Saving the inventory oracle.glcm.opatch.common.api.classpath
        
        Saving the inventory glcm_encryption_lib
        
         Component : cieCfg_common_rcu_lib
        
         Component : glcm_common_lib
        
        Saving the inventory cieCfg_common_rcu_lib
        
        Saving the inventory glcm_common_lib
        
         Component : oracle.glcm.logging
        
        Saving the inventory oracle.glcm.logging
        
         Component : cieCfg_common_lib
        
        Saving the inventory cieCfg_common_lib
        
         Component : svctbl_lib
        
        Saving the inventory svctbl_lib
        
         Component : com.bea.core.binxml_dependencies
        
        Saving the inventory com.bea.core.binxml_dependencies
        
         Component : svctbl_jmx_client
        
        Saving the inventory svctbl_jmx_client
        
         Component : cieCfg_wls_shared_lib
        
        Saving the inventory cieCfg_wls_shared_lib
        
         Component : rcuapi_lib
        
        Saving the inventory rcuapi_lib
        
         Component : rcu_core_lib
        
        Saving the inventory rcu_core_lib
        
         Component : cieCfg_wls_lib
        
        Saving the inventory cieCfg_wls_lib
        
         Component : cieCfg_wls_external_lib
        
        Saving the inventory cieCfg_wls_external_lib
        
         Component : cieCfg_wls_impl_lib
        
        Saving the inventory cieCfg_wls_impl_lib
        
         Component : rcu_dependencies_lib
        
        Saving the inventory rcu_dependencies_lib
        
         Component : oracle.fmwplatform.fmwprov_lib
        
        Saving the inventory oracle.fmwplatform.fmwprov_lib
        
         Component : fmwplatform-wlst-dependencies
        
        Saving the inventory fmwplatform-wlst-dependencies
        
         Component : oracle.fmwplatform.ocp_lib
        
        Saving the inventory oracle.fmwplatform.ocp_lib
        
         Component : oracle.fmwplatform.ocp_plugin_lib
        
        Saving the inventory oracle.fmwplatform.ocp_plugin_lib
        
         Component : wlst.wls.classpath
        
        Saving the inventory wlst.wls.classpath
        
         Component : maven.wls.classpath
        
        Saving the inventory maven.wls.classpath
        
         Component : com.oracle.webservices.fmw.ws-assembler
        
        Saving the inventory com.oracle.webservices.fmw.ws-assembler
        
         Component : sdpmessaging_dependencies
        
        Saving the inventory sdpmessaging_dependencies
        
         Component : sdpclient_dependencies
        
        Saving the inventory sdpclient_dependencies
        
         Component : com.oracle.jersey.fmw.client
        
        Saving the inventory com.oracle.jersey.fmw.client
        
         Component : com.oracle.webservices.fmw.client
        
        Saving the inventory com.oracle.webservices.fmw.client
        
         Component : oracle.jrf.wls.classpath
        
        Saving the inventory oracle.jrf.wls.classpath
        
         Component : oracle.jrf.wlst
        
        Saving the inventory oracle.jrf.wlst
        
         Component : fmwshare-wlst-dependencies
        
        Saving the inventory fmwshare-wlst-dependencies
        
         Component : oracle.fmwshare.pyjar
        
        Saving the inventory oracle.fmwshare.pyjar
        
         Component : com.oracle.webservices.wls.jaxws-owsm-client
        
        Saving the inventory com.oracle.webservices.wls.jaxws-owsm-client
        
         Component : glcm_common_logging_lib
        
         Component : glcm_common_lib
        
        Saving the inventory glcm_common_lib
        
         Component : glcm_encryption_lib
        
        Saving the inventory glcm_encryption_lib
        
         Component : oracle.glcm.opatch.common.api.classpath
        
        Saving the inventory oracle.glcm.opatch.common.api.classpath
        
         Component : cieCfg_common_rcu_lib
        
        Saving the inventory cieCfg_common_rcu_lib
        
        Saving the inventory glcm_common_logging_lib
        
         Component : oracle.glcm.logging
        
        Saving the inventory oracle.glcm.logging
        
         Component : cieCfg_common_lib
        
        Saving the inventory cieCfg_common_lib
        
         Component : svctbl_lib
        
        Saving the inventory svctbl_lib
        
         Component : com.bea.core.binxml_dependencies
        
        Saving the inventory com.bea.core.binxml_dependencies
        
         Component : svctbl_jmx_client
        
        Saving the inventory svctbl_jmx_client
        
         Component : cieCfg_wls_shared_lib
        
        Saving the inventory cieCfg_wls_shared_lib
        
         Component : rcuapi_lib
        
        Saving the inventory rcuapi_lib
        
         Component : rcu_core_lib
        
        Saving the inventory rcu_core_lib
        
         Component : cieCfg_wls_lib
        
        Saving the inventory cieCfg_wls_lib
        
         Component : cieCfg_wls_external_lib
        
        Saving the inventory cieCfg_wls_external_lib
        
         Component : cieCfg_wls_impl_lib
        
        Saving the inventory cieCfg_wls_impl_lib
        
         Component : soa_com.bea.core.binxml_dependencies
        
        Saving the inventory soa_com.bea.core.binxml_dependencies
        
         Component : glcm_common_logging_lib
        
        Saving the inventory glcm_common_logging_lib
        
         Component : glcm_common_lib
        
        Saving the inventory glcm_common_lib
        
         Component : glcm_encryption_lib
        
        Saving the inventory glcm_encryption_lib
        
         Component : oracle.glcm.opatch.common.api.classpath
        
         Component : oracle.glcm.oplan.core.classpath
        
        Saving the inventory oracle.glcm.oplan.core.classpath
        
        Saving the inventory oracle.glcm.opatch.common.api.classpath
        
        The install operation completed successfully.
        
        Logs successfully copied to /u01/oracle/.inventory/logs.
        Removing intermediate container 8380260fe62d
         ---> d57be7ffa162
        Step 8/9 : COPY --chown=oracle:oracle patches/* /tmp/imagetool/patches/
         ---> dd421aae5aaf
        Step 9/9 : RUN /u01/oracle/OPatch/opatch napply -silent -oh /u01/oracle -phBaseDir /tmp/imagetool/patches         && test $? -eq 0         && /u01/oracle/OPatch/opatch util cleanup -silent -oh /u01/oracle         || (cat /u01/oracle/cfgtoollogs/opatch/opatch*.log && exit 1)
         ---> Running in 323e7ae70339
        Oracle Interim Patch Installer version 13.9.4.2.5
        Copyright (c) 2021, Oracle Corporation.  All rights reserved.
        
        
        Oracle Home       : /u01/oracle
        Central Inventory : /u01/oracle/.inventory
           from           : /u01/oracle/oraInst.loc
        OPatch version    : 13.9.4.2.5
        OUI version       : 13.9.4.0.0
        Log file location : /u01/oracle/cfgtoollogs/opatch/opatch2021-04-08_05-20-25AM_1.log
        
        
        OPatch detects the Middleware Home as "/u01/oracle"
        
        Verifying environment and performing prerequisite checks...
        OPatch continues with these patches:   32224021
        
        Do you want to proceed? [y|n]
        Y (auto-answered by -silent)
        User Responded with: Y
        All checks passed.
        
        Please shutdown Oracle instances running out of this ORACLE_HOME on the local system.
        (Oracle Home = '/u01/oracle')
        
        
        Is the local system ready for patching? [y|n]
        Y (auto-answered by -silent)
        User Responded with: Y
        Backing up files...
        Applying interim patch '32224021' to OH '/u01/oracle'
        ApplySession: Optional component(s) [ oracle.webcenter.sca, 12.2.1.4.0 ] , [ oracle.webcenter.sca, 12.2.1.4.0 ] , [ oracle.webcenter.ucm, 12.2.1.4.0 ] , [ oracle.webcenter.ucm, 12.2.1.4.0 ]  not present in the Oracle Home or a higher version is found.
        
        Patching component oracle.webcenter.portal, 12.2.1.4...
        
        Patching component oracle.webcenter.portal, 12.2.1.4...
        
        Patching component oracle.rcu.webcenter.portal, 12.2.1.0...
        
        Patching component oracle.rcu.webcenter.portal, 12.2.1.0...
        Patch 32224021 successfully applied.
        Log file location: /u01/oracle/cfgtoollogs/opatch/opatch2021-04-08_05-20-25AM_1.log
        
        OPatch succeeded.
        Oracle Interim Patch Installer version 13.9.4.2.5
        Copyright (c) 2021, Oracle Corporation.  All rights reserved.
        
        
        Oracle Home       : /u01/oracle
        Central Inventory : /u01/oracle/.inventory
           from           : /u01/oracle/oraInst.loc
        OPatch version    : 13.9.4.2.5
        OUI version       : 13.9.4.0.0
        Log file location : /u01/oracle/cfgtoollogs/opatch/opatch2021-04-08_05-27-11AM_1.log
        
        
        OPatch detects the Middleware Home as "/u01/oracle"
        
        Invoking utility "cleanup"
        OPatch will clean up 'restore.sh,make.txt' files and 'scratch,backup' directories.
        You will be still able to rollback patches after this cleanup.
        Do you want to proceed? [y|n]
        Y (auto-answered by -silent)
        User Responded with: Y
        
        Backup area for restore has been cleaned up. For a complete list of files/directories
        deleted, Please refer log file.
        
        OPatch succeeded.
        Removing intermediate container 323e7ae70339
         ---> 0e7c514dcf7b
        Successfully built 0e7c514dcf7b
        Successfully tagged wcportal:12.2.1.4-32224021
        [INFO   ] Build successful. Build time=645s. Image tag=wcportal:12.2.1.4-32224021

   {{% /expand %}}


   {{%expand "Click here to see the example Dockerfile generated by the WebLogic Image Tool with the --dryRun option:" %}}

     $ imagetool update --fromImage oracle/wcportal:12.2.1.4 --tag=wcportal:12.2.1.4-30761841 --patches=30761841_12.2.1.4.0 --dryRun
     [INFO   ] Image Tool build ID: a473ba32-84b6-4374-9425-9e92ac90ee87
     [INFO   ] Temporary directory used for docker build context: /scratch/asirasag/imagetoolcache/builddir/wlsimgbuilder_temp874401188519547557
     [INFO   ] Using patch 28186730_13.9.4.2.5 from cache: /home/asirasag/imagetool-setup/jars/p28186730_139425_Generic.zip
     [INFO   ] Updating OPatch in final image from version 13.9.4.2.1 to version 13.9.4.2.5
     [WARNING] Skipping patch conflict check, no support credentials provided
     [WARNING] No credentials provided, skipping validation of patches
     [INFO   ] Using patch 32224021_12.2.1.4 from cache: /home/asirasag/imagetool-setup/jars/p32224021_122140_Generic.zip
     [INFO   ] docker cmd = docker build --no-cache --force-rm --tag wcportal:12.2.1.4-32224021 --build-arg http_proxy=http://www-proxy.us.oracle.com:80 --build-arg https_proxy=http://www-proxy.us.oracle.com:80 --build-arg no_proxy=localhost,127.0.0.0/8,.us.oracle.com,.oraclecorp.com,/var/run/docker.sock,100.111.157.155 /scratch/asirasag/imagetoolcache/builddir/wlsimgbuilder_temp874401188519547557
     ########## BEGIN DOCKERFILE ##########
     #
     # Copyright (c) 2019, 2021, Oracle and/or its affiliates.
     #
     # Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
     #
     #
     
     FROM oracle/wcportal:12.2.1.4 as final_build
     USER root
     
     ENV OPATCH_NO_FUSER=true
     
     
     LABEL com.oracle.weblogic.imagetool.buildid="a473ba32-84b6-4374-9425-9e92ac90ee87"
     
     USER oracle
     
         COPY --chown=oracle:oracle p28186730_139425_Generic.zip /tmp/imagetool/opatch/
         RUN cd /tmp/imagetool/opatch \
         && /u01/jdk/bin/jar -xf /tmp/imagetool/opatch/p28186730_139425_Generic.zip \
         && /u01/jdk/bin/java -jar /tmp/imagetool/opatch/6880880/opatch_generic.jar -silent -ignoreSysPrereqs -force -novalidation oracle_home=/u01/oracle \
         && rm -rf /tmp/imagetool
     
         COPY --chown=oracle:oracle patches/* /tmp/imagetool/patches/
     
             # Apply all patches provided at the same time
             RUN /u01/oracle/OPatch/opatch napply -silent -oh /u01/oracle -phBaseDir /tmp/imagetool/patches \
             && test $? -eq 0 \
             && /u01/oracle/OPatch/opatch util cleanup -silent -oh /u01/oracle \
             || (cat /u01/oracle/cfgtoollogs/opatch/opatch*.log && exit 1)
     
     ########## END DOCKERFILE ##########
       
    
   {{% /expand %}}


1. Check the built image using the `docker images` command:
    ```bash
      $ docker images | grep wcportal
      wcportal   12.2.1.4-30761841
      2ef2a67a685b        About a minute ago   3.58GB
      $
    ```

### Create an Oracle WebCenter Portal Docker image using Dockerfile

For test and development purposes, you can create an Oracle WebCenter Portal image using the Dockerfile. Consult the [README](https://github.com/oracle/docker-images/blob/master/OracleWebCenterPortal/dockerfiles/README.md) file for important prerequisite steps,
such as building or pulling the Server JRE Docker image, Oracle Fusion Middleware Infrastructure Docker image and downloading the Oracle WebCenter Portal installer and bundle patch binaries.

A prebuilt Oracle Fusion Middleware Infrastructure image, `container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4`, is available at `container-registry.oracle.com`. We recommend that you pull and rename this image to build the Oracle WebCenter Portal image.


  ```bash
    $ docker pull container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4
    $ docker tag container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4  oracle/fmw-infrastructure:12.2.1.4
  ```
To build an Oracle Fusion Middleware Infrastructure image and on top of that the Oracle WebCenter Portal image as a layer, follow these steps:

1. Make a local clone of the sample repository:

    ```bash
    $ git clone https://github.com/oracle/docker-images
    ```

1. Download the Oracle WebCenter Portal installer from the Oracle Technology Network or e-delivery.

   >Note: Copy the installer binaries to the same location as the Dockerfile.

1. Create the Oracle WebCenter Portal image by running the provided script:

    ```bash
    $ cd docker-images/OracleWebCenterPortal/dockerfiles
    $ ./buildDockerImage.sh -v 12.2.1.4 -s
    ```
    The image produced is named `oracle/wcportal:12.2.1.4`. The samples and instructions assume the Oracle WebCenter Portal image is named `oracle/wcportal:12.2.1.4`. You must rename your image to match this name, or update the samples to refer to the image you created.