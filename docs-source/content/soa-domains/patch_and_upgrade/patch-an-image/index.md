---
title: "Patch an image"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 1
pre: "<b>a. </b>"
description: "Create a patched Oracle SOA Suite image using the WebLogic Image Tool."
---

Oracle releases Oracle SOA Suite images regularly with latest bundle and recommended interim patches in My Oracle Support (MOS). However, if there is a need to create images with new bundle and interim patches, you can build these images using WebLogic Image Tool.

If you have access to the Oracle SOA Suite patches, you can patch an existing Oracle SOA Suite image with a bundle patch and interim patches. It is recommended to use the WebLogic Image Tool to patch the Oracle SOA Suite image.

> **Recommendations:**
>  * Use the WebLogic Image Tool [create]({{< relref "/soa-domains/create-or-update-image/#create-an-image" >}}) feature for patching the Oracle SOA Suite Docker image with a bundle patch and multiple interim patches. This is the recommended approach because it optimizes the size of the image.
>  * Use the WebLogic Image Tool [update]({{< relref "/soa-domains/create-or-update-image/#update-an-image" >}}) feature  for patching the Oracle SOA Suite Docker image with a single interim patch. Note that the patched image size may increase considerably due to additional image layers introduced by the patch application tool.


#### Apply the patched image

1. Update the `image:` field in `domain.yaml` configuration file with the patched image.

1. Apply the updated `domain.yaml` configuration file:

    ``` bash
    $ kubectl apply -f domain.yaml
    ```
> Note: The server pods will be automatically restarted (rolling restart).
