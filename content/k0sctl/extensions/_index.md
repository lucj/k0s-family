---
title: Extensions
weight: 2
---

Extensions allows specifying Helm charts or yaml manifests to be deployed during the creation or the update of a cluster. We will illustrate the extensions capability on the cluster we created in the previous step. 

## Cluster configuration file

In the `cluster.yaml` file, add the *extensions* property as follows. It specifies the Helm charts for *Traefik* (Ingress Controller) under `.spec.k0s.config.spec`.

<br>

<details>
  <summary markdown="span">Modified cluster.yaml</summary>

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
    version: v1.33.1+k0s.0
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

Next, update the cluster with this updated version of configuration file:

```bash
k0sctl apply -c cluster.yaml
```

Then, verify the Traefik Pod is running in the `traefik` namespace. 

```bash
$ kubectl get po -n traefik
NAME                       READY   STATUS    RESTARTS   AGE
traefik-7cf7bc96dd-9n9g9   1/1     Running   0          3m55s
```

Using the *extensions* property makes it easy to deploy additional application in the cluster.

{{< nav-buttons 
    prev_link="../cluster-creation"
    prev_text="Cluster creation"
    next_link="../backup-restore"
    next_text="Backup & Restore"
>}}
