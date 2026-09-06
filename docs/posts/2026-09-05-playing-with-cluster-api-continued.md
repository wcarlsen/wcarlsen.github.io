---
date: 2026-09-05
tags:
  - aws
  - kubernetes
  - capi
---

# Playing with Cluster API continued

In the previous post, we bootstrapped a Cluster API management cluster onto a local Kubernetes distribution and used it to provision a workload cluster. We also made sure that we could take backups of resources related to the workload cluster and restore them, reducing the need for long-lived management clusters. See the post [here](2026-08-18-playing-with-cluster-api.md). In this post we will focus more on Cluster API-specific ways to deploy resources onto the workload cluster, which is important for bootstrapping GitOps capabilities, among other things. Note that all methods covered here apply resources to the workload cluster once it is ready.

### ClusterResourceSet

With Cluster API we can enable ClusterResourceSet by setting the experimental feature flag `EXP_CLUSTER_RESOURCE_SET=true` when bootstrapping the management cluster. This ensures that the custom resource `ClusterResourceSet` becomes available on our management cluster. But how does it work?

The concept is pretty simple to grasp if we inspect an example of the resource:

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

A `ClusterResourceSet` targets a cluster using label selectors, so we may label our workload cluster to make this work. Then it references resources like `ConfigMap` and `Secret` (I haven't tried this with `Secret`) that contain the manifests we want applied to our target cluster. In this example it is just a namespace, but it can be arbitrarily complex. Lastly, the strategy can be `ApplyOnce` or `Reconcile`. Note that if we delete any resources in our `ConfigMap`, Cluster API will not delete the corresponding resources in the target cluster, to my knowledge. We could wish for better controller functionality, but for bootstrapping it probably works fine. You can probably read between the lines that I'm not the biggest fan.

### Helm addon

The second method we will cover is the Helm addon, which can be enabled by adding `--addon helm` when bootstrapping the management cluster. This will make the `HelmChartProxy` custom resource available and install a controller called caaph. If we inspect an example resource where we deploy the metrics-server Helm chart, we will see that it follows the same concept: it uses a cluster label selector, and the rest of the spec relates to the Helm chart we wish to consume.

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

Unlike with ClusterResourceSet, when we delete a `HelmChartProxy` resource the chart will also be removed from the target cluster. So it behaves as we'd expect from a proper controller. If your bootstrapping needs are covered by Helm, I would strongly suggest this as the preferred method.
