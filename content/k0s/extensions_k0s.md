Extensions allows to specify Helm charts or yaml manifests to be deployed during the creation or update of a cluster.
We will illustrate the extensions capability on a single node cluster created with the k0s binary. 

## Pre-requisites

- [Multipass](https://multipass.run)

## Creation of a VM

First create a single VM, named k0s-1, using Multipass:

```
multipass launch -n k0s-1
```

## Extensions with Helm Charts in k0s configuration

Run a shell into the newly created VM:

```
$ kubectl shell k0s-1
```

Next download k0s:

```
ubuntu@k0s-1:~$ curl -sSLf get.k0s.sh | sudo sh
```

In the [single node tutorial](./single_node_multipass.md) we talked about the default k0s configuration file which can be retrieved with the following command:

```
ubuntu@k0s-1:~$ k0s default-config > k0s.yaml
```

This file contains the default properties of all the cluster's components, among them:
- the API Server
- the ETCD key value store
- the network plugins
- ... 

The following shows all the available properties

```
$ cat k0s.yaml
apiVersion: k0s.k0sproject.io/v1beta1
kind: Cluster
metadata:
  name: k0s
spec:
  api:
    address: 192.168.64.113
    port: 6443
    k0sApiPort: 9443
    sans:
    - 192.168.64.113
  storage:
    type: etcd
    etcd:
      peerAddress: 192.168.64.113
  network:
    podCIDR: 10.244.0.0/16
    serviceCIDR: 10.96.0.0/12
    provider: kuberouter
    calico: null
    kuberouter:
      mtu: 0
      peerRouterIPs: ""
      peerRouterASNs: ""
      autoMTU: true
    kubeProxy:
      disabled: false
      mode: iptables
  podSecurityPolicy:
    defaultPolicy: 00-k0s-privileged
  telemetry:
    enabled: true
  installConfig:
    users:
      etcdUser: etcd
      kineUser: kube-apiserver
      konnectivityUser: konnectivity-server
      kubeAPIserverUser: kube-apiserver
      kubeSchedulerUser: kube-scheduler
  images:
    konnectivity:
      image: us.gcr.io/k8s-artifacts-prod/kas-network-proxy/proxy-agent
      version: v0.0.21
    metricsserver:
      image: gcr.io/k8s-staging-metrics-server/metrics-server
      version: v0.3.7
    kubeproxy:
      image: k8s.gcr.io/kube-proxy
      version: v1.21.2
    coredns:
      image: docker.io/coredns/coredns
      version: 1.7.0
    calico:
      cni:
        image: docker.io/calico/cni
        version: v3.18.1
      node:
        image: docker.io/calico/node
        version: v3.18.1
      kubecontrollers:
        image: docker.io/calico/kube-controllers
        version: v3.18.1
    kuberouter:
      cni:
        image: docker.io/cloudnativelabs/kube-router
        version: v1.2.1
      cniInstaller:
        image: quay.io/k0sproject/cni-node
        version: 0.1.0
    default_pull_policy: IfNotPresent
  konnectivity:
    agentPort: 8132
    adminPort: 8133
```

Under the *.spec* property, add the following *extensions* property and its helm sub property:

```
extensions:
  helm:
    repositories:
    - name: traefik
      url: https://helm.traefik.io/traefik
    charts:
    - name: traefik
      chartname: traefik/traefik
      version: "9.11.0"
      namespace: default
```

This indicates to k0s that the Helm Chart for Traefik Ingress Controller needs to be installed during the bootstrap of the cluster.

Next, install the cluster providing this configuration file:

```
ubuntu@k0s-1:~$ sudo k0s install controller --config ./k0s.yaml --single
```

and start it:

```
ubuntu@k0s-1:~$ sudo k0s start
```

Finally, make sure Traefik has been deployed to the cluster:

```
ubuntu@k0s-1:~$ sudo k0s kubectl get po -A
```

You should get a result similar to the following one:

```
NAMESPACE     NAME                                  READY   STATUS    RESTARTS   AGE
default       traefik-1625417854-7f8d8d8987-p4z96   1/1     Running   0          2m58s
kube-system   coredns-5ccbdcc4c4-kb24b              1/1     Running   0          2m58s
kube-system   kube-proxy-t8jn9                      1/1     Running   0          2m44s
kube-system   kube-router-vmhv7                     1/1     Running   0          2m44s
kube-system   metrics-server-59d8698d9-259xl        1/1     Running   0          2m58s
```

In order to verify Traefik has been installed via Helm, first install the helm client using the following command:

```
ubuntu@k0s-1:~$ curl -o helm.tar.gz https://get.helm.sh/helm-v3.6.2-linux-amd64.tar.gz && \
                tar -xvf helm.tar.gz && \
                sudo mv linux-amd64/helm /usr/local/bin
```

Then run a root shell (that will make things easier in this example) and configure the helm client so it uses the kubeconfig file of the cluster:

```
ubuntu@k0s-1:~$ sudo su -
root@k0s-1:~$ export KUBECONFIG=/var/lib/k0s/pki/admin.conf
```

Finally, make sure Traefik Helm chart is listed:

```
root@k0s-1:~$ helm list
```

You should get an output similar to the following one:

```
NAME                    NAMESPACE       REVISION        UPDATED                                         STATUS          CHART           APP VERSION
traefik-1625417854      default         1               2021-07-04 18:57:37.035554595 +0200 CEST        deployed        traefik-9.11.0  2.3.3 
```

As you can see, using the *extensions* property makes it very easy to deploy additional application through Helm Chart.

## Extensions with yaml manifests

K0s also allows to deploy additional resources automatically by adding yaml manifests into the */var/lib/k0s/manifests/* folder.

To illustrate this, first create a *mongo* folder in */var/lib/k0s/manifests/* and create the following Deployment (based on the mongodb image) in the file mongo.yaml inside that new folder:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: db
    spec:
      containers:
      - image: mongo:4.4
        name: mongo
```

After a few tens of seconds, make sure the Deployment has been correctly created:

```
ubuntu@k0s-1:~$ sudo k0s kubectl get deploy,po -l app=db
```

## Cleanup

You can use the following command to remove the VM:

```
$ multipass delete -p k0s-1
```