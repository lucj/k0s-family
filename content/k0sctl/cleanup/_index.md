---
title: Cleanup
weight: 5
---

The following command removes all the k0s related components but keeps the VMs.

```bash
k0sctl reset -c cluster.yaml
```

In case you want to remove all the VMs as well you can directly run the following command.

```bash
multipass delete -p k0s-1 k0s-2 k0s-3
```
