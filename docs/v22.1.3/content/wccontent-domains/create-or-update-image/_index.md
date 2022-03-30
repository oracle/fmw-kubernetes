+++
title = "Create or update an image"
date = 2021-02-14T16:43:45-05:00
weight = 5
pre = "<b>5. </b>"
description = "Create or update an Oracle WebCenter Content Docker image used for deploying Oracle WebCenter Content domains. An Oracle WebCenter Content Docker image can be created using the WebLogic Image Tool or using the Dockerfile approach."
+++

If you have access to the My Oracle Support (MOS), and there is a need to build a new image with a patch (bundle or interim), it is recommended to use the WebLogic Image Tool to build an Oracle WebCenter Content image for production deployments.


* [Create or update an Oracle WebCenter Content Docker image using the WebLogic Image Tool](#create-or-update-an-oracle-webcenter-content-docker-image-using-the-weblogic-image-tool)
    * [Set up the WebLogic Image Tool](#set-up-the-weblogic-image-tool)
    * [Create an image](#create-an-image)
    * [Update an image](#update-an-image)
* [Create an Oracle WebCenter Content Docker image using Dockerfile](#create-an-oracle-webcenter-content-docker-image-using-dockerfile)


### Create or update an Oracle WebCenter Content Docker image using the WebLogic Image Tool

Using the WebLogic Image Tool, you can [create]({{< relref "/wccontent-domains/create-or-update-image/#create-an-image" >}}) a new Oracle WebCenter Content Docker image (can include patches as well) or [update]({{< relref "/wccontent-domains/create-or-update-image/#update-an-image" >}}) an existing image with one or more patches (bundle patch and interim patches).

> **Recommendations:**
>  * Use [create]({{< relref "/wccontent-domains/create-or-update-image/#create-an-image" >}}) for creating a new Oracle WebCenter Content Docker image either:
>    *  without any patches
>    *  or, containing the Oracle WebCenter Content binaries, bundle patch and interim patches. This is the recommended approach if you have access to the Oracle WebCenter Content patches because it optimizes the size of the image.
>  * Use [update]({{< relref "/wccontent-domains/create-or-update-image/#update-an-image" >}}) for patching an existing Oracle WebCenter Content Docker image with a single interim patch. Note that the patched image size may increase considerably due to additional image layers introduced by the patch application tool.  


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

Creating an Oracle WebCenter Content Docker image using the WebLogic Image Tool requires additional container scripts for Oracle WebCenter Content domains.

1. Clone the [docker-images](https://github.com/oracle/docker-images.git) repository to set up those scripts. In these steps, this directory is `DOCKER_REPO`:

    ```bash
    $ cd imagetool-setup
    $ git clone https://github.com/oracle/docker-images.git
    ```
1. Copy the additional WebLogic Image Tool build files from the WebLogic Kubernetes Operator source repository to the `imagetool-setup` location:

    ```bash
    $ mkdir -p imagetool-setup/docker-images/WebCenterContent/imagetool/12.2.1.4.0
    $ cd imagetool-setup/docker-images/WebCenterContent/imagetool/12.2.1.4.0
    $ cp -rf ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/imagetool-scripts/* .
    ```

#### Create an image

After [setting up the WebLogic Image Tool]({{< relref "/wccontent-domains/create-or-update-image/#set-up-the-weblogic-image-tool" >}}) and required build scripts, follow these steps to use the WebLogic Image Tool to `create` a new Oracle WebCenter Content Docker image.

##### Download the Oracle WebCenter Content installation binaries and patches

You must download the required Oracle WebCenter Content installation binaries and patches as listed below from the [Oracle Software Delivery Cloud](https://edelivery.oracle.com/) and save them in a directory of your choice. In these steps, this directory is `download location`.

{{%expand "Click here to see the sample list of installation binaries and patches:" %}}
* JDK:  
    * jdk-8u251-linux-x64.tar.gz

* Fusion MiddleWare Infrastructure installer:  
    * fmw_12.2.1.4.0_infrastructure_generic.jar

* WebCenter Content installers:  
    * fmw_12.2.1.4.0_wccontent.jar    
	
* Fusion MiddleWare Infrastructure patches:  
    * p28186730_139424_Generic-23574493.zip (Opatch)    

* WebCenter Content patches:   
    * p31390302_122140_Generic.zip (wcc)
    
{{% /expand %}}

>Note: This is a sample list of patches. You must get the appropriate list of patches for your Oracle WebCenter Content image.

##### Update required build files

The following files available in the code repository location `<imagetool-setup-location>/docker-images/OracleWebCenterContent/imagetool/12.2.1.4.0` 
are used for creating the image.
* `additionalBuildCmds.txt`
* `buildArgs`

1. In the `buildArgs` file, update all the occurrences of `%DOCKER_REPO%` with the `docker-images` repository location, which is the complete path of `imagetool-setup/docker-images`.

   For example, update:

   `%DOCKER_REPO%/OracleWebCenterContent/imagetool/12.2.1.4.0/`

   to:  
   `<imagetool-setup-location>/docker-images/OracleWebCenterContent/imagetool/12.2.1.4.0/`


1. Similarly, update the placeholders `%JDK_VERSION%` and `%BUILDTAG%` with appropriate values.


##### Create the image

1. Add a JDK package to the WebLogic Image Tool cache:

    ``` bash
    $ imagetool cache addInstaller --type jdk --version 8u251 --path <download location>/jdk-8u251-linux-x64.tar.gz
    ```

1. Add the downloaded installation binaries to the WebLogic Image Tool cache:

    ``` bash
    $ imagetool cache addInstaller --type fmw --version 12.2.1.4.0 --path <download location>/fmw_12.2.1.4.0_infrastructure.jar

    $ imagetool cache addInstaller --type wcc --version 12.2.1.4.0 --path <download location>/fmw_12.2.1.4.0_wccontent.jar

    ```
1. Add the downloaded patches to the WebLogic Image Tool cache:

    {{%expand "Click here to see the commands to add patches in to the cache:" %}}
    ``` bash
    $ imagetool cache addEntry --key p33578966_122140_Generic --path <download location>/p33578966_122140_Generic.zip

    $ imagetool cache addEntry --key 28186730_13.9.4.2.8 --path <download location>/p28186730_139428_Generic-24497645.zip 
    
	```
   {{% /expand  %}}

1. Update the patches list to `buildArgs`.

    To the `create` command in the `buildArgs` file, append the Oracle WebCenter Content patches list using the `--patches` flag and Opatch patch using the `--opatchBugNumber` flag. Sample options for the list of patches above are:

    ```
    --patches 33578966_12.2.1.4.0
    --opatchBugNumber=28186730_13.9.4.2.8
    ```

   Example `buildArgs` file after appending product's list of patches and Opatch patch:

    ```
    create
    --jdkVersion=8u251
    --type WCC
    --version=12.2.1.4.0
    --tag=oracle/wccontent_create_1015:12.2.1.4.0
    --pull
    --chown oracle:root
    --additionalBuildCommands <imagetool-setup-location>/docker-images/OracleWebCenterContent/imagetool/12.2.1.4.0/additionalBuildCmds.txt
    --additionalBuildFiles <imagetool-setup-location>/docker-images/OracleWebCenterContent/dockerfiles/12.2.1.4.0/container-scripts
    --patches 33578966_12.2.1.4.0
	--opatchBugNumber=28186730_13.9.4.2.8
		
    ```

     Refer to [this page](https://oracle.github.io/weblogic-image-tool/userguide/tools/create-image/) for the complete list of options available with the WebLogic Image Tool `create` command.

1. Enter the following command to create the Oracle WebCenter Content image:

      ```bash
      $ imagetool @<absolute path to `buildargs` file>"
      ```

{{%expand "Click here to see the sample Dockerfile generated with the imagetool command." %}}

```bash
########## BEGIN DOCKERFILE ##########
#
# Copyright (c) 2019, 2021, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
#
FROM ghcr.io/oracle/oraclelinux:7-slim as os_update
LABEL com.oracle.weblogic.imagetool.buildid="f46ab190-077e-4ed7-b747-7bb170fe592c"
USER root

RUN yum -y --downloaddir=/tmp/imagetool install gzip tar unzip libaio jq hostname  \
 && yum -y --downloaddir=/tmp/imagetool clean all \
 && rm -rf /var/cache/yum/* \
 && rm -rf /tmp/imagetool

## Create user and group
RUN if [ -z "$(getent group root)" ]; then hash groupadd &> /dev/null && groupadd root || exit -1 ; fi \
 && if [ -z "$(getent passwd oracle)" ]; then hash useradd &> /dev/null && useradd -g root oracle || exit -1; fi \
 && mkdir -p /u01 \
 && chown oracle:root /u01 \
 && chmod 775 /u01

# Install Java
FROM os_update as jdk_build
LABEL com.oracle.weblogic.imagetool.buildid="f46ab190-077e-4ed7-b747-7bb170fe592c"

ENV JAVA_HOME=/u01/jdk

COPY --chown=oracle:root jdk-8u251-linux-x64.tar.gz /tmp/imagetool/

USER oracle


RUN tar xzf /tmp/imagetool/jdk-8u251-linux-x64.tar.gz -C /u01 \
 && $(test -d /u01/jdk* && mv /u01/jdk* /u01/jdk || mv /u01/graal* /u01/jdk) \
 && rm -rf /tmp/imagetool \
 && rm -f /u01/jdk/javafx-src.zip /u01/jdk/src.zip


# Install Middleware
FROM os_update as wls_build
LABEL com.oracle.weblogic.imagetool.buildid="f46ab190-077e-4ed7-b747-7bb170fe592c"

ENV JAVA_HOME=/u01/jdk \
    ORACLE_HOME=/u01/oracle \
    OPATCH_NO_FUSER=true

RUN mkdir -p /u01/oracle \
 && mkdir -p /u01/oracle/oraInventory \
 && chown oracle:root /u01/oracle/oraInventory \
 && chown oracle:root /u01/oracle

COPY --from=jdk_build --chown=oracle:root /u01/jdk /u01/jdk/

COPY --chown=oracle:root fmw_12.2.1.4.0_infrastructure_generic.jar fmw.rsp /tmp/imagetool/
COPY --chown=oracle:root fmw_12.2.1.4.0_wccontent.jar wcc.rsp /tmp/imagetool/
COPY --chown=oracle:root oraInst.loc /u01/oracle/



USER oracle


RUN echo "INSTALLING MIDDLEWARE" \
 && echo "INSTALLING fmw" \
 &&  \
    /u01/jdk/bin/java -Xmx1024m -jar /tmp/imagetool/fmw_12.2.1.4.0_infrastructure_generic.jar -silent ORACLE_HOME=/u01/oracle \
    -responseFile /tmp/imagetool/fmw.rsp -invPtrLoc /u01/oracle/oraInst.loc -ignoreSysPrereqs -force -novalidation \
 && echo "INSTALLING wcc" \
 &&  \
    /u01/jdk/bin/java -Xmx1024m -jar /tmp/imagetool/fmw_12.2.1.4.0_wccontent.jar -silent ORACLE_HOME=/u01/oracle \
    -responseFile /tmp/imagetool/wcc.rsp -invPtrLoc /u01/oracle/oraInst.loc -ignoreSysPrereqs -force -novalidation \
 && chmod -R g+r /u01/oracle





FROM os_update as final_build

ARG ADMIN_NAME
ARG ADMIN_HOST
ARG ADMIN_PORT
ARG MANAGED_SERVER_PORT

ENV ORACLE_HOME=/u01/oracle \
    JAVA_HOME=/u01/jdk \
    PATH=${PATH}:/u01/jdk/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle

LABEL com.oracle.weblogic.imagetool.buildid="f46ab190-077e-4ed7-b747-7bb170fe592c"

    COPY --from=jdk_build --chown=oracle:root /u01/jdk /u01/jdk/

COPY --from=wls_build --chown=oracle:root /u01/oracle /u01/oracle/



USER oracle
WORKDIR /u01/oracle

#ENTRYPOINT /bin/bash



    ENV ORACLE_HOME=/u01/oracle \
        VOLUME_DIR=/u01/oracle/user_projects \
        SCRIPT_FILE=/u01/oracle/container-scripts/* \
        USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" \
        PATH=$PATH:$JAVA_HOME/bin:$ORACLE_HOME/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/container-scripts

    USER root

    RUN mkdir -p $VOLUME_DIR && \
        mkdir -p /u01/oracle/container-scripts && \
        mkdir -p /u01/oracle/silent-install-files-tmp/config && \
        mkdir -p /u01/oracle/logs && \
        chown oracle:root -R /u01 $VOLUME_DIR && \
        chmod a+xr /u01
    COPY --chown=oracle:root files/container-scripts/ /u01/oracle/container-scripts/
    RUN chmod +xr $SCRIPT_FILE


    USER oracle

    EXPOSE $UCM_PORT $UCM_INTRADOC_PORT $IBR_INTRADOC_PORT $IBR_PORT $ADMIN_PORT
    WORKDIR ${ORACLE_HOME}

    CMD ["/u01/oracle/container-scripts/createDomainandStartAdmin.sh"]

########## END DOCKERFILE ##########
```
{{% /expand %}}

1. Check the created image using the `docker images` command:

    ```bash
      $ docker images | grep wcc
    ```

#### Update an image

After [setting up the WebLogic Image Tool]({{< relref "/wccontent-domains/create-or-update-image/#set-up-the-weblogic-image-tool" >}}) and required build scripts, use the WebLogic Image Tool to `update` an existing Oracle WebCenter Content Docker image:

1. Enter the following command for each patch to add the required patch(es) to the WebLogic Image Tool cache:

    ```bash wrap
    $  cd <imagetool-setup>
    $ imagetool cache addEntry --key=33578966_12.2.1.4.0 --value <downloaded-patches-location>/p33578966_122140_Generic.zip
    [INFO   ] Added entry 33578966_12.2.1.4.0=<downloaded-patches-location>/p33578966_122140_Generic.zip
    ```
1. Provide the following arguments to the WebLogic Image Tool `update` command:

    * `–-fromImage` - Identify the image that needs to be updated. In the example below, the image to be updated is `wccontent:12.2.1.4.0`.
    * `–-patches` - Multiple patches can be specified as a comma-separated list.
    * `--tag` - Specify the new tag to be applied for the image being built.

    Refer [here](https://oracle.github.io/weblogic-image-tool/userguide/tools/update-image/) for the complete list of options available with the WebLogic Image Tool `update` command.

    > Note: The WebLogic Image Tool cache should have the latest OPatch zip. The WebLogic Image Tool will update the OPatch if it is not already updated in the image.

    ##### Examples

{{%expand "Click here to see the example `update` command:" %}}

```
  # If you are using a pre-built Oracle WebCenter Content image, obtained from My Oracle Support, then please use this command:
  $ imagetool update --fromImage oracle/wccontent:12.2.1.4.0 --tag=oracle/wccontent_update_1015:12.2.1.4.0 --patches=33578966_12.2.1.4.0 --opatchBugNumber=28186730_13.9.4.2.8

  # In case, you chose to build an Oracle WebCenter Content image, please use the command given below:
  $ imagetool update --chown oracle:root --fromImage oracle/wccontent:12.2.1.4.0 --tag=oracle/wccontent_update_1015:12.2.1.4.0 --patches=33578966_12.2.1.4.0 
    --opatchBugNumber=28186730_13.9.4.2.8
      
```
 {{% /expand %}}

1. Check the built image using the `docker images` command:
    ```bash
      $ docker images | grep wcc
 
    ```

### Create an Oracle WebCenter Content Docker image using Dockerfile

For test and development purposes, you can create an Oracle WebCenter Content image using the Dockerfile. Consult the [README](https://github.com/oracle/docker-images/blob/master/OracleWebCenterContent/dockerfiles/README.md) file for important prerequisite steps,
such as building or pulling the Server JRE Docker image, Oracle FMW Infrastructure Docker image, and downloading the Oracle WebCenter Content installer and bundle patch binaries.

A prebuilt Oracle Fusion Middleware Infrastructure image, `container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4-210407`, is available at `container-registry.oracle.com`. We recommend that you pull and rename this image to build the Oracle WebCenter Content image.


  ```bash
    $ docker pull container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4-210407
    $ docker tag  container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4-210407 oracle/fmw-infrastructure:12.2.1.4.0
  
  ```

Follow these steps to build an Oracle WebCenter Content image :

1. Make a local clone of the sample repository:

    ```bash
    $ git clone https://github.com/oracle/docker-images
    ```

1. Download the Oracle WebCenter Content installer from the Oracle Technology Network or e-delivery.

   >Note: Copy the installer binaries to the same location as the Dockerfile.


1. Create the Oracle WebCenter Content image by running the provided script:

    ```bash
    $ cd docker-images/OracleWebCenterContent/dockerfiles
    $ ./buildDockerImage.sh -v 12.2.1.4 -s
    ```

    The image produced will be named `oracle/wccontent:12.2.1.4`. The samples and instructions assume the Oracle WebCenter Content image is named `wccontent:12.2.1.4.0`. You must rename your image to match this name, or update the samples to refer to the image you created.

    ```bash
    $ docker tag oracle/wccontent:12.2.1.4 wccontent:12.2.1.4.0
    ```
