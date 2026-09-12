---
date: 2026-09-06
tags:
  - aws
  - eks
  - kubernetes
  - capi
  - helm
---

# Playing with Cluster API helm addon

In the previous post, we continued the journey of playing with Cluster API, and tried to cover how to get things onto a workload cluster see the post [here](2026-09-05-playing-with-cluster-api-continued.md). Here we went through `ClusterResourceSet` and `HelmChartProxy`. In this post we will dig deeper into the capabilities of `HelmChartProxy` with focus on templating propagating cluster infrastructure specific details.

### Why is this important?

When bootstrapping controllers and others onto a workload cluster, we might need to provide the controllers some information that is not known up front when provisioning the cluster. VPC ID or OIDC arn is good examples of this. This would mean that we would need to retrofit this information into a Helm chart afterwards.

### Helm addon `valuesTemplete`

It turns out that the Helm addon for Cluster API has templating capabilties built in for fetching data from the spec of `Cluster` and `ControlPlane` resources. Let see an example of this using our favorite metrics-server chart as naive example:

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
  valuesTemplate: |
    commonLabels:
      test: im-a-static-label # static label
      vpcId: {{ .ControlPlane.spec.network.vpc.id }} # label read from control plane resource
      host: "{{ .Cluster.spec.controlPlaneEndpoint.port }}" # label read from cluster resource
```

We would be able to verify that the metrics-server Deployment in the target cluster would have labels containing the VPC ID and control plane endpoint port read from the management cluster knowledge of the workload cluster.

This is a significant advantage the Helm addon has over ClusterResourceSet, that can prove very valuable.
