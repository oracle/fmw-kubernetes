+++
title=  "Create or update an image"
date = 2019-04-18T06:46:23-05:00
weight = 5
pre = "<b>5. </b>"
description = "Create or update an Oracle WebCenter Sites Docker image used for deploying Oracle WebCenter Sites domains. An Oracle WebCenter Sites Docker image can be created using the WebLogic Image Tool or using the Dockerfile approach."
+++

If you have access to the My Oracle Support (MOS), and there is a need to build a new image with a patch (bundle or interim), it is recommended to use the WebLogic Image Tool to build an Oracle WebCenter Sites image for production deployments.


* [Create or update an Oracle WebCenter Sites Docker image using the WebLogic Image Tool](#create-or-update-an-oracle-wcsites-suite-docker-image-using-the-weblogic-image-tool)
    * [Set up the WebLogic Image Tool](#set-up-the-weblogic-image-tool)
    * [Create an image](#create-an-image)
    * [Update an image](#update-an-image)
* [Create an Oracle WebCenter Sites Docker image using Dockerfile](#create-an-oracle-wcsites-suite-docker-image-using-dockerfile)


### Create or update an Oracle WebCenter Sites Docker image using the WebLogic Image Tool

Using the WebLogic Image Tool, you can [create]({{< relref "/wcsites-domains/create-or-update-image/#create-an-image" >}}) a new Oracle WebCenter Sites Docker image (can include patches as well) or [update]({{< relref "/wcsites-domains/create-or-update-image/#update-an-image" >}}) an existing image with one or more patches (bundle patch and interim patches).

> **Recommendations:**
>  * Use [create]({{< relref "/wcsites-domains/create-or-update-image/#create-an-image" >}}) for creating a new Oracle WebCenter Sites Docker image either:
>    *  without any patches
>    *  or, containing the Oracle WebCenter Sites binaries, bundle patch and interim patches. This is the recommended approach if you have access to the Oracle WebCenter Sites patches because it optimizes the size of the image.
>  * Use [update]({{< relref "/wcsites-domains/create-or-update-image/#update-an-image" >}}) for patching an existing Oracle WebCenter Sites Docker image with a single interim patch. Note that the patched image size may increase considerably due to additional image layers introduced by the patch application tool.  


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

Creating an Oracle WebCenter Sites Docker image using the WebLogic Image Tool requires additional container scripts for Oracle WebCenter Sites domains.

1. Clone the [docker-images](https://github.com/oracle/docker-images.git) repository to set up those scripts. In these steps, this directory is `DOCKER_REPO`:

    ```bash
    $ cd imagetool-setup
    $ git clone https://github.com/oracle/docker-images.git
    ```
1. Copy the additional WebLogic Image Tool build files from the operator source repository to the `imagetool-setup` location:

    ```bash
    $ mkdir -p imagetool-setup/docker-images/OracleWebCenterSites/imagetool/12.2.1.4
    $ cd imagetool-setup/docker-images/OracleWebCenterSites/imagetool/12.2.1.4
    $ cp -rf ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/imagetool-scripts/* .
    ```

#### Create an image

After [setting up the WebLogic Image Tool]({{< relref "/wcsites-domains/create-or-update-image/#set-up-the-weblogic-image-tool" >}}) and required build scripts, follow these steps to use the WebLogic Image Tool to `create` a new Oracle WebCenter Sites Docker image.


##### Preparing response files 

1. Add INSTALL_TYPE="WebLogic Server" in %path-to-downloaded-docker-repo%/OracleFMWInfrastructure/dockerfiles/12.2.1.4/install.file
1. Rename %path-to-downloaded-docker-repo%/OracleWebCenterSites/dockerfiles/12.2.1.4/install.file to %path-to-downloaded-docker-repo%/OracleWebCenterSites/dockerfiles/12.2.1.4/wcs.file 

##### Create a wcs-wls-docker-install installer

  ```bash
  $ cd %path-to-downloaded-docker-repo%/OracleWebCenterSites/dockerfiles/12.2.1.4/wcs-wls-docker-install
  $ docker run --rm -u root -v ${PWD}:/wcs-wls-docker-install groovy:2.4.8-jdk8 /wcs-wls-docker-install/packagejar.sh

  ```   

##### Download the Oracle WebCenter Sites installation binaries and patches

You must download the required Oracle WebCenter Sites installation binaries and patches as listed below from the [Oracle Software Delivery Cloud](https://edelivery.oracle.com/) and save them in a directory of your choice. In these steps, this directory is `download location`.

Following is the list of installation binaries and patches required for 21.1.1 release:

* JDK:  
    * jdk-8u241-linux-x64.tar.gz

* Fusion MiddleWare Infrastructure installer:  
    * fmw_12.2.1.4.0_infrastructure.jar

* Fusion MiddleWare Infrastructure patches:  
    * p28186730_139424_Generic.zip (Opatch)
    * p31537019_122140_Generic.zip (WLS)
    * p30729380_122140_Generic.zip (COH)

* WCS installers:  
    * fmw_12.2.1.4.0_wcsites.jar

* WCS patches:   
    * p32315127_122140_Generic.zip (WCS)
    


##### Update required build files

The following files available in the code repository location `${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/scripts/imagetool-scripts` are used for creating the image.

* `additionalBuildCmds.txt`
* `buildArgs`

1. In the `buildArgs` file, update all the occurrences of `%DOCKER_REPO%` with the repository location, which is the complete path of `imagetool-setup`.

   For example, update:

   `%DOCKER_REPO%/OracleWebCenterSites/kubernetes/imagetool-scripts/`


1. Similarly, update the placeholders `%JDK_VERSION%` and `%BUILDTAG%` with appropriate values.


##### Create the image

1. Add a JDK package to the WebLogic Image Tool cache:

    ``` bash
    $ imagetool cache addInstaller --type jdk --version 8u241 --path <download location>/jdk-8u241-linux-x64.tar.gz
    ```

1. Add the downloaded installation binaries to the WebLogic Image Tool cache:

    ``` bash
    $ imagetool cache addInstaller --type fmw --version 12.2.1.4.0 --path <download location>/fmw_12.2.1.4.0_infrastructure.jar

    $ imagetool cache addInstaller --type wcs --version 12.2.1.4.0 --path <download location>/fmw_12.2.1.4.0_wcsites.jar

    ```
1. Add the downloaded patches to the WebLogic Image Tool cache:

    {{%expand "Click here to see the commands to add patches in to the cache:" %}}
    ``` bash
    $ imagetool cache addEntry --key 28186730_13.9.4.2.4 --value <download location>/p28186730_139424_Generic.zip

    $ imagetool cache addEntry --key 31537019_12.2.1.4.0 --value <download location>/p31537019_122140_Generic.zip

    $ imagetool cache addEntry --key 30729380_12.2.1.4.0 --value <download location>/p30729380_122140_Generic.zip

    $ imagetool cache addEntry --key 32315127_12.2.1.4.0 --value <download location>/p32315127_122140_Generic.zip


    ```
   {{% /expand  %}}

1. Update the patches list to `buildArgs`.

    To the `create` command in the `buildArgs` file, append the Oracle WebCenter Sites patches list using the `--patches` flag and Opatch patch using the `--opatchBugNumber` flag. Sample options for the list of patches above are:

    ```
    --patches 31537019_12.2.1.4.0,30729380_12.2.1.4.0,p32315127_12.2.1.4.0
    --opatchBugNumber=28186730_13.9.4.2.4

    ```

   Example `buildArgs` file after appending product's list of patches and Opatch patch:

    ```
    create
    --jdkVersion=8u241
    --type WCS
    --version=12.2.1.4
    --tag=oracle/wcsites:12.2.1.4-21.1.1
    --installerResponseFile %path-to-downloaded-docker-repo%/OracleWebCenterSites/dockerfiles/12.2.1.4/wcs.file,%path-to-downloaded-docker-repo%/OracleWebCenterSites/dockerfiles/12.2.1.4/install.file
    --additionalBuildCommands %path-to-downloaded-fmw-kubernetes%/OracleWebCenterSites/kubernetes/imagetool-scripts/addtionalBuildCmds.txt --additionalBuildFiles %path-to-downloaded-docker-repo%/OracleWebCenterSites/dockerfiles/12.2.1.4/sites-container-scripts,%path-to-downloaded-docker-repo%/OracleWebCenterSites/dockerfiles/12.2.1.4/wcs-wls-docker-install
    --patches 31537019_12.2.1.4.0,30729380_12.2.1.4.0,32315127_12.2.1.4.0
    --opatchBugNumber=28186730_13.9.4.2.4

    ```

     Refer to [this page](https://github.com/oracle/weblogic-image-tool/blob/master/site/create-image.md) for the complete list of options available with the WebLogic Image Tool `create` command.


1. Enter the following command to create the Oracle WebCenter Sites image:

      ```bash
      $ imagetool @<absolute path to `buildargs` file>"
      ```

    {{%expand "Click here to see the sample Dockerfile generated with the imagetool command." %}}

      ```bash
      ########## BEGIN DOCKERFILE ##########
      #
      # Copyright (c) 2019, 2020, Oracle and/or its affiliates.
      #
      # Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
      #
      #
      FROM oraclelinux:7-slim as OS_UPDATE
      LABEL com.oracle.weblogic.imagetool.buildid="3b37c045-11c6-4eb8-b69c-f42256c1e082"
      USER root

      RUN yum -y --downloaddir= install gzip tar unzip libaio \
       && yum -y --downloaddir= clean all \
       && rm -rf /var/cache/yum/* \
       && rm -rf 

      ## Create user and group
      RUN if [ -z "$(getent group oracle)" ]; then hash groupadd &> /dev/null && groupadd oracle || exit -1 ; fi \
       && if [ -z "$(getent passwd oracle)" ]; then hash useradd &> /dev/null && useradd -g oracle oracle || exit -1; fi \
       && mkdir /u01 \
       && chown oracle:oracle /u01

      # Install Java
      FROM OS_UPDATE as JDK_BUILD
      LABEL com.oracle.weblogic.imagetool.buildid="3b37c045-11c6-4eb8-b69c-f42256c1e082"

      ENV JAVA_HOME=/u01/jdk

      COPY --chown=oracle:oracle jdk-8u251-linux-x64.tar.gz /tmp/imagetool/

      USER oracle


      RUN tar xzf /tmp/imagetool/jdk-8u251-linux-x64.tar.gz -C /u01 \
       && mv /u01/jdk* /u01/jdk \
       && rm -rf /tmp/imagetool


      # Install Middleware
      FROM OS_UPDATE as WLS_BUILD
      LABEL com.oracle.weblogic.imagetool.buildid="3b37c045-11c6-4eb8-b69c-f42256c1e082"

      ENV JAVA_HOME=/u01/jdk \
          ORACLE_HOME=/u01/oracle \
          OPATCH_NO_FUSER=true

      RUN mkdir -p /u01/oracle \
       && mkdir -p /u01/oracle/oraInventory \
       && chown oracle:oracle /u01/oracle/oraInventory \
       && chown oracle:oracle /u01/oracle

      COPY --from=JDK_BUILD --chown=oracle:oracle /u01/jdk /u01/jdk/

      COPY --chown=oracle:oracle fmw_12.2.1.4.0_infrastructure.jar install.file /tmp/imagetool/
      COPY --chown=oracle:oracle fmw_12.2.1.4.0_wcsites.jar wcs.file /tmp/imagetool/
      COPY --chown=oracle:oracle oraInst.loc /u01/oracle/

          COPY --chown=oracle:oracle p28186730_139422_Generic.zip /tmp/imagetool/opatch/

          COPY --chown=oracle:oracle patches/* /tmp/imagetool/patches/

      USER oracle


      RUN  \
       /u01/jdk/bin/java -Xmx1024m -jar /tmp/imagetool/fmw_12.2.1.4.0_infrastructure.jar -silent ORACLE_HOME=/u01/oracle \
          -responseFile /tmp/imagetool/install.file -invPtrLoc /u01/oracle/oraInst.loc -ignoreSysPrereqs -force -novalidation
      RUN  \
       /u01/jdk/bin/java -Xmx1024m -jar /tmp/imagetool/fmw_12.2.1.4.0_wcsites.jar -silent ORACLE_HOME=/u01/oracle \
          -responseFile /tmp/imagetool/wcs.file -invPtrLoc /u01/oracle/oraInst.loc -ignoreSysPrereqs -force -novalidation

      RUN cd /tmp/imagetool/opatch \
       && /u01/jdk/bin/jar -xf /tmp/imagetool/opatch/p28186730_139422_Generic.zip \
       && /u01/jdk/bin/java -jar /tmp/imagetool/opatch/6880880/opatch_generic.jar -silent -ignoreSysPrereqs -force -novalidation oracle_home=/u01/oracle

      RUN /u01/oracle/OPatch/opatch napply -silent -oh /u01/oracle -phBaseDir /tmp/imagetool/patches \
       && /u01/oracle/OPatch/opatch util cleanup -silent -oh /u01/oracle



      FROM OS_UPDATE as FINAL_BUILD

      ARG ADMIN_NAME
      ARG ADMIN_HOST
      ARG ADMIN_PORT
      ARG MANAGED_SERVER_PORT

      ENV ORACLE_HOME=/u01/oracle \
          JAVA_HOME=/u01/jdk \
          LC_ALL=${DEFAULT_LOCALE:-en_US.UTF-8} \
          PATH=${PATH}:/u01/jdk/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle

      LABEL com.oracle.weblogic.imagetool.buildid="3b37c045-11c6-4eb8-b69c-f42256c1e082"

          COPY --from=JDK_BUILD --chown=oracle:oracle /u01/jdk /u01/jdk/

      COPY --from=WLS_BUILD --chown=oracle:oracle /u01/oracle /u01/oracle/



      USER oracle
      WORKDIR /u01/oracle

      #ENTRYPOINT /bin/bash

          
          USER root
          
          COPY --chown=oracle:oracle files/sites-container-scripts/overrides/oui/ /u01/oracle/wcsites/common/templates/wls/
          
          USER oracle
            
          RUN cd /u01/oracle/wcsites/common/templates/wls && \
            $JAVA_HOME/bin/jar uvf oracle.wcsites.base.template.jar startup-plan.xml file-definition.xml && \
            rm /u01/oracle/wcsites/common/templates/wls/startup-plan.xml && \
            rm /u01/oracle/wcsites/common/templates/wls/file-definition.xml
          
          #
          # Install the required packages
          # -----------------------------
          USER root
          ENV SITES_CONTAINER_SCRIPTS=/u01/oracle/sites-container-scripts \
            SITES_INSTALLER_PKG=wcs-wls-docker-install \
            DOMAIN_ROOT="${DOMAIN_ROOT:-/u01/oracle/user_projects/domains}" \
            ADMIN_PORT=7001 \
            WCSITES_PORT=7002 \
            ADMIN_SSL_PORT=9001 \
            WCSITES_SSL_PORT=9002 \
              PATH=$PATH:/u01/oracle/sites-container-scripts
            
          RUN yum install -y hostname && \
              rm -rf /var/cache/yum
          
          RUN mkdir -p ${SITES_CONTAINER_SCRIPTS} && \
            mkdir -p /u01/wcs-wls-docker-install 
          COPY --chown=oracle:oracle  files/sites-container-scripts/ ${SITES_CONTAINER_SCRIPTS}/
          COPY --chown=oracle:oracle  files/wcs-wls-docker-install/ /u01/wcs-wls-docker-install/
          
          RUN chown oracle:oracle -R /u01/oracle/sites-container-scripts && \
            chown oracle:oracle -R /u01/wcs-wls-docker-install && \
            chmod a+xr /u01/oracle/sites-container-scripts/* && \
            chmod a+xr /u01/wcs-wls-docker-install/*.sh
          
          # Expose all Ports
          # -------------------------------------------------------------
          EXPOSE $ADMIN_PORT $ADMIN_SSL_PORT $WCSITES_PORT $WCSITES_SSL_PORT
          
          USER oracle
          WORKDIR ${ORACLE_HOME}
          # Define default command to start.
          # -------------------------------------------------------------
          CMD ["/u01/oracle/sites-container-scripts/createOrStartSitesDomain.sh"]
          
          

      ########## END DOCKERFILE ##########

      ```
      {{% /expand %}}

1. Check the created image using the `Docker images` command:

    ```bash
      $ docker images | grep wcsites
    ```

#### Update an image

After [setting up the WebLogic Image Tool]({{< relref "/wcsites-domains/create-or-update-image/#set-up-the-weblogic-image-tool" >}}) and required build scripts, use the WebLogic Image Tool to `update` an existing Oracle WebCenter Sites Docker image:

1. Enter the following command for each patch to add the required patch(es) to the WebLogic Image Tool cache:

    ```bash wrap
    $  cd <imagetool-setup>
    $ imagetool cache addEntry --key 32315127_12.2.1.4.0 --value < %path-to-downloaded-pathes%/patches/p32315127_122140_Generic.zip
      [INFO   ] Added entry 32315127_12.2.1.4.0=< %path-to-downloaded-pathes%/patches/p32315127_122140_Generic.zip
    ```
1. Provide the following arguments to the WebLogic Image Tool `update` command:

    * `–-fromImage` - Identify the image that needs to be updated. In the example below, the image to be updated is `oracle/wcsites:12.2.1.4-21.1.1`.
    * `–-patches` - Multiple patches can be specified as a comma-separated list.
    * `--tag` - Specify the new tag to be applied for the image being built.

    Refer [here](https://github.com/oracle/weblogic-image-tool/blob/master/site/update-image.md) for the complete list of options available with the WebLogic Image Tool `update` command.

    > Note: The WebLogic Image Tool cache should have the latest OPatch zip. The WebLogic Image Tool will update the OPatch if it is not already updated in the image.

    ##### Examples

    {{%expand "Click here to see the example `update` command:" %}}

  ```
  $ imagetool update --fromImage oracle/wcsites:12.2.1.4-21.1.1 --tag=oracle/wcsites:12.2.1.4-21.1.1-32315127 --patches=32315127_12.2.1.4.0

      [INFO   ] Image Tool build ID: 7c268a9a-723f-424e-a06e-cb615c783e6d
      [INFO   ] Temporary directory used for docker build context: %path-to-temp-directory%/tmpBuild/wlsimgbuilder_temp8555048225669509
      [INFO   ] Using patch 28186730_13.9.4.2.4 from cache: %path-to-downloaded-pathes%/patches
/p28186730_139424_Generic.zip
      [INFO   ] OPatch will not be updated, fromImage has version 13.9.4.2.4, available version is 13.9.4.2.4
      [WARNING] skipping patch conflict check, no support credentials provided
      [WARNING] No credentials provided, skipping validation of patches
      [INFO   ] Using patch 32315127_12.2.1.4.0 from cache:  %path-to-downloaded-pathes%/patches
/p32315127_122140_Generic.zip
      [INFO   ] docker cmd = docker build --no-cache --force-rm --tag oracle/wcsites:12.2.1.4-21.1.1 --build-arg http_proxy=http://www-proxy-your-company.com:80 --build-arg https_proxy=http://www-proxy-your-company.com:80 --build-arg no_proxy=localhost,127.0.0.0/8,/var/run/docker.sock %path-to-temp-directory%/tmpBuild/wlsimgbuilder_temp8555048225669509
      Sending build context to Docker daemon  212.7MB

      Step 1/7 : FROM oracle/wcsites:12.2.1.4-21.1.1 as FINAL_BUILD
       ---> 480f1a31c02b
      Step 2/7 : USER root
       ---> Running in 9d5a81ad5bde
      Removing intermediate container 9d5a81ad5bde
       ---> 71b50b0b34dc
      Step 3/7 : ENV OPATCH_NO_FUSER=true
       ---> Running in c361884e8a71
      Removing intermediate container c361884e8a71
       ---> 2951de256951
      Step 4/7 : LABEL com.oracle.weblogic.imagetool.buildid="7c268a9a-723f-424e-a06e-cb615c783e6d"
       ---> Running in e2f485ac9039
      Removing intermediate container e2f485ac9039
       ---> 970f6552ef9a
      Step 5/7 : USER oracle
       ---> Running in e3c85228af4b
      Removing intermediate container e3c85228af4b
       ---> 4401fdb4ebbe
      Step 6/7 : COPY --chown=oracle:oracle patches/* /tmp/imagetool/patches/
       ---> 978a48e1cc95
      Step 7/7 : RUN /u01/oracle/OPatch/opatch napply -silent -oh /u01/oracle -phBaseDir /tmp/imagetool/patches     && /u01/oracle/OPatch/opatch util cleanup -silent -oh /u01/oracle     && rm -rf /tmp/imagetool
       ---> Running in 5039320b2f10
      Oracle Interim Patch Installer version 13.9.4.2.4
      Copyright (c) 2020, Oracle Corporation.  All rights reserved.


      Oracle Home       : /u01/oracle
      Central Inventory : /u01/oracle/oraInventory
         from           : /u01/oracle/oraInst.loc
      OPatch version    : 13.9.4.2.4
      OUI version       : 13.9.4.0.0
      Log file location : /u01/oracle/cfgtoollogs/opatch/opatch2020-08-04_05-15-38AM_1.log


      OPatch detects the Middleware Home as "/u01/oracle"

      Verifying environment and performing prerequisite checks...
      OPatch continues with these patches:   32315127  

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
      Applying interim patch '32315127' to OH '/u01/oracle'
      ApplySession: Optional component(s) [ oracle.wcsites.wccintegration, 12.2.1.4.0 ] , [ oracle.wcsites.wccintegration, 12.2.1.4.0 ]  not present in the Oracle Home or a higher version is found.

      Patching component oracle.wcsites, 12.2.1.4.0...

      Patching component oracle.wcsites, 12.2.1.4.0...

      Patching component oracle.wcsites.visitorservices, 12.2.1.4.0...

      Patching component oracle.wcsites.visitorservices, 12.2.1.4.0...

      Patching component oracle.wcsites.examples, 12.2.1.4.0...

      Patching component oracle.wcsites.examples, 12.2.1.4.0...

      Patching component oracle.wcsites.developer.tools, 12.2.1.4.0...

      Patching component oracle.wcsites.developer.tools, 12.2.1.4.0...

      Patching component oracle.wcsites.satelliteserver, 12.2.1.4.0...

      Patching component oracle.wcsites.satelliteserver, 12.2.1.4.0...

      Patching component oracle.wcsites.sitecapture, 12.2.1.4.0...

      Patching component oracle.wcsites.sitecapture, 12.2.1.4.0...
      Patch 32315127 successfully applied.
      Log file location: /u01/oracle/cfgtoollogs/opatch/opatch2020-08-04_05-15-38AM_1.log

      OPatch succeeded.
      Oracle Interim Patch Installer version 13.9.4.2.4
      Copyright (c) 2020, Oracle Corporation.  All rights reserved.


      Oracle Home       : /u01/oracle
      Central Inventory : /u01/oracle/oraInventory
         from           : /u01/oracle/oraInst.loc
      OPatch version    : 13.9.4.2.4
      OUI version       : 13.9.4.0.0
      Log file location : /u01/oracle/cfgtoollogs/opatch/opatch2020-08-04_05-16-11AM_1.log


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
      Removing intermediate container 5039320b2f10
       ---> 1be958e1e859
      Successfully built 1be958e1e859
      Successfully tagged oracle/wcsites:12.2.1.4-21.1.1-32315127
      [INFO   ] Build successful. Build time=73s. Image tag=oracle/wcsites:12.2.1.4-21.1.1-32315127

  ```
    {{% /expand %}}


    {{%expand "Click here to see the example Dockerfile generated by the WebLogic Image Tool with the `–-dryRun` option:" %}}


  ```bash wrap
  $ imagetool update --fromImage oracle/wcsites:12.2.1.4-21.1.1 --tag=oracle/wcsites:12.2.1.4-21.1.1-32315127 --patches=32315127_12.2.1.4.0 --dryRun

    [INFO   ] Image Tool build ID: a2fca032-7807-4bfb-b5a4-0ed90a710a56
    [INFO   ] Temporary directory used for docker build context: %path-to-temp-directory%/tmpBuild/wlsimgbuilder_temp4743247141639108603
    [INFO   ] Using patch 28186730_13.9.4.2.4 from cache: %path-to-downloaded-pathes%/patches
/p28186730_139424_Generic.zip
    [INFO   ] OPatch will not be updated, fromImage has version 13.9.4.2.4, available version is 13.9.4.2.4
    [WARNING] skipping patch conflict check, no support credentials provided
    [WARNING] No credentials provided, skipping validation of patches
    [INFO   ] Using patch 32315127_12.2.1.4.0 from cache:  %path-to-downloaded-pathes%/patches
/p32315127_122140_Generic.zip
    [INFO   ] docker cmd = docker build --no-cache --force-rm --tag oracle/wcsites:12.2.1.4-21.1.1.1 --build-arg http_proxy=http://www-proxy-your-company.com:80 --build-arg https_proxy=http://www-proxy-your-company.com:80 --build-arg no_proxy=localhost,127.0.0.0/8,/var/run/docker.sock %path-to-temp-directory%/tmpBuild/wlsimgbuilder_temp4743247141639108603
    ########## BEGIN DOCKERFILE ##########
    #
    # Copyright (c) 2019, 2020, Oracle and/or its affiliates.
    #
    # Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
    #
    #

    FROM oracle/wcsites:12.2.1.4-21.1.1 as FINAL_BUILD
    USER root

    ENV OPATCH_NO_FUSER=true


    LABEL com.oracle.weblogic.imagetool.buildid="a2fca032-7807-4bfb-b5a4-0ed90a710a56"

    USER oracle


        COPY --chown=oracle:oracle patches/* /tmp/imagetool/patches/

        RUN /u01/oracle/OPatch/opatch napply -silent -oh /u01/oracle -phBaseDir /tmp/imagetool/patches \
        && /u01/oracle/OPatch/opatch util cleanup -silent -oh /u01/oracle \
        && rm -rf /tmp/imagetool




    ########## END DOCKERFILE ##########
    [INFO   ] Dry run complete.  No image created.

  ```
  {{% /expand %}}


1. Check the built image using the `Docker images` command:
    ```bash
      $ docker images | grep wcsites
      oracle/wcsites   12.2.1.4-21.1.1-32315127   2ef2a67a685b        About a minute ago   2.84GB
      oracle/wcsites   12.2.1.4-21.1.1            445b649a3459        4 days ago           3.2GB

    ```

### Create an Oracle WebCenter Sites Docker image using Dockerfile

For test and development purposes, you can create an Oracle WebCenter Sites image using the Dockerfile. Consult the [README](https://github.com/oracle/docker-images/blob/master/OracleWebCenterSites/dockerfiles/README.md) file for important prerequisite steps,
such as building or pulling the Server JRE Docker image, Oracle FMW Infrastructure Docker image, and downloading the Oracle WebCenter Sites installer and bundle patch binaries.

A prebuilt Oracle Fusion Middleware Infrastructure image, `container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4`, is available at `container-registry.oracle.com`. We recommend that you pull and rename this image to build the Oracle WebCenter Sites image.


  ```bash
    $ docker pull <path-to-container-registry>/fmw-infrastructure:12.2.1.4
    $ docker tag <path-to-container-registry>/fmw-infrastructure:12.2.1.4  oracle/fmw-infrastructure:12.2.1.4
  ```

Follow these steps to build an Oracle Fusion Middleware Infrastructure image, and then the Oracle WebCenter Sites image as a layer on top of that:

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

1. Download the Oracle WebCenter Sites installer from the Oracle Technology Network or e-delivery.

   >Note: Copy the installer binaries to the same location as the Dockerfile.

1. To build the Oracle WebCenter Sites image with patches, you must download and drop the patch zip files (for example, `p32315127_122140_Generic.zip`) into the `patches/` folder under the version that is required. For example, for `12.2.1.4` the folder is `12.2.1.4/patches`.

1. Create the Oracle WebCenter Sites image by running the provided script:

    ```bash
    $ cd docker-images/OracleWebCenterSites/dockerfiles
    $ ./buildDockerImage.sh -v 12.2.1.4 -s
    ```

    The image produced will be named `oracle/wcsites:12.2.1.4`. The samples and instructions assume the Oracle WebCenter Sites image is named `wcsites:12.2.1.4`. You must rename your image to match this name, or update the samples to refer to the image you created.

    ```bash
    $ docker tag oracle/wcsites:12.2.1.4 oracle/wcsites:12.2.1.4-21.1.1 
    ```
