---
title: k0rdent
weight: 4
---

[k0rdent](https://github.com/k0rdent/kcm) is an open-source project allowing you to manage multiple clusters at scale.

k0rdent:
- provides templates for consistent cluster provisioning
- integrates with multiple infrastructure providers (AWS, Azure, GCP, bare metal)
- enables self-service cluster requests through GitOps
- automates day-2 operations (upgrades, scaling, compliance)
- offers multi-tenancy and RBAC controls

![Overview](./overview.svg)

In this section, we'll first create a management cluster using [kind](https://kind.sigs.k8s.io/). Then, we'll use k0rdent to create a child cluster and install [Argo CD](https://argo-cd.readthedocs.io/en/stable) inside it.

{{< nav-buttons 
    next_link="./mgmt_cluster"
    next_text="Creating a management cluster"
>}}

