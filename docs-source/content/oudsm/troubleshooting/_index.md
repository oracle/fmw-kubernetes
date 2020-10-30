+++
title = "Troubleshooting"
date = 2019-04-18T07:32:31-05:00
weight = 8
pre = "<b>8. </b>"
description = "How to Troubleshoot issues."
+++
1. [Check the Status of a Namespace](#check-the-status-of-a-namespace)
1. [View POD Logs](#view-pod-logs)
1. [View Pod Description](#view-pod-description)

### Check the Status of a Namespace

To check the status of objects in a namespace use the following command:

```
$ kubectl --namespace <namespace> get nodes,pod,service,secret,pv,pvc,ingress -o wide
```

Output will be similar to the following:

```
$ kubectl --namespace myhelmns get nodes,pod,service,secret,pv,pvc,ingress -o wide
NAME                STATUS   ROLES    AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                  KERNEL-VERSION                  CONTAINER-RUNTIME
node/10.89.73.203   Ready    <none>   75d   v1.18.4   10.89.73.203   <none>        Oracle Linux Server 7.5   4.1.12-124.35.2.el7uek.x86_64   docker://19.3.11
node/10.89.73.204   Ready    <none>   75d   v1.18.4   10.89.73.204   <none>        Oracle Linux Server 7.5   4.1.12-124.38.1.el7uek.x86_64   docker://19.3.11
node/10.89.73.42    Ready    master   76d   v1.18.4   10.89.73.42    <none>        Oracle Linux Server 7.5   4.1.12-124.35.2.el7uek.x86_64   docker://19.3.11

NAME                 READY   STATUS    RESTARTS   AGE   IP            NODE           NOMINATED NODE   READINESS GATES
pod/my-oud-ds-rs-0   1/1     Running   0          83m   10.244.1.90   10.89.73.203   <none>           <none>
pod/my-oud-ds-rs-1   1/1     Running   0          83m   10.244.1.91   10.89.73.203   <none>           <none>
pod/my-oud-ds-rs-2   1/1     Running   0          83m   10.244.1.89   10.89.73.203   <none>           <none>

NAME                             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE   SELECTOR
service/my-oud-ds-rs-0           ClusterIP   10.100.226.50    <none>        1444/TCP,1888/TCP,1898/TCP   83m   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=my-oud-ds-rs-0
service/my-oud-ds-rs-1           ClusterIP   10.96.231.214    <none>        1444/TCP,1888/TCP,1898/TCP   83m   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=my-oud-ds-rs-1
service/my-oud-ds-rs-2           ClusterIP   10.99.254.14     <none>        1444/TCP,1888/TCP,1898/TCP   83m   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=my-oud-ds-rs-2
service/my-oud-ds-rs-http-0      ClusterIP   10.109.186.111   <none>        1080/TCP,1081/TCP            83m   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=my-oud-ds-rs-0
service/my-oud-ds-rs-http-1      ClusterIP   10.101.227.72    <none>        1080/TCP,1081/TCP            83m   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=my-oud-ds-rs-1
service/my-oud-ds-rs-http-2      ClusterIP   10.103.18.99     <none>        1080/TCP,1081/TCP            83m   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=my-oud-ds-rs-2
service/my-oud-ds-rs-lbr-admin   ClusterIP   10.105.211.54    <none>        1888/TCP,1444/TCP            83m   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
service/my-oud-ds-rs-lbr-http    ClusterIP   10.99.23.245     <none>        1080/TCP,1081/TCP            83m   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
service/my-oud-ds-rs-lbr-ldap    ClusterIP   10.103.171.90    <none>        1389/TCP,1636/TCP            83m   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
service/my-oud-ds-rs-ldap-0      ClusterIP   10.107.250.130   <none>        1389/TCP,1636/TCP            83m   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=my-oud-ds-rs-0
service/my-oud-ds-rs-ldap-1      ClusterIP   10.100.73.198    <none>        1389/TCP,1636/TCP            83m   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=my-oud-ds-rs-1
service/my-oud-ds-rs-ldap-2      ClusterIP   10.98.176.118    <none>        1389/TCP,1636/TCP            83m   app.kubernetes.io/instance=my-oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=my-oud-ds-rs-2

NAME                                        TYPE                                  DATA   AGE
secret/default-token-kfmhq                  kubernetes.io/service-account-token   3      84m
secret/my-oud-ds-rs-creds                   opaque                                8      83m
secret/my-oud-ds-rs-tls-cert                kubernetes.io/tls                     2      83m
secret/my-oud-ds-rs-token-c4tg4             kubernetes.io/service-account-token   3      83m
secret/sh.helm.release.v1.my-oud-ds-rs.v1   helm.sh/release.v1                    1      83m

NAME                                  CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                           STORAGECLASS                   REASON   AGE   VOLUMEMODE
persistentvolume/my-oud-ds-rs-espv1   20Gi       RWX            Retain           Available                                   elk                                     83m   Filesystem
persistentvolume/my-oud-ds-rs-pv      30Gi       RWX            Retain           Bound       myhelmns/my-oud-ds-rs-pvc       manual                                  83m   Filesystem
persistentvolume/oimcluster-oim-pv    10Gi       RWX            Retain           Bound       oimcluster/oimcluster-oim-pvc   oimcluster-oim-storage-class            63d   Filesystem

NAME                                     STATUS   VOLUME            CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE
persistentvolumeclaim/my-oud-ds-rs-pvc   Bound    my-oud-ds-rs-pv   30Gi       RWX            manual         83m   Filesystem

NAME                                                  CLASS    HOSTS                                                                        ADDRESS   PORTS     AGE
ingress.extensions/my-oud-ds-rs-admin-ingress-nginx   <none>   my-oud-ds-rs-admin-0,my-oud-ds-rs-admin-1,my-oud-ds-rs-admin-2 + 2 more...             80, 443   83m
ingress.extensions/my-oud-ds-rs-http-ingress-nginx    <none>   my-oud-ds-rs-http-0,my-oud-ds-rs-http-1,my-oud-ds-rs-http-2 + 3 more...                80, 443   83m
```

Include/exclude elements (nodes,pod,service,secret,pv,pvc,ingress) as required.

### View POD Logs

To view logs for a POD use the following command:

```
$ kubectl logs <pod> -n <namespace>
```

For example:

```
$ kubectl logs my-oudsm -n myhelmns
```

Output will depend on the application running in the POD.

### View Pod Description

Details about a POD can be viewed using the `kubectl describe` command:

```
$ kubectl describe pod <pod> -n <namespace>
```

For example:

```
$ kubectl describe pod my-oud-ds-rs-0 -n myhelmns
Name:         my-oud-ds-rs-0
Namespace:    myhelmns
Priority:     0
Node:         10.89.73.203/10.89.73.203
Start Time:   Wed, 07 Oct 2020 07:30:27 -0700
Labels:       app.kubernetes.io/instance=my-oud-ds-rs
              app.kubernetes.io/managed-by=Helm
              app.kubernetes.io/name=oud-ds-rs
              app.kubernetes.io/version=12.2.1.4.0
              helm.sh/chart=oud-ds-rs-0.1
              oud/instance=my-oud-ds-rs-0
Annotations:  meta.helm.sh/release-name: my-oud-ds-rs
              meta.helm.sh/release-namespace: myhelmns
Status:       Running
IP:           10.244.1.90
IPs:
  IP:  10.244.1.90
Containers:
  oud-ds-rs:
    Container ID:   docker://e3b79a283f56870e6d702cf8c2cc7aafa09a242f7a2cd543d8014a24aa219903
    Image:          oracle/oud:12.2.1.4.0
    Image ID:       docker://sha256:8a937042bef357fdeb09ce20d34332b14d1f1afe3ccb9f9b297f6940fdf32a76
    Ports:          1444/TCP, 1888/TCP, 1389/TCP, 1636/TCP, 1080/TCP, 1081/TCP, 1898/TCP
    Host Ports:     0/TCP, 0/TCP, 0/TCP, 0/TCP, 0/TCP, 0/TCP, 0/TCP
    State:          Running
      Started:      Wed, 07 Oct 2020 07:30:28 -0700
    Ready:          True
    Restart Count:  0
    Liveness:       tcp-socket :ldap delay=900s timeout=15s period=30s #success=1 #failure=1
    Readiness:      exec [/u01/oracle/container-scripts/checkOUDInstance.sh] delay=180s timeout=30s period=60s #success=1 #failure=10
    Environment:
      instanceType:            Directory
      sleepBeforeConfig:       3
      OUD_INSTANCE_NAME:       my-oud-ds-rs-0
      hostname:                my-oud-ds-rs-0
      baseDN:                  dc=example,dc=com
      rootUserDN:              <set to the key 'rootUserDN' in secret 'my-oud-ds-rs-creds'>        Optional: false
      rootUserPassword:        <set to the key 'rootUserPassword' in secret 'my-oud-ds-rs-creds'>  Optional: false
      adminConnectorPort:      1444
      httpAdminConnectorPort:  1888
      ldapPort:                1389
      ldapsPort:               1636
      httpPort:                1080
      httpsPort:               1081
      replicationPort:         1898
      sampleData:              10
    Mounts:
      /u01/oracle/user_projects from my-oud-ds-rs-pv (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from my-oud-ds-rs-token-c4tg4 (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  my-oud-ds-rs-pv:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  my-oud-ds-rs-pvc
    ReadOnly:   false
  my-oud-ds-rs-token-c4tg4:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  my-oud-ds-rs-token-c4tg4
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:          <none>
```


