In this exercise you will create a muti node k0s cluster 

Note: node1 and node2 will be used, make sure to run each command on the correct node :)

## Creating a controller node

In this section, make sure to run the commands on node1.

As you have done in the single node lab, first get the latest release of k0s:

```
curl -sSLf get.k0s.sh | sudo sh
```

Next install k0s as a controller node:

```
sudo k0s install controller
```

Next start the newly created systemd service:

```
sudo k0s start
```

After a few seconds, verify it has been started properly:

```
sudo k0s status
```

You should get an output similar to the following one:

```
Version: v1.22.2+k0s.1
Process ID: 1791
Role: controller
Workloads: false
```

As k0s comes with its own kubectl subcommand, you can directly list the status of our single node cluster:

```
sudo k0s kubectl get node
```

Note: as the current node is a controller node only it will not be listed. Instead, you will get the following output instead:

```
No resources found
```

## Adding a worker node

In this step you will add a worker node to the cluster

First, from node1, get the join token:

```
sudo k0s token create --role=worker
```

Note: the *worker* role specified in the command indicates that the token will be used to add a worker (that is the default value). We could also use a *controller* role to add additional controllers to the cluster.

Next you need to paste the token into the *k0s_worker_token* file within the *home* directory of *node2*'s user.

In order to do so follow the steps below:
- copy the whole token into your clipboard
- run a terminal on node2 selecting this VM in the list within the dropdown at the top of the screen 

![List of VMs](./images/vms-dropdown.png)

- run the following command in this new terminal:
```
cat > $HOME/k0s_worker_token
```
- paste the token and press ENTER
- press CTRL-D.

Next download k0s onto node2:

```
curl -sSLf get.k0s.sh | sudo sh
```

Install it as a worker node by providing the joining token as a parameter:

```
sudo k0s install worker --token-file $HOME/k0s_worker_token
```

Then start it:

```
sudo k0s start
```

It will take a few tens of seconds to get the worker node ready.

Make sure it has started correctly

```
sudo k0s status
```

You should get an output similar to the following one:

```
Version: v1.22.2+k0s.1
Process ID: 1872
Role: worker
Workloads: true
```

From node1, list the nodes:

```
sudo k0s kubectl get node
```

Note: only the worker node appears in this list due to the control plane isolation feature of k0s

```
NAME    STATUS   ROLES    AGE   VERSION
node2   Ready    <none>   32s   v1.22.2+k0s
```

You've successfully created a multi-node cluster containing one controller and one worker node.

## Cleanup 

Remove k0s from node1 and node2 by running the following commands on both VMs:

```
sudo k0s stop
sudo k0s reset
```
