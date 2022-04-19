+++
title = "Troubleshooting"
weight = 9
pre = "<b>9. </b>"
description = "How to Troubleshoot issues."
+++
1. [Check the status of a namespace](#check-the-status-of-a-namespace)
1. [View pod logs](#view-pod-logs)
1. [View pod description](#view-pod-description)
1. [Cleaning down a failed OID deployment](#cleaning-down-a-failed-oid-deployment)

### Check the status of a namespace

To check the status of objects in a namespace use the following command:

```
$ kubectl --namespace <namespace> get pod,service,secret,pv,pvc,ingress -o wide
```

For example:

```
$ kubectl --namespace oidns get pod,service,secret,pv,pvc,ingress -o wide
```


Output will be similar to the following:

```

NAME           READY   STATUS    RESTARTS   AGE   IP             NODE                 NOMINATED NODE   READINESS GATES
pod/oidhost1   1/1     Running   0          26m   10.244.1.150   <worker>   <none>           <none>
pod/oidhost2   1/1     Running   0          26m   10.244.2.157   <worker>   <none>           <none>

NAME                   TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                               AGE   SELECTOR
service/oid-lbr-ldap   ClusterIP   10.96.82.57    <none>        3060/TCP,3131/TCP                     26m   app.kubernetes.io/instance=oid,app.kubernetes.io/name=oid
service/oidhost1       ClusterIP   10.111.67.10   <none>        3060/TCP,3131/TCP,7001/TCP,7002/TCP   26m   app.kubernetes.io/instance=oid,app.kubernetes.io/name=oid,oid/instance=oidhost1
service/oidhost2       ClusterIP   10.96.29.184   <none>        3060/TCP,3131/TCP                     26m   app.kubernetes.io/instance=oid,app.kubernetes.io/name=oid,oid/instance=oidhost2

NAME                               TYPE                                  DATA   AGE
secret/default-token-5nrlh         kubernetes.io/service-account-token   3      3d7h
secret/oid-creds                   opaque                                7      26m
secret/oid-tls-cert                kubernetes.io/tls                     2      26m
secret/oid-token-s95zt             kubernetes.io/service-account-token   3      26m
secret/orclcred                    kubernetes.io/dockerconfigjson        1      3d7h
secret/sh.helm.release.v1.oid.v1   helm.sh/release.v1                    1      26m

NAME                                 CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS        CLAIM                             STORAGECLASS        REASON   AGE    VOLUMEMODE
persistentvolume/oid-pv              20Gi       RWX            Delete           Bound         oidns/oid-pvc                     manual                       26m    Filesystem

NAME                            STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE
persistentvolumeclaim/oid-pvc   Bound    oid-pv   20Gi       RWX            manual         26m   Filesystem

NAME                                          CLASS    HOSTS   ADDRESS   PORTS     AGE
ingress.networking.k8s.io/oid-ingress-nginx   <none>   *                 80, 443   26m
```

Include/exclude elements (pod,service,secret,pv,pvc,ingress) as required.

### View POD Logs

To view logs for a pod use the following command:

```
$ kubectl logs <pod> -n <namespace>
```

For example:

```
$ kubectl logs oidhost1 -n oidns
```

Output will depend on the application running in the POD.

### View Pod Description

Details about a pod can be viewed using the `kubectl describe` command:

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
Node:         <worker>/100.102.48.28
Start Time:   Mon, 28 Mar 2022 16:19:54 +0000
Labels:       app.kubernetes.io/instance=oid
              app.kubernetes.io/managed-by=Helm
              app.kubernetes.io/name=oid
              app.kubernetes.io/version=12.2.1.4.0
              helm.sh/chart=oid-0.1
              oid/instance=oidhost1
Annotations:  meta.helm.sh/release-name: oid
              meta.helm.sh/release-namespace: oidns
Status:       Running
IP:           10.244.1.150
IPs:
  IP:  10.244.1.150
Containers:
  oid:
    Container ID:   cri-o://4172c7694d84c64c7c16e02fe96a8fc233b530ff5ae3b24d6440ff958c224e85
    Image:          container-registry.oracle.com/middleware/oid_cpu:12.2.1.4-jdk8-ol7-220223.1744
    Image ID:       container-registry.oracle.com/middleware/oid_cpu@sha256:ec1483590503837a3aa355dab1e33ab5237017b3924e12c2b1554c373d43a16b
    Ports:          3060/TCP, 3131/TCP, 7001/TCP, 7002/TCP
    Host Ports:     0/TCP, 0/TCP, 0/TCP, 0/TCP
    State:          Running
      Started:      Mon, 28 Mar 2022 16:19:55 +0000
    Ready:          True
    Restart Count:  0
    Readiness:      exec [/u01/oracle/dockertools/healthcheck_status.sh] delay=600s timeout=30s period=60s #success=1 #failure=15
    Environment:
      INSTANCE_TYPE:          PRIMARY
      sleepBeforeConfig:      180
      INSTANCE_NAME:          oid1
      ADMIN_LISTEN_HOST:      oidhost1
      REALM_DN:               dc=oid
      CONNECTION_STRING:      oiddb.example.com:1521/oiddb.example.com
      LDAP_PORT:              3060
      LDAPS_PORT:             3131
      ADMIN_LISTEN_PORT:      7001
      ADMIN_LISTEN_SSL_PORT:  7002
      DOMAIN_NAME:            oid_domain
      DOMAIN_HOME:            /u01/oracle/user_projects/domains/oid_domain
      RCUPREFIX:              OIDK8S7
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
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-r26f6 (ro)
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
  kube-api-access-r26f6:
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
  Type     Reason     Age                  From               Message
  ----     ------     ----                 ----               -------
  Normal   Scheduled  29m                  default-scheduler  Successfully assigned oidns/oidhost1 to <worker>
  Normal   Pulled     29m                  kubelet            Container image "container-registry.oracle.com/middleware/oid_cpu:12.2.1.4-jdk8-ol7-220223.1744" already present on machine
  Normal   Created    29m                  kubelet            Created container oid
  Normal   Started    29m                  kubelet            Started container oid
```


