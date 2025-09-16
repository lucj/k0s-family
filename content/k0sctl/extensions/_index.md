Extensions allows to specify Helm charts or yaml manifests to be deployed during the creation or update of a cluster.
We will illustrate the extensions capability on a multi-node cluster created with the k0sctl binary. 

## Pre-requisites

- [Multipass](https://multipass.run)
- [K0sctl](https://github.com/k0sproject/k0sctl/releases/)

## Creation of the VMs

As you've already done in previous tutorials, you will first create a pair of ssh key that will be used in the next steps:

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

Next create the nodes using Multipass:

```
for i in 0 1;do
  multipass launch -n k0s-$i --cloud-init ./cloud.init
done
```

:Note: the *--cloud-init* flag allows to provide the cloud.init file used to copy the public key into the VM

Next get the IP addresses of the VMs

```
k0s0_IP=$(multipass info k0s-0 | grep IPv4 | awk '{print $2}')
k0s1_IP=$(multipass info k0s-1 | grep IPv4 | awk '{print $2}')
```

## Configuration of the cluster

First create a cluster configuration file with the following command:

```
k0sctl init --k0s -i /tmp/k0s -C 1 ubuntu@${k0s0_IP} ubuntu@${k0s1_IP} > cluster.yaml
```

:Note:
- *--k0s* flag adds the k0s' default values in k0sctl's configuration file
- *-C 1* indicates only one controller node will be used

Add the *extensions* property which specifies that the Helm charts for *Traefik* (Ingress Controller) under *.spec.k0s.config.spec* :

```
apiVersion: k0sctl.k0sproject.io/v1beta1
kind: Cluster
metadata:
  name: k0s-cluster
spec:
  hosts:
    - ssh:
        address: "192.168.64.110"
        user: ubuntu
        port: 22
        keyPath: /tmp/k0s
      role: controller
    - ssh:
        address: "192.168.64.111"
        user: ubuntu
        port: 22
        keyPath: /tmp/k0s
      role: worker
  k0s:
    version: 1.21.2+k0s.0
    config:
      apiVersion: k0s.k0sproject.io/v1beta1
      kind: Cluster
      metadata:
        name: k0s
      spec:
        extensions: # <-- This property and all its sub-properties need to be added
          helm:
            repositories:
              - name: traefik
                url: https://helm.traefik.io/traefik
            charts:
              - name: traefik
                chartname: traefik/traefik
                version: "9.11.0"
                namespace: kube-system
        api:
          k0sApiPort: 9443
          port: 6443
        images:
          calico:
            cni:
              image: docker.io/calico/cni
              version: v3.18.1
            kubecontrollers:
              image: docker.io/calico/kube-controllers
              version: v3.18.1
            node:
              image: docker.io/calico/node
              version: v3.18.1
          coredns:
            image: docker.io/coredns/coredns
            version: 1.7.0
          default_pull_policy: IfNotPresent
          konnectivity:
            image: us.gcr.io/k8s-artifacts-prod/kas-network-proxy/proxy-agent
            version: v0.0.16
          kubeproxy:
            image: k8s.gcr.io/kube-proxy
            version: v1.21.1
          kuberouter:
            cni:
              image: docker.io/cloudnativelabs/kube-router
              version: v1.2.1
            cniInstaller:
              image: quay.io/k0sproject/cni-node
              version: 0.1.0
          metricsserver:
            image: gcr.io/k8s-staging-metrics-server/metrics-server
            version: v0.3.7
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
          kuberouter:
            autoMTU: true
          podCIDR: 10.244.0.0/16
          provider: kuberouter
          serviceCIDR: 10.96.0.0/12
        podSecurityPolicy:
          defaultPolicy: 00-k0s-privileged
        storage:
          type: etcd
        telemetry:
          enabled: true

```

:fire: the helm chart is specified in the *extensions* key under *.spec.k0s.config.spec*.

Next, create the cluster with this updated version of configuration file:

```
k0sctl apply -c cluster.yaml
```

Then retrieve the cluster's kubeconfig file and configure your local *kubectl* with that one:

```
k0sctl kubeconfig -c cluster.yaml > kubeconfig 
export KUBECONFIG=$PWD/kubeconfig
```

Make sure the single worker node is in the Ready state:

```
$ kubectl get nodes
NAME    STATUS   ROLES    AGE   VERSION
k0s-0   Ready    <none>   84s   v1.21.2+k0s
```

Verify that Traefik Helm Chart was created:

```
$ helm list -A
NAME               	NAMESPACE  	REVISION	UPDATED                                 	STATUS  	CHART         	APP VERSION
traefik-1625587310 	kube-system	3       	2021-07-06 18:02:41.006748219 +0200 CEST	deployed	traefik-9.11.0	2.3.3
```

Also verify that Pods for Traefik was created:

```
$ kubectl get po -A
NAMESPACE     NAME                                        READY   STATUS      RESTARTS   AGE
kube-system   coredns-5ccbdcc4c4-qwwzq                    1/1     Running     0          3m47s
kube-system   coredns-5ccbdcc4c4-wfjh8                    1/1     Running     0          3m47s
kube-system   konnectivity-agent-4mpz8                    1/1     Running     0          3m9s
kube-system   konnectivity-agent-gmxvt                    1/1     Running     0          2m50s
kube-system   konnectivity-agent-tx6mc                    1/1     Running     0          3m25s
kube-system   kube-proxy-b7n6f                            1/1     Running     0          3m37s
kube-system   kube-proxy-lj7vw                            1/1     Running     0          3m37s
kube-system   kube-proxy-pvplr                            1/1     Running     0          3m37s
kube-system   kube-router-2zr5k                           1/1     Running     0          3m50s
kube-system   kube-router-57hqf                           1/1     Running     0          4m16s
kube-system   kube-router-dpscn                           1/1     Running     0          4m13s
kube-system   metrics-server-59d8698d9-7hjbb              1/1     Running     0          3m38s
kube-system   traefik-1625587310-7f6b4f6bcc-wnl2f         1/1     Running     0          4m26s
```

Use the following command to open a port-forward against Traefik Pod:

```
POD=$(kubectl -n kube-system get pods --selector "app.kubernetes.io/name=traefik" --output=name)
kubectl port-forward -n kube-system $POD 9000:9000
```

Traefik dashboard it then accessible from [http://localhost:9000/dashboard](http://localhost:9000/dashboard)

![Traefik dashboard](./images/traefik_dashboard.png)

We leave as an exercice to the reader to create an IngressRoute and expose a simple workload.

As you can see, using the *extensions* property makes it very easy to deploy additional application through Helm Chart.

## Cleanup

Remove all the VMs using the following command:

```
$ multipass delete -p k0s-0 k0s-1
```


