+++
title = "Troubleshooting"
weight = 9
pre = "<b>9. </b>"
description = "How to Troubleshoot OHS container failure."
+++

1. [OHS Container in CreatingContainer status](#ohs-container-in-creating-container-status)
1. [OHS Container in ImagePullBackOff](#ohs-container-in-imagepullbackoff)
1. [OHS Container in 0/1 Running Status](#ohs-container-in-01-running-status)
1. [Issues with LivenessProbe](#issues-with-livenessprobe)
1. [Viewing OHS log files](#viewing-ohs-log-files)

The instructions in this section relate to problems creating OHS containers and viewing log files.

### OHS Container in CreatingContainer status

	
During OHS container creation you may see:
	
```
NAME                         READY   STATUS              RESTARTS   AGE
ohs-domain-d5b648bc5-vkp4s   0/1     ContainerCreating   0          2m13s
```
	
To check what is happening while the pod is in `ContainerCreating` status, you can run:

```
$ kubectl describe pod <podname> -n <namespace>
```
	
For example:
	
```
$ kubectl describe pod ohs-domain-d5b648bc5-vkp4s -n ohsns
```

The details of the above command can help identify possible problems. 

In the `Events`, if you see `Pulling image <image>`, this means that the container is pulling the image from the container-registry. Depending on the speed of the network this could take 5-10 minutes. Once the image is pulled you should see the pod go to `RUNNING 0/1` status, before eventually going to `RUNNING 1\1`.


### OHS Container in ImagePullBackOff

If you see the following:

```
kubectl get pods -n ohsns
NAME                          READY   STATUS             RESTARTS   AGE
ohs-domain-58b8dc4749-hzlc9   0/1     ImagePullBackOff   0          16s
```

This could be because you have put the wrong image location in the `ohs.yaml`, there is a problem with the image itself, or the secrets created are incorrect.

Once the problem is identified and resolved, you can delete the container and try again:

```
$ cd $MYOHSFILES
$ kubectl delete -f ohs.yaml
$ kubectl create -f ohs.yaml
```



### OHS Container in 0/1 Running Status

During OHS container creation you may see:

```
NAME                         READY   STATUS              RESTARTS   AGE
ohs-domain-d5b648bc5-vkp4s   0/1     Running             0          2m13s
```

This is normal behaviour during any startup, however the pod should eventually go to `RUNNING 1/1`

Whilst the pod is in `0/1 ` status, you can check what is happening by running:


```
$ kubectl logs -f <pod> -n <namespace>
```

For example

```
$ kubectl logs -f ohs-domain-d5b648bc5-vkp4s -n ohsns
```

If there are any problems or errors during startup, they will be logged here. 

You can also describe the pod to determine potential problems:

```
$ kubectl describe pod <pod> -n <namespace>
```

For example:

```
$ kubectl describe pod ohs-domain-d5b648bc5-vkp4s -n ohsns
```

Additionally, you can view the OHS log files inside the container. See, [Viewing OHS log files](#viewing-ohs-log-files).

Depending on the error, you may need to fix the files in the `$MYOHSFILES/ohsConfig` directories.

Once you have fixed your configuration files, you will need to delete the appropriate configmap(s) and recreate. For example if the problem was in `httpd.conf`, `ssl.conf`, or `mod_wl_ohs.conf`:

```
$ cd $MYOHSFILES
$ kubectl delete -f ohs.yaml
$ kubectl delete cm ohs-httpd -n ohsns
$ kubectl create cm -n ohsns ohs-httpd --from-file=ohsConfig/httpconf
$ kubectl create -f ohs.yaml
```


### Issues with LivenessProbe

If you see OHS Container in `0/1 Running Status` and the container constantly restarts:

```
NAME                         READY   STATUS              RESTARTS   AGE
ohs-domain-d5b648bc5-vkp4s   0/1     Running             4          2m13s
```

If this occurs and `kubectl logs -f <pod> -n <namespace>` is showing no errors, then run:

```
$ kubectl describe pod <podname> -n <namespace>
```

If the output shows:

```
 ----     ------     ----               ----               -------
  Normal   Scheduled  63s                default-scheduler  Successfully assigned ohsns/ohs-domain-857c5d97d5-8nnx9 to doc-worker1
  Normal   Pulled     17s (x2 over 62s)  kubelet            Container image "<image>" already present on machine
  Normal   Created    17s (x2 over 62s)  kubelet            Created container ohs
  Normal   Started    17s (x2 over 62s)  kubelet            Started container ohs
  Warning  Unhealthy  2s (x9 over 61s)   kubelet            Readiness probe failed: Get "http://10.244.1.150:7777/helloWorld.html": dial tcp 10.244.1.150:7777: connect: connection refused
  Warning  Unhealthy  2s (x6 over 57s)   kubelet            Liveness probe failed:
  Normal   Killing    2s (x2 over 47s)   kubelet            Container ohs failed liveness probe, will be restarted
```


It's possible the liveness probe is killing and restarting the container because the httpd process has not started before the liveness probe checks. This can happen on slow systems.

If this occurs delete the container:

```
$ cd $MYOHSFILES
$ kubectl delete -f ohs.yaml
```

and edit the `ohs.yaml` file and increase the `initialDelaySeconds` from `10` to `30`:

```
      livenessProbe:
          exec:
            command:
            - /bin/bash
            - -c
            - pgrep httpd
          initialDelaySeconds: 30
          periodSeconds: 5

```

Then try creating the container again:

```
$ cd $MYOHSFILES
$ kubectl create -f ohs.yaml
```

### Viewing OHS log files

To view OHS log files inside the container, run the following commands:



```
$ kubectl exec -n <namespace> -ti <pod> -- /bin/bash
```
	
For example:
	
```
$ kubectl exec -n ohsns -ti ohs-domain-79f8f99575-8qwfh -- /bin/bash
```
	
This will take you to a bash shell inside the container:
	
```
[oracle@ohs-domain-75fbd9b597-z77d8 oracle]$
```

Inside the bash shell navigate to the `/u01/oracle/user_projects/domains/ohsDomain/server/ohs1/logs` directory:

```
$ cd  /u01/oracle/user_projects/domains/ohsDomain/server/ohs1/logs
```	
	
From within this directory, you can `cat` the OHS log files to help diagnose problems.
