---
title: "a. Patch an image"
description: "Instructions on how to update your OIG Kubernetes cluster with a new OIG docker image."
---

To update your OIG Kubernetes cluster with a new OIG Docker image, first install the new Docker image on all nodes in your Kubernetes cluster. 

Once the new image is installed choose one of the following options to update your OIG Kubernetes cluster to use the new image:

1. Run the `kubectl edit domain` command
2. Run the `kubectl patch domain` command

In all of the above cases, the WebLogic Kubernetes Operator will restart the Administration Server pod first and then perform a rolling restart on the OIG Managed Servers.


### Run the kubectl edit domain command

1. To update the domain with  the `kubectl edit domain` command, run the following:

   ```bash
   $ kubectl edit domain <domainname> -n <namespace>
   ```

   For example:

   ```bash
   $ kubectl edit domain governancedomain -n oigns
   ```

1. Update the `image` tag to point at the new image, for example:

   ```
   domainHomeInImage: false
   image: oracle/oig:12.2.1.4.0-new
   imagePullPolicy: IfNotPresent
   ```


1. Save the file and exit (:wq!)


### Run the kubectl patch command

1. To update the domain with the `kubectl patch domain` command, run the following:

   ```bash
   $ kubectl patch domain <domain> -n <namespace> --type merge  -p '{"spec":{"image":"newimage:tag"}}'
   ```

   For example:

   ```bash
   $ kubectl patch domain governancedomain -n oigns --type merge  -p '{"spec":{"image":"oracle/oig:12.2.1.4-new"}}'
   ```

   The output will look similar to the following:

   ```
   domain.weblogic.oracle/governancedomain patched
   ```

