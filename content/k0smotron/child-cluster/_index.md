---
title: Child clusters
weight: 2
---

In this section, we'll create two child clusters. We'll use k0smotron to manage the control planes of each one, and we'll run worker Nodes in Docker containers.

## Creating a first child cluster

First, create the following specification that defines a `Cluster` resource.

```yaml {filename="cluster-1.yaml"}
apiVersion: k0smotron.io/v1beta1
kind: Cluster
metadata:
  name: cluster-1
spec:
  version: v1.34.1-k0s.0
  replicas: 1
  service:
    type: NodePort
    apiPort: 30443
    konnectivityPort: 30132
```

Next, create the resource.

```bash
kubectl apply -f cluster-1.yaml
```

After a few tens of seconds, you'll see 2 additional Pods running in the management cluster:
- kmc-cluster-1-0 is a Pod running containers for the API Server, Scheduler and Controller Manager of `cluster-1`
- kmc-cluster-1-etcd-0 is a Pod running etcd for this same cluster

```bash
$ k get po | grep cluster-1
kmc-cluster-1-0        1/1     Running   0          64s
kmc-cluster-1-etcd-0   1/1     Running   0          64s
```

Get the kubeconfig file of this child cluster from the `Secret` named `cluster-1-kubeconfig` created by k0smotron.

```bash
kubectl get secret cluster-1-kubeconfig -o jsonpath='{.data.value}' | base64 -d > cluster-1.conf
```

Change the server property of this kubeconfig so it points towards the API Server exposed by the kind management cluster.

```bash
export KUBECONFIG=$PWD/cluster-1.conf
kubectl config set-cluster cluster-1 --server=https://localhost:30443
```

Then, you should see the following pending Pods in the child cluster. This is totally fine, and is due to the fact this cluster does not have any worker Nodes yet.

```bash
$ kubectl get po -A
NAMESPACE     NAME                              READY   STATUS    RESTARTS   AGE
kube-system   coredns-7656c59669-d6jq4          0/1     Pending   0          119s
kube-system   metrics-server-67bc669cf4-2q6mt   0/1     Pending   0          110s
```

## Creating a second child cluster

We'll now create another child cluster. First, create the following specification that defines a `Cluster` resource.

```yaml {filename="cluster-2.yaml"}
apiVersion: k0smotron.io/v1beta1
kind: Cluster
metadata:
  name: cluster-2
spec:
  version: v1.34.1-k0s.0
  replicas: 1
  service:
    type: NodePort
    apiPort: 30444             # <- change the apiPort to this value
    konnectivityPort: 30133    # <- change the konnectivityPort to this value
```

Next, retrieve the kubeconfig file of this new cluster.

```bash
kubectl get secret cluster-2-kubeconfig -o jsonpath='{.data.value}' | base64 -d > cluster-2.conf
```

Next, change the server property, as you've done for the first child cluster.

```bash
export KUBECONFIG=$PWD/cluster-1.conf
kubectl config set-cluster cluster-2 --server=https://localhost:30444
```

Then, verify you can list the Pods of this new child cluster.

```bash
$ kubeclt get po -A
NAMESPACE     NAME                              READY   STATUS    RESTARTS   AGE
kube-system   coredns-7656c59669-2c2hm          0/1     Pending   0          3m31s
kube-system   metrics-server-67bc669cf4-rfqvp   0/1     Pending   0          3m24s
```

This section illustrates how we can create several control planes in the management cluster. In the next section, we'll add worker nodes to one of the child cluster.

## Adding nodes

First, configure your local kubectl so ti communicates with the API Server of the first child cluster.

```bash
export KUBECONFIG=cluster1.kubeconfig
```

To create a worker Node, we first need to get a join token. This can be done in 2 ways, either by:
- getting a join token directly from the control plane
- getting a join token using a dedicated resource

We'll explore both approaches below.

### Getting a join token from control plane directly

Use the following command to exec into the control plane Pods and get a join token using the k0s binary.

```bash
TOKEN=$(kubectl exec -it kmc-cluster-1-0 -- k0s token create --role worker)
```

Next, create this temporary `resolv.conf` file. It will prevent DNS issues when running a worker Node in a Docker container. 

```bash
cat > /tmp/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
options ndots:0
EOF
```

Then, create a worker Node as follows.

```bash
docker run -d --privileged \
  --network kind \
  -v /tmp/resolv.conf:/etc/resolv.conf \
  -v /var/lib/k0s \
  k0sproject/k0s:v1.34.1-k0s.0 k0s worker "$TOKEN"
```

After a few tens of seconds, verify the child cluster now has a worker Node.

```bash
kubectl get nodes
```

### Getting a join token using the `JoinTokenRequest` resource

The cleanest way to get a join token is to create a `JointTokenRequest` as follows. 

```bash
cat <<EOF | kubectl apply -f -
apiVersion: k0smotron.io/v1beta1
kind: JoinTokenRequest
metadata:
  name: cluster-1-worker-token
  namespace: default
spec:
  clusterRef:
    name: cluster-1
    namespace: default
EOF
```

Next, get the token from the Secret generated.

```bash
TOKEN=$(kubectl get secret cluster-1-worker-token -o jsonpath='{.data.token}' | base64 -d)
```

Then, create the worker Node as you did previously.

```bash
docker run -d --privileged \
  --network kind \
  -v /tmp/resolv.conf:/etc/resolv.conf \
  -v /var/lib/k0s \
  k0sproject/k0s:v1.34.1-k0s.0 k0s worker "$TOKEN"
```

In the next section, we'll explore CAPI and how k0smotron can be used as a CAPI provider.

{{< nav-buttons 
    prev_link="../mgmt-cluster"
    prev_text="Creating a management cluster"
    next_link="../capi"
    next_text="Introduction to Cluster API"
>}}
