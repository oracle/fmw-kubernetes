+++
title = "Patch and Upgrade"
weight = 8 
pre = "<b>8. </b>"
description=  "This document provides steps to patch or upgrade an OHS image."
+++

This section shows you how to patch or upgrade the the OHS image used by an OHS container.


1. To show the version of the image the OHS container is currently running, run the following command:

   ```
   $ kubectl describe pod <pod> -n <namespace> | grep Image
   ```
	
   For example:
	
   ```
   $ kubectl describe pod ohs-domain-d5b648bc5-qsgts -n ohsns | grep Image
   ```
	
   The output will look similar to the following:
	
   ```
   Image:         container-registry.oracle.com/middleware/ohs_cpu:12.2.1.4-jdk8-ol8-<version>
   Image ID:      9a7199ac903114793d6ad1f320010c3dbd59a39ad9bc987d926d3422a68603e7
   ```


1. Run the following command to update the container with the new image:

   ```
   $ kubectl set image deployment/ohs-domain -n <namespace> ohs=<new_image> 
   ```
	
   For example:
	
   ```
   $ kubectl set image deployment/ohs-domain -n ohsns ohs=container-registry.oracle.com/middleware/ohs_cpu:12.2.1.4-jdk8-ol8-<new> 
   ```
	
   The output will look similar to the following:
	
   ```
   deployment.apps/ohs-domain image updated
   ```
	
   This command will perform a rolling restart of the OHS container by shutting down the existing OHS container and starting a new one. 

1. Run the following kubectl command to view the pods:  

   ```bash 
   $ kubectl get pods -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl get pods -n ohsns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                         READY   STATUS              RESTARTS   AGE
   ohs-domain-5c9c9879d-kpt9j   0/1     ContainerCreating   0          8s
   ohs-domain-d5b648bc5-qsgts   1/1     Terminating         0          17h
   ```
	
   The existing OHS pod will move to a `STATUS` of `Terminating` and a new OHS pod will be started.
	
   To check what is happening while the pods are in `ContainerCreating` status, you can run:
	
   ```
   $ kubectl describe pod <podname> -n <namespace>
   ```
	
   To check what is happening while the pods are in  `0/1 Running` status, you can run:
	
   ```
   $ kubectl logs -f <pod> -n <namespace>
   ```


   Keep running the `kubectl get pods -n <namespace>` command until the pod is `Running` and at `READY 1\1`:
	
	   
   ```
   NAME                         READY   STATUS    RESTARTS   AGE 
   ohs-domain-5c9c9879d-kpt9j   1/1     Running   0          6m40s
   ```

1. To show the OHS container is running the new image, run the following command:


   ```
   $ kubectl describe pod <pod> -n <namespace> | grep Image
   ```
	
   For example:
	
   ```
   $ kubectl describe pod ohs-domain-5c9c9879d-kpt9j -n ohsns | grep Image
   ```
	
   The output will look similar to the following:
	
   ```
   Image:         container-registry.oracle.com/middleware/ohs_cpu:12.2.1.4-jdk8-ol8-<new>
   Image ID:      118c5c3713ddd6804cb699ecd0c7bd4a26ebf7e1427c5351c63244b5eb74ca94
   ```
	
   
  

