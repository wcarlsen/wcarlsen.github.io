---
date: 2025-10-02
tags:
  - kubernetes
---

# Kubernetes resources

I find my self explaining how I approach setting Kuberentes resources over and over again, and I always struggle rediscovering the good references. So this post serves as a reminder for my self and hopefully it can also help you. I always recommend this 3 part post by Shon Lev-Ran

* [Kubernetes resources under the hood part 1](https://medium.com/directeam/kubernetes-resources-under-the-hood-part-1-4f2400b6bb96) (9 min read)
* [Kubernetes resources under the hood part 2](https://medium.com/directeam/kubernetes-resources-under-the-hood-part-2-6eeb50197c44) (7 min read)
* [Kubernetes resources under the hood part 3](https://medium.com/directeam/kubernetes-resources-under-the-hood-part-3-6ee7d6015965) (9 min read)

But to make it real easy. I always set resource using the following guidelines

1. **Only set resources request for CPU and never set CPU limit.**
2. **Always set resource request and limit for memory and make sure they are equal.**
