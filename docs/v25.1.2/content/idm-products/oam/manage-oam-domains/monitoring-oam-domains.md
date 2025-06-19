---
title: "d. Monitoring an OAM domain"
description: "Describes the steps for Monitoring the OAM domain."
---

After the OAM domain is set up you can monitor the OAM instance using Prometheus and Grafana. 

### Monitor the Oracle Access Management instance using Prometheus and Grafana
Using the `WebLogic Monitoring Exporter` you can scrape runtime information from a running Oracle Access Management instance and monitor them using Prometheus and Grafana.

#### Set up monitoring
Follow [these steps](https://github.com/oracle/fmw-kubernetes/blob/v25.1.1/OracleAccessManagement/kubernetes/monitoring-service/README.md) to set up monitoring for an Oracle Access Management instance. For more details on WebLogic Monitoring Exporter, see [here](https://github.com/oracle/weblogic-monitoring-exporter).