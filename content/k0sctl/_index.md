---
title: k0sctl
---

[k0sctl](https://github.com/k0sproject/k0sctl) is defined as a command-line bootstrapping and management tool for k0s kubernetes clusters. In this section, you'll use `k0sctl` to create a `k0s` cluster on Multipass VMs and perform some day 2 operations on it.
 
Before moving to the cluster creation step, [install k0sctl](https://github.com/k0sproject/k0sctl?tab=readme-ov-file#installation) on your local machine. Then, check all the available commands running `k0sctl` without any parameters.

```bash
$ k0sctl
NAME:
   k0sctl - k0s cluster management tool

USAGE:
   k0sctl [global options] command [command options]

COMMANDS:
   version     Output k0sctl version
   apply       Apply a k0sctl configuration
   kubeconfig  Output the admin kubeconfig of the cluster
   init        Create a configuration template
   reset       Remove traces of k0s from all of the hosts
   backup      Take backup of existing clusters state
   config      Configuration related sub-commands
   completion  
   help, h     Shows a list of commands or help for one command

GLOBAL OPTIONS:
   --debug, -d  Enable debug logging (default: false) [$DEBUG]
   --trace      Enable trace logging (default: false) [$TRACE]
   --no-redact  Do not hide sensitive information in the output (default: false)
   --help, -h   show help
```

We will illustrate several of those commands in the following steps.

{{< nav-buttons 
    next_link="./cluster-creation"
    next_text="Cluster creation"
>}}
