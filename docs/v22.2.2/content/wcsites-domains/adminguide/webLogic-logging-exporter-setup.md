---
title: "Publish logs to Elasticsearch"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 4
pre : "<b> </b>"
description: "Monitor an Oracle WebCenter Sites domain and publish the WebLogic Server logs to Elasticsearch."
---

The WebLogic Logging Exporter adds a log event handler to WebLogic Server. WebLogic Server logs can be pushed to Elasticsearch in Kubernetes directly
by using the Elasticsearch REST API. For more details, see to the [WebLogic Logging Exporter](https://github.com/oracle/weblogic-logging-exporter) project.  

This sample shows you how to publish WebLogic Server logs to Elasticsearch and view them in Kibana. For publishing operator logs, see this [sample](https://oracle.github.io/weblogic-kubernetes-operator/samples/simple/elastic-stack/operator/).

#### Prerequisites

This document assumes that you have already set up Elasticsearch and Kibana for logs collection. If you have not, please see this [document](https://github.com/oracle/weblogic-kubernetes-operator/tree/master/kubernetes/samples/scripts/elasticsearch-and-kibana).

---  

#### Download the WebLogic Logging Exporter binaries

The pre-built binaries are available on the WebLogic Logging Exporter [Releases](https://github.com/oracle/weblogic-logging-exporter/releases) page.  

Download:

* [weblogic-logging-exporter-1.0.0.jar](https://github.com/oracle/weblogic-logging-exporter/releases/download/v1.0.0/weblogic-logging-exporter-1.0.0.jar) from the Releases page.
* [snakeyaml-1.25.jar](https://repo1.maven.org/maven2/org/yaml/snakeyaml/1.25/snakeyaml-1.25.jar) from Maven Central.

{{% notice note %}} These identifiers are used in the sample commands in this document.

* `wcsites-ns`: WebCenter Sites domain namespace
* `wcsitesinfra`: `domainUID`
* `wcsitesinfra-adminserver`: Administration Server pod name
{{% /notice %}}

#### Copy the JAR Files to the WebLogic Domain Home

Copy the `weblogic-logging-exporter-1.0.0.jar` and `snakeyaml-1.25.jar` files to the domain home directory in the Administration Server pod.

```
$ kubectl cp <file-to-copy> <namespace>/<Administration-Server-pod>:<domainhome>

```

```
$ kubectl cp snakeyaml-1.25.jar wcsites-ns/wcsitesinfra-adminserver:/u01/oracle/user_projects/domains/wcsitesinfra/

$ kubectl cp weblogic-logging-exporter-1.0.0.jar wcsites-ns/wcsitesinfra-adminserver:/u01/oracle/user_projects/domains/wcsitesinfra/
```

#### Add a Startup Class to the Domain Configuration

1. In the WebLogic Server Administration Console, in the left navigation pane, expand **Environment**, and then select **Startup and Shutdown Classes**.

1. Add a new startup class. You may choose any descriptive name, however, the class name must be `weblogic.logging.exporter.Startup`.

    ![WLE-Startup-Shutdown-Class](images/wle-startup-shutdown-class.png)

1. Target the startup class to each server from which you want to export logs.

    ![WLE-Startup-Shutdown-Class-Targets](images/wle-startup-shutdown-class-targets.png)

1. In your `/u01/oracle/user_projects/domains/wcsitesinfra/config/config.xml` file, this update should look similar to the following example:
    ```bash
    $ kubectl exec -it wcsitesinfra-adminserver -n wcsites-ns cat /u01/oracle/user_projects/domains/wcsitesinfra/config/config.xml
    ```
    ```
    <startup-class>
      <name>weblogic-logging-exporter</name>
      <target>AdminServer,wcsites_cluster</target>
      <class-name>weblogic.logging.exporter.Startup</class-name>
    </startup-class>
    ```  

#### Update the WebLogic Server `CLASSPATH`

1. Copy the `setDomainEnv.sh` file from the pod to a local folder:
    ```
    $  kubectl cp wcsites-ns/wcsitesinfra-adminserver:/u01/oracle/user_projects/domains/wcsitesinfra/bin/setDomainEnv.sh $PWD/setDomainEnv.sh
    tar: Removing leading `/' from member names
    ```
	
	Ignore exception: `tar: Removing leading '/' from member names`

1. Update the server class path in `setDomainEnv.sh`:
    ```
    CLASSPATH=/u01/oracle/user_projects/domains/wcsitesinfra/weblogic-logging-exporter-1.0.0.jar:/u01/oracle/user_projects/domains/wcsitesinfra/snakeyaml-1.25.jar:${CLASSPATH}
    export CLASSPATH
    ```  

1. Copy back the modified `setDomainEnv.sh` file to the pod:
	```
	$ kubectl cp setDomainEnv.sh wcsites-ns/wcsitesinfra-adminserver:/u01/oracle/user_projects/domains/wcsitesinfra/bin/setDomainEnv.sh
	```

#### Create a Configuration File for the WebLogic Logging Exporter  

1. Specify the Elasticsearch server host and port number in file `kubernetes/create-wcsites-domain/utils/weblogic-logging-exporter/WebLogicLoggingExporter.yaml`:

	Example:
	```
	weblogicLoggingIndexName: wls
	publishHost: elasticsearch.default.svc.cluster.local
	publishPort: 9200
	domainUID: wcsitesinfra
	weblogicLoggingExporterEnabled: true
	weblogicLoggingExporterSeverity: TRACE
	weblogicLoggingExporterBulkSize: 1
	```  

2. Copy the `WebLogicLoggingExporter.yaml` file to the domain home directory in the WebLogic Administration Server pod:
	```
	$ kubectl cp kubernetes/create-wcsites-domain/utils/weblogic-logging-exporter/WebLogicLoggingExporter.yaml wcsites-ns/wcsitesinfra-adminserver:/u01/oracle/user_projects/domains/wcsitesinfra/config/
	```  

#### Restart All the Servers in the Domain

To restart the servers, stop and then start them using the following commands:

To stop the servers:
```
$ kubectl patch domain wcsitesinfra -n wcsites-ns --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "NEVER" }]'
```

To start the servers:
```
$ kubectl patch domain wcsitesinfra -n wcsites-ns --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "IF_NEEDED" }]'
```

After all the servers are restarted, see their server logs to check that the `weblogic-logging-exporter` class is called, as shown below:
```
======================= WebLogic Logging Exporter Startup class called                                                 
Reading configuration from file name: /u01/oracle/user_projects/domains/wcsitesinfra/config/WebLogicLoggingExporter.yaml   
Config{weblogicLoggingIndexName='wls', publishHost='domain.host.com', publishPort=9200, weblogicLoggingExporterSeverity='Notice', weblogicLoggingExporterBulkSize='2', enabled=true, weblogicLoggingExporterFilters=FilterConfig{expression='NOT(MSGID = 'BEA-000449')', servers=[]}], domainUID='wcsitesinfra'}
```  

#### Create an Index Pattern in Kibana  
Create an index pattern `wls*` in **Kibana > Management**. After the servers are started, you will see the log data in the Kibana dashboard:

![WLE-Kibana-Dashboard](images/wle-kibana-dashboard.png)
