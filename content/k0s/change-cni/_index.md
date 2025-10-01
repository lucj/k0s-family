---
title: Change CNI
weight: 5
---

Change the configuration file so it disables `kube-proxy` and specifies a custom CNI provider.

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
      disabled: true               # Disabling kubeproxy
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
    provider: custom               # Using a custom CNI provider
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

```bash
sudo systemctl edit --full k0scontroller
```

```
[Service]
StartLimitInterval=5
StartLimitBurst=10
ExecStart=/usr/local/bin/k0s controller --single=true


[Service]
StartLimitInterval=5
StartLimitBurst=10
ExecStart=/usr/local/bin/k0s controller --single=true -c /etc/k0s/k0s.yaml
```

```bash
sudo systemctl daemon-reload
```

```bash
sudo systemctl restart k0scontroller
```

Cilium needs a kubeconfigfile

```bash
sudo chown $(id -u):$(id -g) /var/lib/k0s/pki/admin.conf
export KUBECONFIG=/var/lib/k0s/pki/admin.conf
```

```bash
OS="$(uname | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"
curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-$OS-$ARCH.tar.gz{,.sha256sum}
sudo tar xzvfC cilium-$OS-$ARCH.tar.gz /usr/local/bin
cilium install
```

{{< nav-buttons 
    prev_link="../adding-a-user"
    prev_text="Adding a user"
    next_link="../multi-nodes"
    next_text="Multi Nodes"
>}}