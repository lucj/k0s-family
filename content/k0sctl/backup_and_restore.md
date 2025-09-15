In this tutorial, you will:
- create 2 k0s clusters using k0sctl
- create a backup of the first one
- restore that backup in the second one 

:fire: both *k0s* and *k0sctl* have the backup / restore fontionnalities, in this tutorial we will use k0sctl to perform those operations.

## Pre-requisites

- [Multipass](https://multipass.run)
- [K0sctl](https://github.com/k0sproject/k0sctl/releases)

## Creation of the clusters

In this part, you will create 2 clusters:

- k0s-1 should contain 2 nodes
  * k0s-11 a controller node 
  * k0s-12 a worker node
  
- k0s-2 should contain 2 nodes
  * k0s-21 a controller node 
  * k0s-22 a worker node


As you have done in some previous tutorials, you will first create a pair of ssh key that will be used in the next steps:

```
ssh-keygen -t rsa -q -N "" -f /tmp/k0s
```

Next define a *cloud.init* file that references the public key

```
cat<<EOF > cloud.init
ssh_authorized_keys:
  - $(cat /tmp/k0s.pub)
EOF
```

Next create all the nodes using Multipass:

```
multipass launch -n k0s-11 --cloud-init cloud.init
multipass launch -n k0s-12 --cloud-init cloud.init
multipass launch -n k0s-21 --cloud-init cloud.init
multipass launch -n k0s-22 --cloud-init cloud.init
```

:Note: the *--cloud-init* flag allows to provide the cloud.init file to copy the  ssh public key into each VM

Next get the IP addresses of the VMs

```
k0s11_IP=$(multipass info k0s-11 | grep IPv4 | awk '{print $2}')
k0s12_IP=$(multipass info k0s-12 | grep IPv4 | awk '{print $2}')
k0s21_IP=$(multipass info k0s-21 | grep IPv4 | awk '{print $2}')
k0s22_IP=$(multipass info k0s-22 | grep IPv4 | awk '{print $2}')
```

Next create a cluster configuration file for each cluster:

```
# Cluster k0s-1
k0sctl init -i /tmp/k0s -C 1 ubuntu@${k0s11_IP} ubuntu@${k0s12_IP} > cluster-k0s-1.yaml

# Cluster k0s-2
k0sctl init -i /tmp/k0s -C 1 ubuntu@${k0s21_IP} ubuntu@${k0s22_IP} > cluster-k0s-2.yaml
```

Next create the clusters:

```
# Cluster k0s-1
k0sctl apply --config cluster-k0s-1.yaml 

# Cluster k0s-2
k0sctl apply --config cluster-k0s-2.yaml 
```

Then get the kubeconfig files of each one:

```
# Cluster k0s-1
k0sctl kubeconfig --config cluster-k0s-1.yaml > kubeconfig-1

# Cluster k0s-2
k0sctl kubeconfig --config cluster-k0s-2.yaml > kubeconfig-2
```

## Backup of the first cluster

First, configure your local kubectl with the kubeconfig file of the cluster k0s-1:

```
export KUBECONFIG=$PWD/kubeconfig-1
```

Before backing up the cluster, first launch a Pod so you can check if it's correctly restored later on.
Use the following imperative commands to run a Pod based on the ghost blogging platform and expose it with a Service:

```
# Run a Pod based on Ghost
kubectl run ghost --image=ghost:4

# Expose the pod
kubectl expose --port 2368 pod/ghost
```

Next, make sure the Pod and Service were correctly created:

```
$ kubectl get pod,svc -l run=ghost
NAME        READY   STATUS    RESTARTS   AGE
pod/ghost   1/1     Running   0          8m15s

NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/ghost   ClusterIP   10.99.152.142   <none>        2368/TCP   6m59s
```

Then use the following command to create a backup of the cluster with *k0sctl*:

```
$ k0sctl backup --config cluster-k0s-1.yaml 
```

You should be an output similar to the following one:

```
⠀⣿⣿⡇⠀⠀⢀⣴⣾⣿⠟⠁⢸⣿⣿⣿⣿⣿⣿⣿⡿⠛⠁⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀█████████ █████████ ███
⠀⣿⣿⡇⣠⣶⣿⡿⠋⠀⠀⠀⢸⣿⡇⠀⠀⠀⣠⠀⠀⢀⣠⡆⢸⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀███          ███    ███
⠀⣿⣿⣿⣿⣟⠋⠀⠀⠀⠀⠀⢸⣿⡇⠀⢰⣾⣿⠀⠀⣿⣿⡇⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀███          ███    ███
⠀⣿⣿⡏⠻⣿⣷⣤⡀⠀⠀⠀⠸⠛⠁⠀⠸⠋⠁⠀⠀⣿⣿⡇⠈⠉⠉⠉⠉⠉⠉⠉⠉⢹⣿⣿⠀███          ███    ███
⠀⣿⣿⡇⠀⠀⠙⢿⣿⣦⣀⠀⠀⠀⣠⣶⣶⣶⣶⣶⣶⣿⣿⡇⢰⣶⣶⣶⣶⣶⣶⣶⣶⣾⣿⣿⠀█████████    ███    ██████████

k0sctl v0.9.0 Copyright 2021, k0sctl authors.
Anonymized telemetry of usage will be sent to the authors.
By continuing to use k0sctl you agree to these terms:
https://k0sproject.io/licenses/eula
INFO ==> Running phase: Connect to hosts 
INFO [ssh] 192.168.64.105:22: connected           
INFO [ssh] 192.168.64.104:22: connected           
INFO ==> Running phase: Detect host operating systems 
INFO [ssh] 192.168.64.104:22: is running Ubuntu 20.04.2 LTS 
INFO [ssh] 192.168.64.105:22: is running Ubuntu 20.04.2 LTS 
INFO ==> Running phase: Gather host facts 
INFO [ssh] 192.168.64.104:22: discovered enp0s2 as private interface 
INFO ==> Running phase: Gather k0s facts 
INFO [ssh] 192.168.64.104:22: found existing configuration 
INFO [ssh] 192.168.64.104:22: is running k0s controller version 1.21.2+k0s.0 
INFO [ssh] 192.168.64.105:22: is running k0s worker version 1.21.2+k0s.0 
INFO [ssh] 192.168.64.104:22: checking if worker k0s-12 has joined 
INFO ==> Running phase: Take backup      
INFO [ssh] 192.168.64.104:22: backing up          
INFO backup file written to /Users/luc/Development/k0s/k0s_backup_1625312160.tar.gz 
INFO ==> Running phase: Disconnect from hosts 
INFO ==> Finished in 8s
```

As we can see in the output, we can see a *tar.gz* archive has been created. In the next step, we will restore this backup in the second cluster.

## Restore the backup

First, configure your local kubectl with the kubeconfig file of the cluster *k0s-2*:

```
export KUBECONFIG=$PWD/kubeconfig-2
```

Next make sure no Pod nor Service exist in the default namespace:

```
$ kubectl get pod,svc
```

Only the default internal *kubernetes* service should be listed:

```
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   15m
```

Then use the following command to restore the previous backup with *k0sctl*:

:fire: use the path towards the tar.gz file provided at the end of the backup step

```
$ k0sctl apply --config cluster-k0s-2.yaml --restore-from /Users/luc/Development/k0s/k0s_backup_1625312160.tar.gz
```

:fire: this restore step is not working yet, I'm investigating what is missing in my configuration

## Cleanup

You can remove the 4 VMs using the following command:

```
$ multipass delete -p k0s-11 k0s-12 k0s-21 k0s-22
```