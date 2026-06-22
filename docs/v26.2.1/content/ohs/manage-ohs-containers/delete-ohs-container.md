---
title: "c. Delete the OHS container"
description: "Learn about the steps to delete the OHS container."
---

The following commands show how to remove the OHS container, OHS nodeport service, configmaps, secrets, and namespace:


1. Run the following command to delete the OHS nodeport service:

   ```bash
   $ kubectl delete -f $MYOHSFILES/ohs_service.yaml
   ```

1. Run the following command to delete the OHS container:

   ```bash
   $ kubectl delete -f $MYOHSFILES/ohs.yaml
   ```

1. Run the following commands to delete any configmaps you have created, for example:

   ```
   $ kubectl delete cm -n ohsns ohs-config
   $ kubectl delete cm -n ohsns ohs-httpd
   $ kubectl delete cm -n ohsns ohs-htdocs
   $ kubectl delete cm -n ohsns ohs-myapp
   $ kubectl delete cm -n ohsns webgate-config
   $ kubectl delete cm -n ohsns webgate-wallet
   $ kubectl delete cm -n ohsns ohs-wallet
   ```
	
1. Run the following command to delete the secrets:

   ```
   $ kubectl delete secret regcred -n ohsns
   $ kubectl delete secret ohs-secret -n ohsns
   ```
	
1. Run the following command to delete the namespace:

   ```
   $ kubectl delete namespace ohsns
   ```
  
  
