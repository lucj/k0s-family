---
title: Configuration
weight: 2
---

In this part, you will use the VM created in the previous step and change the configuration.

## Default k0s configuration

When running a k0s cluster, the default configuration options are used, but we can modify it to match specific needs.

The defaults configuration options can be retrieved with:

```bash
k0s config create > k0s.config
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
    address: 192.168.64.21
    ca:
      certificatesExpireAfter: 8760h0m0s
      expiresAfter: 87600h0m0s
    k0sApiPort: 9443
    port: 6443
    sans:
    - 192.168.64.21
    - fd2b:842a:4fd0:1ed3:5054:ff:fe9c:6728
    - fe80::5054:ff:fe9c:6728
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
      peerAddress: 192.168.64.21
    type: etcd
  telemetry:
    enabled: false
```


Modify this configuration so it use cilium instead of kuberouter.






{{< callout icon="warning" >}}
To override some of those properties you can save the configuration, modify it and use it when running k0s (more on that below)
{{< /callout >}}

## Install k0s

Once the k0s binary is installed, we can get a single node k0s cluster:

```bash
sudo k0s install controller --single -c k0s.config --force
```

## Start the cluster

First, start the cluster:

```bash
sudo k0s start
```

Next verify it has been started properly using the *status* subcommand:

```bash
sudo k0s status
```


## Cleanup

Remove the ghost Deployment and Service:

```
kubectl delete deploy/ghost svc/ghost
```

In order to remove k0s from the VM (without deleting the VM) you first need to stop k0s:

```
ubuntu@node-1:~$ sudo k0s stop
```

and then *reset* it:

```
ubuntu@node-1:~$ sudo k0s reset
```

You can use the following command from test host machine if you need to remove the whole VM:

```
multipass delete -p node-1
```