In this exercise you will create a single node k0s cluster

Note: unless otherwise specified, all the commands should be run from node1.

## k0s binary

First get the latest release of k0s:

```
curl -sSLf get.k0s.sh | sudo sh
```

After a few tens of seconds the k0s binary will be available in your PATH (in /usr/local/bin).

Next get the current version of the k0s binary:

```
k0s version
```

You should get an output similar to the following one (your version could be slightly different though)

```
v1.22.2+k0s.1
```

## Default configuration

When running a k0s cluster, the default configuration option can be used, but it is also possible to modify that one to better match specific needs.

This command shows the default configuration:

```
k0s default-config
```

You should get a result similar to the following one:

```
apiVersion: k0s.k0sproject.io/v1beta1
kind: Cluster
metadata:
  name: k0s
spec:
  api:
    address: 192.168.64.15
    port: 6443
    k0sApiPort: 9443
    sans:
    - 192.168.64.15
  storage:
    type: etcd
    etcd:
      peerAddress: 192.168.64.15
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
      version: v0.0.24
    metricsserver:
      image: gcr.io/k8s-staging-metrics-server/metrics-server
      version: v0.5.0
    kubeproxy:
      image: k8s.gcr.io/kube-proxy
      version: v1.22.2
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

🔥 to override some of those properties you can save the output of the previous command in a file, modify that one to match your needs and use it when running k0s (more on that below)

## Install k0s

Run the following command to create a single node k0s cluster:

```
sudo k0s install controller --single
```

You should get an output similar to the following one:

```
INFO[2021-11-11 16:08:12] no config file given, using defaults
INFO[2021-11-11 16:08:12] creating user: etcd
INFO[2021-11-11 16:08:12] creating user: kube-apiserver
INFO[2021-11-11 16:08:12] creating user: konnectivity-server
INFO[2021-11-11 16:08:12] creating user: kube-scheduler
INFO[2021-11-11 16:08:12] Installing k0s service
```

🔥 if you need to provide some configuration options different from the default ones, you can provide a configuration file through the -c flag in the command above.

As you can see from this output, a k0s systemd service is created (but has not started yet)

## Start the cluster

First, start the cluster with the following command:

```
sudo k0s start
```

Next verify that it has been started properly using the status subcommand:

```
sudo k0s status
```

You should get an output similar to the following one:

```
Version: v1.22.2+k0s.1
Process ID: 1856
Role: controller
Workloads: true
```

It takes a few tens of seconds for the cluster to be up and running.

Since k0s comes with its own kubectl subcommand, you can directly list the status of our single node using the following command:

```
sudo k0s kubectl get node
```

After a few tens of seconds, you should get an output similar to the following one (the name of your node will be different though):

```
NAME               STATUS     ROLES    AGE   VERSION
ip-172-31-36-224   Ready      <none>   8s    v1.22.2+k0s
```

## Communication from an external machine

Usually, we do not ssh into a controller node to manage the cluster but use an external machine instead. In this part, you will setup the admin machine to communicate with the cluster.

- From the node1 VM

First retrieve the kubeconfig file generated during the cluster creation, this one is in /var/lib/k0s/pki/admin.conf.

```
sudo cat /var/lib/k0s/pki/admin.conf > ./kubeconfig
```

As this kubeconfig references an API Server on localhost, you need to replace that value with the IP address of the VM. 

From the Machine Info menu, you can get all the information needed to access the node1 machine from the outside, such as the external DNS name and its public and private IPs:

![machine info](./images/info-1.png)

![machine info](./images/info-2.png)


Save the private IP (172.31.17.54 here but yours would be different) in the NODE_IP environment variable and replace localhost with this one:

```
NODE_IP=172.31.17.54 
sed -i "s/localhost/$NODE_IP/" ./kubeconfig
```

- From the admin machine

Note: to run command in a terminal on the admin VM, select *admin* in the list within the dropdown at the top of the screen 

First, create a folder .kube in the $HOME directory

```
mkdir $HOME/.kube
```

Next copy the content of the previous kubeconfig file in $HOME/.kube/config (you can use the Editor for that purpose)

Next Install the kubectl binary with the following commands:

```
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x ./kubectl

sudo mv ./kubectl /usr/local/bin/kubectl
```

The local kubectl can now communicate with the newly created cluster as by default kubectl reads the configuration from $HOME/.kube/config.

List the nodes to make sure this is working properly:

```
$ kubectl get nodes
NAME               STATUS   ROLES    AGE     VERSION
ip-172-31-36-224   Ready    <none>   5m19s   v1.22.2+k0s
```

## Running a sample workload

Let's now run a Deployment based on the ghost image (ghost is an open source blogging platform) and expose it through a NodePort Service.

🔥 Run all the commands from the admin virtual machine

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

To make sure the resources have been created correctly:

```
kubectl get deploy,po,svc
```

You should get an output similar to the following one (some identifiers might be different though)

```
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/ghost   1/1     1            1           5m3s

NAME                         READY   STATUS    RESTARTS   AGE
pod/ghost-548879c755-dzqtq   1/1     Running   0          5m3s

NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP          23m
service/ghost        NodePort    10.102.65.221   <none>        2368:30000/TCP   5m3s
```

Using the public IP address IP of the node1 VM (3.127.37.169) or the public DNS (ec2-3-127-37-169.eu-central-1.compute.amazonaws.com) and the NodePort 30000, you can access the ghost web interface:

![Ghost web interface](./images/ghost.png)

## Cleanup 

Remove the Ghost Deployment and Service with the following command:

```
$ kubectl delete deploy/ghost svc/ghost
deployment.apps "ghost" deleted
service "ghost" deleted
```

Remove k0s from node1 VM:

```
sudo k0s stop
```

Then to use the reset command:

```
sudo k0s reset
```

You will get an output similar to the following one, indicating that all the k0s related components have been removed:

```
INFO[2021-11-11 16:19:02] * containers steps
INFO[2021-11-11 16:19:09] successfully removed k0s containers!
INFO[2021-11-11 16:19:09] no config file given, using defaults
INFO[2021-11-11 16:19:09] * remove k0s users step:
INFO[2021-11-11 16:19:09] no config file given, using defaults
INFO[2021-11-11 16:19:09] * uninstall service step
INFO[2021-11-11 16:19:09] Uninstalling the k0s service
INFO[2021-11-11 16:19:10] * remove directories step
INFO[2021-11-11 16:19:16] * CNI leftovers cleanup step
INFO[2021-11-11 16:19:16] * kube-bridge leftovers cleanup step
INFO k0s cleanup operations done. To ensure a full reset, a node reboot is recommended.
```
