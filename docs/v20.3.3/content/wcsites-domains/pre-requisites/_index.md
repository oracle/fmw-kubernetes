---
title: "Pre-requisites "
weight: 1
pre : "<b>1. </b>"
description: "Pre-requisites for setting up WebCenter Sites domains with WebLogic Kubernetes Operator"
---


#### Contents

* [Introduction](#introduction)
* [System Requirements](#system-requirements)
* [Limitations](#limitations)
* [WebCenter Sites Cluster Sizing Recommendations](#webcenter-sites-cluster-sizing-recommendations)

#### Introduction

This document describes the special considerations for deploying and running a WebCenter Sites domain with the WebLogic Kubernetes Operator.
Other than those considerations listed here, WebCenter Sites domains work in the same way as Fusion Middleware Infrastructure domains and WebLogic Server domains.

In this release, WebCenter Sites domains are supported using the `domain on a persistent volume`
[model](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/choosing-a-model/) only where a WebCenter Sites domain is located in a persistent volume (PV).

#### System Requirements 
* Kubernetes 1.13.0+, 1.14.0+, and 1.15.0+ (check with `kubectl version`).
* Flannel networking v0.9.1-amd64 (check with `docker images | grep flannel`).
* Docker 18.9.1 (check with `docker version`)
* Helm 2.14.3+ (check with `helm version`).
* Oracle Fusion Middleware Infrastructure 12.2.1.4.0 image.
* You must have the `cluster-admin` role to install the operator.
* These proxy setup are used for pulling the required binaries and source code from the respective repositories:
    *  export NO_PROXY="localhost,127.0.0.0/8,$(hostname -i),.your-company.com,/var/run/docker.sock"
    *  export no_proxy="localhost,127.0.0.0/8,$(hostname -i),.your-company.com,/var/run/docker.sock"
    *  export http_proxy=http://www-proxy-your-company.com:80
    *  export https_proxy=http://www-proxy-your-company.com:80
    *  export HTTP_PROXY=http://www-proxy-your-company.com:80
    *  export HTTPS_PROXY=http://www-proxy-your-company.com:80

NOTE: Add your host IP by using `hostname -i` and also `nslookup` IP addresses to the no_proxy, NO_PROXY list above.

#### Limitations

Compared to running a WebLogic Server domain in Kubernetes using the Operator, the
following limitations currently exist for WebCenter Sites domain:

* `Domain in image` model is not supported in this version of the Operator.
* Only configured clusters are supported. Dynamic clusters are not supported for WebCenter Sites domains. Note that you can still use all of the scaling features. You just need to define the maximum size of your cluster at domain creation time.
* We do not currently support running WebCenter Sites in non-Linux containers.
* Deploying and running a WebCenter Sites domain is supported only in Operator versions 2.4.0 and later.
* The [WebLogic Logging Exporter](https://github.com/oracle/weblogic-logging-exporter)
  currently supports WebLogic Server logs only.  Other logs will not be sent to Elasticsearch.  Note, however, that you can use a sidecar with a log handling tool like Logstash or Fluentd to get logs.
* The [WebLogic Monitoring Exporter](https://github.com/oracle/weblogic-monitoring-exporter)
  currently supports the WebLogic MBean trees only.  Support for JRF MBeans has not been added yet.

#### WebCenter Sites Cluster Sizing Recommendations

WebCenter Sites | Normal Usage | Moderate Usage | High Usage 
--- | --- | --- | --- 
Admin Server | No of CPU(s) : 1, Memory : 4GB | No of CPU(s) : 1, Memory : 4GB | No of CPU(s) : 1, Memory : 4GB 
Managed Server | No of Servers : 2, No of CPU(s) : 2, Memory : 16GB | No of Servers : 2, No of CPU(s) : 4, Memory : 16GB | No of Servers : 3, No of CPU(s) : 6, Memory : 16-32GB
PV Storage | Minimum 250GB | Minimum 250GB | Minimum 500GB

