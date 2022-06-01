+++
title = "Troubleshooting"
weight = 9
pre = "<b>9. </b>"
description = "How to Troubleshoot issues."
+++
1. [Check the status of a namespace](#check-the-status-of-a-namespace)
1. [View pod logs](#view-pod-logs)
1. [View pod description](#view-pod-description)

### Check the status of a namespace

To check the status of objects in a namespace use the following command:

```
$ kubectl --namespace <namespace> get nodes,pod,service,secret,pv,pvc,ingress -o wide
```

For example:

```
$ kubectl --namespace oudsmns get nodes,pod,service,secret,pv,pvc,ingress -o wide
```

The output will look similar to the following:

```
$ kubectl --namespace oudsmns get pod,service,secret,pv,pvc,ingress -o wide

NAME          READY   STATUS    RESTARTS   AGE   IP            NODE            NOMINATED NODE   READINESS GATES
pod/oudsm-1   1/1     Running   0          18m   10.244.1.89   <worker-node>   <none>           <none>

NAME                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE   SELECTOR
service/oudsm-1     ClusterIP   10.101.79.110    <none>        7001/TCP,7002/TCP   18m   app.kubernetes.io/instance=oudsm,app.kubernetes.io/name=oudsm,oudsm/instance=oudsm-1
service/oudsm-lbr   ClusterIP   10.106.241.204   <none>        7001/TCP,7002/TCP   18m   app.kubernetes.io/instance=oudsm,app.kubernetes.io/name=oudsm

NAME                                 TYPE                                  DATA   AGE
secret/default-token-jtwn2           kubernetes.io/service-account-token   3      22h
secret/orclcred                      kubernetes.io/dockerconfigjson        1      22h
secret/oudsm-creds                   opaque                                2      18m
secret/oudsm-tls-cert                kubernetes.io/tls                     2      18m
secret/oudsm-token-7kjff             kubernetes.io/service-account-token   3      18m
secret/sh.helm.release.v1.oudsm.v1   helm.sh/release.v1                    1      18m

NAME                                 CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                       STORAGECLASS        REASON   AGE   VOLUMEMODE
persistentvolume/oudsm-pv            20Gi       RWX            Delete           Bound    oudsmns/oudsm-pvc           manual                       18m   Filesystem

NAME                              STATUS   VOLUME     CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE
persistentvolumeclaim/oudsm-pvc   Bound    oudsm-pv   20Gi       RWX            manual         18m   Filesystem

NAME                                            CLASS    HOSTS           ADDRESS   PORTS     AGE
ingress.networking.k8s.io/oudsm-ingress-nginx   <none>   oudsm-1,oudsm             80, 443   18m
```

Include/exclude elements (nodes,pod,service,secret,pv,pvc,ingress) as required.

### View pod logs

To view logs for a pod use the following command:

```
$ kubectl logs <pod> -n <namespace>
```

For example:

```
$ kubectl logs oudsm-1 -n oudsmns
```

### View pod description

Details about a pod can be viewed using the `kubectl describe` command:

```
$ kubectl describe pod <pod> -n <namespace>
```

For example:

```
$ kubectl describe pod oudsm-1 -n oudsmns
```

The output will look similar to the following:

```
Name:         oudsm-1
Namespace:    oudsmns
Priority:     0
Node:         <worker-node>/100.102.48.28
Start Time:   Tue, 22 Mar 2022 09:56:11 +0000
Labels:       app.kubernetes.io/instance=oudsm
              app.kubernetes.io/managed-by=Helm
              app.kubernetes.io/name=oudsm
              app.kubernetes.io/version=12.2.1.4.0
              helm.sh/chart=oudsm-0.1
              oudsm/instance=oudsm-1
Annotations:  meta.helm.sh/release-name: oudsm
              meta.helm.sh/release-namespace: oudsmns
Status:       Running
IP:           10.244.1.89
IPs:
  IP:  10.244.1.89
Containers:
  oudsm:
    Container ID:   cri-o://37dbe00257095adc0a424b8841db40b70bbb65645451e0bc53718a0fd7ce22e4
    Image:          container-registry.oracle.com/middleware/oudsm_cpu:12.2.1.4-jdk8-ol7-220223.2053
    Image ID:       container-registry.oracle.com/middleware/oudsm_cpu@sha256:47960d36d502d699bfd8f9b1be4c9216e302db95317c288f335f9c8a32974f2c
    Ports:          7001/TCP, 7002/TCP
    Host Ports:     0/TCP, 0/TCP
    State:          Running
      Started:      Tue, 22 Mar 2022 09:56:12 +0000
    Ready:          True
    Restart Count:  0
    Liveness:       http-get http://:7001/oudsm delay=1200s timeout=15s period=60s #success=1 #failure=3
    Readiness:      http-get http://:7001/oudsm delay=900s timeout=15s period=30s #success=1 #failure=3
    Environment:
      DOMAIN_NAME:         oudsmdomain-1
      ADMIN_USER:          <set to the key 'adminUser' in secret 'oudsm-creds'>  Optional: false
      ADMIN_PASS:          <set to the key 'adminPass' in secret 'oudsm-creds'>  Optional: false
      ADMIN_PORT:          7001
      ADMIN_SSL_PORT:      7002
      WLS_PLUGIN_ENABLED:  true
    Mounts:
      /u01/oracle/user_projects from oudsm-pv (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-9ht84 (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  oudsm-pv:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  oudsm-pvc
    ReadOnly:   false
  kube-api-access-9ht84:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  39m   default-scheduler  0/3 nodes are available: 3 pod has unbound immediate PersistentVolumeClaims.
  Normal   Scheduled         39m   default-scheduler  Successfully assigned oudsmns/oudsm-1 to <worker-node>
  Normal   Pulled            39m   kubelet            Container image "container-registry.oracle.com/middleware/oudsm_cpu:12.2.1.4-jdk8-ol7-220223.2053" already present on machine
  Normal   Created           39m   kubelet            Created container oudsm
  Normal   Started           39m   kubelet            Started container oudsm

```


