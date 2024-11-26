+++
title = "Create or update an image"
weight = 7 
pre = "<b>7. </b>"
description=  "Create or update an Oracle HTTP Server (OHS) container image used for deploying OHS domains."
+++

As described in [Prepare Your Environment](../prepare-your-environment) you can create your own OHS container image. If you have access to the My Oracle Support (MOS), and there is a need to build a new image with an interim or one off patch, it is recommended to use the WebLogic Image Tool to build an Oracle HTTP Server image for production deployments.

### Create or update an Oracle HTTP Server image using the WebLogic Image Tool

Using the WebLogic Image Tool, you can [create](../create-or-update-image/#create-an-image) a new Oracle HTTP Server image with PSU's and interim patches or [update](../create-or-update-image/#update-an-image) an existing image with one or more interim patches.

> **Recommendations:**
>  * Use [create](../create-or-update-image/#create-an-image) for creating a new Oracle HTTP Server image containing the Oracle HTTP Server binaries, bundle patch and interim patches. This is the recommended approach if you have access to the OHS patches because it optimizes the size of the image.
>  * Use [update](../create-or-update-image/#update-an-image) for patching an existing Oracle HTTP Server image with a single interim patch. Note that the patched image size may increase considerably due to additional image layers introduced by the patch application tool.

#### Create an image

#### Set up the WebLogic Image Tool

* [Prerequisites](#prerequisites)
* [Set up the WebLogic Image Tool](#set-up-the-weblogic-image-tool)
* [Validate setup](#validate-setup)
* [WebLogic Image Tool build directory](#weblogic-image-tool-build-directory)
* [WebLogic Image Tool cache](#weblogic-image-tool-cache)

##### Prerequisites

Verify that your environment meets the following prerequisites:

* Docker client and daemon on the build machine, with minimum Docker version 18.03.1.ce.
* Bash version 4.0 or later, to enable the <tab> command complete feature.
* JAVA_HOME environment variable set to the appropriate JDK location e.g: /scratch/export/oracle/product/jdk

##### Set up the WebLogic Image Tool

To set up the WebLogic Image Tool:

1. Create a working directory and change to it:

   ```bash
   $ mkdir <workdir>
   $ cd <workdir>
   ```
   
   For example:

   ```bash
   $ mkdir /scratch/imagetool-setup
   $ cd /scratch/imagetool-setup
   ```
1. Download the latest version of the WebLogic Image Tool from the [releases page](https://github.com/oracle/weblogic-image-tool/releases/latest).

   ```bash
   $ wget https://github.com/oracle/weblogic-image-tool/releases/download/release-X.X.X/imagetool.zip
   ```
	
   where X.X.X is the latest release referenced on the [releases page](https://github.com/oracle/weblogic-image-tool/releases/latest).
	
>Note: You must use WebLogic Image Tool 1.14.2 or later.

	
1. Unzip the release ZIP file in the `imagetool-setup` directory.

   ```bash
   $ unzip imagetool.zip
   ````
 
1. Execute the following commands to set up the WebLogic Image Tool:

   ```bash
   $ cd <workdir>/imagetool-setup/imagetool/bin
   $ source setup.sh
   ```
	
   For example:
	
   ```bash
   $ cd /scratch/imagetool-setup/imagetool/bin
   $ source setup.sh
   ```

##### Validate setup
To validate the setup of the WebLogic Image Tool:

1. Enter the following command to retrieve the version of the WebLogic Image Tool:

   ``` bash
   $ imagetool --version
   ```

1. Enter `imagetool` then press the Tab key to display the available `imagetool` commands:

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

The WebLogic Image Tool maintains a local file cache store. This store is used to look up where the OHS and JDK installers, and OHS patches reside in the local file system. By default, the cache store is located in the user's `$HOME/cache` directory. Under this directory, the lookup information is stored in the `.metadata` file. All automatically downloaded patches also reside in this directory. You can change the default cache store location by setting the environment variable `WLSIMG_CACHEDIR`:

```bash
$ export WLSIMG_CACHEDIR="/path/to/cachedir"
```

##### Set up additional build scripts

Creating an Oracle HTTP Server container image using the WebLogic Image Tool requires additional container scripts for Oracle HTTP Server domains.

1. Clone the [docker-images](https://github.com/oracle/docker-images.git) repository to set up those scripts. In these steps, this directory is `DOCKER_REPO`:

   ```bash
   $ cd <workdir>/imagetool-setup
   $ git clone https://github.com/oracle/docker-images.git
   ```
   
   For example:
   
   ```bash
   $ cd /scratch/imagetool-setup
   $ git clone https://github.com/oracle/docker-images.git
   ```
    
>Note: If you want to create the image continue with the following steps, otherwise to update the image see [update an image](#update-an-image).

#### Create an image

After [setting up the WebLogic Image Tool](../create-or-update-image/#set-up-the-weblogic-image-tool), follow these steps to use the WebLogic Image Tool to `create` a new Oracle HTTP Server image.


##### Export the PWD variable

In order for the WebLogic Image Tool to build OHS with all the latest patches, the image creation downloads patches from [My Oracle Support](https://support.oracle.com).

During the image build you are asked to enter your [My Oracle Support](https://support.oracle.com) credentials, however the password is passed as a variable. Set the variable as follows:

```
export MYPWD="MY_ORACLE_SUPPORT_PWD"
```

##### Download the Oracle HTTP Server installation binaries and patches

You must download the required Oracle HTTP Server installation binaries and patches as listed below from [Oracle Software Delivery Cloud](https://edelivery.oracle.com/) and [My Oracle Support](https://support.oracle.com). Save them in a <download location> directory of your choice.

The installation binaries and patches required are:

* Oracle Web Tier  12.2.1.4.0
   * V983369-01.zip

* Oracle JDK v8
   * jdk-8uXXX-linux-x64.tar.gz
	 
* Oracle Database 19c Upgrade for FMW 12.2.1.4.0 (OID/OHS/OTD homes only) 
   * Patch 34761383 DB Client 19c Upgrade for FMW 12.2.1.4.0 (OID/OHS/OTD homes only)
	
##### Update required build files

The following files are used for creating the image:

* `additionalBuildCmds.txt`
* `buildArgs`


1. Create the `<workdir>/imagetool-setup/docker-images/OracleHTTPServer/additionalBuildCmds.txt` file as follows and change the following:

   ```
   [package-manager-packages]
   binutils make glibc-devel procps
   [final-build-commands]
   ENV PATH=$PATH:/u01/oracle/ohssa/oracle_common/common/bin \
       NM_PORT=5556 \
       OHS_LISTEN_PORT=7777 \
       OHS_SSL_PORT=4443 \
       MW_HOME=/u01/oracle/ohssa \
       DOMAIN_NAME=ohsDomain \
       OHS_COMPONENT_NAME=ohs1 \
       PATH=$PATH:$ORACLE_HOME/oracle_common/common/bin:$ORACLE_HOME/user_projects/domains/ohsDomain/bin:/u01/oracle/ \
       WLST_HOME=/u01/oracle/ohssa/oracle_common/common/bin
   COPY --chown=oracle:root files/create-sa-ohs-domain.py files/configureWLSProxyPlugin.sh files/mod_wl_ohs.conf.sample files/provisionOHS.sh files/start-ohs.py files/stop-ohs.py files/helloWorld.html /u01/oracle/
   WORKDIR ${ORACLE_HOME}
   CMD ["/u01/oracle/provisionOHS.sh"]
   ```
	
   **Note:** `oracle:root` is used for OpenShift which has more stringent policies.  Users who do not want those permissions can change to the permissions they require.


1. Create the `<workdir>/imagetool-setup/docker-images/OracleHTTPServer/buildArgs` file as follows and change the following:

   + `<workdir>` to your working directory, for example `/scratch/`
   + `%BUILDTAG%` to the tag you want create for the image, for example `oracle/ohs:12.2.1.4-db19`
   + `%JDK_VERSION%` to the version of your JDK, for example `8uXXX`
   + `<user>` to your [My Oracle Support](https://support.oracle.com) username
   
   ```
   create
   --tag=%BUILDTAG%
   --additionalBuildCommands /<workdir>/imagetool-setup/docker-images/OracleHTTPServer/additionalBuildCmds.txt
   --additionalBuildFiles <workdir>/imagetool-setup/docker-images/OracleHTTPServer/dockerfiles/12.2.1.4.0/container-scripts/create-sa-ohs-domain.py,<workdir>/imagetool-setup/docker-images/OracleHTTPServer/dockerfiles/12.2.1.4.0/container-scripts/provisionOHS.sh,<workdir>/imagetool-setup/docker-images/OracleHTTPServer/dockerfiles/12.2.1.4.0/container-scripts/configureWLSProxyPlugin.sh,<workdir>/imagetool-setup/docker-images/OracleHTTPServer/dockerfiles/12.2.1.4.0/container-scripts/mod_wl_ohs.conf.sample,<workdir>/imagetool-setup/docker-images/OracleHTTPServer/dockerfiles/12.2.1.4.0/container-scripts/start-ohs.py,<workdir>/imagetool-setup/docker-images/OracleHTTPServer/dockerfiles/12.2.1.4.0/container-scripts/stop-ohs.py,<workdir>/imagetool-setup/docker-images/OracleHTTPServer/dockerfiles/12.2.1.4.0/container-scripts/helloWorld.html
   --type=OHS
   --pull
   --recommendedPatches
   --chown=oracle:root
   --user=<user>
   --passwordEnv=MYPWD
   --version=12.2.1.4.0
   --jdkVersion=<latest jdk 8 update>
   ```

   For example:
   
   ```
   create
   --tag=oracle/ohs:12.2.1.4-db19
   --additionalBuildCommands /scratch/imagetool-setup/docker-images/OracleHTTPServer/additionalBuildCmds.txt
   --additionalBuildFiles /scratch/imagetool-setup/docker-images/OracleHTTPServer/dockerfiles/12.2.1.4.0/container-scripts/create-sa-ohs-domain.py,/scratch/imagetool-setup/docker-images/OracleHTTPServer/dockerfiles/12.2.1.4.0/container-scripts/provisionOHS.sh,/scratch/imagetool-setup/docker-images/OracleHTTPServer/dockerfiles/12.2.1.4.0/container-scripts/configureWLSProxyPlugin.sh,/scratch/imagetool-setup/docker-images/OracleHTTPServer/dockerfiles/12.2.1.4.0/container-scripts/mod_wl_ohs.conf.sample,/scratch/imagetool-setup/docker-images/OracleHTTPServer/dockerfiles/12.2.1.4.0/container-scripts/start-ohs.py,/scratch/imagetool-setup/docker-images/OracleHTTPServer/dockerfiles/12.2.1.4.0/container-scripts/stop-ohs.py,/scratch/imagetool-setup/docker-images/OracleHTTPServer/dockerfiles/12.2.1.4.0/container-scripts/helloWorld.html
   --type=OHS
   --pull
   --recommendedPatches
   --chown=oracle:root
   --user=user@example.com
   --passwordEnv=MYPWD
   --version=12.2.1.4.0
   --jdkVersion=8u421
   ```

	
   Refer to [this page](https://oracle.github.io/weblogic-image-tool/userguide/tools/create-image/) for the complete list of options available with the WebLogic Image Tool `create` command.
   
##### Create the image

1. Add a JDK package to the WebLogic Image Tool cache. For example:

   ``` bash
   $ imagetool cache addInstaller --type jdk --version 8uXXX --path <download location>/jdk-8uXXX-linux-x64.tar.gz
   ```
    
   where `XXX` is the JDK version downloaded.
	
1. Add the downloaded installation binaries to the WebLogic Image Tool cache. For example:

   ``` bash
   $ imagetool cache addInstaller --type ohs --version 12.2.1.4.0 --path <download location>/V983369-01.zip
   $ imagetool cache addInstaller --type db19 --version 12.2.1.4.0 --path <download location>/p34761383_122140_Linux-x86-64.zip
   ```
   
	
	
1. Create the Oracle HTTP Server image:

   ```bash
   $ imagetool @<absolute path to buildargs file>
   ```
   >Note: Make sure that the absolute path to the `buildargs` file is prepended with a `@` character, as shown in the example above.

   For example:

   ```bash
   $ imagetool @/scratch/imagetool-setup/docker-images/OracleHTTPServer/buildArgs
   ```

1. Check the created image using the `docker images` command:

   ```bash
   $ docker images | grep OHS
   ```
	
   The output will look similar to the following:
	
   ```bash
   oracle/ohs:12.2.1.4-db19                12.2.1.4.0                     ad732fc7c16b        About a minute ago   3.83GB
   ```
	
1. If you want to see what patches were installed, you can run:

   ```
   $ imagetool inspect --image=<REPOSITORY>:<TAG> --patches
   ```
	
   For example:
	
   ```
   $ imagetool inspect --image=oracle/ohs:12.2.1.4-db19 --patches
   ```
	
1. Run the following command to save the container image to a tar file:

   ```bash
   $ docker save -o <path>/<file>.tar <image>
   ```
   
   For example:
   
   ```bash
   $ docker save -o $WORKDIR/ohs12.2.1.4-db19.tar oracle/ohs:12.2.1.4-db19
   ```

#### Update an image

The steps below show how to update an existing Oracle HTTP Server image with an interim patch.

The container image to be patched must be loaded in the local docker images repository before attempting these steps.

In the examples below the image `oracle/OHS:12.2.1.4.0` is updated with an interim patch.

```bash
$ docker images

REPOSITORY                   TAG          IMAGE ID          CREATED             SIZE
oracle/ohs:12.2.1.4-db19     12.2.1.4.0   b051804ba15f      3 months ago        3.83GB
```


1. [Set up the WebLogic Image Tool](../create-or-update-image/#set-up-the-weblogic-image-tool).

1. Download the required interim patch(es) and latest Opatch (28186730) from [My Oracle Support](https://support.oracle.com). and save them in a <download location> directory of your choice.

1. Add the OPatch patch to the WebLogic Image Tool cache, for example:

   ```bash
   $ imagetool cache addEntry --key 28186730_13.9.4.2.17 --value <downloaded-patches-location>/p28186730_1394217_Generic.zip
   ```

1. Execute the `imagetool cache addEntry` command for each patch to add the required patch(es) to the WebLogic Image Tool cache. For example, to add patch `p6666666_12214241121_Generic.zip`:

   **Note**: This is not a real patch number, it is used purely for an example.

   ```bash wrap
   $ imagetool cache addEntry --key=6666666_12.2.1.4.241121 --value <downloaded-patches-location>/p6666666_12214241121_Generic.zip
   ```

1. Provide the following arguments to the WebLogic Image Tool `update` command:

   * `–-fromImage` - Identify the image that needs to be updated. In the example below, the image to be updated is `oracle/OHS:12.2.1.4.0`.
   * `–-patches` - Multiple patches can be specified as a comma-separated list.
   * `--tag` - Specify the new tag to be applied for the image being built.

   Refer [here](https://oracle.github.io/weblogic-image-tool/userguide/tools/update-image/) for the complete list of options available with the WebLogic Image Tool `update` command.

   > Note: The WebLogic Image Tool cache should have the latest OPatch zip. The WebLogic Image Tool will update the OPatch if it is not already updated in the image.

   For example:
	
   ```bash
   $ imagetool update --fromImage oracle/ohs:12.2.1.4-db19  --tag=oracle/ohs-new:12.2.1.4.0 --patches=6666666_12.2.1.4.241121 --opatchBugNumber=28186730_13.9.4.2.17
   ```

   > Note: If the command fails because the files in the image being upgraded are not owned by `oracle:root`, then add the parameter `--chown <userid>:<groupid>` to correspond with the values returned in the error.
   
1. Check the built image using the `docker images` command:
   
   ```bash
   $ docker images | grep OHS
   ```
   
   The output will look similar to the following:
   
   ```
   REPOSITORY                        TAG          IMAGE ID        CREATED             SIZE
   oracle/ohs-new:12.2.1.4-db19      12.2.1.4.0   78ccd1ad67eb    5 minutes ago       4.5GB
   oracle/ohs:12.2.1.4-db19          12.2.1.4.0   b051804ba15f    3 months ago        3.83GB
   ```

1. Run the following command to save the patched container image to a tar file:

   ```bash
   $ docker save -o <path>/<file>.tar <image>
   ```
   
   For example:
   
   ```bash
   $ docker save -o $WORKDIR/ohs-new12.2.1.4-db19.tar oracle/ohs-new:12.2.1.4-db19:12.2.1.4.0
   ```