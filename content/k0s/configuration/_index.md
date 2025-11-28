---
title: Configuration
weight: 2
---

In this part, we will change the configuration of our one-node cluster, using Cilium CNI instead of the default KubeRouter.

## Default k0s configuration

When running a k0s cluster, the default configuration options are used, but we can modify it to match specific needs. The following command get the default configuration and save it in `/etc/k0s/k0s.yaml`.

```bash
k0s config create | sudo tee /etc/k0s/k0s.yaml
```

The output is similar to the following one:

```yaml
apiVersion: k0s.k0sproject.io/v1beta1
kind: ClusterConfig
metadata:
  name: k0s
  namespace: kube-system
spec:
  api:
    address: 192.168.64.22
    ca:
      certificatesExpireAfter: 8760h0m0s
      expiresAfter: 87600h0m0s
    k0sApiPort: 9443
    port: 6443
    sans:
    - 192.168.64.22
    - 10.244.0.1
    - fd2b:842a:4fd0:1ed3:5054:ff:fe9e:b8c0
    - fe80::5054:ff:fe9e:b8c0
    - fe80::54e7:aeff:fe62:be42
    - fe80::7038:13ff:fe2f:3e64
    - fe80::8468:5cff:fe21:691e
  controllerManager: {}
  extensions:
    helm:
      concurrencyLevel: 5
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
    clusterDomain: cluster.local
    dualStack:
      enabled: false
    kubeProxy:
      iptables:
        minSyncPeriod: 0s
        syncPeriod: 0s
      ipvs:
        minSyncPeriod: 0s
        syncPeriod: 0s
        tcpFinTimeout: 0s
        tcpTimeout: 0s
        udpTimeout: 0s
      metricsBindAddress: 0.0.0.0:10249
      mode: iptables
      nftables:
        minSyncPeriod: 0s
        syncPeriod: 0s
    kuberouter:
      autoMTU: true
      hairpin: Enabled
      metricsPort: 8080
    nodeLocalLoadBalancing:
      enabled: false
      envoyProxy:
        apiServerBindPort: 7443
        konnectivityServerBindPort: 7132
      type: EnvoyProxy
    podCIDR: 10.244.0.0/16
    provider: kuberouter
    serviceCIDR: 10.96.0.0/12
  scheduler: {}
  storage:
    etcd:
      ca:
        certificatesExpireAfter: 8760h0m0s
        expiresAfter: 87600h0m0s
      peerAddress: 192.168.64.22
    type: etcd
  telemetry:
    enabled: false
```

## Update the configuration

For demo purposes, change the configuration file by removing the IPv6 addresses from the `sans` property.

```yaml
...
spec:
  api:
    address: 192.168.64.22
    ca:
      certificatesExpireAfter: 8760h0m0s
      expiresAfter: 87600h0m0s
    k0sApiPort: 9443
    port: 6443
    sans:
    - 192.168.64.22          # <- only leaves IPv4 entries
    - 10.244.0.1
...  
```

In order to take into account the configuration file, we first edit the systemd unit file providing the path towards this file.

```bash
sudo systemctl edit --full k0scontroller
```

Change the unit file from this content.

```
[Service]
StartLimitInterval=5
StartLimitBurst=10
ExecStart=/usr/local/bin/k0s controller --single=true
```

to this one which includes `k0s.yaml` configuration file.

```
[Service]
StartLimitInterval=5
StartLimitBurst=10
ExecStart=/usr/local/bin/k0s controller --single=true -c /etc/k0s/k0s.yaml
```

Next, restart the daemon.

```bash
sudo systemctl daemon-reload
```

```bash
sudo systemctl restart k0scontroller
```

In the next section, we'll get one step further updating the configuration to change the default CNI.

{{< nav-buttons 
    prev_link="../single-node"
    prev_text="Single Node"
    next_link="../extensions"
    next_text="Extensions"
>}}
