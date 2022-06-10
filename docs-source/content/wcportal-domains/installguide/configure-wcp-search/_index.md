+++
title = "Configure WebCenter Portal For Search"
weight = 4
pre  = "<b> </b>"
description = "Set up search functionality in Oracle WebCenter Portal using Elasticsearch."
+++

* [Introduction](#introduction)
* [Set Up Persistent Volume and Persistent Volume Claim](#set-up-persistent-volume-and-persistent-volume-claim )
* [Create a Secret](#create-a-secret)
* [Headless Service](#headless-service)
* [LoadBalancer](#loadbalancer)
* [LoadBalancer Validation](#loadbalancer-validation)
* [Elasticsearch Cluster](#elasticsearch-cluster)
* [Deployment Validation](#deployment-validation)

#### Introduction
Elasticsearch is a highly scalable search engine. It allows you to store, search, and analyze big volumes of data quickly and provides a distributed, multitenant-capable full-text search engine with an HTTP web interface and schema-free JSON document.

#### Set Up Persistent Volume and Persistent Volume Claim
Create a Kubernetes PV and PVC (Persistent Volume and Persistent Volume Claim) to store Elasticsearch data. To create PV and PVC, use the deployment YAML configuration file located at `${WORKDIR}/create-wcp-es-cluster/es-pvpvc.yaml`.

```yaml 
apiVersion: v1
kind: PersistentVolume
metadata:
  name: es-data-pv
  namespace: wcpns
spec:
  storageClassName: es-data-pv-storage-class
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: "/scratch/esdata"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: es-data-pvc
  namespace: wcpns
spec:
  storageClassName: es-data-pv-storage-class
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
```
To create PV & PVC run the below command:
```bash
$ kubectl apply -f es-pvpvc.yaml
```
#### Create a Secret
To grant access to Oracle WebCenter Portal, create a Kubernetes secret using the deployment YAML configuration file located at `${WORKDIR}/create-wcp-es-cluster/es-secret.yaml`

```yaml 
apiVersion: v1
kind: Secret
metadata:
  name: es-secret
  namespace: wcpns
data:
  # base64 encoded strings
  wls-admin: d2VibG9naWM=
  wls-admin-pwd: d2VsY29tZTE=
  search-admin: d2NjcmF3bGFkbWlu
  search-admin-pwd: d2VsY29tZTE=
 ```
    Where:
    wls-admin :Oracle WebCenter Admin UserName
    wls-admin-pwd :Oracle WebCenter Admin Password
    search-admin :ElasticSearch Username
    search-admin-pwd : ElasticSearch Password
To create Kubernetes Secret run the below command:   
```bash
$ kubectl apply -f es-secret.yaml
```
#### Headless Service
 Each node in Elasticsearch cluster can communicate using a headless service. Create a headless service using the deployment YAML configuration file located at `${WORKDIR}/create-wcp-es-cluster/es-service.yaml` to establish cluster communication.
 ```yaml 
apiVersion: v1
kind: Service
metadata:
  name: es-svc
  namespace: wcpns
  labels:
    service: elasticsearch
spec:
  # headless service
  clusterIP: None
  ports:
  - port: 9200
    name: http
  - port: 9300
    name: transport
  selector:
    service: elasticsearch
```
To create Headless Service run below command:
```bash
$ kubectl apply -f es-service.yaml
```
### LoadBalancer 
To access the Elasticsearch service outside of the Kubernetes cluster, create an external loadbalancer. Then access the Elasticsearch service by using the external IP of loadbalancer, create a loadbalancer using the deployment YAML configuration file located at `${WORKDIR}/create-wcp-es-cluster/es-loadbalancer.yaml`.
```yaml
apiVersion: v1
kind: Service
metadata:
  name: es-loadbalancer
  namespace: wcpns
  labels:
    type: external
spec:
  type: LoadBalancer
  selector:
    service: elasticsearch
  ports:
  - name: http
    port: 9200
    targetPort: 9200
```
To create a loadbalancer run below command:
```bash
$ kubectl apply -f es-loadbalancer.yaml
```
#### LoadBalancer Validation
Once the loadbalancer is successfully deployed, validate it by running the following command:

```bash
$ kubectl get svc -n wcpns -l type=external
```
Make a note of the external IP from the above command and use this below sample URL to access Elasticsearch cluster health : http://externalIP:9200/_cluster/health 
 #### Elasticsearch Cluster   
 Using the Kubernetes StatefulSet controller create an Elasticsearch Cluster comprising of three node using the deployment YAML configuration file located at `${WORKDIR}/create-wcp-es-cluster/es-statefulset.yaml`
 
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: es-statefulset
  namespace: wcpns
  labels:
    service: elasticsearch
spec:
  serviceName: es-svc
  replicas: 1
  selector:
    matchLabels:
      service: elasticsearch
  template:
    metadata:
      labels:
        service: elasticsearch
    spec:
      initContainers:
      - name: increase-the-vm-max-map-count
        image: busybox
        command:
        - sysctl
        - -w
        - vm.max_map_count=262144
        securityContext:
          privileged: true
      - name: increase-the-ulimit
        image: busybox
        command:
        - sh
        - -c
        - ulimit -n 65536
        securityContext:
          privileged: true
      volumes:
      - name: es-node
        persistentVolumeClaim:
          claimName: es-data-pvc
      - name: wcp-domain
        persistentVolumeClaim:
          claimName: wcp-domain-domain-pvc
      containers:
      - name: es-container
        image: oracle/wcportal:12.2.1.4
        imagePullPolicy: IfNotPresent
        command: [ "/bin/sh", "-c", "/u01/oracle/container-scripts/configureOrStartElasticsearch.sh" ]
        readinessProbe:
          httpGet:
            path: /
            port: 9200
            httpHeaders:
            - name: Authorization
              value: Basic d2NjcmF3bGFkbWluOndlbGNvbWUx
          initialDelaySeconds: 150
          periodSeconds: 30
          timeoutSeconds: 10
          successThreshold: 1
          failureThreshold: 10
        lifecycle:
          preStop:
            exec:
              command: [ "/bin/sh", "-c", "/u01/oracle/container-scripts/elasticsearchPreStopHandler.sh" ]
        ports:
        - containerPort: 9200
          name: http
        - containerPort: 9300
          name: tcp
        env:
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: UNICAST_HOST_LIST
          value: "es-svc"
        - name: ADMIN_USERNAME
          valueFrom:
            secretKeyRef:
              name: es-secret
              key: wls-admin
        - name: ADMIN_PASSWORD
          valueFrom:
            secretKeyRef:
              name: es-secret
              key: wls-admin-pwd
        - name: SEARCH_APP_USERNAME
          valueFrom:
            secretKeyRef:
              name: es-secret
              key: search-admin
        - name: SEARCH_APP_USER_PASSWORD
          valueFrom:
            secretKeyRef:
              name: es-secret
              key: search-admin-pwd
        - name: ADMIN_SERVER_CONTAINER_NAME
          value: wcp-domain-adminserver
        - name: ADMIN_PORT
          value: "7001"
        - name: ES_CLUSTER_NAME
          value: es-cluster
        - name: DOMAIN_NAME
          value: wcp-domain
        - name: CONFIGURE_ES_CONNECTION
          value: "true"
        - name: LOAD_BALANCER_IP
          value: "es-loadbalancer.wcpns.svc.cluster.local"
        volumeMounts:
        - name: es-node
          mountPath: /u01/esHome/esNode
        - name: wcp-domain
          mountPath: /u01/oracle/user_projects/domains
```
>Note: The values used for ADMIN_PORT and Image name should be same as values passed to `create-domain.sh` job while creating domain.  

To create a es-statefulset run below command:
```bash
$ kubectl apply -f es-statefulset.yaml
```
>Note: After setting up Elasticsearch cluster restart all the instance of Oracle WebCenter Portal server.
#### Deployment Validation
Validate the deployment by running the following command:
```bash
$ kubectl get pods -n wcpns -l service=elasticsearch
```


