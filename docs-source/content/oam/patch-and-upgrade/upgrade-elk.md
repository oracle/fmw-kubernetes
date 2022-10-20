---
title: "d. Upgrade Elasticsearch and Kibana"
description: "Instructions on how to upgrade Elastic Search and Kibana."
---

This section shows how to upgrade Elasticsearch and Kibana.

To determine if this step is required for the version you are upgrading to, refer to the [Release Notes](../../release-notes).

### Undeploy Elasticsearch and Kibana

From October 22 (22.4.1) onwards, OAM logs should be stored on a centralized Elasticsearch and Kibana stack.

Deployments prior to October 22 (22.4.1) used local deployments of Elasticsearch and Kibana. 

If you are upgrading from July 22 (22.3.1) or earlier, to October 22 (22.4.1) or later, you must first undeploy Elasticsearch and Kibana using the steps below:

1. Make sure you have downloaded the latest code repository as per [Download the latest code repository](../upgrade-an-ingress/#download-the-latest-code-repository)

1. Edit the `$WORKDIR/kubernetes/elasticsearch-and-kibana/elasticsearch_and_kibana.yaml` and change all instances of namespace to correspond to your deployment. 

1. Delete the Elasticsearch and Kibana resources using the following command:

   ```
   $ kubectl delete -f $WORKDIR/kubernetes/elasticsearch-and-kibana/elasticsearch_and_kibana.yaml
   ```

### Deploy Elasticsearch and Kibana in centralized stack

1. Follow [Install Elasticsearch stack and Kibana](../../manage-oam-domains/logging-and-visualization/#install-elasticsearch-stack-and-kibana) to deploy Elasticsearch and Kibana in a centralized stack.
