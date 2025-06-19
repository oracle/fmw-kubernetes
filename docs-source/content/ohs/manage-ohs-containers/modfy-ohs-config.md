---
title: "b. Modifying the OHS container"
description: "Learn about modifying the OHS configuration."
---

This document shows how to modify the OHS configuration after the OHS container is deployed.

Modifying the deployed OHS container configuration can be achieved in the following ways:

a. [Editing the configuration files in $MYOHSFILES/ohsConfig](#editing-the-configuration-files-in-the-workdirohsconfig).

b. [Running kubectl edit configmap](#running-kubectl-edit-configmap).


### Editing the configuration files in the $MYOHSFILES/ohsConfig

To edit the configuration files:

1. Edit the required files in the `$MYOHSFILES/ohsConfig` directories.

1. Delete the configmaps for any files you have changed. For example if you have changed `httpd.conf` and files in `moduleconf`, run:

   ```
   $ kubectl delete cm ohs-httpd -n ohsns
   $ kubectl delete cm ohs-config -n ohsns
   ```
	
1. Recreate the required configmaps:
	
   ```	
   $ cd $MYOHSFILES
   $ kubectl create cm -n ohsns ohs-httpd --from-file=ohsConfig/httpconf
   $ kubectl create cm -n ohsns ohs-config --from-file=ohsConfig/moduleconf
   ```

1. Find the name of the existing OHS pod:

   ```bash
   $ kubectl get pods -n <namespace>
   ```

   For example:
	
   ```bash
   $ kubectl get pods -n ohsns
   ```
	
   The output will look similar to the following: 
  
   ```
   NAME                         READY   STATUS    RESTARTS   AGE
   ohs-domain-d5b648bc5-vkp4s   1/1     Running   0          55s
   ```

1. Delete the pod using the following command:

   ```
   $ kubectl delete pod <pod> -n <namespace>
   ```
	
   For example:
	
   ```
   $ kubectl delete pod ohs-domain-d5b648bc5-vkp4s -n ohsns
   ```
	
   The output will look similar to the following:
	
   ```
   pod "ohs-domain-d5b648bc5-vkp4s" deleted
   ```

1. Run the following command to make sure the pod has restarted:

   ```bash
   $ kubectl get pods -n ohsns
   ```

   The output will look similar to the following: 
   ```
   NAME                         READY   STATUS    RESTARTS   AGE
   ohs-domain-d5b648bc5-gdvnp   1/1     Running   0          39s
   ```




### Running kubectl edit configmap


1. Run the following command to edit the OHS configuration:


   ```bash
   $ kubectl edit configmap <configmap> -n <namespace>
   ```

   Where `<configmap>` is either `ohs-httpd` or `ohs-config` to modify the `httpd.conf` and `moduleconf` files respectively.
	

   For example:

   ```bash
   $ kubectl edit configmap ohs-httpd -n ohsns
   ```

   **Note**: This opens an edit session for the configmap where parameters can be changed using standard vi commands.

1. In the edit session, edit the required parameters accordingly. Save the file and exit `(:wq!)`.

1. Find the name of the existing OHS pod:

   ```bash
   $ kubectl get pods -n <namespace>
   ```
	
   For example:

   ```bash
   $ kubectl get pods -n ohsns
   ```

   The output will look similar to the following: 
   ```
   NAME                         READY   STATUS    RESTARTS   AGE
   ohs-domain-d5b648bc5-vkp4s   1/1     Running   0          2h33s
   ```
	
	
1. Delete the pod using the following command:

   ```
   $ kubectl delete pod <pod> -n <namespace>
   ```
	
   For example:
	
   ```
   $ kubectl delete pod ohs-domain-d5b648bc5-vkp4s -n ohsns
   ```
	
   The output will look similar to the following:
	
   ```
   pod "ohs-domain-d5b648bc5-vkp4s" deleted
   ```

1. Run the following command to make sure the pod has restarted:

   ```bash
   $ kubectl get pods -n ohsns -w
   ```

   The output will look similar to the following: 
   ```
   NAME                         READY   STATUS    RESTARTS   AGE
   ohs-domain-d5b648bc5-gdvnp   1/1     Running   0          39s
   ```
