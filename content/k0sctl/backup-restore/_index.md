---
title: Backup & Restore
weight: 3
---

In this step, we will create a backup of the cluster and restore it.  

## Backup of the cluster

Use the following command to create a backup of the cluster with *k0sctl*:

```bash
k0sctl backup --config cluster.yaml 
```

You should be an output similar to the following one.

<details>
  <summary markdown="span">Output of the backup command</summary>

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
INFO [ssh] 192.168.64.36:22: connected            
INFO [ssh] 192.168.64.37:22: connected            
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
INFO ==> Running phase: Gather k0s facts 
INFO [ssh] 192.168.64.35:22: found existing configuration 
INFO [ssh] 192.168.64.35:22: is running k0s controller version v1.33.1+k0s.0 
INFO [ssh] 192.168.64.35:22: listing etcd members 
INFO [ssh] 192.168.64.36:22: is running k0s worker version v1.33.1+k0s.0 
INFO [ssh] 192.168.64.35:22: checking if worker k0s-2 has joined 
INFO [ssh] 192.168.64.37:22: is running k0s worker version v1.33.1+k0s.0 
INFO [ssh] 192.168.64.35:22: checking if worker k0s-3 has joined 
INFO ==> Running phase: Take backup      
INFO [ssh] 192.168.64.35:22: backing up           
INFO ==> Running phase: Release exclusive host lock 
INFO ==> Running phase: Disconnect from hosts 
INFO ==> Finished in 2s
```
</details>

The backup process creates a *tar.gz* archive in the current folder.

```bash
$ ls -al *tar.gz
-rw-------@ 1 lucjuggery  staff  1598592 Oct  1 14:15 k0s_backup_1759320898.tar.gz
```

## Run a workload in the cluster

Before restoring the cluster, launch a Pod so you can check if the restoration process went fine in the next step.

```bash
# Run a Pod based on Ghost
kubectl run ghost --image=ghost:4

# Expose the pod
kubectl expose --port 2368 pod/ghost
```

Next, make sure the Pod and Service were correctly created:

```bash
$ kubectl get pod,svc -l run=ghost
NAME        READY   STATUS    RESTARTS   AGE
pod/ghost   1/1     Running   0          37s

NAME            TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
service/ghost   ClusterIP   10.100.22.8   <none>        2368/TCP   37s
```

## Restore the backup

Use the following command to restore the previous backup.

{{< callout type="info" >}}
Use the path towards the tar.gz file provided at the end of the backup step
{{< /callout >}}

```bash
k0sctl apply --config cluster.yaml --restore-from $PWD/k0s_backup_1759320898.tar.gz
```

The ghost Pod should now not be there anymore as it is not present in the backup.

```bash
$ k get po 
NAME    READY   STATUS    RESTARTS   AGE
ghost   1/1     Running   0          8m33s
```

{{< callout type="error" >}}
Restore process does not seem to be working :({{< /callout >}}

{{< nav-buttons 
    prev_link="../extensions"
    prev_text="Extensions"
    next_link="../upgrade"
    next_text="Upgrade"
>}}