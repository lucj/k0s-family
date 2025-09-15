In this exercise you will create a multi node k0s cluster using k0sctl. You can install k0sctl on the admin VM and create a 2 node cluster using node1 and node2.

All the following commands need to be run from the admin VM only.

## SSH key pair

First create a new ssh key pair:

```
ssh-keygen -t rsa -q -N ""
```

This creates 2 files in */home/ubuntu/.ssh*:

- id_rsa: the private key
- id_rsa.pub: the associated public key

Append the public key (*id_rsa.pub*) in *~/.ssh/authorized_keys* on *node1* and *node2*.

In order to do so:
- copy the content of *id_rsa.pub* in your clipboard
- get a terminal on node1, selecting the VM's name in the dropdown list.
- run the following command in that terminal
```
cat > ~/.ssh/authorized_keys
```
- paste the content of the *id_rsa.pub* file and press ENTER
- press CTRL-D
- repeat all the steps on node2

In a later step, k0sctl will use the private key to connect to node1 and node2 from the admin VM.

## k0sctl

Still from the *admin* VM, download the latest version of k0sctl binary:

```
curl -sSL -O https://github.com/k0sproject/k0sctl/releases/download/v0.11.4/k0sctl-linux-x64
```

Then make it executable and move it into */usr/local/bin*:

```
chmod +x k0sctl-linux-x64
sudo mv k0sctl-linux-x64 /usr/local/bin/k0sctl
```

Check all the available commands provided by k0sctl:

```
k0sctl
```

You can use several of those commands in the following steps.

## Cluster configuration

Let's now define the configuration of the Kubernetes cluster you will setup.

First, create a sample cluster configuration file:

```
k0sctl init > k0sctl.yaml
```

This generates a *k0sctl.yaml* file with the following content :

```
apiVersion: k0sctl.k0sproject.io/v1beta1
kind: Cluster
metadata:
  name: k0s-cluster
spec:
  hosts:
  - ssh:
      address: 10.0.0.1
      user: root
      port: 22
      keyPath: /home/ubuntu/.ssh/id_rsa
    role: controller
  - ssh:
      address: 10.0.0.2
      user: root
      port: 22
      keyPath: /home/ubuntu/.ssh/id_rsa
    role: worker
  k0s:
    version: 1.22.3+k0s.0
```

This file defines:
- the cluster's configuration such as the number of nodes, the role of each nodes, ...
- the configuration k0s such as the Kubernetes version, the specification of the control plane components, the CNI plugin used, ... 

Note: by default only the k0s's version property is provided alongside the cluster default properties. K0s' full default configuration can be retrieved using the additional *-k0s* flag in the init command. 

For informational purposes, you can check the whole list of options using the following command:

```
k0sctl init -k0s
```

Next modify the *k0sctl.yaml* file generated previously so it defines:
- node1 as a controller node
- node2 as a worker node
  
Note: you can get the private IPs from node1 and node2 from Strigo's interface selecting the name of the VM and the info icon

![machine info](./images/info-1.png)

![machine info](./images/info-2.png)


The new version of *k0sctl.yaml* should look like the following (the IP addresses you will get for node1 and node2 might be different though):

```
apiVersion: k0sctl.k0sproject.io/v1beta1
kind: Cluster
metadata:
  name: k0s-cluster
spec:
  hosts:
  - ssh:
      address: 172.31.36.224
      user: ubuntu
      port: 22
      keyPath: /home/ubuntu/.ssh/id_rsa
    role: controller
  - ssh:
      address: 172.31.45.113
      user: ubuntu
      port: 22
      keyPath: /home/ubuntu/.ssh/id_rsa
    role: worker
  k0s:
    version: 1.22.3+k0s.0
```

🔥 k0sctl provides handy options to the init subcommand. The above configuration file can also be generated with the following one-liner:

```
k0sctl init -C 1 ubuntu@172.31.36.224 ubuntu@172.31.45.113
```

## Lauching the cluster

Once the cluster configuration file is ready, create a cluster using k0sctl:

```
k0sctl apply
```

Note: by default k0sctl uses the *k0sctl.yaml* configuration file

Below is an example of the whole output for your reference. In this one you can see the main phases the creation process goes through.

```

⠀⣿⣿⡇⠀⠀⢀⣴⣾⣿⠟⠁⢸⣿⣿⣿⣿⣿⣿⣿⡿⠛⠁⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀█████████ █████████ ███
⠀⣿⣿⡇⣠⣶⣿⡿⠋⠀⠀⠀⢸⣿⡇⠀⠀⠀⣠⠀⠀⢀⣠⡆⢸⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀███          ███    ███
⠀⣿⣿⣿⣿⣟⠋⠀⠀⠀⠀⠀⢸⣿⡇⠀⢰⣾⣿⠀⠀⣿⣿⡇⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀███          ███    ███
⠀⣿⣿⡏⠻⣿⣷⣤⡀⠀⠀⠀⠸⠛⠁⠀⠸⠋⠁⠀⠀⣿⣿⡇⠈⠉⠉⠉⠉⠉⠉⠉⠉⢹⣿⣿⠀███          ███    ███
⠀⣿⣿⡇⠀⠀⠙⢿⣿⣦⣀⠀⠀⠀⣠⣶⣶⣶⣶⣶⣶⣿⣿⡇⢰⣶⣶⣶⣶⣶⣶⣶⣶⣾⣿⣿⠀█████████    ███    ██████████

k0sctl v0.11.4 Copyright 2021, k0sctl authors.
Anonymized telemetry of usage will be sent to the authors.
By continuing to use k0sctl you agree to these terms:
https://k0sproject.io/licenses/eula
INFO ==> Running phase: Connect to hosts
INFO [ssh] 192.168.64.12:22: connected
INFO [ssh] 192.168.64.11:22: connected
INFO ==> Running phase: Detect host operating systems
INFO [ssh] 192.168.64.11:22: is running Ubuntu 20.04.3 LTS
INFO [ssh] 192.168.64.12:22: is running Ubuntu 20.04.3 LTS
INFO ==> Running phase: Prepare hosts
INFO ==> Running phase: Gather host facts
INFO [ssh] 192.168.64.12:22: using node2 as hostname
INFO [ssh] 192.168.64.11:22: using node1 as hostname
INFO [ssh] 192.168.64.12:22: discovered enp0s2 as private interface
INFO [ssh] 192.168.64.11:22: discovered enp0s2 as private interface
INFO ==> Running phase: Validate hosts
INFO ==> Running phase: Gather k0s facts
INFO ==> Running phase: Validate facts
INFO ==> Running phase: Download k0s on hosts
INFO [ssh] 192.168.64.11:22: downloading k0s 1.22.3+k0s.0
INFO [ssh] 192.168.64.12:22: downloading k0s 1.22.3+k0s.0
INFO ==> Running phase: Configure k0s
WARN [ssh] 192.168.64.11:22: generating default configuration
INFO [ssh] 192.168.64.11:22: validating configuration
INFO [ssh] 192.168.64.11:22: configuration was changed
INFO ==> Running phase: Initialize the k0s cluster
INFO [ssh] 192.168.64.11:22: installing k0s controller
INFO [ssh] 192.168.64.11:22: waiting for the k0s service to start
INFO [ssh] 192.168.64.11:22: waiting for kubernetes api to respond
INFO ==> Running phase: Install workers
INFO [ssh] 192.168.64.12:22: validating api connection to https://192.168.64.11:6443
INFO [ssh] 192.168.64.11:22: generating token
INFO [ssh] 192.168.64.12:22: writing join token
INFO [ssh] 192.168.64.12:22: installing k0s worker
INFO [ssh] 192.168.64.12:22: starting service
INFO [ssh] 192.168.64.12:22: waiting for node to become ready
INFO ==> Running phase: Disconnect from hosts
INFO ==> Finished in 1m49s
INFO k0s cluster version 1.22.3+k0s.0 is now installed
INFO Tip: To access the cluster you can now fetch the admin kubeconfig using:
INFO      k0sctl kubeconfig
```

It only takes a couple of minutes for the cluster to be up and running.

## Accessing the cluster

You will use the well known *kubectl* binary to interact with your newly created k0s cluster.

First install *kubectl* on the admin VM

```
VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)

curl -LO https://storage.googleapis.com/kubernetes-release/release/$VERSION/bin/linux/amd64/kubectl

chmod +x ./kubectl

sudo mv ./kubectl /usr/local/bin/kubectl
```

Next, retrieve the new cluster's kubeconfig file using a k0sctl subcommand:

```
k0sctl kubeconfig > kubeconfig 
```

Then configure your local kubectl:

```
export KUBECONFIG=$PWD/kubeconfig
```

You can now use kubectl from the admin VM to communicate with the API server running on the new cluster:

```
kubectl get nodes
```

You should get an output similar to the following one.

```
NAME               STATUS   ROLES    AGE     VERSION
ip-172-31-45-113   Ready    <none>   2m28s   v1.22.3+k0s
```

Only the worker is listed as the controller node is isolated for better security and stability of the cluster.

You can know use your cluster and deploy whatever you want inside of it.

## Cleanup

The following command removes all the k0s related components

```
k0sctl reset -f
```

## Summary

k0sctl is a very useful k0s companion tool which allows you to create and manage k0s clusters in a very simple way. In this lab we've only seen how to setup a cluster using k0sctl but we could use this tool for many other purposes:
- upgrade an existing cluster to a new version of k0s
- backup & restore the cluster
- install Helm charts on startup
- ...

These topics will be detailed in future labs
