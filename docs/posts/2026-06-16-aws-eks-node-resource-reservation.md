---
date: 2026-06-16
tags:
  - aws
  - kubernetes
---

# AWS EKS node system and kubelet resource reservation

It is well known that enabling prefix delegation on the CNI plugin/addon can drastically increase the node's pod limit. This post is about if and how AWS scales node system and kubelet resource reservation in general, and what happens when we tweak the kubelet's max-pods setting. The latter can be beneficial, because it was common that the node ran out of IPs long before any reasonable resource utilization was reached.

### System resource reservation

This one is easy, because AWS EKS managed nodes simply don't have any system resources reserved out of the box. AWS documentation is really vague about setting it, but they write if you must set, you should only set it for un-compressable resources (memory).

### Kubelet resource reservation

How the kubelet's resource reservation for CPU and memory scales with instance size is not widely known and is really interesting. Let's start with CPU, which in the calculation is independent of max-pods.

* The scaling of reserved CPU for the kubelet is calculated as the sum of 6% of the first core, 1% of the second core, 0.5% of the third and fourth cores, and 0.25% of the remaining cores.

If we move on to memory, it is heavily dependent on max-pods.

* The calculation of reserved memory is 255Mi + (11Mi * max_pods)

Each instance type in AWS has different defaults for max-pods, depending on available network interfaces, and is normally lower than the recommended upper limit of 110 pods.

### Effect of tweaking max-pods

Now it becomes interesting: if I enable prefix delegation and set max-pods to 110, the kubelet reserved memory calculation still uses the much lower AWS default. So we have to do the calculation ourselves and set it accordingly, since AWS doesn't do it for us.
