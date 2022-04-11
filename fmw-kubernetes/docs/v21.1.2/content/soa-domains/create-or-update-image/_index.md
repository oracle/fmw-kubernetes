+++
title=  "Create or update an image"
date = 2019-04-18T06:46:23-05:00
weight = 5
pre = "<b>5. </b>"
description = "Create or update an Oracle SOA Suite Docker image used for deploying Oracle SOA Suite domains. An Oracle SOA Suite Docker image can be created using the WebLogic Image Tool or using the Dockerfile approach."
+++

If you have access to the My Oracle Support (MOS), and there is a need to build a new image with a patch (bundle or interim), it is recommended to use the WebLogic Image Tool to build an Oracle SOA Suite image for production deployments.


* [Create or update an Oracle SOA Suite Docker image using the WebLogic Image Tool](#create-or-update-an-oracle-soa-suite-docker-image-using-the-weblogic-image-tool)
    * [Set up the WebLogic Image Tool](#set-up-the-weblogic-image-tool)
    * [Create an image](#create-an-image)
    * [Update an image](#update-an-image)
* [Create an Oracle SOA Suite Docker image using Dockerfile](#create-an-oracle-soa-suite-docker-image-using-dockerfile)


### Create or update an Oracle SOA Suite Docker image using the WebLogic Image Tool

Using the WebLogic Image Tool, you can [create]({{< relref "/soa-domains/create-or-update-image/#create-an-image" >}}) a new Oracle SOA Suite Docker image (can include patches as well) or [update]({{< relref "/soa-domains/create-or-update-image/#update-an-image" >}}) an existing image with one or more patches (bundle patch and interim patches).

> **Recommendations:**
>  * Use [create]({{< relref "/soa-domains/create-or-update-image/#create-an-image" >}}) for creating a new Oracle SOA Suite Docker image either:
>    *  without any patches
>    *  or, containing the Oracle SOA Suite binaries, bundle patch and interim patches. This is the recommended approach if you have access to the Oracle SOA Suite patches because it optimizes the size of the image.
>  * Use [update]({{< relref "/soa-domains/create-or-update-image/#update-an-image" >}}) for patching an existing Oracle SOA Suite Docker image with a single interim patch. Note that the patched image size may increase considerably due to additional image layers introduced by the patch application tool.  


#### Set up the WebLogic Image Tool

* [Prerequisites](#prerequisites)
* [Set up the WebLogic Image Tool](#set-up-the-weblogic-image-tool)
* [Validate setup](#validate-setup)
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

##### Validate setup
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

The WebLogic Image Tool creates a temporary Docker context directory, prefixed by `wlsimgbuilder_temp`, every time the tool runs. Under normal circumstances, this context directory will be deleted. However, if the process is aborted or the tool is unable to remove the directory, it is safe for you to delete it manually. By default, the WebLogic Image Tool creates the Docker context directory under the user's home directory. If you prefer to use a different directory for the temporary context, set the environment variable `WLSIMG_BLDDIR`:

``` bash
$ export WLSIMG_BLDDIR="/path/to/buid/dir"
```

##### WebLogic Image Tool cache

The WebLogic Image Tool maintains a local file cache store. This store is used to look up where the Java, WebLogic Server installers, and WebLogic Server patches reside in the local file system. By default, the cache store is located in the user's `$HOME/cache` directory. Under this directory, the lookup information is stored in the `.metadata` file. All automatically downloaded patches also reside in this directory. You can change the default cache store location by setting the environment variable `WLSIMG_CACHEDIR`:

```bash
$ export WLSIMG_CACHEDIR="/path/to/cachedir"
```

##### Set up additional build scripts

Creating an Oracle SOA Suite Docker image using the WebLogic Image Tool requires additional container scripts for Oracle SOA Suite domains.

1. Clone the [docker-images](https://github.com/oracle/docker-images.git) repository to set up those scripts. In these steps, this directory is `DOCKER_REPO`:

    ```bash
    $ cd imagetool-setup
    $ git clone https://github.com/oracle/docker-images.git
    ```
1. Copy the additional WebLogic Image Tool build files from the operator source repository to the `imagetool-setup` location:

    ```bash
    $ mkdir -p imagetool-setup/docker-images/OracleSOASuite/imagetool/12.2.1.4.0
    $ cd imagetool-setup/docker-images/OracleSOASuite/imagetool/12.2.1.4.0
    $ cp -rf ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/imagetool-scripts/* .
    ```
>Note: If you want to create the image continue with the following steps, otherwise to update the image see [update an image](#update-an-image).

#### Create an image

After [setting up the WebLogic Image Tool]({{< relref "/soa-domains/create-or-update-image/#set-up-the-weblogic-image-tool" >}}) and required build scripts, follow these steps to use the WebLogic Image Tool to `create` a new Oracle SOA Suite Docker image.

##### Download the Oracle SOA Suite installation binaries and patches

You must download the required Oracle SOA Suite installation binaries and patches as listed below from the [Oracle Software Delivery Cloud](https://edelivery.oracle.com/) and save them in a directory of your choice. In these steps, this directory is `download location`.

The installation binaries and patches required for release 21.1.2  are:

* JDK:  
    * jdk-8u281-linux-x64.tar.gz

* Fusion Middleware Infrastructure installer:  
    * fmw_12.2.1.4.0_infrastructure.jar

* SOA and Oracle Service Bus installers:  
    * fmw_12.2.1.4.0_soa.jar
    * fmw_12.2.1.4.0_osb.jar

* Fusion Middleware Infrastructure patches:  
    * p28186730_139425_Generic.zip (OPatch)
    * p32253037_122140_Generic.zip (WLS PATCH SET UPDATE 12.2.1.4.201209)
    * p31544353_122140_Linux-x86-64.zip (WLS ADR Patch)
    * p32357288_122140_Generic.zip (ADF BUNDLE PATCH 12.2.1.4.210107)
    * p31666198_122140_Generic.zip (OPSS Bundle Patch 12.2.1.4.200724)
    * p32124456_122140_Generic.zip (Bundle patch for Oracle Coherence Version 12.2.1.4.7)
    * p31918617_122140_Generic.zip (One-off WLS)
    * p31287540_122140_Generic.zip (One-off WLS)

* SOA and Oracle Service Bus patches:   

    * p32337168_122140_Generic.zip (SOA Bundle Patch 12.2.1.4.210102)
    * p32121987_122140_Generic.zip (Oracle Service Bus Bundle Patch 12.2.1.4.201105)
    * p31869446_122140_Generic.zip (One-off SOA)
    * p31734213_122140_Generic.zip (One-off SOA)
    * p31534880_122140_Generic.zip (One-off SOA)
    * p31857456_122140_Generic.zip (One-off Oracle Service Bus)

##### Update required build files

The following files in the code repository location `<imagetool-setup-location>/docker-images/OracleSOASuite/imagetool/12.2.1.4.0` are used for creating the image:

* `additionalBuildCmds.txt`
* `buildArgs`

1. In the `buildArgs` file, update all occurrences of `%DOCKER_REPO%` with the `docker-images` repository location, which is the complete path of `<imagetool-setup-location>/docker-images`.

   For example, update:

   `%DOCKER_REPO%/OracleSOASuite/imagetool/12.2.1.4.0/`

   to:  

   `<imagetool-setup-location>/docker-images/OracleSOASuite/imagetool/12.2.1.4.0/`


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

    $ imagetool cache addInstaller --type soa --version 12.2.1.4.0 --path <download location>/fmw_12.2.1.4.0_soa.jar

    $ imagetool cache addInstaller --type osb --version 12.2.1.4.0 --path <download location>/fmw_12.2.1.4.0_osb.jar

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

    $ imagetool cache addEntry --key 31544353_12.2.1.4.0 --value <download location>/p31544353_122140_Linux-x86-64.zip

    $ imagetool cache addEntry --key 32357288_12.2.1.4.0 --value <download location>/p32357288_122140_Generic.zip

    $ imagetool cache addEntry --key 31666198_12.2.1.4.0 --value <download location>/p31666198_122140_Generic.zip

    $ imagetool cache addEntry --key 32124456_12.2.1.4.0 --value <download location>/p32124456_122140_Generic.zip

    $ imagetool cache addEntry --key 31918617_12.2.1.4.0 --value <download location>/p31918617_122140_Generic.zip

    $ imagetool cache addEntry --key 31287540_12.2.1.4.0 --value <download location>/p31287540_122140_Generic.zip

    $ imagetool cache addEntry --key 32337168_12.2.1.4.0 --value <download location>/p32337168_122140_Generic.zip

    $ imagetool cache addEntry --key 32121987_12.2.1.4.0 --value <download location>/p32121987_122140_Generic.zip

    $ imagetool cache addEntry --key 31869446_12.2.1.4.0 --value <download location>/p31869446_122140_Generic.zip

    $ imagetool cache addEntry --key 31734213_12.2.1.4.0 --value <download location>/p31734213_122140_Generic.zip

    $ imagetool cache addEntry --key 31534880_12.2.1.4.0 --value <download location>/p31534880_122140_Generic.zip

    $ imagetool cache addEntry --key 31857456_12.2.1.4.0 --value <download location>/p31857456_122140_Generic.zip

    ```

1. Append the `--patches` flag and the product patch keys to the `create` command in the `buildArgs` file. The `--patches` list must be a comma-separated collection of patch `--key` values used in the `imagetool cache addEntry` commands above.

   Sample `--patches` list for the product patches added in to the cache:

      ```
      --patches 31287540_12.2.1.4.0,31534880_12.2.1.4.0,31544353_12.2.1.4.0,31666198_12.2.1.4.0,31734213_12.2.1.4.0,31857456_12.2.1.4.0,31869446_12.2.1.4.0,31918617_12.2.1.4.0,32121987_12.2.1.4.0,32124456_12.2.1.4.0,32253037_12.2.1.4.0,32337168_12.2.1.4.0,32357288_12.2.1.4.0
      ```

    Example `buildArgs` file after appending the OPatch patch and product patches:

    ```
    create
    --jdkVersion=8u281
    --type soa_osb
    --version=12.2.1.4.0
    --tag=oracle/soasuite:12.2.1.4
    --pull
    --additionalBuildCommands <imagetool-setup-location>/docker-images/OracleSOASuite/imagetool/12.2.1.4.0/additionalBuildCmds.txt
    --additionalBuildFiles <imagetool-setup-location>/docker-images/OracleSOASuite/dockerfiles/12.2.1.4/container-scripts
    --installerResponseFile <imagetool-setup-location>/docker-images/OracleFMWInfrastructure/dockerfiles/12.2.1.4/install.file,<imagetool-setup-location>/docker-images/OracleSOASuite/dockerfiles/12.2.1.4/install/soasuite.response,<imagetool-setup-location>/docker-images/OracleSOASuite/dockerfiles/12.2.1.4/install/osb.response
    --opatchBugNumber 28186730_13.9.4.2.5
    --patches 31287540_12.2.1.4.0,31534880_12.2.1.4.0,31544353_12.2.1.4.0,31666198_12.2.1.4.0,31734213_12.2.1.4.0,31857456_12.2.1.4.0,31869446_12.2.1.4.0,31918617_12.2.1.4.0,32121987_12.2.1.4.0,32124456_12.2.1.4.0,32253037_12.2.1.4.0,32337168_12.2.1.4.0,32357288_12.2.1.4.0
    ```
    >Note: In the `buildArgs` file:  
    > * `--jdkVersion` value must match the `--version` value used in the `imagetool cache addInstaller` command for `--type jdk`.  
    > * `--version` value must match the `--version` value used in the `imagetool cache addInstaller` command for `--type soa`.  
    > * `--pull` always pulls the latest base Linux image `oraclelinux:7-slim` from the Docker registry. This flag can be removed if you want to use the Linux image `oraclelinux:7-slim`, which is already available on the host where the SOA image is created.

    Refer to [this page](https://github.com/oracle/weblogic-image-tool/blob/master/site/create-image.md) for the complete list of options available with the WebLogic Image Tool `create` command.

1. Create the Oracle SOA Suite image:

    ```bash
    $ imagetool @<absolute path to buildargs file>
    ```
    >Note: Make sure that the absolute path to the `buildargs` file is prepended with a `@` character, as shown in the example above.

    For example:

    ```bash
    $ imagetool @<imagetool-setup-location>/docker-images/OracleSOASuite/imagetool/12.2.1.4.0/buildArgs
    ```

    {{%expand "Click here to see the sample Dockerfile generated with the `imagetool` command." %}}


    ########## BEGIN DOCKERFILE ##########
    #
    # Copyright (c) 2019, 2020, Oracle and/or its affiliates.
    #
    # Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
    #
    #
    FROM oraclelinux:7-slim as OS_UPDATE
    LABEL com.oracle.weblogic.imagetool.buildid="9870685f-6bd4-44db-b959-3308121211f6"
    USER root

    RUN yum -y --downloaddir=/tmp/imagetool install gzip tar unzip libaio jq \
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
    FROM OS_UPDATE as JDK_BUILD
    LABEL com.oracle.weblogic.imagetool.buildid="9870685f-6bd4-44db-b959-3308121211f6"

    ENV JAVA_HOME=/u01/jdk

    COPY --chown=oracle:oracle jdk-8u281-linux-x64.tar.gz /tmp/imagetool/

    USER oracle


    RUN tar xzf /tmp/imagetool/jdk-8u281-linux-x64.tar.gz -C /u01 \
    && $(test -d /u01/jdk* && mv /u01/jdk* /u01/jdk || mv /u01/graal* /u01/jdk) \
    && rm -rf /tmp/imagetool \
    && rm -f /u01/jdk/javafx-src.zip /u01/jdk/src.zip


    # Install Middleware
    FROM OS_UPDATE as WLS_BUILD
    LABEL com.oracle.weblogic.imagetool.buildid="9870685f-6bd4-44db-b959-3308121211f6"

    ENV JAVA_HOME=/u01/jdk \
        ORACLE_HOME=/u01/oracle \
        OPATCH_NO_FUSER=true

    RUN mkdir -p /u01/oracle \
    && mkdir -p /u01/oracle/oraInventory \
    && chown oracle:oracle /u01/oracle/oraInventory \
    && chown oracle:oracle /u01/oracle

    COPY --from=JDK_BUILD --chown=oracle:oracle /u01/jdk /u01/jdk/

    COPY --chown=oracle:oracle fmw_12.2.1.4.0_infrastructure.jar install.file /tmp/imagetool/
    COPY --chown=oracle:oracle fmw_12.2.1.4.0_soa.jar soasuite.response /tmp/imagetool/
    COPY --chown=oracle:oracle fmw_12.2.1.4.0_osb.jar osb.response /tmp/imagetool/
    COPY --chown=oracle:oracle oraInst.loc /u01/oracle/

        COPY --chown=oracle:oracle p28186730_139425_Generic.zip /tmp/imagetool/opatch/

        COPY --chown=oracle:oracle patches/* /tmp/imagetool/patches/

    USER oracle


    RUN echo "INSTALLING MIDDLEWARE" \
    && echo "INSTALLING fmw" \
    &&  \
        /u01/jdk/bin/java -Xmx1024m -jar /tmp/imagetool/fmw_12.2.1.4.0_infrastructure.jar -silent ORACLE_HOME=/u01/oracle \
        -responseFile /tmp/imagetool/install.file -invPtrLoc /u01/oracle/oraInst.loc -ignoreSysPrereqs -force -novalidation \
    && echo "INSTALLING soa" \
    &&  \
        /u01/jdk/bin/java -Xmx1024m -jar /tmp/imagetool/fmw_12.2.1.4.0_soa.jar -silent ORACLE_HOME=/u01/oracle \
        -responseFile /tmp/imagetool/soasuite.response -invPtrLoc /u01/oracle/oraInst.loc -ignoreSysPrereqs -force -novalidation \
    && echo "INSTALLING osb" \
    &&  \
        /u01/jdk/bin/java -Xmx1024m -jar /tmp/imagetool/fmw_12.2.1.4.0_osb.jar -silent ORACLE_HOME=/u01/oracle \
        -responseFile /tmp/imagetool/osb.response -invPtrLoc /u01/oracle/oraInst.loc -ignoreSysPrereqs -force -novalidation \
    && chmod -R g+r /u01/oracle

    RUN cd /tmp/imagetool/opatch \
    && /u01/jdk/bin/jar -xf /tmp/imagetool/opatch/p28186730_139425_Generic.zip \
    && /u01/jdk/bin/java -jar /tmp/imagetool/opatch/6880880/opatch_generic.jar -silent -ignoreSysPrereqs -force -novalidation oracle_home=/u01/oracle

            # Apply all patches provided at the same time
            RUN /u01/oracle/OPatch/opatch napply -silent -oh /u01/oracle -phBaseDir /tmp/imagetool/patches \
            && test $? -eq 0 \
            && /u01/oracle/OPatch/opatch util cleanup -silent -oh /u01/oracle \
            || (cat /u01/oracle/cfgtoollogs/opatch/opatch*.log && exit 1)



    FROM OS_UPDATE as FINAL_BUILD

    ARG ADMIN_NAME
    ARG ADMIN_HOST
    ARG ADMIN_PORT
    ARG MANAGED_SERVER_PORT

    ENV ORACLE_HOME=/u01/oracle \
        JAVA_HOME=/u01/jdk \
        PATH=${PATH}:/u01/jdk/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle

    LABEL com.oracle.weblogic.imagetool.buildid="9870685f-6bd4-44db-b959-3308121211f6"

        COPY --from=JDK_BUILD --chown=oracle:oracle /u01/jdk /u01/jdk/

    COPY --from=WLS_BUILD --chown=oracle:oracle /u01/oracle /u01/oracle/



    USER oracle
    WORKDIR /u01/oracle

    #ENTRYPOINT /bin/bash


        ENV ORACLE_HOME=/u01/oracle \
            VOLUME_DIR=/u01/oracle/user_projects \
            SCRIPT_FILE=/u01/oracle/container-scripts/* \
            HEALTH_SCRIPT_FILE=/u01/oracle/container-scripts/get_healthcheck_url.sh \
            JAVA_OPTIONS="-Doracle.jdbc.fanEnabled=false -Dweblogic.StdoutDebugEnabled=false" \
            PATH=$PATH:/usr/java/default/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/container-scripts

        USER root
        RUN mkdir -p $VOLUME_DIR && chown oracle:oracle /u01 $VOLUME_DIR && \
            mkdir -p /u01/oracle/container-scripts && \
            yum install -y hostname ant && \
            rm -rf /var/cache/yum

        #COPY container-scripts/* /u01/oracle/container-scripts/
        COPY --chown=oracle:oracle files/container-scripts/ /u01/oracle/container-scripts/
        RUN chmod +xr $SCRIPT_FILE

        USER oracle
        HEALTHCHECK --start-period=5m --interval=1m CMD curl -k -s --fail `$HEALTH_SCRIPT_FILE` || exit 1
        WORKDIR ${ORACLE_HOME}
        CMD ["/u01/oracle/container-scripts/createDomainAndStart.sh"]

    ########## END DOCKERFILE ##########

    {{% /expand %}}

1. Check the created image using the `docker images` command:

    ```bash
      $ docker images | grep soasuite
    ```

#### Update an image

After [setting up the WebLogic Image Tool]({{< relref "/soa-domains/create-or-update-image/#set-up-the-weblogic-image-tool" >}}) and required build scripts, use the WebLogic Image Tool to `update` an existing Oracle SOA Suite Docker image:

1. Enter the following command to add the OPatch patch to the WebLogic Image Tool cache:

   ```bash
   $ imagetool cache addEntry --key 28186730_13.9.4.2.5 --value <downloaded-patches-location>/p28186730_139425_Generic.zip
   ```
1. Execute the `imagetool cache addEntry` command for each patch to add the required patch(es) to the WebLogic Image Tool cache. For example, to add patch `p30761841_122140_Generic.zip`:

    ```bash wrap
    $ imagetool cache addEntry --key=30761841_12.2.1.4.0 --value <downloaded-patches-location>/p30761841_122140_Generic.zip
    ```
1. Provide the following arguments to the WebLogic Image Tool `update` command:

    * `–-fromImage` - Identify the image that needs to be updated. In the example below, the image to be updated is `soasuite:12.2.1.4`.
    * `–-patches` - Multiple patches can be specified as a comma-separated list.
    * `--tag` - Specify the new tag to be applied for the image being built.

    Refer [here](https://github.com/oracle/weblogic-image-tool/blob/master/site/update-image.md) for the complete list of options available with the WebLogic Image Tool `update` command.

    > Note: The WebLogic Image Tool cache should have the latest OPatch zip. The WebLogic Image Tool will update the OPatch if it is not already updated in the image.

    ##### Examples

    {{%expand "Click here to see the example 'update' command:" %}}


    $ imagetool update --fromImage soasuite:12.2.1.4 --tag=soasuite:12.2.1.4-30761841 --patches=30761841_12.2.1.4.0

      [INFO   ] Image Tool build ID: bd21dc73-b775-4186-ae03-8219bf02113e
      [INFO   ] Temporary directory used for docker build context: <work-directory>/wlstmp/wlsimgbuilder_temp1117031733123594064
      [INFO   ] Using patch 28186730_13.9.4.2.2 from cache: <downloaded-patches-location>/p28186730_139422_Generic.zip
      [WARNING] skipping patch conflict check, no support credentials provided
      [WARNING] No credentials provided, skipping validation of patches
      [INFO   ] Using patch 30761841_12.2.1.4.0 from cache: <downloaded-patches-location>/p30761841_122140_Generic.zip
      [INFO   ] docker cmd = docker build --force-rm=true --no-cache --tag soasuite:12.2.1.4-30761841 --build-arg http_proxy=http://<YOUR-COMPANY-PROXY> --build-arg https_proxy=http://<YOUR-COMPANY-PROXY> --build-arg no_proxy=<IP addresses and Domain address for no_proxy>,/var/run/docker.sock <work-directory>/wlstmp/wlsimgbuilder_temp1117031733123594064
      Sending build context to Docker daemon  53.47MB

      Step 1/7 : FROM soasuite:12.2.1.4 as FINAL_BUILD
      ---> 445b649a3459
      Step 2/7 : USER root
      ---> Running in 27f45e6958c3
      Removing intermediate container 27f45e6958c3
      ---> 150ae0161d46
      Step 3/7 : ENV OPATCH_NO_FUSER=true
      ---> Running in daddfbb8fd9e
      Removing intermediate container daddfbb8fd9e
      ---> a5fc6b74be39
      Step 4/7 : LABEL com.oracle.weblogic.imagetool.buildid="bd21dc73-b775-4186-ae03-8219bf02113e"
      ---> Running in cdfec79c3fd4
      Removing intermediate container cdfec79c3fd4
      ---> 4c773aeb956f
      Step 5/7 : USER oracle
      ---> Running in ed3432e43e89
      Removing intermediate container ed3432e43e89
      ---> 54fe6b07c447
      Step 6/7 : COPY --chown=oracle:oracle patches/* /tmp/imagetool/patches/
      ---> d6d12f02a9be
      Step 7/7 : RUN /u01/oracle/OPatch/opatch napply -silent -oh /u01/oracle -phBaseDir /tmp/imagetool/patches     && /u01/oracle/OPatch/opatch util cleanup -silent -oh /u01/oracle     && rm -rf /tmp/imagetool
      ---> Running in a79addca4d2f
      Oracle Interim Patch Installer version 13.9.4.2.2
      Copyright (c) 2020, Oracle Corporation.  All rights reserved.


      Oracle Home       : /u01/oracle
      Central Inventory : /u01/oracle/oraInventory
        from           : /u01/oracle/oraInst.loc
      OPatch version    : 13.9.4.2.2
      OUI version       : 13.9.4.0.0
      Log file location : /u01/oracle/cfgtoollogs/opatch/opatch2020-06-01_10-56-13AM_1.log


      OPatch detects the Middleware Home as "/u01/oracle"

      Verifying environment and performing prerequisite checks...
      OPatch continues with these patches:   30761841

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
      Applying interim patch '30761841' to OH '/u01/oracle'
      ApplySession: Optional component(s) [ oracle.org.bouncycastle.bcprov.ext.jdk15on, 1.55.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.ext.jdk15on, 1.55.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.ext.jdk15on, 1.5.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.ext.jdk15on, 1.5.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.55.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.55.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.52.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.52.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.ext.jdk15on, 1.48.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.ext.jdk15on, 1.48.0.0.0 ] , [ oracle.org.bouncycastle.bcpkix.jdk15on, 1.49.0.0.0 ] , [ oracle.org.bouncycastle.bcpkix.jdk15on, 1.49.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.51.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.51.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.54.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.54.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.ext.jdk15on, 1.54.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.ext.jdk15on, 1.54.0.0.0 ] , [ oracle.org.bouncycastle.bcpkix.jdk15on, 1.5.0.0.0 ] , [ oracle.org.bouncycastle.bcpkix.jdk15on, 1.5.0.0.0 ] , [ oracle.org.bouncycastle.bcpkix.jdk15on, 1.54.0.0.0 ] , [ oracle.org.bouncycastle.bcpkix.jdk15on, 1.54.0.0.0 ] , [ oracle.org.bouncycastle.bcpkix.jdk15on, 1.55.0.0.0 ] , [ oracle.org.bouncycastle.bcpkix.jdk15on, 1.55.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.49.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.49.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.5.0.0.0 ] , [ oracle.org.bouncycastle.bcprov.jdk15on, 1.5.0.0.0 ]  not present in the Oracle Home or a higher version is found.

      Patching component oracle.org.bouncycastle.bcprov.jdk15on, 1.60.0.0.0...

      Patching component oracle.org.bouncycastle.bcprov.jdk15on, 1.60.0.0.0...

      Patching component oracle.org.bouncycastle.bcprov.ext.jdk15on, 1.60.0.0.0...

      Patching component oracle.org.bouncycastle.bcprov.ext.jdk15on, 1.60.0.0.0...

      Patching component oracle.org.bouncycastle.bcpkix.jdk15on, 1.60.0.0.0...

      Patching component oracle.org.bouncycastle.bcpkix.jdk15on, 1.60.0.0.0...
      Patch 30761841 successfully applied.
      Log file location: /u01/oracle/cfgtoollogs/opatch/opatch2020-06-01_10-56-13AM_1.log

      OPatch succeeded.
      Oracle Interim Patch Installer version 13.9.4.2.2
      Copyright (c) 2020, Oracle Corporation.  All rights reserved.


      Oracle Home       : /u01/oracle
      Central Inventory : /u01/oracle/oraInventory
        from           : /u01/oracle/oraInst.loc
      OPatch version    : 13.9.4.2.2
      OUI version       : 13.9.4.0.0
      Log file location : /u01/oracle/cfgtoollogs/opatch/opatch2020-06-01_10-57-19AM_1.log


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
      Removing intermediate container a79addca4d2f
      ---> 2ef2a67a685b
      Successfully built 2ef2a67a685b
      Successfully tagged soasuite:12.2.1.4-30761841
      [INFO   ] Build successful. Build time=112s. Image tag=soasuite:12.2.1.4-30761841

    {{% /expand %}}


    {{%expand "Click here to see the example Dockerfile generated by the WebLogic Image Tool with the '--dryRun' option:" %}}

    $ imagetool update --fromImage soasuite:12.2.1.4 --tag=soasuite:12.2.1.4-30761841 --patches=30761841_12.2.1.4.0 --dryRun

    [INFO ] Image Tool build ID: f9feea35-c52c-4974-b155-eb7f34d95892
    [INFO ] Temporary directory used for docker build context: <work-directory>/wlstmp/wlsimgbuilder_temp1799120592903014749
    [INFO ] Using patch 28186730_13.9.4.2.2 from cache: <downloaded-patches-location>/p28186730_139422_Generic.zip
    [WARNING] skipping patch conflict check, no support credentials provided
    [WARNING] No credentials provided, skipping validation of patches
    [INFO ] Using patch 30761841_12.2.1.4.0 from cache: <downloaded-patches-location>/p30761841_122140_Generic.zip
    [INFO ] docker cmd = docker build --force-rm=true --no-cache --tag soasuite:12.2.1.4-30761841 --build-arg http_proxy=http://www.yourcompany.proxy.com:80 --build-arg https_proxy=http://www.yourcompany.proxy.com:80 --build-arg no_proxy=10.250.109.251,localhost,127.0.0.1,/var/run/docker.sock <work-directory>/wlstmp/wlsimgbuilder_temp1799120592903014749
    ########## BEGIN DOCKERFILE ##########
    #
    # Copyright (c) 2019, 2020, Oracle and/or its affiliates.
    #
    # Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
    #
    #

    FROM soasuite:12.2.1.4 as FINAL_BUILD
    USER root

    ENV OPATCH_NO_FUSER=true


    LABEL com.oracle.weblogic.imagetool.buildid="f9feea35-c52c-4974-b155-eb7f34d95892"

    USER oracle


    COPY --chown=oracle:oracle patches/* /tmp/imagetool/patches/

    RUN /u01/oracle/OPatch/opatch napply -silent -oh /u01/oracle -phBaseDir /tmp/imagetool/patches \
    && /u01/oracle/OPatch/opatch util cleanup -silent -oh /u01/oracle \
    && rm -rf /tmp/imagetool




    ########## END DOCKERFILE ##########

  {{% /expand %}}


1. Check the built image using the `docker images` command:
    ```bash
      $ docker images | grep soasuite
      soasuite   12.2.1.4-30761841
      2ef2a67a685b        About a minute ago   4.84GB
      $
    ```

### Create an Oracle SOA Suite Docker image using Dockerfile

For test and development purposes, you can create an Oracle SOA Suite image using the Dockerfile. Consult the [README](https://github.com/oracle/docker-images/blob/master/OracleSOASuite/dockerfiles/README.md) file for important prerequisite steps,
such as building or pulling the Server JRE Docker image, Oracle FMW Infrastructure Docker image, and downloading the Oracle SOA Suite installer and bundle patch binaries.

A prebuilt Oracle Fusion Middleware Infrastructure image, `container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4`, is available at `container-registry.oracle.com`. We recommend that you pull and rename this image to build the Oracle SOA Suite image.


  ```bash
    $ docker pull container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4
    $ docker tag container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4  oracle/fmw-infrastructure:12.2.1.4
  ```

Follow these steps to build an Oracle Fusion Middleware Infrastructure image, and then the Oracle SOA Suite image as a layer on top of that:

1. Make a local clone of the sample repository:

    ```bash
    $ git clone https://github.com/oracle/docker-images
    ```
1. Build the `oracle/fmw-infrastructure:12.2.1.4` image:

   ```bash
    $ cd docker-images/OracleFMWInfrastructure/dockerfiles
    $ sh buildDockerImage.sh -v 12.2.1.4 -s
   ```
   This will produce an image named `oracle/fmw-infrastructure:12.2.1.4`.

1. Download the Oracle SOA Suite installer from the Oracle Technology Network or e-delivery.

   >Note: Copy the installer binaries to the same location as the Dockerfile.

1. To build the Oracle SOA Suite image with patches, you must download and drop the patch zip files (for example, `p29928100_122140_Generic.zip`) into the `patches/` folder under the version that is required. For example, for `12.2.1.4.0` the folder is `12.2.1.4/patches`. Similarly, to build the image by including the OPatch patch, download and drop the OPatch patch zip file (for e.g. `p28186730_139424_Generic.zip`) into the `opatch_patch/` folder.

1. Create the Oracle SOA Suite image by running the provided script:

    ```bash
    $ cd docker-images/OracleSOASuite/dockerfiles
    $ ./buildDockerImage.sh -v 12.2.1.4 -s
    ```

    The image produced will be named `oracle/soasuite:12.2.1.4`. The samples and instructions assume the Oracle SOA Suite image is named `soasuite:12.2.1.4`. You must rename your image to match this name, or update the samples to refer to the image you created.

    ```bash
    $ docker tag oracle/soasuite:12.2.1.4 soasuite:12.2.1.4
    ```
