---
title: "Manage WebCenter Sites domains"
date: 2019-04-18T07:32:31-05:00
weight: 4
pre: "<b>4. </b>"
description: "Sample for managing a WebCenter Sites domain home on an existing PV or
PVC, and the domain resource YAML file for deploying the generated WebCenter Sites domain."
---

#### Contents

* [Introduction](#introduction)
* [Integrate Logstash, Elasticsearch and Kibana](#integrate-logstash-elasticsearch-and-kibana)
* [Set Up WebLogic Logging Exporter](#set-up-weblogic-logging-exporter)
* [Set Up WebLogic Monitoring Exporter](#set-up-weblogic-monitoring-exporter)
* [Delete the Generated Domain Home](#delete-the-generated-domain-home)
* [Clean Up the `create-domain-job` Script After Execution Failure](#clean-up-the-create-domain-job-script-after-execution-failure)

#### Introduction

This document provides instructions to delete or clear an environment in case of errors and steps to integrate with some of the common utility tools to manage the domains created.

#### Integrate Logstash, Elasticsearch and Kibana
You can send the operator logs to Elasticsearch, to be displayed in Kibana. Use
this [sample script](https://github.com/oracle/weblogic-monitoring-exporter/blob/master/samples/kubernetes/deployments/README.md) to configure Elasticsearch and Kibana deployments and services.
For sample configurations on WebCenter Sites, see
[Elasticsearch integration for the WebLogic Kubernetes Operator]({{< relref "/wcsites-domains/manage-wcsites-domains/Elasticsearch-integration-with-WLS-Operator-and-WLS-server-logs.md">}})
	
#### Set Up WebLogic Logging Exporter
After the WebCenter Sites domain is set up, you can publish WebLogic Kubernetes Operator and WebLogic Server logs into Elasticsearch and interact with them in Kibana.
Follow the steps described in this [document]({{< relref "/wcsites-domains/manage-wcsites-domains/WebLogic-Logging-Exporter-Setup.md">}}) to set up the Weblogic Logging Exporter and publish the logs to Elasticsearch.

#### Set Up WebLogic Monitoring Exporter
The WebCenter Sites instance can be monitored using Prometheus and Grafana.
The WebLogic Monitoring Exporter uses the [WebLogic Server RESTful Management](https://docs.oracle.com/middleware/1221/wls/WLRUR/overview.htm#WLRUR111) API to scrape runtime information and then exports Prometheus-compatible metrics. It is deployed as a web application in a WebLogic Server (WLS) instance, version 12.2.1 or later, typically, in the instance from which you want to get metrics. For information, see [Set Up WebLogic Monitoring Exporter]({{< relref "/wcsites-domains/manage-wcsites-domains/WebLogic-Monitoring-Exporter-Setup.md">}}).

#### Delete the Generated Domain Home

Sometimes in production, but most likely in testing environments, you might want to remove the domain
home that is generated using the `create-domain.sh` script. Do this by running the generated
`delete domain job` script in the `/<path to weblogic-operator-output-directory>/weblogic-domains/<domainUID>` directory.

```
$ kubectl create -f delete-domain-job.yaml
```

#### Clean Up the create-domain-job script After Execution Failure
To clean up the `create-domain-job` script:
 
1. Get the create domain job and configmaps:
 
    ```bash
    $ kubectl get configmaps,jobs -n wcsites-ns |grep "create-domain-job"
    ```
2. Delete the job and configmap:
     
    ```bash
    $ kubectl delete job wcsitesinfra-create-fmw-infra-sample-domain-job -n wcsites-ns
    $ kubectl delete configmap wcsitesinfra-create-fmw-infra-sample-domain-job-cm -n wcsites-ns
    ```
3. Delete the contents of the PV, if any:
 
    ```bash
    $ sudo rm -rf /scratch/K8SVolume/WCSites
    ```