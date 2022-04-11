## Publish WebLogic Server logs into Elasticsearch

The WebLogic Logging Exporter adds a log event handler to WebLogic Server, such that WebLogic Server logs can be integrated into Elastic Stack in Kubernetes directly, by using the Elasticsearch REST API.

## Prerequisite

This document assumes that you have already deployed Elasticsearch/Kibana environment. If you have not, please use a sample/demo deployment of Elasticsearch/Kibana from WebLogic Kubernetes operator.

To deploy Elasticsearch and Kibana on the Kubernetes cluster:
```bash	
$ kubectl create -f https://raw.githubusercontent.com/oracle/weblogic-kubernetes-operator/master/kubernetes/samples/scripts/elasticsearch-and-kibana/elasticsearch_and_kibana.yaml
```

Follow these steps to setup WebLogic Logging Exporter in a WebLogic operator environment and push the WebLogic server logs to Elasticsearch/Kibana

1. Download WebLogic logging exporter binaries

    The WebLogic logging exporter pre-built binaries are available in the github releases page: [Release 1.0.1](https://github.com/oracle/weblogic-logging-exporter/releases)
    
    ```bash	
    $ wget https://github.com/oracle/weblogic-logging-exporter/releases/download/v1.0.1/weblogic-logging-exporter.jar
    ```

    Download weblogic-logging-exporter.jar from the github release link above. Also download dependency jar - snakeyaml-1.27.jar from Maven Central.

    ```bash
    $ wget -O snakeyaml-1.27.jar https://search.maven.org/remotecontent?filepath=org/yaml/snakeyaml/1.27/snakeyaml-1.27.jar
    ```
1. Copy JAR files into the Kubernetes WebLogic Administration Server Pod

    Copy weblogic-logging-exporter.jar and snakeyaml-1.27.jar to the domain home folder in the Administration server pod.

    ```bash
    $ kubectl cp weblogic-logging-exporter.jar wcsites-ns/wcsitesinfra-adminserver:/u01/oracle/user_projects/domains/wcsitesinfra/
    $ kubectl cp snakeyaml-1.27.jar wcsites-ns/wcsitesinfra-adminserver:/u01/oracle/user_projects/domains/wcsitesinfra/ 
    ```

1. Add a startup class to the domain configuration

    In this step, we configure weblogic-logging-exporter JAR as a startup class in the WebLogic servers where we intend to collect the logs.

    a) In the Administration Console,   navigate to `Environment` then `Startup and Shutdown classes` in the main menu.

    b) Add a new Startup class. You may choose any descriptive name and the class name must be `weblogic.logging.exporter.Startup`.

    c) Target the startup class to each server that you want to export logs from.

    You can verify this by checking for the update in your config.xml which should be similar to this example:

    ```bash
    <startup-class>
        <name>LoggingExporterStartupClass</name>
        <target>AdminServer</target>
        <class-name>weblogic.logging.exporter.Startup</class-name>
    </startup-class>
    ```

1. Update WebLogic Server CLASS Path.

    In this step, we set the class path for weblogic-logging-exporter and its dependencies.

    a) Copy setDomainEnv.sh from the pod to local folder.
    ```bash
    $ kubectl cp wcsites-ns/wcsitesinfra-adminserver:/u01/oracle/user_projects/domains/wcsitesinfra/bin/setDomainEnv.sh setDomainEnv.sh
    ```
    b) Modify setDomainEnv.sh to update the Server Class path.
    ```bash
    CLASSPATH=/u01/oracle/user_projects/domains/wcsitesinfra/weblogic-logging-exporter.jar:/u01/oracle/user_projects/domains/wcsitesinfra/snakeyaml-1.27.jar:${CLASSPATH}
    export CLASSPATH
    ```
	
    c) Copy back the modified setDomainEnv.sh to the pod.
    ```bash
    $ kubectl cp setDomainEnv.sh wcsites-ns/wcsitesinfra-adminserver:/u01/oracle/user_projects/domains/wcsitesinfra/bin/setDomainEnv.sh
    ```

1. Create configuration file for the WebLogic Logging Exporter.
Copy WebLogicLoggingExporter.yaml to the domain folder in the WebLogic server pod. YAML specifies the elasticsearch server host and port number.
    ```bash
    $ kubectl cp WebLogicLoggingExporter.yaml wcsites-ns/wcsitesinfra-adminserver:/u01/oracle/user_projects/domains/wcsitesinfra/config/
    ```

1. Restart WebLogic Servers

    Now we can restart the WebLogic servers for the weblogic-logging-exporter to get loaded in the servers.

    To restart the servers, use stopDomain.sh  and startDomain.sh scripts from https://github.com/oracle/weblogic-kubernetes-operator/tree/master/kubernetes/samples/scripts/domain-lifecycle

    The stopDomain.sh script shuts down a domain by patching the `spec.serverStartPolicy` attribute of the domain resource to `NEVER`. The operator will shut down the WebLogic Server instance Pods that are part of the domain after the `spec.serverStartPolicy` attribute is updated to `NEVER`. See the script usage information by using the -h option.

    ```bash
    $ stopDomain.sh -d wcsitesinfra -n wcsites-ns
    ```
    Sample output:
    ```bash
    [INFO] Patching domain 'wcsitesinfra' in namespace 'wcsites-ns' from serverStartPolicy='IF_NEEDED' to 'NEVER'.
    domain.weblogic.oracle/wcsitesinfra patched
    [INFO] Successfully patched domain 'wcsitesinfra' in namespace 'wcsites-ns' with 'NEVER' start policy!
    ```

    Verify servers by checking the pod status. 
    ```bash
    $ kubectl get pods -n wcsites-ns 
    ```

    After all the servers are shutdown, run startDomain.sh script to start again.

    The startDomain.sh script starts a deployed domain by patching the `spec.serverStartPolicy` attribute of the domain resource to `IF_NEEDED`. The operator will start the WebLogic Server instance Pods that are part of the domain after the `spec.serverStartPolicy` attribute of the domain resource is updated to `IF_NEEDED`. See the script usage information by using the -h option.

    ```bash
    $ startDomain.sh -d wcsitesinfra -n wcsites-ns
    ```
    Sample output:
    ```bash
    [INFO] Patching domain 'wcsitesinfra' from serverStartPolicy='NEVER' to 'IF_NEEDED'.
    domain.weblogic.oracle/wcsitesinfra patched
    [INFO] Successfully patched domain 'wcsitesinfra' in namespace 'wcsites-ns' with 'IF_NEEDED' start policy!
    ```

    Verify servers by checking the pod status. Pod status will be RUNNING.
    ```bash
    $ kubectl get pods -n wcsites-ns 
    ```
    In the server logs, you will be able to see the weblogic-logging-exporter class being called.

1. Create an index pattern in Kibana

    We need to create an index pattern in Kibana for the logs to be available in the dashboard.

    Create an index pattern `wls*` in `Kibana` > `Management`. After the server starts, you will be able to see the log data from the WebLogic servers in the Kibana dashboard,

