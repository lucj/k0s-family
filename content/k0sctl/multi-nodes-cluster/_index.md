In this part, you will create several virtual machines locally and run a multi node k0s on those ones. 
You will use *k0sctl*, the k0s' companion tool.

## Pre-requisites

[Multipass](https://multipass.run): Multipass is a very handy tool which allows to create Ubuntu virtual machine in a very easy way. It is available on macOS, Windows and Linux.

[kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) the command line tool to communicate with a Kubernetes cluster

## Create the virtual machines

First, you will create a new pair of ssh key, they will be used by k0sctl in a later step to connect to the VM. 
Use the following command to create this ssh key pair:

```
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

In the next step you will use this file to copy the public key into each VM, this will allow a ssh passwordless connection.

As we have done in a previous tutorial, we will use [Multipass](https://multipass.run) to create some local VMs. Use the following command to launch the VMs named *node-1* to *node-6*:

```
for i in $(seq 1 6); do 
  multipass launch -n node-$i --cloud-init cloud.init
done
```

Make sure those VMs and make sure they are running fine:

```
multipass list
```

You should get an output similar to the following one:

```
Name                    State             IPv4             Image
node-1                  Running           10.30.167.247    Ubuntu 20.04 LTS
node-2                  Running           10.30.167.119    Ubuntu 20.04 LTS
node-3                  Running           10.30.167.215    Ubuntu 20.04 LTS
node-4                  Running           10.30.167.140    Ubuntu 20.04 LTS
node-5                  Running           10.30.167.147    Ubuntu 20.04 LTS
node-6                  Running           10.30.167.224    Ubuntu 20.04 LTS
```

You will use the IP address of those machine in a next step.

## k0sctl

Before launching a new cluster, you need to get the *k0sctl* binary (which can be downloaded from [https://github.com/k0sproject/k0sctl/releases](https://github.com/k0sproject/k0sctl/releases)) and move it in your PATH.

For example, to get k0sctl version 0.12.6 for a linux host:

```
curl -sSL -O https://github.com/k0sproject/k0sctl/releases/download/v0.12.6/k0sctl-linux-x64
sudo mv ./k0sctl-linux-x64 /usr/local/bin/k0sctl
sudo chmod +x /usr/local/bin/k0sctl
```

Once this is done, you can check all the available commands running *k0sctl* without any parameters:

```
$ k0sctl
NAME:
   k0sctl - k0s cluster management tool

USAGE:
   k0sctl [global options] command [command options] [arguments...]

COMMANDS:
   version     Output k0sctl version
   apply       Apply a k0sctl configuration
   kubeconfig  Output the admin kubeconfig of the cluster
   init        Create a configuration template
   reset       Remove traces of k0s from all of the hosts
   backup      Take backup of existing clusters state
   completion
   help, h     Shows a list of commands or help for one command

GLOBAL OPTIONS:
   --debug, -d  Enable debug logging (default: false) [$DEBUG]
   --trace      Enable trace logging (default: false) [$TRACE]
   --no-redact  Do not hide sensitive information in the output (default: false)
   --help, -h   show help (default: false)
```

We will illustrate several of those commands in the following steps.

## Cluster configuration

First, create a sample cluster configuration file, this can be done with the following command:

```
k0sctl init > cluster.yaml
```

This generates a *cluster.yaml* file with the following content (the path towards your default ssh key will be different though):

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
      keyPath: /root/.ssh/id_rsa
    role: controller
  - ssh:
      address: 10.0.0.2
      user: root
      port: 22
      keyPath: /root/.ssh/id_rsa
    role: worker
  k0s:
    version: 1.23.5+k0s.0
```

Note: by default only the k0s's version property is provided alongside the k0sctl default properties. K0s' full default configuration can be retrieved using the additional *-k0s* flag in the init command `k0sctl init -k0s`

Next modify that file so it uses the VMs created previously. You will define:
- *node-1*, *node-2* and *node-3* as controller nodes
- *node-4*, *node-5* and *node-6* as worker nodes

Note: if you need to deploy a cluster in a version different than the default one, you only need to change the .spec.k0s.version property to the value you want to use (this will be illustrated in a later tutorial detailling how to upgrade a k0sctl cluster).

Using the IP addresses retrieved above, the modified version of the cluster.yaml file looks like the following:

```
apiVersion: k0sctl.k0sproject.io/v1beta1
kind: Cluster
metadata:
  name: k0s-cluster
spec:
  hosts:
  - ssh:
      address: 10.30.167.247 
      user: ubuntu
      port: 22
      keyPath: /tmp/k0s
    role: controller
  - ssh:
      address: 10.30.167.119
      user: ubuntu
      port: 22
      keyPath: /tmp/k0s
    role: controller
  - ssh:
      address: 10.30.167.215
      user: ubuntu
      port: 22
      keyPath: /tmp/k0s
    role: controller
  - ssh:
      address: 10.30.167.140
      user: ubuntu
      port: 22
      keyPath: /tmp/k0s
    role: worker
  - ssh:
      address: 10.30.167.147
      user: ubuntu
      port: 22
      keyPath: /tmp/k0s
    role: worker
  - ssh:
      address: 10.30.167.224
      user: ubuntu
      port: 22
      keyPath: /tmp/k0s
    role: worker
  k0s:
    version: 1.23.5+k0s.0
```

:fire: *k0sctl* provides handy options to the *init* subcommand. The above configuration file could also be generated with the following one-liner:

```
k0sctl init -i /tmp/k0s -C 3 \
  ubuntu@10.30.167.247  ubuntu@10.30.167.119 ubuntu@10.30.167.215 \
  ubuntu@10.30.167.140 ubuntu@10.30.167.147 ubuntu@10.30.167.224
```

## Lauching the cluster

Once the cluster's configuration file is ready, you only need to run the following command to have k0sctl creating the cluster:

```
k0sctl apply --config cluster.yaml
```

Below is an example of the whole output for reference. In that one you can see the main phases the creation process goes through. 

```

⠀⣿⣿⡇⠀⠀⢀⣴⣾⣿⠟⠁⢸⣿⣿⣿⣿⣿⣿⣿⡿⠛⠁⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀█████████ █████████ ███
⠀⣿⣿⡇⣠⣶⣿⡿⠋⠀⠀⠀⢸⣿⡇⠀⠀⠀⣠⠀⠀⢀⣠⡆⢸⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀███          ███    ███
⠀⣿⣿⣿⣿⣟⠋⠀⠀⠀⠀⠀⢸⣿⡇⠀⢰⣾⣿⠀⠀⣿⣿⡇⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀███          ███    ███
⠀⣿⣿⡏⠻⣿⣷⣤⡀⠀⠀⠀⠸⠛⠁⠀⠸⠋⠁⠀⠀⣿⣿⡇⠈⠉⠉⠉⠉⠉⠉⠉⠉⢹⣿⣿⠀███          ███    ███
⠀⣿⣿⡇⠀⠀⠙⢿⣿⣦⣀⠀⠀⠀⣠⣶⣶⣶⣶⣶⣶⣿⣿⡇⢰⣶⣶⣶⣶⣶⣶⣶⣶⣾⣿⣿⠀█████████    ███    ██████████

k0sctl v0.12.6 Copyright 2021, k0sctl authors.
Anonymized telemetry of usage will be sent to the authors.
By continuing to use k0sctl you agree to these terms:
https://k0sproject.io/licenses/eula
INFO ==> Running phase: Connect to hosts
INFO [ssh] 10.30.167.119:22: connected
INFO [ssh] 10.30.167.147:22: connected
INFO [ssh] 10.30.167.224:22: connected
INFO [ssh] 10.30.167.247:22: connected
INFO [ssh] 10.30.167.215:22: connected
INFO [ssh] 10.30.167.140:22: connected
INFO ==> Running phase: Detect host operating systems
INFO [ssh] 10.30.167.247:22: is running Ubuntu 20.04.4 LTS
INFO [ssh] 10.30.167.119:22: is running Ubuntu 20.04.4 LTS
INFO [ssh] 10.30.167.215:22: is running Ubuntu 20.04.4 LTS
INFO [ssh] 10.30.167.147:22: is running Ubuntu 20.04.4 LTS
INFO [ssh] 10.30.167.224:22: is running Ubuntu 20.04.4 LTS
INFO [ssh] 10.30.167.140:22: is running Ubuntu 20.04.4 LTS
INFO ==> Running phase: Prepare hosts
INFO ==> Running phase: Gather host facts
INFO [ssh] 10.30.167.140:22: using node-4 as hostname
INFO [ssh] 10.30.167.147:22: using node-5 as hostname
INFO [ssh] 10.30.167.215:22: using node-3 as hostname
INFO [ssh] 10.30.167.247:22: using node-1 as hostname
INFO [ssh] 10.30.167.140:22: discovered ens3 as private interface
INFO [ssh] 10.30.167.215:22: discovered ens3 as private interface
INFO [ssh] 10.30.167.224:22: using node-6 as hostname
INFO [ssh] 10.30.167.119:22: using node-2 as hostname
INFO [ssh] 10.30.167.247:22: discovered ens3 as private interface
INFO [ssh] 10.30.167.147:22: discovered ens3 as private interface
INFO [ssh] 10.30.167.119:22: discovered ens3 as private interface
INFO [ssh] 10.30.167.224:22: discovered ens3 as private interface
INFO ==> Running phase: Validate hosts
INFO ==> Running phase: Gather k0s facts
INFO ==> Running phase: Validate facts
INFO ==> Running phase: Download k0s on hosts
INFO [ssh] 10.30.167.247:22: downloading k0s 1.23.5+k0s.0
INFO [ssh] 10.30.167.140:22: downloading k0s 1.23.5+k0s.0
INFO [ssh] 10.30.167.147:22: downloading k0s 1.23.5+k0s.0
INFO [ssh] 10.30.167.119:22: downloading k0s 1.23.5+k0s.0
INFO [ssh] 10.30.167.215:22: downloading k0s 1.23.5+k0s.0
INFO [ssh] 10.30.167.224:22: downloading k0s 1.23.5+k0s.0
INFO ==> Running phase: Configure k0s
WARN [ssh] 10.30.167.247:22: generating default configuration
INFO [ssh] 10.30.167.215:22: validating configuration
INFO [ssh] 10.30.167.247:22: validating configuration
INFO [ssh] 10.30.167.119:22: validating configuration
INFO [ssh] 10.30.167.119:22: configuration was changed
INFO [ssh] 10.30.167.247:22: configuration was changed
INFO [ssh] 10.30.167.215:22: configuration was changed
INFO ==> Running phase: Initialize the k0s cluster
INFO [ssh] 10.30.167.247:22: installing k0s controller
INFO [ssh] 10.30.167.247:22: waiting for the k0s service to start
INFO [ssh] 10.30.167.247:22: waiting for kubernetes api to respond
INFO ==> Running phase: Install controllers
INFO [ssh] 10.30.167.247:22: generating token
INFO [ssh] 10.30.167.119:22: writing join token
INFO [ssh] 10.30.167.119:22: installing k0s controller
INFO [ssh] 10.30.167.119:22: starting service
INFO [ssh] 10.30.167.119:22: waiting for the k0s service to start
INFO [ssh] 10.30.167.119:22: waiting for kubernetes api to respond
INFO [ssh] 10.30.167.247:22: generating token
INFO [ssh] 10.30.167.215:22: writing join token
INFO [ssh] 10.30.167.215:22: installing k0s controller
INFO [ssh] 10.30.167.215:22: starting service
INFO [ssh] 10.30.167.215:22: waiting for the k0s service to start
INFO [ssh] 10.30.167.215:22: waiting for kubernetes api to respond
INFO ==> Running phase: Install workers
INFO [ssh] 10.30.167.140:22: validating api connection to https://10.30.167.247:6443
INFO [ssh] 10.30.167.224:22: validating api connection to https://10.30.167.247:6443
INFO [ssh] 10.30.167.147:22: validating api connection to https://10.30.167.247:6443
INFO [ssh] 10.30.167.247:22: generating token
INFO [ssh] 10.30.167.140:22: writing join token
INFO [ssh] 10.30.167.147:22: writing join token
INFO [ssh] 10.30.167.224:22: writing join token
INFO [ssh] 10.30.167.224:22: installing k0s worker
INFO [ssh] 10.30.167.140:22: installing k0s worker
INFO [ssh] 10.30.167.147:22: installing k0s worker
INFO [ssh] 10.30.167.140:22: starting service
INFO [ssh] 10.30.167.224:22: starting service
INFO [ssh] 10.30.167.140:22: waiting for node to become ready
INFO [ssh] 10.30.167.224:22: waiting for node to become ready
INFO [ssh] 10.30.167.147:22: starting service
INFO [ssh] 10.30.167.147:22: waiting for node to become ready
INFO ==> Running phase: Disconnect from hosts
INFO ==> Finished in 2m7s
INFO k0s cluster version 1.23.5+k0s.0 is now installed
INFO Tip: To access the cluster you can now fetch the admin kubeconfig using:
INFO      k0sctl kubeconfig
```

It only takes a couple of minutes for the cluster to be up and running.

Next you can retrieve the cluster's kubeconfig file and configure your local *kubectl*:

```
k0sctl kubeconfig -c cluster.yaml > kubeconfig 
export KUBECONFIG=$PWD/kubeconfig
```

Then list the cluster's nodes:

```
kubectl get nodes
```

You should get an output similar to the following one.

```
NAME     STATUS   ROLES    AGE     VERSION
node-4   Ready    <none>   2m55s   v1.23.5+k0s
node-5   Ready    <none>   2m55s   v1.23.5+k0s
node-6   Ready    <none>   2m55s   v1.23.5+k0s
```

Note: only the workers are listed as the controller nodes are isolated for a better security and stability of the cluster.

## Cleanup

The following command removes all the k0s related components but keeps the VMs:

```
k0sctl reset -c cluster.yaml
```

In case you want to remove all the VMs as well you can directly run the following command:

```
multipass delete -p node-1 node-2 node-3 node-4 node-5 node-6
```