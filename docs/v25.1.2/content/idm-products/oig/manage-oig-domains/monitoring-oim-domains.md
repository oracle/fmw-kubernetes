---
title: "e. Monitoring an OIG domain"
description: "Describes the steps for Monitoring the OIG domain and Publishing the logs to Elasticsearch."
---

After the OIG domain is set up you can monitor the OIG instance using Prometheus and Grafana. 

### Monitor the Oracle Identity Management instance using Prometheus and Grafana
Using the `WebLogic Monitoring Exporter` you can scrape runtime information from a running Oracle Identity Management instance and monitor them using Prometheus and Grafana.

#### Set up monitoring
Follow [these steps](https://github.com/oracle/fmw-kubernetes/blob/v25.1.1/OracleIdentityGovernance/kubernetes/monitoring-service/README.md) to set up monitoring for an Oracle Identity Management instance. For more details on WebLogic Monitoring Exporter, see [here](https://github.com/oracle/weblogic-monitoring-exporter).