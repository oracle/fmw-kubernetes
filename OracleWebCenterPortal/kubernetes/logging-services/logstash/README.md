## Publish  OracleWebCenterPortal server and diagnostics logs into Elasticsearch

## Prerequisites
See [here](https://oracle.github.io/weblogic-kubernetes-operator/samples/simple/elastic-stack/) for the steps to integrate Elasticsearch for the WebLogic Kubernetes operator.

Before deploying the WebLogic Kubernetes operator edit `values.yaml` in weblogic-kubernetes-operator/kubernetes/charts/weblogic-operator/ to enable elastic search integration. 
Configure the following variables:
```bash	
# elkIntegrationEnabled specifies whether or not ELK integration is enabled.                                           
elkIntegrationEnabled: true                                                                                                                                                                                                           
# logStashImage specifies the docker image containing logstash.                                                        
# This parameter is ignored if 'elkIntegrationEnabled' is false.                                                       
logStashImage: "logstash:6.6.0"                                                                                        
                                                                                                                    
# elasticSearchHost specifies the hostname of where Elasticsearch is running.                                          
# This parameter is ignored if 'elkIntegrationEnabled' is false.                                                       
elasticSearchHost: "elasticsearch.default.svc.cluster.local"                                                           
                                                                                                                    
# elasticSearchPort specifies the port number of where Elasticsearch is running.                                       
# This parameter is ignored if 'elkIntegrationEnabled' is false.                                                       
elasticSearchPort: 9200	
```
Deployment of WebLogic Kubernetes operator with above changes, will create an additional logstash container as sidecar. This logstash container will push the operator logs to the configured Elasticsearch server.

### WebLogic Server logs

The WebLogic server logs or diagnostics logs can be pushed to Elasticsearch server using logstash pod. The logstash pod should have access to the shared domain home or the log location. The persistent volume of the domain home can be used in the logstash pod. 

### Create the logstash pod

1. Get Domain home persistence volume claim details
Get the persistent volume details of the domain home of the WebLogic server(s).

    ```bash
    $ kubectl get pvc -n wcpns  
    ```

1. Create logstash configuration.
Create logstash configuration file. The logstash configuration file can be loaded from a volume. 
    ```bash
    $ kubectl cp logstash.conf  wcpns/wcp-domain-adminserver:/u01/oracle/user_projects/domains --namespace wcpns
    ```

    You can use sample logstash configuration file generated to push server and diagnostic logs of all servers available at DOMAIN_HOME/servers/<server_name>/logs/<server_name>-diagnostic.log

1. Copy the logstash.conf into say /u01/oracle/user_projects/domains so that it can be used for logstash deployment, using Administration Server pod 

1. Create deployment YAML for logstash pod.
You can use sample logstash.yaml file generated to create deployment for logstash pod. The mounted persistent volume of the domain home will provide access to the WebLogic server logs to logstash pod. 
Make sure to point the logstash configuration file to correct location and also correct domain home persistence volume claim. 

1. Deploy logstash to start publish logs to Elasticsearch:

    ```bash
    $ kubectl create -f  logstash.yaml
    ```

1. Now, you can view the diagnostics logs using Kibana with index pattern `logstash-*`.

