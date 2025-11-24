---
title: CAPI
weight: 3
---

## What is CAPI

[Cluster API](https://github.com/kubernetes-sigs/cluster-api) (a.k.a. CAPI) is defined as a Kubernetes sub-project focused on providing declarative APIs and tooling to simplify provisioning, upgrading, and operating multiple Kubernetes clusters.

## k0smotron as a CAPI provider

k0smotron can act as a CAPI provider in 3 ways:

- control-plane
- bootstrap
- infrastructure

This example demonstrates how k0smotron can be used with CAPD (Cluster API Provider Docker).

{{< callout type="info">}}
CAPD should only be used for development purposes and not for production environments.
{{< /callout >}}

## Creating the management cluster

We'll run the management cluster in Docker container using [kind](https://kind.sigs.k8s.io) once again. First, create the following configuration file.

```yaml {filename="config.yaml"}
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  ipFamily: ipv4
nodes:
- role: control-plane
  extraMounts:
    - hostPath: /var/run/docker.sock
      containerPath: /var/run/docker.sock
  extraPortMappings:
    - containerPort: 30443
      hostPort: 30443
```

Next, create the cluster.

```bash
kind create cluster --name mgmt --config config.yaml
```

Next, switch the Kubernetes context to access our newly created cluster.

```bash
kubectl config use-context kind-mgmt
```

Then, check that your one-node cluster is up and running.

```bash
kubectl get no
```

Initialize the management cluster so that it installs k0smotron CAPI provider and Docker infrastructure provider. For more details on Cluster API Provider Docker see it's [docs](https://github.com/kubernetes-sigs/cluster-api/tree/main/test/infrastructure/docker).

```bash
clusterctl init --control-plane k0sproject-k0smotron --bootstrap k0sproject-k0smotron --infrastructure docker
```

## Creating a child cluster

Once all the controllers are up and running, you can apply the cluster manifests containing the specifications of the cluster you want to provision. Here is an example:

{{% details title="Cluster specification" closed="true" %}}

```yaml {filename="docker-demo.yaml"}
apiVersion: cluster.x-k8s.io/v1beta2
kind: Cluster
metadata:
  name: docker-demo
  namespace: default
spec:
  clusterNetwork:
    pods:
      cidrBlocks:
      - 192.168.0.0/16
    serviceDomain: cluster.local
    services:
      cidrBlocks:
      - 10.128.0.0/12
  controlPlaneRef:
    apiGroup: controlplane.cluster.x-k8s.io
    kind: K0smotronControlPlane   # This is the config for the controlplane
    name: docker-demo-cp
  infrastructureRef:
    apiGroup: infrastructure.cluster.x-k8s.io
    kind: DockerCluster
    name: docker-demo
---
apiVersion: controlplane.cluster.x-k8s.io/v1beta1
kind: K0smotronControlPlane
metadata:
  name: docker-demo-cp
  namespace: default
spec:
  version: v1.34.1-k0s.0
  persistence:
    type: emptyDir
  service:
    type: NodePort
---
apiVersion: infrastructure.cluster.x-k8s.io/v1beta2
kind: DockerCluster
metadata:
  name: docker-demo
  namespace: default
  annotations:
    cluster.x-k8s.io/managed-by: k0smotron   # This marks the base infra to be self managed. The value of the annotation is irrelevant, as long as there is a value.
spec: {}
---
apiVersion: cluster.x-k8s.io/v1beta2
kind: MachineDeployment
metadata:
  name:  docker-demo-md
  namespace: default
spec:
  clusterName: docker-demo
  replicas: 1
  selector:
    matchLabels:
      cluster.x-k8s.io/cluster-name: docker-demo
      pool: worker-pool-1
  template:
    metadata:
      labels:
        cluster.x-k8s.io/cluster-name: docker-demo
        pool: worker-pool-1
    spec:
      clusterName: docker-demo
      version: v1.34.0   # Docker Provider requires a version to be set (see https://hub.docker.com/r/kindest/node/tags)
      bootstrap:
        configRef:
          apiGroup: bootstrap.cluster.x-k8s.io
          kind: K0sWorkerConfigTemplate
          name: docker-demo-machine-config
      infrastructureRef:
        apiGroup: infrastructure.cluster.x-k8s.io
        kind: DockerMachineTemplate
        name: docker-demo-mt
---
apiVersion: infrastructure.cluster.x-k8s.io/v1beta2
kind: DockerMachineTemplate
metadata:
  name: docker-demo-mt
  namespace: default
spec:
  template:
    spec: {}
    # More details of the DockerMachineTemplate can be set here
---
apiVersion: bootstrap.cluster.x-k8s.io/v1beta1
kind: K0sWorkerConfigTemplate
metadata:
  name: docker-demo-machine-config
spec:
  template:
    spec:
      version: v1.34.1+k0s.0
      # More details of the worker configuration can be set here
```

{{% /details %}}

Create these resources, it only takes a few tens of seconds for the child cluster to the created. 

```bash
kubectl apply -f docker-demo.yaml
```

When the child cluster is up and running, verify the Cluster and Machine resources.

```bash
% kubectl get cluster,machine
NAME                                   CLUSTERCLASS   AVAILABLE   CP DESIRED   CP AVAILABLE   CP UP-TO-DATE   W DESIRED   W AVAILABLE   W UP-TO-DATE   PHASE         AGE     VERSION
cluster.cluster.x-k8s.io/docker-demo                  True        1            1              1               1           1             1              Provisioned   2m45s   

NAME                                                  CLUSTER       NODE NAME                    READY   AVAILABLE   UP-TO-DATE   PHASE     AGE   VERSION
machine.cluster.x-k8s.io/docker-demo-md-cn5pq-4vjcn   docker-demo   docker-demo-md-cn5pq-4vjcn   True    True        True         Running   89s   v1.34.0
```

## Accessing the child cluster

To access the child cluster, get the kubeconfig and save it to `docker-demo.conf`.

```bash
clusterctl get kubeconfig docker-demo > docker-demo.conf
```

Because we are using the CAPD provider we need to change the `server` property of this kubeconfig so that we can access the cluster from our local machine.

```bash
kubectl config set-cluster docker-demo --server=https://localhost:30443 --kubeconfig=$PWD/docker-demo.conf
```

Verify you can access the child cluster.

```bash
kubectl get nodes --kubeconfig=$PWD/docker-demo.conf
```

## Deleting the child cluster

{{< callout type="warning">}}
Do not use `kubectl delete -f docker-demo.yaml` to delete the cluster as it can result in orphan resources.
{{< /callout >}}

Delete the top level `Cluster` object

```bash
kubectl delete cluster docker-demo
```

## Deleting the management cluster

You can also delete the management cluster.

```bash
kind delete clusters mgmt
```

{{< nav-buttons 
    prev_link="../child-clusters"
    prev_text="Creating a child cluster"
    next_link="../../k0rdent"
    next_text="Introduction to k0rdent"
>}}
