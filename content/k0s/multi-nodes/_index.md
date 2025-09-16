---
title: Multi-nodes cluster
weight: 5
---

In this part, you will create several virtual machines and run a multi node k0s on that ones

## Pre-requisites

[Multipass](https://multipass.run): Multipass is a very handy tool which allows to create Ubuntu virtual machine in a very easy way. It is available on macOS, Windows and Linux.

## Create the virtual machines

First run the following command to launch the VMs named *node-1*, *node-2* and *node-3*:

```
for i in 1 2 3; do 
  multipass launch -n node-$i
done
```

Next list the VMs and make sure they are running fine:

```
multipass list
```

You should get an output similar to the following one:

```
Name                    State             IPv4             Image
node-1                  Running           192.168.64.48    Ubuntu 20.04 LTS
node-2                  Running           192.168.64.49    Ubuntu 20.04 LTS
node-3                  Running           192.168.64.50    Ubuntu 20.04 LTS
```

## Get the k0s binary

First, you need to get the *k0s$ binary on each VM:

```
for i in 1 2 3; do 
  multipass exec node-$i -- bash -c "curl -sSLf get.k0s.sh | sudo sh"
done
```

## Init the cluster

First install the k0s controller as a systemd unit file on *node-1*:

```
multipass exec node-1 -- sudo k0s install controller
```

Next start the cluster:

```
multipass exec node-1 -- sudo k0s start
```

Next make sure it is running fine:

```
multipass exec node-1 -- sudo systemctl status k0scontroller
```

## Accessing the cluster

As you have done in the [single_node](./single_node_multipass.md) tutorial, you need to:

- retrieve the kubeconfig file generated during the cluster installation

```
multipass exec node-1 -- sudo cat /var/lib/k0s/pki/admin.conf > kubeconfig
```

- modify that file to use the IP address of *node-1* instead of *localhost*

```
NODE1_IP=$(multipass info node-1 | grep IP | awk '{print $2}')
sed -i '' "s/localhost/$NODE1_IP/" kubeconfig
```

- configure your local *kubectl* to use that file

```
export KUBECONFIG=$PWD/kubeconfig
```

You can now communicate with your cluster from your local machine:

```
kubectl get nodes
```

Note: the above list is empty... so it appears that your cluster does not have any node. That is not exactly true as only the worker nodes should be listed (those will be added in the next step), the controller node are just hidden. The isolation between the control plane components and the data plane ones is one great feature of k0s.

In the next step you will add worker nodes (nodes that will be used to run workload) in the cluster.

## Adding some worker nodes

First, you need to get a token from the control plane node:

```
multipass exec node-1 -- sudo k0s token create --role=worker > ./worker_token
```

Note: the *worker* role specified in the command indicates that the token will be used to add a worker (that is the default value). We could also use a *controller* role to add additional controllers in the cluster.

Next copy that token into *node-2* and *node-3*

```
multipass transfer ./worker_token node-2:/tmp/worker_token
multipass transfer ./worker_token node-3:/tmp/worker_token
```

Next install k0s onto *node-2* and *node-3*:

```
multipass exec node-2 -- sudo k0s install worker --token-file /tmp/worker_token
multipass exec node-3 -- sudo k0s install worker --token-file /tmp/worker_token
```

Then start k0s on both worker nodes:

```
multipass exec node-2 -- sudo k0s start
multipass exec node-3 -- sudo k0s start
```

Listing the cluster's nodes one more time, you should now be able to see the newly added workers:

```
$ kubectl get nodes
NAME     STATUS     ROLES    AGE   VERSION
node-2   Ready      <none>   52s   v1.23.5+k0s
node-3   Ready      <none>   27s   v1.23.5+k0s
```

Note: it can take a few tens of seconds for the nodes to appear in Ready status

As you have seen, creating a multi nodes cluster is very simple with k0s. In a next tutorial you will use *k0sctl*, a k0s's companion tool that makes this process even easier.

## Cleanup

The following command delete the 3 VMs used in this tutorial

```
multipass delete -p node-1 node-2 node-3
```