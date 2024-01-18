+++
title = "Troubleshooting"
weight = 10
pre = "<b>10. </b>"
description = "How to Troubleshoot issues."
+++
1. [Check the status of a namespace](#check-the-status-of-a-namespace)
1. [View pod logs](#view-pod-logs)
1. [View pod description](#view-pod-description)
1. [Known issues](#known-issues)

### Check the status of a namespace

To check the status of objects in a namespace use the following command:

```bash
$ kubectl --namespace <namespace> get nodes,pod,service,secret,pv,pvc,ingress -o wide
```

For example:

```bash
$ kubectl --namespace oudns get pod,service,secret,pv,pvc,ingress -o wide
```

The output will look similar to the following:

```
NAME                                  READY   STATUS      RESTARTS   AGE     IP             NODE            NOMINATED NODE   READINESS GATES
pod/oud-ds-rs-0                       1/1     Running     0          14m     10.244.1.180   <Worker Node>   <none>           <none>
pod/oud-ds-rs-1                       1/1     Running     0          8m26s   10.244.1.181   <Worker Node>   <none>           <none>
pod/oud-ds-rs-2                       0/1     Running     0          2m24s   10.244.1.182   <Worker Node>   <none>           <none>
pod/oud-pod-cron-job-27586680-p5d8q   0/1     Completed   0          50s     10.244.1.183   <Worker Node>   <none>           <none>

NAME                          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                          AGE   SELECTOR
service/oud-ds-rs             ClusterIP   None             <none>        1444/TCP,1888/TCP,1389/TCP,1636/TCP,1080/TCP,1081/TCP,1898/TCP   14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
service/oud-ds-rs-0           ClusterIP   None             <none>        1444/TCP,1888/TCP,1898/TCP                                       14m app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-0
service/oud-ds-rs-1           ClusterIP   None             <none>        1444/TCP,1888/TCP,1898/TCP                                       14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-1
service/oud-ds-rs-2           ClusterIP   None             <none>        1444/TCP,1888/TCP,1898/TCP                                       14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-2
service/oud-ds-rs-http-0      ClusterIP   10.104.112.93    <none>        1080/TCP,1081/TCP                                                14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-0
service/oud-ds-rs-http-1      ClusterIP   10.103.105.70    <none>        1080/TCP,1081/TCP                                                14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-1
service/oud-ds-rs-http-2      ClusterIP   10.110.160.107   <none>        1080/TCP,1081/TCP                                                14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-2
service/oud-ds-rs-lbr-admin   ClusterIP   10.99.238.222    <none>        1888/TCP,1444/TCP                                                14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
service/oud-ds-rs-lbr-http    ClusterIP   10.101.250.196   <none>        1080/TCP,1081/TCP                                                14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
service/oud-ds-rs-lbr-ldap    ClusterIP   10.104.149.90    <none>        1389/TCP,1636/TCP                                                14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
service/oud-ds-rs-ldap-0      ClusterIP   10.109.255.221   <none>        1389/TCP,1636/TCP                                                14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-0
service/oud-ds-rs-ldap-1      ClusterIP   10.111.135.142   <none>        1389/TCP,1636/TCP                                                14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-1
service/oud-ds-rs-ldap-2      ClusterIP   10.100.8.145     <none>        1389/TCP,1636/TCP                                                14m   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,statefulset.kubernetes.io/pod-name=oud-ds-rs-2

NAME                                     TYPE                             DATA   AGE
secret/dockercred                        kubernetes.io/dockerconfigjson   1      4h24m
secret/orclcred                          kubernetes.io/dockerconfigjson   1      14m
secret/oud-ds-rs-creds                   opaque                           8      14m
secret/oud-ds-rs-tls-cert                kubernetes.io/tls                2      14m
secret/sh.helm.release.v1.oud-ds-rs.v1   helm.sh/release.v1               1      14m


NAME                                 CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                       STORAGECLASS        REASON   AGE    VOLUMEMODE
persistentvolume/oud-ds-rs-pv        20Gi       RWX            Delete           Bound    oudns/oud-ds-rs-pvc         manual                       14m    Filesystem

NAME                                  STATUS   VOLUME         CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE
persistentvolumeclaim/oud-ds-rs-pvc   Bound    oud-ds-rs-pv   20Gi       RWX            manual         14m   Filesystem

NAME                                                      CLASS    HOSTS                                                               ADDRESS   PORTS     AGE
ingress.networking.k8s.io/oud-ds-rs-admin-ingress-nginx   <none>   oud-ds-rs-admin-0,oud-ds-rs-admin-0,oud-ds-rs-admin-1 + 3 more...             80, 443   14m
ingress.networking.k8s.io/oud-ds-rs-http-ingress-nginx    <none>   oud-ds-rs-http-0,oud-ds-rs-http-1,oud-ds-rs-http-2 + 3 more...                80, 443   14m
```

Include/exclude elements (nodes,pod,service,secret,pv,pvc,ingress) as required.

### View pod logs

To view logs for a pod use the following command:

```bash
$ kubectl logs <pod> -n <namespace>
```

For example:

```
$ kubectl logs oud-ds-rs-0 -n oudns
```

### View pod description

Details about a pod can be viewed using the `kubectl describe` command:

```bash
$ kubectl describe pod <pod> -n <namespace>
```

For example:

```bash
$ kubectl describe pod oud-ds-rs-0 -n oudns
```

The output will look similar to the following:

```
Name:         oud-ds-rs-0
Namespace:    oudns
Priority:     0
Node:         <Worker Node>/100.105.18.114
Start Time:   <DATE>
Labels:       app.kubernetes.io/instance=oud-ds-rs
              app.kubernetes.io/name=oud-ds-rs
              controller-revision-hash=oud-ds-rs-5c8b8f67c9
              statefulset.kubernetes.io/pod-name=oud-ds-rs-0
Annotations:  <none>
Status:       Running
IP:           10.244.2.48
IPs:
  IP:           10.244.2.48
Controlled By:  StatefulSet/oud-ds-rs
Init Containers:
  mount-pv:
    Container ID:  cri-o://905af11c6f032f2dfa18b1e3956d7936cb7dd04d9d0df0cfcf8ed061e6930b52
    Image:         <location>/busybox
    Image ID:      <location>@sha256:2c8ed5408179ff4f53242a4bdd2706110ce000be239fe37a61be9c52f704c437
    Port:          <none>
    Host Port:     <none>
    Command:
      /bin/sh
      -c
    Args:
      ordinal=${OUD_INSTANCE_NAME##*-}; if [[ ${CLEANUP_BEFORE_START} == "true" ]]; then if [[ "$ordinal" != "0" ]]; then cd /u01/oracle; rm -fr /u01/oracle/user_projects/$(OUD_INSTANCE_NAME)/OUD; fi; fi
      if [[ ${CONFIGVOLUME_ENABLED} == "true" ]]; then if [[ "$ordinal" == "0" ]]; then cp "/mnt/baseOUD.props" "${CONFIGVOLUME_MOUNTPATH}/config-baseOUD.props"; else cp "/mnt/replOUD.props" "${CONFIGVOLUME_MOUNTPATH}/config-replOUD.props"; fi; fi;
    State:          Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      <DATE>
      Finished:     <DATE>
    Ready:          True
    Restart Count:  0
    Environment:
      OUD_INSTANCE_NAME:       oud-ds-rs-0 (v1:metadata.name)
      CONFIGVOLUME_ENABLED:    false
      CONFIGVOLUME_MOUNTPATH:  /u01/oracle/config-input
      CLEANUP_BEFORE_START:    false
    Mounts:
      /u01/oracle/user_projects from oud-ds-rs-pv (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-65skp (ro)
Containers:
  oud-ds-rs:
    Container ID:   cri-o://d691b090dfbb1ee1b8606952497d80642424a82a2290071b325ea720098817c3
    Image:          container-registry.oracle.com/middleware/oud_cpu:12.2.1.4-jdk8-ol8-<January'24>
    Image ID:       container-registry.oracle.com/middleware/oud_cpu@sha256:faca16dbbcda1985ff567eefe3f2ca7bae6cbbb7ebcd296fffb040ce61e9396a
    Ports:          1444/TCP, 1888/TCP, 1389/TCP, 1636/TCP, 1080/TCP, 1081/TCP, 1898/TCP
    Host Ports:     0/TCP, 0/TCP, 0/TCP, 0/TCP, 0/TCP, 0/TCP, 0/TCP
    State:          Running
      Started:      <DATE>
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     1
      memory:  4Gi
    Requests:
      cpu:      500m
      memory:   4Gi
    Liveness:   tcp-socket :ldap delay=300s timeout=30s period=60s #success=1 #failure=5
    Readiness:  exec [/u01/oracle/container-scripts/checkOUDInstance.sh] delay=300s timeout=30s period=60s #success=1 #failure=10
    Environment:
      instanceType:                   DS2RS_STS
      OUD_INSTANCE_NAME:              oud-ds-rs-0 (v1:metadata.name)
      MY_NODE_NAME:                    (v1:spec.nodeName)
      MY_POD_NAME:                    oud-ds-rs-0 (v1:metadata.name)
      sleepBeforeConfig:              3
      sourceHost:                     oud-ds-rs-0
      baseDN:                         dc=example,dc=com
      rootUserDN:                     <set to the key 'rootUserDN' in secret 'oud-ds-rs-creds'>        Optional: false
      rootUserPassword:               <set to the key 'rootUserPassword' in secret 'oud-ds-rs-creds'>  Optional: false
      adminUID:                       <set to the key 'adminUID' in secret 'oud-ds-rs-creds'>          Optional: false
      adminPassword:                  <set to the key 'adminPassword' in secret 'oud-ds-rs-creds'>     Optional: false
      bindDN1:                        <set to the key 'bindDN1' in secret 'oud-ds-rs-creds'>           Optional: false
      bindPassword1:                  <set to the key 'bindPassword1' in secret 'oud-ds-rs-creds'>     Optional: false
      bindDN2:                        <set to the key 'bindDN2' in secret 'oud-ds-rs-creds'>           Optional: false
      bindPassword2:                  <set to the key 'bindPassword2' in secret 'oud-ds-rs-creds'>     Optional: false
      sourceServerPorts:              oud-ds-rs-0:1444
      sourceAdminConnectorPort:       1444
      sourceReplicationPort:          1898
      sampleData:                     200
      adminConnectorPort:             1444
      httpAdminConnectorPort:         1888
      ldapPort:                       1389
      ldapsPort:                      1636
      httpPort:                       1080
      httpsPort:                      1081
      replicationPort:                1898
      dsreplication_1:                verify --hostname ${sourceHost} --port ${sourceAdminConnectorPort} --baseDN ${baseDN} --serverToRemove $(OUD_INSTANCE_NAME):${adminConnectorPort} --connectTimeout 600000 --readTimeout 600000
      dsreplication_2:                enable --host1 ${sourceHost} --port1 ${sourceAdminConnectorPort} --replicationPort1 ${sourceReplicationPort} --host2 $(OUD_INSTANCE_NAME) --port2 ${adminConnectorPort} --replicationPort2 ${replicationPort} --baseDN ${baseDN} --connectTimeout 600000 --readTimeout 600000
      dsreplication_3:                initialize --hostSource ${initializeFromHost} --portSource ${sourceAdminConnectorPort} --hostDestination $(OUD_INSTANCE_NAME) --portDestination ${adminConnectorPort} --baseDN ${baseDN} --connectTimeout 600000 --readTimeout 600000
      dsreplication_4:                verify --hostname $(OUD_INSTANCE_NAME) --port ${adminConnectorPort} --baseDN ${baseDN} --connectTimeout 600000 --readTimeout 600000
      post_dsreplication_dsconfig_1:  set-replication-domain-prop --domain-name ${baseDN} --set group-id:1
      post_dsreplication_dsconfig_2:  set-replication-server-prop --set group-id:1
    Mounts:
      /u01/oracle/user_projects from oud-ds-rs-pv (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-65skp (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  oud-ds-rs-pv:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  oud-ds-rs-pvc
    ReadOnly:   false
  kube-api-access-65skp:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   Burstable
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:                      <none>

```

### Known issues

#### dsreplication output after scale up/down shows pod in unknown state

Sometimes when scaling up or down, it is possible to get incorrect data in the `dsreplication` output. In the example below the `replicaCount` was changed from `4` to `3`. The `oud-ds-rs-3` server appears as `<Unknown>` when it should have disappeared:

```
dc=example,dc=com - Replication Enabled
=======================================
 
Server                         : Entries : M.C. [1] : A.O.M.C. [2] : Port [3] : Encryption [4] : Trust [5] : U.C. [6] : Status [7] : ChangeLog [8] : Group ID [9] : Connected To [10]
-------------------------------:---------:----------:--------------:----------:----------------:-----------:----------:------------:---------------:--------------:-------------------------------
oud-ds-rs-3:<Unknown>          : --      : N/A      : --           : 1898     : Disabled       : --        : --       : Unknown    : --            : N/A          : --
[11]                           :         :          :              :          :                :           :          :            :               :              :
oud-ds-rs-0:1444               : 39135   : 0        : 0            : 1898     : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : oud-ds-rs-2:1898
                               :         :          :              :          :                :           :          :            :               :              : (GID=1)
oud-ds-rs-1:1444               : 39135   : 0        : 0            : 1898     : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : oud-ds-rs-1:1898
                               :         :          :              :          :                :           :          :            :               :              : (GID=1)
oud-ds-rs-2:1444               : 39135   : 0        : 0            : 1898     : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : oud-ds-rs-2:1898
                               :         :          :              :          :                :           :          :            :               :              : (GID=1)
 
Replication Server [12]       : RS #1 : RS #2 : RS #3 : RS #4
------------------------------:-------:-------:-------:------
oud-ds-rs-0:1898 (#1)  : --    : Yes   : Yes   : N/A
oud-ds-rs-1:1898 (#2)  : Yes   : --    : Yes   : N/A
oud-ds-rs-2:1898 (#3)  : Yes   : Yes   : --    : N/A
oud-ds-rs-3:1898 (#4)  : No    : No    : No    : --

```

In this situation perform the following steps to remove the <Unknown> server:

1. Run the following command to enter the OUD Kubernetes pod:

   ```
   $ kubectl --namespace <namespace> exec -it -c <containername> <podname> -- bash
   ```
   
   For example:
   
   ```
   kubectl --namespace oudns exec -it -c oud-ds-rs oud-ds-rs-0 -- bash
   ```
   
   This will take you into the pod:

   ```
   [oracle@oud-ds-rs-0 oracle]$
   ```
   
 
1. Once inside the pod run the following command to create a password file:

   ```
   echo <ADMIN_PASSWORD> > /tmp/adminpassword.txt
   ```

1. Run the following command to remove the `replicationPort`:

   ```
   /u01/oracle/oud/bin/dsreplication disable --hostname localhost --port $adminConnectorPort --adminUID admin --trustAll --adminPasswordFile /tmp/adminpassword.txt --no-prompt --unreachableServer oud-ds-rs-3:$replicationPort
   ```
   
   The output will look similar to the following:
   
   ```
   Establishing connections and reading configuration ........ Done.
 
   The following errors were encountered reading the configuration of the
   existing servers:
   Could not connect to the server oud-ds-rs-3:1444.  Check that the
   server is running and that is accessible from the local machine.  Details:
   oud-ds-rs-3:1444
   The tool will try to update the configuration in a best effort mode.
 
   Removing references to replication server oud-ds-rs-3:1898 ..... Done.
   ```

1. Run the following command to remove the `adminConnectorPort`:

   ```
   /u01/oracle/oud/bin/dsreplication disable --hostname localhost --port $adminConnectorPort --adminUID admin --trustAll --adminPasswordFile /tmp/adminpassword.txt --no-prompt --unreachableServer oud-ds-rs-3:$adminConnectorPort
   ```
   
   The output will look similar to the following:
   
   ```
   Establishing connections and reading configuration ...... Done.
 
   Removing server oud-ds-rs-3:1444 from the registration information ..... Done.
   ```
   
1. Delete the password file:

   ```
   rm /tmp/adminpassword.txt
   ```