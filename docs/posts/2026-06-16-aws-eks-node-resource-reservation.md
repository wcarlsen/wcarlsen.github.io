---
date: 2026-06-16
tags:
  - aws
  - kubernetes
---

# AWS EKS node system and kubelet resource reservation

It is well known that enabling prefix delegation on the CNI plugin/addon can drastically increase the node's pod limit. This post is about if and how AWS scale node system and kubelet resource reservation in general and what happens when we tweak max-pods of the kubelet. The latter can be benificial, because it was common that the node ran out of IP's long before any reasonable resource utilization where hit.

### System resource reservation

This one is easy, because AWS EKS managed nodes simply doesn't have any system resources reserved out of the box.

### Kubelet resource reservation

How the kubelet resource reservation for CPU and memory scales with instance size I've found to be not that common knowledge and really interesting. Let start with CPU, which in the calculation is independent of max-pods.

* The scaling of reserved CPU for the kubelet is calculated as 6% of the first core + 1% of the second core + 0.5% of the third and fourth core + 0.25% of the remainding cores

If we move on to the memory it is heavily dependent of max-pods.

* The calculation of reserved memory is 255Mi + (11Mi * max_pods)

Each instance type in AWS has different defaults for max-pods, dependent on network interfaces available, and are normally lower that the recommended upper limit of 110 pods.

### Effect of tweaking max-pods

Now it becomes interesting, because if I enable prefix delegation and tweak max-pods to 110, the calculation for kubelet reserved memory still uses the much lower AWS default. So we have to do the calculation ourselves and set it accordingly. This has side effect is using node scaling tools such as Karpenter that has a bug, where it doesn't take into account system/kubelet reserved resource when pulling in new nodes and it will loop endlessly and fail on scheduling, because there isn't room on the node.
