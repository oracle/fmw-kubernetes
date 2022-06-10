+++
title = "Requirements and limitations"
weight = 1
pre = "<b> </b>"
description = "Understand the system requirements and limitations for deploying and running Oracle WebCenter Portal with the WebLogic Kubernetes operator."
+++

#### Contents

* [Introduction](#introduction)
* [System Requirements](#system-requirements)
* [Limitations](#limitations)

#### Introduction

This document describes the special considerations for deploying and running a WebCenter Portal domain with the WebLogic Kubernetes Operator.
Other than those considerations listed here, the WebCenter Portal domain works in the same way as Fusion Middleware Infrastructure and WebLogic Server domains do.

In this release, WebCenter Portal domain is based on the `domain on a persistent volume` [model](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/choosing-a-model/) where a WebCenter Portal domain is located in a persistent volume (PV).

#### System Requirements 
* Kubernetes 1.18.18+, 1.19.7+, and 1.20.6+ (check with `kubectl version`).
* Flannel networking v0.14.0 or later (check with `docker images | grep flannel`), Calico networking v3.15.
* Docker 19.03.11+ (check with `docker version`).
* Helm 3.4+ (check with `helm version`).
* WebLogic Kubernetes operator 3.3.0 (see [the operator releases](https://github.com/oracle/weblogic-kubernetes-operator/releases/tag/v3.3.0) page). 
* Oracle WebCenter Portal 12.2.1.4.0 image.
* These proxy setups are used for pulling the required binaries and source code from the respective repositories:
    *  export NO_PROXY="localhost,127.0.0.0/8,$(hostname -i),.your-company.com,/var/run/docker.sock"
    *  export no_proxy="localhost,127.0.0.0/8,$(hostname -i),.your-company.com,/var/run/docker.sock"
    *  export http_proxy=http://www-proxy-your-company.com:80
    *  export https_proxy=http://www-proxy-your-company.com:80
    *  export HTTP_PROXY=http://www-proxy-your-company.com:80
    *  export HTTPS_PROXY=http://www-proxy-your-company.com:80

NOTE: Add your host IP by using `hostname -i` and `nslookup` IP addresses to the no_proxy, NO_PROXY list above.

#### Limitations

Compared to running a WebLogic Server domain in Kubernetes using the operator, the
following limitations currently exist for a WebCenter Portal domain:

* `Domain in image` model is not supported in this version of the operator.
* Only configured clusters are supported. Dynamic clusters are not supported on WebCenter Portal domains. Note that you can still use all of the scaling features. You just need to define the maximum size of your cluster at the time when you create a domain.
* At present, WebCenter Portal doesn't run on non-Linux containers.
* Deploying and running a WebCenter Portal domain is supported only in the operator versions 3.3.0 and later.
* The [WebLogic Logging Exporter](https://github.com/oracle/weblogic-logging-exporter)
  currently supports WebLogic Server logs only. Other logs are not sent to Elasticsearch.  Note, however, that you can use a sidecar with a log handling tool like Fluentd to get logs.
* The [WebLogic Monitoring Exporter](https://github.com/oracle/weblogic-monitoring-exporter)
  currently supports the WebLogic MBean trees only.  Support for JRF MBeans has not been added yet.