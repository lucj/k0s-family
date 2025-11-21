---
title: 'Discover the k0s family'
---

{{< callout type="important">}}
This is a WIP, not fully ready yet.
{{< /callout >}}

<br/>

Welcome to this hands-on workshop where you’ll discover the k0s family which addresses the challenges of managing multi-cluster Kubernetes. At the foundation of this growing ecosystem is [k0s](https://k0sproject.io), a lightweight Kubernetes distribution, which power lies in the tools implemented around it. With k0sctl, you can easily manage cluster lifecycles. k0smotron enables Kubernetes control planes to run inside Pods. And k0rdent provides the building blocks for Kubernetes-based internal developer platforms.

## Requirements

In order to follow this workshop, you'll need to have the following items installed on your local machine.

- [Multipass](https://multipass.run): Multipass is a very handy tool that allows to create Ubuntu virtual machine in a very easy way. It is available on macOS, Windows and Linux.

- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) the command line tool to communicate with a Kubernetes cluster

- [helm](https://helm.sh/docs/intro/install/) the command line tool to manage application in Kubernetes

- [kind](https://kind.sigs.k8s.io/), an useful tool to run Kubernetes in containers

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

