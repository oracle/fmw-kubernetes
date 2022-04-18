---
title: "a. Patch an image"
description: "Instructions on how to update your OAM Kubernetes cluster with a new OAM container image."
---

Choose one of the following options to update your OAM kubernetes cluster to use the new image:

1. Run the `kubectl edit domain` command
2. Run the `kubectl patch domain` command

In all of the above cases, the WebLogic Kubernetes Operator will restart the Administration Server pod first and then perform a rolling restart on the OAM Managed Servers.

**Note**: If you are not using Oracle Container Registry or your own container registry, then you must first load the new container image on all nodes in your Kubernetes cluster. 

### Run the kubectl edit domain command

1. To update the domain with  the `kubectl edit domain` command, run the following:

   ```bash
   $ kubectl edit domain <domainname> -n <namespace>
   ```

   For example:

   ```bash
   $ kubectl edit domain accessdomain -n oamns
   ```
   
   If using Oracle Container Registry or your own container registry for your OAM container image, update the `image` <tag> to point at the new image, for example:

   ```
   domainHomeInImage: false
   image: container-registry.oracle.com/middleware/oam_cpu:<tag>
   imagePullPolicy: IfNotPresent
   ```
   
   If you are not using a container registry and have loaded the image on each of the master and worker nodes, update the `image` <tag> to point at the new image:
   
   ```
   domainHomeInImage: false
   image: oracle/oam:<tag>
   imagePullPolicy: IfNotPresent
   ```
   
   
1. Save the file and exit (:wq!)

### Run the kubectl patch command

1. To update the domain with the `kubectl patch domain` command, run the following:

   ```bash
   $ kubectl patch domain <domain> -n <namespace> --type merge  -p '{"spec":{"image":"newimage:tag"}}'
   ```
   

   For example, if using Oracle Container Registry or your own container registry for your OAM container image:

   ```bash
   $ kubectl patch domain accessdomain -n oamns --type merge  -p '{"spec":{"image":"container-registry.oracle.com/middleware/oam_cpu:<tag>"}}'
   ```
   
   For example, if you are not using a container registry and have loaded the image on each of the master and worker nodes:
   
   ```bash
   $ kubectl patch domain accessdomain -n oamns --type merge  -p '{"spec":{"image":"oracle/oam:<tag>"}}'
   ```

   The output will look similar to the following:

   ```
   domain.weblogic.oracle/accessdomain patched
   ```
