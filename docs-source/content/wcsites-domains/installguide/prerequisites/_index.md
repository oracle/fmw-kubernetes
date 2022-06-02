---
title: "Requirements and limitations"
date: 2019-04-18T07:32:31-05:00
weight: 1
pre : "<b>  </b>"
description: "Understand the system requirements and limitations for deploying and running Oracle WebCenter Sites domains with the WebLogic Kubernetes Operator, including the WebCenter Sites domain cluster sizing recommendations."
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
* Oracle Linux 7 (UL6+) and Red Hat Enterprise Linux 7 (UL3+ only with standalone Kubernetes) are supported.
* Kubernetes 1.16.15+, 1.17.13+, 1.18.10+, 1.19.7+, and 1.20.6+ (check with `kubectl version`).
* Docker 18.09.1ce+, 19.03.1+ (check with `docker version`) or CRI-O 1.14.7 (check with `crictl version | grep RuntimeVersion`).
* Flannel networking v0.9.1-amd64 or later (check with `Docker images | grep flannel`).
* Helm 3.2.4+ (check with `helm version --client --short`).
* Oracle WebLogic Kubernetes Operator 3.3.0 (see [operator releases](https://github.com/oracle/weblogic-kubernetes-operator/releases) page).
* Oracle WebCenterSites 12.2.1.4 Docker image (built either using imagetool or the buildDockerImage script).
* You must have the `cluster-admin` role to install the operator. The operator does not need the `cluster-admin` role at runtime.
* We do not currently support running WebCenterSites in non-Linux containers.
* These proxy setup are used for pulling the required binaries and source code from the respective repositories:
    *  export NO_PROXY="localhost,127.0.0.0/8,$(hostname -i),.your-company.com,/var/run/docker.sock"
    *  export no_proxy="localhost,127.0.0.0/8,$(hostname -i),.your-company.com,/var/run/docker.sock"
    *  export http_proxy=http://www-proxy-your-company.com:80
    *  export https_proxy=http://www-proxy-your-company.com:80
    *  export HTTP_PROXY=http://www-proxy-your-company.com:80
    *  export HTTPS_PROXY=http://www-proxy-your-company.com:80

> NOTE: Add your host IP by using `hostname -i` and also `nslookup` IP addresses to the no_proxy, NO_PROXY list above.

#### Limitations

Compared to running a WebLogic Server domain in Kubernetes using the Operator, the
following limitations currently exist for WebCenter Sites domain:

* `Domain in image` model is not supported in this version of the Operator.
* Only configured clusters are supported. Dynamic clusters are not supported for WebCenter Sites domains. Note that you can still use all of the scaling features. You just need to define the maximum size of your cluster at domain creation time.
* We do not currently support running WebCenter Sites in non-Linux containers.
* Deploying and running a WebCenter Sites domain is supported only in Operator versions 3.3.0 and later.
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

