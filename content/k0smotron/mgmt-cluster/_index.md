---
title: Management cluster
weight: 1
---

In this step we'll create a management cluster, and install k0smotron inside it to host the control planes of child clusters.

{{< callout type="info">}}
In this first part, we'll install k0smotron in standalone mode, meaning it does not interact with Cluster API (CAPI) resources. We'll discuss CAPI in a next section.
{{< /callout >}}

## Creating the cluster

First, define the kind's configuration file for our management cluster.

```yaml {filename="config.yaml"}
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30443
    hostPort: 30443
    protocol: TCP
  - containerPort: 30444
    hostPort: 30444
    protocol: TCP
  - containerPort: 30445
    hostPort: 30445
    protocol: TCP
```

Next, create the cluster.

```bash
kind create cluster --name mgmt --config config.yaml
```

Then, switch the Kubernetes context to access our newly created cluster.

```bash
kubectl config use-context kind-mgmt
```

Your one-node management cluster is up and running.

```bash
$ kubectl get no
NAME                 STATUS   ROLES           AGE     VERSION
mgmt-control-plane   Ready    control-plane   3m36s   v1.34.0
```

## Installing cert-manager

Before installing `k0smotron`, we need to install cert-manager. Use the following command to install it using Helm.

```bash
helm repo add jetstack https://charts.jetstack.io --force-update

helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.19.1 \
  --set crds.enabled=true
```

## Installing k0smotron

Install `k0smotron` as follows.

```bash
kubectl apply --server-side=true -f https://docs.k0smotron.io/stable/install.yaml
```

The management cluster is now ready to host control plane of child cluster. This is the topic of the next section.

{{< nav-buttons 
    next_link="../child-cluster"
    next_text="Creating a child cluster"
>}}
