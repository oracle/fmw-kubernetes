---
title: "Domain resource sizing"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 1
pre : "<b> </b>"
description: "Describes the resourse sizing information for the Oracle WebCenter Portal domain setup on Kubernetes cluster."
---

### Oracle WebCenter Portal cluster sizing recommendations

WebCenter Portal | Normal Usage | Moderate Usage | High Usage 
--- | --- | --- | --- 
Admin Server | No of CPU(s) : 1, Memory : 4GB | No of CPU(s) : 1, Memory : 4GB | No of CPU(s) : 1, Memory : 4GB 
Number of Managed Server | No of Servers : 2 | No of Servers : 2 | No of Servers : 3
Configurations per Managed Server | No of CPU(s) : 2, Memory : 16GB | No of CPU(s) : 4, Memory : 16GB |  No of CPU(s) : 6, Memory : 16-32GB
PV Storage | Minimum 250GB | Minimum 250GB | Minimum 500GB

