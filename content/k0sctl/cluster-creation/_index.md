---
title: Cluster creation
weight: 1
---

In this part, you will create several Multipass VMs, and create a `k0s`cluster on these using `k0sctl`.

## Create the virtual machines

First, you will create a new pair of ssh key, they will be used by k0sctl in a later step to connect to the VM. 
Use the following command to create this ssh key pair:

```bash
ssh-keygen -t rsa -q -N "" -f /tmp/k0s
```

This basically creates 2 files:
- k0s: private key
- k0s.pub: associated public key

Next, create a *cloud.init* file containing the public key:

```
cat<<EOF > cloud.init
ssh_authorized_keys:
  - $(cat /tmp/k0s.pub)
EOF
```

In the next step you will use this file to copy the public key into each VM, this will allow SSH passwordless connection.

As we have done in a previous section, we will use [Multipass](https://multipass.run) to create some local VMs. Use the following command to launch the VMs named `k0s-1` to `k0s-3`.

```bash
for i in $(seq 1 3); do 
  multipass launch -n k0s-$i --cloud-init cloud.init --disk 10G --cpus 2 --memory 2G
done
```

Make sure those VMs and make sure they are running fine:

```bash
multipass list
```

You should get an output similar to the following one (the IP addresses you will get would be different though).

```bash
Name                    State             IPv4             Image
k0s-1                   Running           192.168.64.35    Ubuntu 24.04 LTS
k0s-2                   Running           192.168.64.36    Ubuntu 24.04 LTS
k0s-3                   Running           192.168.64.37    Ubuntu 24.04 LTS
```

You will use the IP address of these VMs in a next step.

## Cluster configuration

First, create a sample cluster configuration file, this can be done with the following command:

```bash
k0sctl init --k0s > cluster.yaml
```

{{< callout type="info" >}}
The `--k0s` property add the detailed k0s configuration in this file
{{< /callout >}}


This generates a `cluster.yaml` file with the following content:
- list of hosts
- k0s configuration
- cluster configuration

<br>

<details>
  <summary markdown="span">Default cluster.yaml</summary>

```yaml {filename="cluster.yaml"}
apiVersion: k0sctl.k0sproject.io/v1beta1
kind: Cluster
metadata:
  name: k0s-cluster
  user: admin
spec:
  hosts:
  - ssh:
      address: 10.0.0.1
      user: root
      port: 22
      keyPath: null
    role: controller
  - ssh:
      address: 10.0.0.2
      user: root
      port: 22
      keyPath: null
    role: worker
  k0s:
    config:
      apiVersion: k0s.k0sproject.io/v1beta1
      kind: Cluster
      metadata:
        name: k0s
      spec:
        api:
          k0sApiPort: 9443
          port: 6443
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
          kubeProxy:
            disabled: false
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
        storage:
          type: etcd
        telemetry:
          enabled: true
  options:
    wait:
      enabled: true
    drain:
      enabled: true
      gracePeriod: 2m0s
      timeout: 5m0s
      force: true
      ignoreDaemonSets: true
      deleteEmptyDirData: true
      podSelector: ""
      skipWaitForDeleteTimeout: 0s
    concurrency:
      limit: 30
      workerDisruptionPercent: 10
      uploads: 5
    evictTaint:
      enabled: false
      taint: k0sctl.k0sproject.io/evict=true
      effect: NoExecute
      controllerWorkers: false
```
</details>

Next, modify that file, so it uses the VMs created previously. You will define:
- `k0s-1` as a control-plane Node
- `k0s-2` and `k0s-3` as worker Nodes

Also add the k0s version, we'll use v1.33.1+k0s.0 in this example.

The new version of the configuration file should look as follows (the IP addresses of your VMs might be different)

<br>

<details>
  <summary markdown="span">Modified cluster.yaml</summary>

```yaml {filename="cluster.yaml"}
apiVersion: k0sctl.k0sproject.io/v1beta1
kind: Cluster
metadata:
  name: k0s-cluster
  user: admin
spec:
  hosts:                         # <- This block should list the VMs you created
  - ssh:
      address: 192.168.64.35
      user: ubuntu
      port: 22
      keyPath: /tmp/k0s
    role: controller
  - ssh:
      address: 192.168.64.36
      user: ubuntu
      port: 22
      keyPath: /tmp/k0s
    role: worker
  - ssh:
      address: 192.168.64.37
      user: ubuntu
      port: 22
      keyPath: /tmp/k0s
    role: worker
  k0s:
    version: v1.33.1+k0s.0       # <- Add this property to specify the Kubernetes version to install
    config:
      apiVersion: k0s.k0sproject.io/v1beta1
      kind: Cluster
      metadata:
        name: k0s
      spec:
        api:
          k0sApiPort: 9443
          port: 6443
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
          kubeProxy:
            disabled: false
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
        storage:
          type: etcd
        telemetry:
          enabled: true
  options:
    wait:
      enabled: true
    drain:
      enabled: true
      gracePeriod: 2m0s
      timeout: 5m0s
      force: true
      ignoreDaemonSets: true
      deleteEmptyDirData: true
      podSelector: ""
      skipWaitForDeleteTimeout: 0s
    concurrency:
      limit: 30
      workerDisruptionPercent: 10
      uploads: 5
    evictTaint:
      enabled: false
      taint: k0sctl.k0sproject.io/evict=true
      effect: NoExecute
      controllerWorkers: false
```
</details>

{{< callout type="info" >}}
The above configuration file could also be generated with the following one-liner.

```bash
k0sctl init --k0s -i /tmp/k0s ubuntu@192.168.64.35  ubuntu@192.168.64.36 ubuntu@192.168.64.37 
```
{{< /callout >}}

## Launching the cluster

Create the cluster using `k0sctl`.

```bash
k0sctl apply --config cluster.yaml
```

You can see, below, the steps the creation process goes through. It only takes a couple of minutes for the cluster to be up and running.

<br>

<details>
  <summary markdown="span">Cluster creation steps</summary>

```bash
⠀⣿⣿⡇⠀⠀⢀⣴⣾⣿⠟⠁⢸⣿⣿⣿⣿⣿⣿⣿⡿⠛⠁⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀█████████ █████████ ███
⠀⣿⣿⡇⣠⣶⣿⡿⠋⠀⠀⠀⢸⣿⡇⠀⠀⠀⣠⠀⠀⢀⣠⡆⢸⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀███          ███    ███
⠀⣿⣿⣿⣿⣟⠋⠀⠀⠀⠀⠀⢸⣿⡇⠀⢰⣾⣿⠀⠀⣿⣿⡇⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀███          ███    ███
⠀⣿⣿⡏⠻⣿⣷⣤⡀⠀⠀⠀⠸⠛⠁⠀⠸⠋⠁⠀⠀⣿⣿⡇⠈⠉⠉⠉⠉⠉⠉⠉⠉⢹⣿⣿⠀███          ███    ███
⠀⣿⣿⡇⠀⠀⠙⢿⣿⣦⣀⠀⠀⠀⣠⣶⣶⣶⣶⣶⣶⣿⣿⡇⢰⣶⣶⣶⣶⣶⣶⣶⣶⣾⣿⣿⠀█████████    ███    ██████████
k0sctl v0.25.1 Copyright 2025, k0sctl authors.
INFO apiVersion: k0sctl.k0sproject.io/v1beta1
kind: Cluster
metadata:
  name: k0s-cluster
  user: admin
spec:
  hosts:
  - ssh:
      address: 192.168.64.35
      user: ubuntu
      port: 22
      keyPath: /tmp/k0s
    role: controller
  - ssh:
      address: 192.168.64.36
      user: ubuntu
      port: 22
      keyPath: /tmp/k0s
    role: worker
  - ssh:
      address: 192.168.64.37
      user: ubuntu
      port: 22
      keyPath: /tmp/k0s
    role: worker
  k0s:
    version: v1.33.1+k0s.0
    config:
      apiVersion: k0s.k0sproject.io/v1beta1
      kind: Cluster
      metadata:
        name: k0s
      spec:
        api:
          k0sApiPort: 9443
          port: 6443
        extensions:
          helm:
            charts:
            - chartname: traefik/traefik
              name: traefik
              namespace: traefik
              version: 37.1.1
            repositories:
            - name: traefik
              url: https://traefik.github.io/charts
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
          kubeProxy:
            disabled: false
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
        storage:
          type: etcd
        telemetry:
          enabled: true
  options:
    wait:
      enabled: true
    drain:
      enabled: true
      gracePeriod: 2m0s
      timeout: 5m0s
      force: true
      ignoreDaemonSets: true
      deleteEmptyDirData: true
      podSelector: ""
      skipWaitForDeleteTimeout: 0s
    concurrency:
      limit: 30
      workerDisruptionPercent: 10
      uploads: 5
    evictTaint:
      enabled: false
      taint: k0sctl.k0sproject.io/evict=true
      effect: NoExecute
      controllerWorkers: false 
INFO ==> Running phase: Connect to hosts 
INFO [ssh] 192.168.64.35:22: connected            
INFO [ssh] 192.168.64.37:22: connected            
INFO [ssh] 192.168.64.36:22: connected            
INFO ==> Running phase: Detect host operating systems 
INFO [ssh] 192.168.64.37:22: is running Ubuntu 24.04.3 LTS 
INFO [ssh] 192.168.64.35:22: is running Ubuntu 24.04.3 LTS 
INFO [ssh] 192.168.64.36:22: is running Ubuntu 24.04.3 LTS 
INFO ==> Running phase: Acquire exclusive host lock 
INFO ==> Running phase: Prepare hosts    
INFO ==> Running phase: Gather host facts 
INFO [ssh] 192.168.64.37:22: using k0s-3 as hostname 
INFO [ssh] 192.168.64.36:22: using k0s-2 as hostname 
INFO [ssh] 192.168.64.35:22: using k0s-1 as hostname 
INFO [ssh] 192.168.64.37:22: discovered enp0s1 as private interface 
INFO [ssh] 192.168.64.36:22: discovered enp0s1 as private interface 
INFO [ssh] 192.168.64.35:22: discovered enp0s1 as private interface 
INFO ==> Running phase: Validate hosts   
WARN failed to walk k0s.tmp.* files in /usr/local/bin/k0s: stat /usr/local/bin/k0s.tmp.*: file does not exist 
WARN failed to walk k0s.tmp.* files in /usr/local/bin/k0s: stat /usr/local/bin/k0s.tmp.*: file does not exist 
WARN failed to walk k0s.tmp.* files in /usr/local/bin/k0s: stat /usr/local/bin/k0s.tmp.*: file does not exist 
INFO validating clock skew                        
INFO ==> Running phase: Validate facts   
INFO ==> Running phase: Download k0s on hosts 
INFO [ssh] 192.168.64.37:22: downloading k0s v1.33.1+k0s.0 
INFO [ssh] 192.168.64.36:22: downloading k0s v1.33.1+k0s.0 
INFO [ssh] 192.168.64.35:22: downloading k0s v1.33.1+k0s.0 
INFO ==> Running phase: Install k0s binaries on hosts 
INFO [ssh] 192.168.64.35:22: validating configuration 
INFO ==> Running phase: Configure k0s    
INFO [ssh] 192.168.64.35:22: installing new configuration 
INFO ==> Running phase: Initialize the k0s cluster 
INFO [ssh] 192.168.64.35:22: installing k0s controller 
INFO [ssh] 192.168.64.35:22: waiting for the k0s service to start 
INFO [ssh] 192.168.64.35:22: wait for kubernetes to reach ready state 
INFO ==> Running phase: Install workers  
INFO [ssh] 192.168.64.35:22: generating a join token for worker 1 
INFO [ssh] 192.168.64.35:22: generating a join token for worker 2 
INFO [ssh] 192.168.64.37:22: validating api connection to https://192.168.64.35:6443 using join token 
INFO [ssh] 192.168.64.36:22: validating api connection to https://192.168.64.35:6443 using join token 
INFO [ssh] 192.168.64.37:22: writing join token to /etc/k0s/k0stoken 
INFO [ssh] 192.168.64.36:22: writing join token to /etc/k0s/k0stoken 
INFO [ssh] 192.168.64.37:22: installing k0s worker 
INFO [ssh] 192.168.64.36:22: installing k0s worker 
INFO [ssh] 192.168.64.37:22: starting service     
INFO [ssh] 192.168.64.36:22: starting service     
INFO [ssh] 192.168.64.37:22: waiting for node to become ready 
INFO [ssh] 192.168.64.36:22: waiting for node to become ready 
INFO ==> Running phase: Release exclusive host lock 
INFO ==> Running phase: Disconnect from hosts 
INFO ==> Finished in 50s                 
INFO k0s cluster version v1.33.1+k0s.0 is now installed 
INFO Tip: To access the cluster you can now fetch the admin kubeconfig using: 
INFO      k0sctl kubeconfig 
```

</details>

Next, use the `k0sctl kubeconfig` command to retrieve the cluster's kubeconfig file.

```bash
k0sctl kubeconfig -c cluster.yaml > kubeconfig
```

Next, configure your local `kubectl`.

```bash
export KUBECONFIG=$PWD/kubeconfig
```

Then, make sure the cluster is reachable listing the Nodes.

```bash
kubectl get nodes
```

You should get an output similar to the following one.

```bash
NAME    STATUS   ROLES    AGE   VERSION
k0s-2   Ready    <none>   88s   v1.33.1+k0s
k0s-3   Ready    <none>   88s   v1.33.1+k0s
```

{{< callout type="info" >}}
As we've seen in the previous section, only the workers are listed as the controller Node is isolated for a better security and stability of the cluster.
{{< /callout >}}

{{< nav-buttons 
    next_link="../extensions"
    next_text="Extensions"
>}}