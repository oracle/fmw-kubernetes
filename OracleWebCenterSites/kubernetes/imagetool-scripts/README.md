Building WC-SITES image with WebLogic Image Tool
=============================================

## Contents

1. [Introduction](#1-introduction)
2. [Download the required packages/installers&Patches](#2-download-the-required-packagesinstallerspatches)
3. [Required build files](#3-required-build-files)
4. [Steps to create image](#4-steps-to-create-image)
5. [Sample Dockerfile generated with imagetool](#5-sample-dockerfile-generated-with-imagetool)

# 1. Introduction

This README describes the steps involved in building WC-SITES image with the WebLogic Image Tool.


# 2. Download the required packages/installers&Patches

Download the required installers from the [Oracle Software Delivery Cloud](https://edelivery.oracle.com/) and save them in a directory of your choice. Below the list of packages/installers & patches required for WC-SITES image.
```
JDK
    jdk-8u291-linux-x64.tar.gz

FMW INFRA
    fmw_12.2.1.4.0_infrastructure.jar

FMW INFRA PATCHES
    p28186730_139428_Generic.zip(Opatch)
    p34012040_122140_Generic.zip(WLS)
    p33902201_122140_Generic.zip(COH)

WCS
    fmw_12.2.1.4.0_wcsites.jar

WCS PATCH 
    p33975762_122140_Generic.zip

```

# 3. Required build files

The following files from this [repository](./) will be used for building the image,

        additionalBuildCmds.txt
        buildArgs

Update the repository location in `buildArgs` file in place of the place holder %DOCKER_REPO%

```
--additionalBuildCommands %DOCKER_REPO%/OracleWebCenterSites/kubernetes/imagetool-scripts/additionalBuildCmds.txt

```
Similarily, update the placeholders %JDK_VERSION% & %BUILDTAG%

Also download the docker-images [repositoty](https://github.com/oracle/docker-images.git) and 
update %path-to-downloaded-docker-repo% with the docker-images repository path.


# 4. Steps to create image

### i) Add JDK package to Imagetool cache

```bash
    $ imagetool cache addInstaller --type jdk --version 8u291 --path <download location>/jdk-8u291-linux-x64.tar.gz
```

### ii) Add installers to Imagetool cache

```bash
    $ imagetool cache addInstaller --type fmw --version 12.2.1.4.0 --path <download location>/fmw_12.2.1.4.0_infrastructure.jar
    $ imagetool cache addInstaller --type wcs --version 12.2.1.4.0 --path <download location>/fmw_12.2.1.4.0_wcsites.jar
```
### iii) Add Patches to Imagetool cache

```bash
    $ imagetool cache addEntry --key 28186730_13.9.4.2.8 --value <download location>/p28186730_139428_Generic.zip
    $ imagetool cache addEntry --key 34012040_12.2.1.4.0 --value <download location>/p34012040_122140_Generic.zip
    $ imagetool cache addEntry --key 33902201_12.2.1.4.0 --value <download location>/p33902201_122140_Generic.zip
    $ imagetool cache addEntry --key 33975762_12.2.1.4.0 --value <download location>/p33975762_122140_Generic.zip
```

### iv) Updated patch/Opatch to the buildAgrs

Append patch and opatch list to be used for image creation to the `buildArgs` file. Below the sample options for the above patches,

```
--patches 34012040_12.2.1.4.0,33902201_12.2.1.4.0,33975762_12.2.1.4.0
--opatchBugNumber=28186730_13.9.4.2.8
```
Below a sample `buildArgs` file after appending patch/Opacth detals,
```

create
--jdkVersion=8u291
--type WCS
--version=12.2.1.4
--tag=oracle/wcsites:12.2.1.4
--installerResponseFile %path-to-downloaded-docker-repo%/OracleWebCenterSites/dockerfiles/12.2.1.4/wcs.file,%path-to-downloaded-docker-repo%/OracleWebCenterSites/dockerfiles/12.2.1.4/install.file
--additionalBuildCommands %path-to-downloaded-docker-repo%/OracleWebCenterSites/kubernetes/imagetool-scripts/additionalBuildCmds.txt --additionalBuildFiles %path-to-downloaded-docker-repo%/OracleWebCenterSites/dockerfiles/12.2.1.4/sites-container-scripts,%path-to-downloaded-docker-repo%/OracleWebCenterSites/dockerfiles/12.2.1.4/wcs-wls-docker-install
--patches 34012040_12.2.1.4.0,33902201_12.2.1.4.0,33975762_12.2.1.4.0
--opatchBugNumber=28186730_13.9.4.2.8
```

### v) Preparing response files 

1. Add INSTALL_TYPE="WebLogic Server" in %path-to-downloaded-docker-repo%/OracleFMWInfrastructure/dockerfiles/12.2.1.4/install.file
1. Rename %path-to-downloaded-docker-repo%/OracleWebCenterSites/dockerfiles/12.2.1.4/install.file to %path-to-downloaded-docker-repo%/OracleWebCenterSites/dockerfiles/12.2.1.4/wcs.file 

### vi) Create a wcs-wls-docker-install installer

  ```
  $ cd %path-to-downloaded-docker-repo%/OracleWebCenterSites/dockerfiles/12.2.1.4/wcs-wls-docker-install
  $ docker run --rm -u root -v ${PWD}:/wcs-wls-docker-install groovy:2.4.8-jdk8 /wcs-wls-docker-install/packagejar.sh

  ```

### vii) Create image

Execute the below command to create the WCS image,

```bash
        $ imagetool @buildArgs
```

# 5. Sample Dockerfile generated with imagetool

```Dockerfile
########## BEGIN DOCKERFILE ##########
#
# Copyright (c) 2021, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl
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
 && chown oracle:root /u01

# Install Java
FROM OS_UPDATE as JDK_BUILD
LABEL com.oracle.weblogic.imagetool.buildid="3b37c045-11c6-4eb8-b69c-f42256c1e082"

ENV JAVA_HOME=/u01/jdk

COPY --chown=oracle:root jdk-8u291-linux-x64.tar.gz /tmp/imagetool/

USER oracle


RUN tar xzf /tmp/imagetool/jdk-8u291-linux-x64.tar.gz -C /u01 \
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
 && chown oracle:root /u01/oracle/oraInventory \
 && chown oracle:root /u01/oracle

COPY --from=JDK_BUILD --chown=oracle:root /u01/jdk /u01/jdk/

COPY --chown=oracle:root fmw_12.2.1.4.0_infrastructure.jar install.file /tmp/imagetool/
COPY --chown=oracle:root fmw_12.2.1.4.0_wcsites.jar wcs.file /tmp/imagetool/
COPY --chown=oracle:root oraInst.loc /u01/oracle/

    COPY --chown=oracle:root p28186730_139428_Generic.zip /tmp/imagetool/opatch/

    COPY --chown=oracle:root patches/* /tmp/imagetool/patches/

USER oracle


RUN  \
 /u01/jdk/bin/java -Xmx1024m -jar /tmp/imagetool/fmw_12.2.1.4.0_infrastructure.jar -silent ORACLE_HOME=/u01/oracle \
    -responseFile /tmp/imagetool/install.file -invPtrLoc /u01/oracle/oraInst.loc -ignoreSysPrereqs -force -novalidation
RUN  \
 /u01/jdk/bin/java -Xmx1024m -jar /tmp/imagetool/fmw_12.2.1.4.0_wcsites.jar -silent ORACLE_HOME=/u01/oracle \
    -responseFile /tmp/imagetool/wcs.file -invPtrLoc /u01/oracle/oraInst.loc -ignoreSysPrereqs -force -novalidation

RUN cd /tmp/imagetool/opatch \
 && /u01/jdk/bin/jar -xf /tmp/imagetool/opatch/p28186730_139428_Generic.zip \
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

    COPY --from=JDK_BUILD --chown=oracle:root /u01/jdk /u01/jdk/

COPY --from=WLS_BUILD --chown=oracle:root /u01/oracle /u01/oracle/



USER oracle
WORKDIR /u01/oracle

#ENTRYPOINT /bin/bash

    
    USER root
    
    COPY --chown=oracle:root files/sites-container-scripts/overrides/oui/ /u01/oracle/wcsites/common/templates/wls/
    
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
    COPY --chown=oracle:root  files/sites-container-scripts/ ${SITES_CONTAINER_SCRIPTS}/
    COPY --chown=oracle:root  files/wcs-wls-docker-install/ /u01/wcs-wls-docker-install/
    
    RUN chown oracle:root -R /u01/oracle/sites-container-scripts && \
    	chown oracle:root -R /u01/wcs-wls-docker-install && \
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
