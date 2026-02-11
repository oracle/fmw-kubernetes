---
title: "Security hardening"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 3
pre : "<b> </b>"
description: "Review resources for the Docker and Kubernetes cluster hardening."
---

Securing a Kubernetes cluster involves hardening on multiple fronts - securing the API servers, etcd, nodes, container images, container run-time, and the cluster network. Apply principles of defense in depth, principle of least privilege, and minimize the attack surface. Use security tools such as [Kube-Bench](https://github.com/aquasecurity/kube-bench) to verify the cluster's security posture. Since Kubernetes is evolving rapidly refer to [Kubernetes Security Overview](https://kubernetes.io/docs/concepts/security/overview/) for the latest information on securing a Kubernetes cluster. Also ensure the deployed Docker containers follow the [Docker Security](https://docs.docker.com/engine/security/security/) guidance.

This section provides references on how to securely configure Docker and Kubernetes.

#### References

1. Docker hardening
   * https://docs.docker.com/engine/security/security/
   * https://blog.aquasec.com/docker-security-best-practices

1. Kubernetes hardening
   * https://kubernetes.io/docs/concepts/security/overview/
   * https://kubernetes.io/docs/concepts/security/pod-security-standards/
   * https://blogs.oracle.com/developers/5-best-practices-for-kubernetes-security

1. Security best practices for Oracle WebLogic Server Running in Docker and Kubernetes
   * https://blogs.oracle.com/weblogicserver/security-best-practices-for-weblogic-server-running-in-docker-and-kubernetes
