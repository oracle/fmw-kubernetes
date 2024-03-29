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
NAME                                      READY   STATUS    RESTARTS   AGE    IP             NODE                 NOMINATED NODE   READINESS GATES
pod/oud-ds-rs-0                           1/1     Running   1          2d2h   10.244.2.129   <Worker Node>   <none>           <none>
pod/oud-ds-rs-1                           1/1     Running   1          2d2h   10.244.2.128   <Worker Node>   <none>           <none>
pod/oud-ds-rs-2                           1/1     Running   1          2d2h   10.244.1.53    <Worker Node>   <none>           <none>

NAME                                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE    SELECTOR
service/oud-ds-rs-0                  ClusterIP   10.111.120.232   <none>        1444/TCP,1888/TCP,1898/TCP   2d2h   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-0
service/oud-ds-rs-1                  ClusterIP   10.98.199.92     <none>        1444/TCP,1888/TCP,1898/TCP   2d2h   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-1
service/oud-ds-rs-2                  ClusterIP   10.103.22.27     <none>        1444/TCP,1888/TCP,1898/TCP   2d2h   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-2
service/oud-ds-rs-http-0             ClusterIP   10.100.75.60     <none>        1080/TCP,1081/TCP            2d2h   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-0
service/oud-ds-rs-http-1             ClusterIP   10.96.125.29     <none>        1080/TCP,1081/TCP            2d2h   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-1
service/oud-ds-rs-http-2             ClusterIP   10.98.147.195    <none>        1080/TCP,1081/TCP            2d2h   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-2
service/oud-ds-rs-lbr-admin          ClusterIP   10.105.146.21    <none>        1888/TCP,1444/TCP            2d2h   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
service/oud-ds-rs-lbr-http           ClusterIP   10.101.185.178   <none>        1080/TCP,1081/TCP            2d2h   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
service/oud-ds-rs-lbr-ldap           ClusterIP   10.111.134.94    <none>        1389/TCP,1636/TCP            2d2h   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
service/oud-ds-rs-ldap-0             ClusterIP   10.102.210.144   <none>        1389/TCP,1636/TCP            2d2h   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-0
service/oud-ds-rs-ldap-1             ClusterIP   10.98.75.22      <none>        1389/TCP,1636/TCP            2d2h   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-1
service/oud-ds-rs-ldap-2             ClusterIP   10.110.130.119   <none>        1389/TCP,1636/TCP            2d2h   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-2

NAME                                     TYPE                                  DATA   AGE
secret/default-token-n2pmp               kubernetes.io/service-account-token   3      3d1h
secret/orclcred                          kubernetes.io/dockerconfigjson        1      3d
secret/oud-ds-rs-creds                   opaque                                8      2d2h
secret/oud-ds-rs-job-token-p4pz7         kubernetes.io/service-account-token   3      2d2h
secret/oud-ds-rs-tls-cert                kubernetes.io/tls                     2      2d2h
secret/oud-ds-rs-token-qzqt2             kubernetes.io/service-account-token   3      2d2h
secret/sh.helm.release.v1.oud-ds-rs.v1   helm.sh/release.v1                    1      2d2h
secret/sh.helm.release.v1.oud-ds-rs.v2   helm.sh/release.v1                    1      2d1h
secret/sh.helm.release.v1.oud-ds-rs.v3   helm.sh/release.v1                    1      2d1h
secret/sh.helm.release.v1.oud-ds-rs.v4   helm.sh/release.v1                    1      28h
secret/sh.helm.release.v1.oud-ds-rs.v5   helm.sh/release.v1                    1      25h
secret/sh.helm.release.v1.oud-ds-rs.v6   helm.sh/release.v1                    1      23h
secret/sh.helm.release.v1.oud-ds-rs.v7   helm.sh/release.v1                    1      23h

NAME                                 CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                               STORAGECLASS        REASON   AGE    VOLUMEMODE
persistentvolume/fmwk8s-jenkins-pv   1Gi        RWO,RWX        Delete           Bound    fmwk8s/fmwk8s-jenkins-pvc           fmwk8s-jenkins-pv            35d    Filesystem
persistentvolume/fmwk8s-pv           1Gi        RWO,RWX        Delete           Bound    fmwk8s/fmwk8s-pvc                   fmwk8s-pv                    35d    Filesystem
persistentvolume/fmwk8s-root-pv      1Gi        RWO,RWX        Delete           Bound    fmwk8s/fmwk8s-root-pvc              fmwk8s-root-pv               35d    Filesystem
persistentvolume/oud-ds-rs-espv1     20Gi       RWX            Retain           Bound    oudns/data-oud-ds-rs-es-cluster-0   elk-oud                      23h    Filesystem
persistentvolume/oud-ds-rs-job-pv    2Gi        RWX            Delete           Bound    oudns/oud-ds-rs-job-pvc             manual                       2d2h   Filesystem
persistentvolume/oud-ds-rs-pv        20Gi       RWX            Delete           Bound    oudns/oud-ds-rs-pvc                 manual                       2d2h   Filesystem

NAME                                                STATUS   VOLUME             CAPACITY   ACCESS MODES   STORAGECLASS   AGE    VOLUMEMODE
persistentvolumeclaim/data-oud-ds-rs-es-cluster-0   Bound    oud-ds-rs-espv1    20Gi       RWX            elk-oud        23h    Filesystem
persistentvolumeclaim/oud-ds-rs-job-pvc             Bound    oud-ds-rs-job-pv   2Gi        RWX            manual         2d2h   Filesystem
persistentvolumeclaim/oud-ds-rs-pvc                 Bound    oud-ds-rs-pv       20Gi       RWX            manual         2d2h   Filesystem

NAME                                                      CLASS    HOSTS                                                               ADDRESS   PORTS     AGE
ingress.networking.k8s.io/oud-ds-rs-admin-ingress-nginx   <none>   oud-ds-rs-admin-0,oud-ds-rs-admin-1,oud-ds-rs-admin-2 + 3 more...             80, 443   2d2h
ingress.networking.k8s.io/oud-ds-rs-http-ingress-nginx    <none>   oud-ds-rs-http-0,oud-ds-rs-http-1,oud-ds-rs-http-2 + 4 more...                80, 443   2d2h

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
Node:         <Worker Node>/100.102.48.84
Start Time:   <DATE>
Labels:       app.kubernetes.io/instance=oud-ds-rs
              app.kubernetes.io/managed-by=Helm
              app.kubernetes.io/name=oud-ds-rs
              app.kubernetes.io/version=12.2.1.4.0
              helm.sh/chart=oud-ds-rs-0.1
              oud/instance=oud-ds-rs-0
Annotations:  meta.helm.sh/release-name: oud-ds-rs
              meta.helm.sh/release-namespace: oudns
Status:       Running
IP:           10.244.2.129
IPs:
  IP:  10.244.2.129
Containers:
  oud-ds-rs:
    Container ID:   cri-o://2795176b6af2c17a9426df54214c7e53318db9676bbcf3676d67843174845d68
    Image:          container-registry.oracle.com/middleware/oud_cpu:12.2.1.4-jdk8-ol7-<January'23>
    Image ID:       container-registry.oracle.com/middleware/oud_cpu@sha256:6ba20e54d17bb41312618011481e9b35a40f36f419834d751277f2ce2f172dca
    Ports:          1444/TCP, 1888/TCP, 1389/TCP, 1636/TCP, 1080/TCP, 1081/TCP, 1898/TCP
    Host Ports:     0/TCP, 0/TCP, 0/TCP, 0/TCP, 0/TCP, 0/TCP, 0/TCP
    State:          Running
      Started:      <DATE>
    Last State:     Terminated
      Reason:       Error
      Exit Code:    137
      Started:      <DATE>
      Finished:     <DATE>
    Ready:          True
    Restart Count:  1
    Liveness:       tcp-socket :ldap delay=900s timeout=15s period=30s #success=1 #failure=1
    Readiness:      exec [/u01/oracle/container-scripts/checkOUDInstance.sh] delay=180s timeout=30s period=60s #success=1 #failure=10
    Environment:
      instanceType:            Directory
      sleepBeforeConfig:       3
      OUD_INSTANCE_NAME:       oud-ds-rs-0
      hostname:                oud-ds-rs-0
      baseDN:                  dc=example,dc=com
      rootUserDN:              <set to the key 'rootUserDN' in secret 'oud-ds-rs-creds'>        Optional: false
      rootUserPassword:        <set to the key 'rootUserPassword' in secret 'oud-ds-rs-creds'>  Optional: false
      adminConnectorPort:      1444
      httpAdminConnectorPort:  1888
      ldapPort:                1389
      ldapsPort:               1636
      httpPort:                1080
      httpsPort:               1081
      replicationPort:         1898
      sampleData:              0
    Mounts:
      /u01/oracle/user_projects from oud-ds-rs-pv (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-vr6v8 (ro)
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
  kube-api-access-vr6v8:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
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