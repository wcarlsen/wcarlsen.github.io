---
date: 2026-09-05
tags:
  - aws
  - kubernetes
  - capi
---

# Playing with Cluster API continued

In the previous post we bootstrapped a Cluster API management cluster onto a local Kubernetes distribution and used that to provision a workload cluster. We also made sure that we could take backup of workload cluster related resources and restore them, making the need for long live management clusters less important. See the post [here](2026-08-18-playing-with-cluster-api.md). In this post we will focusing more on Cluster API specific ways to deploy things onto the workload cluster, which is important for bootstrapping GitOps capabilties among other things. It should be noted that all methods covered here will first apply things to the workload cluster once it is ready.

### ClusterResourceSet

With Cluster API we can enable ClusterResourceSet by  setting the experimental feature with the flag `EXP_CLUSTER_RESOURCE_SET=true` when bootstrapping the management cluster. This ensures that the custom resource `ClusterResourceSet` becomes available on our management cluster. But how does it work?

The concept is pretty simple to grasp if we inspect an example of the resource

```yaml
---
apiVersion: addons.cluster.x-k8s.io/v1beta2
kind: ClusterResourceSet
metadata:
  name: my-customresourceset
  namespace: default
spec:
  clusterSelector:
    matchLabels:
      clusterresourceset: enabled
  resources:
    - kind: ConfigMap
      name: my-manifests
  strategy: ApplyOnce

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-manifests
  namespace: default
data:
  namespace.yaml: |-
    ---
    apiVersion: v1
    kind: Namespace
    metadata:
      name: my-new-namespace
```

A `ClusterResourceSet` targets a cluster using label selectors, so we my label our workload cluster resource to make this work. Then it references resources like `ConfigMap` and `Secret` (I haven't tried with `Secret`) that contains the manifest we want applied on our target cluster. In this example it is just a namespace, but it can be arbitrary comlex. Lastly we have a strategy which can be `ApplyOnce` or `Reconcile`. It should be noted that if we delete any resources in our configmap Cluster API will not delete the resource in the target cluster to my knowledge. We could have wished for better controller functionality, but for bootstrapping it probably works okay. You can probably read between the lines, that I'm not the biggest of fans.

### Helm addon

The second method we will cover is Helm addon, which can be enabled by adding `--addon helm` when bootstrapping the management cluster. This will make the `HelmChartProxy` custom resource available and install a controller called capah. If we inspect an example resource where we just deploy the metrics-server helm chart. We will see that it follows the same concept of using a cluster label selector and the rest of the spec is related to the helm chart we whish to consume.

```yaml
apiVersion: addons.cluster.x-k8s.io/v1alpha1
kind: HelmChartProxy
metadata:
  name: metrics-server
  namespace: default
spec:
  clusterSelector:
    matchLabels:
      helm-addon: enabled
  repoURL: "https://kubernetes-sigs.github.io/metrics-server/"
  chartName: metrics-server
  options:
    waitForJobs: true
    wait: true
    timeout: 5m
    install:
      createNamespace: true
```

Unlike with ClusterResourceSet, when delete a HelmChartProxy resource it will also be deleted in the target cluster. So it follows the concept we would expect from a proper controller. If your need for bootstrapping is covered by Helm, I would strongly suggest this as the prefferred method.
