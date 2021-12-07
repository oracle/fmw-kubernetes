+++
title = "Create or update an image"
weight = 10 
pre = "<b>10. </b>"
description=  "Create or update an Oracle Identity Governance (OIG) container image used for deploying OIG domains. An OIG container image can be created using the WebLogic Image Tool or using the Dockerfile approach."
+++


As described in [Prepare Your Environment]({{< relref "/oig/prepare-your-environment" >}}) you can obtain or build OIG container images in the following ways:

1. Download the latest prebuilt OIG container image from [My Oracle Support](https://support.oracle.com) by referring to the document ID 2723908.1. This image is prebuilt by Oracle and includes Oracle Identity Governance 12.2.1.4.0 and the latest PSU.

1. Build your own OIG image using the WebLogic Image Tool or by using the dockerfile, scripts and base images from Oracle Container Registry (OCR). You can also build your own image by using only the dockerfile and scripts. [Building the OIG Image](https://github.com/oracle/docker-images/tree/master/OracleIdentityGovernance/#building-the-oig-image).

If you have access to the My Oracle Support (MOS), and there is a need to build a new image with an interim or one off patch, it is recommended to use the WebLogic Image Tool to build an Oracle Identity Governance image for production deployments.


### Create or update an Oracle Identity Governance image using the WebLogic Image Tool

Using the WebLogic Image Tool, you can [create]({{< relref "/oig/create-or-update-image/#create-an-image" >}}) a new Oracle Identity Governance image with PSU's and interim patches or [update]({{< relref "/oig/create-or-update-image/#update-an-image" >}}) an existing image with one or more interim patches.

> **Recommendations:**
>  * Use [create]({{< relref "/oig/create-or-update-image/#create-an-image" >}}) for creating a new Oracle Identity Governance image containing the Oracle Identity Governance binaries, bundle patch and interim patches. This is the recommended approach if you have access to the OIG patches because it optimizes the size of the image.
>  * Use [update]({{< relref "/oig/create-or-update-image/#update-an-image" >}}) for patching an existing Oracle Identity Governance image with a single interim patch. Note that the patched image size may increase considerably due to additional image layers introduced by the patch application tool.

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

Creating an Oracle Identity Governance Docker image using the WebLogic Image Tool requires additional container scripts for Oracle Identity Governance domains.

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

After [setting up the WebLogic Image Tool]({{< relref "/oig/create-or-update-image/#set-up-the-weblogic-image-tool" >}}), follow these steps to use the WebLogic Image Tool to `create` a new Oracle Identity Governance image.

##### Download the Oracle Identity Governance installation binaries and patches

You must download the required Oracle Identity Governance installation binaries and patches as listed below from the [Oracle Software Delivery Cloud](https://edelivery.oracle.com/) and save them in a <download location> directory of your choice.

The installation binaries and patches required are:

* Oracle Identity and Access Management 12.2.1.4.0
	* fmw_12.2.1.4.0_idm.jar

* Oracle Fusion Middleware 12c Infrastructure 12.2.1.4.0
	* fmw_12.2.1.4.0_infrastructure.jar
	
* Oracle SOA Suite for Oracle Middleware 12.2.1.4.0
	* fmw_12.2.1.4.0_soa.jar
	
* Oracle Service Bus 12.2.1.4.0
	* fmw_12.2.1.4.0_osb.jar
	
* OIG and FMW Infrastructure Patches:
    * View document ID 2723908.1 on [My Oracle Support](https://support.oracle.com).  In the `Container Image Download/Patch Details` section, locate the `Oracle Identity Governance (OIG)` table. For the latest PSU click the `README` link in the `Documentation` column. In the README, locate the "Installed Software" section. All the patch numbers to be download are listed here. Download all these individual patches from My Oracle Support.

* Oracle JDK v8
    * jdk-8uXXX-linux-x64.tar.gz where XXX is the JDK version referenced in the README above.	
	
##### Update required build files

The following files in the code repository location `<imagetool-setup-location>/docker-images/OracleIdentityGovernance/imagetool/12.2.1.4.0` are used for creating the image:

* `additionalBuildCmds.txt`
* `buildArgs`

. Edit the `<workdir>/imagetool-setup/docker-images/OracleIdentityGovernance/imagetool/12.2.1.4.0/buildArgs` file and change `%DOCKER_REPO%`, `%JDK_VERSION%` and `%BUILDTAG%` appropriately.

   For example:
   
   ```
   create
   --jdkVersion=8u311
   --type oig
   --chown oracle:root
   --version=12.2.1.4.0
   --tag=oig-latestpsu:12.2.1.4.0
   --pull
   --installerResponseFile /scratch/imagetool-setup/docker-images/OracleFMWInfrastructure/dockerfiles/12.2.1.4/install.file,/scratch/imagetool-setup/docker-images/OracleSOASuite/dockerfiles/12.2.1.4.0/install/soasuite.response,/scratch/imagetool-setup/docker-images/OracleSOASuite/dockerfiles/12.2.1.4.0/install/osb.response,/scratch/imagetool-setup/docker-images/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/idmqs.response
   --additionalBuildCommands /scratch/imagetool-setup/docker-images/OracleIdentityGovernance/imagetool/12.2.1.4.0/additionalBuildCmds.txt
   --additionalBuildFiles /scratch/imagetool-setup/docker-images/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/container-scripts
   ```

1. Edit the `<workdir>/imagetool-setup/docker-images/OracleFMWInfrastructure/dockerfiles/12.2.1.4.0/install.file` and under the GENERIC section add the line INSTALL_TYPE="Fusion Middleware Infrastructure". For example:

   ```
   [GENERIC]
   INSTALL_TYPE="Fusion Middleware Infrastructure"
   DECLINE_SECURITY_UPDATES=true
   SECURITY_UPDATES_VIA_MYORACLESUPPORT=false
   ```
   
##### Create the image

1. Add a JDK package to the WebLogic Image Tool cache. For example:

   ``` bash
   $ imagetool cache addInstaller --type jdk --version 8uXXX --path <download location>/jdk-8uXXX-linux-x64.tar.gz
   ```
    
   where `XXX` is the JDK version downloaded
	
1. Add the downloaded installation binaries to the WebLogic Image Tool cache. For example:

   ``` bash
   $ imagetool cache addInstaller --type fmw --version 12.2.1.4.0 --path <download location>/fmw_12.2.1.4.0_infrastructure.jar
   
   $ imagetool cache addInstaller --type soa --version 12.2.1.4.0 --path <download location>/fmw_12.2.1.4.0_soa.jar
   
   $ imagetool cache addInstaller --type osb --version 12.2.1.4.0 --path <download location>/fmw_12.2.1.4.0_osb.jar
   
   $ imagetool cache addInstaller --type idm --version 12.2.1.4.0 --path <download location>/fmw_12.2.1.4.0_idm.jar
   ```
	
1. Add the downloaded OPatch patch to the WebLogic Image Tool cache. For example:

   ``` bash
   $ imagetool cache addEntry --key 28186730_13.9.4.2.7 --value <download location>/p28186730_139427_Generic.zip
   ```

1. Add the rest of the downloaded product patches to the WebLogic Image Tool cache:

   ``` bash
   $ imagetool cache addEntry --key <patch>_12.2.1.4.0 --value <download location>/p<patch>_122140_Generic.zip
   ```
	
   For example:

   ```bash
   $ imagetool cache addEntry --key 33416868_12.2.1.4.0 --value <download location>/p33416868_122140_Generic.zip
   $ imagetool cache addEntry --key 33453703_12.2.1.4.0 --value <download location>/p33453703_122140_Generic.zip
   $ imagetool cache addEntry --key 32999272_12.2.1.4.0 --value <download location>/p32999272_122140_Generic.zip
   $ imagetool cache addEntry --key 33093748_12.2.1.4.0 --value <download location>/p33093748_122140_Generic.zip
   $ imagetool cache addEntry --key 33281560_12.2.1.4.0 --value <download location>/p33281560_122140_Generic.zip
   $ imagetool cache addEntry --key 31544353_12.2.1.4.0 --value <download location>/p31544353_122140_Linux-x86-64.zip
   $ imagetool cache addEntry --key 33313802_12.2.1.4.0 --value <download location>/p33313802_122140_Generic.zip
   $ imagetool cache addEntry --key 33408307_12.2.1.4.0 --value <download location>/p33408307_122140_Generic.zip
   $ imagetool cache addEntry --key 33286160_12.2.1.4.0 --value <download location>/p33286160_122140_Generic.zip
   $ imagetool cache addEntry --key 32880070_12.2.1.4.0 --value <download location>/p32880070_122140_Generic.zip
   $ imagetool cache addEntry --key 32905339_12.2.1.4.0 --value <download location>/p32905339_122140_Generic.zip
   $ imagetool cache addEntry --key 32784652_12.2.1.4.0 --value <download location>/p32784652_122140_Generic.zip
   ```

1. Edit the `<workdir>/imagetool-setup/docker-images/OracleIdentityGovernance/imagetool/12.2.1.4.0/buildArgs` file and append the product patches and opatch patch as follows:

   ```
   --patches 33416868_12.2.1.4.0,33453703_12.2.1.4.0,32999272_12.2.1.4.0,33093748_12.2.1.4.0,33281560_12.2.1.4.0,31544353_12.2.1.4.0,33313802_12.2.1.4.0,33408307_12.2.1.4.0,33286160_12.2.1.4.0,32880070_12.2.1.4.0,32905339_12.2.1.4.0,32784652_12.2.1.4.0
   --opatchBugNumber=28186730_13.9.4.2.7
   ```

   An example `buildArgs` file is now as follows:

   ```
   create
   --jdkVersion=8u301
   --type oig
   --version=12.2.1.4.0
   --tag=oig-latestpsu:12.2.1.4.0
   --pull
   --installerResponseFile /scratch/imagetool-setup/docker-images/OracleFMWInfrastructure/dockerfiles/12.2.1.4/install.file,/scratch/docker-images/OracleSOASuite/dockerfiles/12.2.1.4.0/install/soasuite.response,/scratch/docker-images/OracleSOASuite/dockerfiles/12.2.1.4.0/install/osb.response,/scratch/docker-images/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/idmqs.response
   --additionalBuildCommands /scratch/imagetool-setup/docker-images/OracleIdentityGovernance/imagetool/12.2.1.4.0/additionalBuildCmds.txt
   --additionalBuildFiles /scratch/imagetool-setup/docker-images/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/container-scripts
   --patches 33416868_12.2.1.4.0,33453703_12.2.1.4.0,32999272_12.2.1.4.0,33093748_12.2.1.4.0,33281560_12.2.1.4.0,31544353_12.2.1.4.0,33313802_12.2.1.4.0,33408307_12.2.1.4.0,33286160_12.2.1.4.0,32880070_12.2.1.4.0,32905339_12.2.1.4.0,32784652_12.2.1.4.0
   --opatchBugNumber=28186730_13.9.4.2.7
   ```
   
   >Note: In the `buildArgs` file:  
   > * `--jdkVersion` value must match the `--version` value used in the `imagetool cache addInstaller` command for `--type jdk`.  
   > * `--version` value must match the `--version` value used in the `imagetool cache addInstaller` command for `--type idm`.  
   > * `--pull` always pulls the latest base Linux image `oraclelinux:7-slim` from the Docker registry.

    Refer to [this page](https://oracle.github.io/weblogic-image-tool/userguide/tools/create-image/) for the complete list of options available with the WebLogic Image Tool `create` command.

1. Create the Oracle Identity Governance image:

   ```bash
   $ imagetool @<absolute path to buildargs file>
   ```
   >Note: Make sure that the absolute path to the `buildargs` file is prepended with a `@` character, as shown in the example above.

   For example:

   ```bash
   $ imagetool @<imagetool-setup-location>/docker-images/OracleIdentityGovernance/imagetool/12.2.1.4.0/buildArgs
   ```

1. Check the created image using the `docker images` command:

   ```bash
   $ docker images | grep oig
   ```
	
   The output will look similar to the following:
	
   ```
   oig-latestpsu                                    12.2.1.4.0                     e391ed154bcb        50 seconds ago      4.43GB
   ```

#### Update an image

The steps below show how to update an existing Oracle Identity Governance image with an interim patch. In the examples below the image `oracle/oig:12.2.1.4.0` is updated with an interim patch.

```bash
$ docker images

REPOSITORY     TAG          IMAGE ID          CREATED             SIZE
oracle/oig     12.2.1.4.0   298fdb98e79c      3 months ago        4.42GB
```

1. [Set up the WebLogic Image Tool]({{< relref "/oig/create-or-update-image/#set-up-the-weblogic-image-tool" >}}).

1. Download the required interim patch and latest Opatch (28186730) from [My Oracle Support](https://support.oracle.com). and save them in a <download location> directory of your choice.

1. Add the OPatch patch to the WebLogic Image Tool cache, for example:

   ```bash
   $ imagetool cache addEntry --key 28186730_13.9.4.2.7 --value <downloaded-patches-location>/p28186730_139427_Generic.zip
   ```

1. Execute the `imagetool cache addEntry` command for each patch to add the required patch(es) to the WebLogic Image Tool cache. For example, to add patch `p32701831_12214210607_Generic.zip`:

   ```bash
   $ imagetool cache addEntry --key=33165837_12.2.1.4.210708 --value <downloaded-patches-location>/p33165837_12214210708_Generic.zip
   ```

1. Provide the following arguments to the WebLogic Image Tool `update` command:

   * `–-fromImage` - Identify the image that needs to be updated. In the example below, the image to be updated is `oracle/oig:12.2.1.4.0`.
   * `–-patches` - Multiple patches can be specified as a comma-separated list.
   * `--tag` - Specify the new tag to be applied for the image being built.

   Refer [here](https://oracle.github.io/weblogic-image-tool/userguide/tools/update-image/) for the complete list of options available with the WebLogic Image Tool `update` command.

   > Note: The WebLogic Image Tool cache should have the latest OPatch zip. The WebLogic Image Tool will update the OPatch if it is not already updated in the image.

   For example:
	
   ```bash
   $ imagetool update --fromImage oracle/oig:12.2.1.4.0 --tag=oracle/oig-new:12.2.1.4.0 --patches=33165837_12.2.1.4.210708 --opatchBugNumber=28186730_13.9.4.2.7
   ```

   > Note: If the command fails because the files in the image being upgraded are not owned by `oracle:oracle`, then add the parameter `--chown <userid>:<groupid>` to correspond with the values returned in the error.
  
1. Check the built image using the `docker images` command:
   
   ```bash
   $ docker images | grep oig
   ```
   
   The output will look similar to the following:
   
   ```
   REPOSITORY         TAG          IMAGE ID        CREATED             SIZE
   oracle/oig-new     12.2.1.4.0   0c8381922e95    16 seconds ago      4.91GB
   oracle/oig         12.2.1.4.0   298fdb98e79c    3 months ago        4.42GB
   ```
