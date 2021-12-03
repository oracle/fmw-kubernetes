+++
title = "Troubleshooting"
date = 2019-04-18T07:32:31-05:00
weight = 5
pre = "<b>5. </b>"
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

For example:

```
$ kubectl --namespace oidns get nodes,pod,service,secret,pv,pvc,ingress -o wide
```


Output will be similar to the following:

```
NAME              STATUS   ROLES    AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                  KERNEL-VERSION                      CONTAINER-RUNTIME
node/myoidhost    Ready    master   99d   v1.18.4   100.94.12.231   <none>        Oracle Linux Server 7.8   5.4.17-2036.102.0.2.el7uek.x86_64   docker://19.3.11

NAME                READY   STATUS    RESTARTS   AGE     IP             NODE         NOMINATED NODE   READINESS GATES
pod/oidhost1   1/1     Running   0          3h34m   10.244.0.137   myoidhost    <none>           <none>
pod/oidhost2   1/1     Running   0          3h34m   10.244.0.138   myoidhost    <none>           <none>
pod/oidhost3   1/1     Running   0          3h34m   10.244.0.136   myoidhost    <none>           <none>

NAME                        TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                               AGE     SELECTOR
service/oid-lbr-ldap        ClusterIP   10.103.103.151   <none>        3060/TCP,3131/TCP                     3h34m   app.kubernetes.io/instance=oid,app.kubernetes.io/name=oid
service/oidhost1            ClusterIP   10.108.25.249    <none>        3060/TCP,3131/TCP,7001/TCP,7002/TCP   3h34m   app.kubernetes.io/instance=oid,app.kubernetes.io/name=oid,oid/instance=oidhost1
service/oidhost2            ClusterIP   10.99.99.62      <none>        3060/TCP,3131/TCP                     3h34m   app.kubernetes.io/instance=oid,app.kubernetes.io/name=oid,oid/instance=oidhost2
service/oidhost3            ClusterIP   10.107.13.174    <none>        3060/TCP,3131/TCP                     3h34m   app.kubernetes.io/instance=oid,app.kubernetes.io/name=oid,oid/instance=oidhost3

NAME                                TYPE                                  DATA   AGE
secret/default-token-ngdrb          kubernetes.io/service-account-token   3      99d
secret/oid-creds                    opaque                                7      3h34m
secret/oid-tls-cert                 kubernetes.io/tls                     2      3h34m
secret/oid-token-n9wp6              kubernetes.io/service-account-token   3      3h34m
secret/oiddomain                    kubernetes.io/tls                     2      48d
secret/sh.helm.release.v1.app.v1    helm.sh/release.v1                    1      3h34m

NAME                                     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                             STORAGECLASS                       REASON   AGE     VOLUMEMODE
persistentvolume/oid-pv                  20Gi       RWX            Delete           Bound    myhelmns/oid-pvc                  manual                                      3h34m   Filesystem

NAME                                               STATUS    VOLUME        CAPACITY   ACCESS MODES   STORAGECLASS   AGE     VOLUMEMODE
persistentvolumeclaim/oid-pvc                      Bound     oid-pv        20Gi       RWX            manual         3h34m   Filesystem

NAME                                        CLASS    HOSTS   ADDRESS         PORTS     AGE
ingress.extensions/oid-ingress-nginx        <none>   *       10.103.111.88   80, 443   3h34m

```

Include/exclude elements (nodes,pod,service,secret,pv,pvc,ingress) as required.

### View POD Logs

To view logs for a POD use the following command:

```
$ kubectl logs <pod> -n <namespace>
```

For example:

```
$ kubectl logs oidhost1 -n oidns
```

Output will depend on the application running in the POD.

### View Pod Description

Details about a POD can be viewed using the `kubectl describe` command:

```
$ kubectl describe pod <pod> -n <namespace>
```

For example:

```
$ kubectl describe pod oidhost1 -n oidns
```

Output will be similar to the following:

```
Name:         oidhost1
Namespace:    oidns
Priority:     0
Node:         myoidhost/100.94.12.231
Start Time:   Tue, 19 Oct 2021 05:27:24 +0000
Labels:       app.kubernetes.io/instance=oid
              app.kubernetes.io/managed-by=Helm
              app.kubernetes.io/name=oid
              app.kubernetes.io/version=12.2.1.4.0
              helm.sh/chart=oid-0.1
              oid/instance=oidhost1
Annotations:  meta.helm.sh/release-name: oid
              meta.helm.sh/release-namespace: oidns
Status:       Running
IP:           10.244.0.137
IPs:
  IP:  10.244.0.137
Containers:
  oid:
    Container ID:   docker://8017433f42d2d6159e89b03daf47ac2f854ecbad9df3b92e157c36d353fd9cb8
    Image:          oracle/oid:12.2.1.4.0
    Image ID:       docker-pullable://oracle/oid@sha256:acc2df0a87bb53fcf71abe28e5387794f94b9f2eb900404dee7b2ffafe27887d
    Ports:          3060/TCP, 3131/TCP, 7001/TCP, 7002/TCP
    Host Ports:     0/TCP, 0/TCP, 0/TCP, 0/TCP
    State:          Running
      Started:      Tue, 19 Oct 2021 05:27:26 +0000
    Ready:          True
    Restart Count:  0
    Readiness:      exec [/u01/oracle/dockertools/healthcheck_status.sh] delay=600s timeout=30s period=60s #success=1 #failure=15
    Environment:
      INSTANCE_TYPE:          PRIMARY
      sleepBeforeConfig:      180
      INSTANCE_NAME:          oid1
      ADMIN_LISTEN_HOST:      oidhost1
      REALM_DN:               dc=oid,dc=example,dc=com
      CONNECTION_STRING:      oid.example.com:1521/oidpdb.example.com
      LDAP_PORT:              3060
      LDAPS_PORT:             3131
      ADMIN_LISTEN_PORT:      7001
      ADMIN_LISTEN_SSL_PORT:  7002
      DOMAIN_NAME:            oid_domain
      DOMAIN_HOME:            /u01/oracle/user_projects/domains/oid_domain
      RCUPREFIX:              OIDPD
      ADMIN_USER:             <set to the key 'adminUser' in secret 'oid-creds'>          Optional: false
      ADMIN_PASSWORD:         <set to the key 'adminPassword' in secret 'oid-creds'>      Optional: false
      DB_USER:                <set to the key 'dbUser' in secret 'oid-creds'>             Optional: false
      DB_PASSWORD:            <set to the key 'dbPassword' in secret 'oid-creds'>         Optional: false
      DB_SCHEMA_PASSWORD:     <set to the key 'dbschemaPassword' in secret 'oid-creds'>   Optional: false
      ORCL_ADMIN_PASSWORD:    <set to the key 'orcladminPassword' in secret 'oid-creds'>  Optional: false
      SSL_WALLET_PASSWORD:    <set to the key 'sslwalletPassword' in secret 'oid-creds'>  Optional: false
      ldapPort:               3060
      ldapsPort:              3131
      httpPort:               7001
      httpsPort:              7002
    Mounts:
      /u01/oracle/user_projects from oid-pv (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from oid-token-n9wp6 (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  oid-pv:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  oid-pvc
    ReadOnly:   false
  oid-token-n9wp6:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  oid-token-n9wp6
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:          <none>
```
