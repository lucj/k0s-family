---
title: Introduction to k0s
weight: 1
---

[k0s](https://k0sproject.io/) is a Kubernetes distribution developed by [Mirantis](https://mirantis.com). It is shipped as a single binary without any OS dependencies and is thus defined as a zero-friction/zero-deps/zero-cost Kubernetes distribution.

k0s:
- ships a certified and (CIS-benchmarked) Kubernetes 1.33
- uses containerd as the default container runtime
- supports x86-64, ARM64 and ARMv7 architectures
- uses an in-cluster etcd
- uses the Kube-router network plugin by default
- uses DNS with CoreDNS
- exposes cluster metrics via Metrics Server
- allows the usage of Horizontal Pod Autoscaling (HPA)
- ...

