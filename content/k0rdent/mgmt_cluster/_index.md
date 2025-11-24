---
title: ''
weight: 1
---

In this step we'll create a management cluster. We'll use it next to host the control planes of child clusters.

## Creating the management cluster

We'll run the management cluster in Docker container using [kind](https://kind.sigs.k8s.io) with the following configuration.

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
    - containerPort: 30444
      hostPort: 30444
```

Create the cluster.

```bash
kind create cluster --name mgmt --config config.yaml
```

Next, switch the Kubernetes context to access our newly created cluster.

```bash
kubectl config use-context kind-mgmt
```

{{< callout >}}
You can get the kubeconfig with the following command if you've already created the cluster but lost the kubeconfig.

```bash
kind get kubeconfig --name mgmt > kubeconfig
export KUBECONFIG=$PWD/kubeconfig
```
{{< /callout >}}

Next, check that your one-node cluster is up and running.

```bash
kubectl get no
```

Then, install k0rdent.

```bash
helm install kcm oci://ghcr.io/k0rdent/kcm/charts/kcm --version 1.5.0 -n kcm-system --create-namespace
```

{{< callout type="info">}}
It create several CRDs used for the management of child clusters:

- Management
- Release
- ClusterDeployment
- ProviderTemplate
- ...
{{< /callout >}}

Verify that Pods in `kcm-system` and `projectsveltos` Namespaces are up and running

```bash
kubectl get pods -n kcm-system
kubectl get pods -n projectsveltos
```

{{< callout type="info">}}
In these Namespaces, you'll find the projects, from the Kubernetes ecosystem, that k0rdent relies on. Among them:

- [`Sveltos`](https://github.com/projectsveltos) simplifies management of add-ons
- CAPI core provider
- CAP{A,D,G,O,V,Z} provider
{{< /callout >}}

Make sure that the Management resource is ready. 

```bash
$ kubectl get Management -n kcm-system
NAME   READY   RELEASE     AGE
kcm    True    kcm-1-5-0   3m
```

Verify the Cluster API related resources are created.

```bash
$ kubectl get providertemplate -n kcm-system
NAME                                               VALID
cluster-api-1-0-7                                  true
cluster-api-provider-aws-1-0-7                     true
cluster-api-provider-azure-1-0-9                   true
cluster-api-provider-docker-1-0-5                  true
cluster-api-provider-gcp-1-0-6                     true
cluster-api-provider-infoblox-1-0-2                true
cluster-api-provider-ipam-1-0-3                    true
cluster-api-provider-k0sproject-k0smotron-1-0-11   true
cluster-api-provider-openstack-1-0-10              true
cluster-api-provider-vsphere-1-0-6                 true
kcm-1-5-0                                          true
kcm-regional-1-0-5                                 true
projectsveltos-1-1-1                               true
```

```bash
$ kubectl get clustertemplate -n kcm-system
NAME                             VALID
adopted-cluster-1-0-1            true
aws-eks-1-0-3                    true
aws-hosted-cp-1-0-16             true
aws-standalone-cp-1-0-16         true
azure-aks-1-0-1                  true
azure-hosted-cp-1-0-19           true
azure-standalone-cp-1-0-17       true
docker-hosted-cp-1-0-4           true
gcp-gke-1-0-6                    true
gcp-hosted-cp-1-0-16             true
gcp-standalone-cp-1-0-15         true
openstack-hosted-cp-1-0-7        true
openstack-standalone-cp-1-0-17   true
remote-cluster-1-0-15            true
vsphere-hosted-cp-1-0-15         true
vsphere-standalone-cp-1-0-15     true
```


```bash
apiVersion: clusters.k0rdent.io/v1alpha1
kind: Cluster
metadata:
  name: demo-child
spec:
  class: k0smotron-docker # provided out of the box by k0rdent
  parameters:
    kubernetesVersion: "1.34.1"
    controlPlane:
      replicas: 1
    workers:
      machineDeployments:
      - name: default
        replicas: 2
```

{{< nav-buttons 
    next_link="../child_cluster"
    next_text="Creating a child cluster"
>}}
