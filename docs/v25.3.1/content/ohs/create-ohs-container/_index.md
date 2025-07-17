---
title: "Create the OHS Container and Nodeport"
weight: 5
pre : "<b>5. </b>"
description: "Deploying the OHS Container and Nodeport"
---

1. [Introduction](#introduction)
1. [Create the OHS Nodeport](#create-the-ohs-nodeport)
1. [Create the OHS Container](#create-the-ohs-container)
1. [Validating the OHS Container](#validating-the-ohs-container)
    
	a. [Validating the OHS container file system](#validating-the-ohs-container-file-system)
	
	b. [Validating the OHS nodeport](#validating-the-ohs-nodeport)

	
### Introduction

This section demonstrates how to create the OHS container and OHS nodeport.

The OHS nodeport is the Kubernetes entry port (HTTP/HTTPS) for OHS , for example 31777 (HTTP) and 31443 (HTTPS).

### Create the OHS Nodeport

In this section you create the OHS nodeport using the `$MYOHSFILES/ohs_service.yaml`. 

The nodeport is the entry point for OHS. For example `http://ohs.example.com:31777` or `https://ohs.example.com:31443`

1. Edit the `$MYOHSFILES/ohs_service.yaml` and make the following changes:

   + `<NAMESPACE>` to your namespace, for example `ohsns`.
   + If you want your OHS node port to listen on something other that 31777 and 31443, change accordingly
   + If you are using your own `httpd.conf` file and have changed the port to anything other than `7777`, you must change the `targetPort` and `port` to match.
   + If you are using your own `ssl.conf` file and have changed the port to anything other than `4443`, you must change the `targetPort` and `port` to match.
	
	
   ```
   kind: Service
   apiVersion: v1
   metadata:
     name: ohs-domain-nodeport
     namespace: ohsns
   spec:
     selector:
       oracle: ohs
     type: NodePort
     ports:
     - port: 7777
       name: http
       targetPort: 7777
       nodePort: 31777
       protocol: TCP
     - port: 4443
       name: https
       targetPort: 4443
       nodePort: 31443
       protocol: TCP
   ```
	

1. Run the following command to create a Kubernetes service nodeport for OHS.

   **Note**: Administrators should be aware of the following:
	
   + As this is a Kubernetes service the port is accessible on all the worker nodes in the cluster.
   + If you create another OHS container on a different port, you will need to create another nodeport service for that OHS.


   ```
   $ kubectl create -f $MYOHSFILES/ohs_service.yaml
   ```
	
   The output will look similar to the following:
	
   ```
   service/ohs-domain-nodeport created
   ```
	
1. Validate the service has been created using the command:
   
   ```
   $ kubectl get service -n <namespace>
   ```
	
   For example:
	
   ```
   $ kubectl get service -n ohsns
   ```
	
   The output will look similar to the following:
	
   ```
   NAME                  TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)                         AGE
   ohs-domain-nodeport   NodePort   10.98.163.75   <none>        7777:31777/TCP,4443:31443/TCP   22s
   ```
	
	

### Create the OHS Container

In this section you create the OHS container using the `ohs.yaml` file created in [Prepare the ohs.yaml file](../prepare-your-environment#prepare-the-ohsyaml-file).


1. Run the following command to create the OHS container:

   ```bash
   $ kubectl create -f $MYOHSFILES/ohs.yaml
   ```
   
   
   The output will look similar to the following:

   ```
   configmap/ohs-script-configmap created
   deployment.apps/ohs-domain created
   ```
	
   Run the following command to view the status of the pods:
   
   ```bash
   $ kubectl get pods -n <namespace> -w
   ```
	
   For example:
	
	
   ```bash
   $ kubectl get pods -n ohsns -w
   ```
	
   Whilst the OHS container is creating you, may see:
	
   ```
   NAME                         READY   STATUS              RESTARTS   AGE
   ohs-domain-d5b648bc5-vkp4s   0/1     ContainerCreating   0          2m13s
   ```
	
   To check what is happening while the pod is in `ContainerCreating` status, you can run:
	
   ```
   kubectl describe pod <podname> -n <namespace>
   ```
	
   For example:
	
   ```
   $ kubectl describe pod ohs-domain-d5b648bc5-vkp4s -n ohsns
   ```
	
   Once the container is created, it will go to a `READY` status of `0/1` with `STATUS` of `Running`. For example:
	
   ```
   NAME                         READY   STATUS    RESTARTS   AGE
   ohs-domain-d5b648bc5-vkp4s   1/1     Running   0          3m10s
   ```
	
   To check what is happening while the pod is in this status, you can run:
	
   ```
   $ kubectl logs -f <pod> -n <namespace>
   ```
		
   Once everything is started you should see the OHS is running (`READY 1/1`):
   
   ```
   NAME                         READY   STATUS    RESTARTS   AGE
   ohs-domain-d5b648bc5-vkp4s   1/1     Running   0          4m10s
   ```

   If there are any failures, follow [Troubleshooting](../troubleshooting).


	


## Validating the OHS Container

In this section you validate the OHS container and check you can access OHS using the nodeport.

### Validating the OHS container file system

To validate the OHS container file system:

1. Run the following command to get the name of the OHS container:

  
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
   ohs-domain-d5b648bc5-vkp4s   1/1     Running   0          5m34s
   ```

1. Run the following command to create a bash shell inside the container:

   ```
   $ kubectl exec -n <namespace> -ti <pod> -- /bin/bash
   ```
	
   For example:
	
   ```
   $ kubectl exec -n ohsns -ti ohs-domain-79f8f99575-8qwfh -- /bin/bash
   ```
	
   This will take you to a bash shell inside the container:
	
   ```
   [oracle@ohs-domain-75fbd9b597-z77d8 oracle]$
   ```

1. Inside the bash shell navigate to the `/u01/oracle/user_projects/domains/ohsDomain/config/fmwconfig/components/OHS/ohs1/` directory:

   ```
   cd  /u01/oracle/user_projects/domains/ohsDomain/config/fmwconfig/components/OHS/ohs1/
   ```	
	
   From within this directory, you can navigate around and list (`ls`) or  `cat` any files you configured using the configmaps.



### Validating the OHS nodeport

In this section you validate the OHS nodeport by accessing the OHS URL's.

In the examples below, `${OHS-HOSTNAME}` refers to the hostname.domain of the server where the OHS nodeport was deployed. `${OHS-NODEPORT}` refers to the `nodePort` specified in your `ohs-service.yaml`, for example `31777`for HTTP, or `31443` for HTTPS.

**Note**: If OHS is accessed via a loadbalancer, replace `${OHS-HOSTNAME}` and `${OHS-NODEPORT}` with the loadbalancer hostname.domain and port.

If you have any problems accessing the URL's, refer to [Troubleshooting](../troubleshooting).
	
Launch a browser and access the following:

   **Note**: If you have deployed OHS with WebGate, then it will depend on your policy setup as to whether the URL's below are accessible or not.

   a) The OHS homepage `http(s)://${OHS-HOSTNAME}:${OHS-NODEPORT}`.
	
   b) Any other files copied in your `ohs-htdocs` configmap, for example `http(s)://${OHS-HOSTNAME}:${OHS-NODEPORT}/mypage.html`.
	
   c) Any files from directories crested under `htdocs`, for example the `ohs-myapp` configmap, for example `http(s)://${OHS-HOSTNAME}:${OHS-NODEPORT}/myapp`.
	
   d) Any URI's defined for mod_wl_ohs in your `httpd.conf`, `ssl.conf` or `moduleconf/*.conf` files, for example `http(s)://${OHS-HOSTNAME}:${OHS-NODEPORT}/console`.
	
   e) If WebGate is deployed, any protected applications, for example `http(s)://${OHS-HOSTNAME}:${OHS-NODEPORT}/myprotectedapp`.
	

	
	
