---
title: "Launch Oracle Webcenter Content Native Applications in Containers"
date: 2020-12-3T07:32:31-05:00
weight: 4
pre : "<b>  </b>"
description: "How to launch Oracle WebCenter Content native binaries from inside containerized environment."
---

This section provides the steps required to use product native binaries with user interfaces.

### Issue with Launching Headful User Interfaces for Oracle WebCenter Content Native Binaries

Oracle WebCenter Content (UCM) provide a set of native binaries with headful UIs, which are located inside the persistent volume, as part of the domain. 
WebCenter Content container images are, by default, created with Oracle slim linux image, which doesn't come with all the packages pre-installed to support headful applications with UIs to be launched. With current Oracle WebCenter Content container images, running native applications fails, being unable to launch UIs.

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
c.  Create VNC sessions on the master node to launch native apps. These are the steps to be followed using the VNC session.

d.  Run this command on each VNC session:

```
$ xhost + <HOST-IP or HOST-NAME of the node, on which POD is deployed> 
```
>Note: The above command works for multi-node clusters (in which master node and worker nodes are deployed on different hosts and pods are distributed among worker nodes, running on different hosts). In case of single node clusters (where there is only master node and no worker nodes and all pods are deployed on the host, on which master node is
running), one needs to use container/pod’s IP instead of the master-node’s HOST-IP itself.

To obtain the container IP, follow the command mentioned in step `g`, from within that container's shell.

```
$ xhost + <IP of the container, from which binaries are to be run >  
```
e.  Get into the pod's (for example, `wccinfra-ucm-server1`) shell:

```
$ kubectl exec -n wccns -it wccinfra-ucm-server1 -- /bin/bash 
```
f.  Traverse to the binaries location:

```
$ cd /u01/oracle/user_projects/domains/wccinfra/ucm/cs/bin 
```
g.  Get the container IP:

```
$ hostname -i 
```
h.  Set DISPLAY variable within the container:

```
$ export DISPLAY=<HOST-IP/HOST-NAME of the master node, where VNC session was
created>:vnc-session display-id 
```
i.  Launch any native UCM application, from within the container, like this:

```
$ ./SystemProperties
```
If the application has an UI, it will get launched now.


