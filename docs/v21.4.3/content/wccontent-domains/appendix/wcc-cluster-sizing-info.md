---
title: "Domain resource sizing"
date: 2021-02-01T15:44:42-05:00
draft: false
weight: 1
pre : "<b> </b>"
description: "Describes the resourse sizing information for Oracle WebCenter Content domain setup on Kubernetes cluster."
---

### Oracle WebCenter Content cluster sizing recommendations
Oracle WCC | Normal Usage | Moderate Usage | High Usage
--- | --- | --- | ---
Administration Server | No of CPU core(s) : 1, Memory : 4GB | No of CPU core(s) : 1, Memory : 4GB | No of CPU core(s) : 1, Memory : 4GB
Number of Managed Servers | 2 | 3 | 5
Configurations per Managed Server | No of CPU core(s) : 2, Memory : 16GB | No of CPU core(s) : 4, Memory : 16GB | No of CPU core(s) : 6, Memory : 16-32GB
PV Storage | Minimum 250GB | Minimum 250GB | Minimum 500GB
