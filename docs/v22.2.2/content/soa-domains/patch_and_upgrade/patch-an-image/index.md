---
title: "Patch an image"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 1
pre: "<b>a. </b>"
description: "Create a patched Oracle SOA Suite image using the WebLogic Image Tool."
---

Oracle releases Oracle SOA Suite images regularly with the latest bundle and recommended interim patches in My Oracle Support (MOS). However, if you need to create images with new bundle and interim patches, you can build these images using the WebLogic Image Tool.

If you have access to the Oracle SOA Suite patches, you can patch an existing Oracle SOA Suite image with a bundle patch and interim patches. Oracle recommends that you use the WebLogic Image Tool to patch the Oracle SOA Suite image.

> **Recommendations:**
>  * Use the WebLogic Image Tool [create]({{< relref "/soa-domains/create-or-update-image/#create-an-image" >}}) feature for patching the Oracle SOA Suite Docker image with a bundle patch and multiple interim patches. This is the recommended approach because it optimizes the size of the image.
>  * Use the WebLogic Image Tool [update]({{< relref "/soa-domains/create-or-update-image/#update-an-image" >}}) feature  for patching the Oracle SOA Suite Docker image with a single interim patch. Note that the patched image size may increase considerably due to additional image layers introduced by the patch application tool.


### Apply the patched Oracle SOA Suite image

To update an Oracle SOA Suite domain with a patched image, first make sure the patched image is pulled or created and available on the nodes in your Kubernetes cluster.
Once the patched image is available, you can follow these steps to update the Oracle SOA Suite domain with a patched image:

* [Stop all servers](#stop-all-servers)
* [Update user permissions of the domain PV storage](#update-user-permissions-of-the-domain-pv-storage)
* [Address post-installation requirements](#address-post-installation-requirements)
* [Apply the patched image](#apply-the-patched-image)


#### Stop all servers

>**Note**: The following steps are applicable only for non-Zero Downtime Patching. For Zero Downtime Patching, go to [Address post-installation requirements](#address-post-installation-requirements).

Before applying the patch, stop all servers in the domain:

1. In the `domain.yaml` configuration file, update the `spec.serverStartPolicy` field value to `NEVER`.

1. Shut down the domain (stop all servers) by applying the updated `domain.yaml` file:

   ```
   $ kubectl apply -f domain.yaml
   ```

#### Update user permissions of the domain PV storage

The Oracle SOA Suite image for release 22.2.2 has an oracle user with UID 1000, with the default group set to `root`. Before applying the patched image, update the user permissions of the domain persistent volume (PV) to set the group to `root`:

```
$ sudo chown -R 1000:0 /scratch/k8s_dir/SOA
```

#### Address post-installation requirements

If the patches in the patched Oracle SOA Suite image have any post-installation steps, follow these steps:

* [Create a Kubernetes pod with domain home access](#create-a-kubernetes-pod-with-domain-home-access)
* [Perform post-installation steps](#perform-post-installation-steps)

##### Create a Kubernetes pod with domain home access

1. Get domain home persistence volume claim details for the Oracle SOA Suite domain.

   For example, to list the persistent volume claim details in the namespace `soans`:
   ```
   $ kubectl get pvc -n soans   
   ```

   Sample output showing the persistent volume claim is `soainfra-domain-pvc`:
   ```
   NAME                  STATUS   VOLUME               CAPACITY   ACCESS MODES   STORAGECLASS                    AGE
   soainfra-domain-pvc   Bound    soainfra-domain-pv   10Gi       RWX            soainfra-domain-storage-class   xxd
   ```

1. Create a YAML `soapostinstall.yaml` using the domain home persistence volume claim.

   For example, using `soainfra-domain-pvc` per the sample output:

   > Note: Replace `soasuite:12.2.1.4-30761841` with the patched image in the following sample YAML:

   ```
   apiVersion: v1
   kind: Pod
   metadata:
     labels:
        run: soapostinstall
     name: soapostinstall
     namespace: soans
   spec:
    containers:
    - image: soasuite:12.2.1.4-30761841
      name: soapostinstall
      command: ["/bin/bash", "-c", "sleep infinity"]
      imagePullPolicy: IfNotPresent
      volumeMounts:
      - name: soainfra-domain-storage-volume
        mountPath: /u01/oracle/user_projects
    volumes:
    - name: soainfra-domain-storage-volume
      persistentVolumeClaim:
       claimName: soainfra-domain-pvc
   ```

1. Apply the YAML to create the Kubernetes pod:

   ```
   $ kubectl apply -f soapostinstall.yaml
   ```

##### Perform post-installation steps
If you need to perform any post-installation steps on the domain home:

1. Start a bash shell in the `soapostinstall` pod:

   ```
   $ kubectl exec -it -n soans soapostinstall -- bash
   ```

   This opens a bash shell in the running `soapostinstall` pod:

   ```
   [oracle@soapostinstall oracle]$
   ```

1. Use the bash shell of the `soapostinstall` pod and perform the required  steps on the domain home.

1. After successful completion of the post-installation steps, you can delete the `soapostinstall` pod:

   ```
   $ kubectl delete -f  soapostinstall.yaml
   ```

#### Apply the patched image

After completing the required SOA schema upgrade and post-installation steps, start up the domain:

1. In the `domain.yaml` configuration file, update the `image` field value with the patched image:   
   For example:

   ```
     image: soasuite:12.2.1.4-30761841
   ```

1. In case of non-Zero Downtime Patching, update the `spec.serverStartPolicy` field value to `IF_NEEDED` in `domain.yaml`.

1. Apply the updated `domain.yaml` configuration file to start up the domain.

   ```
   $ kubectl apply -f domain.yaml
   ```
   >**Note**: In case of non-Zero Downtime Patching, the complete domain startup happens, as the servers in the domain were stopped earlier. For Zero Downtime Patching, the servers in the domain are rolling restarted.

1. Verify the domain is updated with the patched image:

   ```
   $ kubectl describe domain <domainUID> -n <domain-namespace>|grep "Image:"
   ```

   Sample output:
   ```
   $ kubectl describe domain soainfra -n soans |grep "Image:"
   Image:                          soasuite:12.2.1.4-30761841
   $
   ```
