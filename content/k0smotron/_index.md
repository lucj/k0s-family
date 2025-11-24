---
title: k0smotron
---

[k0smotron](https://k0smotron.io/) is a Kubernetes operator designed to manage the lifecycle of k0s control planes in a Kubernetes cluster. It turns an existing Kubernetes cluster into a control plane management platform. As the following illustration shows, it enables you to run multiple Kubernetes control planes as Pods in a host/management cluster.

![Overview](./overview.png)
 
In this section, we'll first create a management cluster using [kind](https://kind.sigs.k8s.io/). Next, we'll create a child cluster which control plane is running as Pods in the management cluster. We'll then focus on [CAPI](https://github.com/kubernetes-sigs/cluster-api) to illustrate how k0smotron can be used as a CAPI provider.

{{< callout type="important">}}
Prerequisite: make sure you installed [kind](https://kind.sigs.k8s.io/) on your local machine.
{{< /callout >}}

{{< nav-buttons 
    next_link="./mgmt-cluster"
    next_text="Creating a management cluster"
>}}
