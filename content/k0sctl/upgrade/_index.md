---
title: Upgrade
weight: 4
---

In this step, you will upgrade the cluster to a newer version of Kubernetes. 

## Upgrade

In order to upgrade the cluster to a newer version (v1.33.4+k0s in this example), change the cluster configuration file with the desired value in *.spec.k0s.version*:

<details>
  <summary markdown="span">Cluster.yaml with k0s version v1.33.4+k0s</summary>

```yaml {filename="cluster.yaml"}
apiVersion: k0sctl.k0sproject.io/v1beta1
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
    version: v1.33.4+k0s.0
    config:
      apiVersion: k0s.k0sproject.io/v1beta1
      kind: Cluster
      metadata:
        name: k0s
      spec:
        extensions:
          helm:
            repositories:
              - name: traefik
                url: https://traefik.github.io/charts
            charts:
              - name: traefik
                chartname: traefik/traefik
                version: "37.1.1"
                namespace: traefik
        api:
          k0sApiPort: 9443
          port: 6443
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
```
</details>

You can then upgrade the cluster with the same command as the one used to create it:

```bash
k0sctl apply --config cluster.yaml
```

k0sctl will upgrade all the nodes starting with the controller ones. It only takes a couple of minutes for the cluster to be upgraded.

<br>

<details>
  <summary markdown="span">Output of the upgrade process</summary>

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
    version: v1.33.4+k0s.0
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
INFO [ssh] 192.168.64.37:22: connected            
INFO [ssh] 192.168.64.36:22: connected            
INFO ==> Running phase: Detect host operating systems 
INFO [ssh] 192.168.64.37:22: is running Ubuntu 24.04.3 LTS 
INFO [ssh] 192.168.64.35:22: is running Ubuntu 24.04.3 LTS 
INFO [ssh] 192.168.64.36:22: is running Ubuntu 24.04.3 LTS 
INFO ==> Running phase: Acquire exclusive host lock 
INFO ==> Running phase: Prepare hosts    
INFO ==> Running phase: Gather host facts 
INFO [ssh] 192.168.64.36:22: using k0s-2 as hostname 
INFO [ssh] 192.168.64.35:22: using k0s-1 as hostname 
INFO [ssh] 192.168.64.37:22: using k0s-3 as hostname 
INFO [ssh] 192.168.64.35:22: discovered enp0s1 as private interface 
INFO [ssh] 192.168.64.36:22: discovered enp0s1 as private interface 
INFO [ssh] 192.168.64.37:22: discovered enp0s1 as private interface 
INFO ==> Running phase: Validate hosts   
WARN failed to walk k0s.tmp.* files in /usr/local/bin/k0s: stat /usr/local/bin/k0s.tmp.*: file does not exist 
WARN failed to walk k0s.tmp.* files in /usr/local/bin/k0s: stat /usr/local/bin/k0s.tmp.*: file does not exist 
WARN failed to walk k0s.tmp.* files in /usr/local/bin/k0s: stat /usr/local/bin/k0s.tmp.*: file does not exist 
INFO validating clock skew                        
INFO ==> Running phase: Gather k0s facts 
INFO [ssh] 192.168.64.35:22: found existing configuration 
INFO [ssh] 192.168.64.35:22: is running k0s controller version v1.33.1+k0s.0 
WARN [ssh] 192.168.64.35:22: k0s will be upgraded 
INFO [ssh] 192.168.64.35:22: listing etcd members 
INFO [ssh] 192.168.64.36:22: is running k0s worker version v1.33.1+k0s.0 
WARN [ssh] 192.168.64.36:22: k0s will be upgraded 
INFO [ssh] 192.168.64.35:22: checking if worker k0s-2 has joined 
INFO [ssh] 192.168.64.37:22: is running k0s worker version v1.33.1+k0s.0 
WARN [ssh] 192.168.64.37:22: k0s will be upgraded 
INFO [ssh] 192.168.64.35:22: checking if worker k0s-3 has joined 
INFO ==> Running phase: Validate facts   
INFO ==> Running phase: Download k0s on hosts 
INFO [ssh] 192.168.64.37:22: downloading k0s v1.33.4+k0s.0 
INFO [ssh] 192.168.64.35:22: downloading k0s v1.33.4+k0s.0 
INFO [ssh] 192.168.64.36:22: downloading k0s v1.33.4+k0s.0 
INFO [ssh] 192.168.64.35:22: validating configuration 
INFO ==> Running phase: Upgrade controllers 
INFO [ssh] 192.168.64.35:22: starting upgrade     
INFO [ssh] 192.168.64.35:22: waiting for the k0s service to start 
INFO ==> Running phase: Upgrade workers  
INFO Upgrading max 1 workers in parallel          
INFO [ssh] 192.168.64.36:22: starting upgrade     
INFO [ssh] 192.168.64.36:22: waiting for node to become ready again 
INFO [ssh] 192.168.64.36:22: upgrade finished     
INFO [ssh] 192.168.64.37:22: starting upgrade     
INFO [ssh] 192.168.64.37:22: waiting for node to become ready again 
INFO [ssh] 192.168.64.37:22: upgrade finished     
INFO ==> Running phase: Release exclusive host lock 
INFO ==> Running phase: Disconnect from hosts 
INFO ==> Finished in 2m6s                
INFO k0s cluster version v1.33.4+k0s.0 is now installed 
INFO Tip: To access the cluster you can now fetch the admin kubeconfig using: 
INFO      k0sctl kubeconfig
```
</details>

Then, verify the Nodes are now running in version v1.33.4+k0s.

```bash
$ kubectl get nodes                 
NAME    STATUS   ROLES    AGE   VERSION
k0s-2   Ready    <none>   13m   v1.33.4+k0s
k0s-3   Ready    <none>   13m   v1.33.4+k0s
```

{{< nav-buttons 
    prev_link="../backup-restore"
    prev_text="Backup & Restore"
    next_link="../cleanup"
    next_text="Cleanup"
>}}