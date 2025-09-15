This repo will be used to demo k0s and its k0sctl companion tool.

## About k0s

k0s is a Kubernetes distribution developed by Mirantis. It is shipped as a single binary without any OS dependencies and is thus defined as a zero-friction/zero-deps/zero-cost Kubernetes distribution.

The latest k0s release:
- Ships a certified and (CIS-benchmarked) Kubernetes 1.23.5
- Uses containerd as the default container runtime
- Supports Intel (x86-64) and ARM (ARM64) architectures
- Uses an in-cluster etcd
- Uses the Kube-router network plugin by default
- Enables the Pod Security Policies admission controller
- Uses DNS with CoreDNS
- Exposes cluster metrics via Metrics Server
- Allows the usage of Horizontal Pod Autoscaling (HPA)
- and much much more...

More information on [https://k0sproject.io/](https://k0sproject.io/)

## About this repository

The current repository contains several tutorials:

- Several ways to create a single node cluster

  * [single node k0s cluster using Multipass](./single_node_multipass.md)
  * [single node k0s cluster using Vagrant](./single_node_vagrant.md)

- Several ways to create a multi nodes cluster

  * [multi nodes k0s cluster](./multi_nodes.md)
  * [multi nodes k0s cluster with k0sctl](./multi_nodes_k0sctl.md)

- Extensions

  * [Using extensions with k0s](./extensions_k0s.md)
  * [Using extensions with k0sctl](./extensions_k0sctl.md)

- Others:

  * [Add a new user to your cluster](./add_a_user.md)
  * [Upgrade a cluster](./upgrade_a_cluster.md)
  * WIP: [Backup and restore a cluster](./backup_and_restore.md)

:fire: additional tutorials will be added soon
