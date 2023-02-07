---
title: "Launch Oracle Webcenter Content Native Applications in Containers deployed in Oracle Cloud Infrastructure"
date: 2020-12-3T07:32:31-05:00
weight: 7
pre : "<b>7. </b>"
description: "How to launch Oracle WebCenter Content native binaries from inside containerized environment in OCI."
---

This section provides the steps required to use Oracle WebCenter Content native binaries with user interfaces, from containerized Managed Servers deployed in OCI. 

### Issue with Launching Headful User Interfaces for Oracle WebCenter Content Native Binaries

Oracle WebCenter Content (UCM) provide a set of native binaries with headful UIs, which are delivered as part of the product container image. 
WebCenter Content container images are, by default, created with Oracle slim linux image, which doesn't come with all the packages pre-installed to support headful applications with UIs to be launched. UCM provides many such native binaries which uses JAVA AWT for UI support. 
With current Oracle WebCenter Content container images, native applications fails to run, being unable to launch UIs.

The following sections document the solution, by providing a set of instructions, enabling users to run UCM native applications with UIs.


These instructions are divided in two parts -
1. [Steps to update the existing container image](#steps-to-update-out-of-the-box-oracle-webcenter-content-container-image-using-weblogic-image-tool)
1. [Steps to launch native apps using VNC sessions](#steps-to-launch-oracle-webcenter-content-native-applications-using-vnc-sessions)


### Steps to Update out-of-the-box Oracle WebCenter Content Container Image Using WebLogic Image Tool

This section describes the method to update image with a OS package using WebLogic Image Tool. Please refer [this](https://oracle.github.io/weblogic-image-tool/) for setting up the WebLogic Image Tool.
#### Additional Build Commands

The installation of required OS packages in the image, can be done using yum command in additional build command option available in WebLogic Image Tool. Here is the sample `additionalBuildCmds.txt` file, to be used, to install required Linux packages (libXext.x86_64, libXrender.x86_64 and libXtst.x86_64).

```
[final-build-commands]
USER root
RUN yum -y --downloaddir=/tmp/imagetool install libXext libXrender libXtst  \
        && yum -y --downloaddir=/tmp/imagetool clean all \
    && rm -rf /var/cache/yum/* \
    && rm -rf /tmp/imagetool
USER oracle

```

>Note: It is important to change the user to `oracle`, otherwise the user during the container execution will be `root`.
#### Build arguments

The arguments required for updating the image can be passed as file to the WebLogic Image Tool.

    'update' is the sub command to Image Tool for updating an existing docker image.
    '--fromImage' option provides the existing docker image that has to be updated.
    '--tag' option should be provided with the new tag for the updated image.
    '--additionalBuildCommands' option should be provided with the above created additional build commands file.
	'--chown oracle:root' option should be provided to update file permissions.

Below is a sample build argument (buildArgs) file, to be used for updating the image,


```
  update
  --fromImage <existing_WCContent_image_without_dependent_packages>
  --tag <name_of_updated_WCContent_image_to_be_built>
  --additionalBuildCommands ./additionalBuildCmds.txt
  --chown oracle:root 
```

#### Update Oracle WebCenter Content Container Image

Now we can execute the WebLogic Image Tool to update the out-of-the-box image, using the build-argument file described above -

```
$ imagetool @buildArgs
```


WebLogic Image Tool provides multiple options for updating the image. For detailed information on the update options, please refer to [this](https://oracle.github.io/weblogic-image-tool/userguide/tools/update-image/) document.

Updating the image does not modify the 'CMD' from the source image unless it is modified in the additional build commands.

```
$ docker inspect -f '{{.Config.Cmd}}' <name_of_updated_Wccontent_image>
[/u01/oracle/container-scripts/createDomainandStartAdmin.sh]
```

### Steps to launch Oracle WebCenter Content native applications using VNC sessions.

Once updated image is successfully built and available on all required nodes, do the following:

a.  Update the domain.yaml file with updated image name and apply the domain.yaml file.  
```
$ kubectl apply -f domain.yaml
```

b.  After applying the modified domain.yaml, pods will get restarted and start running with updated image with required packages.

```
$ kubectl get pods -n <namespace_being_used_for_wccontent_domain>
```
c.  Install VNC SERVER on any one worker node, on which there is an UCM server pod deployed.

d.  After starting vncserver systemctl daemon in the Worker Node, execute the following command from Bastion Host to the Private Subnet Instance (Worker Node).

```
# The default VNC port is 5900, but that number is incremented according to the configured display number. Thus, display 1 corresponds to 5901, display 2 to 5902, and so on.
$ ssh -i <Workernode_private.key> -L 590<display_number>:localhost:590<display_number> -p 22 -L 590<display number>:localhost:590<display number> -N -f <user>@<Workernode_privateIPAddress>

# Sample command 
$ ssh -i <Workernode_private.key> -L 5901:localhost:5901 -p 22 -L 5901:localhost:5901 -N -f opc@10.0.10.xx
```

e.  From personal client execute the below command with the above session opened.

```
# Use any Linux emulator (like, Windows Power Shell for Windows) to run the following command
$ ssh -i <Bastionnode_private.key> -L 590<display_number>:localhost:590<display_number> -p 22 -L 590<display_number>:localhost:590<display_number> -N -f <user>@<BastionHost_publicIPAddress>

#  Sample command
$ ssh -i <Bastionnode_private.key> -L 5901:localhost:5901 -p 22 -L 5901:localhost:5901 -N -f opc@129.xxx.249.xxx
```

f.  Open VNC Client software in personal client and connect to Worker Node VNC Server using `localhost:590<display_number>`.

g.  Open a terminal once the VNC session to the Worker Node is connected -

```
$ xhost +
```
h.  Run the following commands from Bastion Host terminal –

```
# Get into the pod's (for example, wccinfra-ucm-server1) shell:
$ kubectl exec -n wccns -it wccinfra-ucm-server1 -- /bin/bash

# Traverse to the Native Binaries' location
$ cd /u01/oracle/user_projects/domains/wccinfra/ucm/cs/bin

# Set DISPLAY variable within the container
$ export DISPLAY=<Workernode_privateIPAddress, where VNC session was created>:<dispay_number>
# Sample command 
$ export DISPLAY=10.0.10.xx:1

# Launch any native UCM application, from within the container, like this:
$ ./SystemProperties 
```
i. If the application has an UI, it'll get launched now in the VNC session connected from personal client.


