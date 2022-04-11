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

NAME          READY   STATUS    RESTARTS   AGE   IP            NODE             NOMINATED NODE   READINESS GATES
pod/oudsm-1   1/1     Running   0          22h   10.244.0.19   100.102.51.238   <none>           <none>
pod/oudsm-2   1/1     Running   0          22h   10.244.0.20   100.102.51.238   <none>           <none>
	
NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE   SELECTOR
service/oudsm-1     ClusterIP   10.96.108.200   <none>        7001/TCP,7002/TCP   22h   app.kubernetes.io/instance=oudsm,app.kubernetes.io/name=oudsm,oudsm/instance=oudsm-1
service/oudsm-2     ClusterIP   10.96.96.12     <none>        7001/TCP,7002/TCP   22h   app.kubernetes.io/instance=oudsm,app.kubernetes.io/name=oudsm,oudsm/instance=oudsm-2
service/oudsm-lbr   ClusterIP   10.96.41.201    <none>        7001/TCP,7002/TCP   22h   app.kubernetes.io/instance=oudsm,app.kubernetes.io/name=oudsm
	
NAME                                 TYPE                                  DATA   AGE
secret/default-token-w4jft           kubernetes.io/service-account-token   3      32d
secret/oudsm-creds                   opaque                                2      22h
secret/oudsm-token-ksr4g             kubernetes.io/service-account-token   3      22h
secret/sh.helm.release.v1.oudsm.v1   helm.sh/release.v1                    1      22h
secret/sh.helm.release.v1.oudsm.v2   helm.sh/release.v1                    1      21h
secret/sh.helm.release.v1.oudsm.v3   helm.sh/release.v1                    1      19h
	
NAME                            CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                   STORAGECLASS   REASON   AGE   VOLUMEMODE
persistentvolume/oudsm-pv       30Gi       RWX            Retain           Bound    myoudns/oudsm-pvc     manual                  22h   Filesystem

NAME                              STATUS   VOLUME     CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE
persistentvolumeclaim/oudsm-pvc   Bound    oudsm-pv   30Gi       RWX            manual         22h   Filesystem

NAME                                     HOSTS                               ADDRESS          PORTS   AGE
ingress.extensions/oudsm-ingress-nginx   oudsm-1,oudsm-2,oudsm + 1 more...   100.102.51.230   80      19h


Include/exclude elements (nodes,pod,service,secret,pv,pvc,ingress) as required.
```

### View POD Logs

To view logs for a POD use the following command:

```
$ kubectl logs <pod> -n <namespace>
```

For example:

```
$ kubectl logs oudsm-1 -n oudns
```

Output will depend on the application running in the POD.

### View Pod Description

Details about a POD can be viewed using the `kubectl describe` command:

```
$ kubectl describe pod <pod> -n <namespace>
```

For example:

```
$ kubectl describe pod oudsm-1 -n oudns

Name:         oudsm-1
Namespace:    oudns
Priority:     0
Node:         10.252.12.103/10.252.12.103
Start Time:   Thu, 02 Sep 2021 04:37:41 -0700
Labels:       app.kubernetes.io/instance=oudsm
              app.kubernetes.io/managed-by=Helm
              app.kubernetes.io/name=oudsm
              app.kubernetes.io/version=12.2.1.4.0
              helm.sh/chart=oudsm-0.1
              oudsm/instance=oudsm-1
Annotations:  meta.helm.sh/release-name: oudsm
              meta.helm.sh/release-namespace: oudns
Status:       Running
IP:           10.244.3.33
IPs:
  IP:  10.244.3.33
Containers:
  oudsm:
    Container ID:   docker://583080692e2957d2a567350d497f88063ed79dfb3c52e717322                                                                                                        
afdafa94d2ca4
    Image:          oracle/oudsm:12.2.1.4.0-8-ol7-210721.0755
    Image ID:       docker://sha256:91cbafb6b7f9b2b76a61d8d4df9babef570d3f88f8a0                                                                                                       
72eb0966fdec3324cab9
    Ports:          7001/TCP, 7002/TCP
    Host Ports:     0/TCP, 0/TCP
    State:          Running
      Started:      Thu, 02 Sep 2021 04:37:43 -0700
    Ready:          True
    Restart Count:  0
    Liveness:       http-get http://:7001/oudsm delay=1200s timeout=15s period=6
0s #success=1 #failure=3
    Readiness:      http-get http://:7001/oudsm delay=900s timeout=15s period=30                                                                                                                                          
s #success=1 #failure=3
    Environment:
      DOMAIN_NAME:         oudsmdomain-1
      ADMIN_USER:          <set to the key 'adminUser' in secret 'oudsm-creds'>                                                                                                                                            
Optional: false
      ADMIN_PASS:          <set to the key 'adminPass' in secret 'oudsm-creds'>                                                                                                                                            
Optional: false
      ADMIN_PORT:          7001
      ADMIN_SSL_PORT:      7002
      WLS_PLUGIN_ENABLED:  true
    Mounts:
      /u01/oracle/user_projects from oudsm-pv (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from oudsm-token-gvv65 (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  oudsm-pv:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in                                                                                                                                           
the same namespace)
    ClaimName:  oudsm-pvc
    ReadOnly:   false
  oudsm-token-gvv65:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  oudsm-token-gvv65
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:          <none>

```


