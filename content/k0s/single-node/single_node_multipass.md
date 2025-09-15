In this part, you will create a VM and run k0s on that one.

## Pre-requisites

- [Multipass](https://multipass.run): Multipass is a very handy tool which allows to create Ubuntu virtual machine in a very easy way. It is available on macOS, Windows and Linux.

- [https://kubernetes.io/docs/tasks/tools/#kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl): kubectl is THE binary used to communicate with the API Server of a Kubernetes cluster. It can be used to manage the cluster and the workloads that are running inside of it.

## Create the virtual machine

First run the following command to launch a VM named *node-1*:

```
multipass launch -n node-1
```

Then run a shell on that VM

```
multipass shell node-1
```

Note: you will end up as the *ubuntu* user

## Get the k0s binary

First, from the previous shell, get the latest release of k0s:

```
ubuntu@node-1:~$ curl -sSLf get.k0s.sh | sudo sh
```

After a few tens of seconds the k0s binary will be available in your PATH (in */usr/local/bin*).

Next get the current version of the k0s binary:

```
ubuntu@node-1:~$ k0s version
```

You should get an output similar to the following one (your version could be slightly different though)

```
v1.23.5+k0s.0
```

## Default k0s configuration

When running a k0s cluster, the default configuration options are used but it is also possible to modify that one to better match specific needs.

The defaults configuration options can be retrieved with:

```
k0s config create
```

The output is similar to the following one:

```
apiVersion: k0s.k0sproject.io/v1beta1
kind: ClusterConfig
metadata:
  creationTimestamp: null
  name: k0s
spec:
  api:
    address: 192.168.64.78
    k0sApiPort: 9443
    port: 6443
    sans:
    - 192.168.64.78
    - fd6a:f620:1157:6e48:5054:ff:fe9d:8603
    - fe80::5054:ff:fe9d:8603
    tunneledNetworkingMode: false
  controllerManager: {}
  extensions:
    helm:
      charts: null
      repositories: null
    storage:
      create_default_storage_class: false
      type: external_storage
  images:
    calico:
      cni:
        image: docker.io/calico/cni
        version: v3.21.2
      kubecontrollers:
        image: docker.io/calico/kube-controllers
        version: v3.21.2
      node:
        image: docker.io/calico/node
        version: v3.21.2
    coredns:
      image: k8s.gcr.io/coredns/coredns
      version: v1.7.0
    default_pull_policy: IfNotPresent
    konnectivity:
      image: quay.io/k0sproject/apiserver-network-proxy-agent
      version: 0.0.30-k0s
    kubeproxy:
      image: k8s.gcr.io/kube-proxy
      version: v1.23.5
    kuberouter:
      cni:
        image: docker.io/cloudnativelabs/kube-router
        version: v1.3.2
      cniInstaller:
        image: quay.io/k0sproject/cni-node
        version: 0.1.0
    metricsserver:
      image: k8s.gcr.io/metrics-server/metrics-server
      version: v0.5.2
  installConfig:
    users:
      etcdUser: etcd
      kineUser: kube-apiserver
      konnectivityUser: konnectivity-server
      kubeAPIserverUser: kube-apiserver
      kubeSchedulerUser: kube-scheduler
  konnectivity:
    adminPort: 8133
    agentPort: 8132
  network:
    calico: null
    dualStack: {}
    kubeProxy:
      mode: iptables
    kuberouter:
      autoMTU: true
      mtu: 0
      peerRouterASNs: ""
      peerRouterIPs: ""
    podCIDR: 10.244.0.0/16
    provider: kuberouter
    serviceCIDR: 10.96.0.0/12
  podSecurityPolicy:
    defaultPolicy: 00-k0s-privileged
  scheduler: {}
  storage:
    etcd:
      externalCluster: null
      peerAddress: 192.168.64.78
    type: etcd
  telemetry:
    enabled: true
status: {}
```

:fire: to override some of those properties you can save the output of the previous command in a file, modify that one to match our needs and then use it when running k0s (more on that below)

## Install k0s

Once the k0s binary is installed, we can get a single node k0s cluster:

```
ubuntu@node-1:~$ sudo k0s install controller --single
```

A systemd unit file has been created but the controller is not started yet:

```
ubuntu@node-1:~$ sudo systemctl status k0scontroller
● k0scontroller.service - k0s - Zero Friction Kubernetes
     Loaded: loaded (/etc/systemd/system/k0scontroller.service; enabled; vendor preset: enabled)
     Active: inactive (dead)
       Docs: https://docs.k0sproject.io
```

You should get an output similar to the following one:

:fire: if you need to provide some configuration options different from the default ones, you could provide a configuration file through the *-c* flag in the command above.

## Start the cluster

First, start the cluster:

```
ubuntu@node-1:~$ sudo k0s start
```

Next verify it has been started properly using the *status* subcommand:

```
ubuntu@node-1:~$ sudo k0s status
```

You should should get an output similar the following one:

```
Version: v1.23.5+k0s.0
Process ID: 1843
Role: controller
Workloads: true
SingleNode: true
```

It takes a few tens of seconds for the cluster to be up and running. In the following step you will configure your local *kubectl* binary to communicate with the cluster's  API Server.

You could also now see the k0scontroller is started in systemd:

```
● k0scontroller.service - k0s - Zero Friction Kubernetes
     Loaded: loaded (/etc/systemd/system/k0scontroller.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2022-04-12 15:29:47 CEST; 52s ago
       Docs: https://docs.k0sproject.io
   Main PID: 1843 (k0s)
      Tasks: 101
     Memory: 618.9M
     CGroup: /system.slice/k0scontroller.service
             ├─1843 /usr/local/bin/k0s controller --single=true
             ├─1859 /var/lib/k0s/bin/kine --endpoint=sqlite:///var/lib/k0s/db/state.db?more=rwc&_journal=WAL&cache=shared --l>
             ├─1864 /var/lib/k0s/bin/kube-apiserver --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname --api-au>
             ├─1907 /var/lib/k0s/bin/kube-scheduler --profiling=false --authentication-kubeconfig=/var/lib/k0s/pki/scheduler.>
             ├─1911 /var/lib/k0s/bin/kube-controller-manager --service-account-private-key-file=/var/lib/k0s/pki/sa.key --clu>
             ├─1921 /var/lib/k0s/bin/containerd --root=/var/lib/k0s/containerd --state=/run/k0s/containerd --address=/run/k0s>
             ├─1937 /var/lib/k0s/bin/kubelet --v=1 --node-labels=node.k0sproject.io/role=control-plane --container-runtime=re>
             ├─2059 /var/lib/k0s/bin/containerd-shim-runc-v2 -namespace k8s.io -id 595dc4c6ab62c88cfd5b1fc352298c00c17f516829>
             ├─2061 /var/lib/k0s/bin/containerd-shim-runc-v2 -namespace k8s.io -id d77e1aadb5657b0b9ee919021e441fea307b2c84be>
             ├─2104 /pause
             └─2112 /pause
...
```


## Installation using a cloud config file

In the steps above, you have:
- created a VM with multipass
- downloaded / installed / started k0s inside of it

An alternative method to perform all those steps is to create the following cloud-config file:

```
$ cat<<EOF > cloud-config.yaml
#cloud-config

runcmd:
  - curl -sSLf https://get.k0s.sh | sudo sh
  - sudo k0s install controller --single
  - sudo k0s start
EOF
```

and use it when creating the VM with Multipass:

```
multipass launch -n node-1 --cloud-init cloud-config.yaml
```

## Communication from an external machine

As k0s comes with its own *kubectl* subcommand, you can communicate with the API Server directly from the master node:

```
ubuntu@node-1:~$ sudo k0s kubectl get node
NAME     STATUS   ROLES           AGE    VERSION
node-1   Ready    control-plane   3m4s   v1.23.5+k0s
```

Usually, we do not ssh into a master node to run kubectl commands but use an admin machine instead. In order to do so, you first need to retrieve the kubeconfig file generated during the cluster creation (located in */var/lib/k0s/pki/admin.conf*). Use the multipass' helper for this purpose (the following command must be run from the host machine):

```
multipass exec node-1 -- sudo cat /var/lib/k0s/pki/admin.conf > kubeconfig
```

As this kubeconfig references an API Server on localhost, you need to get the IP address of the node-1 VM and use it in the kubeconfig file:

```
NODE1_IP=$(multipass info node-1 | grep IP | awk '{print $2}')
sed -i '' "s/localhost/$NODE1_IP/" kubeconfig
```

Then configure your local *kubectl* so it uses this kubeconfig:

```
export KUBECONFIG=$PWD/kubeconfig
```

You can now communicate with the newly created cluster from your machine. List the nodes to make sure this is working properly:

```
$ kubectl get nodes
NAME     STATUS   ROLES           AGE     VERSION
node-1   Ready    control-plane   4m57s   v1.23.5+k0s
```

## Testing the whole thing

Let's now run a Deployment based on the ghost image (ghost is an open source blogging platform) and expose it though a NodePort Service.

```
cat<<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ghost
spec:
  selector:
    matchLabels:
      app: ghost
  template:
    metadata:
      labels:
        app: ghost
    spec:
      containers:
      - name: ghost
        image: ghost
        ports:
        - containerPort: 2368
---
apiVersion: v1
kind: Service
metadata:
  name: ghost
spec:
  selector:
    app: ghost
  type: NodePort
  ports:
  - port: 2368
    targetPort: 2368
    nodePort: 30000
EOF
```

Make sure the resources have been created correctly:

```
kubectl get deploy,po,svc
```

You should get an output similar to the following one:

```
kubectl get deploy,po,svc
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/ghost   1/1     1            1           25s

NAME                         READY   STATUS    RESTARTS   AGE
pod/ghost-6bc955dc89-zrmjt   1/1     Running   0          25s

NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
service/kubernetes   ClusterIP   10.96.0.1      <none>        443/TCP          6m14s
service/ghost        NodePort    10.105.70.69   <none>        2368:30000/TCP   25s
```

Using node-1's IP address (192.168.64.48 in this exemple) and the NodePort 3000, we can access the ghost web interface:

![ghost interface](./images/ghost.png)

## Cleanup

Remove the ghost Deployment and Service:

```
kubectl delete deploy/ghost svc/ghost
```

In order to remove k0s from the VM (without deleting the VM) you first need to stop k0s:

```
ubuntu@node-1:~$ sudo k0s stop
```

and then *reset* it:

```
ubuntu@node-1:~$ sudo k0s reset
```

You can use the following command from test host machine if you need to remove the whole VM:

```
multipass delete -p node-1
```