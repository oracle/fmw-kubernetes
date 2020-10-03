---
title: "Domain resource sizing"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 1
pre : "<b> </b>"
description: "Describes the resourse sizing information for Oracle SOA Suite domains setup on Kubernetes cluster."
---

### Oracle SOA cluster sizing recommendations
Oracle SOA | Normal Usage | Moderate Usage | High Usage
--- | --- | --- | ---
Administration Server | No of CPU core(s) : 1, Memory : 4GB | No of CPU core(s) : 1, Memory : 4GB | No of CPU core(s) : 1, Memory : 4GB
Managed Server | No of Servers : 2, No of CPU core(s) : 2, Memory : 16GB | No of Servers : 2, No of CPU core(s) : 4, Memory : 16GB | No of Servers : 3, No of CPU core(s) : 6, Memory : 16-32GB
PV Storage | Minimum 250GB | Minimum 250GB | Minimum 500GB
