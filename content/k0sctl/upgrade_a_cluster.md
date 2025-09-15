In this tutorial, you will first create a cluster using *k0sctl* and then upgrade it to a newer version of Kubernetes. 
As you have already done in previous tutorials, you will use Multipass to create local virtual machines. 

## Pre-requisites

- [Multipass](https://multipass.run)
- [K0sctl](https://github.com/k0sproject/k0sctl/releases)

## Create the virtual machines

First, create a new pair of ssh key:

```
$ ssh-keygen -t rsa -q -N "" -f /tmp/k0s
```

Next create the cloud.init file that will contains the public key:

```
cat<<EOF > cloud.init
ssh_authorized_keys:
  - $(cat /tmp/k0s.pub)
EOF
```

Run the following command to launch the VMs named *node-1* to *node-5*:

Note: the *--cloud-init* flag is used to configure each VM with the public key created in the previous step

```
for i in $(seq 1 5); do 
  multipass launch -n node-$i --cloud-init cloud.init
done
```

Make sure those VMs are running fine:

```
$ multipass list
```

You should get an output similar to the following one (the IP addresses would probably be different though):

```
Name                     State             IPv4             Image
node-1                   Running           192.168.64.11    Ubuntu 20.04 LTS
node-2                   Running           192.168.64.12    Ubuntu 20.04 LTS
node-3                   Running           192.168.64.13    Ubuntu 20.04 LTS
node-4                   Running           192.168.64.29    Ubuntu 20.04 LTS
node-5                   Running           192.168.64.30    Ubuntu 20.04 LTS
```

You will use the IP addresses of those machines in a next step.

## Cluster configuration

First you will generate a sample cluster configuration file, this can be done with the following command:

```
$ k0sctl init > cluster.yaml
```

This command returns a content similar to the following one:
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
      keyPath: /Users/luc/.ssh/id_rsa
    role: controller
  - ssh:
      address: 10.0.0.2
      user: root
      port: 22
      keyPath: /Users/luc/.ssh/id_rsa
    role: worker
  k0s:
    version: 1.21.2+k0s.0
```

Next, modify that file so it defines:
- *node-1*, *node-2* and *node-3* as controller nodes
- *node-4*, *node-5* as worker nodes
- k0s 1.20.6 as the cluster version (this version is not the latest one)

Using the address IP from the previous command, the modified version of the cluster.yaml file would look like the following:

```
apiVersion: k0sctl.k0sproject.io/v1beta1
kind: Cluster
metadata:
  name: k0s-cluster
spec:
  hosts:
  - ssh:
      address: 192.168.64.11 
      user: ubuntu
      port: 22
      keyPath: /tmp/k0s
    role: controller
  - ssh:
      address: 192.168.64.12
      user: ubuntu
      port: 22
      keyPath: /tmp/k0s
    role: controller
  - ssh:
      address: 192.168.64.13
      user: ubuntu
      port: 22
      keyPath: /tmp/k0s
    role: controller
  - ssh:
      address: 192.168.64.29
      user: ubuntu
      port: 22
      keyPath: /tmp/k0s
    role: worker
  - ssh:
      address: 192.168.64.30
      user: ubuntu
      port: 22
      keyPath: /tmp/k0s
    role: worker
  k0s:
    version: 1.20.6+k0s.0
```

## Lauching the cluster

Once the cluster's configuration file is ready, you only need to run the following command to create the cluster (it only takes a couple of minutes for the cluster to be up and running):

```
$ k0sctl apply --config cluster.yaml
```

Next you can retrieve the cluster's kubeconfig file and configure your local *kubectl* using that one:

```
k0sctl kubeconfig -c cluster.yaml > kubeconfig 
export KUBECONFIG=$PWD/kubeconfig
```

You should now be able to list the cluster's nodes and get an output similar to the following one:

```
$ kubectl get nodes
NAME     STATUS   ROLES    AGE     VERSION
node-4   Ready    <none>   76s     v1.20.6-k0s1
node-5   Ready    <none>   77s     v1.20.6-k0s1
```

Note: only the worker nodes are listed as the controller ones are isolated for a better security

As you can see, the nodes are in the version provided in the *.spec.k0s.version* property. 

## Upgrade

In order to upgrade the cluster to a newer version (1.21.1 in this example), change the cluster configuration file with the desired value in *.spec.k0s.version*:

```
  ...
  k0s:
    version: 1.21.1+k0s.0
```

You can then upgrade the cluster with the same command as the one used to create it:

```
$ k0sctl apply --config cluster.yaml
```

During the process, we can see k0sctl get the current status of each node checking if an upgrade is needed:

```
...
INFO ==> Running phase: Gather k0s facts 
INFO [ssh] 192.168.64.13:22: found existing configuration 
INFO [ssh] 192.168.64.11:22: found existing configuration 
INFO [ssh] 192.168.64.11:22: is running k0s controller version 1.20.6+k0s.0 
WARN [ssh] 192.168.64.11:22: k0s will be upgraded 
INFO [ssh] 192.168.64.12:22: is running k0s controller version 1.20.6+k0s.0 
WARN [ssh] 192.168.64.12:22: k0s will be upgraded 
INFO [ssh] 192.168.64.13:22: is running k0s controller version 1.20.6+k0s.0 
WARN [ssh] 192.168.64.13:22: k0s will be upgraded 
INFO [ssh] 192.168.64.29:22: is running k0s worker version 1.20.6+k0s.0 
WARN [ssh] 192.168.64.29:22: k0s will be upgraded 
INFO [ssh] 192.168.64.11:22: checking if worker node4 has joined 
INFO [ssh] 192.168.64.30:22: is running k0s worker version 1.20.6+k0s.0 
WARN [ssh] 192.168.64.30:22: k0s will be upgraded 
INFO [ssh] 192.168.64.11:22: checking if worker node5 has joined
...
```

k0sctl will then upgrade all the nodes starting with the controller ones. It only takes a couple of minutes for the cluster to be upgraded.


You should now be able to list the cluster's nodes and verify they are in the updated version:

```
$ kubectl get nodes                 
NAME     STATUS   ROLES    AGE   VERSION
node-4   Ready    <none>   16m   v1.21.1-k0s1
node-5   Ready    <none>   16m   v1.21.1-k0s1
```

## Cleanup

The following command removes all the k0s related components but keeps the VMs:

```
$ k0sctl reset -c cluster.yaml
```

In case you want to remove all the VMs as well you can directly run the following command:

```
$ multipass delete -p node-1 node-2 node-3 node-4 node-5
```