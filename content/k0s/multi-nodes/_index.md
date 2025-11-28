---
title: Multi-nodes cluster
weight: 6
---

In this part, you will create a multi-nodes cluster.

## Create the virtual machines

First, run the following command to launch VMs named `k0s-1`, `k0s-2` and `k0s-3`.

```bash
multipass launch -n k0s-1 --disk 10G --cpus 2 --memory 2G
multipass launch -n k0s-2 --disk 10G --cpus 2 --memory 2G
multipass launch -n k0s-3 --disk 10G --cpus 2 --memory 2G
```

Next list the VMs and make sure they are running fine:

```bash
multipass list
```

You should get an output similar to the following one (the IP addresses you get would be different though).

```bash
Name                    State             IPv4             Image
k0s-1                   Running           192.168.64.27    Ubuntu 24.04 LTS
k0s-2                   Running           192.168.64.25    Ubuntu 24.04 LTS
k0s-3                   Running           192.168.64.26    Ubuntu 24.04 LTS
```

## Download k0s binary in each VMs

```bash
for i in 1 2 3; do
  multipass exec k0s-$i -- /bin/sh -c "curl -sSf https://get.k0s.sh | sudo sh"
done
```

## Init the cluster

First, run a shell in `k0s-1`.

```bash
multipass shell k0s-1
```

Next, install k0s controller and start it.

```bash
sudo k0s install controller
sudo k0s start
```

{{< callout type="info" >}}
We don't use the `--single` option as this instance will only act as a control plane Node.
{{< /callout >}}

You can now exit the shell from `k0s-1`.

## Adding worker Nodes

In order to add worker Nodes, we need to generate a token from the control plane and use this token to install k0s on the worker Nodes.

First, generate the token as follows. This will create the file `worker_token` in the current folder.

```bash
multipass exec k0s-1 -- sudo k0s token create --role=worker > ./worker_token
```

{{< callout type="info" >}}
The `worker` role specified in the command indicates that the token will be used to add a worker (default value). We could also use a `controller` role to add additional controllers in the cluster.
{{< /callout >}}

Next, copy that token into *k0s-2* and *k0s-3*.

```bash
multipass transfer ./worker_token k0s-2:/tmp/worker_token
multipass transfer ./worker_token k0s-3:/tmp/worker_token
```

Next, install k0s onto *k0s-2* and *k0s-3* VMs.

```bash
multipass exec k0s-2 -- sudo k0s install worker --token-file /tmp/worker_token
multipass exec k0s-3 -- sudo k0s install worker --token-file /tmp/worker_token
```

Then, start k0s on both worker Nodes:

```bash
multipass exec k0s-2 -- sudo k0s start
multipass exec k0s-3 -- sudo k0s start
```

## Get a kubeconfig file

```bash
multipass exec k0s-1 -- sudo cat /var/lib/k0s/pki/admin.conf > k0s.kubeconfig
```

Next, replace `localhost` with the actual IP address of the Multipass VM.

```bash
K0S1_IP=$(multipass info k0s-1 | grep IP | awk '{print $2}')
sed -i'' "s/localhost/$K0S1_IP/" k0s.kubeconfig
```

Then, configure your local *kubectl*, so it uses this modified kubeconfig file.

```bash
export KUBECONFIG=$PWD/k0s.kubeconfig
```

Listing the cluster's Nodes you should get a list similar to the one below.

```bash
$ kubectl get nodes
NAME    STATUS   ROLES    AGE   VERSION
k0s-2   Ready    <none>   92s   v1.33.4+k0s
k0s-3   Ready    <none>   92s   v1.33.4+k0s
```

{{< callout type="info" >}}
As `k0s-1` was configured as a control plane only Node, it does not appear in this list which only shows the worker Nodes.
{{< /callout >}}

## Cleanup

You can now delete the VMs used in this section.

```bash
multipass delete -p k0s-1 k0s-2 k0s-3
```

In the next section, you will use `k0sctl`, a k0s's companion tool that simplifies the management of multi-nodes clusters.


{{< nav-buttons 
    prev_link="../adding-a-user"
    prev_text="Adding a user"
    next_link="../cleanup"
    next_text="Cleanup"
>}}
