---
title: Management cluster
weight: 1
---

In this step we'll create a management cluster, that we'll use to host the workload clusters' control plane.

## Creating the cluster

First, we install [kind](https://kind.sigs.k8s.io/), an handy tool that allows creating Kubernetes clusters in containers.

Next, we define a configuration file for this cluster.


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

Next, we create the cluster.

```bash
kind create cluster --name mgmt --config config.yaml
```

Then, we switch the Kubernetes context to access our newly created cluster.

```bash
kubectl config use-context kind-mgmt
```

Our onde-node cluster is up and running.

```bash
$ kubectl get no
NAME                 STATUS   ROLES           AGE     VERSION
mgmt-control-plane   Ready    control-plane   3m36s   v1.34.0
```

## Installing cert-manager

Before installing `k0smotron`, we need to install cert-manager.

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

We can now install `k0smotron`.

```bash
kubectl apply --server-side=true -f https://docs.k0smotron.io/stable/install.yaml
```

{{< nav-buttons 
    next_link="../workload-clusters"
    next_text="Workload clusters"
>}}
