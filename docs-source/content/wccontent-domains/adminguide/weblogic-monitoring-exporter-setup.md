---
title: "Monitor an Oracle WebCenter Content domain"
weight: 2
pre : "<b> </b>"
description: "Use the WebLogic Monitoring Exporter to monitor an Oracle WebCenter Content instance using Prometheus and Grafana."
---

You can monitor a WebCenter Content domain using Prometheus and Grafana by exporting the metrics from the domain instance using the
WebLogic Monitoring Exporter.


### Set up monitoring for OracleWebCenterContent domain 

Using the `WebLogic Monitoring Exporter` you can scrape runtime information from a running Oracle WebCenter Content Suite instance and monitor them using Prometheus and Grafana.
Follow [these steps](https://github.com/oracle/fmw-kubernetes/blob/v22.4.1/OracleWebCenterContent/kubernetes/monitoring-service/README.md) to set up monitoring for an Oracle WebCenter Content Suite instance. For more details on WebLogic Monitoring Exporter, see [here](https://github.com/oracle/weblogic-monitoring-exporter).

### Verify monitoring using Grafana Dashboard

After set-up is complete, to view the domain metrics, you can access the Grafana dashboard at `http://mycompany.com:32100/`. 

This displays the WebLogic Server Dashboard.

![wcc-gp-dashboard](images/wcc-gp-dashboard.png)
