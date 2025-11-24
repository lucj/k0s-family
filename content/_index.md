---
title: 'Discover the k0s family'
---

{{< callout type="warning">}}
This content is a work in progress, it's not fully ready yet.
{{< /callout >}}

{{< callout type="important">}}
Disclaimer: this content is created for educational purposes, it's independent of the [k0s](https://k0sproject.io) CNCF project.
{{< /callout >}}



<br/>

Welcome to this hands-on workshop where you’ll discover the k0s family which addresses the challenges of managing multi-cluster Kubernetes. At the foundation of this ecosystem is [k0s](https://k0sproject.io), a lightweight Kubernetes distribution, which power lies in the tools implemented around it. With [k0sctl](https://github.com/k0sproject/k0sctl), you can easily manage cluster lifecycles. [k0smotron](https://k0smotron.io) enables Kubernetes control planes to run inside Pods. And [k0rdent](https://k0rdent.io) provides the building blocks for Kubernetes-based internal developer platforms.

## Requirements

In order to follow this workshop, you'll need to have the following items installed on your local machine.

- [Multipass](https://multipass.run): an handy tool that allows you to create Ubuntu virtual machine with ease. It is available on macOS, Windows and Linux.

- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl): the command line tool to communicate with a Kubernetes cluster

- [helm](https://helm.sh/docs/intro/install/): the command line tool to manage application in Kubernetes

- [kind](https://kind.sigs.k8s.io/): a useful tool to run Kubernetes in containers

- [clusterctl](https://cluster-api.sigs.k8s.io/user/quick-start#install-clusterctl): a CLI tool to manage clusters created with Cluster API

## Workshop's layout

To get the most out of the workshop, please follow the section below in order, starting with the [introduction to k0s](./k0s).

{{< cards >}}
    {{< card    link="./k0s" 
                title="k0s" 
                subtitle="Discover k0s, a lightweight Kubernetes distribution" 
                icon=""
    >}}
    {{< card    link="./k0sctl" 
                title="k0sctl" 
                subtitle="Manage multi k0s clusters with k0stcl" 
                icon=""
    >}}
    {{< card    link="./k0smotron" 
                title="k0smotron" 
                subtitle="Use k0smotron to run Kubernetes control planes inside Pods" 
                icon=""
    >}}
    {{< card    link="./k0rdent" 
                title="k0rdent" 
                subtitle="Manage hundreds of clusters from a single point of control with k0rdent" 
                icon=""
    >}}
{{< /cards >}}

<br/>

{{< callout type="info">}}
We use different environments to showcase each tool's strengths:

- **k0s & k0sctl**: Multipass VMs (traditional deployment)
- **k0smotron & k0rdent**: kind + Docker (cloud-native patterns)
{{< /callout >}}

