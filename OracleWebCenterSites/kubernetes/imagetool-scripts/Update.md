Update WCSites image with patch using Imagetool
=============================================

**Note:-**

1. The `update` command can be used for updating the image with a one-off patch. Be aware that there may be considerable increase in the size of the image due to additional layers introduced by the OPatch execution.
2. For multiple patches/bundle patches, we recommend you to use `create` command of Imagetool.

## Contents

1. [Add patch to Imagetool cache](#1-add-patch-to-imagetool-cache)
2. [Update image](#2-update-image)
   - [Generated Dockerfile](#generated-dockerfile)
3. [Verify updated image](#4-verify-updated-image)


After you have created a Docker image with the Image Tool, you can update the image with patches using "update" command in Imagetool.

# 1. Add patch to Imagetool cache

Add the required patch to the Imagetool cache,
```bash wrap
$ imagetool cache addEntry --key 29710661_12.2.1.4.0 --value <download-path>/p29710661_122140_Generic.zip
[INFO   ] Added entry 29710661_12.2.1.4.0=<download-path>/p29710661_122140_Generic.zip
```
# 2. Update image
The following arguments should be provided to Imagetool update command,

1. "–-fromImage" - Identify the image that needs to be updated. In the below case, the image to be updated is "oracle/wcsites:12.2.1.4-21.1.1" as the value.

2. "–-patches" - The patches key/id should be provided as value. Multiple patches should be a comma separated list.

3. "--tag" - New tag to applied for the image being built.

**Note:-**

The Imagetool cache should have the latest OPatch zip. The Imagetool will update the OPatch if it is not already updated in the image.

Update the image using the following command,
```bash wrap
$ imagetool update --fromImage oracle/wcsites:12.2.1.4-21.1.1 --tag=oracle/wcsites:12.2.1.4-21.1.1-29710661 --patches=29710661_12.2.1.4.0

[INFO   ] Image Tool build ID: 7c268a9a-723f-424e-a06e-cb615c783e6d
[INFO   ] Temporary directory used for docker build context: <path-to-temp-dir>/tmpBuild/wlsimgbuilder_temp8555048225669509
[INFO   ] Using patch 28186730_13.9.4.2.4 from cache: <path-to-patches>/p28186730_139424_Generic.zip
[INFO   ] OPatch will not be updated, fromImage has version 13.9.4.2.4, available version is 13.9.4.2.4
[WARNING] skipping patch conflict check, no support credentials provided
[WARNING] No credentials provided, skipping validation of patches
[INFO   ] Using patch 31548912_12.2.1.4.0 from cache: <download-path>/p31548912_122140_Generic.zip
[INFO   ] docker cmd = docker build --no-cache --force-rm --tag oracle/wcsites:12.2.1.4-21.1.1-29710661 --build-arg http_proxy=http://www-proxy-your-company.com:80 --build-arg https_proxy=http://www-proxy-your-company.com:80 --build-arg no_proxy=localhost,127.0.0.0/8,100.111.157.58,/var/run/docker.sock <path-to-temp-dir>/tmpBuild/wlsimgbuilder_temp8555048225669509
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
OPatch continues with these patches:   31548912  

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
Applying interim patch '31548912' to OH '/u01/oracle'
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
Patch 31548912 successfully applied.
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
Successfully tagged oracle/wcsites:12.2.1.4-21.1.1-29710661
[INFO   ] Build successful. Build time=73s. Image tag=oracle/wcsites:12.2.1.4-21.1.1-29710661
```
## Generated Dockerfile
Below the Dockerfile generated by the Imagetool with "–dryRun" option,
```bash wrap
$ imagetool update --fromImage oracle/wcsites:12.2.1.4-21.1.1 --tag=oracle/wcsites:12.2.1.4-21.1.1-29710661 --patches=29710661_12.2.1.4.0 --dryRun

[INFO   ] Image Tool build ID: a2fca032-7807-4bfb-b5a4-0ed90a710a56
[INFO   ] Temporary directory used for docker build context: <path-to-temp-dir>/tmpBuild/wlsimgbuilder_temp4743247141639108603
[INFO   ] Using patch 28186730_13.9.4.2.4 from cache: <download-path>/p28186730_139424_Generic.zip
[INFO   ] OPatch will not be updated, fromImage has version 13.9.4.2.4, available version is 13.9.4.2.4
[WARNING] skipping patch conflict check, no support credentials provided
[WARNING] No credentials provided, skipping validation of patches
[INFO   ] Using patch 29710661_12.2.1.4.0 from cache: <download-path>/p29710661_122140_Generic.zip
[INFO   ] docker cmd = docker build --no-cache --force-rm --tag oracle/wcsites:12.2.1.4-21.1.1-29710661 --build-arg http_proxy=http://www-proxy-your-company.com:80 --build-arg https_proxy=http://www-proxy-your-company.com:80 --build-arg no_proxy=localhost,127.0.0.0/8,100.111.157.58,/var/run/docker.sock <path-to-tmp-directory>/tmpBuild/wlsimgbuilder_temp4743247141639108603
########## BEGIN DOCKERFILE ##########
#
# Copyright (c) 2021, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl
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
# 4. Verify updated image
List the built image using the following command,
```bash
$ docker images | grep wcsites
oracle/wcsites   12.2.1.4-21.1.1-29710661  445b649a3459        About a minute ago           3.2GB
oracle/wcsites   12.2.1.4-21.1.1   2ef2a67a685b        4 days ago   2.84GB

```
