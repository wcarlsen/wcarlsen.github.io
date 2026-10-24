---
date: 2026-10-24
tags:
  - kubernetes
  - capi
---

# Cluster API bootstrap and pivot

In my investigation of learning Cluster API, I stumpled upon a thing called bootstrap and pivot using the `clusterctl move` command. To my knowledge it is an attempt to try and solve the chicken and the egg problem, so you can bootstrap a new target management cluster with Cluster API from a bootstrap cluster and then later pivot/move the management of the target management cluster from the bootstrap cluster to the target management cluster it self. Confusing I know, but let's try to break it down and investigate.

### Bootstrap and pivot

So how would the process actually look like.

1. Create local bootstrap cluster with e.g. `minikube start`
1. Install CAPI plus providers with `clusterctl init`
1. Provision new cluster (future target for management cluster) with `clusterctl generate`
1. Get kubeconfig for new cluster with `clusterctl get kubeconfig`
1. Backup new cluster with `clusterctl move --to-folder`, because the pivot later will delete resources
1. Install CAPI plus providers on the new cluster with `clusterctl init`
1. Pivot CAPI related resources to new cluster with `clusterctl move --to-kubeconfig`
1. Remove local bootstrap cluster with `minikube delete`

The new cluster is now managing it self. This of course means that we can solve the chicken and the egg problem using only Cluster API. But it also means that all clusters created with Cluster API can now manage their own resources and create total isolation. It also removes the overhead of having a dedicated management cluster, if you cluster count is low. If this is a good idea or not I will let you think about.

Lastly here is a link to the [documentation](https://cluster-api.sigs.k8s.io/clusterctl/commands/move#bootstrap--pivot).
