+++
title = "Troubleshooting"
date = 2019-04-18T07:32:31-05:00
weight = 6
pre = "<b>6. </b>"
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
$ kubectl --namespace oudns get nodes,pod,service,secret,pv,pvc,ingress -o wide
NAME              READY   STATUS    RESTARTS   AGE     IP             NODE            NOMINATED NODE   READINESS GATES
pod/oud-ds-rs-0   1/1     Running   0          8m44s   10.244.0.195   <Worker Node>   <none>           <none>
pod/oud-ds-rs-1   1/1     Running   0          8m44s   10.244.0.194   <Worker Node>   <none>           <none>
pod/oud-ds-rs-2   0/1     Running   0          8m44s   10.244.0.193   <Worker Node>   <none>           <none>
    
NAME                          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE     SELECTOR
service/oud-ds-rs-0           ClusterIP   10.99.232.83     <none>        1444/TCP,1888/TCP,1898/TCP   8m44s   kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-0
service/oud-ds-rs-1           ClusterIP   10.100.186.42    <none>        1444/TCP,1888/TCP,1898/TCP   8m45s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-1
service/oud-ds-rs-2           ClusterIP   10.104.55.53     <none>        1444/TCP,1888/TCP,1898/TCP   8m45s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-2
service/oud-ds-rs-http-0      ClusterIP   10.102.116.145   <none>        1080/TCP,1081/TCP            8m45s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-0
service/oud-ds-rs-http-1      ClusterIP   10.111.103.84    <none>        1080/TCP,1081/TCP            8m44s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-1
service/oud-ds-rs-http-2      ClusterIP   10.105.53.24     <none>        1080/TCP,1081/TCP            8m45s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-2
service/oud-ds-rs-lbr-admin   ClusterIP   10.98.39.206     <none>        1888/TCP,1444/TCP            8m45s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
service/oud-ds-rs-lbr-http    ClusterIP   10.110.77.132    <none>        1080/TCP,1081/TCP            8m45s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
service/oud-ds-rs-lbr-ldap    ClusterIP   10.111.55.122    <none>        1389/TCP,1636/TCP            8m45s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs
service/oud-ds-rs-ldap-0      ClusterIP   10.108.155.81    <none>        1389/TCP,1636/TCP            8m44s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-0
service/oud-ds-rs-ldap-1      ClusterIP   10.104.88.44     <none>        1389/TCP,1636/TCP            8m45s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-1
service/oud-ds-rs-ldap-2      ClusterIP   10.105.253.120   <none>        1389/TCP,1636/TCP            8m45s   app.kubernetes.io/instance=oud-ds-rs,app.kubernetes.io/name=oud-ds-rs,oud/instance=oud-ds-rs-2
    
NAME                                        TYPE                                  DATA   AGE
secret/default-token-tbjr5                  kubernetes.io/service-account-token   3      25d
secret/oud-ds-rs-creds                      opaque                                8      8m48s
secret/oud-ds-rs-token-cct26                kubernetes.io/service-account-token   3      8m50s
secret/sh.helm.release.v1.oud-ds-rs.v1      helm.sh/release.v1                    1      8m51s
    
NAME                               CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                    STORAGECLASS   REASON   AGE
persistentvolume/oud-ds-rs-pv      20Gi       RWX            Retain           Bound    oudns/oud-ds-rs-pvc      manual                  8m47s
 
NAME                                  STATUS   VOLUME         CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/oud-ds-rs-pvc   Bound    oud-ds-rs-pv   20Gi       RWX            manual         8m48s
   
NAME                                               HOSTS                                                               ADDRESS         PORTS   AGE
ingress.extensions/oud-ds-rs-admin-ingress-nginx   oud-ds-rs-admin-0,oud-ds-rs-admin-1,oud-ds-rs-admin-2 + 2 more...   10.229.141.78   80      8m45s
ingress.extensions/oud-ds-rs-http-ingress-nginx    oud-ds-rs-http-0,oud-ds-rs-http-1,oud-ds-rs-http-2 + 3 more...      10.229.141.78   80      8m45s
```

Include/exclude elements (nodes,pod,service,secret,pv,pvc,ingress) as required.

### View POD Logs

To view logs for a POD use the following command:

```
$ kubectl logs <pod> -n <namespace>
```

For example:

```
$ kubectl logs oud-ds-rs-0 -n oudns
```

Output will depend on the application running in the POD.

### View Pod Description

Details about a POD can be viewed using the `kubectl describe` command:

```
$ kubectl describe pod <pod> -n <namespace>
```

For example:

```
$ kubectl describe pod oud-ds-rs-0 -n oudns
Name:         oud-ds-rs-0
Namespace:    oudns
Priority:     0
Node:         10.89.73.203/10.89.73.203
Start Time:   Wed, 07 Oct 2020 07:30:27 -0700
Labels:       app.kubernetes.io/instance=oud-ds-rs
              app.kubernetes.io/managed-by=Helm
              app.kubernetes.io/name=oud-ds-rs
              app.kubernetes.io/version=12.2.1.4.0
              helm.sh/chart=oud-ds-rs-0.1
              oud/instance=oud-ds-rs-0
Annotations:  meta.helm.sh/release-name: oud-ds-rs
              meta.helm.sh/release-namespace: oudns
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
      sampleData:              10
    Mounts:
      /u01/oracle/user_projects from oud-ds-rs-pv (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from oud-ds-rs-token-c4tg4 (ro)
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
  oud-ds-rs-token-c4tg4:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  oud-ds-rs-token-c4tg4
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:          <none>
```


