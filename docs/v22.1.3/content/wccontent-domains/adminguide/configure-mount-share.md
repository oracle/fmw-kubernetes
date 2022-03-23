---
title: "Configure an additional mount or shared space to a domain for Imaging and Capture"
date: 2020-11-27T16:43:45-05:00
weight: 6
description: "Configure an additional mount or shared space to a domain, for WebCeneter Imaging and WebCenter Capture"
---

A volume can be mounted to a server pod which can be accessible directly from outside Kubernetes cluster so that an external application could write new files to it.

This can be used specifically in WebCenter Imaging and WebCenter Capture applications for File Imports.

Kubernetes supports several types of volumes as given in [Volumes | Kubernetes](https://kubernetes.io/docs/concepts/storage/volumes/#volume-types).

Further in this section, we will take `nfs` volume as an example.

#### Mount "nfs" as volume

To use a volume, specify the volumes to provide for the Pod in .spec.volumes and declare where to mount those volumes into containers in .spec.containers[*].volumeMounts in `domain.yaml` file.

Update the `domain.yaml` and apply the changes as shown in sample below for mounting nfs server (for example, 100.XXX.XXX.X with shared export path at `/sharedir`) to all the server pods at `/u01/sharedir`.

The path `/u01/sharedir` can be configured as the file import path in WebCenter Imaging and WebCenter Capture applications and the files put to `/sharedir` will be processed by the applications.

Sample entry of domain.yaml with nfs-volume configuration
```bash
...
serverPod:
    # an (optional) list of environment variable to be set on the servers
    env:
    - name: JAVA_OPTIONS
      value: "-Dweblogic.StdoutDebugEnabled=false"
    - name: USER_MEM_ARGS
      value: "-Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx1024m "
    volumes:
    - name: weblogic-domain-storage-volume
      persistentVolumeClaim:
        claimName: wccinfra-domain-pvc
    - name: nfs-volume
      nfs:
        server: 100.XXX.XXX.XXX
        path: /sharedir
    volumeMounts:
    - mountPath: /u01/oracle/user_projects/domains
      name: weblogic-domain-storage-volume
    - mountPath: /u01/sharedir
      name: nfs-volume
...
```