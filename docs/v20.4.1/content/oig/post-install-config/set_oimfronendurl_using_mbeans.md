+++
title = "a. Set OIMfrontendURL"
description = "Set the OIMfrontendURL in Oracle Enterprise Manager."
+++


### Set OIMFrontendURL using MBeans

1. Login to Oracle Enterprise Manager using the following URL:

   `https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/em`

1. Click the Target Navigation icon in the top left of the screen and navigate to the following:

   * Expand *Identity and Access* > *Access* > *OIM* > *oim*
   * Right click the instance *oim* and select *System MBean Browser*
   * Under *Application Defined MBeans*, navigate to *oracle.iam, Server:oim_server1, Application:oim* > *XMLConfig*  > *Config* > *XMLConfig.DiscoveryConfig* > *Discovery*.

1. Enter a new value for the `OimFrontEndURL` attribute, in the format:

   `http://<OIM-Cluster-Service-Name>:<Cluster-Service-Port>`

   For example:
 
   `http://oimcluster-cluster-oim-cluster:14000`
   
   Then click `Apply`.
   
   **Note**: To find the `<OIM-Cluster-Service-Name>` run the following command:

   ```
   $ kubectl -n oimcluster get svc
   ```

   Your output will look similar to this:

   ```
   $ kubectl -n oimcluster get svc
   NAME                             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)     AGE
   oimcluster-adminserver           ClusterIP   None             <none>        7001/TCP    6d23h
   oimcluster-cluster-oim-cluster   ClusterIP   10.107.191.53    <none>        14000/TCP   6d23h
   oimcluster-cluster-soa-cluster   ClusterIP   10.97.108.226    <none>        8001/TCP    6d23h
   oimcluster-oim-server1           ClusterIP   None             <none>        14000/TCP   6d23h
   oimcluster-oim-server2           ClusterIP   10.96.147.43     <none>        14000/TCP   6d23h
   oimcluster-oim-server3           ClusterIP   10.103.65.77     <none>        14000/TCP   6d23h
   oimcluster-oim-server4           ClusterIP   10.98.157.253    <none>        14000/TCP   6d23h
   oimcluster-oim-server5           ClusterIP   10.102.19.32     <none>        14000/TCP   6d23h
   oimcluster-soa-server1           ClusterIP   None             <none>        8001/TCP    6d23h
   oimcluster-soa-server2           ClusterIP   10.96.73.62      <none>        8001/TCP    6d23h
   oimcluster-soa-server3           ClusterIP   10.105.198.83    <none>        8001/TCP    6d23h
   oimcluster-soa-server4           ClusterIP   10.98.171.18     <none>        8001/TCP    6d23h
   oimcluster-soa-server5           ClusterIP   10.105.196.107   <none>        8001/TCP    6d23h
   ```



