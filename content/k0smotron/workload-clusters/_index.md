---
title: Workload clusters
weight: 2
---

In this section, we'll create two clusters in the `standalone` mode (we'll see the CAPI provider way of creating a cluster in a next section).

## Creating a first workload cluster


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

```bash
$ k get po | grep cluster-1
kmc-cluster-1-0        1/1     Running   0          64s
kmc-cluster-1-etcd-0   1/1     Running   0          64s
```



```
kubectl get secret cluster-1-kubeconfig -o jsonpath='{.data.value}' | base64 -d > cluster-1.conf
```

Change server from `server: https://172.19.0.2:30443` to `server: https://localhost:30443`

```bash
export KUBECONFIG=$PWD/cluster-1.conf
```

```bash
$ kubectl get po -A
NAMESPACE     NAME                              READY   STATUS    RESTARTS   AGE
kube-system   coredns-7656c59669-d6jq4          0/1     Pending   0          119s
kube-system   metrics-server-67bc669cf4-2q6mt   0/1     Pending   0          110s
```



## Creating a second workload cluster

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

Next, we retrieve the kubeconfig file of this new cluster.

```bash
kubectl get secret cluster-2-kubeconfig -o jsonpath='{.data.value}' | base64 -d > cluster-2.conf
```

Next, we change the server property, as we've done previously.

Change `server: https://172.19.0.2:30444` to `server: https://localhost:30444`

Then, we can configure our local `kubectl` to access this new cluster.

```bash
$ export KUBECONFIG=$PWD/cluster-2.conf

$ kubeclt get po -A
NAMESPACE     NAME                              READY   STATUS    RESTARTS   AGE
kube-system   coredns-7656c59669-2c2hm          0/1     Pending   0          3m31s
kube-system   metrics-server-67bc669cf4-rfqvp   0/1     Pending   0          3m24s
```



## Adding nodes

export KUBECONFIG=cluster1.kubeconfig

- get token from control plane directly

```
TOKEN=$(kubectl exec -it kmc-cluster-1-0 -- k0s token create --role worker)
```

```bash
cat > /tmp/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
options ndots:0
EOF
```

```bash
docker run -d --privileged \
  --network kind \
  -v /tmp/resolv.conf:/etc/resolv.conf \
  -v /var/lib/k0s \
  k0sproject/k0s:v1.34.1-k0s.0 k0s worker "$TOKEN"
```

# After a moment, check the managed cluster

```bash
kubectl get nodes
```

- use join token

JoinTokenRequest

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

```
TOKEN=$(kubectl get secret cluster-1-worker-token -o jsonpath='{.data.token}' | base64 -d)
```

```bash
docker run -d --privileged \
  --network kind \
  -v /tmp/resolv.conf:/etc/resolv.conf \
  -v /var/lib/k0s \
  k0sproject/k0s:v1.34.1-k0s.0 k0s worker "$TOKEN"
```

{{< nav-buttons 
    prev_link="../mgmt-cluster"
    prev_text="Management cluster"
    next_link="../capi"
    next_text="Cluster API"
>}}
