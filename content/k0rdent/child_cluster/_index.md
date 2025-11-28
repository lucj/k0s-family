---
title: ''
weight: 2
---

## Creating a child cluster

In this section, we'll create a child cluster using a template named `docker-hosted-cp-1-0-4`. This template uses:
- k0smotron to run the control plane in Pods in the management cluster
- docker to run the worker Nodes

{{< callout >}}
The steps below can be used to run a local child cluster, but the same logic can be used to create other types of child cluster.
{{< /callout >}}

First, create the following specification defining a `Secret`.

```yaml{filename="secret.yaml"}
apiVersion: v1
kind: Secret
metadata:
  name: docker-identity
  namespace: kcm-system
  labels:
    k0rdent.mirantis.com/component: "kcm"
type: Opaque
stringData:
  placeholder: "none"
```

Next, create a `Credentials` specification, which references the `Secret` created above.

```yaml{filename="credentials.yaml"}
apiVersion: k0rdent.mirantis.com/v1beta1
kind: Credential
metadata:
  name: docker-default
  namespace: kcm-system
spec:
  identityRef:
    apiVersion: v1
    kind: Secret
    name: docker-identity
    namespace: kcm-system
  description: "Placeholder credential for local Docker (CAPD)"
```

Next, create the `ClusterDeployment` specification. It specifies the template to use (`docker-hosted-cp-1-0-4`) and references the `Credentials` defined above. The resource is the one which defines the cluster's components to create.

```yaml {filename="clusterdeployment.yaml"}
apiVersion: k0rdent.mirantis.com/v1beta1
kind: ClusterDeployment
metadata:
  name: docker-demo
  namespace: kcm-system
  labels:
      env: demo 
spec:
  template: docker-hosted-cp-1-0-4
  credential: docker-default
  config:
    kubernetesVersion: v1.34.1-k0s.0
    controlPlane:
      replicas: 1
    worker:
      replicas: 1
```

Then, create the resources from these specifications.

```bash
kubectl apply -f secret.yaml
kubectl apply -f credentials.yaml
kubectl apply -f clusterdeployment.yaml
```

After a few tens of seconds, check the `ClusterDeployment`'s status.

```bash
kubectl get clusterDeployment -A
NAMESPACE    NAME          READY   SERVICES   TEMPLATE                 MESSAGES          AGE
kcm-system   docker-demo   True    0/0        docker-hosted-cp-1-0-4   Object is ready   5m
```

Next, verify that a `Cluster` resource was created.

```bash
$ kubectl get cluster -A
NAMESPACE    NAME          CLUSTERCLASS   AVAILABLE   CP DESIRED   CP AVAILABLE   CP UP-TO-DATE   W DESIRED   W AVAILABLE   W UP-TO-DATE   PHASE         AGE    VERSION
kcm-system   docker-demo                  True        1            1              1               1           1             1              Provisioned   7m
```

Next, get the kubeconfig of this child cluster.

```bash
kubectl get secret docker-demo-kubeconfig -n kcm-system -o jsonpath='{.data.value}' | base64 -d > kubeconfig-docker-demo
```

Then, configure your local kubectl to communicate with the child cluster.

```bash
export KUBECONFIG=$PWD/kubeconfig-docker-demo
```

As we are using a management cluster based on `kind`, we need to change the server property as it currently references the internal IP of the control plane Pod.

```bash
kubectl config set-cluster docker-demo-k0s --server=https://localhost:55000
```

Verify that your cluster has a single Node, as requested in the `ClusterDeployment`.

```bash
$ kubectl get nodes
NAME                         STATUS   ROLES    AGE    VERSION
docker-demo-md-b85kl-pktww   Ready    <none>   15m   v1.32.8+k0s
```

{{< callout type="info">}}
The single worker Node of the cluster is based on k0s version `v1.32.8+k0s` as this is the specific version referenced in the `ClusterTemplate` resource the `ClusterDeployment` is using.
{{< /callout >}}

## Installing an application in the child cluster

To install some applications in the child cluster, k0rdent relies on the following CRDs:

- `MultiClusterServices` allows you to deploy a service across one or multiple child clusters
- `ServiceSets` defines a collection of services installed together
- `ServiceTemplateChains` defines a sequence of templates applied in order
- `ServiceTemplates` specifies how to deploy a single service

In this step, we'll deploy [Argo CD](https://argo-cd.readthedocs.io/en/stable/) to the child cluster. First, create the following file containing the specification of a `MultiClusterService`.

```yaml{filename="mcs.yaml"}
apiVersion: k0rdent.mirantis.com/v1beta1
kind: MultiClusterService
metadata:
  name: argocd-demo
  namespace: kcm-system
spec:
  clusterSelector:
    matchLabels:
      env: demo
  serviceSpec:
    services:
      - name: argocd-demo-service
        namespace: argocd
        template: argo-cd-8-6-1
```

{{< callout >}}
The `matchLabels` property of the `MultiClusterService` must match the labels defined in the `ClusterDeployment` resource.
{{< /callout >}}

Then, create the `MultiClusterService` in the management cluster.

```bash
kubectl apply -f mcs.yaml --kubeconfig=/PATH/TO/MGMT_CLUSTER_KUBECONFIG
```

After a few seconds, you'll have Argo CD running in your child cluster.

```bash
$ k get po -A
NAMESPACE        NAME                                                             READY   STATUS      RESTARTS   AGE
argocd           argocd-demo-service-application-controller-0                     1/1     Running     0          25s
argocd           argocd-demo-service-applicationset-controller-5655779fd9-b4z6r   1/1     Running     0          25s
argocd           argocd-demo-service-dex-server-796cddb478-7lfhd                  1/1     Running     0          25s
argocd           argocd-demo-service-notifications-controller-8675d79d5c-kchkr    1/1     Running     0          25s
argocd           argocd-demo-service-redis-5f4f47c684-xwv65                       1/1     Running     0          25s
argocd           argocd-demo-service-redis-secret-init-fchz9                      0/1     Completed   0          35s
argocd           argocd-demo-service-repo-server-6b4f8bdddb-shdwz                 1/1     Running     0          25s
argocd           argocd-demo-service-server-5655564bf4-h65gh 
...
```

{{< callout type="info">}}
We've only scratched the surface of k0rdent, check the [documentation](https://docs.k0rdent.io/latest/) to get a detailed view of all its capabilities.
{{< /callout >}}

{{< nav-buttons 
    prev_link="../mgmt_cluster"
    prev_text="Creating a management cluster"
    next_link="../../congrats"
    next_text="Congratulations"
>}}
